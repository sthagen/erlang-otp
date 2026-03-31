/*
 * %CopyrightBegin%
 *
 * SPDX-License-Identifier: Apache-2.0
 * 
 * Copyright Ericsson AB 2026. All Rights Reserved.
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

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif

#include "erl_errno.h"
#include "sys.h"

#if !defined(ERTS_USE_BUILTIN_ERRNO_ID)

#include <string.h>
#include "hash.h"
#include "erl_driver.h"
#include "erl_alloc.h"

static char *unknown = "unknown";
static char **errno_map;
static int max_errno = 0;
static erts_rwmtx_t errno_rwmtx;
static int hash_initialized = 0;
static Hash *errno_table = NULL;
static int used_before_init = 0;
static int init_done = 0;
static int late_init_done = 0;

#ifdef DEBUG
#  define ERTS_MAX_CACHED_ERRNO 5
#else
#  define ERTS_MAX_CACHED_ERRNO 1000
#endif

#define ERTS_DEFAULT_ERRNO_STRING_CHARS 4

typedef struct {
    HashBucket bkt;
    int eno;
    char str[ERTS_DEFAULT_ERRNO_STRING_CHARS];
} ErtsErrnoEntry;

static void *
alloc(ErtsAlcType_t type, Uint size)
{
    if (used_before_init) {
        return malloc(size);
    }
    else {
        return erts_alloc(type, size);
    }
}

static void *
permanent_alloc(ErtsAlcType_t type, Uint size)
{
    if (used_before_init) {
        return malloc(size);
    }
    else {
        return erts_alloc_permanent_cache_aligned(type, size);
    }
}

static void
dealloc(ErtsAlcType_t type, void *ptr)
{
    if (used_before_init) {
        free(ptr);
    }
    else {
        erts_free(type, ptr);
    }
}

static char *
tolower_copy_estring(char *dst, char *end, const char *src)
{
    char *ptr = dst;
    char c;
    int i = 0;
    do {
        if (ptr > end) {
            erts_exit(ERTS_ABORT_EXIT, "Errno map overrun!\n");
        }
        c = src[i++];
        if ('A' <= c && c <= 'Z') {
            c += ('a' - 'A');
        }
        *(ptr++) = c;
    } while (c != '\0');

    return ptr;
}

static ErtsErrnoEntry *
make_errno_entry(int eno, char *str)
{
    ErtsErrnoEntry *entry;
    size_t len, sz;

    sz = sizeof(ErtsErrnoEntry);
    len = strlen(str) + 1;
    if (len > ERTS_DEFAULT_ERRNO_STRING_CHARS) {
        sz += len - ERTS_DEFAULT_ERRNO_STRING_CHARS;
    }
    entry = (ErtsErrnoEntry *) alloc(ERTS_ALC_T_ENO_ENTRY, sz);
    entry->eno = eno;
    (void) tolower_copy_estring(&entry->str[0], &entry->str[0] + len, str);
    return entry;
}

static int errno_cmp(void *ve1, void *ve2)
{
    ErtsErrnoEntry *e1 = ve1;
    ErtsErrnoEntry *e2 = ve2;
    return e1->eno != e2->eno;
}

static HashValue errno_hash(void *ve)
{
    ErtsErrnoEntry *e = ve;
    return ((HashValue) e->eno) * ((HashValue) 268437017);
}

static void *errno_alloc(void *ve)
{
    /*
     * We allocate the element before hash_put() and pass it as
     * template which we get as input...
     */
    return ve;
}

static void errno_free(void *ve)
{
    /*
     * We *never* remove any elements that has been inserted...
     */
}

static void *errno_meta_alloc(int i, size_t size)
{
    return alloc(ERTS_ALC_T_ENO_TAB_BKTS, size);
}

static void errno_meta_free(int i, void *ptr)
{
    dealloc(ERTS_ALC_T_ENO_TAB_BKTS, ptr);
}

static void
init_hash_table(void)
{
    if (!hash_initialized) {
        HashFunctions hash_funcs;

        errno_table = permanent_alloc(ERTS_ALC_T_ENO_TAB, sizeof(Hash));
        hash_funcs.hash = errno_hash;
        hash_funcs.cmp = errno_cmp;

        hash_funcs.alloc = errno_alloc;
        hash_funcs.free = errno_free;
        hash_funcs.meta_alloc = errno_meta_alloc;
        hash_funcs.meta_free = errno_meta_free;
        hash_funcs.meta_print = erts_print;
        hash_init(0, errno_table, "errno_table", 1, hash_funcs);
        hash_initialized = !0;
    }
}

static const char *errno_name(int eno)
{
#define ERTS_ERRNO_CASE(ENO) case ENO: return #ENO

    /*
     * Some errno names might have the same integer value. Make sure to return
     * the same name that we've always returned for such collisions.
     */
    switch (eno) {

#ifdef EAGAIN
        ERTS_ERRNO_CASE(EAGAIN);
#endif

#ifdef EALREADY
#if !defined(EBUSY) || EBUSY != EALREADY
        ERTS_ERRNO_CASE(EALREADY);
#endif
#endif

#ifdef EBUSY
        ERTS_ERRNO_CASE(EBUSY);
#endif

#ifdef ECONNREFUSED
        ERTS_ERRNO_CASE(ECONNREFUSED);
#endif

#ifdef EDEADLK
#if !defined(EWOULDBLOCK) || EWOULDBLOCK != EDEADLK
        ERTS_ERRNO_CASE(EDEADLK);
#endif
#endif

#ifdef EEXIST
        ERTS_ERRNO_CASE(EEXIST);
#endif

#ifdef EIDRM
#if !defined(EINPROGRESS) || EINPROGRESS != EIDRM
        ERTS_ERRNO_CASE(EIDRM);
#endif
#endif

#ifdef EINPROGRESS
        ERTS_ERRNO_CASE(EINPROGRESS);
#endif

#ifdef ELOOP
#if !defined(ENOENT) || ENOENT != ELOOP
        ERTS_ERRNO_CASE(ELOOP);
#endif
#endif

#ifdef ENAMETOOLONG
        ERTS_ERRNO_CASE(ENAMETOOLONG);
#endif

#ifdef ENOBUFS
#if !defined(ENOSR) || ENOSR != ENOBUFS
        ERTS_ERRNO_CASE(ENOBUFS);
#endif
#endif

#ifdef ENOSTR
#if !defined(ENOTTY) || ENOTTY != ENOSTR
        ERTS_ERRNO_CASE(ENOSTR);
#endif
#endif

#ifdef ENODATA
#if !defined(ECONNREFUSED) || ECONNREFUSED != ENODATA
        ERTS_ERRNO_CASE(ENODATA);
#endif
#endif

#ifdef ENOENT
        ERTS_ERRNO_CASE(ENOENT);
#endif

#ifdef ENOLCK
        ERTS_ERRNO_CASE(ENOLCK);
#endif

#ifdef ENOSR
#if !defined(ENAMETOOLONG) || ENAMETOOLONG != ENOSR
        ERTS_ERRNO_CASE(ENOSR);
#endif
#endif

#ifdef ENOTEMPTY
#if !defined(EEXIST) || EEXIST != ENOTEMPTY
        ERTS_ERRNO_CASE(ENOTEMPTY);
#endif
#endif

#ifdef ENOTTY
        ERTS_ERRNO_CASE(ENOTTY);
#endif

#ifdef ENOTSUP
        ERTS_ERRNO_CASE(ENOTSUP);
#endif

#ifdef EOPNOTSUPP
#if !defined(ENOTSUP) || ENOTSUP != EOPNOTSUPP
        ERTS_ERRNO_CASE(EOPNOTSUPP);
#endif
#endif

#ifdef ETIME
#if !defined(ELOOP) || ELOOP != ETIME
        ERTS_ERRNO_CASE(ETIME);
#endif
#endif

#ifdef ETIMEDOUT
#if ((!defined(ENOSTR) || ENOSTR != ETIMEDOUT)          \
     && (!defined(EAGAIN) || EAGAIN != ETIMEDOUT))
        ERTS_ERRNO_CASE(ETIMEDOUT);
#endif
#endif

#ifdef EWOULDBLOCK
#if !defined(EAGAIN) || EAGAIN != EWOULDBLOCK
        ERTS_ERRNO_CASE(EWOULDBLOCK);
#endif
#endif

    default:

#ifdef HAVE_STRERRORNAME_NP
        return strerrorname_np(eno);
#else
#error Missing primitive mapping errno integer values to errno names
#endif

    }

#undef ERTS_ERRNO_CASE
}

void
erts_errno_init(void)
{
    /* Allocators have been initialized... */
    int eno;
    size_t tot_sz = 0, arr_sz;
    char *ptr, *end_ptr;

    for (eno = 0; eno < ERTS_MAX_CACHED_ERRNO; eno++) {
        const char *str = errno_name(eno);
        if (str) {
            max_errno = eno;
            tot_sz += strlen(str) + 1;
        }
    }

    arr_sz = sizeof(char *)*(max_errno + 1);
    tot_sz += arr_sz;
    ptr = permanent_alloc(ERTS_ALC_T_ENO_MAP, tot_sz);
    end_ptr = ptr + tot_sz;

    errno_map = (char **) ptr;

    ptr += arr_sz;

    errno_map[0] = unknown;
    for (eno = 1; eno <= max_errno; eno++) {
        const char *str = errno_name(eno);
        if (!str) {
            errno_map[eno] = unknown;
        }
        else {
            errno_map[eno] = ptr;
            ptr = tolower_copy_estring(ptr, end_ptr, str);
        }
    }

    init_done = !0;
}

void
erts_errno_late_init(void)
{
    /*
     * We are still single threaded and now the thread lib has been
     * initialized...
     */
    erts_rwmtx_opt_t rwmtx_opt = ERTS_RWMTX_OPT_DEFAULT_INITER;
    rwmtx_opt.type = ERTS_RWMTX_TYPE_NORMAL;
    rwmtx_opt.lived = ERTS_RWMTX_LONG_LIVED;
    erts_rwmtx_init_opt(&errno_rwmtx, &rwmtx_opt, "errno_table", NIL,
                        ERTS_LOCK_FLAGS_PROPERTY_STATIC | ERTS_LOCK_FLAGS_CATEGORY_GENERIC);
    late_init_done = !0;
}

static void rlock(void)
{
    if (late_init_done) {
        erts_rwmtx_rlock(&errno_rwmtx);
    }
}

static void runlock(void)
{
    if (late_init_done) {
        erts_rwmtx_runlock(&errno_rwmtx);
    }
}

static void rwlock(void)
{
    if (late_init_done) {
        erts_rwmtx_rwlock(&errno_rwmtx);
    }
}
static void rwunlock(void)
{
    if (late_init_done) {
        erts_rwmtx_rwunlock(&errno_rwmtx);
    }
}

char *
erl_errno_id(int eno)
{
    /*
     * Note! Returned strings must not move or be deallocated
     * during the runtime systems lifetime.
     */
    char *res, *str;
    ErtsErrnoEntry *hash_res;
    ErtsErrnoEntry tmpl;

    if (!init_done) {
        /*
         * Alloc-util allocators have not yet been initialized so we will go
         * for malloc/free instead of erts_alloc/erts_free from now on.
         *
         * This scenario is very unlikely, but might happen on a fatal error
         * during initialization of the emulator.
         */
        used_before_init = !0;
    }

    if (0 <= eno && eno <= max_errno) {
        return errno_map[eno];
    }

    str = (char *) errno_name(eno);
    if (!str) {
        return unknown;
    }

    rlock();

    if (!hash_initialized) {
        runlock();
        rwlock();
        init_hash_table();
        rwunlock();
        rlock();
    }

    tmpl.eno = eno;
    tmpl.str[0] = '\0';

    hash_res = hash_get(errno_table, (void *) &tmpl);

    runlock();

    if (hash_res) {
        res = &hash_res->str[0];
    }
    else {
        ErtsErrnoEntry *entry = make_errno_entry(eno, str);
        rwlock();
        hash_res = hash_put(errno_table, entry);
        if (hash_res != entry) {
            /*
             * Insert raced with an insert by another thread and the other
             * thread won...
             */
            dealloc(ERTS_ALC_T_ENO_ENTRY, entry);
        }
        rwunlock();
        res = &hash_res->str[0];
    }

    ASSERT(res && res[0]);

    return res;
}

#endif /* !defined(ERTS_USE_BUILTIN_ERRNO_ID) */
