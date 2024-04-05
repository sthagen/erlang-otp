<!--
%CopyrightBegin%

Copyright Ericsson AB 2023-2024. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

%CopyrightEnd%
-->
# fprof - The File Trace Profiler

`m:fprof` is a profiling tool that can be used to get a picture of how much
processing time different functions consumes and in which processes.

`fprof` uses tracing with timestamps to collect profiling data. Therefore there
is no need for special compilation of any module to be profiled.

`fprof` presents wall clock times from the host machine OS, with the assumption
that OS scheduling will randomly load the profiled functions in a fair way. Both
_own time_, that is, the time used by a function for its own execution, and
_accumulated time_, that is, execution time including called functions.

Profiling is essentially done in 3 steps:

- Tracing to a file.

- Profiling: the trace file is read and raw profile data is collected
  into an internal RAM storage on the node. During this step the trace data may
  be dumped in text format to file or console.

- Analysing: the raw profile data is sorted and dumped in text format
  either to file or console.

Since `fprof` stores trace data to a file, the runtime performance degradation is
minimized, but still far from negligible, especially for programs that themselves
use the filesystem heavily. Where the trace file is placed is also important;
on Unix systems `/tmp` is usually a good choice, while any
network-mounted disk is a bad choice.

`fprof` can also skip the file step and trace to a tracer process of its own that
does the profiling in runtime.

The following sections show some examples of how to profile with `m:fprof`.

## Profiling from the source code

If you can edit and recompile the source code, it is convenient to
insert [`fprof:trace(start)`](`fprof:trace/1`) and
[`fprof:trace(stop)`](`fprof:trace/1`) before and after the code to be profiled.
All spawned processes are also traced. If you want some other filename than
the default, use [`fprof:trace(start, "my_fprof.trace")`](`fprof:trace/2`).

When execution is finished, the raw profile can be processed using
[`fprof:profile()`](`fprof:profile/0`),
or [`fprof:profile(file, "my_fprof.trace")`](`fprof:profile/2`)
for a non-default filename.

Finally create an informative table dumped on the console with
[`fprof:analyse()`](`fprof:analyse/0`), or on file with
[`fprof:analyse(dest, [])`](`fprof:analyse/2`), or
[`fprof:analyse([{dest, "my_fprof.analysis"}, {cols, 120}])`](`fprof:analyse/1`)
for a wider listing of a non-default filename.

## Profiling a function

If you have one function that does the task that you want to profile, and the
function returns when the profiling should stop, it is convenient to use
[`fprof:apply(Module, Function, Args)`](`fprof:apply/3`) for the tracing step.

If the tracing should continue after the function has returned, for
example if it is a start function that spawns processes to be
profiled, use
[`fprof:apply(M, F, Args, [continue | OtherOpts])`](`fprof:apply/4`).
The tracing has to be stopped at a suitable later time using
[`fprof:trace(stop)`](`fprof:trace/1`).

## Immediate profiling

It is also possible to trace immediately into the profiling process that creates
the raw profile data, that is to short circuit the tracing and profiling steps
so that the filesystem is not used for tracing.

Do something like this:

```erlang
{ok, Tracer} = fprof:profile(start),
fprof:trace([start, {tracer, Tracer}]),
%% Run code to profile
fprof:trace(stop);
```

This puts less load on the filesystem, but much more load on the Erlang runtime
system.
