/*
 * %CopyrightBegin%
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Copyright Ericsson AB 1999-2025. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * %CopyrightEnd%
 */

/*
 * Support functions for tracing.
 *
 * Ideas for future speed improvements in tracing framework:
 *  * Move ErtsTracerNif into ErtsTracer
 *     + Removes need for locking
 *     + Removes hash lookup overhead
 *     + Use a refc on the ErtsTracerNif to know when it can
 *       be freed. We don't want to allocate a separate
 *       ErtsTracerNif for each module used.
 *  * Optimize GenericBp for cache locality by reusing equivalent
 *    GenericBp and GenericBpData in multiple tracer points.
 *     + Possibly we want to use specialized instructions for different
 *       types of trace so that the knowledge of which struct is used
 *       can be in the instruction.
 */

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif

#include "sys.h"
#include "erl_vm.h"
#include "global.h"
#include "erl_process.h"
#include "big.h"
#include "bif.h"
#include "dist.h"
#include "beam_bp.h"
#include "error.h"
#include "erl_binary.h"
#include "erl_bits.h"
#include "erl_thr_progress.h"
#include "erl_bif_unique.h"
#include "erl_map.h"
#include "erl_global_literals.h"

#if 0
#define DEBUG_PRINTOUTS
#else
#undef DEBUG_PRINTOUTS
#endif

erts_atomic32_t erts_active_bp_index;
erts_atomic32_t erts_staging_bp_index;

/* Pseudo export entries. Never filled in with data, only used to
   yield unique pointers of the correct type. */
Export exp_send, exp_receive, exp_timeout;

static ErtsTracer system_seq_tracer;

static Eterm system_profile;
static erts_atomic_t system_logger;

#ifdef HAVE_ERTS_NOW_CPU
int erts_cpu_timestamp;
#endif

static erts_mtx_t smq_mtx;
static erts_rwmtx_t sys_trace_rwmtx;

enum ErtsSysMsgType {
    SYS_MSG_TYPE_UNDEFINED,
    SYS_MSG_TYPE_SYSMON,
    SYS_MSG_TYPE_ERRLGR,
    SYS_MSG_TYPE_PROC_MSG,
    SYS_MSG_TYPE_SYSPROF
};

#define ERTS_TRACE_TS_NOW_MAX_SIZE				\
    4
#define ERTS_TRACE_TS_MONOTONIC_MAX_SIZE			\
    ERTS_MAX_SINT64_HEAP_SIZE
#define ERTS_TRACE_TS_STRICT_MONOTONIC_MAX_SIZE			\
    (3 + ERTS_MAX_SINT64_HEAP_SIZE				\
     + ERTS_MAX_UINT64_HEAP_SIZE)

#define ERTS_TRACE_PATCH_TS_MAX_SIZE				\
    (1 + ((ERTS_TRACE_TS_NOW_MAX_SIZE				\
	   > ERTS_TRACE_TS_MONOTONIC_MAX_SIZE)			\
	  ? ((ERTS_TRACE_TS_NOW_MAX_SIZE			\
	      > ERTS_TRACE_TS_STRICT_MONOTONIC_MAX_SIZE)	\
	     ? ERTS_TRACE_TS_NOW_MAX_SIZE			\
	     : ERTS_TRACE_TS_STRICT_MONOTONIC_MAX_SIZE)		\
	  : ((ERTS_TRACE_TS_MONOTONIC_MAX_SIZE			\
	      > ERTS_TRACE_TS_STRICT_MONOTONIC_MAX_SIZE)	\
	     ? ERTS_TRACE_TS_MONOTONIC_MAX_SIZE			\
	     : ERTS_TRACE_TS_STRICT_MONOTONIC_MAX_SIZE)))

/*
 * FUTURE CHANGES:
 *
 * The timestamp functionality has intentionally been
 * split in two parts for future use even though it
 * is not used like this today. take_timestamp() takes
 * the timestamp and calculate heap need for it (which
 * is not constant). write_timestamp() writes the
 * timestamp to the allocated heap. That is, one typically
 * want to take the timestamp before allocating the heap
 * and then write it to the heap.
 *
 * The trace output functionality now use patch_ts_size(),
 * write_ts(), and patch_ts(). write_ts() both takes the
 * timestamp and writes it. Since we don't know the
 * heap need when allocating the heap area we need to
 * over allocate (maximum size from patch_ts_size()) and
 * then potentially (often) shrink the heap area after the
 * timestamp has been written. The only reason it is
 * currently done this way is because we do not want to
 * make major changes of the trace behavior in a patch.
 * This is planned to be changed in next major release.
 */

typedef struct {
    int ts_type_flag;
    union {
	struct {
	    Uint ms;
	    Uint s;
	    Uint us;
	} now;
	struct {
	    ErtsMonotonicTime time;
	    Sint64 raw_unique;
	} monotonic;
    } u;
} ErtsTraceTimeStamp;

static ERTS_INLINE Uint
take_timestamp(ErtsTraceTimeStamp *tsp, int ts_type)
{
    int ts_type_flag = ts_type & -ts_type; /* least significant flag */

    ASSERT(ts_type_flag == ERTS_TRACE_FLG_NOW_TIMESTAMP
	   || ts_type_flag == ERTS_TRACE_FLG_MONOTONIC_TIMESTAMP
	   || ts_type_flag == ERTS_TRACE_FLG_STRICT_MONOTONIC_TIMESTAMP
	   || ts_type_flag == 0);

    tsp->ts_type_flag = ts_type_flag;
    switch (ts_type_flag) {
    case 0:
	return (Uint) 0;
    case ERTS_TRACE_FLG_NOW_TIMESTAMP:
#ifdef HAVE_ERTS_NOW_CPU
	if (erts_cpu_timestamp)
	    erts_get_now_cpu(&tsp->u.now.ms, &tsp->u.now.s, &tsp->u.now.us);
	else
#endif
	    get_now(&tsp->u.now.ms, &tsp->u.now.s, &tsp->u.now.us);
	return (Uint) 4;
    case ERTS_TRACE_FLG_MONOTONIC_TIMESTAMP:
    case ERTS_TRACE_FLG_STRICT_MONOTONIC_TIMESTAMP: {
	Uint hsz = 0;
	ErtsMonotonicTime mtime = erts_get_monotonic_time(NULL);
	mtime = ERTS_MONOTONIC_TO_NSEC(mtime);
	mtime += ERTS_MONOTONIC_OFFSET_NSEC;
	hsz = (IS_SSMALL(mtime) ?
	       (Uint) 0
	       : ERTS_SINT64_HEAP_SIZE((Sint64) mtime));
	tsp->u.monotonic.time = mtime;
	if (ts_type_flag == ERTS_TRACE_FLG_STRICT_MONOTONIC_TIMESTAMP) {
	    Sint64 raw_unique;
	    hsz += 3; /* 2-tuple */
	    raw_unique = erts_raw_get_unique_monotonic_integer();
	    tsp->u.monotonic.raw_unique = raw_unique;
	    hsz += erts_raw_unique_monotonic_integer_heap_size(raw_unique, 0);
	}
	return hsz;
    }
    default:
	ERTS_INTERNAL_ERROR("invalid timestamp type");
	return 0;
    }
}

static ERTS_INLINE Eterm
write_timestamp(ErtsTraceTimeStamp *tsp, Eterm **hpp)
{
    int ts_type_flag = tsp->ts_type_flag;
    Eterm res;

    switch (ts_type_flag) {
    case 0:
	return NIL;
    case ERTS_TRACE_FLG_NOW_TIMESTAMP:
	res = TUPLE3(*hpp,
		     make_small(tsp->u.now.ms),
		     make_small(tsp->u.now.s),
		     make_small(tsp->u.now.us));
	*hpp += 4;
	return res;
    case ERTS_TRACE_FLG_MONOTONIC_TIMESTAMP:
    case ERTS_TRACE_FLG_STRICT_MONOTONIC_TIMESTAMP: {
	Sint64 mtime, raw;
	Eterm unique, emtime;

	mtime = (Sint64) tsp->u.monotonic.time;
	emtime = (IS_SSMALL(mtime)
		  ? make_small((Sint64) mtime)
		  : erts_sint64_to_big((Sint64) mtime, hpp));

	if (ts_type_flag == ERTS_TRACE_FLG_MONOTONIC_TIMESTAMP)
	    return emtime;

	raw = tsp->u.monotonic.raw_unique;
	unique = erts_raw_make_unique_monotonic_integer_value(hpp, raw, 0);
	res = TUPLE2(*hpp, emtime, unique);
	*hpp += 3;
	return res;
    }
    default:
	ERTS_INTERNAL_ERROR("invalid timestamp type");
	return THE_NON_VALUE;
    }
}


static ERTS_INLINE Uint
patch_ts_size(int ts_type)
{
    int ts_type_flag = ts_type & -ts_type; /* least significant flag */
    switch (ts_type_flag) {
    case 0:
	return 0;
    case ERTS_TRACE_FLG_NOW_TIMESTAMP:
	return 1 + ERTS_TRACE_TS_NOW_MAX_SIZE;
    case ERTS_TRACE_FLG_MONOTONIC_TIMESTAMP:
	return 1 + ERTS_TRACE_TS_MONOTONIC_MAX_SIZE;
    case ERTS_TRACE_FLG_STRICT_MONOTONIC_TIMESTAMP:
	return 1 + ERTS_TRACE_TS_STRICT_MONOTONIC_MAX_SIZE;
    default:
	ERTS_INTERNAL_ERROR("invalid timestamp type");
	return 0;
    }
}

/*
 * Write a timestamp. The timestamp MUST be the last
 * thing built on the heap. This since write_ts() might
 * adjust the size of the used area.
 */
static Eterm
write_ts(int ts_type, Eterm *hp, ErlHeapFragment *bp, Process *tracer)
{
    ErtsTraceTimeStamp ts;
    Sint shrink;
    Eterm res, *ts_hp = hp;
    Uint hsz;

    ASSERT(ts_type);

    hsz = take_timestamp(&ts, ts_type);

    res = write_timestamp(&ts, &ts_hp);

    ASSERT(ts_hp == hp + hsz);

    switch (ts.ts_type_flag) {
    case ERTS_TRACE_FLG_MONOTONIC_TIMESTAMP:
	shrink = ERTS_TRACE_TS_MONOTONIC_MAX_SIZE;
	break;
    case ERTS_TRACE_FLG_STRICT_MONOTONIC_TIMESTAMP:
	shrink = ERTS_TRACE_TS_STRICT_MONOTONIC_MAX_SIZE;
	break;
    default:
	return res;
    }

    shrink -= hsz;

    ASSERT(shrink >= 0);

    if (shrink) {
	if (bp)
	    bp->used_size -= shrink;
    }

    return res;
}

static void enqueue_sys_msg_unlocked(enum ErtsSysMsgType type,
				     Eterm from,
				     Eterm to,
				     Eterm msg,
				     ErlHeapFragment *bp,
                                     ErtsTraceSession*);
static void enqueue_sys_msg(enum ErtsSysMsgType type,
			    Eterm from,
			    Eterm to,
			    Eterm msg,
			    ErlHeapFragment *bp,
                            ErtsTraceSession*);
static void init_sys_msg_dispatcher(void);

static void init_tracer_nif(void);
static int tracer_cmp_fun(void*, void*);
static HashValue tracer_hash_fun(void*);
static void *tracer_alloc_fun(void*);
static void tracer_free_fun(void*);

typedef struct ErtsTracerNif_ ErtsTracerNif;

void erts_init_trace(void) {
    erts_rwmtx_opt_t rwmtx_opts = ERTS_RWMTX_OPT_DEFAULT_INITER;
    rwmtx_opts.type = ERTS_RWMTX_TYPE_EXTREMELY_FREQUENT_READ;
    rwmtx_opts.lived = ERTS_RWMTX_LONG_LIVED;

    erts_rwmtx_init_opt(&sys_trace_rwmtx, &rwmtx_opts, "sys_tracers", NIL,
        ERTS_LOCK_FLAGS_PROPERTY_STATIC | ERTS_LOCK_FLAGS_CATEGORY_DEBUG);

#ifdef HAVE_ERTS_NOW_CPU
    erts_cpu_timestamp = 0;
#endif
    erts_bif_trace_init();
    erts_system_profile_clear(NULL);
    system_seq_tracer = erts_tracer_nil;
    erts_atomic_init_nob(&system_logger, am_logger);
    init_sys_msg_dispatcher();
    init_tracer_nif();
}

#define ERTS_ALLOC_SYSMSG_HEAP(SZ, BPP, OHPP, UNUSED) \
  (*(BPP) = new_message_buffer((SZ)), \
   *(OHPP) = &(*(BPP))->off_heap, \
   (*(BPP))->mem)

enum ErtsTracerOpt {
    TRACE_FUN_DEFAULT   = 0,
    TRACE_FUN_ENABLED   = 1,
    TRACE_FUN_T_SEND    = 2,
    TRACE_FUN_T_RECEIVE = 3,
    TRACE_FUN_T_CALL    = 4,
    TRACE_FUN_T_SCHED_PROC = 5,
    TRACE_FUN_T_SCHED_PORT = 6,
    TRACE_FUN_T_GC      = 7,
    TRACE_FUN_T_PROCS   = 8,
    TRACE_FUN_T_PORTS   = 9,
    TRACE_FUN_E_SEND    = 10,
    TRACE_FUN_E_RECEIVE = 11,
    TRACE_FUN_E_CALL    = 12,
    TRACE_FUN_E_SCHED_PROC = 13,
    TRACE_FUN_E_SCHED_PORT = 14,
    TRACE_FUN_E_GC      = 15,
    TRACE_FUN_E_PROCS   = 16,
    TRACE_FUN_E_PORTS   = 17
};

#define NIF_TRACER_TYPES (18)


static ERTS_INLINE int
send_to_tracer_nif_raw(Process *c_p, Process *tracee, const ErtsTracer tracer,
                       Uint trace_flags, Eterm t_p_id, ErtsTracerNif *tnif,
                       enum ErtsTracerOpt topt,
                       Eterm tag, Eterm msg, Eterm extra, Eterm pam_result);
static ERTS_INLINE int
send_to_tracer_nif(Process *c_p, ErtsPTabElementCommon *t_p, ErtsTracerRef *ref,
                   Eterm t_p_id, ErtsTracerNif *tnif,
                   enum ErtsTracerOpt topt,
                   Eterm tag, Eterm msg, Eterm extra,
                   Eterm pam_result);
static ERTS_INLINE Eterm
call_enabled_tracer(const ErtsTracer tracer,
                    ErtsTracerNif **tnif_ref,
                    enum ErtsTracerOpt topt,
                    Eterm tag, Eterm t_p_id);
static int
is_tracer_ref_enabled(Process* c_p, ErtsProcLocks c_p_locks,
                      ErtsPTabElementCommon *t_p,
                      ErtsTracerRef *ref,
                      ErtsTracerNif **tnif_ret,
                      enum ErtsTracerOpt topt, Eterm tag);

static Uint active_sched;

void
erts_system_profile_setup_active_schedulers(void)
{
    ERTS_LC_ASSERT(erts_thr_progress_is_blocking());
    active_sched = erts_active_schedulers();
}

static void
exiting_reset(Eterm exiting)
{
    erts_rwmtx_rwlock(&erts_trace_session_list_lock);
    erts_rwmtx_rwlock(&sys_trace_rwmtx);

    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        if (exiting == s->system_monitor.receiver) {
            s->system_monitor.receiver = NIL;
            /* Let the trace message dispatcher clear flags, etc */
        }
    }

    if (exiting == system_profile) {
	system_profile = NIL;
	/* Let the trace message dispatcher clear flags, etc */
    }
    erts_rwmtx_rwunlock(&sys_trace_rwmtx);
    erts_rwmtx_rwunlock(&erts_trace_session_list_lock);
}

void
erts_trace_check_exiting(Eterm exiting)
{
    int reset = 0;
    erts_rwmtx_rlock(&erts_trace_session_list_lock);
    erts_rwmtx_rlock(&sys_trace_rwmtx);

    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        if (exiting == s->system_monitor.receiver) {
            reset = 1;
            break;
        }
    }

    if (exiting == system_profile)
        reset = 1;
    erts_rwmtx_runlock(&sys_trace_rwmtx);
    erts_rwmtx_runlock(&erts_trace_session_list_lock);
    if (reset)
	exiting_reset(exiting);
}

ErtsTracer
erts_set_system_seq_tracer(Process *c_p, ErtsProcLocks c_p_locks, ErtsTracer new)
{
    ErtsTracer old;

    if (!ERTS_TRACER_IS_NIL(new)) {
        Eterm nif_result = call_enabled_tracer(
            new, NULL, TRACE_FUN_ENABLED, am_trace_status, am_undefined);
        switch (nif_result) {
        case am_trace: break;
        default:
            return THE_NON_VALUE;
        }
    }

    erts_rwmtx_rwlock(&sys_trace_rwmtx);
    old = system_seq_tracer;
    system_seq_tracer = erts_tracer_nil;
    erts_tracer_update(&system_seq_tracer, new);

#ifdef DEBUG_PRINTOUTS
    erts_fprintf(stderr, "set seq tracer new=%T old=%T\n", new, old);
#endif
    erts_rwmtx_rwunlock(&sys_trace_rwmtx);
    return old;
}

ErtsTracer
erts_get_system_seq_tracer(void)
{
    ErtsTracer st;
    erts_rwmtx_rlock(&sys_trace_rwmtx);
    st = system_seq_tracer;
#ifdef DEBUG_PRINTOUTS
    erts_fprintf(stderr, "get seq tracer %T\n", st);
#endif
    erts_rwmtx_runlock(&sys_trace_rwmtx);

    if (st != erts_tracer_nil &&
        call_enabled_tracer(st, NULL, TRACE_FUN_ENABLED,
                            am_trace_status, am_undefined) == am_remove) {
        st = erts_set_system_seq_tracer(NULL, 0, erts_tracer_nil);
        ERTS_TRACER_CLEAR(&st);
    }

    return st;
}

static ERTS_INLINE void
get_new_p_tracing(Uint32 *flagsp, ErtsTracer *tracerp,
                  Uint32 *default_trace_flags,
                  ErtsTracer *default_tracer)
{
    if (!(*default_trace_flags & TRACEE_FLAGS))
	ERTS_TRACER_CLEAR(default_tracer);

    if (ERTS_TRACER_IS_NIL(*default_tracer)) {
	*default_trace_flags &= ~TRACEE_FLAGS;
    } else {
        Eterm nif_res;
        nif_res = call_enabled_tracer(*default_tracer,
                                      NULL, TRACE_FUN_ENABLED,
                                      am_trace_status, am_undefined);
        switch (nif_res) {
        case am_trace: break;
        default: {
            ErtsTracer curr_default_tracer = *default_tracer;
            if (tracerp) {
                /* we only have a rlock, so we have to unlock and then rwlock */
                erts_rwmtx_runlock(&sys_trace_rwmtx);
                erts_rwmtx_rwlock(&sys_trace_rwmtx);
            }
            /* check if someone else changed default tracer
               while we got the write lock, if so we don't do
               anything. */
            if (curr_default_tracer == *default_tracer) {
                *default_trace_flags &= ~TRACEE_FLAGS;
                ERTS_TRACER_CLEAR(default_tracer);
            }
            if (tracerp) {
                erts_rwmtx_rwunlock(&sys_trace_rwmtx);
                erts_rwmtx_rlock(&sys_trace_rwmtx);
            }
        }
        }
    }

    if (flagsp)
	*flagsp = *default_trace_flags;
    if (tracerp) {
	erts_tracer_update(tracerp,*default_tracer);
    }
}

static void
erts_change_new_p_tracing(int setflags, Uint32 flags,
                          const ErtsTracer tracer,
                          Uint32 *default_trace_flags,
                          ErtsTracer *default_tracer)
{
    if (setflags)
        *default_trace_flags |= flags;
    else
        *default_trace_flags &= ~flags;

    erts_tracer_update(default_tracer, tracer);

    get_new_p_tracing(NULL, NULL, default_trace_flags, default_tracer);
}

void
erts_change_new_procs_tracing(ErtsTraceSession* session,
                              int setflags, Uint32 flags,
                              const ErtsTracer tracer)
{
    Uint32 was_tracer;

    erts_rwmtx_rwlock(&sys_trace_rwmtx);
    was_tracer = session->new_procs_tracer;

    erts_change_new_p_tracing(
        setflags, flags, tracer,
        &session->new_procs_trace_flags,
        &session->new_procs_tracer);

    if (session->new_procs_tracer != was_tracer) {
        if (ERTS_TRACER_IS_NIL(was_tracer)) {
            erts_refc_inc(&erts_new_procs_trace_cnt, 1);
        }
        else if (ERTS_TRACER_IS_NIL(session->new_procs_tracer)) {
            erts_refc_dec(&erts_new_procs_trace_cnt, 0);
        }
    }
    erts_rwmtx_rwunlock(&sys_trace_rwmtx);
}

void
erts_change_new_ports_tracing(ErtsTraceSession* session,
                              int setflags, Uint32 flags,
                              const ErtsTracer tracer)
{
    Uint32 was_tracer;

    erts_rwmtx_rwlock(&sys_trace_rwmtx);
    was_tracer = session->new_ports_tracer;

    erts_change_new_p_tracing(
        setflags, flags, tracer,
        &session->new_ports_trace_flags,
        &session->new_ports_tracer);

    if (session->new_ports_tracer != was_tracer) {
        if (ERTS_TRACER_IS_NIL(was_tracer)) {
            erts_refc_inc(&erts_new_ports_trace_cnt, 1);
        }
        else if (ERTS_TRACER_IS_NIL(session->new_ports_tracer)) {
            erts_refc_dec(&erts_new_ports_trace_cnt, 0);
        }
    }
    erts_rwmtx_rwunlock(&sys_trace_rwmtx);
}

void
erts_get_new_proc_tracing(ErtsTraceSession* session,
                          Uint32 *flagsp, ErtsTracer *tracerp)
{
    erts_rwmtx_rlock(&sys_trace_rwmtx);
    *tracerp = erts_tracer_nil; /* initialize */
    get_new_p_tracing(
        flagsp, tracerp,
        &session->new_procs_trace_flags,
        &session->new_procs_tracer);
    erts_rwmtx_runlock(&sys_trace_rwmtx);
}

void
erts_get_new_port_tracing(ErtsTraceSession* session,
                              Uint32 *flagsp, ErtsTracer *tracerp)
{
    erts_rwmtx_rlock(&sys_trace_rwmtx);
    *tracerp = erts_tracer_nil; /* initialize */
    get_new_p_tracing(
        flagsp, tracerp,
        &session->new_ports_trace_flags,
        &session->new_ports_tracer);
    erts_rwmtx_runlock(&sys_trace_rwmtx);
}

void
erts_set_system_monitor(ErtsTraceSession *session, Eterm monitor)
{
    erts_rwmtx_rwlock(&sys_trace_rwmtx);
    session->system_monitor.receiver = monitor;
    erts_rwmtx_rwunlock(&sys_trace_rwmtx);
}

Eterm
erts_get_system_monitor(ErtsTraceSession *session)
{
    Eterm monitor;
    erts_rwmtx_rlock(&sys_trace_rwmtx);
    monitor = session->system_monitor.receiver;
    erts_rwmtx_runlock(&sys_trace_rwmtx);
    return monitor;
}

/* Performance monitoring */
void erts_set_system_profile(Eterm profile) {
    erts_rwmtx_rwlock(&sys_trace_rwmtx);
    system_profile = profile;
    erts_rwmtx_rwunlock(&sys_trace_rwmtx);
}

Eterm
erts_get_system_profile(void) {
    Eterm profile;
    erts_rwmtx_rlock(&sys_trace_rwmtx);
    profile = system_profile;
    erts_rwmtx_runlock(&sys_trace_rwmtx);
    return profile;
}

static void
write_sys_msg_to_port(Eterm unused_to,
		      Port* trace_port,
		      Eterm unused_from,
		      enum ErtsSysMsgType unused_type,
		      Eterm message) {
    byte *buffer;
    byte *ptr;
    Uint size;

    if (erts_encode_ext_size(message, &size) != ERTS_EXT_SZ_OK)
	erts_exit(ERTS_ERROR_EXIT, "Internal error: System limit\n");

    buffer = (byte *) erts_alloc(ERTS_ALC_T_TMP, size);

    ptr = buffer;

    erts_encode_ext(message, &ptr);
    if (!(ptr <= buffer+size)) {
	erts_exit(ERTS_ERROR_EXIT, "Internal error in do_send_to_port: %d\n", ptr-buffer);
    }

	erts_raw_port_command(trace_port, buffer, ptr-buffer);

    erts_free(ERTS_ALC_T_TMP, (void *) buffer);
}

/* Send {trace_ts, Pid, What, {Mod, Func, Arity}, Timestamp}
 * or   {trace, Pid, What, {Mod, Func, Arity}}
 *
 * where 'What' is supposed to be 'in', 'out', 'in_exiting',
 * 'out_exiting', or 'out_exited'.
 */
void
trace_sched(Process *p, ErtsProcLocks locks, Eterm what, Uint32 trace_flags)
{
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    for (ref = p->common.tracee.first_ref; ref; ref = next_ref) {
        next_ref = ref->next;
        if (IS_SESSION_TRACED_ANY_FL(ref, trace_flags)) {
            trace_sched_session(p, locks, what, ref);
        }
    }
    ERTS_ASSERT_TRACER_REFS(&p->common);
}

void
trace_sched_session(Process *p, ErtsProcLocks locks, Eterm what,
                    ErtsTracerRef *ref)
{
    Eterm tmp, *hp;
    int curr_func;
    ErtsTracerNif *tnif = NULL;

    if (ERTS_TRACER_IS_NIL(ref->tracer))
	return;

    switch (what) {
    case am_out:
    case am_out_exiting:
    case am_out_exited:
    case am_in:
    case am_in_exiting:
	break;
    default:
	ASSERT(0);
	break;
    }

    if (!is_tracer_ref_enabled(p, locks, &p->common, ref, &tnif,
                               TRACE_FUN_E_SCHED_PROC, what))
        return;

    if (ERTS_PROC_IS_EXITING(p))
	curr_func = 0;
    else {
	if (!p->current)
	    p->current = erts_find_function_from_pc(p->i);
	curr_func = p->current != NULL;
    }

    if (!curr_func) {
	tmp = make_small(0);
    } else {
        hp = HAlloc(p, 4);
	tmp = TUPLE3(hp,p->current->module,p->current->function,
                     make_small(p->current->arity));
	hp += 4;
    }

    send_to_tracer_nif(p, &p->common, ref, p->common.id, tnif, TRACE_FUN_T_SCHED_PROC,
                       what, tmp, THE_NON_VALUE, am_true);
}

static void
trace_send_session(Process*, Eterm to, Eterm msg, ErtsTracerRef*);

/* Send {trace_ts, Pid, Send, Msg, DestPid, PamResult, Timestamp}
 * or   {trace_ts, Pid, Send, Msg, DestPid, Timestamp}
 * or   {trace, Pid, Send, Msg, DestPid, PamResult}
 * or   {trace, Pid, Send, Msg, DestPid}
 *
 * where 'Send' is 'send' or 'send_to_non_existing_process'.
 */
void
trace_send(Process *p, Eterm to, Eterm msg)
{
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    for (ref = p->common.tracee.first_ref; ref; ref = next_ref) {
        next_ref = ref->next;
        if (IS_SESSION_TRACED_FL(ref, F_TRACE_SEND)) {
            trace_send_session(p, to, msg, ref);
        }
    }
    ERTS_ASSERT_TRACER_REFS(&p->common);
}

static void
trace_send_session(Process *p, Eterm to, Eterm msg, ErtsTracerRef *ref)
{
    ErtsTracingEvent *te = &ref->session->send_tracing[erts_active_bp_ix()];
    Eterm operation = am_send;
    ErtsTracerNif *tnif = NULL;
    Eterm pam_result;
    ErtsThrPrgrDelayHandle dhndl;

    if (!te->on)
        return;

    //ASSERT(ARE_TRACE_FLAGS_ON(p, F_TRACE_SEND));

    if (te->match_spec) {
	Eterm args[2];
	Uint32 return_flags;
	args[0] = to;
	args[1] = msg;
	pam_result = erts_match_set_run_trace(p, p,
                                              te->match_spec, args, 2,
                                              ERTS_PAM_TMP_RESULT, &return_flags);
	if (pam_result == am_false)
            return;
        if (ref->flags & F_TRACE_SILENT) {
            erts_match_set_release_result_trace(p, pam_result);
	    return;
	}
    } else
        pam_result = am_true;

    dhndl = erts_thr_progress_unmanaged_delay();

    if (is_internal_pid(to)) {
	if (!erts_proc_lookup(to))
	    goto send_to_non_existing_process;
    }
    else if(is_external_pid(to)
	    && external_pid_dist_entry(to) == erts_this_dist_entry) {
    send_to_non_existing_process:
	operation = am_send_to_non_existing_process;
    }

    if (is_tracer_ref_enabled(p, ERTS_PROC_LOCK_MAIN, &p->common, ref, &tnif,
                              TRACE_FUN_E_SEND, operation)) {
        send_to_tracer_nif(p, &p->common, ref, p->common.id, tnif,
                           TRACE_FUN_T_SEND, operation, msg, to, pam_result);
    }

    erts_thr_progress_unmanaged_continue(dhndl);

    erts_match_set_release_result_trace(p, pam_result);
}

static void
trace_receive_session(Process*, Eterm from, Eterm msg, ErtsTracerRef*);

/* Send {trace_ts, Pid, receive, Msg, PamResult, Timestamp}
 * or   {trace_ts, Pid, receive, Msg, Timestamp}
 * or   {trace, Pid, receive, Msg, PamResult}
 * or   {trace, Pid, receive, Msg}
 */
void
trace_receive(Process* receiver,
              Eterm from,
              Eterm msg)
{
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    for (ref = receiver->common.tracee.first_ref; ref; ref = next_ref) {
        next_ref = ref->next;
        if (IS_SESSION_TRACED_FL(ref, F_TRACE_RECEIVE)) {
            trace_receive_session(receiver, from, msg, ref);
        }
    }
    ERTS_ASSERT_TRACER_REFS(&receiver->common);
}

static void
trace_receive_session(Process* receiver,
                      Eterm from,
                      Eterm msg,
                      ErtsTracerRef *ref)
{
    ErtsTracingEvent *te = &ref->session->receive_tracing[erts_active_bp_ix()];
    ErtsTracerNif *tnif = NULL;
    Eterm pam_result;

    if (!te->on) {
        return;
    }

    if (te->match_spec) {
        Eterm args[3];
        Uint32 return_flags;
        if (is_pid(from)) {
            args[0] = pid_node_name(from);
            args[1] = from;
        }
        else {
            ASSERT(is_atom(from));
            args[0] = from;  /* node name or other atom (e.g 'system') */
            args[1] = am_undefined;
        }
        args[2] = msg;
        pam_result = erts_match_set_run_trace(NULL, receiver,
                                              te->match_spec, args, 3,
                                              ERTS_PAM_TMP_RESULT, &return_flags);
        if (pam_result == am_false)
            return;
        if (ref->flags & F_TRACE_SILENT) {
            erts_match_set_release_result_trace(NULL, pam_result);
            return;
        }
    } else {
        pam_result = am_true;
    }

    if (is_tracer_ref_enabled(NULL, 0, &receiver->common, ref, &tnif,
                              TRACE_FUN_E_RECEIVE, am_receive)) {
        send_to_tracer_nif(NULL, &receiver->common, ref, receiver->common.id,
                           tnif, TRACE_FUN_T_RECEIVE,
                           am_receive, msg, THE_NON_VALUE, pam_result);
    }
    erts_match_set_release_result_trace(NULL, pam_result);
}

int
seq_trace_update_serial(Process *p)
{
    ErtsTracer seq_tracer = erts_get_system_seq_tracer();
    ASSERT((is_tuple(SEQ_TRACE_TOKEN(p)) || is_nil(SEQ_TRACE_TOKEN(p))));
    if (have_no_seqtrace(SEQ_TRACE_TOKEN(p)) ||
        (seq_tracer != NIL &&
         call_enabled_tracer(seq_tracer, NULL,
                             TRACE_FUN_ENABLED, am_seq_trace,
                             p ? p->common.id : am_undefined) != am_trace)
#ifdef USE_VM_PROBES
	 || (SEQ_TRACE_TOKEN(p) == am_have_dt_utag)
#endif
	 ) {
	return 0;
    }
    SEQ_TRACE_TOKEN_SENDER(p) = p->common.id;
    SEQ_TRACE_TOKEN_SERIAL(p) = 
	make_small(++(p -> seq_trace_clock));
    SEQ_TRACE_TOKEN_LASTCNT(p) = 
	make_small(p -> seq_trace_lastcnt);
    return 1;
}

void
erts_seq_trace_update_node_token(Eterm token)
{
    Eterm serial;
    Uint serial_num;
    SEQ_TRACE_T_SENDER(token) = erts_this_dist_entry->sysname;
    serial = SEQ_TRACE_T_SERIAL(token);
    serial_num = unsigned_val(serial);
    serial_num++;
    SEQ_TRACE_T_SERIAL(token) = make_small(serial_num);
}


/* Send a sequential trace message to the sequential tracer.
 * p is the caller (which contains the trace token), 
 * msg is the original message, type is trace type (SEQ_TRACE_SEND etc),
 * and receiver is the receiver of the message.
 *
 * The message to be received by the sequential tracer is:
 * 
 *    TraceMsg = 
 *   {seq_trace, Label, {Type, {Lastcnt, Serial}, Sender, Receiver, Msg} [,Timestamp] }
 *
 */
void 
seq_trace_output_generic(Eterm token, Eterm msg, Uint type,
			 Eterm receiver, Process *process, Eterm exitfrom)
{
    Eterm mess;
    Eterm* hp;
    Eterm label;
    Eterm lastcnt_serial;
    Eterm type_atom;
    ErtsTracer seq_tracer;
    int seq_tracer_flags = 0;
#define LOCAL_HEAP_SIZE (64)
    DeclareTmpHeapNoproc(local_heap,LOCAL_HEAP_SIZE);

    seq_tracer = erts_get_system_seq_tracer();

    ASSERT(is_tuple(token) || is_nil(token));
    if (token == NIL || (process && ERTS_IS_PROC_SENSITIVE(process)) ||
        ERTS_TRACER_IS_NIL(seq_tracer) ||
        call_enabled_tracer(seq_tracer,
                            NULL, TRACE_FUN_ENABLED,
                            am_seq_trace,
                            process ? process->common.id : am_undefined) != am_trace) {
	return;
    }

    if ((unsigned_val(SEQ_TRACE_T_FLAGS(token)) & type) == 0) {
	/* No flags set, nothing to do */
	return;
    }

    switch (type) {
    case SEQ_TRACE_SEND:    type_atom = am_send; break;
    case SEQ_TRACE_PRINT:   type_atom = am_print; break;
    case SEQ_TRACE_RECEIVE: type_atom = am_receive; break;
    default:
	erts_exit(ERTS_ERROR_EXIT, "invalid type in seq_trace_output_generic: %d:\n", type);
	return;			/* To avoid warning */
    }

    UseTmpHeapNoproc(LOCAL_HEAP_SIZE);

    hp = local_heap;
    label = SEQ_TRACE_T_LABEL(token);
    lastcnt_serial = TUPLE2(hp, SEQ_TRACE_T_LASTCNT(token),
                            SEQ_TRACE_T_SERIAL(token));
    hp += 3;
    if (exitfrom != NIL) {
        msg = TUPLE3(hp, am_EXIT, exitfrom, msg);
        hp += 4;
    }
    mess = TUPLE5(hp, type_atom, lastcnt_serial, SEQ_TRACE_T_SENDER(token), receiver, msg);
    hp += 6;

    seq_tracer_flags |=  ERTS_SEQTFLGS2TFLGS(unsigned_val(SEQ_TRACE_T_FLAGS(token)));

    send_to_tracer_nif_raw(NULL, process, seq_tracer, seq_tracer_flags,
                           label, NULL, TRACE_FUN_DEFAULT, am_seq_trace, mess,
                           THE_NON_VALUE, am_true);

    UnUseTmpHeapNoproc(LOCAL_HEAP_SIZE);
#undef LOCAL_HEAP_SIZE
}




/* Send {trace_ts, Pid, return_to, {Mod, Func, Arity}, Timestamp}
 * or   {trace, Pid, return_to, {Mod, Func, Arity}}
 */
void 
erts_trace_return_to(Process *p, ErtsCodePtr pc, ErtsTracerRef *ref)
{
    const ErtsCodeMFA *cmfa;
    Eterm mfa;

    cmfa = erts_find_function_from_pc(pc);

    if (!cmfa) {
	mfa = am_undefined;
    } else {
        Eterm *hp = HAlloc(p, 4);
	mfa = TUPLE3(hp, cmfa->module, cmfa->function,
                     make_small(cmfa->arity));
    }

    send_to_tracer_nif(p, &p->common, ref, p->common.id, NULL, TRACE_FUN_T_CALL,
                       am_return_to, mfa, THE_NON_VALUE, am_true);
}


/* Send {trace_ts, Pid, return_from, {Mod, Name, Arity}, Retval, Timestamp}
 * or   {trace, Pid, return_from, {Mod, Name, Arity}, Retval}
 */
void
erts_trace_return(Process* p, ErtsCodeMFA *mfa,
                  Eterm retval, ErtsTracer tracer, Eterm session_weak_id)
{
    Eterm* hp;
    Eterm mfa_tuple;
    Uint32 tracee_flags;

    ASSERT(p->return_trace_frames > 0);
    p->return_trace_frames--;

    if (ERTS_TRACER_COMPARE(tracer, erts_tracer_true)) {
        ErtsTracerRef *ref;
	/* Breakpoint trace enabled without specifying tracer =>
	 *   use process tracer and flags
	 */
        ref = get_tracer_ref_from_weak_id(&p->common, session_weak_id);
        if (!ref)
            return;

	tracer = ref->tracer;
        tracee_flags = ref->flags;
        if (! (tracee_flags & F_TRACE_CALLS))
            return;
    }
    else {
        /* Meta tracing with specified tracer and fixed flags */
        tracee_flags = F_TRACE_CALLS | F_NOW_TS;
    }

    if (ERTS_TRACER_IS_NIL(tracer)) {
	/* Trace disabled */
	return;
    }

    ASSERT(IS_TRACER_VALID(tracer));

    hp = HAlloc(p, 4);
    mfa_tuple = TUPLE3(hp, mfa->module, mfa->function,
                       make_small(mfa->arity));
    hp += 4;
    send_to_tracer_nif_raw(p, NULL, tracer, tracee_flags, p->common.id,
                           NULL, TRACE_FUN_T_CALL, am_return_from, mfa_tuple,
                           retval, am_true);
}

/* Send {trace_ts, Pid, exception_from, {Mod, Name, Arity}, {Class,Value}, 
 *       Timestamp}
 * or   {trace, Pid, exception_from, {Mod, Name, Arity}, {Class,Value}, 
 *       Timestamp}
 *
 * Where Class is atomic but Value is any term.
 */
void
erts_trace_exception(Process* p, ErtsCodeMFA *mfa, Eterm class, Eterm value,
		     ErtsTracer tracer, Eterm session_weak_id)
{
    Eterm* hp;
    Eterm mfa_tuple, cv;
    Uint32 tracee_flags;

    if (ERTS_TRACER_COMPARE(tracer, erts_tracer_true)) {
        ErtsTracerRef *ref;
	/* Breakpoint trace enabled without specifying tracer =>
	 *   use process tracer and flags
	 */
        ref = get_tracer_ref_from_weak_id(&p->common, session_weak_id);
        if (!ref)
            return;

	tracer = ref->tracer;
        tracee_flags = ref->flags;
        if (! (tracee_flags & F_TRACE_CALLS))
            return;
    }
    else {
        /* Meta tracing with specified tracer and fixed flags */
        tracee_flags = F_TRACE_CALLS | F_NOW_TS;
    }

    if (ERTS_TRACER_IS_NIL(tracer)) {
	/* Trace disabled */
	return;
    }

    ASSERT(IS_TRACER_VALID(tracer));

    hp = HAlloc(p, 7);;
    mfa_tuple = TUPLE3(hp, mfa->module, mfa->function, make_small(mfa->arity));
    hp += 4;
    cv = TUPLE2(hp, class, value);
    hp += 3;
    send_to_tracer_nif_raw(p, NULL, tracer, tracee_flags, p->common.id,
                           NULL, TRACE_FUN_T_CALL, am_exception_from,
                           mfa_tuple, cv, am_true);
}

/*
 * This function implements the new call trace.
 *
 * Send {trace_ts, Pid, call, {Mod, Func, A}, PamResult, Timestamp}
 * or   {trace_ts, Pid, call, {Mod, Func, A}, Timestamp}
 * or   {trace, Pid, call, {Mod, Func, A}, PamResult}
 * or   {trace, Pid, call, {Mod, Func, A}
 *
 * where 'A' is arity or argument list depending on trace flag 'arity'.
 *
 * If *tracer_pid is am_true, it is a breakpoint trace that shall use
 * the process tracer, if it is NIL no trace message is generated, 
 * if it is a pid or port we do a meta trace.
 */
Uint32
erts_call_trace(Process* p, ErtsCodeInfo *info, Binary *match_spec,
		Eterm* args, int local,
                ErtsTracerRef *ref,
                ErtsTracer *tracer_p)
{
    const int arity = info->mfa.arity;
    Eterm* hp;
    Eterm mfa_tuple;
    Uint32 return_flags;
    Eterm pam_result = am_true;
    Uint32 tracee_flags;
    ErtsTracerNif *tnif = NULL;
    ErtsTracer tracer;
    ErtsTracer pre_ms_tracer = erts_tracer_nil;
    Eterm session_id;

    ERTS_UNDEF(session_id, THE_NON_VALUE);

    ERTS_LC_ASSERT(erts_proc_lc_my_proc_locks(p) & ERTS_PROC_LOCK_MAIN);

    if (ref) {
        /* Breakpoint trace enabled without specifying tracer =>
	 *   use process tracer and flags
	 */
        ASSERT(ERTS_TRACER_COMPARE(*tracer_p, erts_tracer_true));
        ASSERT(!ERTS_TRACER_IS_NIL(ref->tracer));
        tracer = ref->tracer;
        tracee_flags = ref->flags;
        session_id = ref->session->weak_id;
        /* It is not ideal at all to call this check twice,
           it should be optimized so that only one call is made. */
        if (!is_tracer_ref_enabled(p, ERTS_PROC_LOCK_MAIN, &p->common, ref, &tnif,
                               TRACE_FUN_ENABLED, am_trace_status)
            || !is_tracer_ref_enabled(p, ERTS_PROC_LOCK_MAIN, &p->common, ref, &tnif,
                    TRACE_FUN_E_CALL, am_call)) {
            return 0;
        }
    } else {
	/* Tracer not specified in process structure =>
	 *   tracer specified in breakpoint =>
	 *     meta trace =>
	 *       use fixed flag set instead of process flags
	 */
        tracer = *tracer_p;
        if (ERTS_TRACER_IS_NIL(tracer)) {
            /* Trace disabled */
            return 0;
        }
        if (ERTS_IS_PROC_SENSITIVE(p)) {
            /* No trace messages for sensitive processes. */
            return 0;
        }
	tracee_flags = F_TRACE_CALLS | F_NOW_TS;
        switch (call_enabled_tracer(tracer,
                                    &tnif, TRACE_FUN_ENABLED,
                                    am_trace_status, p->common.id)) {
        default:
        case am_remove: *tracer_p = erts_tracer_nil; ERTS_FALLTHROUGH();
        case am_discard: return 0;
        case am_trace:
            switch (call_enabled_tracer(tracer,
                                        &tnif, TRACE_FUN_T_CALL,
                                        am_call, p->common.id)) {
            default:
            case am_discard: return 0;
            case am_trace: break;
            }
            break;
        }
    }

    /*
     * If there is a PAM program, run it.  Return if it fails.
     *
     * Some precedence rules:
     *
     * - No proc flags, e.g 'silent' or 'return_to'
     *   has any effect on meta trace.
     * - The 'silent' process trace flag silences all call
     *   related messages, e.g 'call', 'return_to' and 'return_from'.
     * - The {message,_} PAM function does not affect {return_trace}.
     * - The {message,false} PAM function shall give the same
     *   'call' trace message as no PAM match.
     * - The {message,true} PAM function shall give the same
     *   'call' trace message as a nonexistent PAM program.
     */

    return_flags = 0;
    if (match_spec) {
        /* we have to make a copy of the tracer here as the match spec
           may remove it, and we still want to generate a trace message */
        erts_tracer_update(&pre_ms_tracer, tracer);
        tracer = pre_ms_tracer;
        pam_result = erts_match_set_run_trace(p, p,
                                              match_spec, args, arity,
                                              ERTS_PAM_TMP_RESULT, &return_flags);
    }

    if (!ref) {
        /* Meta trace */
        if (pam_result == am_false) {
            UnUseTmpHeap(ERL_SUB_BITS_SIZE,p);
            ERTS_TRACER_CLEAR(&pre_ms_tracer);
            return return_flags;
        }
    } else {
        if (match_spec) {
            /* match spec may have removed our session ref */
            if (!get_tracer_ref_from_weak_id(&p->common, session_id)) {
                tracee_flags = 0;
            } else {
                tracee_flags = ref->flags;
            }
        }

        /* Non-meta trace */
        if (tracee_flags & F_TRACE_SILENT) {
            erts_match_set_release_result_trace(p, pam_result);
            UnUseTmpHeap(ERL_SUB_BITS_SIZE,p);
            ERTS_TRACER_CLEAR(&pre_ms_tracer);
            return 0;
        }
        if (pam_result == am_false) {
            UnUseTmpHeap(ERL_SUB_BITS_SIZE,p);
            ERTS_TRACER_CLEAR(&pre_ms_tracer);
            return return_flags;
        }
        if (local && (tracee_flags & F_TRACE_RETURN_TO)) {
            return_flags |= MATCH_SET_RETURN_TO_TRACE;
        }
    }

    ASSERT(!ERTS_TRACER_IS_NIL(tracer));

    /*
     * Build the {M,F,A} tuple in the local heap.
     * (A is arguments or arity.)
     */


    if (tracee_flags & F_TRACE_ARITY_ONLY) {
        hp = HAlloc(p, 4);
        mfa_tuple = make_small(arity);
    } else {
        int i;
        hp = HAlloc(p, 4 + arity * 2);
        mfa_tuple = NIL;
        for (i = arity-1; i >= 0; i--) {
            mfa_tuple = CONS(hp, args[i], mfa_tuple);
            hp += 2;
        }
    }
    mfa_tuple = TUPLE3(hp, info->mfa.module, info->mfa.function, mfa_tuple);
    hp += 4;

    /*
     * Build the trace tuple and send it to the port.
     */
    send_to_tracer_nif_raw(p, NULL, tracer, tracee_flags, p->common.id,
                           tnif, TRACE_FUN_T_CALL, am_call, mfa_tuple,
                           THE_NON_VALUE, pam_result);

    if (match_spec) {
        erts_match_set_release_result_trace(p, pam_result);
        ERTS_TRACER_CLEAR(&pre_ms_tracer);
    }

    return return_flags;
}

/* Sends trace message:
 *    {trace_ts, ProcessPid, What, Data, Timestamp}
 * or {trace, ProcessPid, What, Data}
 *
 * 'what' must be atomic, 'data' may be a deep term.
 * 'c_p' is the currently executing process, may be NULL.
 * 't_p' is the traced process.
 */
void
trace_proc(Process *c_p, ErtsProcLocks c_p_locks,
           Process *t_p, Eterm what, Eterm data)
{
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    for (ref = t_p->common.tracee.first_ref; ref; ref = next_ref) {
        ErtsTracerNif *tnif = NULL;

        next_ref = ref->next;
        if (IS_SESSION_TRACED_FL(ref, F_TRACE_PROCS)) {
            if (is_tracer_ref_enabled(NULL, 0, &t_p->common, ref, &tnif,
                                      TRACE_FUN_E_PROCS, what)) {
                send_to_tracer_nif(NULL, &t_p->common, ref, t_p->common.id, tnif,
                                   TRACE_FUN_T_PROCS,
                                   what, data, THE_NON_VALUE, am_true);

            }
        }
    }
    ERTS_ASSERT_TRACER_REFS(&t_p->common);
}


/* Sends trace message:
 *    {trace_ts, ParentPid, spawn, ChildPid, {Mod, Func, Args}, Timestamp}
 * or {trace, ParentPid, spawn, ChildPid, {Mod, Func, Args}}
 *
 * 'pid' is the ChildPid, 'mod' and 'func' must be atomic,
 * and 'args' may be a deep term.
 */
void
trace_proc_spawn(Process *p, Eterm what, Eterm pid,
		 Eterm mod, Eterm func, Eterm args)
{
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;
    Eterm mfa = THE_NON_VALUE;

    for (ref = p->common.tracee.first_ref; ref; ref = next_ref) {
        ErtsTracerNif *tnif = NULL;
        next_ref = ref->next;
        if (IS_SESSION_TRACED_FL(ref, F_TRACE_PROCS)
            && is_tracer_ref_enabled(NULL, 0, &p->common, ref, &tnif,
                                     TRACE_FUN_E_PROCS, what)) {

            if(is_non_value(mfa)){
                Eterm* hp = HAlloc(p, 4);
                mfa = TUPLE3(hp, mod, func, args);
            }
            send_to_tracer_nif(NULL, &p->common, ref, p->common.id, tnif, TRACE_FUN_T_PROCS,
                            what, pid, mfa, am_true);
        }
    }
    ERTS_ASSERT_TRACER_REFS(&p->common);
}

void save_calls(Process *p, const Export *e)
{
    if (!ERTS_IS_PROC_SENSITIVE(p)) {
	struct saved_calls *scb = ERTS_PROC_GET_SAVED_CALLS_BUF(p);
	if (scb) {
	    const Export **ct = &scb->ct[0];
	    int len = scb->len;

	    ct[scb->cur] = e;
	    if (++scb->cur >= len)
		scb->cur = 0;
	    if (scb->n < len)
		scb->n++;
	}
    }
}

/* Sends trace message:
 *    {trace_ts, Pid, What, Msg, Timestamp}
 * or {trace, Pid, What, Msg}
 *
 * where 'What' must be atomic and 'Msg' is: 
 * [{heap_size, HeapSize}, {old_heap_size, OldHeapSize}, 
 *  {stack_size, StackSize}, {recent_size, RecentSize}, 
 *  {mbuf_size, MbufSize}]
 *
 * where 'HeapSize', 'OldHeapSize', 'StackSize', 'RecentSize and 'MbufSize'
 * are all small (atomic) integers.
 */
void
trace_gc(Process *p, Eterm what, Uint size, Eterm msg)
{
    ErtsThrPrgrDelayHandle dhndl = erts_thr_progress_unmanaged_delay();
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    for (ref = p->common.tracee.first_ref; ref; ref = next_ref) {
        ErtsTracerNif *tnif = NULL;

        next_ref = ref->next;
        if (IS_SESSION_TRACED_FL(ref, F_TRACE_GC)
            && is_tracer_ref_enabled(p, ERTS_PROC_LOCK_MAIN, &p->common, ref,
                                     &tnif, TRACE_FUN_E_GC, what)) {
            Eterm* o_hp = NULL;
            Eterm* hp;
            Uint sz = 0;
            Eterm tup;

            if (is_non_value(msg)) {

                (void) erts_process_gc_info(p, &sz, NULL, 0, 0);
                o_hp = hp = erts_alloc(ERTS_ALC_T_TMP, (sz + 3 + 2) * sizeof(Eterm));

                msg = erts_process_gc_info(p, NULL, &hp, 0, 0);
                tup = TUPLE2(hp, am_wordsize, make_small(size)); hp += 3;
                msg = CONS(hp, tup, msg); hp += 2;
            }

            send_to_tracer_nif(p, &p->common, ref, p->common.id, tnif, TRACE_FUN_T_GC,
                               what, msg, THE_NON_VALUE, am_true);
            if (o_hp)
                erts_free(ERTS_ALC_T_TMP, o_hp);
        }
    }
    erts_thr_progress_unmanaged_continue(dhndl);
}

static void
monitor_long_schedule_proc_session(Process *p, const ErtsCodeMFA *in_fp,
                                   const ErtsCodeMFA *out_fp, Uint time,
                                   ErtsTraceSession *session)
{
    ErlHeapFragment *bp;
    ErlOffHeap *off_heap;
    Uint hsz;
    Eterm *hp, list, in_mfa = am_undefined, out_mfa = am_undefined;
    Eterm in_tpl, out_tpl, tmo_tpl, tmo, msg;
 

    /* 
     * Size: {monitor, pid, long_schedule, [{timeout, T}, {in, {M,F,A}},{out,{M,F,A}}]} ->
     * 5 (top tuple of 4), (3 (elements) * 2 (cons)) + 3 (timeout tuple of 2) + size of Timeout +
     * (2 * 3 (in/out tuple of 2)) + 
     * 0 (unknown) or 4 (MFA tuple of 3) + 0 (unknown) or 4 (MFA tuple of 3)
     * = 20 + (in_fp != NULL) ? 4 : 0 + (out_fp != NULL) ? 4 : 0 + size of Timeout
     */
    hsz = 20 + ((in_fp != NULL) ? 4 : 0) + ((out_fp != NULL) ? 4 : 0);
    (void) erts_bld_uint(NULL, &hsz, time);
    hp = ERTS_ALLOC_SYSMSG_HEAP(hsz, &bp, &off_heap, monitor_p);
    tmo = erts_bld_uint(&hp, NULL, time);
    if (in_fp != NULL) {
	in_mfa = TUPLE3(hp, in_fp->module, in_fp->function,
                        make_small(in_fp->arity));
	hp +=4;
    } 
    if (out_fp != NULL) {
	out_mfa = TUPLE3(hp, out_fp->module, out_fp->function,
                         make_small(out_fp->arity));
	hp +=4;
    } 
    tmo_tpl = TUPLE2(hp,am_timeout, tmo);
    hp += 3;
    in_tpl = TUPLE2(hp,am_in,in_mfa);
    hp += 3;
    out_tpl = TUPLE2(hp,am_out,out_mfa);
    hp += 3;
    list = CONS(hp,out_tpl,NIL); 
    hp += 2;
    list = CONS(hp,in_tpl,list);
    hp += 2;
    list = CONS(hp,tmo_tpl,list);
    hp += 2;
    msg = TUPLE4(hp, am_monitor, p->common.id, am_long_schedule, list);
    hp += 5;
    enqueue_sys_msg(SYS_MSG_TYPE_SYSMON, p->common.id,
                    session->system_monitor.receiver, msg, bp, session);
}

void 
monitor_long_schedule_proc(Process *p, const ErtsCodeMFA *in_fp,
                           const ErtsCodeMFA *out_fp, Uint time)
{
    erts_rwmtx_rlock(&erts_trace_session_list_lock);
    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        if (time-1 > s->system_monitor.limits[ERTS_SYSMON_LONG_SCHEDULE]-1) {
            monitor_long_schedule_proc_session(p, in_fp, out_fp, time, s);
        }
    }
    erts_rwmtx_runlock(&erts_trace_session_list_lock);
}


static void
monitor_long_schedule_port_session(Port *pp, ErtsPortTaskType type, Uint time,
                                   ErtsTraceSession *session)
{
    ErlHeapFragment *bp;
    ErlOffHeap *off_heap;
    Uint hsz;
    Eterm *hp, list, op;
    Eterm op_tpl, tmo_tpl, tmo, msg;
 

    /* 
     * Size: {monitor, port, long_schedule, [{timeout, T}, {op, Operation}]} ->
     * 5 (top tuple of 4), (2 (elements) * 2 (cons)) + 3 (timeout tuple of 2) 
     * + size of Timeout + 3 (op tuple of 2 atoms)
     * = 15 + size of Timeout
     */
    hsz = 15;
    (void) erts_bld_uint(NULL, &hsz, time);

    hp = ERTS_ALLOC_SYSMSG_HEAP(hsz, &bp, &off_heap, monitor_p);

    switch (type) {
    case ERTS_PORT_TASK_PROC_SIG: op = am_proc_sig; break;
    case ERTS_PORT_TASK_TIMEOUT: op = am_timeout; break;
    case ERTS_PORT_TASK_INPUT: op = am_input; break;
    case ERTS_PORT_TASK_OUTPUT: op = am_output; break;
    case ERTS_PORT_TASK_DIST_CMD: op = am_dist_cmd; break;
    default: op = am_undefined; break;
    }

    tmo = erts_bld_uint(&hp, NULL, time);

    op_tpl = TUPLE2(hp,am_port_op,op); 
    hp += 3;

    tmo_tpl = TUPLE2(hp,am_timeout, tmo);
    hp += 3;

    list = CONS(hp,op_tpl,NIL);
    hp += 2;
    list = CONS(hp,tmo_tpl,list);
    hp += 2;
    msg = TUPLE4(hp, am_monitor, pp->common.id, am_long_schedule, list);
    hp += 5;
    enqueue_sys_msg(SYS_MSG_TYPE_SYSMON, pp->common.id,
                    session->system_monitor.receiver, msg, bp, session);
}

void
monitor_long_schedule_port(Port *pp, ErtsPortTaskType type, Uint time)
{
    erts_rwmtx_rlock(&erts_trace_session_list_lock);
    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        if (time-1 > s->system_monitor.limits[ERTS_SYSMON_LONG_SCHEDULE]-1) {
            monitor_long_schedule_port_session(pp, type, time, s);
        }
    }
    erts_rwmtx_runlock(&erts_trace_session_list_lock);
}


static void
monitor_long_gc_session(Process *p, Uint time, ErtsTraceSession* session)
{
    ErlHeapFragment *bp;
    ErlOffHeap *off_heap;
    Uint hsz;
    Eterm *hp, list, msg;
    Eterm tags[] = {
	am_timeout,
	am_old_heap_block_size,
	am_heap_block_size,
	am_mbuf_size,
	am_stack_size,
	am_old_heap_size,
	am_heap_size
    };
    UWord values[] = {
	time,
	OLD_HEAP(p) ? OLD_HEND(p) - OLD_HEAP(p) : 0,
	HEAP_SIZE(p),
	MBUF_SIZE(p),
	STACK_START(p) - p->stop,
	OLD_HEAP(p) ? OLD_HTOP(p) - OLD_HEAP(p) : 0,
	HEAP_TOP(p) - HEAP_START(p)
    };
#ifdef DEBUG
    Eterm *hp_end;
#endif
	

    hsz = 0;
    (void) erts_bld_atom_uword_2tup_list(NULL,
					&hsz,
					sizeof(values)/sizeof(*values),
					tags,
					values);
    hsz += 5 /* 4-tuple */;

    hp = ERTS_ALLOC_SYSMSG_HEAP(hsz, &bp, &off_heap, monitor_p);

#ifdef DEBUG
    hp_end = hp + hsz;
#endif

    list = erts_bld_atom_uword_2tup_list(&hp,
					NULL,
					sizeof(values)/sizeof(*values),
					tags,
					values);
    msg = TUPLE4(hp, am_monitor, p->common.id, am_long_gc, list); 

#ifdef DEBUG
    hp += 5 /* 4-tuple */;
    ASSERT(hp == hp_end);
#endif

    enqueue_sys_msg(SYS_MSG_TYPE_SYSMON, p->common.id,
                    session->system_monitor.receiver, msg, bp, session);
}

void
monitor_long_gc(Process *p, Uint time)
{
    erts_rwmtx_rlock(&erts_trace_session_list_lock);
    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        if (time-1 > s->system_monitor.limits[ERTS_SYSMON_LONG_GC]-1) {
            monitor_long_gc_session(p, time, s);
        }
    }
    erts_rwmtx_runlock(&erts_trace_session_list_lock);
}

static void
monitor_large_heap_session(Process *p, ErtsTraceSession *session)
{
    ErlHeapFragment *bp;
    ErlOffHeap *off_heap;
    Uint hsz;
    Eterm *hp, list, msg;
    Eterm tags[] = {
	am_old_heap_block_size,
	am_heap_block_size,
	am_mbuf_size,
	am_stack_size,
	am_old_heap_size,
	am_heap_size
    };
    UWord values[] = {
	OLD_HEAP(p) ? OLD_HEND(p) - OLD_HEAP(p) : 0,
	HEAP_SIZE(p),
	MBUF_SIZE(p),
	STACK_START(p) - p->stop,
	OLD_HEAP(p) ? OLD_HTOP(p) - OLD_HEAP(p) : 0,
	HEAP_TOP(p) - HEAP_START(p)
    };
#ifdef DEBUG
    Eterm *hp_end;
#endif



    hsz = 0;
    (void) erts_bld_atom_uword_2tup_list(NULL,
					&hsz,
					sizeof(values)/sizeof(*values),
					tags,
					values);
    hsz += 5 /* 4-tuple */;

    hp = ERTS_ALLOC_SYSMSG_HEAP(hsz, &bp, &off_heap, monitor_p);

#ifdef DEBUG
    hp_end = hp + hsz;
#endif

    list = erts_bld_atom_uword_2tup_list(&hp,
					NULL,
					sizeof(values)/sizeof(*values),
					tags,
					values);
    msg = TUPLE4(hp, am_monitor, p->common.id, am_large_heap, list); 

#ifdef DEBUG
    hp += 5 /* 4-tuple */;
    ASSERT(hp == hp_end);
#endif

    enqueue_sys_msg(SYS_MSG_TYPE_SYSMON, p->common.id,
                    session->system_monitor.receiver, msg, bp, session);
}

void
monitor_large_heap(Process *p, Uint size)
{
    erts_rwmtx_rlock(&erts_trace_session_list_lock);
    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        if (size-1 > s->system_monitor.limits[ERTS_SYSMON_LARGE_HEAP]-1) {
            monitor_large_heap_session(p, s);
        }
    }
    erts_rwmtx_runlock(&erts_trace_session_list_lock);
}

static void
monitor_generic(Process *p, Eterm type, Eterm spec, ErtsTraceSession *session)
{
    ErlHeapFragment *bp;
    ErlOffHeap *off_heap;
    Eterm *hp, msg;


    hp = ERTS_ALLOC_SYSMSG_HEAP(5, &bp, &off_heap, monitor_p);

    msg = TUPLE4(hp, am_monitor, p->common.id, type, spec); 
    hp += 5;

    enqueue_sys_msg(SYS_MSG_TYPE_SYSMON, p->common.id,
                    session->system_monitor.receiver, msg, bp, session);
}

/*
 * ERTS_PSD_SYSMON_MSGQ_LEN_LOW
 * A trace session where this process have reached the upper msgq limit
 * and is "on its way down" to the lower limit.
 */
typedef struct ErtsSysMonMsgqLow {
    struct ErtsSysMonMsgqLow *next;
    struct ErtsSysMonMsgqLow *prev;
    Eterm session_weak_id;
} ErtsSysMonMsgqLow;

static ErtsSysMonMsgqLow*
get_msgq_low_session(Process *p, ErtsTraceSession *session)
{
    ErtsSysMonMsgqLow *that =
        (ErtsSysMonMsgqLow*) erts_psd_get(p, ERTS_PSD_SYSMON_MSGQ_LEN_LOW);

    ASSERT(!!that == !!(p->sig_qs.flags & FS_MON_MSGQ_LEN_LOW));

    while (that) {
        if (that->session_weak_id == session->weak_id) {
            return that;
        }
        that = that->next;
    }
    return NULL;
}

static void
add_msgq_low_session(Process *p, ErtsTraceSession *session)
{
    ErtsSysMonMsgqLow *thiz = erts_alloc(ERTS_ALC_T_HEAP_FRAG,  // ToDo type?
                                         sizeof(ErtsSysMonMsgqLow));
    ErtsSysMonMsgqLow *was_first;

    thiz->session_weak_id = session->weak_id;
    was_first = erts_psd_set(p, ERTS_PSD_SYSMON_MSGQ_LEN_LOW, thiz);
    ASSERT(!was_first || !was_first->prev);

    thiz->next = was_first;
    thiz->prev = NULL;
    if (was_first) {
        was_first->prev = thiz;
    }

    p->sig_qs.flags |= FS_MON_MSGQ_LEN_LOW;
}

static void
remove_msgq_low_session(Process *p, ErtsSysMonMsgqLow *thiz)
{
    ErtsSysMonMsgqLow *was_first;

    if (thiz->prev) {
        thiz->prev->next = thiz->next;
#ifdef DEBUG
        was_first = erts_psd_get(p, ERTS_PSD_SYSMON_MSGQ_LEN_LOW);
        ASSERT(was_first && was_first != thiz);
#endif
    }
    else {
        was_first = erts_psd_set(p, ERTS_PSD_SYSMON_MSGQ_LEN_LOW, thiz->next);
        ASSERT(was_first == thiz); (void)was_first;
        if (!thiz->next) {
            p->sig_qs.flags &= ~FS_MON_MSGQ_LEN_LOW;
        }
    }
    if (thiz->next) {
        thiz->next->prev = thiz->prev;
    }
    erts_free(ERTS_ALC_T_HEAP_FRAG, thiz);  // ToDo type?
}

void
erts_clear_all_msgq_low_sessions(Process *p)
{
    ErtsSysMonMsgqLow *that, *next;

    that = erts_psd_set(p, ERTS_PSD_SYSMON_MSGQ_LEN_LOW, NULL);
    while (that) {
        next = that->next;
        erts_free(ERTS_ALC_T_HEAP_FRAG, that);  // ToDo type?
        that = next;
    }
    p->sig_qs.flags &= ~FS_MON_MSGQ_LEN_LOW;
}

void
erts_consolidate_all_msgq_low_sessions(Process *p)
{
    ErtsSysMonMsgqLow *that, *next;
    ErtsTraceSession *s;

    that = (ErtsSysMonMsgqLow*) erts_psd_get(p, ERTS_PSD_SYSMON_MSGQ_LEN_LOW);
    while (that) {
        next = that->next;

        erts_rwmtx_rlock(&erts_trace_session_list_lock);
        for (s = &erts_trace_session_0; s; s = s->next) {
            if (s->weak_id == that->session_weak_id) {
                if (s->system_monitor.long_msgq_off < 0) {
                    s = NULL;
                }
                break;
            }
        }
        erts_rwmtx_runlock(&erts_trace_session_list_lock);
        if (!s) {
            remove_msgq_low_session(p, that);
        }
        that = next;
    }
}

void
monitor_long_msgq_on(Process *p)
{
    p->sig_qs.flags &= ~FS_MON_MSGQ_LEN_HIGH;

    erts_rwmtx_rlock(&erts_trace_session_list_lock);
    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        if (s->system_monitor.limits[ERTS_SYSMON_LONG_MSGQ]) {
            ErtsSysMonMsgqLow *low = get_msgq_low_session(p, s);

            if (!low) {
                if (p->sig_qs.mq_len >= s->system_monitor.limits[ERTS_SYSMON_LONG_MSGQ]) {
                    monitor_generic(p, am_long_message_queue, am_true, s);
                    add_msgq_low_session(p, s);
                }
                else {
                    /* still a session with a limit we have not reached */
                    p->sig_qs.flags |= FS_MON_MSGQ_LEN_HIGH;
                }
            }
            /* else we have already reached the upper limit for this session */
        }
    }
    erts_rwmtx_runlock(&erts_trace_session_list_lock);
}

void
monitor_long_msgq_off(Process *p)
{
    ASSERT(p->sig_qs.flags & FS_MON_MSGQ_LEN_LOW);

    erts_rwmtx_rlock(&erts_trace_session_list_lock);
    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        ErtsSysMonMsgqLow *low = get_msgq_low_session(p, s);

        if (low) {
            if (p->sig_qs.mq_len <= s->system_monitor.long_msgq_off) {
                monitor_generic(p, am_long_message_queue, am_false, s);
                remove_msgq_low_session(p, low);
                p->sig_qs.flags |= FS_MON_MSGQ_LEN_HIGH;
            }
            else if (s->system_monitor.long_msgq_off < 0) {
                /* disabled */
                remove_msgq_low_session(p, low);
            }

        }
        /* else we have not reached the upper limit for this session */
    }
    erts_rwmtx_runlock(&erts_trace_session_list_lock);
}

void
monitor_busy_port(Process *p, Eterm spec)
{
    erts_rwmtx_rlock(&erts_trace_session_list_lock);
    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        if (s->system_monitor.flags.busy_port) {
            monitor_generic(p, am_busy_port, spec, s);
        }
    }
    erts_rwmtx_runlock(&erts_trace_session_list_lock);
}

void
monitor_busy_dist_port(Process *p, Eterm spec)
{
    erts_rwmtx_rlock(&erts_trace_session_list_lock);
    for (ErtsTraceSession *s = &erts_trace_session_0; s; s = s->next) {
        if (s->system_monitor.flags.busy_dist_port) {
            monitor_generic(p, am_busy_dist_port, spec, s);
        }
    }
    erts_rwmtx_runlock(&erts_trace_session_list_lock);
}

/* Begin system_profile tracing */
/* Scheduler profiling */

void
profile_scheduler(Eterm scheduler_id, Eterm state) {
    Eterm *hp, msg;
    ErlHeapFragment *bp = NULL;

    Uint hsz;

    hsz = 7 + patch_ts_size(erts_system_profile_ts_type)-1;
	
    bp = new_message_buffer(hsz);
    hp = bp->mem;

    erts_mtx_lock(&smq_mtx);

    switch (state) {
    case am_active:
	active_sched++;
	break;
    case am_inactive:
	active_sched--;
	break;
    default:
	ASSERT(!"Invalid state");
	break;
    }

    msg = TUPLE6(hp, am_profile, am_scheduler, scheduler_id,
		 state, make_small(active_sched),
		 NIL /* Will be overwritten by timestamp */);
    hp += 7;

    /* Write timestamp in element 6 of the 'msg' tuple */
    hp[-1] = write_ts(erts_system_profile_ts_type, hp, bp, NULL);

    enqueue_sys_msg_unlocked(SYS_MSG_TYPE_SYSPROF, NIL, NIL, msg, bp, NULL);
    erts_mtx_unlock(&smq_mtx);

}

/* Port profiling */

void
trace_port_open(Port *p, Eterm calling_pid, Eterm drv_name) {
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    ERTS_CHK_NO_PROC_LOCKS;

    for (ref = p->common.tracee.first_ref; ref; ref = next_ref) {
        ErtsTracerNif *tnif = NULL;

        next_ref = ref->next;
        if (IS_SESSION_TRACED_FL(ref, F_TRACE_PORTS)
            && is_tracer_ref_enabled(NULL, 0, &p->common, ref, &tnif,
                                     TRACE_FUN_E_PORTS, am_open)) {

            send_to_tracer_nif(NULL, &p->common, ref, p->common.id, tnif,
                               TRACE_FUN_T_PORTS, am_open, calling_pid,
                               drv_name, am_true);
        }
    }
    ERTS_ASSERT_TRACER_REFS(&p->common);
}

/* Sends trace message:
 *    {trace_ts, PortPid, What, Data, Timestamp}
 * or {trace, PortPid, What, Data}
 *
 * 'what' must be atomic, 'data' must be atomic.
 * 't_p' is the traced port.
 */
void
trace_port(Port *t_p, Eterm what, Eterm data, Uint32 trace_flag) {

    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    ERTS_LC_ASSERT(erts_lc_is_port_locked(t_p)
		       || erts_thr_progress_is_blocking());
    ERTS_CHK_NO_PROC_LOCKS;
    ASSERT(!(trace_flag & (trace_flag-1)));

    for (ref = t_p->common.tracee.first_ref; ref; ref = next_ref) {
        ErtsTracerNif *tnif = NULL;

        next_ref = ref->next;
        if (IS_SESSION_TRACED_FL(ref, trace_flag)
            && is_tracer_ref_enabled(NULL, 0, &t_p->common, ref, &tnif,
                                     TRACE_FUN_E_PORTS, what)) {

            send_to_tracer_nif(NULL, &t_p->common, ref, t_p->common.id, tnif,
                               TRACE_FUN_T_PORTS, what, data, THE_NON_VALUE,
                               am_true);
        }
    }
    ERTS_ASSERT_TRACER_REFS(&t_p->common);
}


static Eterm
trace_port_tmp_binary(char *bin, Sint sz, Binary **bptrp, Eterm **hpp)
{
    Uint size_in_bits = NBITS(sz);

    if (size_in_bits <= ERL_ONHEAP_BITS_LIMIT) {
        Eterm result = HEAP_BITSTRING(*hpp, bin, 0, size_in_bits);
        *hpp += heap_bits_size(size_in_bits);
        return result;
    } else {
        ErlOffHeap dummy_oh = {0};
        Binary *refc_binary;

        refc_binary = erts_bin_nrml_alloc(sz);

        sys_memcpy(refc_binary->orig_bytes, bin, sz);
        *bptrp = refc_binary;

        return erts_wrap_refc_bitstring(&dummy_oh.first,
                                        &dummy_oh.overhead,
                                        hpp,
                                        refc_binary,
                                        (byte*)refc_binary->orig_bytes,
                                        0,
                                        size_in_bits);
    }
}

static void
trace_port_session_receive(Port *t_p, ErtsTracerRef*, Eterm caller,
                           Eterm what, va_list args);

/* Sends trace message:
 *    {trace, PortPid, 'receive', {pid(), {command, iolist()}}}
 *    {trace, PortPid, 'receive', {pid(), {control, pid()}}}
 *    {trace, PortPid, 'receive', {pid(), exit}}
 *
 */
void
trace_port_receive(Port *t_p, Eterm caller, Eterm what, ...)
{
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    ERTS_LC_ASSERT(erts_lc_is_port_locked(t_p)
                   || erts_thr_progress_is_blocking());
    ERTS_CHK_NO_PROC_LOCKS;

    for (ref = t_p->common.tracee.first_ref; ref; ref = next_ref) {
        next_ref = ref->next;
        if (IS_SESSION_TRACED_FL(ref, F_TRACE_RECEIVE)) {
            va_list args;
            va_start(args, what);
            trace_port_session_receive(t_p, ref, caller, what, args);
            va_end(args);
        }
    }
    ERTS_ASSERT_TRACER_REFS(&t_p->common);
}

static void
trace_port_session_receive(Port *t_p, ErtsTracerRef *ref,
                           Eterm caller, Eterm what, va_list args)
{
    ErtsTracerNif *tnif = NULL;

    if (is_tracer_ref_enabled(NULL, 0, &t_p->common, ref, &tnif,
                              TRACE_FUN_E_RECEIVE, am_receive)) {
        /* We can use a stack heap here, as the nif is called in the
           context of a port */
        enum { LOCAL_HEAP_SIZE = 3 + 3 + 3 + MAX(heap_bits_size(ERL_ONHEAP_BITS_LIMIT), ERL_REFC_BITS_SIZE) };
        Eterm local_heap[LOCAL_HEAP_SIZE];

        Eterm *hp, data, *orig_hp = NULL;
        Binary *bptr = NULL;
        hp = local_heap;

        if (what == am_close) {
            data = what;
        } else {
            Eterm arg;
            if (what == am_command) {
                char *bin = va_arg(args, char *);
                Sint sz = va_arg(args, Sint);
                arg = trace_port_tmp_binary(bin, sz, &bptr, &hp);
            } else if (what == am_call || what == am_control) {
                unsigned int command = va_arg(args, unsigned int);
                char *bin = va_arg(args, char *);
                Sint sz = va_arg(args, Sint);
                Eterm cmd;
                arg = trace_port_tmp_binary(bin, sz, &bptr, &hp);
#if defined(ARCH_32)
                if (!IS_USMALL(0, command)) {
                    *hp = make_pos_bignum_header(1);
                    BIG_DIGIT(hp, 0) = (Uint)command;
                    cmd = make_big(hp);
                    hp += 2;
                } else
#endif
                {
                    cmd = make_small((Sint)command);
                }
                arg = TUPLE2(hp, cmd, arg);
                hp += 3;
            } else if (what == am_commandv) {
                ErlIOVec *evp = va_arg(args, ErlIOVec*);
                int i;
                if ((6 + evp->vsize * (2+ERL_REFC_BITS_SIZE)) > LOCAL_HEAP_SIZE) {
                    hp = erts_alloc(ERTS_ALC_T_TMP,
                                    (6 + evp->vsize * (2+ERL_REFC_BITS_SIZE)) * sizeof(Eterm));
                    orig_hp = hp;
                }
                arg = NIL;
                /* Convert each element in the ErlIOVec to a sub bin that points
                   to a procbin. We don't have to increment the proc bin refc as
                   the port task keeps the reference alive. */
                for (i = evp->vsize-1; i >= 0; i--) {
                    if (evp->iov[i].iov_len) {
                        ErlOffHeap dummy_oh = {0};
                        Uint byte_offset;
                        Eterm wrapped;
                        Binary *bin;

                        bin = ErlDrvBinary2Binary(evp->binv[i]);

                        ASSERT((char*)evp->iov[i].iov_base >= bin->orig_bytes);
                        byte_offset =
                            (char*)evp->iov[i].iov_base - bin->orig_bytes;

                        wrapped =
                            erts_wrap_refc_bitstring(&dummy_oh.first,
                                                     &dummy_oh.overhead,
                                                     &hp,
                                                     bin,
                                                     (byte*)bin->orig_bytes,
                                                     NBITS(byte_offset),
                                                     NBITS(evp->iov[i].iov_len));

                        arg = CONS(hp, wrapped, arg);
                        hp += 2;
                    }
                }
                what = am_command;
            } else {
                arg = va_arg(args, Eterm);
            }
            data = TUPLE2(hp, what, arg);
            hp += 3;
        }

        data = TUPLE2(hp, caller, data);
        hp += 3;
        ASSERT(hp <= (local_heap + LOCAL_HEAP_SIZE) || orig_hp);
        send_to_tracer_nif(NULL, &t_p->common, ref, t_p->common.id, tnif,
                           TRACE_FUN_T_RECEIVE,
                           am_receive, data, THE_NON_VALUE, am_true);

        if (bptr)
            erts_bin_release(bptr);

        if (orig_hp)
            erts_free(ERTS_ALC_T_TMP, orig_hp);
    }
}

void
trace_port_send(Port *t_p, Eterm receiver, Eterm msg, int exists)
{
    const ErtsBpIndex bp_ix = erts_active_bp_ix();
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;
    Eterm op = exists ? am_send : am_send_to_non_existing_process;
    ERTS_LC_ASSERT(erts_lc_is_port_locked(t_p)
		       || erts_thr_progress_is_blocking());
    ERTS_CHK_NO_PROC_LOCKS;

    for (ref = t_p->common.tracee.first_ref; ref; ref = next_ref) {
        ErtsTracerNif *tnif = NULL;

        next_ref = ref->next;
        if (ref->session->send_tracing[bp_ix].on
            && IS_SESSION_TRACED_FL(ref, F_TRACE_SEND)
            && is_tracer_ref_enabled(NULL, 0, &t_p->common, ref, &tnif,
                                     TRACE_FUN_E_SEND, op)) {

            send_to_tracer_nif(NULL, &t_p->common, ref, t_p->common.id, tnif,
                               TRACE_FUN_T_SEND, op, msg, receiver, am_true);
        }
    }
    ERTS_ASSERT_TRACER_REFS(&t_p->common);
}

void trace_port_send_binary(Port *t_p, Eterm to, Eterm what, char *bin, Sint sz)
{
    const ErtsBpIndex bp_ix = erts_active_bp_ix();
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    ERTS_LC_ASSERT(erts_lc_is_port_locked(t_p)
		       || erts_thr_progress_is_blocking());
    ERTS_CHK_NO_PROC_LOCKS;

    for (ref = t_p->common.tracee.first_ref; ref; ref = next_ref) {
        ErtsTracerNif *tnif = NULL;

        next_ref = ref->next;
        if (ref->session->send_tracing[bp_ix].on
            && IS_SESSION_TRACED_FL(ref, F_TRACE_SEND)
            && is_tracer_ref_enabled(NULL, 0, &t_p->common, ref, &tnif,
                                     TRACE_FUN_E_SEND, am_send)) {

            Eterm msg;
            Binary* bptr = NULL;
            Eterm local_heap[3 + 3 + MAX(heap_bits_size(ERL_ONHEAP_BITS_LIMIT), ERL_REFC_BITS_SIZE)];
            Eterm *hp;

            hp = local_heap;

            msg = trace_port_tmp_binary(bin, sz, &bptr, &hp);

            msg = TUPLE2(hp, what, msg);
            hp += 3;
            msg = TUPLE2(hp, t_p->common.id, msg);
            hp += 3;

            send_to_tracer_nif(NULL, &t_p->common, ref, t_p->common.id, tnif,
                               TRACE_FUN_T_SEND, am_send, msg, to, am_true);
            if (bptr)
                erts_bin_release(bptr);

        }
    }
    ERTS_ASSERT_TRACER_REFS(&t_p->common);
}

/* Send {trace_ts, Pid, What, {Mod, Func, Arity}, Timestamp}
 * or   {trace, Pid, What, {Mod, Func, Arity}}
 *
 * where 'What' is supposed to be 'in' or 'out' and
 * where 'where' is supposed to be location (callback) 
 * for the port.
 */

void
trace_sched_ports(Port *p, Eterm what) {
    trace_sched_ports_where(p, what, make_small(0));
}

void
trace_sched_ports_where(Port *t_p, Eterm what, Eterm where) {
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    ERTS_LC_ASSERT(erts_lc_is_port_locked(t_p)
		       || erts_thr_progress_is_blocking());
    ERTS_CHK_NO_PROC_LOCKS;

    for (ref = t_p->common.tracee.first_ref; ref; ref = next_ref) {
        ErtsTracerNif *tnif = NULL;

        next_ref = ref->next;
        if (IS_SESSION_TRACED_FL(ref, F_TRACE_SCHED_PORTS)
            && is_tracer_ref_enabled(NULL, 0, &t_p->common, ref, &tnif,
                                     TRACE_FUN_E_SCHED_PORT, what)) {
            send_to_tracer_nif(NULL, &t_p->common, ref, t_p->common.id,
                               tnif, TRACE_FUN_T_SCHED_PORT,
                               what, where, THE_NON_VALUE, am_true);
        }
    }
    ERTS_ASSERT_TRACER_REFS(&t_p->common);
}

/* Port profiling */

void
profile_runnable_port(Port *p, Eterm status) {
    Eterm *hp, msg;
    ErlHeapFragment *bp = NULL;
    Eterm count = make_small(0);

    Uint hsz;

    hsz = 6 + patch_ts_size(erts_system_profile_ts_type)-1;

    bp = new_message_buffer(hsz);
    hp = bp->mem;

    erts_mtx_lock(&smq_mtx);

    msg = TUPLE5(hp, am_profile, p->common.id, status, count,
		 NIL /* Will be overwritten by timestamp */);
    hp += 6;

    /* Write timestamp in element 5 of the 'msg' tuple */
    hp[-1] = write_ts(erts_system_profile_ts_type, hp, bp, NULL);

    enqueue_sys_msg_unlocked(SYS_MSG_TYPE_SYSPROF, p->common.id, NIL, msg, bp, NULL);
    erts_mtx_unlock(&smq_mtx);
}

/* Process profiling */
void 
profile_runnable_proc(Process *p, Eterm status){
    Eterm *hp, msg;
    Eterm where = am_undefined;
    ErlHeapFragment *bp = NULL;
    const ErtsCodeMFA *cmfa = NULL;

    ErtsThrPrgrDelayHandle dhndl;
    Uint hsz = 4 + 6 + patch_ts_size(erts_system_profile_ts_type)-1;
    /* Assumptions:
     * We possibly don't have the MAIN_LOCK for the process p here.
     * We assume that we can read from p->current and p->i atomically
     */
    dhndl = erts_thr_progress_unmanaged_delay(); /* suspend purge operations */

    if (!ERTS_PROC_IS_EXITING(p)) {
        if (p->current) {
            cmfa = p->current;
        } else {
            cmfa = erts_find_function_from_pc(p->i);
        }
    }

    if (!cmfa) {
	hsz -= 4;
    }

    bp = new_message_buffer(hsz);
    hp = bp->mem;

    if (cmfa) {
	where = TUPLE3(hp, cmfa->module, cmfa->function,
                       make_small(cmfa->arity));
        hp += 4;
    } else {
	where = make_small(0);
    }

    erts_thr_progress_unmanaged_continue(dhndl);
	
    erts_mtx_lock(&smq_mtx);

    msg = TUPLE5(hp, am_profile, p->common.id, status, where,
		 NIL /* Will be overwritten by timestamp */);
    hp += 6;

    /* Write timestamp in element 5 of the 'msg' tuple */
    hp[-1] = write_ts(erts_system_profile_ts_type, hp, bp, NULL);

    enqueue_sys_msg_unlocked(SYS_MSG_TYPE_SYSPROF, p->common.id, NIL, msg, bp, NULL);
    erts_mtx_unlock(&smq_mtx);
}
/* End system_profile tracing */




typedef struct ErtsSysMsgQ_ ErtsSysMsgQ;
struct  ErtsSysMsgQ_ {
    ErtsSysMsgQ *next;
    enum ErtsSysMsgType type;
    ErtsTraceSession *session;
    Eterm from;
    Eterm to;
    Eterm msg;
    ErlHeapFragment *bp;
};

static ErtsSysMsgQ *sys_message_queue;
static ErtsSysMsgQ *sys_message_queue_end;

static erts_tid_t sys_msg_dispatcher_tid;
static erts_cnd_t smq_cnd;

ERTS_QUALLOC_IMPL(smq_element, ErtsSysMsgQ, 20, ERTS_ALC_T_SYS_MSG_Q)

static void
enqueue_sys_msg_unlocked(enum ErtsSysMsgType type,
			 Eterm from,
			 Eterm to,
			 Eterm msg,
			 ErlHeapFragment *bp,
                         ErtsTraceSession *session)
{
    ErtsSysMsgQ *smqp;

    smqp	= smq_element_alloc();
    smqp->next	= NULL;
    smqp->type	= type;
    smqp->session = session;
    if (session) {
        erts_ref_trace_session(session);
    }
    smqp->from	= from;
    smqp->to	= to;
    smqp->msg	= msg;
    smqp->bp	= bp;

    if (sys_message_queue_end) {
	ASSERT(sys_message_queue);
	sys_message_queue_end->next = smqp;
    }
    else {
	ASSERT(!sys_message_queue);
	sys_message_queue = smqp;
    }
    sys_message_queue_end = smqp;
    erts_cnd_signal(&smq_cnd);
}

static void
enqueue_sys_msg(enum ErtsSysMsgType type,
		Eterm from,
		Eterm to,
		Eterm msg,
		ErlHeapFragment *bp,
                ErtsTraceSession *session)
{
    erts_mtx_lock(&smq_mtx);
    enqueue_sys_msg_unlocked(type, from, to, msg, bp, session);
    erts_mtx_unlock(&smq_mtx);
}

Eterm
erts_get_system_logger(void)
{
    return (Eterm)erts_atomic_read_nob(&system_logger);
}

Eterm
erts_set_system_logger(Eterm logger)
{
    if (logger != am_logger && logger != am_undefined && !is_internal_pid(logger))
        return THE_NON_VALUE;
    return (Eterm)erts_atomic_xchg_nob(&system_logger, logger);
}

void
erts_queue_error_logger_message(Eterm from, Eterm msg, ErlHeapFragment *bp)
{
    enqueue_sys_msg(SYS_MSG_TYPE_ERRLGR, from, erts_get_system_logger(), msg, bp, NULL);
}

void
erts_send_sys_msg_proc(Eterm from, Eterm to, Eterm msg, ErlHeapFragment *bp)
{
    ASSERT(is_internal_pid(to));
    enqueue_sys_msg(SYS_MSG_TYPE_PROC_MSG, from, to, msg, bp, NULL);
}

#ifdef DEBUG_PRINTOUTS
static void
print_msg_type(ErtsSysMsgQ *smqp)
{
    switch (smqp->type) {
    case SYS_MSG_TYPE_SYSMON:
	erts_fprintf(stderr, "SYSMON ");
	break;
	 case SYS_MSG_TYPE_SYSPROF:
	erts_fprintf(stderr, "SYSPROF ");
	break;
    case SYS_MSG_TYPE_ERRLGR:
	erts_fprintf(stderr, "ERRLGR ");
	break;
    case SYS_MSG_TYPE_PROC_MSG:
       erts_fprintf(stderr, "PROC_MSG ");
       break;
    default:
	erts_fprintf(stderr, "??? ");
	break;
    }
}
#endif

static void
sys_msg_disp_failure(ErtsSysMsgQ *smqp, Eterm receiver)
{
    switch (smqp->type) {
    case SYS_MSG_TYPE_SYSMON:
	if (receiver == NIL
            && !smqp->session->system_monitor.limits[ERTS_SYSMON_LONG_GC]
	    && !smqp->session->system_monitor.limits[ERTS_SYSMON_LONG_SCHEDULE]
	    && !smqp->session->system_monitor.limits[ERTS_SYSMON_LARGE_HEAP]
            && !smqp->session->system_monitor.limits[ERTS_SYSMON_LONG_MSGQ]
	    && !smqp->session->system_monitor.flags.busy_port
	    && !smqp->session->system_monitor.flags.busy_dist_port)
	    break; /* Everything is disabled */
	erts_thr_progress_block();
	if (receiver == smqp->session->system_monitor.receiver
            || receiver == NIL) {
	    erts_system_monitor_clear(smqp->session);
        }
	erts_thr_progress_unblock();
	break;
    case SYS_MSG_TYPE_SYSPROF:
	if (receiver == NIL
	    && !erts_system_profile_flags.runnable_procs
	    && !erts_system_profile_flags.runnable_ports
	    && !erts_system_profile_flags.exclusive
	    && !erts_system_profile_flags.scheduler)
		 break;
	/* Block system to clear flags */
	erts_thr_progress_block();
	if (system_profile == receiver || receiver == NIL) { 
		erts_system_profile_clear(NULL);
	}
	erts_thr_progress_unblock();
	break;
    case SYS_MSG_TYPE_ERRLGR: {
	Eterm *tp;
	Eterm tag;

	if (is_not_tuple(smqp->msg)) {
	    goto unexpected_error_msg;
	}
	tp = tuple_val(smqp->msg);
	if (arityval(tp[0]) != 2) {
	    goto unexpected_error_msg;
	}
	if (is_not_tuple(tp[2])) {
	    goto unexpected_error_msg;
	}
	tp = tuple_val(tp[2]);
	if (arityval(tp[0]) != 3) {
	    goto unexpected_error_msg;
	}
	tag = tp[1];
	if (is_not_tuple(tp[3])) {
	    goto unexpected_error_msg;
	}
	tp = tuple_val(tp[3]);
	if (arityval(tp[0]) != 3) {
	    goto unexpected_error_msg;
	}
	if (is_not_list(tp[3])) {
	    goto unexpected_error_msg;
	}

        {
            static const char *no_logger = "(no logger present)";
        /* no_error_logger: */
            erts_fprintf(stderr, "%s %T: %T\n",
                         no_logger, tag, CAR(list_val(tp[3])));
            break;
        unexpected_error_msg:
            erts_fprintf(stderr,
                         "%s unexpected logger message: %T\n",
                         no_logger,
                         smqp->msg);
            break;
        }
        ASSERT(0);
    }
    case SYS_MSG_TYPE_PROC_MSG:
        break;
    default:
	ASSERT(0);
    }
}

static void
sys_msg_dispatcher_wakeup(void *vwait_p)
{
    int *wait_p = (int *) vwait_p;
    erts_mtx_lock(&smq_mtx);
    *wait_p = 0;
    erts_cnd_signal(&smq_cnd);
    erts_mtx_unlock(&smq_mtx);
}

static void
sys_msg_dispatcher_prep_wait(void *vwait_p)
{
    int *wait_p = (int *) vwait_p;
    erts_mtx_lock(&smq_mtx);
    *wait_p = 1;
    erts_mtx_unlock(&smq_mtx);
}

static void
sys_msg_dispatcher_fin_wait(void *vwait_p)
{
    int *wait_p = (int *) vwait_p;
    erts_mtx_lock(&smq_mtx);
    *wait_p = 0;
    erts_mtx_unlock(&smq_mtx);
}

static void
sys_msg_dispatcher_wait(void *vwait_p)
{
    int *wait_p = (int *) vwait_p;
    erts_mtx_lock(&smq_mtx);
    while (*wait_p)
	erts_cnd_wait(&smq_cnd, &smq_mtx);
    erts_mtx_unlock(&smq_mtx);
}

static ErtsSysMsgQ *local_sys_message_queue = NULL;

static void *
sys_msg_dispatcher_func(void *unused)
{
    ErtsThrPrgrCallbacks callbacks;
    ErtsThrPrgrData *tpd;
    int wait = 0;

#ifdef ERTS_ENABLE_LOCK_CHECK
    erts_lc_set_thread_name("system message dispatcher");
#endif

    local_sys_message_queue = NULL;

    callbacks.arg = (void *) &wait;
    callbacks.wakeup = sys_msg_dispatcher_wakeup;
    callbacks.prepare_wait = sys_msg_dispatcher_prep_wait;
    callbacks.wait = sys_msg_dispatcher_wait;
    callbacks.finalize_wait = sys_msg_dispatcher_fin_wait;

    tpd = erts_thr_progress_register_managed_thread(NULL, &callbacks, 0, 0);

    while (1) {
	int end_wait = 0;
	ErtsSysMsgQ *smqp;

	ERTS_LC_ASSERT(!erts_thr_progress_is_blocking());

	erts_mtx_lock(&smq_mtx);

	/* Free previously used queue ... */
	while (local_sys_message_queue) {
	    smqp = local_sys_message_queue;
	    local_sys_message_queue = smqp->next;
            if (smqp->session) {
                erts_deref_trace_session(smqp->session);
            }
	    smq_element_free(smqp);
	}

	/* Fetch current trace message queue ... */
	if (!sys_message_queue) {
            wait = 1;
	    erts_mtx_unlock(&smq_mtx);
	    end_wait = 1;
	    erts_thr_progress_active(tpd, 0);
	    erts_thr_progress_prepare_wait(tpd);
	    erts_mtx_lock(&smq_mtx);
	}

	while (!sys_message_queue) {
            if (wait)
                erts_cnd_wait(&smq_cnd, &smq_mtx);
            if (sys_message_queue)
                break;
            wait = 1;
	    erts_mtx_unlock(&smq_mtx);
            /*
             * Ensure thread progress continue. We might have
             * been the last thread to go to sleep. In that case
             * erts_thr_progress_finalize_wait() will take care
             * of it...
             */
	    erts_thr_progress_finalize_wait(tpd);
	    erts_thr_progress_prepare_wait(tpd);
	    erts_mtx_lock(&smq_mtx);
        }

	local_sys_message_queue = sys_message_queue;
	sys_message_queue = NULL;
	sys_message_queue_end = NULL;

	erts_mtx_unlock(&smq_mtx);

	if (end_wait) {
	    erts_thr_progress_finalize_wait(tpd);
	    erts_thr_progress_active(tpd, 1);
	}

	/* Send trace messages ... */

	ASSERT(local_sys_message_queue);

	for (smqp = local_sys_message_queue; smqp; smqp = smqp->next) {
	    Eterm receiver;
	    ErtsProcLocks proc_locks = ERTS_PROC_LOCKS_MSG_SEND;
	    Process *proc = NULL;
	    Port *port = NULL;

            ASSERT(is_value(smqp->msg));

	    if (erts_thr_progress_update(tpd))
		erts_thr_progress_leader_update(tpd);

#ifdef DEBUG_PRINTOUTS
	    print_msg_type(smqp);
#endif
	    switch (smqp->type) {
            case SYS_MSG_TYPE_PROC_MSG:
                receiver = smqp->to;
                break;
	    case SYS_MSG_TYPE_SYSMON:
                receiver = smqp->to;
		if (smqp->from == receiver) {
#ifdef DEBUG_PRINTOUTS
		    erts_fprintf(stderr, "MSG=%T to %T... ",
				 smqp->msg, receiver);
#endif
		    goto drop_sys_msg;
		}
		break;
	    case SYS_MSG_TYPE_SYSPROF:
		receiver = erts_get_system_profile();
		if (smqp->from == receiver) {
#ifdef DEBUG_PRINTOUTS
		    erts_fprintf(stderr, "MSG=%T to %T... ",
				 smqp->msg, receiver);
#endif
	   	    goto drop_sys_msg;
		}
		break;
	    case SYS_MSG_TYPE_ERRLGR:
		receiver = smqp->to;
		break;
	    default:
		receiver = NIL;
		break;
	    }

#ifdef DEBUG_PRINTOUTS
	    erts_fprintf(stderr, "MSG=%T to %T... ", smqp->msg, receiver);
#endif

	    if (is_internal_pid(receiver)) {
		proc = erts_pid2proc(NULL, 0, receiver, proc_locks);
		if (!proc) {
                    if (smqp->type == SYS_MSG_TYPE_ERRLGR) {
                        /* Bad logger process, send to kernel 'logger' process */
                        erts_set_system_logger(am_logger);
                        receiver = erts_get_system_logger();
                        goto logger;
                    } else {
                        /* Bad tracer */
                        goto failure;
                    }
		}
		else {
		    ErtsMessage *mp;
		queue_proc_msg:
		    mp = erts_alloc_message(0, NULL);
		    mp->data.heap_frag = smqp->bp;
		    erts_queue_message(proc,proc_locks,mp,smqp->msg,am_system);
#ifdef DEBUG_PRINTOUTS
		    erts_fprintf(stderr, "delivered\n");
#endif
		    erts_proc_unlock(proc, proc_locks);
		}
	    } else if (receiver == am_logger) {
            logger:
		proc = erts_whereis_process(NULL,0,am_logger,proc_locks,0);
		if (!proc)
		    goto failure;
		else if (smqp->from == proc->common.id)
		    goto drop_sys_msg;
		else
		    goto queue_proc_msg;
	    }
            else if (receiver == am_undefined) {
                goto drop_sys_msg;
	    }
            else if (is_internal_port(receiver)) {
		port = erts_thr_id2port_sflgs(receiver,
					      ERTS_PORT_SFLGS_INVALID_TRACER_LOOKUP);
		if (!port)
		    goto failure;
		else {
		    write_sys_msg_to_port(receiver,
					  port,
					  smqp->from,
					  smqp->type,
					  smqp->msg);
		    if (port->control_flags & PORT_CONTROL_FLAG_HEAVY)
			port->control_flags &= ~PORT_CONTROL_FLAG_HEAVY;
#ifdef DEBUG_PRINTOUTS
		    erts_fprintf(stderr, "delivered\n");
#endif
		    erts_thr_port_release(port);
		    if (smqp->bp)
			free_message_buffer(smqp->bp);
		}
	    }
	    else {
	    failure:
		sys_msg_disp_failure(smqp, receiver);
	    drop_sys_msg:
		if (proc)
		    erts_proc_unlock(proc, proc_locks);
		if (smqp->bp)
		    free_message_buffer(smqp->bp);
#ifdef DEBUG_PRINTOUTS
		erts_fprintf(stderr, "dropped\n");
#endif
	    }
            smqp->msg = THE_NON_VALUE;
	}
    }

    return NULL;
}

void
erts_debug_foreach_sys_msg_in_q(void (*func)(Eterm,
                                             Eterm,
                                             Eterm,
                                             ErlHeapFragment *))
{
    ErtsSysMsgQ *smq[] = {sys_message_queue, local_sys_message_queue};
    int i;

    ERTS_LC_ASSERT(erts_thr_progress_is_blocking());

    for (i = 0; i < sizeof(smq)/sizeof(smq[0]); i++) {
        ErtsSysMsgQ *sm;
        for (sm = smq[i]; sm; sm = sm->next) {
            Eterm to;
            switch (sm->type) {
            case SYS_MSG_TYPE_SYSMON:
                to = erts_get_system_monitor(sm->session);
                break;
            case SYS_MSG_TYPE_SYSPROF:
                to = erts_get_system_profile();
                break;
            case SYS_MSG_TYPE_ERRLGR:
                to = erts_get_system_logger();
                break;
            default:
                to = NIL;
                break;
            }
            if (is_value(sm->msg))
                (*func)(sm->from, to, sm->msg, sm->bp);
        }
    }
}


static void
init_sys_msg_dispatcher(void)
{
    erts_thr_opts_t thr_opts = ERTS_THR_OPTS_DEFAULT_INITER;
    thr_opts.detached = 1;
    thr_opts.name = "erts_smsg_disp";
    init_smq_element_alloc();
    sys_message_queue = NULL;
    sys_message_queue_end = NULL;
    erts_cnd_init(&smq_cnd);
    erts_mtx_init(&smq_mtx, "sys_msg_q", NIL,
        ERTS_LOCK_FLAGS_PROPERTY_STATIC | ERTS_LOCK_FLAGS_CATEGORY_DEBUG);
    erts_thr_create(&sys_msg_dispatcher_tid,
			sys_msg_dispatcher_func,
			NULL,
			&thr_opts);
}


#include "erl_nif.h"

typedef struct {
    char *name;
    Uint arity;
    ErlNifFunc *cb;
} ErtsTracerType;

struct ErtsTracerNif_ {
    HashBucket hb;
    Eterm module;
    struct erl_module_nif* nif_mod;
    ErtsTracerType tracers[NIF_TRACER_TYPES];
};

static void init_tracer_template(ErtsTracerNif *tnif) {

    /* default tracer functions */
    tnif->tracers[TRACE_FUN_DEFAULT].name  = "trace";
    tnif->tracers[TRACE_FUN_DEFAULT].arity = 5;
    tnif->tracers[TRACE_FUN_DEFAULT].cb    = NULL;

    tnif->tracers[TRACE_FUN_ENABLED].name  = "enabled";
    tnif->tracers[TRACE_FUN_ENABLED].arity = 3;
    tnif->tracers[TRACE_FUN_ENABLED].cb    = NULL;

    /* specific tracer functions */
    tnif->tracers[TRACE_FUN_T_SEND].name  = "trace_send";
    tnif->tracers[TRACE_FUN_T_SEND].arity = 5;
    tnif->tracers[TRACE_FUN_T_SEND].cb    = NULL;

    tnif->tracers[TRACE_FUN_T_RECEIVE].name  = "trace_receive";
    tnif->tracers[TRACE_FUN_T_RECEIVE].arity = 5;
    tnif->tracers[TRACE_FUN_T_RECEIVE].cb    = NULL;

    tnif->tracers[TRACE_FUN_T_CALL].name  = "trace_call";
    tnif->tracers[TRACE_FUN_T_CALL].arity = 5;
    tnif->tracers[TRACE_FUN_T_CALL].cb    = NULL;

    tnif->tracers[TRACE_FUN_T_SCHED_PROC].name  = "trace_running_procs";
    tnif->tracers[TRACE_FUN_T_SCHED_PROC].arity = 5;
    tnif->tracers[TRACE_FUN_T_SCHED_PROC].cb    = NULL;

    tnif->tracers[TRACE_FUN_T_SCHED_PORT].name  = "trace_running_ports";
    tnif->tracers[TRACE_FUN_T_SCHED_PORT].arity = 5;
    tnif->tracers[TRACE_FUN_T_SCHED_PORT].cb    = NULL;

    tnif->tracers[TRACE_FUN_T_GC].name  = "trace_garbage_collection";
    tnif->tracers[TRACE_FUN_T_GC].arity = 5;
    tnif->tracers[TRACE_FUN_T_GC].cb    = NULL;

    tnif->tracers[TRACE_FUN_T_PROCS].name  = "trace_procs";
    tnif->tracers[TRACE_FUN_T_PROCS].arity = 5;
    tnif->tracers[TRACE_FUN_T_PROCS].cb    = NULL;

    tnif->tracers[TRACE_FUN_T_PORTS].name  = "trace_ports";
    tnif->tracers[TRACE_FUN_T_PORTS].arity = 5;
    tnif->tracers[TRACE_FUN_T_PORTS].cb    = NULL;

    /* specific enabled functions */
    tnif->tracers[TRACE_FUN_E_SEND].name  = "enabled_send";
    tnif->tracers[TRACE_FUN_E_SEND].arity = 3;
    tnif->tracers[TRACE_FUN_E_SEND].cb    = NULL;

    tnif->tracers[TRACE_FUN_E_RECEIVE].name  = "enabled_receive";
    tnif->tracers[TRACE_FUN_E_RECEIVE].arity = 3;
    tnif->tracers[TRACE_FUN_E_RECEIVE].cb    = NULL;

    tnif->tracers[TRACE_FUN_E_CALL].name  = "enabled_call";
    tnif->tracers[TRACE_FUN_E_CALL].arity = 3;
    tnif->tracers[TRACE_FUN_E_CALL].cb    = NULL;

    tnif->tracers[TRACE_FUN_E_SCHED_PROC].name  = "enabled_running_procs";
    tnif->tracers[TRACE_FUN_E_SCHED_PROC].arity = 3;
    tnif->tracers[TRACE_FUN_E_SCHED_PROC].cb    = NULL;

    tnif->tracers[TRACE_FUN_E_SCHED_PORT].name  = "enabled_running_ports";
    tnif->tracers[TRACE_FUN_E_SCHED_PORT].arity = 3;
    tnif->tracers[TRACE_FUN_E_SCHED_PORT].cb    = NULL;

    tnif->tracers[TRACE_FUN_E_GC].name  = "enabled_garbage_collection";
    tnif->tracers[TRACE_FUN_E_GC].arity = 3;
    tnif->tracers[TRACE_FUN_E_GC].cb    = NULL;

    tnif->tracers[TRACE_FUN_E_PROCS].name  = "enabled_procs";
    tnif->tracers[TRACE_FUN_E_PROCS].arity = 3;
    tnif->tracers[TRACE_FUN_E_PROCS].cb    = NULL;

    tnif->tracers[TRACE_FUN_E_PORTS].name  = "enabled_ports";
    tnif->tracers[TRACE_FUN_E_PORTS].arity = 3;
    tnif->tracers[TRACE_FUN_E_PORTS].cb    = NULL;
}

static Hash *tracer_hash = NULL;
static erts_rwmtx_t tracer_mtx;

static ErtsTracerNif *
load_tracer_nif(const ErtsTracer tracer)
{
    Module* mod = erts_get_module(ERTS_TRACER_MODULE(tracer),
                                  erts_active_code_ix());
    struct erl_module_instance *instance;
    ErlNifFunc *funcs;
    int num_of_funcs;
    ErtsTracerNif tnif_tmpl, *tnif;
    ErtsTracerType *tracers;
    int i,j;

    if (!mod || !mod->curr.nif) {
        return NULL;
    }

    instance = &mod->curr;

    init_tracer_template(&tnif_tmpl);
    tnif_tmpl.nif_mod = instance->nif;
    tnif_tmpl.module = ERTS_TRACER_MODULE(tracer);
    tracers = tnif_tmpl.tracers;

    num_of_funcs = erts_nif_get_funcs(instance->nif, &funcs);

    for(i = 0; i < num_of_funcs; i++) {
        for (j = 0; j < NIF_TRACER_TYPES; j++) {
            if (sys_strcmp(tracers[j].name, funcs[i].name) == 0 && tracers[j].arity == funcs[i].arity) {
                tracers[j].cb = &(funcs[i]);
                break;
            }
        }
    }

    if (tracers[TRACE_FUN_DEFAULT].cb == NULL || tracers[TRACE_FUN_ENABLED].cb == NULL ) {
        return NULL;
    }

    erts_rwmtx_rwlock(&tracer_mtx);
    tnif = hash_put(tracer_hash, &tnif_tmpl);
    erts_rwmtx_rwunlock(&tracer_mtx);

    return tnif;
}

static ERTS_INLINE ErtsTracerNif *
lookup_tracer_nif(const ErtsTracer tracer)
{
    ErtsTracerNif tnif_tmpl;
    ErtsTracerNif *tnif;
    if (tracer == erts_tracer_nil) {
        return NULL;
    }
    tnif_tmpl.module = ERTS_TRACER_MODULE(tracer);
    ERTS_LC_ASSERT(erts_thr_progress_lc_is_delaying() || erts_get_scheduler_id() > 0);
    erts_rwmtx_rlock(&tracer_mtx);
    if ((tnif = hash_get(tracer_hash, &tnif_tmpl)) == NULL) {
        erts_rwmtx_runlock(&tracer_mtx);
        tnif = load_tracer_nif(tracer);
        ASSERT(!tnif || tnif->nif_mod);
        return tnif;
    }
    erts_rwmtx_runlock(&tracer_mtx);
    ASSERT(tnif->nif_mod);
    return tnif;
}

/* This function converts an Erlang tracer term to ErtsTracer.
   It returns THE_NON_VALUE if an invalid tracer term was given.
   Accepted input is:
     pid() || port() || {prefix, pid()} || {prefix, port()} ||
     {prefix, atom(), term()} || {atom(), term()}
 */
ErtsTracer
erts_term_to_tracer(Eterm prefix, Eterm t)
{
    ErtsTracer tracer = erts_tracer_nil;
    ASSERT(is_atom(prefix) || prefix == THE_NON_VALUE);

    if (is_internal_pid(t)) {
        tracer = t;
    }
    else if (!is_nil(t)) {
        Eterm module = am_erl_tracer, state = THE_NON_VALUE;
        Eterm hp[2];
        if (is_tuple(t)) {
            Eterm *tp = tuple_val(t);
            if (prefix != THE_NON_VALUE) {
                if (arityval(tp[0]) == 2 && tp[1] == prefix)
                    t = tp[2];
                else if (arityval(tp[0]) == 3 && tp[1] == prefix && is_atom(tp[2])) {
                    module = tp[2];
                    state = tp[3];
                }
            } else {
                if (arityval(tp[0]) == 2 && is_atom(tp[1])) {
                    module = tp[1];
                    state = tp[2];
                }
            }
        }
        if (state == THE_NON_VALUE && (is_internal_pid(t) || is_internal_port(t)))
            state = t;
        if (state == THE_NON_VALUE)
            return THE_NON_VALUE;
        erts_tracer_update(&tracer, CONS(hp, module, state));
    }
    if (!lookup_tracer_nif(tracer)) {
        ASSERT(ERTS_TRACER_MODULE(tracer) != am_erl_tracer);
        ERTS_TRACER_CLEAR(&tracer);
        return THE_NON_VALUE;
    }
    return tracer;
}

Eterm
erts_tracer_to_term(Process *p, ErtsTracer tracer)
{
    if (ERTS_TRACER_IS_NIL(tracer))
        return am_false;
    if (ERTS_TRACER_MODULE(tracer) == am_erl_tracer)
        /* Have to manage these specifically in order to be
           backwards compatible */
        return ERTS_TRACER_STATE(tracer);
    else {
        Eterm *hp = HAlloc(p, 3);
        return TUPLE2(hp, ERTS_TRACER_MODULE(tracer),
                      copy_object(ERTS_TRACER_STATE(tracer), p));
    }
}

Eterm
erts_build_tracer_to_term(Eterm **hpp, ErlOffHeap *ohp, Uint *szp, ErtsTracer tracer)
{
    Eterm res;
    Eterm state;
    Uint sz;

    if (ERTS_TRACER_IS_NIL(tracer))
        return am_false;

    state = ERTS_TRACER_STATE(tracer);
    sz = is_immed(state) ? 0 : size_object(state);

    if (szp)
        *szp += sz;

    if (hpp)
        res = is_immed(state) ? state : copy_struct(state, sz, hpp, ohp);
    else
        res = THE_NON_VALUE;

    if (ERTS_TRACER_MODULE(tracer) != am_erl_tracer) {
        if (szp)
            *szp += 3;
        if (hpp) {
            res = TUPLE2(*hpp, ERTS_TRACER_MODULE(tracer), res);
            *hpp += 3;
        }
    }

    return res;
}

static ERTS_INLINE int
send_to_tracer_nif_raw(Process *c_p, Process *tracee,
                       const ErtsTracer tracer, Uint tracee_flags,
                       Eterm t_p_id, ErtsTracerNif *tnif,
                       enum ErtsTracerOpt topt,
                       Eterm tag, Eterm msg, Eterm extra, Eterm pam_result)
{
    if (tnif || (tnif = lookup_tracer_nif(tracer)) != NULL) {
#define MAP_SIZE 4
        Eterm argv[5], local_heap[3+MAP_SIZE /* values */ + (MAP_SIZE+1 /* keys */)];
        flatmap_t *map = (flatmap_t*)(local_heap+(MAP_SIZE+1));
        Eterm *map_values = flatmap_get_values(map);
        Eterm *map_keys = local_heap + 1;
        Uint map_elem_count = 0;

        topt = (tnif->tracers[topt].cb) ? topt : TRACE_FUN_DEFAULT;
        ASSERT(topt < NIF_TRACER_TYPES);

        argv[0] = tag;
        argv[1] = ERTS_TRACER_STATE(tracer);
        argv[2] = t_p_id;
        argv[3] = msg;
        argv[4] = make_flatmap(map);

        map->thing_word = MAP_HEADER_FLATMAP;

        if (extra != THE_NON_VALUE) {
            map_keys[map_elem_count] = am_extra;
            map_values[map_elem_count++] = extra;
        }

        if (pam_result != am_true) {
            map_keys[map_elem_count] = am_match_spec_result;
            map_values[map_elem_count++] = pam_result;
        }

        if (tracee_flags & F_TRACE_SCHED_NO) {
            map_keys[map_elem_count] = am_scheduler_id;
            map_values[map_elem_count++] = make_small(erts_get_scheduler_id());
        }
        map_keys[map_elem_count] = am_timestamp;
        if (tracee_flags & F_NOW_TS)
#ifdef HAVE_ERTS_NOW_CPU
            if (erts_cpu_timestamp)
                map_values[map_elem_count++] = am_cpu_timestamp;
            else
#endif
                map_values[map_elem_count++] = am_timestamp;
        else if (tracee_flags & F_STRICT_MON_TS)
            map_values[map_elem_count++] = am_strict_monotonic;
        else if (tracee_flags & F_MON_TS)
            map_values[map_elem_count++] = am_monotonic;

        map->size = map_elem_count;
        if (map_elem_count == 0) {
            map->keys = ERTS_GLOBAL_LIT_EMPTY_TUPLE;
        } else {
            map->keys = make_tuple(local_heap);
            local_heap[0] = make_arityval(map_elem_count);
        }

#undef MAP_SIZE
        erts_nif_call_function(c_p, tracee ? tracee : c_p,
                               tnif->nif_mod,
                               tnif->tracers[topt].cb,
                               tnif->tracers[topt].arity,
                               argv);
    }
    return 1;
}

static ERTS_INLINE int
send_to_tracer_nif(Process *c_p, ErtsPTabElementCommon *t_p, ErtsTracerRef *ref,
                   Eterm t_p_id, ErtsTracerNif *tnif, enum ErtsTracerOpt topt,
                   Eterm tag, Eterm msg, Eterm extra, Eterm pam_result)
{
    ASSERT(ref);

#if defined(ERTS_ENABLE_LOCK_CHECK)
    if (c_p) {
        /* We have to hold the main lock of the currently executing process */
        erts_proc_lc_chk_have_proc_locks(c_p, ERTS_PROC_LOCK_MAIN);
    }
    if (is_internal_pid(t_p->id)) {
        /* We have to have at least one lock */
        ERTS_LC_ASSERT(erts_proc_lc_my_proc_locks((Process*)t_p) & ERTS_PROC_LOCKS_ALL);
    } else {
        ASSERT(is_internal_port(t_p->id));
        ERTS_LC_ASSERT(erts_lc_is_port_locked((Port*)t_p));
    }
#endif

    return send_to_tracer_nif_raw(c_p,
                                  is_internal_pid(t_p->id) ? (Process*)t_p : NULL,
                                  ref->tracer,
                                  ref->flags,
                                  t_p_id, tnif, topt, tag, msg, extra,
                                  pam_result);
}

static ERTS_INLINE Eterm
call_enabled_tracer(const ErtsTracer tracer,
                    ErtsTracerNif **tnif_ret,
                    enum ErtsTracerOpt topt,
                    Eterm tag, Eterm t_p_id) {
    ErtsTracerNif *tnif = lookup_tracer_nif(tracer);
    if (tnif) {
        Eterm argv[] = {tag, ERTS_TRACER_STATE(tracer), t_p_id},
            ret;
        topt = (tnif->tracers[topt].cb) ? topt : TRACE_FUN_ENABLED;
        ASSERT(topt < NIF_TRACER_TYPES);
        ASSERT(tnif->tracers[topt].cb != NULL);
        if (tnif_ret) *tnif_ret = tnif;
        ret = erts_nif_call_function(NULL, NULL, tnif->nif_mod,
                                     tnif->tracers[topt].cb,
                                     tnif->tracers[topt].arity,
                                     argv);
        if (tag == am_trace_status && ret != am_remove)
            return am_trace;
        ASSERT(tag == am_trace_status || ret != am_remove);
        return ret;
    }
    return tag == am_trace_status ? am_remove : am_discard;
}

static int
is_tracer_ref_enabled(Process* c_p, ErtsProcLocks c_p_locks,
                      ErtsPTabElementCommon *t_p,
                      ErtsTracerRef *ref,
                      ErtsTracerNif **tnif_ret,
                      enum ErtsTracerOpt topt, Eterm tag)
{
    ASSERT(t_p);
    ASSERT(ref);

#if defined(ERTS_ENABLE_LOCK_CHECK)
    if (c_p)
        ERTS_LC_ASSERT(erts_proc_lc_my_proc_locks(c_p) == c_p_locks
                           || erts_thr_progress_is_blocking());
    if (is_internal_pid(t_p->id)) {
        /* We have to have at least one lock */
        ERTS_LC_ASSERT(erts_proc_lc_my_proc_locks((Process*)t_p) & ERTS_PROC_LOCKS_ALL
                           || erts_thr_progress_is_blocking());
    } else {
        ASSERT(is_internal_port(t_p->id));
        ERTS_LC_ASSERT(erts_lc_is_port_locked((Port*)t_p)
                           || erts_thr_progress_is_blocking());
    }
#endif

    if (erts_is_trace_session_alive(ref->session)) {
        Eterm nif_result = call_enabled_tracer(ref->tracer, tnif_ret,
                                     topt, tag, t_p->id);
        switch (nif_result) {
        case am_discard: return 0;
        case am_trace: return 1;
        case THE_NON_VALUE:
        case am_remove: ASSERT(tag == am_trace_status); break;
        default:
            /* only am_remove should be returned, but if
               something else is returned we fall-through
               and remove the tracer. */
            ASSERT(0);
        }
    }

    /* Only remove tracer on (self() or ports) AND we are on a normal scheduler */
    if (is_internal_port(t_p->id) || (c_p && c_p->common.id == t_p->id)) {
        ErtsSchedulerData *esdp = erts_get_scheduler_data();
        ErtsProcLocks c_p_xlocks = 0;
        if (esdp && !ERTS_SCHEDULER_IS_DIRTY(esdp)) {
            if (is_internal_pid(t_p->id)) {
                ERTS_ASSERT(c_p && "Silence GCC array out of bounds warning");
                ERTS_LC_ASSERT(erts_proc_lc_my_proc_locks(c_p) & ERTS_PROC_LOCK_MAIN);
                if (c_p_locks != ERTS_PROC_LOCKS_ALL) {
                    c_p_xlocks = ~c_p_locks & ERTS_PROC_LOCKS_ALL;
                    if (erts_proc_trylock(c_p, c_p_xlocks) == EBUSY) {
                        erts_proc_unlock(c_p, c_p_locks & ~ERTS_PROC_LOCK_MAIN);
                        erts_proc_lock(c_p, ERTS_PROC_LOCKS_ALL_MINOR);
                    }
                }
            }

            clear_tracer_ref(t_p, ref);
            delete_tracer_ref(t_p, ref);

            if (c_p_xlocks)
                erts_proc_unlock(c_p, c_p_xlocks);
            return 0;
        }
    }
    return 0;
}

int erts_is_tracer_enabled(const ErtsTracer tracer, ErtsPTabElementCommon *t_p)
{
    ErtsTracerNif *tnif = lookup_tracer_nif(tracer);
    if (tnif) {
        Eterm nif_result = call_enabled_tracer(tracer, &tnif,
                                               TRACE_FUN_ENABLED,
                                               am_trace_status,
                                               t_p->id);
        switch (nif_result) {
        case am_discard:
        case am_trace: return 1;
        default:
            break;
        }
    }
    return 0;
}

int erts_is_tracer_ref_proc_enabled(Process* c_p, ErtsProcLocks c_p_locks,
                                    ErtsPTabElementCommon *t_p,
                                    ErtsTracerRef *ref)
{
    return is_tracer_ref_enabled(c_p, c_p_locks, t_p, ref, NULL,
                                 TRACE_FUN_ENABLED, am_trace_status);
}

int erts_is_tracer_ref_proc_enabled_send(Process* c_p, ErtsProcLocks c_p_locks,
                                         ErtsPTabElementCommon *t_p,
                                         ErtsTracerRef *ref)
{
    return is_tracer_ref_enabled(c_p, c_p_locks, t_p, ref, NULL,
                                 TRACE_FUN_T_SEND, am_send);
}


void erts_tracer_replace(ErtsPTabElementCommon *t_p,
                         ErtsTracerRef *ref,
                         const ErtsTracer tracer)
{
#if defined(ERTS_ENABLE_LOCK_CHECK)
    if (is_internal_pid(t_p->id) && !erts_thr_progress_is_blocking()) {
        erts_proc_lc_chk_have_proc_locks((Process*)t_p, ERTS_PROC_LOCKS_ALL);
    } else if (is_internal_port(t_p->id)) {
        ERTS_LC_ASSERT(erts_lc_is_port_locked((Port*)t_p)
                       || erts_thr_progress_is_blocking());
    }
#endif
    if (ERTS_TRACER_COMPARE(ref->tracer, tracer))
        return;

    erts_tracer_update(&ref->tracer, tracer);
}

static void free_tracer(void *p)
{
    ErtsTracer tracer = (ErtsTracer)p;

    if (is_immed(ERTS_TRACER_STATE(tracer))) {
        erts_free(ERTS_ALC_T_HEAP_FRAG, ptr_val(tracer));
    } else {
        ErlHeapFragment *hf = (void*)((char*)(ptr_val(tracer)) - offsetof(ErlHeapFragment, mem));
        free_message_buffer(hf);
    }
}

bool erts_get_tracer_pid(ErtsTracer tracer, Eterm* pid)
{
    if (is_list(tracer) && ERTS_TRACER_MODULE(tracer) == am_erl_tracer
        && is_internal_pid(ERTS_TRACER_STATE(tracer))) {

        *pid = ERTS_TRACER_STATE(tracer);
        return true;
    }
    return false;
}

/*
 * ErtsTracer is either NIL, 'true', local pid or [Mod | State]
 *
 * - If State is immediate then the memory for
 *   the cons cell is just two words + sizeof(ErtsThrPrgrLaterOp) large.
 * - If State is a complex term then the cons cell
 *   is allocated in an ErlHeapFragment where the cons
 *   ptr points to the mem field. So in order to get the
 *   ptr to the fragment you do this:
 *   (char*)(ptr_val(tracer)) - offsetof(ErlHeapFragment, mem)
 *   Normally you shouldn't have to care about this though
 *   as erts_tracer_update takes care of it for you.
 *
 *   When ErtsTracer is stored in the stack as part of a
 *   return trace, the cons cell is stored on the heap of
 *   the process.
 *
 *   The cons cell is not always stored on the heap as:
 *     1) for port/meta tracing there is no heap
 *     2) we would need the main lock in order to
 *        read the tracer which is undesirable.
 *
 * One way to optimize this (memory wise) is to keep an refc and only bump
 * the refc when *tracer is NIL.
 */
void
erts_tracer_update_impl(ErtsTracer *tracer, ErtsTracer new_tracer)
{
    ErlHeapFragment *hf;

    if (is_list(*tracer)) {
        Uint offs = 2;
        UWord size = 2 * sizeof(Eterm) + sizeof(ErtsThrPrgrLaterOp);
        ErtsThrPrgrLaterOp *lop;

        if (is_not_immed(ERTS_TRACER_STATE(*tracer))) {
            hf = ErtsContainerStruct_(ptr_val(*tracer), ErlHeapFragment, mem);
            offs = hf->used_size;
            size = hf->alloc_size * sizeof(Eterm) + sizeof(ErlHeapFragment);
            ASSERT(offs == size_object(*tracer));
        }

        /* sparc assumes that all structs are double word aligned, so we
           have to align the ErtsThrPrgrLaterOp struct otherwise it may
           segfault.*/
        if ((UWord)(ptr_val(*tracer) + offs) % (sizeof(UWord)*2) == sizeof(UWord))
            offs += 1;

        lop = (ErtsThrPrgrLaterOp*)(ptr_val(*tracer) + offs);
        ASSERT((UWord)lop % (sizeof(UWord)*2) == 0);

        /* We schedule the free:ing of the tracer until after a thread progress
           has been made so that we know that no schedulers have any references
           to it. Because we do this, it is possible to release all locks of a
           process/port and still use the ErtsTracer of that port/process
           without having to worry if it is free'd.
        */
        erts_schedule_thr_prgr_later_cleanup_op(
            free_tracer, (void*)(*tracer), lop, size);
    }

    if (is_list(new_tracer)) {
        const Eterm module = ERTS_TRACER_MODULE(new_tracer);
        const Eterm state = ERTS_TRACER_STATE(new_tracer);
        if (module == am_erl_tracer && is_internal_pid(state)) {
            new_tracer = state;
        }
    }
    if (is_immed(new_tracer)) {
        ASSERT(is_nil(new_tracer) || is_internal_pid(new_tracer));
        *tracer = new_tracer;
    } else if (is_immed(ERTS_TRACER_STATE(new_tracer))) {
        /* If tracer state is an immediate we only allocate a 2 Eterm heap.
           Not sure if it is worth it, we save 4 words (sizeof(ErlHeapFragment))
           per tracer. */
        Eterm *hp = erts_alloc(ERTS_ALC_T_HEAP_FRAG,
                               3*sizeof(Eterm) + sizeof(ErtsThrPrgrLaterOp));
        *tracer = CONS(hp, ERTS_TRACER_MODULE(new_tracer),
                       ERTS_TRACER_STATE(new_tracer));
    } else {
        Eterm *hp, tracer_state = ERTS_TRACER_STATE(new_tracer),
            tracer_module = ERTS_TRACER_MODULE(new_tracer);
        Uint sz = size_object(tracer_state);
        hf = new_message_buffer(sz + 2  /* cons cell */ +
                                (sizeof(ErtsThrPrgrLaterOp)+sizeof(Eterm)-1)/sizeof(Eterm) + 1);
        hp = hf->mem + 2;
        hf->used_size -= (sizeof(ErtsThrPrgrLaterOp)+sizeof(Eterm)-1)/sizeof(Eterm) + 1;
        *tracer = copy_struct(tracer_state, sz, &hp, &hf->off_heap);
        *tracer = CONS(hf->mem, tracer_module, *tracer);
        ASSERT((void*)(((char*)(ptr_val(*tracer)) - offsetof(ErlHeapFragment, mem))) == hf);
    }
}

static void init_tracer_nif(void)
{
    erts_rwmtx_opt_t rwmtx_opt = ERTS_RWMTX_OPT_DEFAULT_INITER;
    rwmtx_opt.type = ERTS_RWMTX_TYPE_EXTREMELY_FREQUENT_READ;
    rwmtx_opt.lived = ERTS_RWMTX_LONG_LIVED;

    erts_rwmtx_init_opt(&tracer_mtx, &rwmtx_opt, "tracer_mtx", NIL,
        ERTS_LOCK_FLAGS_PROPERTY_STATIC | ERTS_LOCK_FLAGS_CATEGORY_DEBUG);

    erts_tracer_nif_clear();

}

int erts_tracer_nif_clear(void)
{

    erts_rwmtx_rlock(&tracer_mtx);
    if (!tracer_hash || tracer_hash->nobjs) {

        HashFunctions hf;
        hf.hash = tracer_hash_fun;
        hf.cmp = tracer_cmp_fun;
        hf.alloc = tracer_alloc_fun;
        hf.free = tracer_free_fun;
        hf.meta_alloc = (HMALLOC_FUN) erts_alloc;
        hf.meta_free = (HMFREE_FUN) erts_free;
        hf.meta_print = (HMPRINT_FUN) erts_print;

        erts_rwmtx_runlock(&tracer_mtx);
        erts_rwmtx_rwlock(&tracer_mtx);

        if (tracer_hash)
            hash_delete(tracer_hash);

        tracer_hash = hash_new(ERTS_ALC_T_TRACER_NIF, "tracer_hash", 10, hf);

        erts_rwmtx_rwunlock(&tracer_mtx);
        return 1;
    }

    erts_rwmtx_runlock(&tracer_mtx);
    return 0;
}

static int tracer_cmp_fun(void* a, void* b)
{
    return ((ErtsTracerNif*)a)->module != ((ErtsTracerNif*)b)->module;
}

static HashValue tracer_hash_fun(void* obj)
{
    return erts_internal_hash(((ErtsTracerNif*)obj)->module);
}

static void *tracer_alloc_fun(void* tmpl)
{
    ErtsTracerNif *obj = erts_alloc(ERTS_ALC_T_TRACER_NIF,
                                    sizeof(ErtsTracerNif) +
                                    sizeof(ErtsThrPrgrLaterOp));
    sys_memcpy(obj, tmpl, sizeof(*obj));
    return obj;
}

static void tracer_free_fun_cb(void* obj)
{
    erts_free(ERTS_ALC_T_TRACER_NIF, obj);
}

static void tracer_free_fun(void* obj)
{
    ErtsTracerNif *tnif = obj;
    erts_schedule_thr_prgr_later_op(
        tracer_free_fun_cb, obj,
        (ErtsThrPrgrLaterOp*)(tnif + 1));

}

void erts_ref_trace_session(ErtsTraceSession* session)
{
    if (session != &erts_trace_session_0) {
	ErtsBinary* bin = ERTS_MAGIC_BIN_FROM_DATA(session);
	erts_refc_inc(&bin->magic_binary.intern.refc, 2);
    }
}

void erts_deref_trace_session(ErtsTraceSession* session)
{
    if (session != &erts_trace_session_0) {
	ErtsBinary* bin = ERTS_MAGIC_BIN_FROM_DATA(session);
	erts_bin_release(&bin->binary);
    }
}

ErtsTracerRef* get_tracer_ref(ErtsPTabElementCommon* t_p,
                              ErtsTraceSession* session)
{
    ErtsTracerRef* ref;

    for (ref = t_p->tracee.first_ref; ref; ref = ref->next) {
	if (ref->session == session)
            return ref;
    }

    return NULL;
}

ErtsTracerRef* get_tracer_ref_from_weak_id(ErtsPTabElementCommon* t_p,
                                           Eterm weak_id)
{
    ErtsTracerRef* ref;

#ifdef DEBUG
    {
        Uint32 all = erts_sum_all_trace_flags(t_p) & ~F_TRACE_RETURN_TO_MARK;
        ASSERT(all == t_p->tracee.all_trace_flags);
    }
#endif

    for (ref = t_p->tracee.first_ref; ref; ref = ref->next)
        if (ref->session->weak_id == weak_id)
	    return ref;

    return NULL;
}

#ifdef DEBUG
static void dbg_add_p_ref(ErtsPTabElementCommon* t_p,
                          ErtsTracerRef *ref)
{
    ErtsTraceSession *s = ref->session;
    erts_refc_inc(&s->dbg_p_refc, 1);
}
#else
#  define dbg_add_p_ref(t_p, ref)
#endif

ErtsTracerRef* new_tracer_ref(ErtsPTabElementCommon* t_p,
                              ErtsTraceSession* session)
{
    ErtsTracerRef *ref = t_p->tracee.first_ref;

    ASSERT(get_tracer_ref(t_p, session) == NULL);
    ASSERT(erts_is_trace_session_alive(session));

    ref = erts_alloc(ERTS_ALC_T_HEAP_FRAG,  // ToDo type?
                     sizeof(ErtsTracerRef));
    ref->next = t_p->tracee.first_ref;
    t_p->tracee.first_ref =  ref;
    ref->session = session;
    ref->flags = t_p->tracee.all_trace_flags & F_SENSITIVE;
    ref->tracer = erts_tracer_nil;
    dbg_add_p_ref(t_p, ref);
    return ref;
}

#ifdef DEBUG
static void dbg_remove_p_ref(ErtsPTabElementCommon* t_p,
                             ErtsTracerRef *ref)
{
    erts_refc_dec(&ref->session->dbg_p_refc, 0);
}
#else
#  define dbg_remove_p_ref(t_p, ref)
#endif

void clear_tracer_ref(ErtsPTabElementCommon* t_p,
                      ErtsTracerRef *ref)
{
    ASSERT(t_p->tracee.all_trace_flags == erts_sum_all_trace_flags(t_p)
           || (t_p->tracee.all_trace_flags & F_TRACE_DBG_CANARY));

    erts_tracer_replace(t_p, ref, erts_tracer_nil);
    ref->flags = 0;
    dbg_remove_p_ref(t_p, ref);
    ref->session = NULL;

    t_p->tracee.all_trace_flags |= F_TRACE_DBG_CANARY;
}

void delete_tracer_ref(ErtsPTabElementCommon* t_p, ErtsTracerRef *ref)
{
    ErtsTracerRef** prev_p;

    ASSERT(ref->tracer == erts_tracer_nil);
    ASSERT(ref->flags == 0);
    ASSERT(ref->session == NULL);
    ASSERT(t_p->tracee.all_trace_flags & F_TRACE_DBG_CANARY);

    prev_p = &t_p->tracee.first_ref;
    while (*prev_p != ref) {
        ASSERT(*prev_p);
        prev_p = &(*prev_p)->next;
    }

    *prev_p = ref->next;

    erts_free(ERTS_ALC_T_HEAP_FRAG, ref);  // ToDo: type?

    t_p->tracee.all_trace_flags = erts_sum_all_trace_flags(t_p);
    ERTS_ASSERT_TRACER_REFS(t_p);
}

Uint delete_unalive_trace_refs(ErtsPTabElementCommon* t_p)
{
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;
    ErtsTracerRef** prev_p;
    Uint reds = 0;

    prev_p = &t_p->tracee.first_ref;

    for (ref = t_p->tracee.first_ref; ref; ref = next_ref) {
        next_ref = ref->next;

        ASSERT(ref->session);
        if (erts_is_trace_session_alive(ref->session)) {
            prev_p = &ref->next;
        } else {
            dbg_remove_p_ref(t_p, ref);
            ERTS_TRACER_CLEAR(&ref->tracer);
            erts_free(ERTS_ALC_T_HEAP_FRAG, ref);  // ToDo: type?
            reds += 10;
            *prev_p = next_ref;
        }
        reds++;
    }
    return reds;
}


void delete_all_trace_refs(ErtsPTabElementCommon* t_p)
{
    ErtsTracerRef *ref;
    ErtsTracerRef *next_ref;

    for (ref = t_p->tracee.first_ref; ref; ref = next_ref) {
        next_ref = ref->next;

        ASSERT(ref->session);
        dbg_remove_p_ref(t_p, ref);
        ERTS_TRACER_CLEAR(&ref->tracer);

        erts_free(ERTS_ALC_T_HEAP_FRAG, ref);  // ToDo: type?
    }
    t_p->tracee.first_ref = NULL;
}


Uint32 erts_sum_all_trace_flags(ErtsPTabElementCommon* t_p)
{
    ErtsTracerRef* ref;
    Uint32 all_flags = t_p->tracee.all_trace_flags;


    if (all_flags & F_SENSITIVE) {
        ASSERT(!(all_flags & TRACEE_FLAGS));
        all_flags = F_SENSITIVE;
    }
    else {
        all_flags = 0;
        for (ref = t_p->tracee.first_ref; ref; ref = ref->next) {
            ASSERT(!(ref->flags & F_SENSITIVE));
            all_flags |= ref->flags;
        }
    }
    return all_flags;
}

void erts_change_proc_trace_session_flags(Process* p, ErtsTraceSession* session,
                                          Uint32 clear_flags,
                                          Uint32 set_flags)
{
    ErtsTracerRef* ref = get_tracer_ref(&p->common, session);
    if (ref) {
        ref->flags &= ~clear_flags;
        ref->flags |= set_flags;
        p->common.tracee.all_trace_flags = erts_sum_all_trace_flags(&p->common);
    }
}

#ifdef DEBUG
void erts_assert_tracer_refs(ErtsPTabElementCommon* t_p)
{
    ErtsTracerRef *ref, *other;

    ASSERT(!(t_p->tracee.all_trace_flags & F_TRACE_DBG_CANARY));

    for (ref = t_p->tracee.first_ref; ref; ref = ref->next) {
        ASSERT(ref->session);
        ASSERT(ref->flags);
        ASSERT(ref->tracer != erts_tracer_nil);
        for (other = ref->next; other; other =  other->next) {
            ASSERT(other->session != ref->session);
        }
    }
}
#endif
