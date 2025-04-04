<!--
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
-->
### Archives

The following features of archives will be removed:

* Using archives for packaging a single application or parts of a single application
  into an archive file that is included in the code path.

* All functionality to handle archives in module `m:erl_prim_loader`.

* The `-code_path_choice` flag for `erl`.

The functionality to use a single archive file in Escripts is **not**
deprecated and will continue to work.  However, to access files in the
archive, the `escript:extract/2` function has to be used.
