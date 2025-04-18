%%
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% Copyright Ericsson AB 1999-2025. All Rights Reserved.
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
%%
-module(erl_lint_SUITE).

%%-define(debug, true).

-ifdef(debug).
-define(line, put(line, ?LINE), ).
-define(config(X,Y), foo).
-define(datadir, "erl_lint_SUITE_data").
-define(privdir, "erl_lint_SUITE_priv").
-define(t, test_server).
-else.
-include_lib("common_test/include/ct.hrl").
-define(datadir, proplists:get_value(data_dir, Conf)).
-define(privdir, proplists:get_value(priv_dir, Conf)).
-endif.

-export([all/0, suite/0, groups/0]).

-export([singleton_type_var_errors/1,
         documentation_attributes/1,
         unused_vars_warn_basic/1,
         unused_vars_warn_lc/1,
         unused_vars_warn_rec/1,
         unused_vars_warn_fun/1,
         unused_vars_OTP_4858/1,
         unused_unsafe_vars_warn/1,
         export_vars_warn/1,
         shadow_vars/1,
         unused_import/1,
         unused_function/1,
         unsafe_vars/1,unsafe_vars2/1,
         unsafe_vars_try/1,
         unsized_binary_in_bin_gen_pattern/1,
         guard/1, otp_4886/1, otp_4988/1, otp_5091/1, otp_5276/1, otp_5338/1,
         otp_5362/1, otp_5371/1, otp_7227/1, binary_aliases/1,
         otp_5494/1, otp_5644/1, otp_5878/1,
         otp_5917/1, otp_6585/1, otp_6885/1, otp_10436/1, otp_11254/1,
         otp_11772/1, otp_11771/1, otp_11872/1,
         export_all/1,
         bif_clash/1,
         behaviour_basic/1, behaviour_multiple/1, otp_11861/1,
         otp_7550/1,
         otp_8051/1,
         format_warn/1,
         on_load_successful/1, on_load_failing/1,
         too_many_arguments/1,
         basic_errors/1,bin_syntax_errors/1,
         predef/1,
         maps/1,maps_type/1,maps_parallel_match/1,
         otp_11851/1,otp_11879/1,otp_13230/1,
         record_errors/1, otp_11879_cont/1,
         non_latin1_module/1, illegal_module_name/1, otp_14323/1,
         stacktrace_syntax/1,
         otp_14285/1, otp_14378/1,
         external_funs/1,otp_15456/1,otp_15563/1,
         types/1,
         removed/1, otp_16516/1,
         inline_nifs/1,
         undefined_nifs/1,
         no_load_nif/1,
         warn_missing_spec/1,
         otp_16824/1,
         underscore_match/1,
         unused_record/1,
         untyped_record/1,
         unused_type2/1,
         eep49/1,
         redefined_builtin_type/1,
         tilde_k/1,
         match_float_zero/1,
         undefined_module/1,
         update_literal/1,
         messages_with_jaro_suggestions/1,
         illegal_zip_generator/1,
         record_info_0/1,
         coverage/1]).

suite() ->
    [{ct_hooks,[ts_install_cth]},
     {timetrap,{minutes,1}}].

all() -> 
    [{group, unused_vars_warn}, export_vars_warn,
     shadow_vars, unused_import, unused_function,
     unsafe_vars, unsafe_vars2, unsafe_vars_try, guard,
     unsized_binary_in_bin_gen_pattern,
     otp_4886, otp_4988, otp_5091, otp_5276, otp_5338,
     otp_5362, otp_5371, otp_7227, binary_aliases, otp_5494, otp_5644,
     otp_5878, otp_5917, otp_6585, otp_6885, otp_10436, otp_11254,
     otp_11772, otp_11771, otp_11872, export_all,
     bif_clash, behaviour_basic, behaviour_multiple, otp_11861,
     otp_7550, otp_8051, format_warn, {group, on_load},
     too_many_arguments, basic_errors, bin_syntax_errors, predef,
     maps, maps_type, maps_parallel_match,
     otp_11851, otp_11879, otp_13230,
     record_errors, otp_11879_cont,
     non_latin1_module, illegal_module_name, otp_14323,
     stacktrace_syntax, otp_14285, otp_14378, external_funs,
     otp_15456, otp_15563,
     types,
     removed, otp_16516,
     undefined_nifs,
     no_load_nif,
     inline_nifs, warn_missing_spec, otp_16824,
     underscore_match, unused_record, untyped_record, unused_type2,
     eep49,
     redefined_builtin_type,
     tilde_k,
     singleton_type_var_errors,
     documentation_attributes,
     match_float_zero,
     undefined_module,
     update_literal,
     messages_with_jaro_suggestions,
     illegal_zip_generator,
     record_info_0,
     coverage].

groups() -> 
    [{unused_vars_warn, [],
      [unused_vars_warn_basic, unused_vars_warn_lc,
       unused_vars_warn_rec, unused_vars_warn_fun,
       unused_vars_OTP_4858, unused_unsafe_vars_warn]},
     {on_load, [], [on_load_successful, on_load_failing]}].


%% Warnings for unused variables in some simple cases.
unused_vars_warn_basic(Config) when is_list(Config) ->
    Ts = [{basic1,
           <<"f(F) -> % F unused.
                ok.

f(F, F) ->
    ok.

g(_X) ->
    y.

h(P) ->
    P.

x(N) ->
    case a:b() of
	[N|Y] -> % Y unused.
	    ok
    end.

y(N, L) ->
    lists:map(fun(T) -> T*N end, L).

z(N, L) -> % N unused
    lists:map(fun(N, T) -> T*N end, L).  % N shadowed.


c(A) ->
    case A of
	1 -> B = []; % B unused.
	2 -> B = []; % B unused.
	3 -> B = f, B
    end.
">>,
	   [warn_unused_vars],
{warnings,[{{1,23},erl_lint,{unused_var,'F'}},
	   {{15,5},erl_lint,{unused_var,'Y'}},
	   {{22,3},erl_lint,{unused_var,'N'}},
	   {{23,19},erl_lint,{shadowed_var,'N','fun'}},
	   {{28,7},erl_lint,{unused_var,'B'}},
	   {{29,7},erl_lint,{unused_var,'B'}}]}},
          {basic2,
           <<"-record(r, {x,y}).
              f({X,Y}) -> {Z=X,Z=Y};
              f([H|T]) -> [Z=H|Z=T];
              f(#r{x=X,y=Y}) -> #r{x=A=X,y=A=Y}.
              g({M, F}) -> (Z=M):(Z=F)();
              g({M, F, Arg}) -> (Z=M):F(Z=Arg).
              h(X, Y) -> (Z=X) + (Z=Y).">>,
           [warn_unused_vars], []},
          {basic3,
           <<"f(E) ->
                  X = Y = E.">>,
           [warn_unused_vars],
           {warnings,[{{2,19},erl_lint,{unused_var,'X'}},
                      {{2,23},erl_lint,{unused_var,'Y'}}]}}],
    [] = run(Config, Ts),
    ok.

%% Warnings for unused variables in list comprehensions.
unused_vars_warn_lc(Config) when is_list(Config) ->
    Ts = [{lc1, 
           <<"bin([X]) ->
                  [A || <<A:X>> <- []]; % X used, not shadowed.
              bin({X}) ->
                  [X || <<X:X>> <- []]; % X used, and shadowed.
              bin({X,Y,Z}) ->
                  [{A,B} || <<A:X>> <- Z, <<B:Y>> <- Z];
              bin([X,Y,Z]) -> % Y unused.
                  [C || <<V:X>> <- Z, <<B:V>> <- Z, <<C:B>> <- Z].
           ">>, 
           [warn_unused_vars],
           {warnings, [{{4,27},erl_lint,{shadowed_var,'X',generate}},
                       {{7,22},erl_lint,{unused_var,'Y'}}]}},

          {lc2,
           <<"bin([X]) ->
                  [A || <<A:X>> <- []]; % X used, not shadowed.
              bin({X}) ->
                  [X || <<X:X>> <- []]; % X used, and shadowed.
              bin({X,Y,Z}) ->
                  [{A,B} || <<A:X>> <- Z, <<B:Y>> <- Z];
              bin([X,Y,Z]) -> % Y unused.
                  [C || <<V:X>> <- Z, <<B:V>> <- Z, <<C:B>> <- Z].
           ">>,
           [warn_unused_vars],
           {warnings,[{{4,27},erl_lint,{shadowed_var,'X',generate}},
                      {{7,22},erl_lint,{unused_var,'Y'}}]}},

          {lc3,
           <<"a([A]) ->
                  B = foo,
                  [{C,B} || {C,_} <- A];
              a({A}) ->
                  B = foo,
                  [C || {C,_} <- [B,A]];
              a({A,A}) ->
                  B = foo,
                  [C || {C,_} <- B, B < A].
           ">>,
           [warn_unused_vars],
           []},

          {lc4,
           <<"b(A) ->
                  B = foo, % B unused.
                  [C || {C,_} <- A].
           ">>,
           [warn_unused_vars],
           {warnings,[{{2,19},erl_lint,{unused_var,'B'}}]}},

          {lc5,
           <<"c(A) ->
                  B = foo,
                  [C || {C,_} <- A],
                  B.
           ">>,
           [warn_unused_vars],
           []},

          {lc6,
           <<"d(A) ->
                  B = foo,
                  [{A,B} || {Id,_} <- A]. % Id unused.
           ">>,
           [warn_unused_vars],
           {warnings,[{{3,30},erl_lint,{unused_var,'Id'}}]}},

          {lc7,
           <<"e(A) ->
                  B = foo, % B unused.
                  [B || B <- A]. % B shadowed.
           ">>,
           [warn_unused_vars],
           {warnings,[{{2,19},erl_lint,{unused_var,'B'}},
                      {{3,25},erl_lint,{shadowed_var,'B',generate}}]}},

          {lc8,
           <<"f(A) ->
                  B = foo,
                  [B || B <- A], % B shadowed.
                  B.
           ">>,
           [warn_unused_vars],
           {warnings,[{{3,25},erl_lint,{shadowed_var,'B',generate}}]}},

          {lc9,
           <<"g(A) ->
                  B = foo, % B unused.
                  [A || B <- A]. % B shadowed, B unused.
           ">>,
           [warn_unused_vars],
           {warnings,[{{2,19},erl_lint,{unused_var,'B'}},
                      {{3,25},erl_lint,{unused_var,'B'}},
                      {{3,25},erl_lint,{shadowed_var,'B',generate}}]}},

          {lc10,
           <<"h(A) ->
                  B = foo,
                  [A || B <- A], % B shadowed, B unused.
                  B.
           ">>,
           [warn_unused_vars],
           {warnings,[{{3,25},erl_lint,{unused_var,'B'}},
                      {{3,25},erl_lint,{shadowed_var,'B',generate}}]}},

          {lc11,
           <<"i(X) ->
                  [Z || Z <- X, % Z unused.
                        Z = X <- [foo]]. % X and Z shadowed. X unused!
           ">>,
           [warn_unused_vars],
           {warnings,[{{2,25},erl_lint,{unused_var,'Z'}},
                      {{3,25},erl_lint,{shadowed_var,'Z',generate}},
                      {{3,29},erl_lint,{unused_var,'X'}},
                      {{3,29},erl_lint,{shadowed_var,'X',generate}}]}},

          {lc12,
           <<"j({X}) ->
                  [Z || Z <- X, % Z unused.
                        Z <- X = [[1,2,3]], % Z shadowed. Z unused.
                        Z <- X, % Z shadowed. Z unused.
                        Z <- X]; % Z shadowed.
              j(X) ->
                  [foo || X <- X, % X shadowed.
                        X <-    % X shadowed. X unused.
                             X =
                                 Y = [[1,2,3]], % Y unused.
                        X <- [], % X shadowed.
                        X <- X]. % X shadowed. X unused.
           ">>,
           [warn_unused_vars],
           {warnings,[{{2,25},erl_lint,{unused_var,'Z'}},
                      {{3,25},erl_lint,{unused_var,'Z'}},
                      {{3,25},erl_lint,{shadowed_var,'Z',generate}},
                      {{4,25},erl_lint,{unused_var,'Z'}},
                      {{4,25},erl_lint,{shadowed_var,'Z',generate}},
                      {{5,25},erl_lint,{shadowed_var,'Z',generate}},
                      {{7,27},erl_lint,{shadowed_var,'X',generate}},
                      {{8,25},erl_lint,{unused_var,'X'}},
                      {{8,25},erl_lint,{shadowed_var,'X',generate}},
                      {{10,34},erl_lint,{unused_var,'Y'}},
                      {{11,25},erl_lint,{shadowed_var,'X',generate}},
                      {{12,25},erl_lint,{unused_var,'X'}},
                      {{12,25},erl_lint,{shadowed_var,'X',generate}}]}},

          {lc13,
           <<"k(X) ->
                  [Z || Z <- Y = X]; % Y unused.
              k(X) ->
                  [Z || Z <- X = Y = X]; % Y unused!
              k(X) ->
                  [Z || Z <- begin X = Y = X, Y end];
              k(X) ->
                  [{Y,W} || W <- Y = X]; % Y unbound
              k(X) ->
                  [Z || Z <- (Y = X), % Y unused.
                       Y > X]; % Y unbound.
              k(X) ->
                  [Y || Y = X > 3, Z = X]; % Z unused.
              k(X) ->
                  [Z || Y = X > 3, Z = X]. % Y unused.
           ">>,
           [warn_unused_vars],
           {error,[{{8,21},erl_lint,{unbound_var,'Y'}},
                   {{11,24},erl_lint,{unbound_var,'Y'}}],
                  [{{2,30},erl_lint,{unused_var,'Y'}},
                   {{4,34},erl_lint,{unused_var,'Y'}},
                   {{8,34},erl_lint,{unused_var,'Y'}},
                   {{10,31},erl_lint,{unused_var,'Y'}},
                   {{13,36},erl_lint,{unused_var,'Z'}},
                   {{15,25},erl_lint,{unused_var,'Y'}}]}},

          {lc14,
           <<"lc2() ->
                  Z = [[1],[2],[3]], 
                  [X || Z <- Z, % Z shadowed.
                        X <- Z].
           ">>,
           [warn_unused_vars],
           {warnings,[{{3,25},erl_lint,{shadowed_var,'Z',generate}}]}},

          {lc15,
           <<"lc3() ->
                  Z = [1,2,3], 
                  [X || X <- Z, 
                        Z <- Z]. % Z shadowed. Z unused.
           ">>,
           [warn_unused_vars],
           {warnings,[{{4,25},erl_lint,{unused_var,'Z'}},
                      {{4,25},erl_lint,{shadowed_var,'Z',generate}}]}},

          {lc16,
           <<"bin(Z) ->
                  case bar of
                      true ->
                          U = 2;
                      false ->
                          true
                  end,
                  case bar of
                      true ->
                          X = 2;
                      false ->
                          X = 3
                  end,
                  case foo of
                      true ->
                          Y = 3; % Y unused.
                      false ->
                          4
                  end,
                  case foo of
                      1 ->
                          U; % U unsafe.
                      2 ->
                          [Z || <<U:X>> <- Z]; % (X exported.) U unused.
                      3 ->
                          [Z || <<U:X>> <- Z], % (X exported.) U unused.
                          U % U unsafe.
                  end.
           ">>,
           [warn_unused_vars],
           {error,[{{22,27},erl_lint,{unsafe_var,'U',{'case',{2,19}}}},
                   {{27,27},erl_lint,{unsafe_var,'U',{'case',{2,19}}}}],
            [{{16,27},erl_lint,{unused_var,'Y'}},
             {{24,35},erl_lint,{unused_var,'U'}},
             {{26,35},erl_lint,{unused_var,'U'}}]}},

          {lc17,
           <<"bin(Z) ->
                  %% This used to pass erl_lint...
                  case bar of
                      true ->
                          U = 2;
                      false ->
                          true
                  end,
                  case bar of
                      true ->
                          X = 2;
                      false ->
                          X = 3
                  end,
                  case foo of
                      true ->
                          Y = 3; % Y unused.
                      false ->
                          4
                  end,
                  [Z || <<U:X>> <- Z], % (X exported.) U unused.
                  U. % U unsafe.
           ">>,
           [warn_unused_vars],
           {error,[{{22,19},erl_lint,{unsafe_var,'U',{'case',{3,19}}}}],
            [{{17,27},erl_lint,{unused_var,'Y'}},
             {{21,27},erl_lint,{unused_var,'U'}}]}},

          {lc18,
           <<"bin(Z) ->
                  case bar of
                      true ->
                          U = 2;
                      false ->
                          true
                  end,
                  case bar of
                      true ->
                          X = 2;
                      false ->
                          X = 3
                  end,
                  case foo of
                      true ->
                          Y = 3;
                      false ->
                          4
                  end,
                  [B || <<U: % U unused
                          U>> <- X, <<B:Y>> <- Z]. % U unsafe. Y unsafe. 
						% U shadowed. (X exported.)
           ">>,
           [warn_unused_vars],
           {error,[{{21,27},erl_lint,{unsafe_var,'U',{'case',{2,19}}}},
                   {{21,41},erl_lint,{unsafe_var,'Y',{'case',{14,19}}}}],
            [{{20,27},erl_lint,{unused_var,'U'}}
            ]}},

          {lc19,
           <<"p({B,C}) ->
                  <<A:B,A:C>> = <<17:32>>;
              p(B) ->
                  <<A:B>> = <<17:32>>. % A unused.
           ">>,
           [warn_unused_vars],
           {warnings,[{{4,21},erl_lint,{unused_var,'A'}}]}},

          {lc20,
           <<"c({I1,I2}) ->
                  if
                      <<I1:I2>> == <<>> ->
                          foo
                  end;
              c([C1,C2]) -> % C1 unused.
                  case foo of
                      <<C2:C2,
                        C3:C2>> -> % C3 unused.
                          bar
                  end.

           ">>,
           [warn_unused_vars],
           {warnings,[{{6,18},erl_lint,{unused_var,'C1'}},
                      {{7,19},sys_core_fold,{nomatch,no_clause}},
                      {{9,25},erl_lint,{unused_var,'C3'}}]}},

          {lc21,
           <<"t() ->
                  S = 8,
                  case <<3:8>> of
                      <<X:S>> ->
                          X;
                      <<S:X>> -> % X unbound
                          foo
                  end;
              t() ->
                  S = 8,
                  case <<3:8>> of
                      <<S:S>> ->
                          S;
                      <<Q:32>> -> % Q unused.
                          foo
                  end.
           ">>,
           [warn_unused_vars],
           {error,[{{6,27},erl_lint,{unbound_var,'X'}}],
                  [{{14,25},erl_lint,{unused_var,'Q'}}]}}

          ],
    [] = run(Config, Ts),
    ok.


%% Warnings for unused variables in records.
unused_vars_warn_rec(Config) when is_list(Config) ->
    Ts = [{rec1, % An example provided by Bjorn.
           <<"-record(edge,
                      {ltpr,
                       ltsu,
                       rtpr,
                       rtsu
                      }).

              f1(#edge{ltpr = A, ltsu = A}) ->
                  true;
              f1({Q, Q}) ->
                  true.

              f2(Edge, Etab) ->
                  case gb_trees:lookup(Edge, Etab) of
                      {value,#edge{ltpr=Same,ltsu=Same}} -> ok;
                      {value,_} -> error
                  end.

              bar(Edge, Etab) ->
                  case gb_trees:lookup(Edge, Etab) of
                      {Same,Same} -> ok;
                      {value,#edge{ltpr=Same}} -> ok; % Same unused.
                      {value,_} -> error
                  end.
           ">>,
           [warn_unused_vars],
           {warnings,[{{22,41},erl_lint,{unused_var,'Same'}}]}},
          {rec2,
           <<"-record(r, {a,b}).
              f(X, Y) -> #r{a=[K || K <- Y], b=[K || K <- Y]}.
              g(X, Y) -> #r{a=lists:map(fun (K) -> K end, Y),
                            b=lists:map(fun (K) -> K end, Y)}.
              h(X, Y) -> #r{a=case Y of _ when is_list(Y) -> Y end,
                            b=case Y of _ when is_list(Y) -> Y end}.
              i(X, Y) -> #r{a=if is_list(Y) -> Y end, b=if is_list(Y) -> Y end}.
             ">>,
           [warn_unused_vars],
           {warnings,[{{2,17},erl_lint,{unused_var,'X'}},
                      {{3,17},erl_lint,{unused_var,'X'}},
                      {{5,17},erl_lint,{unused_var,'X'}},
                      {{7,17},erl_lint,{unused_var,'X'}}]}},
          {rec3,
           <<"-record(r, {a}).
              t() -> X = 1, #r{a=foo, a=bar, a=qux}.
             ">>,
           [warn_unused_vars],
           {error,[{{2,39},erl_lint,{redefine_field,r,a}},
                   {{2,46},erl_lint,{redefine_field,r,a}}],
                  [{{2,22},erl_lint,{unused_var,'X'}}]}}],
    [] = run(Config, Ts),
    ok.

%% Warnings for unused variables in funs.
unused_vars_warn_fun(Config) when is_list(Config) ->
    Ts = [{fun1,
           <<"a({A,B}) -> % A unused.
                  fun(A) -> B end; % A shadowed. A unused.
              a([A,B]) ->
                  fun(<<A:B>>, % A shadowed. A unused.
                       <<Q:A>>) -> foo % Q unused.
                  end;
              a({A,B,C,D,E}) ->
                  fun(E) when C == <<A:A>>, <<17:B>> == D -> % E shadowed. E unused.
                          foo
                  end,
                  E;
              a([A,B,C,D,E]) -> % E unused.
                  fun() ->
                          (C == <<A:A>>) and (<<17:B>> == D)
                  end.
           ">>,
           [warn_unused_vars],
           {warnings,[{{1,24},erl_lint,{unused_var,'A'}},
                      {{2,23},erl_lint,{unused_var,'A'}},
                      {{2,23},erl_lint,{shadowed_var,'A','fun'}},
                      {{4,25},erl_lint,{unused_var,'A'}},
                      {{4,25},erl_lint,{shadowed_var,'A','fun'}},
                      {{5,26},erl_lint,{unused_var,'Q'}},
                      {{8,19},sys_core_fold,{ignored,useless_building}},
                      {{8,23},erl_lint,{unused_var,'E'}},
                      {{8,23},erl_lint,{shadowed_var,'E','fun'}},
                      {{12,26},erl_lint,{unused_var,'E'}}]}},

          {fun2,
           <<"u() ->
                  case foo of
                      true ->
                          U = 2;
                      false ->
                          true
                  end,
                  fun(U) -> foo end, % U unused.
                  U; % U unsafe.
              u() ->
                  case foo of
                      true ->
                          U = 2;
                      false ->
                          U = 3
                  end,
                  fun(U) -> foo end, % U shadowed. U unused.
                  U;
              u() ->
                  case foo of
                      true ->
                          U = 2; % U unused.
                      false ->
                          U = 3 % U unused.
                  end,
                  fun(U) -> foo end. % U shadowed. U unused.
           ">>,
           [warn_unused_vars],
           {error,[{{9,19},erl_lint,{unsafe_var,'U',{'case',{2,19}}}}],
              [{{8,23},erl_lint,{unused_var,'U'}},
               {{17,23},erl_lint,{unused_var,'U'}},
               {{17,23},erl_lint,{shadowed_var,'U','fun'}},
               {{22,27},erl_lint,{unused_var,'U'}},
               {{24,27},erl_lint,{unused_var,'U'}},
               {{26,23},erl_lint,{unused_var,'U'}},
               {{26,23},erl_lint,{shadowed_var,'U','fun'}}]}},
          {named_fun,
           <<"u() ->
                  fun U() -> foo end, % U unused.
                  U; % U unbound.
              u() ->
                  case foo of
                      true ->
                          U = 2;
                      false ->
                          true
                  end,
                  fun U() -> foo end, % U unused.
                  U; % U unsafe.
              u() ->
                  case foo of
                      true ->
                          U = 2;
                      false ->
                          U = 3
                  end,
                  fun U() -> foo end, % U shadowed. U unused.
                  U;
              u() ->
                  case foo of
                      true ->
                          U = 2; % U unused.
                      false ->
                          U = 3 % U unused.
                  end,
                  fun U() -> foo end; % U shadowed. U unused.
              u() ->
                  fun U(U) -> foo end; % U shadowed. U unused.
              u() ->
                  fun U(1) -> U; U(U) -> foo end; % U shadowed. U unused.
              u() ->
                  fun _(N) -> N + 1 end.  % Cover handling of '_' name.
           ">>,
           [warn_unused_vars],
           {error,[{{3,19},erl_lint,{unbound_var,'U'}},
                   {{12,19},erl_lint,{unsafe_var,'U',{'case',{5,19}}}}],
                  [{{2,19},erl_lint,{unused_var,'U'}},
                   {{11,19},erl_lint,{unused_var,'U'}},
                   {{20,19},erl_lint,{unused_var,'U'}},
                   {{20,19},erl_lint,{shadowed_var,'U','named fun'}},
                   {{25,27},erl_lint,{unused_var,'U'}},
                   {{27,27},erl_lint,{unused_var,'U'}},
                   {{29,19},erl_lint,{unused_var,'U'}},
                   {{29,19},erl_lint,{shadowed_var,'U','named fun'}},
                   {{31,19},erl_lint,{unused_var,'U'}},
                   {{31,25},erl_lint,{unused_var,'U'}},
                   {{31,25},erl_lint,{shadowed_var,'U','fun'}},
                   {{33,36},erl_lint,{unused_var,'U'}},
                   {{33,36},erl_lint,{shadowed_var,'U','fun'}}]}}
          ],
    [] = run(Config, Ts),
    ok.

%% Bit syntax, binsize variable used in the same matching.
unused_vars_OTP_4858(Config) when is_list(Config) ->
    Ts = [{otp_4858,
           <<"objs(<<Size:4/unit:8, B:Size/binary>>) ->
                  B.

              fel(<<Size:4/unit:8, B:BadSize/binary>>) -> % BadSize unbound.
                  BadSize.                                % B, Size unused.

              r9c_highlight() -> % B, Rest unused.
                 <<Size, B:Size/binary,Rest/binary>> = <<2,\"AB\",3,\"CDE\">>.
           ">>,
           [warn_unused_vars],
           {error,[{{4,38},erl_lint,{unbound_var,'BadSize'}}],
              [{{4,21},erl_lint,{unused_var,'Size'}},
               {{4,36},erl_lint,{unused_var,'B'}},
               {{8,26},erl_lint,{unused_var,'B'}},
               {{8,40},erl_lint,{unused_var,'Rest'}}]}}
         ],
    [] = run(Config, Ts),
    ok.

unused_unsafe_vars_warn(Config) when is_list(Config) ->
    Ts = [{unused_unsafe1,
           <<"t1() ->
                  UnusedVar1 = unused1,
                  try
                      UnusedVar2 = unused2
                  catch
                      _:_ ->
                          ok
                  end,
                  ok.
           ">>,
           [warn_unused_vars],
           {warnings,[{{2,19},erl_lint,{unused_var,'UnusedVar1'}},
                      {{4,23},erl_lint,{unused_var,'UnusedVar2'}}]}},
          {unused_unsafe2,
           <<"t2() ->
                  try
                      X = 1
                  catch
                      _:_ -> ok
                  end.
           ">>,
           [warn_unused_vars],
           {warnings,[{{3,23},erl_lint,{unused_var,'X'}}]}},
          {unused_unsafe2,
           <<"t3(X, Y) ->
                  X andalso Y.
           ">>,
           [warn_unused_vars],
           []},
          {unused_unsafe4,
           <<"t4() ->
                  _ = (catch X = X = 1),
                  _ = case ok of _ -> fun() -> ok end end,
                  fun (X) -> X end.
           ">>,
           [warn_unused_vars],
           []}],
    run(Config, Ts),
    ok.

%% Warnings for exported variables.
export_vars_warn(Config) when is_list(Config) ->
    Ts = [{exp1,
           <<"u() ->
                  case foo of
                      1 ->
                          A = 1,
                          B = 2,
                          W = 3, % W unused.
                          Z = 3; % Z unused.
                      2 ->
                          B = 2,
                          Z = 4 % Z unused.
                  end,
                  case bar of
                      true ->
                          A = 17, % A unsafe.
                          X = 3, % X unused.
                          U = 2,
                          U;
                      false ->
                          B = 19, % B exported.
                          U = 3; % U unused.
                      foo ->
                          X = 3,
                          X;
                      bar ->
                          X = 9, % X unused.
                          U = 14 % U unused.
                  end.
           ">>,
           [warn_unused_vars],
           {error,[{{14,27},erl_lint,{unsafe_var,'A',{'case',{2,19}}}}],
                  [{{6,27},erl_lint,{unused_var,'W'}},
                   {{7,27},erl_lint,{unused_var,'Z'}},
                   {{10,27},erl_lint,{unused_var,'Z'}},
                   {{15,27},erl_lint,{unused_var,'X'}},
                   {{19,27},erl_lint,{exported_var,'B',{'case',{2,19}}}},
                   {{20,27},erl_lint,{unused_var,'U'}},
                   {{25,27},erl_lint,{unused_var,'X'}},
                   {{26,27},erl_lint,{unused_var,'U'}}]}},

          {exp2,
           <<"bin(A) ->
                  receive
                      M ->
                           X = M,
                           Y = M,
                           Z = M
                  end,
                  [B || <<B:X>> <- A], % X exported.
                  Y = B, % Y exported. B unbound.
                  [B || B <- Z]. % Z exported. B shadowed.
           ">>,
           [warn_export_vars],
           {error,[{{9,23},erl_lint,{unbound_var,'B'}}],
                  [{{8,29},erl_lint,{exported_var,'X',{'receive',{2,19}}}},
                   {{9,19},erl_lint,{exported_var,'Y',{'receive',{2,19}}}},
                   {{10,25},erl_lint,{shadowed_var,'B',generate}},
                   {{10,30},erl_lint,{exported_var,'Z',{'receive',{2,19}}}}]}},

          {exp3,
           <<"bin(A) ->
                  receive
                      M ->
                           X = M,
                           Y = M,
                           Z = M
                  end,
                  [B || <<B:X>> <- A], % (X exported.)
                  Y = B, % Y exported. B unbound.
                  [B || B <- Z]. % (Z exported.) B shadowed.
           ">>,
           [],
           {error,[{{9,23},erl_lint,{unbound_var,'B'}}],
                  [{{9,19},erl_lint,{exported_var,'Y',{'receive',{2,19}}}},
                   {{10,25},erl_lint,{shadowed_var,'B',generate}}]}},

          {exp4,
           <<"t(X) ->
                  if true -> Z = X end,
                  case X of
                      1 -> Z;
                      2 -> X
                  end,
                  Z = X.
           ">>,
           [],
           {warnings,[{{7,19},erl_lint,{exported_var,'Z',{'if',{2,19}}}}]}}
         ],
    [] = run(Config, Ts),
    ok.

%% Shadowed variables are tested in other places, but here we test
%% that the warning can be turned off.
shadow_vars(Config) when is_list(Config) ->
    Ts = [{shadow1,
	   <<"bin(A) ->
                  receive
                      M ->
                           X = M,
                           Y = M,
                           Z = M
                  end,
                  [B || <<B:X>> <- A],
                  Y = B,
                  [B || B <- Z]. % B shadowed.
           ">>,
	   [nowarn_shadow_vars],
	   {error,[{{9,23},erl_lint,{unbound_var,'B'}}],
	    [{{9,19},erl_lint,{exported_var,'Y',{'receive',{2,19}}}}]}},
          {shadow2,
           <<"t() ->
                  _ = (catch MS = MS = 1), % MS used unsafe
                  _ = case ok of _ -> fun() -> ok end end,
                  fun (MS) -> MS end. % MS not shadowed here
           ">>,
           [],
           []}],
    [] = run(Config, Ts),
    ok.

%% Test that the 'warn_unused_import' option works.
unused_import(Config) when is_list(Config) ->
    Ts = [{imp1,
	   <<"-import(lists, [map/2,foldl/3]).
              t(L) ->
                 map(fun(X) -> 2*X end, L).
           ">>,
	   [warn_unused_import],
	   {warnings,[{{1,22},erl_lint,{unused_import,{{foldl,3},lists}}}]}}],
    [] = run(Config, Ts),
    ok.

documentation_attributes(Config) when is_list(Config) ->
    Ts = [{error_moduledoc,
           "-moduledoc \"\"\"
             Error
             \"\"\".
             -import(lists, []).

             -moduledoc \"\"\"
             Duplicate entry
             \"\"\".
             main() -> error.
            ",
          [],
          {errors,[{{6,15},erl_lint,{moduledoc,duplicate_doc_attribute,1}}], []}},

          {error_moduledoc,
           "-moduledoc \"Error\".
            -moduledoc false.
            ",
          [],
          {errors,[{{2,14},erl_lint,{moduledoc,duplicate_doc_attribute,1}}], []}},

          {error_moduledoc,
           "-moduledoc \"Error\".
            -moduledoc hidden.
            ",
          [],
          {errors,[{{2,14},erl_lint,{moduledoc,duplicate_doc_attribute,1}}], []}},

          {error_moduledoc,
           "-moduledoc hidden.
            -moduledoc \"Error\".
            ",
          [],
          {errors,[{{2,14},erl_lint,{moduledoc,duplicate_doc_attribute,1}}], []}},

          {error_doc_import,
          <<"-doc \"\"\"
             Error
             \"\"\".
             -import(lists, []).

             -doc \"\"\"
             Duplicate entry
             \"\"\".
             main() -> error.
            ">>,
          [],
          {errors,[{{6,15},erl_lint,{doc,duplicate_doc_attribute,1}}], []}},

          {error_doc_export,
           <<"-doc \"\"\"
              Error
              \"\"\".
              -export([]).

              -doc false.
              main() -> error.
            ">>,
          [],
          {errors,[{{6,16},erl_lint,{doc,duplicate_doc_attribute,1}}], []}},

          {error_doc_export_type,
           <<"-doc \"\"\"
              Error
              \"\"\".
              -export_type([]).

              -doc hidden.
              main() -> error.
            ">>,
          [],
          {errors,[{{6,16},erl_lint,{doc,duplicate_doc_attribute,1}}], []}},

          {error_doc_include,
           <<"-doc hidden.
              -include_lib(\"common_test/include/ct.hrl\").

              -doc \"\"\"
              Duplicate entry
              \"\"\".
              main() -> error.
            ">>,
          [],
          {errors,[{{4,16},erl_lint,{doc,duplicate_doc_attribute,1}}], []}},

          {error_doc_behaviour,
           <<"-doc false.
              -behaviour(gen_server).

              -doc hidden.
              main() -> error.
            ">>,
          [],
          {error,[{{4,16},erl_lint,{doc,duplicate_doc_attribute,1}}],
           [{{2,16},erl_lint,{undefined_behaviour_func,{handle_call,3},gen_server}},
            {{2,16},erl_lint,{undefined_behaviour_func,{handle_cast,2},gen_server}},
            {{2,16},erl_lint,{undefined_behaviour_func,{init,1},gen_server}}]}},

          {ok_doc_in_wrong_position,
           <<"-doc \"\"\"
              Bad position, that gets attached to function.
              We do not report this as an error.
              \"\"\".
              -include_lib(\"common_test/include/ct.hrl\").

              main() -> ok.
            ">>, [], []}
         ],
    [] = run(Config, Ts),
    ok.

%% Test singleton type variables
singleton_type_var_errors(Config) when is_list(Config) ->
    Ts = [{singleton_error1,
           <<"-spec test_singleton_typevars_in_union(Opts) -> term() when
                      Opts :: {ok, Unknown} | {error, Unknown}.
                test_singleton_typevars_in_union(_) ->
                  error.
             ">>,
           [],
           {errors,[{{2,36},erl_lint,{singleton_typevar,'Unknown'}}], []}},

          {singleton_error2,
           <<"-spec test_singleton_list_typevars_in_union([Opts]) -> term() when
                      Opts :: {ok, Unknown} | {error, Unknown}.
                test_singleton_list_typevars_in_union(_) ->
                    error.">>,
           [],
           {errors,[{{2,36},erl_lint,{singleton_typevar,'Unknown'}}], []}},

          {singleton_error3,
           <<"-spec test_singleton_list_typevars_in_list([Opts]) -> term() when
                      Opts :: {ok, Unknown}.
                test_singleton_list_typevars_in_list(_) ->
                    error.">>,
           [],
           {errors,
            [{{2,36},erl_lint,{singleton_typevar,'Unknown'}}],[]}},

          {singleton_error4,
           <<"-spec test_singleton_list_typevars_in_list_with_type_subst([{ok, Unknown}]) -> term().
                test_singleton_list_typevars_in_list_with_type_subst(_) ->
                    error.">>,
           [],
           {errors,[{{1,86},erl_lint,{singleton_typevar,'Unknown'}}],[]}},

          {singleton_error5,
           <<"-spec test_singleton_buried_typevars_in_union(Opts) -> term() when
                      Opts :: {ok, Foo} | {error, Foo},
                      Foo  :: {true, X} | {false, X}.
                test_singleton_buried_typevars_in_union(_) ->
                    error.">>,
           [],
           {errors,[{{3,38},erl_lint,{singleton_typevar,'X'}}], []}},

          {singleton_error6,
           <<"-spec test_multiple_subtypes_to_same_typevar(Opts) -> term() when
                      Opts :: {Foo, Bar} | Y,
                      Foo  :: X,
                      Bar  :: X,
                      Y    :: Z.
                test_multiple_subtypes_to_same_typevar(_) ->
                    error.">>,
           [],
           {errors,[{{5,31},erl_lint,{singleton_typevar,'Z'}}],[]}},

          {singleton_error7,
           <<"-spec test_duplicate_non_terminal_var_in_union(Opts) -> term() when
                      Opts :: {ok, U, U} | {error, U, U},
                      U    :: Foo.
                test_duplicate_non_terminal_var_in_union(_) ->
                    error.">>,
           [],
           {errors,[{{3,31},erl_lint,{singleton_typevar,'Foo'}}],[]}},

          {singleton_error8,
           <<"-spec test_unused_outside_union(Opts) -> term() when
                    Unused :: Unknown,
                    A :: Unknown,
                    Opts :: {Unknown | A}.
              test_unused_outside_union(_) ->
                  error.">>,
           [],
           {errors,[{{2,21},erl_lint,{singleton_typevar,'Unused'}}],[]}},

          {singleton_ok1,
           <<"-spec test_multiple_occurrences_singleton(Opts) -> term() when
                      Opts :: {Foo, Foo}.
                test_multiple_occurrences_singleton(_) ->
                    ok.">>,
           [],
           []},

          {singleton_ok2,
           <<"-spec id(X) -> X.
                id(X) ->
                    X.">>,
           [],
           []},

          {singleton_ok3,
           <<"-spec ok(Opts) -> term() when
                    Opts :: {Unknown, {ok, Unknown} | {error, Unknown}}.
              ok(_) ->
                  error.">>,
           [],
           []},

          {singleton_ok4,
           <<"-spec ok(Opts) -> term() when
                    Union :: {ok, Unknown} | {error, Unknown},
                    Opts :: {{tag, Unknown} | Union}.
              ok(_) ->
                  error.">>,
           [],
           []}

          ],

    [] = run(Config, Ts),
    ok.

%% Test warnings for unused functions.
unused_function(Config) when is_list(Config) ->
    Ts = [{func1,
	   <<"-export([t/1]).
              t(L) ->
                 lists:map(fun(X) -> 2*X end, L).

              fact(N) ->
                fact_1(N, 1).

              fact_1(1, P) -> P;
              fact_1(N, P) -> fact_1(N-1, P*N).
           ">>,
	   {[]},				%Tuple indicates no 'export_all'.
	   {warnings,[{{5,15},erl_lint,{unused_function,{fact,1}}},
		      {{8,15},erl_lint,{unused_function,{fact_1,2}}}]}},

	  %% Turn off warnings for unused functions.
	  {func2,
	   <<"-export([t/1]).
              t(L) ->
                 lists:map(fun(X) -> 2*X end, L).

              b(X) ->
                32*X.
           ">>,
	   {[nowarn_unused_function]},         %Tuple indicates no 'export_all'.
	   []},

	  %% Turn off warnings for unused functions using a -compile() directive.
	  {func3,
	   <<"-export([t/1]).
              -compile(nowarn_unused_function).

              t(L) ->
                 lists:map(fun(X) -> 2*X end, L).

              b(X) ->
                32*X.
           ">>,
	   {[]},		     %Tuple indicates no 'export_all'.
	   []},

          %% Raises a warning that flurb/1 is unused, and that we should
          %% probably export it because it's referenced in t/0 and u/1.
          {func4,
           <<"-export([t/0, u/1]).

              t() ->
                 fun ?MODULE:flurb/1.
              u(X) ->
                 ?MODULE:flurb(X).

              flurb(X) ->
                32*X.
           ">>,
           {[]}, %% Tuple indicates no 'export_all'.
           {warnings,[{{4,18},erl_lint,{unexported_function,{lint_test,flurb,1}}},
             {{6,19},erl_lint,{unexported_function,{lint_test,flurb,1}}},
             {{8,15},erl_lint,{unused_function,{flurb,1}}}]}},

          %% Turn off warnings for unexported functions using a -compile()
          %% directive.
          {func5,
           <<"-export([t/0, u/1]).
              -compile(nowarn_unexported_function).

              t() ->
                 fun ?MODULE:flurb/1.
              u(X) ->
                 ?MODULE:flurb(X).

              flurb(X) ->
                32*X.
           ">>,
           {[]}, %% Tuple indicates no 'export_all'.
           {warnings,[{{9,15},erl_lint,{unused_function,{flurb,1}}}]}},

          %% GH-9267: references prior to the -export directive caused false
          %% positives.
          {func6,
           <<"-record(blurf, {a = ?MODULE:t() }).
              -export([t/0]).

              t() ->
                 #blurf{a=hello}.
           ">>,
           {[]}, %% Tuple indicates no 'export_all'.
           []},

          %% GH-9267: references prior to the -export directive caused false
          %% positives.
          {func7,
           <<"-callback foo() -> ok.
              -export([t/0]).

              t() ->
                 ?MODULE:behaviour_info(callbacks).
           ">>,
           {[]}, %% Tuple indicates no 'export_all'.
           []}],

    [] = run(Config, Ts),
    ok.

%% Test warnings for unused types
types(Config) ->
    Ts = [{func1,
           <<"-type foo() :: term().">>,
           {[]},                                %Tuple indicates no export_all
           {warnings,[{{1,22},erl_lint,{unused_type,{foo,0}}}]}},

           %% Turn off warnings for unused types.
           {func2,
           <<"-type foo() :: term().">>,
           {[nowarn_unused_type]},              %Tuple indicates no export_all
           []},

           %% Turn off warnings for unused types using a -compile() directive.
           {func3,
           <<"-compile(nowarn_unused_type).
              -type foo() :: term().">>,
           {[]},                                %Tuple indicates no export_all
           []},

          %% OTP-17301. Types nonempty_binary(), nonempty_bitstring().
          {binary1,
           <<"-type nonempty_binary() :: term().">>,
           [nowarn_unused_type],
           {warnings,[{{1,22},erl_lint,
                       {redefine_builtin_type,{nonempty_binary,0}}}]}},
          {binary2,
           <<"-type nonempty_bitstring() :: term().">>,
           [nowarn_unused_type],
           {warnings,[{{1,22},erl_lint,
                       {redefine_builtin_type,{nonempty_bitstring,0}}}]}},

          %% Test for bad types.
          {bad_export_type1,
           <<"-export_type(no_arity).
              -export_type(undefined_type/0).
              -export_type([fine/0,fine/0]).
              -type fine() :: any().
              -type duplicated() :: atom().
              -type duplicated() :: integer().
             ">>,
           [nowarn_unused_type],
           {error,[{{1,22},erl_lint,{bad_export_type,no_arity}},
                   {{2,16},erl_lint,{bad_export_type,{undefined_type,0}}},
                   {{6,16},erl_lint,{redefine_type,{duplicated,0}}}],
            [{{3,16},erl_lint,{duplicated_export_type,{fine,0}}}]}}
         ],

    [] = run(Config, Ts),
    ok.

%% OTP-4671. Errors for unsafe variables.
unsafe_vars(Config) when is_list(Config) ->
    Ts = [{unsafe1,
           <<"t() ->
                 (X = true) orelse (Y = false),
                  Y.
           ">>,
           [warn_unused_vars],
           {error,[{{3,19},erl_lint,{unsafe_var,'Y',{'orelse',{2,29}}}}],
            [{{2,19},erl_lint,{unused_var,'X'}}]}},
          {unsafe2,
           <<"t2() ->
                  (X = true) orelse (Y = false),
                  X.
           ">>,
           [warn_unused_vars],
           {warnings,[{{2,38},erl_lint,{unused_var,'Y'}}]}},
          {unsafe3,
           <<"t3() ->
                  (X = true) andalso (Y = false),
                  Y.
           ">>,
           [warn_unused_vars],
           {error,[{{3,19},erl_lint,{unsafe_var,'Y',{'andalso',{2,30}}}}],
            [{{2,20},erl_lint,{unused_var,'X'}}]}},
          {unsafe4,
           <<"t4() ->
                  (X = true) andalso (true = X),
                  X.
           ">>,
           [warn_unused_vars],
           []},
          {unsafe5,
           <<"t5() ->
                  Y = 3,
                  (X = true) andalso (X = true),
                  {X,Y}.
           ">>,
           [warn_unused_vars],
           []},
          {unsafe6,
           <<"t6() ->
                  X = true,
                  (X = true) andalso (true = X),
                  X.
           ">>,
           [warn_unused_vars],
           []},
          {unsafe7,
           <<"t7() ->
                  (if true -> X = 3; false -> true end) 
                      andalso (X > 2),
                  X.
           ">>,
           [warn_unused_vars],
           {errors,[{{3,32},erl_lint,{unsafe_var,'X',{'if',{2,20}}}},
                    {{4,19},erl_lint,{unsafe_var,'X',{'if',{2,20}}}}],
            []}},
          {unsafe8,
           <<"t8(X) ->
                  case X of _ -> catch _Y = 1 end,
                  _Y."
           >>,
           [],
           {errors,[{{3,19},erl_lint,{unsafe_var,'_Y',{'catch',{2,34}}}}],
            []}},
           {unsafe9,
           <<"t9(X) ->
                  case X of
                      1 ->
                          catch A = 1, % unsafe only here
                          B = 1,
                          C = 1,
                          D = 1;
                      2 ->
                          A = 2,
                          %% B not bound here
                          C = 2,
                          catch D = 2; % unsafe in two clauses
                      3 ->
                          A = 3,
                          B = 3,
                          C = 3,
                          catch D = 3; % unsafe in two clauses
                      4 ->
                          A = 4,
                          B = 4,
                          C = 4,
                          D = 4
                  end,
                  {A,B,C,D}."
           >>,
           [],
           {errors,[{{24,20},erl_lint,{unsafe_var,'A',{'catch',{4,27}}}},
                    {{24,22},erl_lint,{unsafe_var,'B',{'case',{2,19}}}},
                    {{24,26},erl_lint,{unsafe_var,'D',{'case',{2,19}}}}],
            []}},
          {unsafe_comprehension,
           <<"foo() ->
                 case node() of
                     P when is_tuple(P) ->
                         P;
                     _ ->
                         ok
                 end,
                 Y = try
                         ok
                     catch _C:_R ->
                             [1 || _ <- []]
                     end,
                 case Y of
                     P ->
                         P
                 end.
           ">>,
           [],
           {errors,[{{14,22},erl_lint,{unsafe_var,'P',{'case',{2,18}}}}],[]}}
         ],
    [] = run(Config, Ts),
    ok.

%% OTP-4831, seq8202. No warn_unused_vars and unsafe variables.
unsafe_vars2(Config) when is_list(Config) ->
    Ts = [{unsafe2_1,
           <<"foo(State) ->
                  case State of
                      true ->
                          if
                              false -> ok;
                              true ->  State1=State
                          end
                  end,
                  State1. % unsafe
           ">>,
           [warn_unused_vars],
           {errors,[{{9,19},erl_lint,{unsafe_var,'State1',{'if',{4,27}}}}],[]}},
          {unsafe2_2,
           <<"foo(State) ->
                  case State of
                      true ->
                          if
                              false -> ok;
                              true ->  State1=State
                          end
                  end,
                  State1. % unsafe
           ">>,
           [],
           {errors,[{{9,19},erl_lint,{unsafe_var,'State1',{'if',{4,27}}}}],[]}}
         ],
    [] = run(Config, Ts),
    ok.

%% Errors for unsafe variables in try/catch constructs.
unsafe_vars_try(Config) when is_list(Config) ->
    Ts = [{unsafe_try1,
	   <<"foo2() ->
                try self()
                catch
                  Class:Data -> Result={Class,Data}
                end,
                Result.
              foo3a() ->
                try self() of
                  R -> R
                catch
                  Class:Data -> Result={Class,Data}
                end,
                Result.
              foo3b() ->
                try self() of
                  Result -> ok
                catch
                  Class:Data -> {Class,Data}
                end,
                Result.
           ">>,
	   [],
	   {errors,[{{6,17},erl_lint,{unsafe_var,'Result',{'try',{2,17}}}},
		    {{13,17},erl_lint,{unsafe_var,'Result',{'try',{8,17}}}},
		    {{20,17},erl_lint,{unsafe_var,'Result',{'try',{15,17}}}}],
	    []}},
	  {unsafe_try2,
	   <<"foo1a() ->
                Try = 
                  try self()
                  catch
                    Class:Data -> Rc={Class,Data}
                  after
                    Ra=ok
                  end,
                {Try,Rc,Ra}.
              foo1b() ->
                Try = 
                  try self() of
                    R -> R
                  catch
                    Class:Data -> Rc={Class,Data}
                  after
                    Ra=R
                  end,
                {Try,Rc,Ra}.
              foo2() ->
                Try = 
                  try self() of
                    R -> Ro=R
                  catch
                    Class:Data -> {Class,Data}
                  after
                    Ra=R
                  end,
                {Try,Ro,Ra}.
              foo3() ->
                Try = 
                  try self() of
                    R -> Ro=R
                  catch
                    Class:Data -> Rc={Class,Data}
                  after
                    Ra=R
                  end,
                {Try,R,Ro,Rc,Ra}.
           ">>,
	   [],
	   {errors,[{{9,22},erl_lint,{unsafe_var,'Rc',{'try',{3,19}}}},
                    {{9,25},erl_lint,{unsafe_var,'Ra',{'try',{3,19}}}},
		    {{17,24},erl_lint,{unsafe_var,'R',{'try',{12,19}}}},
		    {{19,22},erl_lint,{unsafe_var,'Rc',{'try',{12,19}}}},
		    {{19,25},erl_lint,{unsafe_var,'Ra',{'try',{12,19}}}},
		    {{27,24},erl_lint,{unsafe_var,'R',{'try',{22,19}}}},
		    {{29,22},erl_lint,{unsafe_var,'Ro',{'try',{22,19}}}},
		    {{29,25},erl_lint,{unsafe_var,'Ra',{'try',{22,19}}}},
		    {{37,24},erl_lint,{unsafe_var,'R',{'try',{32,19}}}},
		    {{39,22},erl_lint,{unsafe_var,'R',{'try',{32,19}}}},
		    {{39,24},erl_lint,{unsafe_var,'Ro',{'try',{32,19}}}},
                    {{39,27},erl_lint,{unsafe_var,'Rc',{'try',{32,19}}}},
                    {{39,30},erl_lint,{unsafe_var,'Ra',{'try',{32,19}}}}],
	    []}},
	  {unsafe_try3,
	   <<"foo1(X) ->
                Try = 
                  try R=self()
                  catch
                    Class:Data -> Rc={X,R,Class,Data}
                  end,
                {X,Try,Rc}.
	      foo2(X) ->
                Try = 
                  try R=self() of
                    RR -> Ro={X,R,RR}
                  catch
                    Class:Data -> {X,R,RR,Ro,Class,Data}
                  end,
                {X,Try,R,RR,Ro,Class,Data}.
	      foo3(X) ->
                Try = 
                  try R=self() of
                    RR -> {X,R,RR}
                  catch
                    Class:Data -> {X,R,RR,Class,Data}
                  after
                    Ra={X,R,RR,Class,Data}
                  end,
                {X,Try,R,RR,Ra,Class,Data}.
           ">>,
	   [],
	   {errors,[{{5,41},erl_lint,{unsafe_var,'R',{'try',{3,19}}}},
		    {{7,24},erl_lint,{unsafe_var,'Rc',{'try',{3,19}}}},
		    {{13,38},erl_lint,{unsafe_var,'R',{'try',{10,19}}}},
		    {{13,40},erl_lint,{unbound_var,'RR','R'}},
		    {{13,43},erl_lint,{unbound_var,'Ro','R'}},
		    {{15,24},erl_lint,{unsafe_var,'R',{'try',{10,19}}}},
		    {{15,26},erl_lint,{unsafe_var,'RR',{'try',{10,19}}}},
		    {{15,29},erl_lint,{unsafe_var,'Ro',{'try',{10,19}}}},
		    {{15,32},erl_lint,{unsafe_var,'Class',{'try',{10,19}}}},
		    {{15,38},erl_lint,{unsafe_var,'Data',{'try',{10,19}}}},
		    {{21,38},erl_lint,{unsafe_var,'R',{'try',{18,19}}}},
		    {{21,40},erl_lint,{unbound_var,'RR','R'}},
		    {{23,27},erl_lint,{unsafe_var,'R',{'try',{18,19}}}},
		    {{23,29},erl_lint,{unsafe_var,'RR',{'try',{18,19}}}},
		    {{23,32},erl_lint,{unsafe_var,'Class',{'try',{18,19}}}},
		    {{23,38},erl_lint,{unsafe_var,'Data',{'try',{18,19}}}},
		    {{25,24},erl_lint,{unsafe_var,'R',{'try',{18,19}}}},
		    {{25,26},erl_lint,{unsafe_var,'RR',{'try',{18,19}}}},
		    {{25,29},erl_lint,{unsafe_var,'Ra',{'try',{18,19}}}},
		    {{25,32},erl_lint,{unsafe_var,'Class',{'try',{18,19}}}},
                    {{25,38},erl_lint,{unsafe_var,'Data',{'try',{18,19}}}}],
	    []}},
	  {unsafe_try4,
	   <<"foo1(X) ->
                Try = 
                  try R=self() of
                    RR -> Ro={X,R,RR}
                  catch
                    Class:Data -> Rc={X,R,RR,Ro,Class,Data}
                  after
                    Ra={X,R,RR,Ro,Rc,Class,Data}
                  end,
                {X,Try,R,RR,Ro,Rc,Ra,Class,Data}.
           ">>,
	   [],
	   {errors,[{{6,41},erl_lint,{unsafe_var,'R',{'try',{3,19}}}},
		    {{6,43},erl_lint,{unbound_var,'RR','R'}},
		    {{6,46},erl_lint,{unbound_var,'Ro','R'}},
		    {{8,27},erl_lint,{unsafe_var,'R',{'try',{3,19}}}},
		    {{8,29},erl_lint,{unsafe_var,'RR',{'try',{3,19}}}},
		    {{8,32},erl_lint,{unsafe_var,'Ro',{'try',{3,19}}}},
		    {{8,35},erl_lint,{unsafe_var,'Rc',{'try',{3,19}}}},
		    {{8,38},erl_lint,{unsafe_var,'Class',{'try',{3,19}}}},
		    {{8,44},erl_lint,{unsafe_var,'Data',{'try',{3,19}}}},
		    {{10,24},erl_lint,{unsafe_var,'R',{'try',{3,19}}}},
		    {{10,26},erl_lint,{unsafe_var,'RR',{'try',{3,19}}}},
		    {{10,29},erl_lint,{unsafe_var,'Ro',{'try',{3,19}}}},
		    {{10,32},erl_lint,{unsafe_var,'Rc',{'try',{3,19}}}},
		    {{10,35},erl_lint,{unsafe_var,'Ra',{'try',{3,19}}}},
		    {{10,38},erl_lint,{unsafe_var,'Class',{'try',{3,19}}}},
                    {{10,44},erl_lint,{unsafe_var,'Data',{'try',{3,19}}}}],
	    []}},
          {unsafe_try5,
           <<"bang() ->
                case 1 of
                  nil ->
                    Acc = 2;
                  _ ->
                    try
                      Acc = 3,
                      Acc
                    catch _:_ ->
                      ok
                    end
                end,
                Acc.
           ">>,
           [],
           {errors,[{{13,17},erl_lint,{unsafe_var,'Acc',{'try',{6,21}}}}],[]}}],
        [] = run(Config, Ts),
    ok.

%% Unsized binary fields are forbidden in patterns of bit string generators.
unsized_binary_in_bin_gen_pattern(Config) when is_list(Config) ->
    Ts = [{unsized_binary_in_bin_gen_pattern,
	   <<"t({bc,binary,Bin}) ->
		  << <<X,Tail/binary>> || <<X,Tail/binary>> <= Bin >>;
	      t({bc,bytes,Bin}) ->
		  << <<X,Tail/binary>> || <<X,Tail/bytes>> <= Bin >>;
	      t({bc,bits,Bin}) ->
		  << <<X,Tail/bits>> || <<X,Tail/bits>> <= Bin >>;
	      t({bc,bitstring,Bin}) ->
		  << <<X,Tail/bits>> || <<X,Tail/bitstring>> <= Bin >>;
              t({bc,binary_lit,Bin}) ->
		  << <<X>> || <<X,1/binary>> <= Bin >>;
	      t({bc,bytes_lit,Bin}) ->
		  << <<X>> || <<X,a/bytes>> <= Bin >>;
	      t({lc,binary,Bin}) ->
		  [ {X,Tail} || <<X,Tail/binary>> <= Bin ];
	      t({lc,bytes,Bin}) ->
		  [ {X,Tail} || <<X,Tail/bytes>> <= Bin ];
	      t({lc,bits,Bin}) ->
		  [ {X,Tail} || <<X,Tail/bits>> <= Bin ];
	      t({lc,bitstring,Bin}) ->
		  [ {X,Tail} || <<X,Tail/bitstring>> <= Bin ];
              t({lc,bits_lit,Bin}) ->
		  [ X || <<X,42/bits>> <= Bin ];
	      t({lc,bitstring_lit,Bin}) ->
		  [ X || <<X,b/bitstring>> <= Bin ].">>,
	   [],
	   {errors,
	    [{{2,33},erl_lint,unsized_binary_in_bin_gen_pattern},
	     {{4,33},erl_lint,unsized_binary_in_bin_gen_pattern},
	     {{6,31},erl_lint,unsized_binary_in_bin_gen_pattern},
	     {{8,31},erl_lint,unsized_binary_in_bin_gen_pattern},
             {{10,21},erl_lint,unsized_binary_in_bin_gen_pattern},
             {{12,21},erl_lint,unsized_binary_in_bin_gen_pattern},
             {{14,23},erl_lint,unsized_binary_in_bin_gen_pattern},
             {{16,23},erl_lint,unsized_binary_in_bin_gen_pattern},
	     {{18,23},erl_lint,unsized_binary_in_bin_gen_pattern},
	     {{20,23},erl_lint,unsized_binary_in_bin_gen_pattern},
	     {{22,16},erl_lint,unsized_binary_in_bin_gen_pattern},
	     {{24,16},erl_lint,unsized_binary_in_bin_gen_pattern}],
	     []}}],
    [] = run(Config, Ts),
    ok.

%% OTP-4670. Guards, is_record in particular.
guard(Config) when is_list(Config) ->
    %% Well, these could be plain code...
    Ts = [{guard1,
           <<"-record(apa, {}).
              t(A) when atom(A) ->
                  atom;
              t(A) when binary(A) ->
                  binary;
              t(A) when constant(A) ->
                  constant;
              t(A) when float(A) ->
                  float;
              t(A) when function(A) ->
                  function;
              t(A) when integer(A) ->
                  integer;
              t(A) when is_atom(A) ->
                  is_atom;
              t(A) when is_binary(A) ->
                  is_binary;
              t(A) when is_constant(A) ->
                  is_constant;
              t(A) when is_float(A) ->
                  is_float;
              t(A) when is_function(A) ->
                  is_function;
              t(A) when is_integer(A) ->
                  is_integer;
              t(A) when is_list(A) ->
                  is_list;
              t(A) when is_number(A) ->
                  is_number;
              t(A) when is_pid(A) ->
                  is_pid;
              t(A) when is_port(A) ->
                  is_port;
              t(A) when is_record(A, apa) ->
                  is_record;
              t(A) when is_record(A, apa, 1) ->
                  is_record;
              t(A) when is_reference(A) ->
                  is_reference;
              t(A) when is_tuple(A) ->
                  is_tuple;
              t(A) when list(A) ->
                  list;
              t(A) when number(A) ->
                  number;
              t(A) when pid(A) ->
                  pid;
              t(A) when port(A) ->
                  port;
              t(A) when record(A, apa) ->
                  record;
              t(A) when reference(A) ->
                  reference;
              t(A) when tuple(A) ->
                  tuple.
           ">>,
           [nowarn_obsolete_guard],
           {errors,
	    [{{6,25},erl_lint,illegal_guard_expr},
             {{18,25},erl_lint,illegal_guard_expr}],
	    []}},
          {guard2,
           <<"-record(apa,{}).
              t1(A) when atom(A), atom(A) ->
                  atom;
              t1(A) when binary(A), binary(A) ->
                  binary;
              t1(A) when constant(A), constant(A) ->
                  constant;
              t1(A) when float(A), float(A) ->
                  float;
              t1(A) when function(A), function(A) ->
                  function;
              t1(A) when integer(A), integer(A) ->
                  integer;
              t1(A) when is_atom(A), is_atom(A) ->
                  is_atom;
              t1(A) when is_binary(A), is_binary(A) ->
                  is_binary;
              t1(A) when is_constant(A), is_constant(A) ->
                  is_constant;
              t1(A) when is_float(A), is_float(A) ->
                  is_float;
              t1(A) when is_function(A), is_function(A) ->
                  is_function;
              t1(A) when is_integer(A), is_integer(A) ->
                  is_integer;
              t1(A) when is_list(A), is_list(A) ->
                  is_list;
              t1(A) when is_number(A), is_number(A) ->
                  is_number;
              t1(A) when is_pid(A), is_pid(A) ->
                  is_pid;
              t1(A) when is_port(A), is_port(A) ->
                  is_port;
              t1(A) when is_record(A, apa), is_record(A, apa) ->
                  is_record;
              t1(A) when is_record(A, apa, 1), is_record(A, apa, 1) ->
                  is_record;
              t1(A) when is_reference(A), is_reference(A) ->
                  is_reference;
              t1(A) when is_tuple(A), is_tuple(A) ->
                  is_tuple;
              t1(A) when list(A), list(A) ->
                  list;
              t1(A) when number(A), number(A) ->
                  number;
              t1(A) when pid(A), pid(A) ->
                  pid;
              t1(A) when port(A), port(A) ->
                  port;
              t1(A) when record(A, apa), record(A, apa) ->
                  record;
              t1(A) when reference(A), reference(A) ->
                  reference;
              t1(A) when tuple(A), tuple(A) ->
                  tuple.
           ">>,
           [nowarn_obsolete_guard],
	   {errors,[{{6,26},erl_lint,illegal_guard_expr},
		    {{6,39},erl_lint,illegal_guard_expr},
		    {{18,26},erl_lint,illegal_guard_expr},
		    {{18,42},erl_lint,illegal_guard_expr}],
	    []}},
          {guard3,
           <<"-record(apa,{}).
              t2(A) when atom(A); atom(A) ->
                  atom;
              t2(A) when binary(A); binary(A) ->
                  binary;
              t2(A) when float(A); float(A) ->
                  float;
              t2(A) when function(A); function(A) ->
                  function;
              t2(A) when integer(A); integer(A) ->
                  integer;
              t2(A) when is_atom(A); is_atom(A) ->
                  is_atom;
              t2(A) when is_binary(A); is_binary(A) ->
                  is_binary;
              t2(A) when is_float(A); is_float(A) ->
                  is_float;
              t2(A) when is_function(A); is_function(A) ->
                  is_function;
              t2(A) when is_integer(A); is_integer(A) ->
                  is_integer;
              t2(A) when is_list(A); is_list(A) ->
                  is_list;
              t2(A) when is_number(A); is_number(A) ->
                  is_number;
              t2(A) when is_pid(A); is_pid(A) ->
                  is_pid;
              t2(A) when is_port(A); is_port(A) ->
                  is_port;
              t2(A) when is_record(A, apa); is_record(A, apa) ->
                  is_record;
              t2(A) when is_record(A, gurka, 1); is_record(A, gurka, 1) ->
                  is_record;
              t2(A) when is_reference(A); is_reference(A) ->
                  is_reference;
              t2(A) when is_tuple(A); is_tuple(A) ->
                  is_tuple;
              t2(A) when list(A); list(A) ->
                  list;
              t2(A) when number(A); number(A) ->
                  number;
              t2(A) when pid(A); pid(A) ->
                  pid;
              t2(A) when port(A); port(A) ->
                  port;
              t2(A) when record(A, apa); record(A, apa) ->
                  record;
              t2(A) when reference(A); reference(A) ->
                  reference;
              t2(A) when tuple(A); tuple(A) ->
                  tuple.
           ">>,
           [nowarn_obsolete_guard],
	   []},
          {guard4,
           <<"-record(apa, {}).
              t3(A) when float(A) or float(A) -> % coercing... (badarg)
                  float;
              t3(A) when is_atom(A) or is_atom(A) ->
                  is_atom;
              t3(A) when is_binary(A) or is_binary(A) ->
                  is_binary;
              t3(A) when is_float(A) or is_float(A) ->
                  is_float;
              t3(A) when is_function(A) or is_function(A) ->
                  is_function;
              t3(A) when is_integer(A) or is_integer(A) ->
                  is_integer;
              t3(A) when is_list(A) or is_list(A) ->
                  is_list;
              t3(A) when is_number(A) or is_number(A) ->
                  is_number;
              t3(A) when is_pid(A) or is_pid(A) ->
                  is_pid;
              t3(A) when is_port(A) or is_port(A) ->
                  is_port;
              t3(A) when is_record(A, apa) or is_record(A, apa) ->
                  is_record;
              t3(A) when is_record(A, apa, 1) or is_record(A, apa, 1) ->
                  is_record;
              t3(A) when is_reference(A) or is_reference(A) ->
                  is_reference;
              t3(A) when is_tuple(A) or is_tuple(A) ->
                  is_tuple.
           ">>,
           [nowarn_obsolete_guard],
           []}],
    [] = run(Config, Ts),
    Ts1 = [{guard5,
            <<"-record(apa, {}).
               t3(A) when record(A, {apa}) ->
                   foo;
               t3(A) when is_record(A, {apa}) ->
                   foo;
               t3(A) when erlang:is_record(A, {apa}) ->
                   foo;
               t3(A) when is_record(A, {apa}, 1) ->
                   foo;
               t3(A) when erlang:is_record(A, {apa}, 1) ->
                   foo;
               t3(A) when is_record(A, apa, []) ->
                   foo;
               t3(A) when erlang:is_record(A, apa, []) ->
                   foo;
               t3(A) when record(A, apa) ->
                   foo;
               t3(A) when is_record(A, apa) ->
                   foo;
               t3(A) when erlang:is_record(A, apa) ->
                   foo.
            ">>,
            [warn_unused_vars, nowarn_obsolete_guard],
            {errors,[{{2,27},erl_lint,illegal_guard_expr},
		     {{4,27},erl_lint,illegal_guard_expr},
		     {{6,27},erl_lint,illegal_guard_expr},
		     {{8,27},erl_lint,illegal_guard_expr},
		     {{10,27},erl_lint,illegal_guard_expr},
		     {{12,27},erl_lint,illegal_guard_expr},
		     {{14,27},erl_lint,illegal_guard_expr}],
	     []}},
           {guard6,
            <<"-record(apa,{a=a,b=foo:bar()}).
              apa() ->
                 [X || X <- [], #apa{a = a} == {r,X,foo}];
              apa() ->
                 [X || X <- [], #apa{b = b} == {r,X,foo}];
              apa() ->
                 [X || X <- [], #ful{a = a} == {r,X,foo}].
            ">>,
            [],
            {errors,[{{7,33},erl_lint,{undefined_record,ful}}],
             []}},
           {guard7,
            <<"-record(apa,{}).
               t() ->
               [X || X <- [1,#apa{},3], (3+is_record(X, apa)) or 
                                        (is_record(X, apa)*2)].
            ">>,
            [],
            []},
	   {guard8,
	    <<"t(A) when erlang:is_foobar(A) -> ok;
	      t(A) when A ! ok -> ok;
	      t(A) when A ++ [x] -> ok."
	    >>,
	    [],
	    {errors,[{{1,31},erl_lint,illegal_guard_expr},
		     {{2,20},erl_lint,illegal_guard_expr},
		     {{3,20},erl_lint,illegal_guard_expr}],[]}},
           {guard9,
            <<"t(X, Y) when erlang:'andalso'(X, Y) -> ok;
               t(X, Y) when erlang:'orelse'(X, Y) -> ok.
            ">>,
            [],
            {errors,[{{1,34},erl_lint,illegal_guard_expr},
                     {{2,29},erl_lint,illegal_guard_expr}],
             []}},
           {guard10,
            <<"is_port(_) -> false.
               t(P) when port(P) -> ok.
            ">>,
            [],
            {error,
	     [{{2,26},erl_lint,{obsolete_guard_overridden,port}}],
	     [{{2,26},erl_lint,{obsolete_guard,{port,1}}}]}},
           {guard11,
            <<"-record(bar, {a = mk_a()}).
               mk_a() -> 1.

               test_rec(Rec) when Rec =:= #bar{} -> true.
               map_pattern(#{#bar{} := _}) -> ok.
              ">>,
            [],
            {errors,
             [{{4,43},erl_lint,{illegal_guard_local_call,{mk_a,0}}},
              {{5,30},erl_lint,{illegal_guard_local_call,{mk_a,0}}}],
             []}}
          ],
    [] = run(Config, Ts1),
    ok.

%% OTP-4886. Calling is_record with given record name.
otp_4886(Config) when is_list(Config) ->
    Ts = [{otp_4886,
           <<"t() ->
                  X = {foo},
                  is_record(X, foo),
                  erlang:is_record(X, foo),
                  {erlang,is_record}(X, foo),
                  %% Note: is_record/3 does not verify that the record is defined,
                  %% so the following lines should give no errors.
                  is_record(X, foo, 1),
                  erlang:is_record(X, foo, 1),
                  {erlang,is_record}(X, foo, 1).
             ">>,
           [],
           {errors,[{{3,32},erl_lint,{undefined_record,foo}},
                    {{4,39},erl_lint,{undefined_record,foo}},
                    {{5,41},erl_lint,{undefined_record,foo}}],
            []}}],
    [] = run(Config, Ts),
    ok.

%% OTP-4988. Error when in-lining non-existent functions.
otp_4988(Config) when is_list(Config) ->
    Ts = [{otp_4988,
           <<"-compile({inline, [{f,3},{f,4},{f,2},{f,a},{1,foo}]}).
              -compile({inline, {g,1}}).
              -compile({inline, {g,12}}).
              -compile(inline).
              -compile({inline_size,100}).

              f(A, B) ->
                  {g(A), B}.

              g(A) ->
                  {A}.
             ">>,
           [],
            {errors,[{{1,22},erl_lint,{bad_inline,{1,foo}}},
                    {{1,22},erl_lint,{bad_inline,{f,3},{f,[2]}}},
                    {{1,22},erl_lint,{bad_inline,{f,4},{f,[2]}}},
                    {{1,22},erl_lint,{bad_inline,{f,a},{f,[2]}}},
                    {{3,16},erl_lint,{bad_inline,{g,12},{g,[1]}}}],
            []}}],
    [] = run(Config, Ts),
    ok.

%% OTP-5091. Patterns and the bit syntax: invalid warnings.
otp_5091(Config) when is_list(Config) ->
    Ts = [{otp_5091_1,
           <<"t() ->
                 [{Type, Value} || <<Type:16, _Len:16, 
                                    Value:_Len/binary>> <- []].
             ">>,
           [],
           []},
          {otp_5091_2,
           <<"t() ->
                 %% This one has always been handled OK:
                 <<Type:16, _Len:16, 
                      Value:_Len/binary>> = <<18:16, 9:16, \"123456789\">>,
                 {Type, Value}.
             ">>,
           [],
           []},
          {otp_5091_3,
           <<"t() ->
                 fun(<<Type:16, _Len:16, Value:_Len/binary>>) ->
                     {Type, Value}
                 end.
             ">>,
           [],
           []},
          {otp_5091_4,
           <<"t() ->
                 L = 8,
                 F = fun(<<A:L,B:A>>) -> B end,
                 F(<<16:8, 7:16>>).
             ">>,
           [],
           []},
          {otp_5091_5,
           <<"t() ->
                 L = 8,
                 F = fun(<<L: % L shadowed.
                            L,
                           B:
                            L>>) -> B end,
                 F(<<16:8, 7:16>>).
             ">>,
           [],
           {warnings,[{{3,28},erl_lint,{shadowed_var,'L','fun'}}]}},
          {otp_5091_6,
           <<"t(A) ->
                 (fun(<<L:16,M:L,N:M>>) -> ok end)(A).
             ">>,
           [],
           {warnings,[{{2,34},erl_lint,{unused_var,'N'}}]}},
          {otp_5091_7,
           <<"t() ->
                  U = 8, 
                  (fun(<<U: % U shadowed.
                          U>>) -> U end)(<<32:8>>).
             ">>,
           [],
           {warnings,[{{3,26},erl_lint,{shadowed_var,'U','fun'}}]}},
          {otp_5091_8,
           <<"t() ->
                  [X || <<A:8,
                          B:A>> <- [],
                        <<X:8>> <- [B]].
             ">>,
           [],
           []},
          {otp_5091_9,
           <<"t() ->
                  L = 8,
                  F = fun(<<L: % Shadow.
                           L,
                           L:
                           L,
                           L:
                           L
                           >>) ->
                              L
                      end,
                  F(<<16:8, 8:16, 32:8>>).
             ">>,
           [],
           {warnings,[{{3,29},erl_lint,{shadowed_var,'L','fun'}}]}},
          {otp_5091_10,
           <<"t() ->
                L = 8, <<A:L,B:A>> = <<16:8, 7:16>>, B.
             ">>,
           [],
           []},
          {otp_5091_11,
           <<"t() ->
                fun(<<L:16,L:L,L:L>>) -> ok end.
             ">>,
           [],
           []},
          {otp_5091_12,
           <<"t([A,B]) ->
                 fun(<<A:B>>, % A shadowed and unused
                     <<Q:A>>) -> foo % Q unused. 'outer' A is used.
                 end.
             ">>,
           [],
           {warnings,[{{2,24},erl_lint,{unused_var,'A'}},
                      {{2,24},erl_lint,{shadowed_var,'A','fun'}},
                      {{3,24},erl_lint,{unused_var,'Q'}}]}},
          {otp_5091_13,
           <<"t([A,B]) -> % A unused, B unused
                 fun({A,B}, % A shadowed, B unused, B shadowed
                     {Q,A}) -> foo % Q unused. 'inner' A is used
                 end.
             ">>,
           [],
           {warnings,[{{1,24},erl_lint,{unused_var,'A'}},
                      {{1,26},erl_lint,{unused_var,'B'}},
                      {{2,23},erl_lint,{shadowed_var,'A','fun'}},
                      {{2,25},erl_lint,{unused_var,'B'}},
                      {{2,25},erl_lint,{shadowed_var,'B','fun'}},
                      {{3,23},erl_lint,{unused_var,'Q'}}]}},
          {otp_5091_14,
           <<"t() ->
                 A = 4,
                 fun(<<A: % shadowed, unused
                       A>>) -> 2 end.
             ">>,
           [],
           {warnings,[{{3,24},erl_lint,{unused_var,'A'}},
                      {{3,24},erl_lint,{shadowed_var,'A','fun'}}]}},
          {otp_5091_15,
           <<"t() ->
                 A = 4, % unused
                 fun(<<A:8, % shadowed
                       16:A>>) -> 2 end.
             ">>,
           [],
           {warnings,[{{2,18},erl_lint,{unused_var,'A'}},
                      {{3,24},erl_lint,{shadowed_var,'A','fun'}}]}},
          {otp_5091_16,
           <<"t() ->
                 A = 4,
                 fun(<<8:A, % 
                       A:8>>) -> 7 end. % shadowed, unused
             ">>,
           [],
           {warnings,[{{4,24},erl_lint,{unused_var,'A'}},
                      {{4,24},erl_lint,{shadowed_var,'A','fun'}}]}},
          {otp_5091_17,
           <<"t() ->
                 L = 16,
                 fun(<<L: % shadow
                       L>>, % 'outer' L
                     <<L: % shadow and match
                       L>>) -> % 'outer' L
                         a
                 end.
             ">>,
           [],
           {warnings,[{{3,24},erl_lint,{shadowed_var,'L','fun'}}]}},
          {otp_5091_18,
           <<"t() ->
                 L = 4,      % L unused
                 fun({L,     % L shadowed
                      L},
                     {L,
                      L}) ->
                         a
                 end.
             ">>,
           [],
           {warnings,[{{2,18},erl_lint,{unused_var,'L'}},
                      {{3,23},erl_lint,{shadowed_var,'L','fun'}}]}},
          {otp_5091_19,
           <<"t() ->
                 L = 4,
                 [L || <<L: % shadowed
                         L, 
                         L:
                         L>> <- []].
             ">>,
           [],
           {warnings,[{{3,26},erl_lint,{shadowed_var,'L',generate}}]}},
          {otp_5091_20,
           <<"t() ->
                 L = 4, % L unused.
                 [1 || L <- []]. % L unused, L shadowed.
             ">>,
           [],
           {warnings,[{{2,18},erl_lint,{unused_var,'L'}},
                      {{3,24},erl_lint,{unused_var,'L'}},
                      {{3,24},erl_lint,{shadowed_var,'L',generate}}]}},
          {otp_5091_21,
           <<"t() ->
                 L = 4,
                 [1 || L <- [L]]. % L shadowed. L unused.
             ">>,
           [],
           {warnings,[{{3,24},erl_lint,{unused_var,'L'}},
                      {{3,24},erl_lint,{shadowed_var,'L',generate}}]}},
          {otp_5091_22,
           <<"t() ->
                 L = 4, % unused
                 fun(L) -> L end. % shadowed
             ">>,
           [],
           {warnings,[{{2,18},erl_lint,{unused_var,'L'}},
                      {{3,22},erl_lint,{shadowed_var,'L','fun'}}]}},
          {otp_5091_23,
           <<"t([A,A]) -> a.">>, [], []},
          {otp_5091_24,
           <<"t({A,A}) -> a.">>, [], []},
          {otp_5091_25,
           <<"-record(r, {f1,f2}).
              t(#r{f1 = A, f2 = A}) -> a.">>, [], []}],

    [] = run(Config, Ts),
    ok.

%% OTP-5276. Check the 'deprecated' attributed.
otp_5276(Config) when is_list(Config) ->
    Ts = [{otp_5276_1,
          <<"-deprecated([{frutt,0,next_version}]).
             -deprecated([{does_not_exist,1}]).
             -deprecated('foo bar').
             -deprecated(module).
             -deprecated([{f,'_'}]).
             -deprecated([{t,0}]).
             -deprecated([{t,'_',eventually}]).
             -deprecated([{'_','_',never}]).
             -deprecated([{{badly,formed},1}]).
             -deprecated([{'_','_',next_major_release}]).
             -deprecated([{atom_to_list,1}]).
             -export([t/0]).
             frutt() -> ok.
             t() -> ok.
            ">>,
           {[]},
           {error,[{{1,22},erl_lint,{bad_deprecated,{frutt,0}}},
                   {{2,15},erl_lint,{bad_deprecated,{does_not_exist,1}}},
                   {{3,15},erl_lint,{invalid_deprecated,'foo bar'}},
                   {{5,15},erl_lint,{bad_deprecated,{f,'_'}}},
                   {{8,15},erl_lint,{invalid_deprecated,{'_','_',never}}},
                   {{9,15},erl_lint,{invalid_deprecated,{{badly,formed},1}}},
		   {{11,15},erl_lint,{bad_deprecated,{atom_to_list,1}}}],
            [{{13,14},erl_lint,{unused_function,{frutt,0}}}]}}],
    [] = run(Config, Ts),
    ok.

%% OTP-5917. Check the 'deprecated' attributed.
otp_5917(Config) when is_list(Config) ->
    Ts = [{otp_5917_1,
          <<"-export([t/0]).

             -deprecated({t,0}).

             t() ->
                 foo.
            ">>,
           {[]},
           []}],
    [] = run(Config, Ts),
    ok.

%% OTP-6585. Check the deprecated guards list/1, pid/1, ....
otp_6585(Config) when is_list(Config) ->
    Ts = [{otp_6585_1,
          <<"-export([t/0]).

             -record(r, {}).

             f(A) when list(A) -> list;
             f(R) when record(R, r) -> rec;
             f(P) when pid(P) -> pid.

             t() ->
                 f([]).
            ">>,
           [warn_obsolete_guard],
           {warnings,[{{5,24},erl_lint,{obsolete_guard,{list,1}}},
                      {{6,24},erl_lint,{obsolete_guard,{record,2}}},
                      {{7,24},erl_lint,{obsolete_guard,{pid,1}}}]}}],
    [] = run(Config, Ts),
    ok.

%% OTP-5338. Bad warning in record initialization.
otp_5338(Config) when is_list(Config) ->
    %% OTP-5878: variables like X are no longer allowed in initialisations
    Ts = [{otp_5338,
          <<"-record(c, {a = <<X:7/binary-unit:8>>}).
              t() ->
                  X = <<\"hejsans\">>,
                  #c{}.
            ">>,
           [],
           {error,[{{1,39},erl_lint,{unbound_var,'X'}}],
                  [{{3,19},erl_lint,{unused_var,'X'}}]}}],
    [] = run(Config, Ts),
    ok.

%% OTP-5362. deprecated_function,
%% {nowarn_unused_funtion,FAs}, 'better' line numbers.
otp_5362(Config) when is_list(Config) ->
    Ts = [{otp_5362_1,
          <<"-include_lib(\"stdlib/include/qlc.hrl\").

             -file(?FILE, 1000).

             t() ->
                 qlc:q([X || X <- [],
                             begin A = 3, true end]).
            ">>,
           {[warn_unused_vars]},
           {warnings,[{{1002,14},erl_lint,{unused_function,{t,0}}},
                      {{1004,36},erl_lint,{unused_var,'A'}}]}},

          {otp_5362_2,
          <<"-export([inline/0]).

             -import(lists, [a/1,b/1]). % b/1 is not used

             -compile([{inline,{inl,7}}]).    % undefined
             -compile([{inline,[{inl,17}]}]). % undefined
             -compile([{inline,{inl,1}}]).    % OK

             foop() ->   % unused function
                 a([]),  % used import, OK
                 fipp(). % undefined

             inline() ->
                 inl(foo).

             inl(_) ->
                 true.

             not_used() ->      % unused function
                 true.

             -compile({nowarn_unused_function,[{and_not_used,2}]}). % unknown 
             and_not_used(_) -> % unused function
                 foo.

             -compile({nowarn_unused_function,{unused_function,2}}).
             unused_function(_, _) ->
                 ok.

             -compile({nowarn_unused_function,{totally_undefined,0}}).
           ">>,
          {[warn_unused_vars, warn_unused_import]},
           {error,[{{5,15},erl_lint,{bad_inline,{inl,7},{inl,[1]}}},
                   {{6,15},erl_lint,{bad_inline,{inl,17},{inl,[1]}}},
                   {{11,18},erl_lint,{undefined_function,{fipp,0},{foop,[0]}}},
                   {{22,15},erl_lint,{bad_nowarn_unused_function,
                                      {and_not_used,2},{and_not_used,[1]}}},
                   {{30,15},erl_lint,
                    {bad_nowarn_unused_function,{totally_undefined,0}}}],
            [{{3,15},erl_lint,{unused_import,{{b,1},lists}}},
             {{9,14},erl_lint,{unused_function,{foop,0}}},
             {{19,14},erl_lint,{unused_function,{not_used,0}}},
             {{23,14},erl_lint,{unused_function,{and_not_used,1}}}]}},

          {otp_5362_3,
           <<"-record(a, {x,
                          x}).
              -record(a, {x,
                          X}). % erl_parse
              -record(a, [x,
                          x]). % erl_parse
              -record(ok, {a,b}).

              -record(r, {a = #ok{}, 
                          b = (#ok{})#ok.a}).

              t() ->
                  {#a{},
                   #nix{},
                   #ok{nix = []},
                   #ok{Var = 4}, 
                   #r{}
                  }.
           ">>,
           {[nowarn_unused_function]},
           {errors2, [{{4,27},erl_parse,"bad record field"},
                      {{5,26},erl_parse,"bad record declaration"}],
                     [{{2,27},erl_lint,{redefine_field,a,x}},
                      {{14,20},erl_lint,{undefined_record,nix}},
                      {{15,24},erl_lint,{undefined_field,ok,nix}},
                      {{16,24},erl_lint,{field_name_is_variable,ok,'Var'}}]}},

	  %% `nowarn_bif_clash` has changed behaviour as local functions
	  %% nowdays supersede auto-imported BIFs. Therefore,
	  %% `nowarn_bif_clash` in itself generates an error (OTP-8579).
          {otp_5362_4,
           <<"-compile(warn_deprecated_function).
              -compile(warn_bif_clash).
              spawn(A) ->
                  erlang:now(),
                  spawn(A).
           ">>,
           {[nowarn_unused_function,
             warn_deprecated_function]},
           {warnings,
            [{{4,19},erl_lint,{deprecated,{erlang,now,0},
                          "see the \"Time and Time Correction in Erlang\" "
                          "chapter of the ERTS User's Guide for more "
                          "information"}},
             {{5,19},erl_lint,{call_to_redefined_bif,{spawn,1}}}]}},
          {otp_5362_5,
           <<"-compile(nowarn_deprecated_function).
              -compile(nowarn_bif_clash).
              spawn(A) ->
                  erlang:now(),
                  spawn(A).
           ">>,
           {[nowarn_unused_function]},
	   {errors,
            [{{2,16},erl_lint,disallowed_nowarn_bif_clash}],[]}},

          %% The special nowarn_X are not affected by general warn_X.
          {otp_5362_6,
           <<"-compile({nowarn_deprecated_function,{erlang,now,0}}).
              -compile({nowarn_bif_clash,{spawn,1}}).
              spawn(A) ->
                  erlang:now(),
                  spawn(A).
           ">>,
           {[nowarn_unused_function,
             warn_deprecated_function,
             warn_bif_clash]},
           {errors,
            [{{2,16},erl_lint,disallowed_nowarn_bif_clash}],[]}},

          {otp_5362_7,
           <<"-export([spawn/1]).
              -compile({nowarn_deprecated_function,{erlang,now,0}}).
              -compile({nowarn_bif_clash,{spawn,1}}).
              -compile({nowarn_bif_clash,{spawn,2}}). % bad
              -compile([{nowarn_deprecated_function, 
                                [{erlang,now,-1},{3,now,-1}]}, % 2 bad
                     {nowarn_deprecated_function, {{a,b,c},now,-1}}]). % bad
              -compile({nowarn_bif_clash,{not_a_bif_at_all,1}}).
              spawn(A) ->
                  erlang:now(),
                  spawn(A).
           ">>,
           {[nowarn_unused_function]},
           {errors,[{{3,16},erl_lint,disallowed_nowarn_bif_clash},
                    {{4,16},erl_lint,disallowed_nowarn_bif_clash},
                    {{4,16},erl_lint,{bad_nowarn_bif_clash,{spawn,2},
                                      {spawn,[1]}}},
                    {{8,16},erl_lint,disallowed_nowarn_bif_clash},
                    {{8,16},erl_lint,
                     {bad_nowarn_bif_clash,{not_a_bif_at_all,1}}}],
            []}
           },

          {otp_5362_8,
           <<"-export([spawn/1]).
              -compile(warn_deprecated_function).
              -compile(warn_bif_clash).
              spawn(A) ->
                  erlang:now(),
                  spawn(A).
           ">>,
           {[nowarn_unused_function,
             {nowarn_bif_clash,{spawn,1}}]}, % has no effect
           {warnings,
            [{{5,19},erl_lint,{deprecated,{erlang,now,0},
                          "see the \"Time and Time Correction in Erlang\" "
                          "chapter of the ERTS User's Guide for more "
                          "information"}}]}},

          {otp_5362_9,
           <<"-include_lib(\"stdlib/include/qlc.hrl\").
              -record(a, {x = qlc:q([{X,Y} || {X} <- [],{Y} <- [],X =:= Y])}).
              -export([t/0]).              
              t() -> #a{}.
          ">>,
           {[]},
           []},

          {otp_5362_10,
           <<"-compile({nowarn_deprecated_function,{erlang,now,0}}).
              -compile({nowarn_bif_clash,{spawn,1}}).
              -import(x,[spawn/1]).
              spin(A) ->
                  erlang:now(),
                  spawn(A).
           ">>,
           {[nowarn_unused_function,
             warn_deprecated_function,
             warn_bif_clash]},
           {errors,
            [{{2,16},erl_lint,disallowed_nowarn_bif_clash}],[]}},

	  {call_deprecated_function,
	   <<"t(X) -> calendar:local_time_to_universal_time(X).">>,
	   [],
	   {warnings,
            [{{1,29},erl_lint,{deprecated,{calendar,local_time_to_universal_time,1},
                          "use calendar:local_time_to_universal_time_dst/1 "
                          "instead"}}]}},

	  {call_removed_function,
	   <<"t(X) -> erlang:hash(X, 10000).">>,
	   [],
	   {warnings,
            [{{1,29},erl_lint,{removed,{erlang,hash,2},
                          "use erlang:phash2/2 instead"}}]}},

	  {nowarn_call_removed_function_1,
	   <<"t(X) -> erlang:hash(X, 10000).">>,
	   [{nowarn_removed,{erlang,hash,2}}],
	   []},

	  {nowarn_call_removed_function_2,
	   <<"t(X) -> os_mon_mib:any_function_really(erlang:hash(X, 10000)).">>,
	   [nowarn_removed],
	   []},

	  {call_removed_module,
	   <<"t(X) -> os_mon_mib:any_function_really(X).">>,
	   [],
           {warnings,[{{1,29},erl_lint,
                       {removed,{os_mon_mib,any_function_really,1},
                        "this module was removed in OTP 22.0"}}]}},

	  {nowarn_call_removed_module,
	   <<"t(X) -> os_mon_mib:any_function_really(X).">>,
	   [{nowarn_removed,os_mon_mib}],
	   []}

	 ],

    [] = run(Config, Ts),
    ok.

%% OTP-15456. All compiler options can now be given in the option list
%% (as opposed to only in files).
otp_15456(Config) when is_list(Config) ->
    Ts = [
          %% {nowarn_deprecated_function,[{M,F,A}]} can now be given
          %% in the option list as well as in an attribute.
          %% Wherever it occurs, it is not affected by
          %% warn_deprecated_function.
          {otp_15456_1,
           <<"-compile({nowarn_deprecated_function,{erlang,now,0}}).
              -export([foo/0]).

              foo() ->
                  {erlang:now(), random:seed0(), random:seed(1, 2, 3),
                   random:uniform(), random:uniform(42)}.
           ">>,
           {[{nowarn_deprecated_function,{random,seed0,0}},
             {nowarn_deprecated_function,[{random,uniform,0},
                                          {random,uniform,1}]},
             %% There should be no warnings when attempting to
             %% turn of warnings for functions that are not
             %% deprecated or not used in the module.
             {nowarn_deprecated_function,{random,uniform_s,1}},
             {nowarn_deprecated_function,{erlang,abs,1}},
             warn_deprecated_function]},
           {warnings,[{{5,50},erl_lint,
                       {deprecated,{random,seed,3},
                        "use the 'rand' module instead"}}]}},

          %% {nowarn_unused_function,[{M,F,A}]} can be given
          %% in the option list as well as in an attribute.
          %% It was incorrectly documented to only work when
          %% given in an attribute.
          {otp_15456_2,
           <<"-compile({nowarn_unused_function,foo/0}).
              foo() -> ok.
              bar() -> ok.
              foobar() -> ok.
              barf(_) -> ok.
              other() -> ok.
           ">>,
           {[{nowarn_unused_function,[{bar,0},{foobar,0}]},
             {nowarn_unused_function,{barf,1}},
             %% There should be no warnings when attempting to
             %% turn of warnings for unused functions that are not
             %% defined in the module.
             {nowarn_unused_function,{not_defined_in_module,1}},
             warn_unused_function]},
           {warnings,[{{6,15},erl_lint,{unused_function,{other,0}}}]}
          }],

    [] = run(Config, Ts),
    ok.

%% OTP-5371. Aliases for bit syntax expressions are no longer allowed.
%% GH-6348/OTP-18297: Updated for OTP 26 to allow aliases.
otp_5371(Config) when is_list(Config) ->
    Ts = [{otp_5371_1,
           <<"t(<<A:8>> = <<B:8>>) ->
                  {A,B}.
             ">>,
	   [],
           []},
	  {otp_5371_2,
           <<"x([<<A:8>>] = [<<B:8>>]) ->
                  {A,B}.
              y({a,<<A:8>>} = {b,<<B:8>>}) ->
                  {A,B}.
             ">>,
           [],
           {warnings,[{{3,15},v3_core,{nomatch,pattern}}]}},
	  {otp_5371_3,
           <<"-record(foo, {a,b,c}).
              -record(bar, {x,y,z}).
              -record(buzz, {x,y}).
              a(#foo{a = <<X:8>>} = #bar{x = <<Y:8>>}) ->
                  {X,Y}.
              b(#foo{b = <<X:8>>} = #foo{b = <<Y:4,Z:4>>}) ->
                  {X,Y,Z}.
              c(#foo{a = <<X:8>>} = #buzz{x = <<Y:8>>}) ->
                  {X,Y}.
              d(#foo{a=x,b = <<X:8>>} = #buzz{y = <<Y:8>>}) ->
                  {X,Y}.
              e(#foo{a=x,b = <<X:8>>} = #buzz{x=glurf,y = <<Y:8>>}) ->
                  {X,Y}.
             ">>,
	   [],
           {warnings,[{{4,15},v3_core,{nomatch,pattern}},
                      {{8,15},v3_core,{nomatch,pattern}},
                      {{10,15},v3_core,{nomatch,pattern}},
                      {{12,15},v3_core,{nomatch,pattern}}]}},
	  {otp_5371_4,
           <<"-record(foo, {a,b,c}).
              -record(bar, {x,y,z}).
              -record(buzz, {x,y}).
              a(#foo{a = <<X:8>>,b=x} = #foo{b = <<Y:8>>}) ->
                  {X,Y}.
              b(#foo{a = <<X:8>>} = #bar{y = <<Y:4,Z:4>>}) ->
                  {X,Y,Z}.
              c(#foo{a = <<X:8>>} = #buzz{y = <<Y:8>>}) ->
                  {X,Y}.
             ">>,
	   [],
	   {warnings,[{{4,15},v3_core,{nomatch,pattern}},
		      {{6,15},v3_core,{nomatch,pattern}},
		      {{8,15},v3_core,{nomatch,pattern}}]}}
	 ],
    [] = run(Config, Ts),
    ok.

%% OTP-7227. Some aliases for bit syntax expressions were still allowed.
%% GH-6348/OTP-18297: Updated for OTP 26 to allow aliases.
otp_7227(Config) when is_list(Config) ->
    Ts = [{otp_7227_1,
           <<"t([<<A:8>> = {C,D} = <<B:8>>]) ->
                  {A,B,C,D}.
             ">>,
	   [],
           {warnings,[{{1,21},v3_core,{nomatch,pattern}}]}},
	  {otp_7227_2,
           <<"t([(<<A:8>> = {C,D}) = <<B:8>>]) ->
                  {A,B,C,D}.
             ">>,
	   [],
	   {warnings,[{{1,21},v3_core,{nomatch,pattern}}]}},
	  {otp_7227_3,
           <<"t([(<<A:8>> = {C,D}) = (<<B:8>> = <<C:8>>)]) ->
                  {A,B,C,D}.
             ">>,
	   [],
           {warnings,[{{1,21},v3_core,{nomatch,pattern}}]}},
	  {otp_7227_4,
           <<"t(Val) ->
                  <<A:8>> = <<B:8>> = Val,
                  {A,B}.
             ">>,
	   [],
	   []},
	  {otp_7227_5,
           <<"t(Val) ->
                  <<A:8>> = X = <<B:8>> = Val,
                  {A,B,X}.
             ">>,
	   [],
	   []},
	  {otp_7227_6,
           <<"t(X, Y) ->
                  <<A:8>> = <<X:4,Y:4>>,
                  A.
             ">>,
	   [],
	   []},
	  {otp_7227_7,
           <<"t(Val) ->
                  (<<A:8>> = X) = (<<B:8>> = <<A:4,B:4>>) = Val,
                  {A,B,X}.
             ">>,
	   [],
           []},
          {otp_7227_8,
           <<"t(Val) ->
                  (<<A:8>> = X) = (Y = <<B:8>>) = Val,
                  {A,B,X,Y}.
             ">>,
	   [],
	   []},
	  {otp_7227_9,
           <<"t(Val) ->
                  (Z = <<A:8>> = X) = (Y = <<B:8>> = W) = Val,
                  {A,B,X,Y,Z,W}.
             ">>,
	   [],
           []}
	 ],
    [] = run(Config, Ts),
    ok.

%% GH-6348/OTP-18297: Allow aliases of binary patterns.
binary_aliases(Config) when is_list(Config) ->
    Ts = [{binary_aliases_1,
           <<"t([<<Size:8,_/bits>> = <<_:8,Data:Size/bits>>]) ->
                  Data.
             ">>,
	   [],
           {errors,[{{1,55},erl_lint,{unbound_var,'Size'}}],[]}},
          {binary_aliases_2,
           <<"t(#{key := <<Size:8,_/bits>>} = #{key := <<_:8,Data:Size/bits>>}) ->
                  Data.
             ">>,
	   [],
           {errors,[{{1,73},erl_lint,{unbound_var,'Size'}}],[]}},
          {binary_aliases_3,
           <<"t(<<_:8,Data:Size/bits>> = <<Size:8,_/bits>>) ->
                  Data.
             ">>,
	   [],
           {errors,[{{1,34},erl_lint,{unbound_var,'Size'}}],[]}},
          {binary_aliases_4,
           <<"t([<<_:8,Data:Size/bits>> = <<Size:8,_/bits>>]) ->
                  Data.
             ">>,
	   [],
           {errors,[{{1,35},erl_lint,{unbound_var,'Size'}}],[]}},
          {binary_aliases_5,
           <<"t(Bin) ->
                  <<_:8,A:Size>> = <<_:8,B:Size/bits>> = <<Size:8,_/bits>> = Bin,
                  {A,B,Size}.
             ">>,
           [],
           []},
          {binary_aliases_6,
           <<"t(<<_:8,A:Size>> = <<_:8,B:Size/bits>> = <<Size:8,_/bits>>) ->
                  {A,B,Size}.
             ">>,
           [],
           {errors,[{{1,31},erl_lint,{unbound_var,'Size'}},
                    {{1,48},erl_lint,{unbound_var,'Size'}}],
            []}}
         ],
    [] = run(Config, Ts),
    ok.

%% OTP-5494. Warnings for functions exported more than once.
otp_5494(Config) when is_list(Config) ->
    Ts = [{otp_5494_1,
           <<"-export([t/0]).
              -export([t/0]).
              t() -> a.
             ">>,
           [],
           {warnings,[{{2,16},erl_lint,{duplicated_export,{t,0}}}]}}],
    [] = run(Config, Ts),
    ok.

%% OTP-5644. M:F/A in record initialization.
otp_5644(Config) when is_list(Config) ->
    %% This test is a no-op. Although {function,mfa,i,1} was
    %% transformed into {function,Line,i,1} by copy_expr, the module
    %% was never checked (Line is the line number).
    %% (OTP-5878: somewhat modified.)
    Ts = [{otp_5644,
          <<"-record(c, {a = fun ?MODULE:i/1(17)}).
              t() ->
                  #c{}.

              i(X) ->
                  X.
            ">>,
           [nowarn_unexported_function],
           []}],
    [] = run(Config, Ts),
    ok.

%% OTP-5878. Record declaration: forward references, introduced variables.
otp_5878(Config) when is_list(Config) ->
    Ts = [{otp_5878_10,
          <<"-record(rec1, {a = #rec2{}}).
             -record(rec2, {a = #rec1{}}).
             t() ->#rec1{}.
            ">>,
           [warn_unused_record],
           {error,[{{1,40},erl_lint,{undefined_record,rec2}}],
                  [{{2,15},erl_lint,{unused_record,rec2}}]}},

          {otp_5878_20,
           <<"-record(r1, {a = begin A = 4, {A,B} end}). % B unbound
              -record(r2, {e = begin A = 3, #r1{} end}).
              t() -> #r2{}.
             ">>,
           [warn_unused_record],
           {error,[{{1,44},erl_lint,{variable_in_record_def,'A'}},
                   {{1,54},erl_lint,{unbound_var,'B'}},
                   {{2,38},erl_lint,{variable_in_record_def,'A'}}],
            [{{1,22},erl_lint,{unused_record,r1}}]}},

          {otp_5878_30,
           <<"-record(r1, {t = case foo of _ -> 3 end}).
              -record(r2, {a = case foo of A -> A; _ -> 3 end}).
              -record(r3, {a = case foo of A -> A end}).
              -record(r4, {a = fun _AllowedFunName() -> allowed end}).
              t() -> {#r1{},#r2{},#r3{},#r4{}}.
             ">>,
           [warn_unused_record],
           {errors,[{{2,44},erl_lint,{variable_in_record_def,'A'}},
                    {{3,44},erl_lint,{variable_in_record_def,'A'}}],
            []}},

          {otp_5878_40,
           <<"-record(r1, {foo = A}). % A unbound
              -record(r2, {a = fun(X) -> X end(3)}).
              -record(r3, {a = [X || X <- [1,2,3]]}).
              t() -> {#r1{},#r2{},#r3{}}.
             ">>,
           [warn_unused_record],
           {errors,[{{1,40},erl_lint,{unbound_var,'A'}}],[]}},

          {otp_5878_50,
           <<"-record(r1, {a = {A, % A unbound
                                A}}). % A unbound
              -record(r2, {a = begin case foo of 
                                         A -> A
                                     end,
                                     A
                                end}).
              -record(r3, {a = fun(X) ->
                                       case foo of
                                           A -> A
                                       end
                               end
                          }).
              -record(r4, {a = case foo of
                                   foo ->
                                       case foo of
                                           A -> A
                                       end;
                                   _ -> 
                                       bar
                               end}).
              t() -> {#r1{},#r2{},#r3{},#r4{}}.
             ">>,
           [warn_unused_record],
           {error,[{{1,39},erl_lint,{unbound_var,'A'}},
                   {{2,33},erl_lint,{unbound_var,'A'}},
                   {{4,42},erl_lint,{variable_in_record_def,'A'}},
                   {{17,44},erl_lint,{variable_in_record_def,'A'}}],
            [{{8,36},erl_lint,{unused_var,'X'}}]}},

          {otp_5878_60,
           <<"-record(r1, {a = fun(NotShadowing) -> NotShadowing end}).
              t() ->
                  NotShadowing = 17,
                  {#r1{}, NotShadowing}.
             ">>,
           [warn_unused_record],
           []},

          {otp_5878_70,
           <<"-record(r1, {a = fun(<<X:8>>) -> X end,
                           b = case <<17:8>> of
                                   <<_:Y>> -> Y;
                                   <<Y:8>> -> 
                                       Y
                               end}).
              t() -> #r1{}.
             ">>,
           [warn_unused_record],
           {errors,[{{3,40},erl_lint,{unbound_var,'Y'}},
                    {{4,38},erl_lint,{variable_in_record_def,'Y'}}],
            []}},

          {otp_5878_80,
           <<"-record(r, {a = [X || {A,Y} <- [{1,2},V={3,4}],
                                    begin Z = [1,2,3], true end,
                                    X <- Z ++ [A,Y]]}).
              t() ->#r{}.
             ">>,
           [warn_unused_record],
           {warnings,[{{1,59},erl_lint,{unused_var,'V'}}]}},

          {otp_5878_90,
           <<"-record(r, {a = foo()}). % unused

              t() -> ok.
             ">>,
           [warn_unused_record],
           {error,[{{1,37},erl_lint,{undefined_function,{foo,0}}}],
            [{{1,22},erl_lint,{unused_record,r}}]}}

         ],
    [] = run(Config, Ts),

    Abstr = <<"-module(lint_test, [A, B]).
            ">>,
    {errors,[{{1,2},erl_lint,pmod_unsupported}],[]} =
        run_test2(Config, Abstr, [warn_unused_record]),

    QLC1 = <<"-module(lint_test).
              -include_lib(\"stdlib/include/qlc.hrl\").
              -export([t/0]).
              -record(r1, {a = qlc:e(qlc:q([X || X <- [1,2,3]]))}).
              -record(r2, {a = qlc:q([X || X <- [1,2,3]])}).
              -record(r3, {a = qlc:q([X || {A,Y} <- [{1,2},V={3,4}],
                                           begin Z = [1,2,3], true end,
                                           X <- Z ++ [A,Y]])}).
              t() -> {#r1{},#r2{},#r3{}}.
             ">>,
    {error,[{{8,49},qlc,{used_generator_variable,'Z'}},
            {{8,55},qlc,{used_generator_variable,'A'}},
            {{8,57},qlc,{used_generator_variable,'Y'}}],
           [{{6,60},erl_lint,{unused_var,'V'}}]} =
        run_test2(Config, QLC1, [warn_unused_record]),

    Ill1 = <<"-module(lint_test).
              -export([t/0]).
              -record(r, {a = true}).
              -record(r1, {a,b}).
              -record(r2, {a = #r1{a = true}}).
              -record(r3, {a = A}). % A is unbound
              -record(r4, {a = dict:new()}).

              t() ->
                  case x() of
                      _ when (#r{})#r.a ->
                          a; 
                      _ when (#r4{})#r.a -> % illegal
                          b;
                      _ when (#r3{q = 5})#r.a -> % no warning for unbound A
                          q;
                      _ when (#r{q = 5})#r.a ->
                          a; 
                      _ when (((#r{a = #r2{}})#r.a)#r2.a)#r1.a ->
                          b;
                      _ when #r{a = dict:new()} -> % illegal
                          c; 
                      _ when l() > 3 -> % illegal, does not use l/0...
                          d;
                      _ ->
                          w
                  end.

              l() ->
                  foo.

              x() ->
                  bar.
              ">>,
   
    {errors,[{{6,32},erl_lint,{unbound_var,'A'}},
             {{13,31},erl_lint,illegal_guard_expr},
             {{15,35},erl_lint,{undefined_field,r3,q}},
             {{17,34},erl_lint,{undefined_field,r,q}},
             {{21,37},erl_lint,illegal_guard_expr},
             {{23,30},erl_lint,{illegal_guard_local_call,{l,0}}}],
           []} = 
        run_test2(Config, Ill1, [warn_unused_record]),

    Ill2 = <<"-module(lint_test).
              -export([t/0]).
              t() ->
                  case x() of
                      _ when l() 
                             or
                             l() ->
                          foo
                  end.
             ">>,
    {errors,[{{4,24},erl_lint,{undefined_function,{x,0}}},
             {{5,30},erl_lint,illegal_guard_expr},
             {{7,30},erl_lint,illegal_guard_expr}],
           []} =
        run_test2(Config, Ill2, [warn_unused_record]),

    Ill3 = <<"t() -> ok.">>,
    {errors,[{{1,1},erl_lint,undefined_module}],[]} =
        run_test2(Config, Ill3, [warn_unused_record]),

    Usage1 = <<"-module(lint_test).
                -export([t/0]).
                -record(u1, {a}).
                -record(u2, {a = #u1{}}).
                -record(u3, {a}). % unused
                -record(u4, {a = #u3{}}). % unused

                t() ->
                    {#u2{}}.
               ">>,
    {warnings,[{{5,18},erl_lint,{unused_record,u3}},
               {{6,18},erl_lint,{unused_record,u4}}]} = 
        run_test2(Config, Usage1, [warn_unused_record]),

    Usage2 = <<"-module(lint_test).
                -export([t/0]).
                -record(u1, {a}).
                -record(u2, {a = #u1{}}).
                -file(\"some_file.hrl\", 1).
                -record(u3, {a}). % unused, but on other file
                -record(u4, {a = #u3{}}). % -\"-

                t() ->
                    {#u2{}}.
               ">>,
    [] = run_test2(Config, Usage2, [warn_unused_record]),

    %% This a completely different story...
    %% The linter checks if qlc.hrl hasn't been included
    QLC2 = <<"-module(lint_test).
              -import(qlc, [q/2]).
              -export([t/0]).

              t() ->
                  H1 = qlc:q([X || X <- [1,2]]),
                  H2 = qlc:q([X || X <- [1,2]], []),
                  H3 = q([X || X <- [1,2]], []),
                  {H1,H2,H3}.
             ">>,
    {warnings,[{{6,24},erl_lint,{missing_qlc_hrl,1}},
               {{7,24},erl_lint,{missing_qlc_hrl,2}},
               {{8,24},erl_lint,{missing_qlc_hrl,2}}]} =
        run_test2(Config, QLC2, [warn_unused_record]),

    %% Records that are used by types are not unused.
    %% (Thanks to Fredrik Thulin and Kostis Sagonas.)
    UsedByType = <<"-module(t).
                    -export([foo/1]).
                    -record(sipurl,  {host :: string()}).
                    -record(keylist, {list = [] :: [_]}).
                    -type sip_headers() :: #keylist{}.
                    -record(request, {uri :: #sipurl{}, header :: sip_headers()}).

                    foo(#request{}) -> ok.
                  ">>,
    [] = run_test2(Config, UsedByType, [warn_unused_record]),

    %% Abstract code generated by OTP 18. Note that the type info for
    %% record fields has been put in a separate form.
    OldAbstract = [{attribute,1,file,{"rec.erl",1}},
                   {attribute,1,module,rec},
                   {attribute,3,export,[{t,0}]},
                   {attribute,7,record,{r,[{record_field,7,{atom,7,f}}]}},
                   {attribute,7,type,
                    {{record,r},
                     [{typed_record_field,
                       {record_field,7,{atom,7,f}},
                       {type,7,union,[{atom,7,undefined},{type,7,atom,[]}]}}],
                     []}},
                   {function,9,t,0,[{clause,9,[],[],[{record,10,r,[]}]}]},
                   {eof,11}],
    {error,[{"rec.erl",[{7,erl_lint,old_abstract_code}]}],[]} =
        compile_forms(OldAbstract, [return, report]),

    ok.

%% OTP-6885. Binary fields in bit syntax matching is now only
%% allowed at the end.
otp_6885(Config) when is_list(Config) ->
    Ts = <<"-module(otp_6885).
            -export([t/1]).
            t(<<_/binary,I>>) -> I;
            t(<<X/binary,I:X>>) -> I;
	    t(<<B/binary,T/binary>>) -> {B,T}.

            build(A, B) ->
               <<A/binary,B/binary>>.

            foo(<<\"abc\"/binary>>) ->
               ok;
            foo(<<\"abc\":13/integer>>) ->
               ok;
            foo(<<\"abc\"/float>>) ->
               ok;
            foo(<<\"abc\":19>>) ->
               ok;
            foo(<<\"abc\"/utf8>>) ->
               ok;
            foo(<<\"abc\"/utf16>>) ->
               ok;
            foo(<<\"abc\"/utf32>>) ->
               ok.

           ">>,
    {errors,[{{3,17},erl_lint,unsized_binary_not_at_end},
             {{4,17},erl_lint,unsized_binary_not_at_end},
             {{5,10},erl_lint,unsized_binary_not_at_end},
             {{10,19},erl_lint,typed_literal_string},
             {{12,19},erl_lint,typed_literal_string},
             {{14,19},erl_lint,typed_literal_string},
             {{16,19},erl_lint,typed_literal_string}],
	   []} = run_test2(Config, Ts, []),
    ok.

%% OTP-6885. Warnings for opaque types.
otp_10436(Config) when is_list(Config) ->
    Ts = <<"-module(otp_10436).
            -export_type([t1/0]).
            -opaque t1() :: {i, integer()}.
            -opaque t2() :: {a, atom()}.
         ">>,
    {warnings,[{{4,14},erl_lint,{not_exported_opaque,{t2,0}}},
               {{4,14},erl_lint,{unused_type,{t2,0}}}]} =
        run_test2(Config, Ts, []),
    ok.

%% OTP-11254. M:F/A could crash the linter.
otp_11254(Config) when is_list(Config) ->
    Ts = <<"-module(p2).
            -export([manifest/2]).
            manifest(Module, Name) ->
              fun Module:Nine/1.
         ">>,
    {error,[{{4,26},erl_lint,{unbound_var,'Nine','Name'}}],
     [{{3,30},erl_lint,{unused_var,'Name'}}]} =
        run_test2(Config, Ts, []),
    ok.

%% OTP-11772. Reintroduce errors for redefined builtin types.
otp_11772(Config) when is_list(Config) ->
    Ts = <<"
            -module(newly).

            -export([t/0]).

            %% Built-in:
            -type node() :: node().
            -type mfa() :: tuple().
            -type gb_tree() :: mfa(). % Allowed since Erlang/OTP 17.0
            -type digraph() :: [_].   % Allowed since Erlang/OTP 17.0

            -type t() :: mfa() | digraph() | gb_tree() | node().

            -spec t() -> t().

            t() ->
                1.
         ">>,
    {warnings,[{{7,14},erl_lint,{redefine_builtin_type,{node,0}}},
               {{8,14},erl_lint,{redefine_builtin_type,{mfa,0}}}]} =
        run_test2(Config, Ts, []),
    ok.

%% OTP-11771. Do not allow redefinition of the types arity(_) &c..
otp_11771(Config) when is_list(Config) ->
    Ts = <<"
            -module(newly).

            -export([t/0]).

            %% No longer allowed in 17.0:
            -type arity() :: atom().
            -type bitstring() :: list().
            -type iodata() :: integer().
            -type boolean() :: iodata().

            -type t() :: arity() | bitstring() | iodata() | boolean().

            -spec t() -> t().

            t() ->
                1.
         ">>,
    {warnings,[{{7,14},erl_lint,{redefine_builtin_type,{arity,0}}},
               {{8,14},erl_lint,{redefine_builtin_type,{bitstring,0}}},
               {{9,14},erl_lint,{redefine_builtin_type,{iodata,0}}},
               {{10,14},erl_lint,{redefine_builtin_type,{boolean,0}}}]} =
        run_test2(Config, Ts, []),
    ok.

%% OTP-11872. The type map() undefined when exported.
otp_11872(Config) when is_list(Config) ->
    Ts = <<"
            -module(map).

            -export([t/0]).

            -export_type([map/0, product/0]).

            -opaque map() :: unknown_type().

            -spec t() -> map().

            t() ->
                1.
         ">>,
    {error,[{{6,14},erl_lint,{undefined_type,{product,0}}},
            {{8,30},erl_lint,{undefined_type,{unknown_type,0}}}],
     [{{8,14},erl_lint,{redefine_builtin_type,{map,0}}}]} =
        run_test2(Config, Ts, []),
    ok.

%% OTP-7392. Warning for export_all.
export_all(Config) when is_list(Config) ->
    Ts = <<"-module(export_all_module).
            -compile([export_all]).

            id(I) -> I.
           ">>,
    [] = run_test2(Config, Ts, [nowarn_export_all]),
    {warnings,[{{2,14},erl_lint,export_all}]} =
	run_test2(Config, Ts, []),
    ok.

%% Test warnings for functions that clash with BIFs.
bif_clash(Config) when is_list(Config) ->
    Ts = [{clash1,
           <<"t(X) ->
                  size(X).

              %% No warning for the following calls, since they
              %% are unambigous.
              b(X) ->
                  erlang:size(X).

              c(X) ->
                  ?MODULE:size(X).

              size({N,_}) ->
                N.
             ">>,
           [nowarn_unexported_function],
	   {warnings,[{{2,19},erl_lint,{call_to_redefined_bif,{size,1}}}]}},

	  %% Verify that warnings cannot be turned off in the old way.
	  {clash2,
           <<"-export([t/1,size/1]).
              t(X) ->
                  size(X).

              size({N,_}) ->
                N.

              %% My own abs/1 function works on lists too. From R14 this really works.
              abs([H|T]) when $a =< H, H =< $z -> [H-($a-$A)|abs(T)];
              abs([H|T]) -> [H|abs(T)];
              abs([]) -> [];
              abs(X) -> erlang:abs(X).
             ">>,
	   {[nowarn_unused_function,nowarn_bif_clash]},
	   {errors,[{erl_lint,disallowed_nowarn_bif_clash}],[]}},
	  %% As long as noone calls an overridden BIF, it's totally OK
	  {clash3,
           <<"-export([size/1]).
              size({N,_}) ->
                N;
              size(X) ->
                erlang:size(X).
             ">>,
	   [],
	   []},
	  %% For a pre R14 bif, it used to be an error, but is now a warning
	  {clash4,
           <<"-export([size/1]).
              size({N,_}) ->
                N;
              size(X) ->
                size(X).
             ">>,
	   [],
	   {warnings,[{{5,17},erl_lint,{call_to_redefined_bif,{size,1}}}]}},
	  %% For a post R14 bif, its only a warning; also check symbolic funs
	  {clash5,
           <<"-export([binary_part/2,f/0]).
              binary_part({B,_},{X,Y}) ->
                binary_part(B,{X,Y});
              binary_part(B,{X,Y}) ->
                binary:part(B,X,Y).
              f() -> fun binary_part/2.
             ">>,
	   [],
	   {warnings,[{{3,17},erl_lint,{call_to_redefined_bif,{binary_part,2}}},
                      {{6,22},erl_lint,{call_to_redefined_bif,{binary_part,2}}}]}},
	  %% If you really mean to call yourself here, you can "unimport" size/1
	  {clash6,
           <<"-export([size/1,f/0]).
              -compile({no_auto_import,[size/1]}).
              size([]) ->
                0;
              size({N,_}) ->
                N;
              size([_|T]) ->
                1+size(T).
              f() -> fun size/1.
             ">>,
	   [],
	   []},
	  %% Same for the post R14 autoimport warning
	  {clash7,
           <<"-export([binary_part/2]).
              -compile({no_auto_import,[binary_part/2]}).
              binary_part({B,_},{X,Y}) ->
                binary_part(B,{X,Y});
              binary_part(B,{X,Y}) ->
                binary:part(B,X,Y).
             ">>,
	   [],
	   []},
          %% but this doesn't mean the local function is allowed in a guard...
	  {clash8,
           <<"-export([x/1]).
              -compile({no_auto_import,[binary_part/2]}).
              x(X) when binary_part(X,{1,2}) =:= <<1,2>> ->
                 hej.
              binary_part({B,_},{X,Y}) ->
                binary_part(B,{X,Y});
              binary_part(B,{X,Y}) ->
                binary:part(B,X,Y).
             ">>,
	   [],
	   {errors,[{{3,25},erl_lint,{illegal_guard_local_call,{binary_part,2}}}],[]}},
          %% no_auto_import is not like nowarn_bif_clash, it actually removes the autoimport
	  {clash9,
           <<"-export([x/1]).
              -compile({no_auto_import,[binary_part/2]}).
              x(X) ->
                 binary_part(X,{1,2}) =:= <<1,2>>.
             ">>,
	   [],
	   {errors,[{{4,18},erl_lint,{undefined_function,{binary_part,2}}}],[]}},
          %% but we could import it again...
	  {clash10,
           <<"-export([x/1]).
              -compile({no_auto_import,[binary_part/2]}).
              -import(erlang,[binary_part/2]).
              x(X) ->
                 binary_part(X,{1,2}) =:= <<1,2>>.
             ">>,
	   [],
	   []},
          %% and actually use it in a guard...
	  {clash11,
           <<"-export([x/1]).
              -compile({no_auto_import,[binary_part/2]}).
              -import(erlang,[binary_part/2]).
              x(X) when binary_part(X,{0,1}) =:= <<0>> ->
                 binary_part(X,{1,2}) =:= <<1,2>>.
             ">>,
	   [],
	   []},
          %% but for non-obvious historical reasons, imported functions cannot be used in
	  %% fun construction without the module name...
	  {clash12,
           <<"-export([x/1]).
              -compile({no_auto_import,[binary_part/2]}).
              -import(erlang,[binary_part/2]).
              x(X) when binary_part(X,{0,1}) =:= <<0>> ->
                 binary_part(X,{1,2}) =:= fun binary_part/2.
             ">>,
	   [],
	   {errors,[{{5,43},erl_lint,{fun_import,{binary_part,2}}}],[]}},
          %% Not from erlang and not from anywhere else
	  {clash13,
           <<"-export([x/1]).
              -compile({no_auto_import,[binary_part/2]}).
              -import(x,[binary_part/2]).
              x(X) ->
                 binary_part(X,{1,2}) =:= fun binary_part/2.
             ">>,
	   [],
	   {errors,[{{5,43},erl_lint,{fun_import,{binary_part,2}}}],[]}},
	  %% ...while real auto-import is OK.
	  {clash14,
           <<"-export([x/1]).
              x(X) when binary_part(X,{0,1}) =:= <<0>> ->
                 binary_part(X,{1,2}) =:= fun binary_part/2.
             ">>,
	   [],
	   []},
          %% Import directive clashing with old bif used to be an error, now a warning
	  {clash15,
           <<"-export([x/1]).
              -import(x,[abs/1]).
              x(X) ->
                 binary_part(X,{1,2}).
             ">>,
	   [],
	   {warnings,[{{2,16},erl_lint,{redefine_bif_import,{abs,1}}}]}},
	  %% For a new BIF, it's only a warning
	  {clash16,
           <<"-export([x/1]).
              -import(x,[binary_part/3]).
              x(X) ->
                 abs(X).
             ">>,
	   [],
	   {warnings,[{{2,16},erl_lint,{redefine_bif_import,{binary_part,3}}}]}},
	  %% And, you cannot redefine already imported things that aren't auto-imported
	  {clash17,
           <<"-export([x/1]).
              -import(x,[binary_port/3]).
              -import(y,[binary_port/3]).
              x(X) ->
                 abs(X).
             ">>,
	   [],
	   {errors,[{{3,16},erl_lint,{redefine_import,{{binary_port,3},x}}}],[]}},
	  %% Not with local functions either
	  {clash18,
           <<"-export([x/1]).
              -import(x,[binary_port/3]).
              binary_port(A,B,C) ->
                 binary_part(A,B,C).
              x(X) ->
                 abs(X).
             ">>,
	   [],
	   {errors,[{{3,15},erl_lint,{define_import,{binary_port,3}}}],[]}},
	  %% Like clash8: Dont accept a guard if it's explicitly module-name called either
	  {clash19,
           <<"-export([binary_port/3]).
              -compile({no_auto_import,[binary_part/3]}).
              -import(x,[binary_part/3]).
              binary_port(A,B,C) when x:binary_part(A,B,C) ->
                 binary_part(A,B,C+1).
             ">>,
	   [],
	   {errors,[{{4,39},erl_lint,illegal_guard_expr}],[]}},
	  %% Not with local functions either
	  {clash20,
           <<"-export([binary_port/3]).
              -import(x,[binary_part/3]).
              binary_port(A,B,C) ->
                 binary_part(A,B,C).
             ">>,
	   [warn_unused_import],
	   {warnings,[{{2,16},erl_lint,{redefine_bif_import,{binary_part,3}}}]}},
	  %% Don't accept call to a guard BIF if there is a local definition
	  %% or an import with the same name. Note: is_record/2 is an
	  %% exception, since it is more of syntatic sugar than a real BIF.
	  {clash21,
           <<"-export([is_list/1]).
              -import(x, [is_tuple/1]).
              -record(r, {a,b}).
              x(T) when is_tuple(T) -> ok;
              x(T) when is_list(T) -> ok.
              y(T) when is_tuple(T) =:= true -> ok;
              y(T) when is_list(T) =:= true -> ok;
              y(T) when is_record(T, r, 3) -> ok;
              y(T) when is_record(T, r, 3) =:= true -> ok;
              y(T) when is_record(T, r) =:= true -> ok.
              is_list(_) ->
                ok.
              is_record(_, _) ->
                ok.
              is_record(_, _, _) ->
                ok.
             ">>,
	   [{no_auto_import,[{is_tuple,1}]}],
	   {errors,[{{4,25},erl_lint,{illegal_guard_local_call,{is_tuple,1}}},
		    {{5,25},erl_lint,{illegal_guard_local_call,{is_list,1}}},
		    {{6,25},erl_lint,{illegal_guard_local_call,{is_tuple,1}}},
		    {{7,25},erl_lint,{illegal_guard_local_call,{is_list,1}}},
		    {{8,25},erl_lint,{illegal_guard_local_call,{is_record,3}}},
		    {{9,25},erl_lint,{illegal_guard_local_call,{is_record,3}}}],[]}},
	  %% We can also suppress all auto imports at once
	  {clash22,
          <<"-export([size/1, binary_part/2]).
             -compile(no_auto_import).
             size([]) ->
               0;
             size({N,_}) ->
               N;
             size([_|T]) ->
               1+size(T).
             binary_part({B,_},{X,Y}) ->
               binary_part(B,{X,Y});
             binary_part(B,{X,Y}) ->
               binary:part(B,X,Y).
            ">>,
	   [],
	   []}
	 ],

    [] = run(Config, Ts),
    ok.

%% Basic tests with one behaviour.
behaviour_basic(Config) when is_list(Config) ->
    Ts = [{behaviour1,
           <<"-behaviour(application).
             ">>,
           [],
	   {warnings,[{{1,22},erl_lint,{undefined_behaviour_func,{start,2},application}},
		      {{1,22},erl_lint,{undefined_behaviour_func,{stop,1},application}}]}},

	  {behaviour2,
           <<"-behaviour(application).
              -export([stop/1]).
              stop(_) -> ok.
             ">>,
           [],
	   {warnings,[{{1,22},erl_lint,{undefined_behaviour_func,{start,2},application}}]}},
	  
	  {behaviour3,
           <<"-behavior(application).  %% Test American spelling.
              -export([start/2,stop/1]).
              start(_, _) -> ok.
              stop(_) -> ok.
             ">>,
           [],
           []},

          {behaviour4,
           <<"-behavior(application).  %% Test callbacks with export_all
              -compile([export_all, nowarn_export_all]).
              stop(_) -> ok.
             ">>,
           [],
           {warnings,[{{1,22},erl_lint,{undefined_behaviour_func,{start,2},application}}]}}
	 ],
    [] = run(Config, Ts),

    Subst0 = #{behaviour1 => [nowarn_undefined_behaviour_func],
               behaviour2 => [nowarn_undefined_behaviour_func],
               behaviour4 => [nowarn_undefined_behaviour_func]},
    [] = run(Config, rewrite(Ts, Subst0)),

    Subst = #{K => [nowarn_behaviours] || K := _ <- Subst0},
    [] = run(Config, rewrite(Ts, Subst)),

    ok.

%% Basic tests with multiple behaviours.
behaviour_multiple(Config) when is_list(Config) ->
    Ts = [{behaviour1,
           <<"-behaviour(application).
              -behaviour(supervisor).
             ">>,
           [],
	   {warnings,[{{1,22},erl_lint,{undefined_behaviour_func,{start,2},application}},
		      {{1,22},erl_lint,{undefined_behaviour_func,{stop,1},application}},
		      {{2,16},erl_lint,{undefined_behaviour_func,{init,1},supervisor}}]}},

	  {behaviour2,
           <<"-behaviour(application).
              -behaviour(supervisor).
              -export([start/2,stop/1,init/1]).
              start(_, _) -> ok.
              stop(_) -> ok.
              init(_) -> ok.
             ">>,
           [],
	   []},

	  {american_behavior2,
           <<"-behavior(application).
              -behavior(supervisor).
              -export([start/2,stop/1,init/1]).
              start(_, _) -> ok.
              stop(_) -> ok.
              init(_) -> ok.
             ">>,
           [],
	   []},

	  {behaviour3,
           <<"-behaviour(gen_server).
              -behaviour(supervisor).
              -export([handle_call/3,handle_cast/2,handle_info/2]).
              handle_call(_, _, _) -> ok.
              handle_cast(_, _) -> ok.
              handle_info(_, _) -> ok.
             ">>,
           [],
	   {warnings,[{{1,22},erl_lint,{undefined_behaviour_func,{init,1},gen_server}},
		      {{2,16},erl_lint,{undefined_behaviour_func,{init,1},supervisor}},
		      {{2,16},
		       erl_lint,
		       {conflicting_behaviours,{init,1},supervisor,{1,22},gen_server}}]}},
	  {american_behavior3,
           <<"-behavior(gen_server).
              -behavior(supervisor).
              -export([handle_call/3,handle_cast/2,handle_info/2]).
              handle_call(_, _, _) -> ok.
              handle_cast(_, _) -> ok.
              handle_info(_, _) -> ok.
             ">>,
           [],
	   {warnings,[{{1,22},erl_lint,{undefined_behaviour_func,{init,1},gen_server}},
		      {{2,16},erl_lint,{undefined_behaviour_func,{init,1},supervisor}},
		      {{2,16},
		       erl_lint,
		       {conflicting_behaviours,{init,1},supervisor,{1,22},gen_server}}]}},

	  {behaviour4,
           <<"-behaviour(gen_server).
              -behaviour(gen_statem).
              -behaviour(supervisor).
              -export([init/1,handle_call/3,handle_cast/2,
                       handle_info/2,handle_info/3,
                       handle_event/3,handle_sync_event/4,
                       code_change/3,code_change/4,
                       terminate/2,terminate/3,terminate/4,
                       callback_mode/0]).
              init(_) -> ok.
              handle_call(_, _, _) -> ok.
              handle_event(_, _, _) -> ok.
              handle_sync_event(_, _, _, _) -> ok.
              handle_cast(_, _) -> ok.
              handle_info(_, _) -> ok.
              handle_info(_, _, _) -> ok.
              code_change(_, _, _) -> ok.
              code_change(_, _, _, _) -> ok.
              terminate(_, _) -> ok.
              terminate(_, _, _) -> ok.
              terminate(_, _, _, _) -> ok.
              callback_mode() -> state_functions.
             ">>,
           [],
	   {warnings,[{{2,16},
		       erl_lint,
		       {conflicting_behaviours,{init,1},gen_statem,{1,22},gen_server}},
		      {{3,16},
		       erl_lint,
		       {conflicting_behaviours,{init,1},supervisor,{1,22},gen_server}}]}}
	 ],
    [] = run(Config, Ts),

    Subst = #{behaviour3 => [nowarn_undefined_behaviour_func,
                             nowarn_conflicting_behaviours],
              american_behavior3 => [nowarn_undefined_behaviour_func,
                                     nowarn_conflicting_behaviours],
              behaviour4 => [nowarn_conflicting_behaviours]},
    [] = run(Config, rewrite(Ts, Subst)),

    ok.

%% OTP-11861. behaviour_info() and -callback.
otp_11861(Conf) when is_list(Conf) ->
    CallbackFiles = [callback1, callback2, callback3,
                     bad_behaviour1, bad_behaviour2,
                     bad_behaviour3],
    lists:foreach(fun(M) ->
                          F = filename:join(?datadir, M),
                          Opts = [{outdir,?privdir}, return],
                          {ok, M, []} = compile:file(F, Opts)
                  end, CallbackFiles),
    CodePath = code:get_path(),
    true = code:add_path(?privdir),
    Ts = [{otp_11861_1,
           <<"
              -export([b1/1]).
              -behaviour(callback1).
              -behaviour(callback2).

              -spec b1(atom()) -> integer().
              b1(A) when is_atom(A)->
                  3.
             ">>,
           [],
           %% b2/1 is optional in both modules
           {warnings,[{{4,16},erl_lint,
                       {conflicting_behaviours,{b1,1},callback2,{3,16},callback1}}]}},
          {otp_11861_2,
           <<"
              -export([b2/1]).
              -behaviour(callback1).
              -behaviour(callback2).

              -spec b2(integer()) -> atom().
              b2(I) when is_integer(I)->
                  a.
             ">>,
           [],
           %% b2/1 is optional in callback2, but not in callback1
           {warnings,[{{3,16},erl_lint,{undefined_behaviour_func,{b1,1},callback1}},
                      {{4,16},erl_lint,
                       {conflicting_behaviours,{b2,1},callback2,{3,16},callback1}}]}},
          {otp_11861_3,
           <<"
              -callback b(_) -> atom().
              -optional_callbacks({b1,1}). % non-existing and ignored
             ">>,
           [],
           []},
          {otp_11861_4,
           <<"
              -callback b(_) -> atom().
              -optional_callbacks([{b1,1}]). % non-existing
             ">>,
           [],
           %% No behaviour-info(), but callback.
           {errors,[{{3,16},erl_lint,{undefined_callback,{lint_test,b1,1}}}],[]}},
          {otp_11861_5,
           <<"
              -optional_callbacks([{b1,1}]). % non-existing
             ">>,
           [],
           %% No behaviour-info() and no callback: warning anyway
           {errors,[{{2,16},erl_lint,{undefined_callback,{lint_test,b1,1}}}],[]}},
          {otp_11861_6,
           <<"
              -optional_callbacks([b1/1]). % non-existing
              behaviour_info(callbacks) -> [{b1,1}].
             ">>,
           [],
           %% behaviour-info() and no callback: warning anyway
           {errors,[{{2,16},erl_lint,{undefined_callback,{lint_test,b1,1}}}],[]}},
          {otp_11861_7,
           <<"
              -optional_callbacks([b1/1]). % non-existing
              -callback b(_) -> atom().
              behaviour_info(callbacks) -> [{b1,1}].
             ">>,
           [],
           %% behaviour-info() callback: warning
           {errors,[{{2,16},erl_lint,{undefined_callback,{lint_test,b1,1}}},
                    {{3,16},erl_lint,{behaviour_info,{lint_test,b,1}}}],
            []}},
          {otp_11861_8,
           <<"
              -callback b(_) -> atom().
              -optional_callbacks([b/1, {b, 1}]).
             ">>,
           [],
           {errors,[{{3,16},erl_lint,{redefine_optional_callback,{b,1}}}],[]}},
          {otp_11861_9,
           <<"
              -behaviour(gen_server).
              -export([handle_call/3,handle_cast/2,handle_info/2,
                       code_change/3, init/1, terminate/2]).
              handle_call(_, _, _) -> ok.
              handle_cast(_, _) -> ok.
              handle_info(_, _) -> ok.
              code_change(_, _, _) -> ok.
              init(_) -> ok.
              terminate(_, _) -> ok.
             ">>,
           [],
           %% Nothing...
           []},
          {otp_11861_9,
           <<"
              -behaviour(gen_server).
              -export([handle_call/3,handle_cast/2,handle_info/2,
                       code_change/3, init/1, terminate/2,
                       format_status/1, format_status/2]).
              handle_call(_, _, _) -> ok.
              handle_cast(_, _) -> ok.
              handle_info(_, _) -> ok.
              code_change(_, _, _) -> ok.
              init(_) -> ok.
              terminate(_, _) -> ok.
              format_status(_) -> ok. % optional callback
              format_status(_, _) -> ok. % deprecated optional callback
             ">>,
           [],
           {warnings,[{{2,16},
                       erl_lint,
                       {deprecated_callback,{gen_server,format_status,2},
                        "use format_status/1 instead"}}]}},
          {otp_11861_10,
           <<"
              -optional_callbacks([{b1,1,bad}]). % badly formed and ignored
              behaviour_info(callbacks) -> [{b1,1}].
             ">>,
           [],
           []},
          {otp_11861_11,
           <<"
              -behaviour(bad_behaviour1).
             ">>,
           [],
           {warnings,[{{2,16},erl_lint,
                       {ill_defined_behaviour_callbacks,bad_behaviour1}}]}},
          {otp_11861_12,
           <<"
              -behaviour(non_existing_behaviour).
             ">>,
           [],
           {warnings,[{{2,16},erl_lint,
                       {undefined_behaviour,non_existing_behaviour}}]}},
          {otp_11861_13,
           <<"
              -behaviour(bad_behaviour_none).
             ">>,
           [],
           {warnings,[{{2,16},erl_lint,{undefined_behaviour,bad_behaviour_none}}]}},
          {otp_11861_14,
           <<"
              -callback b(_) -> atom().
             ">>,
           [],
           []},
          {otp_11861_15,
           <<"
              -optional_callbacks([{b1,1,bad}]). % badly formed
              -callback b(_) -> atom().
             ">>,
           [],
           []},
          {otp_11861_16,
           <<"
              -callback b(_) -> atom().
              -callback b(_) -> atom().
             ">>,
           [],
           {errors,[{{3,16},erl_lint,{redefine_callback,{b,1}}}],[]}},
          {otp_11861_17,
           <<"
              -behaviour(bad_behaviour2).
             ">>,
           [],
           {warnings,[{{2,16},erl_lint,{undefined_behaviour_callbacks,
                                   bad_behaviour2}}]}},
          {otp_11861_18,
           <<"
              -export([f1/1]).
              -behaviour(callback3).
              f1(_) -> ok.
             ">>,
           [],
           []},

          {otp_11861_19,
           <<"
              -export([good/1]).
              -behaviour(bad_behaviour3).
              good(_) -> ok.
             ">>,
           [],
           {warnings,[{{3,16},erl_lint,{ill_defined_optional_callbacks,bad_behaviour3}}]}}
	 ],
    [] = run(Conf, Ts),

    Subst0 = #{otp_11861_1 => [nowarn_conflicting_behaviours],
               otp_11861_11 => [nowarn_ill_defined_behaviour_callbacks],
               otp_11861_12 => [nowarn_undefined_behaviour],
               otp_11861_13 => [nowarn_undefined_behaviour],
               otp_11861_17 => [nowarn_undefined_behaviour_callbacks],
               otp_11861_19 => [nowarn_ill_defined_optional_callbacks]
              },
    [] = run(Conf, rewrite(Ts, Subst0)),

    Subst = #{K => [nowarn_behaviours] || K := _ <- Subst0},
    [] = run(Conf, rewrite(Ts, Subst)),

    true = code:set_path(CodePath),
    ok.

%% Test that the new utf8/utf16/utf32 types do not allow size or
%% unit specifiers.
otp_7550(Config) when is_list(Config) ->
    Ts = [{otp_7550,
           <<"f8(A) ->
                  <<A:8/utf8>>.
              g8(A) ->
                  <<A:8/utf8-unit:1>>.
              h8(A) ->
                  <<A/utf8-unit:1>>.

              f16(A) ->
                  <<A:8/utf16>>.
              g16(A) ->
                  <<A:8/utf16-unit:1>>.
              h16(A) ->
                  <<A/utf16-unit:1>>.

              f32(A) ->
                  <<A:8/utf32>>.
              g32(A) ->
                  <<A:8/utf32-unit:1>>.
              h32(A) ->
                  <<A/utf32-unit:1>>.
             ">>,
           [],
           {errors,[{{2,21},erl_lint,utf_bittype_size_or_unit},
		    {{4,21},erl_lint,utf_bittype_size_or_unit},
		    {{6,21},erl_lint,utf_bittype_size_or_unit},
		    {{9,21},erl_lint,utf_bittype_size_or_unit},
		    {{11,21},erl_lint,utf_bittype_size_or_unit},
		    {{13,21},erl_lint,utf_bittype_size_or_unit},
		    {{16,21},erl_lint,utf_bittype_size_or_unit},
		    {{18,21},erl_lint,utf_bittype_size_or_unit},
		    {{20,21},erl_lint,utf_bittype_size_or_unit}
		   ],
            []}}],
    [] = run(Config, Ts),
    ok.
    

%% Bugfix: -opaque with invalid type.
otp_8051(Config) when is_list(Config) ->
    Ts = [{otp_8051,
           <<"-opaque foo() :: bar().
              -export_type([foo/0]).
             ">>,
           [],
           {errors,[{{1,38},erl_lint,{undefined_type,{bar,0}}}],[]}}],
    [] = run(Config, Ts),
    ok.

%% Check that format warnings are generated.
format_warn(Config) when is_list(Config) ->
    L1 = 23,
    L2 = 5,
    format_level(1, L1, Config),
    format_level(2, L1+L2, Config),
    format_level(3, L1+L2, Config),             %there is no level 3
    ok.

format_level(Level, Count, Config) ->
    W = get_compilation_result(Config, "format",
                                     [{warn_format, Level}]),
    %% Pick out the 'format' warnings.
    FW = lists:filter(fun({_Line, erl_lint, {format_error, _}}) -> true;
                               (_) -> false
                            end,
                            W),
    case length(FW) of
              Count ->
                  ok;
              Other ->
                  io:format("Expected ~w warning(s); got ~w", [Count,Other]),
                  fail()
          end,
    ok.

%% Test the -on_load(Name/0) directive.


on_load_successful(Config) when is_list(Config) ->
    Ts = [{on_load_1,
	   %% Exported on_load function.
	   <<"-export([do_on_load/0]).
             -on_load(do_on_load/0).
             do_on_load() -> ok.
             ">>,
	   {[]},				%Tuple indicates no 'export_all'.
	   []},

	  {on_load_2,
	   %% Local on_load function.
	   <<"-on_load(do_on_load/0).
             do_on_load() -> ok.
             ">>,
	   {[]},				%Tuple indicates no 'export_all'.
	   []},

	  {on_load_3,
	   %% Local on_load function, calling other local functions.
	   <<"-on_load(do_on_load/0).
             do_on_load() -> foo().
             foo() -> bar(5) + 42.
             bar(N) -> 2*N.
             ">>,
	   {[]},				%Tuple indicates no 'export_all'.
	   []}
	 ],
    [] = run(Config, Ts),
    ok.

on_load_failing(Config) when is_list(Config) ->
    Ts = [{on_load_1,
	   %% Badly formed.
	   <<"-on_load(atom).
             ">>,
	   {[]},				%Tuple indicates no 'export_all'.
	   {errors,
	    [{{1,22},erl_lint,{bad_on_load,atom}}],[]}},

	  {on_load_2,
	   %% Badly formed.
	   <<"-on_load({42,0}).
             ">>,
	   {[]},				%Tuple indicates no 'export_all'.
	   {errors,
	    [{{1,22},erl_lint,{bad_on_load,{42,0}}}],[]}},

	  {on_load_3,
	   %% Multiple on_load attributes.
	   <<"-on_load(foo/0).
              -on_load(bar/0).
              foo() -> ok.
              bar() -> ok.
             ">>,
	   {[]},				%Tuple indicates no 'export_all'.
	   {errors,
	    [{{2,16},erl_lint,multiple_on_loads}],[]}},

	  {on_load_4,
	   %% Wrong arity.
	   <<"-on_load(foo/1).
              foo(_) -> ok.
             ">>,
	   {[]},				%Tuple indicates no 'export_all'.
	   {errors,
	    [{{1,22},erl_lint,{bad_on_load_arity,{foo,1}}}],[]}},

	  {on_load_5,
	   %% Non-existing function.
	   <<"-on_load(non_existing/0).
             ">>,
	   {[]},				%Tuple indicates no 'export_all'.
	   {errors,
	    [{{1,22},erl_lint,{undefined_on_load,{non_existing,0}}}],[]}}
	 ],
    [] = run(Config, Ts),
    ok.

%% Test that too many arguments is not accepted.
too_many_arguments(Config) when is_list(Config) ->
    Ts = [{too_many_1,
	   <<"f(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_) -> ok.">>,
	   [],
	   {errors,
	    [{{1,21},erl_lint,{too_many_arguments,256}}],[]}}
	 ],
	  
    [] = run(Config, Ts),
    ok.


%% Test some basic errors to improve coverage.
basic_errors(Config) ->
    Ts = [{redefine_module,
	   <<"-module(redefine_module).">>,
	   [],
	   {errors,[{{1,22},erl_lint,redefine_module}],[]}},

	  {attr_after_function,
	   <<"f() -> ok.
               -attr(x).">>,
	   [],
	   {errors,[{{2,17},erl_lint,{attribute,attr}}],[]}},

	  {redefine_function,
	   <<"f() -> ok.
              f() -> ok.">>,
	   [],
	   {errors,[{{2,15},erl_lint,{redefine_function,{f,0}}}],[]}},

	  {redefine_record,
	   <<"-record(r, {a}).
              -record(r, {a}).
	      f(#r{}) -> ok.">>,
	   [],
	   {errors,[{{2,16},erl_lint,{redefine_record,r}}],[]}},

	  {illegal_record_info,
	   <<"f1() -> record_info(42, record).
	      f2() -> record_info(shoe_size, record).
              f3() -> fun record_info/2.">>,
	   [],
	   {errors,[{{1,29},erl_lint,illegal_record_info},
		    {{2,28},erl_lint,illegal_record_info},
                    {{3,23},erl_lint,illegal_record_info}],[]}},

	  {illegal_expr,
	   <<"f() -> a:b.">>,
	   [],
	   {errors,[{{1,28},erl_lint,illegal_expr}],[]}},

	  {illegal_pattern,
	   <<"f(A+B) -> ok.">>,
	   [],
	   {errors,[{{1,24},erl_lint,illegal_pattern}],[]}}
	 ],
    [] = run(Config, Ts),
    ok.

%% Test binary syntax errors
bin_syntax_errors(Config) ->
    Ts = [{bin_syntax_errors,
	   <<"t(<<X:bad_size>>) -> X;
	      t(<<_:(x ! y)/integer>>) -> ok;
	      t(<<_:(l())/integer>>) -> ok;
              t(<<X:all/integer>>) -> X;
              t(<<X/bad_type>>) -> X;
	      t(<<X/unit:8>>) -> X;
	      t(<<X:7/float>>) -> X;
	      t(<< <<_:8>> >>) -> ok;
	      t(<<(x ! y):8/integer>>) -> ok;
              t(X) ->
                {<<X/binary-integer>>,<<X/signed-unsigned-integer>>,
                 <<X/little-big>>,<<X/unit:4-unit:8>>};
              t(<<_:{A,B}>>) -> ok.

              l() ->
                  foo.
	    ">>,
	   [],
	   {error,[{{2,17},erl_lint,illegal_bitsize},
		   {{3,15},erl_lint,{illegal_bitsize_local_call,{l,0}}},
		   {{5,19},erl_lint,{undefined_bittype,bad_type}},
		   {{6,12},erl_lint,bittype_unit},
		   {{8,13},erl_lint,illegal_pattern},
		   {{9,15},erl_lint,illegal_pattern},
		   {{11,20},erl_lint,{bittype_mismatch,integer,binary,"type"}},
		   {{11,41},erl_lint,{bittype_mismatch,unsigned,signed,"sign"}},
		   {{12,20},erl_lint,{bittype_mismatch,big,little,"endianness"}},
		   {{12,37},erl_lint,{bittype_mismatch,8,4,"unit"}},
                   {{13,22},erl_lint,{unbound_var,'A'}},
                   {{13,24},erl_lint,{unbound_var,'B'}}
		  ],
	    [{{1,27},erl_lint,non_integer_bitsize},
             {{4,21},erl_lint,non_integer_bitsize},
             {{7,12},erl_lint,{bad_bitsize,"float"}},
             {{13,21},erl_lint,non_integer_bitsize}]}}
	 ],
    [] = run(Config, Ts),
    ok.

%% OTP-10342: No longer predefined types: array(), digraph(), and so on.
predef(Config) when is_list(Config) ->
    W = get_compilation_result(Config, "predef", []),
    [] = W,
    %% dict(), digraph() and so on were removed in Erlang/OTP 18.0.
    E2 = get_compilation_result(Config, "predef2", []),
    Tag = undefined_type,
    {[{{5,2},erl_lint,{Tag,{array,0}}},
      {{5,2},erl_lint,{Tag,{digraph,0}}},
      {{5,2},erl_lint,{Tag,{gb_set,0}}},
      {{7,13},erl_lint,{Tag,{array,0}}},
      {{12,12},erl_lint,{Tag,{dict,0}}},
      {{17,15},erl_lint,{Tag,{digraph,0}}},
      {{27,14},erl_lint,{Tag,{gb_set,0}}},
      {{32,15},erl_lint,{Tag,{gb_tree,0}}},
      {{37,13},erl_lint,{Tag,{queue,0}}},
      {{42,11},erl_lint,{Tag,{set,0}}},
      {{47,16},erl_lint,{Tag,{tid,0}}}],[]} = E2,
    ok.

maps(Config) ->
    Ts = [{illegal_map_construction,
           <<"t() ->
                  #{ a := b,
                     c => d,
                     e := f
                  }#{ a := b,
                      c => d,
                      e := f };
              t() when is_map(#{ a := b,
                                 c => d
                              }#{ a := b,
                                  c => d,
                                  e := f }) ->
                  ok.
            ">>,
           [],
           {error,
            [{{2,24},erl_lint,illegal_map_construction},
             {{4,24},erl_lint,illegal_map_construction},
             {{8,36},erl_lint,illegal_map_construction}],
            [{{5,20},erl_lint,update_literal}]}},
          {illegal_map_assoc_in_pattern,
           <<"t(#{ a := A,
                   c => d,
                   e := F,
                   g := 1 + 1,
                   h := _,
                   i := (_X = _Y),
                   j := (x ! y),
		   <<0:300>> := 33}) ->
                  {A,F}.
            ">>,
           [],
           {errors,[{{2,22},erl_lint,illegal_map_assoc_in_pattern},
                    {{7,28},erl_lint,illegal_pattern}],
            []}},
          {error_in_illegal_map_construction,
           <<"t() -> #{ a := X }.">>,
           [],
	   {errors,[{{1,33},erl_lint,illegal_map_construction},
                    {{1,36},erl_lint,{unbound_var,'X'}}],
            []}},
          {legal_map_pattern,
	   <<"
               -record(mapkey, {a=1,b=2}).
               t(M,K1) ->
                     #{ a := 1,
                        $a := 1, $z := 99,
                        #{a=>val} := 2,
                        K1 := 1337,
                        #mapkey{a = 10} := wat,
                        #{{a,val}=>val} := 2,
                        #{ \"hi\" => wazzup, hi => ho } := yep,
                        ok := 1.0,
                        [3+3] := nope,
                        1.0 := yep,
                        {3.0+3} := nope,
                        {yep} := yep
                      } = M.
	   ">>,
	   [],
	   []},
	  {legal_map_construction,
	   <<"t(V) -> #{ a => 1,
			#{a=>V} => 2,
			#{{a,V}=>V} => 2,
			#{ \"hi\" => wazzup, hi => ho } => yep,
			[try a catch _:_ -> b end] => nope,
			ok => 1.0,
			[3+3] => nope,
			1.0 => yep,
			{3.0+3} => nope,
			{yep} => yep,
			[case a of a -> a end] => nope
		      }.
	   ">>,
	   [],
	   []},
	   {errors_in_map_keys_pattern,
	   <<"t(#{ a := 2,
	           #{} := A,
	           #{ 3 => 33 } := hi,
	           #{ 3 := 33 } := hi,
	           #{ hi => 54, \"hello\" => 45 } := hi,
		   #{ V => 33 } := hi }) ->
	       A.
	   ">>,
	   [],
	   {errors,[{{4,18},erl_lint,illegal_map_construction},
                    {{6,9},erl_lint,{unbound_var,'V'}}],[]}},
          {unused_vars_with_empty_maps,
           <<"t(Foo, Bar, Baz) -> {#{},#{}}.">>,
           [warn_unused_variables],
           {warnings,[{{1,23},erl_lint,{unused_var,'Foo'}},
                      {{1,28},erl_lint,{unused_var,'Bar'}},
                      {{1,33},erl_lint,{unused_var,'Baz'}}]}}],
    [] = run(Config, Ts),
    ok.

maps_type(Config) when is_list(Config) ->
    Ts = [
	{maps_type1,
	 <<"
	-type m() :: #{a => integer()}.
	-spec t1(#{k=>term()}) -> {term(), map()}.

	t1(#{k:=V}=M) -> {V,M}.

	-spec t2(m()) -> integer().

	t2(#{a:=V}) -> V.
	">>,
	[],
	[]},
	{maps_type2,
	 <<"
            %% Built-in var arity map type:
	    -type map() :: tuple().
	    -type a() :: map().

	    -spec t(a()) -> a().
	    t(M) -> M.
	 ">>,
	 [],
         {warnings,[{{3,7},erl_lint,{redefine_builtin_type,{map,0}}}]}}],
    [] = run(Config, Ts),
    ok.

%% GH-6348/OTP-18297: In OTP 26 parallel matching of maps
%% has been extended.
maps_parallel_match(Config) when is_list(Config) ->
    Ts = [{parallel_map_patterns_unbound,
           <<"
           t(#{} = M) ->
               #{k := K} = #{K := V} = M,
               V.
           ">>,
           [],
           {errors,[{{3,30},erl_lint,{unbound_var,'K'}}],[]}},
          {parallel_map_patterns_not_toplevel1,
           <<"
           t(#{} = M) ->
               [#{K1 := V1} =
                #{K2 := V2} =
                #{k1 := K1,k2 := K2}] = [M],
               [V1,V2].
           ">>,
           [],
           {errors,[{{3,19},erl_lint,{unbound_var,'K1'}},
                    {{4,19},erl_lint,{unbound_var,'K2'}}],[]}},
          {parallel_map_patterns_unbound_not_toplevel2,
           <<"
           t(#{} = M) ->
               [#{k := K} = #{K := V}] = [M],
               V.
           ">>,
           [],
           {errors,[{{3,31},erl_lint,{unbound_var,'K'}}],[]}},
          {parallel_map_patterns_bound1,
           <<"
           t(#{} = M,K1,K2) ->
               #{K1 := V1} =
               #{K2 := V2} =
               #{k1 := K1,k2 := K2} = M,
               [V1,V2].
           ">>,
           [],
           []},
          {parallel_map_patterns_bound2,
           <<"
           t(#{} = M) ->
               #{K := V} = #{k := K} = M,
               V.
           ">>,
           [],
           []},
          {parallel_map_patterns_bound3,
           <<"
           t(#{} = M) ->
               #{K1 := V1} =
               #{K2 := V2} =
               #{k1 := K1,k2 := K2} = M,
               [V1,V2].
           ">>,
           [],
           []},
          {parallel_map_patterns_literal,
           <<"
           t(#{} = M) ->
               #{k1 := V1} =
               #{k2 := V2} =
               #{k1 := V1,k2 := V2} = M,
               [V1,V2].
           ">>,
           [],
           []}],
    [] = run(Config, Ts),
    ok.

%% OTP-11851: More atoms can be used as type names + bug fixes.
otp_11851(Config) when is_list(Config) ->
    Ts = [
	{otp_11851_1,
	 <<"-export([t/0]).
            -type range(A, B) :: A | B.

            -type union(A) :: A.

            -type product() :: integer().

            -type tuple(A) :: A.

            -type map(A) :: A.

            -type record() :: a | b.

            -type integer(A) :: A.

            -type atom(A) :: A.

            -type binary(A, B) :: A | B.

            -type 'fun'() :: integer().

            -type 'fun'(X) :: X.

            -type 'fun'(X, Y) :: X | Y.

            -type all() :: range(atom(), integer()) | union(pid()) | product()
                         | tuple(reference()) | map(function()) | record()
                         | integer(atom()) | atom(integer())
                         | binary(pid(), tuple()) | 'fun'(port())
                         | 'fun'() | 'fun'(<<>>, 'none').

            -spec t() -> all().

            t() ->
                a.
	">>,
	[],
	[]},
	{otp_11851_2,
	 <<"-export([a/1, b/1, t/0]).

            -callback b(_) -> integer().

            -callback ?MODULE:a(_) -> integer().

            a(_) -> 3.

            b(_) -> a.

            t()-> a.
	">>,
	[],
	{errors,[{{5,14},erl_lint,{bad_callback,{lint_test,a,1}}}],[]}},
	{otp_11851_3,
	 <<"-export([a/1]).

            -spec a(_A) -> boolean() when
                  _ :: atom(),
                  _A :: integer().

            a(_) -> true.
	">>,
	[],
	{errors,[{{4,19},erl_parse,"bad type variable"}],[]}},
	{otp_11851_4,
	 <<"
            -spec a(_) -> ok.
            -spec a(_) -> ok.

            -spec ?MODULE:a(_) -> ok.
            -spec ?MODULE:a(_) -> ok.
	">>,
	[],
         {errors,[{{3,14},erl_lint,{redefine_spec,{a,1}}},
                  {{5,14},erl_lint,{redefine_spec,{lint_test,a,1}}},
                  {{6,14},erl_lint,{redefine_spec,{lint_test,a,1}}},
                  {{6,14},erl_lint,{spec_fun_undefined,{a,1}}}],
          []}}
          ],
    [] = run(Config, Ts),
    ok.

%% OTP-11879: The -spec f/a :: (As) -> B; syntax removed,
%% and is_subtype/2 deprecated.
otp_11879(_Config) ->
    Fs = [{attribute,0,file,{"file.erl",0}},
          {attribute,0,module,m},
          {attribute,1,spec,
           {{f,1},
            [{type,2,'fun',[{type,3,product,[{var,4,'V1'},
                                             {var,5,'V1'}]},
                            {type,6,integer,[]}]}]}},
          {attribute,20,callback,
           {{cb,21},
            [{type,22,'fun',[{type,23,product,[{var,24,'V1'},
                                               {var,25,'V1'}]},
                             {type,6,integer,[]}]}]}}],
    {error,[{"file.erl",
             [{1,erl_lint,{spec_fun_undefined,{f,1}}},
              {2,erl_lint,spec_wrong_arity},
              {22,erl_lint,callback_wrong_arity}]}],
     []} = compile_forms(Fs, [return,report]),
    ok.

compile_forms(Terms, Opts) ->
    Forms = [erl_parse:anno_from_term(Term) || Term <- Terms],
    compile:forms(Forms, Opts).

%% OTP-13230: -deprecated without -module.
otp_13230(Config) when is_list(Config) ->
    Abstr = <<"-deprecated([{frutt,0,next_version}]).">>,
    {errors,[{{1,2},erl_lint,undefined_module},
             {{1,2},erl_lint,{bad_deprecated,{frutt,0}}}],
     []} = run_test2(Config, Abstr, []),
    ok.

record_errors(Config) when is_list(Config) ->
    Ts = [{rec1,
           <<"-record(r, {a,b}).
              b() -> #r{a=foo,b=42,a=bar}.
              u(R) -> R#r{a=1,b=2,a=2}.
             ">>,
           [],
           {errors,[{{2,36},erl_lint,{redefine_field,r,a}},
		    {{3,35},erl_lint,{redefine_field,r,a}}],[]}}],
    run(Config, Ts).

otp_11879_cont(Config) ->
    Ts = [{constraint1,
           <<"-export([t/1]).
              -spec t(X) -> X when is_subtype(integer()).
              t(a) -> foo:bar().
             ">>,
           [],
           {errors,
            [{{2,36},erl_parse,"unsupported constraint " ++ ["is_subtype"]}],
            []}},
          {constraint2,
           <<"-export([t/1]).
              -spec t(X) -> X when bad_atom(X, integer()).
              t(a) -> foo:bar().
             ">>,
           [],
           {errors,
            [{{2,36},erl_parse,"unsupported constraint " ++ ["bad_atom"]}],
            []}},
          {constraint3,
           <<"-export([t/1]).
              -spec t(X) -> X when is_subtype(bad_variable, integer()).
              t(a) -> foo:bar().
             ">>,
           [],
           {errors,[{{2,47},erl_parse,"bad type variable"}],[]}},
          {constraint4,
           <<"-export([t/1]).
              -spec t(X) -> X when is_subtype(atom(), integer()).
              t(a) -> foo:bar().
             ">>,
           [],
           {errors,[{{2,47},erl_parse,"bad type variable"}],[]}},
          {constraint5,
           <<"-export([t/1]).
              -spec t(X) -> X when is_subtype(X, integer()).
              t(a) -> foo:bar().
             ">>,
           [],
           []},
          {constraint6,
           <<"-export([t/1]).
              -spec t(X) -> X when X :: integer().
              t(a) -> foo:bar().
             ">>,
           [],
           []}],
    run(Config, Ts).

%% OTP-14285: We currently don't support non-latin1 module names.

non_latin1_module(Config) ->
    Expected = [non_latin1_module_unsupported],
    Expected = check_module_name('юникод'),
    Expected = check_module_name(list_to_atom([256,$a,$b,$c])),
    Expected = check_module_name(list_to_atom([$a,$b,256,$c])),

    "module names with non-latin1 characters are not supported" =
        format_error(non_latin1_module_unsupported),
    BadCallback =
        {bad_callback,{'кирилли́ческий атом','кирилли́ческий атом',0}},
    BadModule =
        {bad_module,{'кирилли́ческий атом','кирилли́ческий атом',0}},
    "explicit module not allowed for callback "
    "'кирилли́ческий атом':'кирилли́ческий атом'/0" =
        format_error(BadCallback),
    UndefBehav = {undefined_behaviour,'кирилли́ческий атом'},
    "behaviour 'кирилли́ческий атом' undefined" =
        format_error(UndefBehav),
    Ts = [{non_latin1_module,
           <<"
            %% Report uses of module names with non-Latin-1 characters.

            -import('кирилли́ческий атом', []).
            -behaviour('кирилли́ческий атом').
            -behavior('кирилли́ческий атом').

            -callback 'кирилли́ческий атом':'кирилли́ческий атом'() -> a.

            %% erl_lint:gexpr/3 is not extended to check module name here:
            t1() when 'кирилли́ческий атом':'кирилли́ческий атом'(1) ->
                b.

            t2() ->
                'кирилли́ческий атом':'кирилли́ческий атом'().

            -spec 'кирилли́ческий атом':'кирилли́ческий атом'() -> atom().

            -spec 'кирилли́ческий атом'(integer()) ->
              'кирилли́ческий атом':'кирилли́ческий атом'().

            'кирилли́ческий атом'(1) ->
                'кирилли́ческий атом':f(),
                F = f,
                'кирилли́ческий атом':F()."/utf8>>,
           [],
           {error,
            [{{4,14},erl_lint,non_latin1_module_unsupported},
             {{5,14},erl_lint,non_latin1_module_unsupported},
             {{6,14},erl_lint,non_latin1_module_unsupported},
             {{8,14},erl_lint,non_latin1_module_unsupported},
             {{8,14},erl_lint,BadCallback},
             {{11,23},erl_lint,illegal_guard_expr},
             {{15,17},erl_lint,non_latin1_module_unsupported},
             {{17,14},erl_lint,non_latin1_module_unsupported},
             {{17,14},erl_lint,BadModule},
             {{20,15},erl_lint,non_latin1_module_unsupported},
             {{23,17},erl_lint,non_latin1_module_unsupported},
             {{25,17},erl_lint,non_latin1_module_unsupported}],
            [{{5,14},erl_lint,UndefBehav},
             {{6,14},erl_lint,UndefBehav}]}}],
    run(Config, Ts),
    ok.

illegal_module_name(_Config) ->
    [empty_module_name] = check_module_name(''),

    [ctrl_chars_in_module_name] = check_module_name('\x00'),
    [ctrl_chars_in_module_name] = check_module_name('abc\x1F'),
    [ctrl_chars_in_module_name] = check_module_name('\x7F'),
    [ctrl_chars_in_module_name] = check_module_name('abc\x80'),
    [ctrl_chars_in_module_name] = check_module_name('abc\x80xyz'),
    [ctrl_chars_in_module_name] = check_module_name('\x9Fxyz'),

    [ctrl_chars_in_module_name,
     non_latin1_module_unsupported] = check_module_name('атом\x00'),

    [blank_module_name] = check_module_name(' '),
    [blank_module_name] = check_module_name('\xA0'),
    [blank_module_name] = check_module_name('\xAD'),
    [blank_module_name] = check_module_name('  \xA0\xAD '),

    %% White space and soft hyphens are OK if there are visible
    %% characters in the name.
    ok = check_module_name(' abc '),
    ok = check_module_name('abc '),
    ok = check_module_name(' abc '),
    ok = check_module_name(' abc xyz '),
    ok = check_module_name(' abc\xADxyz '),

    ok.

check_module_name(Mod) ->
    File = atom_to_list(Mod) ++ ".erl",
    L1 = erl_anno:new(1),
    Forms = [{attribute,L1,file,{File,1}},
             {attribute,L1,module,Mod},
             {eof,2}],
    _ = compile:forms(Forms),
    case compile:forms(Forms, [return]) of
        {error,Errors,[]} ->
            [{_ModName,L}] = Errors,
            lists:sort([Reason || {1,erl_lint,Reason} <- L]);
        {ok,Mod,Code,Ws} when is_binary(Code), is_list(Ws)  ->
            ok
    end.

otp_14378(Config) ->
    Ts = [
          {otp_14378_1,
           <<"-export([t/0]).
              -compile({nowarn_deprecated_function,{erlang,now,1}}).
              t() ->
                 erlang:now().">>,
           [],
           {warnings,[{{4,18},erl_lint,
                       {deprecated,{erlang,now,0},
                        "see the \"Time and Time Correction in Erlang\" "
                        "chapter of the ERTS User's Guide for more "
                        "information"}}]}}],
    [] = run(Config, Ts),
    ok.

%% OTP-14323: Check the dialyzer attribute.
otp_14323(Config) ->
    Ts = [
          {otp_14323_1,
           <<"-import(mod, [m/1]).

              -export([f/0, g/0, h/0]).

              -dialyzer({nowarn_function,module_info/0}). % undefined function
              -dialyzer({nowarn_function,record_info/2}). % undefined function
              -dialyzer({nowarn_function,m/1}). % undefined function

              -dialyzer(nowarn_function). % unknown option
              -dialyzer(1). % badly formed
              -dialyzer(malformed). % unknown option
              -dialyzer({malformed,f/0}). % unknown option
              -dialyzer({nowarn_function,a/1}). % undefined function
              -dialyzer({nowarn_function,{a,-1}}). % badly formed

              -dialyzer([no_return, no_match]).
              -dialyzer({nowarn_function, f/0}).
              -dialyzer(no_improper_lists).
              -dialyzer([{nowarn_function, [f/0]}, no_improper_lists]).
              -dialyzer({no_improper_lists, g/0}).
              -dialyzer({[no_return, no_match], [g/0, h/0]}).

              f() -> a.
              g() -> b.
              h() -> c.">>,
           [],
           {errors,[{{5,16},erl_lint,{undefined_function,{module_info,0}}},
                    {{6,16},erl_lint,{undefined_function,{record_info,2}}},
                    {{7,16},erl_lint,{undefined_function,{m,1}}},
                    {{9,16},erl_lint,{bad_dialyzer_option,nowarn_function}},
                    {{10,16},erl_lint,{bad_dialyzer_attribute,1}},
                    {{11,16},erl_lint,{bad_dialyzer_option,malformed}},
                    {{12,16},erl_lint,{bad_dialyzer_option,malformed}},
                    {{13,16},erl_lint,{undefined_function,{a,1}}},
                    {{14,16},erl_lint,{bad_dialyzer_attribute,
                                  {nowarn_function,{a,-1}}}}],
            []}},
          {otp_14323_2,
           <<"-type t(_) :: atom().">>,
           [],
           {errors,[{{1,29},erl_parse,"bad type variable"}],[]}}],
    [] = run(Config, Ts),
    ok.

stacktrace_syntax(Config) ->
    Ts = [{guard,
           <<"t1() ->
                  try error(foo)
                  catch _:_:Stk when is_number(Stk) -> ok
                  end.
           ">>,
           [],
           {errors,[{{3,48},erl_lint,{stacktrace_guard,'Stk'}}],[]}},
          {bound,
           <<"t1() ->
                  Stk = [],
                  try error(foo)
                  catch _:_:Stk -> ok
                  end.
           ">>,
           [],
           {errors,[{{4,29},erl_lint,{stacktrace_bound,'Stk'}}],[]}},
          {bound_in_pattern,
           <<"t1() ->
                  try error(foo)
                  catch _:{x,T}:T -> ok
                  end.
           ">>,
           [],
           {errors,[{{3,33},erl_lint,{stacktrace_bound,'T'}}],[]}},
          {guard_and_bound,
           <<"t1() ->
                  Stk = [],
                  try error(foo)
                  catch _:_:Stk when is_integer(Stk) -> ok
                  end.
           ">>,
           [],
           {errors,[{{4,29},erl_lint,{stacktrace_bound,'Stk'}},
                    {{4,49},erl_lint,{stacktrace_guard,'Stk'}}],[]}}
         ],

    run(Config, Ts),
    ok.


%% Unicode atoms.
otp_14285(Config) ->
    %% A small sample of all the errors and warnings in module erl_lint.
    E1 = {redefine_function,{'кирилли́ческий атом',0}},
    E2 = {attribute,'кирилли́ческий атом'},
    E3 = {undefined_record,'кирилли́ческий атом'},
    E4 = {undefined_bittype,'кирилли́ческий атом'},
    "function 'кирилли́ческий атом'/0 already defined" = format_error(E1),
    "attribute 'кирилли́ческий атом' after function definitions" =
        format_error(E2),
    "record 'кирилли́ческий атом' undefined" = format_error(E3),
    "bit type 'кирилли́ческий атом' undefined" = format_error(E4),
    Ts = [{otp_14285_1,
           <<"'кирилли́ческий атом'() -> a.
              'кирилли́ческий атом'() -> a.
             "/utf8>>,
           [],
           {errors,
            [{{2,15},erl_lint,E1}],
            []}},
         {otp_14285_2,
           <<"'кирилли́ческий атом'() -> a.
              -'кирилли́ческий атом'(a).
             "/utf8>>,
           [],
           {errors,
            [{{2,16},erl_lint,E2}],
            []}},
         {otp_14285_3,
           <<"'кирилли́ческий атом'() -> #'кирилли́ческий атом'{}.
             "/utf8>>,
           [],
           {errors,
            [{{1,48},erl_lint,E3}],
            []}},
         {otp_14285_4,
           <<"t() -> <<34/'кирилли́ческий атом'>>.
             "/utf8>>,
           [],
           {errors,
            [{{1,30},erl_lint,E4}],
            []}}],
    run(Config, Ts),
    ok.

external_funs(Config) when is_list(Config) ->
    Ts = [{external_funs_1,
           %% ERL-762: Unused variable warning not being emitted.
           <<"f() ->
                BugVar = process_info(self()),
                if true -> fun m:f/1 end.
              f(M, F) ->
                BugVar = process_info(self()),
                if true -> fun M:F/1 end.">>,
           [],
           {warnings,[{{2,17},erl_lint,{unused_var,'BugVar'}},
                      {{5,17},erl_lint,{unused_var,'BugVar'}}]}}],
    run(Config, Ts),
    ok.

otp_15563(Config) when is_list(Config) ->
    Ts = [{otp_15563,
           <<"-type deep_list(A) :: [A | deep_list(A)].
              -spec lists:flatten(deep_list(A)) -> [A].
              -callback lists:concat([_]) -> string().
              -spec ?MODULE:foo() -> any().
              foo() -> a.
           ">>,
           [warn_unused_vars],
           {errors,[{{2,16},erl_lint,{bad_module,{lists,flatten,1}}},
                    {{3,16},erl_lint,{bad_callback,{lists,concat,1}}}],
            []}}],
    [] = run(Config, Ts),
    ok.

removed(Config) when is_list(Config) ->
    Ts = [{removed,
          <<"-removed([{nonexistent,1,\"hi\"}]). %% okay since it doesn't exist
             -removed([frutt/0]).   %% okay since frutt/0 is not exported
             -removed([t/0]).       %% not okay since t/0 is exported
             -removed([{t,'_'}]).   %% not okay since t/0 is exported
             -removed([{'_','_'}]). %% not okay since t/0 is exported
             -removed([{{badly,formed},1}]).
             -removed('badly formed').
             -export([t/0]).
             frutt() -> ok.
             t() -> ok.
            ">>,
           {[]},
           {error,[{{3,15},erl_lint,{bad_removed,{t,0}}},
                   {{4,15},erl_lint,{bad_removed,{t,'_'}}},
                   {{5,15},erl_lint,{bad_removed,{'_','_'}}},
                   {{6,15},erl_lint,{invalid_removed,{{badly,formed},1}}},
                   {{7,15},erl_lint,{invalid_removed,'badly formed'}}],
                   [{{9,14},erl_lint,{unused_function,{frutt,0}}}]}}
         ],
    [] = run(Config, Ts),
    ok.

otp_16516(Config) when is_list(Config) ->
    one_multi_init(Config),
    several_multi_inits(Config).

one_multi_init(Config) ->
    "'_' initializes no omitted fields" =
        format_error(bad_multi_field_init),
    Ts = [{otp_16516_1,
           <<"-record(r, {f}).
              t(#r{f = 17, _ = V}) ->
                  V.
              u(#r{_ = V, f = 17}) ->
                  V.
              -record(r1, {f, g = 17}).
              g(#r1{f = 3, _ = 42}) ->
                g.
             ">>,
           [],
           {errors,[{{2,28},erl_lint,bad_multi_field_init},
                    {{4,20},erl_lint,bad_multi_field_init}],[]}},
          {otp_16516_2,
           %% No error since "_ = '_'" is actually used as a catch-all
           %% initialization. V is unused (as compilation with the 'E'
           %% option shows), but no warning about V being unused is
           %% output.
           <<"-record(r, {f}).
              t(V) ->
                  #r{f = 3, _ = V}.
              u(V) ->
                  #r{_ = V, f = 3}.
             ">>,
           [],
           []},
          {otp_16516_3,
           %% No error in this case either. And no unused variable warning.
           <<"-record(r, {f}).
              t(V) when #r{f = 3, _ = V} =:= #r{f = 3} ->
                  a.
              u(V) when #r{_ = V, f = 3} =:= #r{f = 3} ->
                  a.
             ">>,
           [],
           []}],
    [] = run(Config, Ts).

several_multi_inits(Config) ->
    Ts = [{otp_16516_4,
           <<"-record(r, {f, g}).
              t(#r{f = 17, _ = V1,
                           _ = V2}) ->
                  {V1, V2}.
              u(#r{_ = V1, f = 17,
                   _ = V2}) ->
                  {V1, V2}.
              v(#r{_ = V1, f = 17}) ->
                  V1.
             ">>,
           [],
           {errors,[{{3,28},erl_lint,bad_multi_field_init},
                    {{4,20},erl_lint,{unbound_var,'V1'}},
                    {{4,24},erl_lint,{unbound_var,'V2'}},
                    {{6,20},erl_lint,bad_multi_field_init},
                    {{7,20},erl_lint,{unbound_var,'V1'}},
                    {{7,24},erl_lint,{unbound_var,'V2'}}],[]}},
          {otp_16516_5,
           <<"-record(r, {f, g}).
              t(V1, V2) ->
                  #r{_ = V1, f = 3,
                     _ = V2}.
              u(V1, V2) ->
                  #r{_ = V1,
                     _ = V2, f = 3}.
             ">>,
           [],
           {error,[{{4,22},erl_lint,bad_multi_field_init},
                   {{7,22},erl_lint,bad_multi_field_init}],
            [{{2,21},erl_lint,{unused_var,'V2'}},
             {{5,21},erl_lint,{unused_var,'V2'}}]}},
          {otp_16516_6,
           <<"-record(r, {f, g}).
              t(V1, V2) when #r{_ = V1, f = 3,
                                _ = V2} =:= #r{} ->
                  a.
              u(V1, V2) when #r{_ = V1, f = 3,
                                _ = V2} =:= #r{} ->
                  a.
             ">>,
           [],
           {error,[{{3,33},erl_lint,bad_multi_field_init},
                   {{6,33},erl_lint,bad_multi_field_init}],
            [{{2,21},erl_lint,{unused_var,'V2'}},
             {{5,21},erl_lint,{unused_var,'V2'}}]}}],
    [] = run(Config, Ts).

inline_nifs(Config) ->
    Ts = [{implicit_inline,
           <<"-compile(inline).
              t() -> erlang:load_nif([], []).
              gurka() -> ok.
             ">>,
           [],
           {warnings,[{{2,22},erl_lint,nif_inline}]}},
          {explicit_inline,
           <<"-compile({inline, [gurka/0]}).
              t() -> erlang:load_nif([], []).
              gurka() -> ok.
             ">>,
           [],
           {warnings,[{{2,22},erl_lint,nif_inline}]}}],
    [] = run(Config, Ts).

undefined_nifs(Config) when is_list(Config) ->
    Ts = [{undefined_nifs,
          <<"-export([t/0]).
             -nifs([hej/1]).
              t() ->
                  erlang:load_nif(\"lib\", []).
            ">>,
           [],
           {errors,[{{2,15},erl_lint,{undefined_nif,{hej,1}}}],[]}}
         ],
    [] = run(Config, Ts),

    ok.

no_load_nif(Config) when is_list(Config) ->
    Ts = [{no_load_nif,
          <<"-export([t/0]).
             -nifs([t/0]).
              t() ->
                  a.
            ">>,
           [],
           {warnings,[{{2,15},erl_lint,no_load_nif}]}}
         ],
    [] = run(Config, Ts),

    ok.

warn_missing_spec(Config) ->
    Test = ~"""
-export([external_with_spec/0, external_no_spec/0,
         hidden_with_spec/0, hidden_no_spec/0]).

-spec external_with_spec() -> ok.
external_with_spec() -> ok.

external_no_spec() -> ok.

-spec hidden_with_spec() -> ok.
-doc hidden.
hidden_with_spec() -> ok.

-doc hidden.
hidden_no_spec() -> ok.

-spec internal_with_spec() -> ok.
internal_with_spec() -> ok.

internal_no_spec() -> ok.
""",

    %% Be sure to avoid adding export_all using the option-list-in-a-tuple trick.
    {warnings, [{{7,1}, erl_lint, {missing_spec, {external_no_spec, 0}}}]} =
        run_test(Config, Test, {[warn_missing_spec_documented, nowarn_unused_function]}),

    [] = run_test(Config, ["-moduledoc false.\n",Test],
                  {[warn_missing_spec_documented, nowarn_unused_function]}),

    {warnings, [{{7,1}, erl_lint, {missing_spec, {external_no_spec, 0}}},
                {{14,1}, erl_lint, {missing_spec, {hidden_no_spec, 0}}}]} =
        run_test(Config, Test, {[warn_missing_spec, nowarn_unused_function]}),

    {warnings, [{{8,1}, erl_lint, {missing_spec, {external_no_spec, 0}}},
                {{15,1}, erl_lint, {missing_spec, {hidden_no_spec, 0}}}]} =
        run_test(Config, ["-moduledoc false.\n",Test],
                 {[warn_missing_spec, nowarn_unused_function]}),

    Ts = [{warn_missing_spec_all, Test, [warn_missing_spec_all],
           {warnings, [{{7,1}, erl_lint, {missing_spec, {external_no_spec, 0}}},
                       {{14,1}, erl_lint, {missing_spec, {hidden_no_spec, 0}}},
                       {{19,1}, erl_lint, {missing_spec, {internal_no_spec, 0}}}]}},
          {warn_missing_spec_export_all,
           <<"-compile([export_all, nowarn_export_all]).
              -compile([warn_missing_spec_documented]).
              main(_) -> ok.
             ">>,
           [],
           {warnings,[{{3,15},erl_lint,{missing_spec,{main,1}}}]}}],
    run(Config, Ts).

otp_16824(Config) ->
    Ts = [{otp_16824_1,
          <<"-record(a, {x,y}).
              t() ->
                  R = #a{},
                  R#a{_ = 4},
                  R.
            ">>,
           {[]},
           {error,[{{4,23},erl_lint,{wildcard_in_update,a}}],
                  [{{2,15},erl_lint,{unused_function,{t,0}}}]}},

         {otp_16824_2,
          <<"\n-type t(_A, 3 + 4) :: integer().
            ">>,
           {[]},
          {errors,[{{2,13},erl_parse,"bad type variable"}],[]}},

         {otp_16824_3,
          <<"-export_type([s/0, t/0, u/0]).
             -record(r, {a :: integer() ,b :: atom()}).
             -type s() :: #s{a :: atom(), b :: integer()}.
             -type t() :: #r{c :: integer()}.
             -type u() :: #r{a :: integer(), a :: atom()}.
            ">>,
           {[]},
          {errors,[{{3,27},erl_lint,{undefined_record,s}},
                   {{4,30},erl_lint,{undefined_field,r,c}},
                   {{5,46},erl_lint,{redefine_field,r,a}}],
           []}}
         ],
    [] = run(Config, Ts),

    ok.

underscore_match(Config) when is_list(Config) ->
    Test = <<"
                match_underscore() ->
                    _Test = id(13),
                    case id(_Test) of               %% Usage: no warning.
                        _Test -> handle:msg(_Test)  %% Match: warning.
                    end.

                f(_A, _A, _A) ->                    %% Match: warning.
                    _A.                             %% Usage: no warning.

                t(_T, _T) ->                            %% Match: warning.
                    case _T of                          %% Usage: no warning.
                        {_T,_T} ->                      %% Match: warning.
                            {_T,_T} =                   %% Match: warning.
                                fun(_T1, _T1) ->        %% Match: warning.
                                        {_T,_T} = _T1   %% Match: warning.
                                end,
                        [_T = T2 || T2 <- _T],          %% Match: warning.
                        [{_T,_T} || _ <- _T]            %% Usage: no warning.
                    end.

                id(I) -> I.
           ">>,

    run(Config, [
        {warn_underscore_match, Test, [],
            {warnings,[{{5,25},erl_lint,{match_underscore_var,'_Test'}},
                       {{8,19},erl_lint,{match_underscore_var_pat,'_A'}},
                       {{8,23},erl_lint,{match_underscore_var_pat,'_A'}},
                       {{8,27},erl_lint,{match_underscore_var_pat,'_A'}},
                       {{11,19},erl_lint,{match_underscore_var_pat,'_T'}},
                       {{11,23},erl_lint,{match_underscore_var_pat,'_T'}},
                       {{13,26},erl_lint,{match_underscore_var,'_T'}},
                       {{13,29},erl_lint,{match_underscore_var,'_T'}},
                       {{14,30},erl_lint,{match_underscore_var,'_T'}},
                       {{14,33},erl_lint,{match_underscore_var,'_T'}},
                       {{15,37},erl_lint,{match_underscore_var_pat,'_T1'}},
                       {{15,42},erl_lint,{match_underscore_var_pat,'_T1'}},
                       {{16,42},erl_lint,{match_underscore_var,'_T'}},
                       {{16,45},erl_lint,{match_underscore_var,'_T'}},
                       {{18,26},erl_lint,{match_underscore_var,'_T'}}
                      ]}},
        {warn_underscore_match, Test, [warn_underscore_match],
            {warnings,[{{5,25},erl_lint,{match_underscore_var,'_Test'}},
                       {{8,19},erl_lint,{match_underscore_var_pat,'_A'}},
                       {{8,23},erl_lint,{match_underscore_var_pat,'_A'}},
                       {{8,27},erl_lint,{match_underscore_var_pat,'_A'}},
                       {{11,19},erl_lint,{match_underscore_var_pat,'_T'}},
                       {{11,23},erl_lint,{match_underscore_var_pat,'_T'}},
                       {{13,26},erl_lint,{match_underscore_var,'_T'}},
                       {{13,29},erl_lint,{match_underscore_var,'_T'}},
                       {{14,30},erl_lint,{match_underscore_var,'_T'}},
                       {{14,33},erl_lint,{match_underscore_var,'_T'}},
                       {{15,37},erl_lint,{match_underscore_var_pat,'_T1'}},
                       {{15,42},erl_lint,{match_underscore_var_pat,'_T1'}},
                       {{16,42},erl_lint,{match_underscore_var,'_T'}},
                       {{16,45},erl_lint,{match_underscore_var,'_T'}},
                       {{18,26},erl_lint,{match_underscore_var,'_T'}}
                      ]}},
        {nowarn_underscore_match, Test, [nowarn_underscore_match],
            []}
    ]).

unused_record(Config) when is_list(Config) ->
    Ts = [{unused_record_1,
          <<"-export([t/0]).
             -record(a, {x,y}).
             -compile({nowarn_unused_record,a}).
              t() ->
                  a.
            ">>,
           {[]},
           []},
          {unused_record_2,
          <<"-export([t/0]).
             -record(a, {x,y}).
             -compile(nowarn_unused_record).
              t() ->
                  a.
            ">>,
           {[]},
           []}
         ],
    [] = run(Config, Ts),

    ok.

untyped_record(Config) when is_list(Config) ->
    Ts = [{untyped_record_1,
          <<"-export([t/0]).
             -record(a, {x :: integer(), y}).
             -record(b, {}).
             -compile(warn_untyped_record).
              t() ->
                  {#a{}, #b{}}.
            ">>,
           {[]},
           {warnings,[{{2,15},erl_lint,{untyped_record,a}}]}}
         ],
    [] = run(Config, Ts),

    ok.

unused_type2(Config) when is_list(Config) ->
    Ts = [{unused_type2_1,
           <<"-type t() :: [t()].
              t() ->
                  a.
            ">>,
           {[]},
           {warnings,[{{1,22},erl_lint,{unused_type,{t,0}}},
                      {{2,15},erl_lint,{unused_function,{t,0}}}]}},
          {unused_type2_2,
           <<"-type t1() :: t2().
              -type t2() :: t1().
               t() ->
                   a.
            ">>,
           {[]},
           {warnings,[{{1,22},erl_lint,{unused_type,{t1,0}}},
                      {{2,16},erl_lint,{unused_type,{t2,0}}},
                      {{3,16},erl_lint,{unused_function,{t,0}}}]}},
          {unused_type2_3,
           <<"-callback cb() -> t().
              -type t() :: atom().
               t() ->
                   a.
            ">>,
           {[]},
           {warnings,[{{3,16},erl_lint,{unused_function,{t,0}}}]}},
          {unused_type2_4,
           <<"-spec t() -> t().
              -type t() :: atom().
               t() ->
                   a.
            ">>,
           {[]},
           {warnings,[{{3,16},erl_lint,{unused_function,{t,0}}}]}},
          {unused_type2_5,
           <<"-export_type([t/0]).
              -type t() :: atom().
               t() ->
                   a.
            ">>,
           {[]},
           {warnings,[{{3,16},erl_lint,{unused_function,{t,0}}}]}},
          {unused_type2_6,
           <<"-record(r, {f :: t()}).
              -type t() :: atom().
               t() ->
                   a.
            ">>,
           {[]},
           {warnings,[{{1,22},erl_lint,{unused_record,r}},
                      {{3,16},erl_lint,{unused_function,{t,0}}}]}}
         ],
    [] = run(Config, Ts),

    ok.

%% Test maybe ... else ... end.
eep49(Config) when is_list(Config) ->
    EnableMaybe = {feature,maybe_expr,enable},
    Ts = [{exp1,
           <<"t(X) ->
                  maybe
                      A = X()
                  end,
                  A.
           ">>,
           [EnableMaybe],
           {errors,[{{5,19},erl_lint,{unsafe_var,'A',{'maybe',{2,19}}}}],
            []}},

          {exp2,
           <<"t(X) ->
                  maybe
                      A = X()
                  else
                      _ -> {ok,A}
                  end,
                  A.
           ">>,
           [EnableMaybe],
           {errors,[{{5,32},erl_lint,{unsafe_var,'A',{'maybe',{2,19}}}},
                    {{7,19},erl_lint,{unsafe_var,'A',{'maybe',{2,19}}}}],
            []}},

          {exp3,
           <<"t(X) ->
                  maybe
                      X()
                  else
                      A ->
                          B = 42,
                          {error,A}
                  end,
                  {A,B}.
           ">>,
           [EnableMaybe],
           {errors,[{{9,20},erl_lint,{unsafe_var,'A',{'else',{4,19}}}},
                    {{9,22},erl_lint,{unsafe_var,'B',{'else',{4,19}}}}],
            []}},

          {exp4,
           <<"t(X) ->
                  maybe
                      X()
                  else
                      ok ->
                          A = 42;
                      error ->
                          error
                  end,
                  A.
           ">>,
           [EnableMaybe],
           {errors,[{{10,19},erl_lint,{unsafe_var,'A',{'else',{4,19}}}}],
            []}},

          %% Using '?=' not at the top-level of a 'maybe' ... 'else' is forbidden.
          {illegal_maybe_match1,
           <<"t(X) ->
                  maybe (ok ?= X()) end.
           ">>,
           [EnableMaybe],
           {errors,[{{2,29},erl_parse,["syntax error before: ","'?='"]}],[]}},
          {illegal_maybe_match2,
           <<"t(X) ->
                  ok ?= X().
           ">>,
           [EnableMaybe],
           {errors,[{{2,22},erl_parse,["syntax error before: ","'?='"]}],[]}}
         ],

    [] = run(Config, Ts),
    ok.

%% GH-6132: Allow local redefinition of types.
redefined_builtin_type(Config) ->
    Ts = [{redef1,
           <<"-type nonempty_binary() :: term().
              -type map() :: {_,_}.">>,
           [nowarn_unused_type,
            nowarn_redefined_builtin_type],
           []},
          {redef2,
           <<"-type nonempty_bitstring() :: term().
              -type map() :: {_,_}.">>,
           [nowarn_unused_type,
            {nowarn_redefined_builtin_type,{map,0}}],
           {warnings,[{{1,22},erl_lint,
                       {redefine_builtin_type,{nonempty_bitstring,0}}}]}},
          {redef3,
           <<"-compile({nowarn_redefined_builtin_type,{map,0}}).
              -compile({nowarn_redefined_builtin_type,[{nonempty_bitstring,0}]}).
              -type nonempty_bitstring() :: term().
              -type map() :: {_,_}.
              -type list() :: erlang:map().">>,
           [nowarn_unused_type,
            {nowarn_redefined_builtin_type,{map,0}}],
           {warnings,[{{5,16},erl_lint,
                       {redefine_builtin_type,{list,0}}}]}},
          {redef4,
           <<"-type tuple() :: 'tuple'.
              -type map() :: 'map'.
              -type list() :: 'list'.
              -spec t(tuple() | map()) -> list().
              t(_) -> ok.
             ">>,
           [],
           {warnings,[{{1,22},erl_lint,{redefine_builtin_type,{tuple,0}}},
                      {{2,16},erl_lint,{redefine_builtin_type,{map,0}}},
                      {{3,16},erl_lint,{redefine_builtin_type,{list,0}}}
                     ]}},
          {redef5,
           <<"-type atom() :: 'atom'.
              -type integer() :: 'integer'.
              -type reference() :: 'ref'.
              -type pid() :: 'pid'.
              -type port() :: 'port'.
              -type float() :: 'float'.
              -type iodata() :: 'iodata'.
              -type ref_set() :: gb_sets:set(reference()).
              -type pid_map() :: #{pid() => port()}.
              -type atom_int_fun() :: fun((atom()) -> integer()).
              -type collection(Type) :: {'collection', Type}.
              -callback b1(I :: iodata()) -> atom().
              -spec t(collection(float())) -> {pid_map(), ref_set(), atom_int_fun()}.
              t(_) -> ok.
             ">>,
           [],
           {warnings,[{{1,22},erl_lint,{redefine_builtin_type,{atom,0}}},
                      {{2,16},erl_lint,{redefine_builtin_type,{integer,0}}},
                      {{3,16},erl_lint,{redefine_builtin_type,{reference,0}}},
                      {{4,16},erl_lint,{redefine_builtin_type,{pid,0}}},
                      {{5,16},erl_lint,{redefine_builtin_type,{port,0}}},
                      {{6,16},erl_lint,{redefine_builtin_type,{float,0}}},
                      {{7,16},erl_lint,{redefine_builtin_type,{iodata,0}}}
                     ]}},
          {redef6,
           <<"-spec bar(function()) -> bar().
              bar({function, F}) -> F().
              -type function() :: {function, fun(() -> bar())}.
              -type bar() :: {bar, binary()}.
             ">>,
           [],
           {warnings,[{{3,16},erl_lint,
                       {redefine_builtin_type,{function,0}}}]}},
          {redef7,
           <<"-type function() :: {function, fun(() -> bar())}.
              -type bar() :: {bar, binary()}.
              -spec bar(function()) -> bar().
              bar({function, F}) -> F().
             ">>,
           [],
           {warnings,[{{1,22},erl_lint,
                       {redefine_builtin_type,{function,0}}}]}},
          {redef8,
           <<"-type function() :: {function, fun(() -> atom())}.
             ">>,
           [],
           {warnings,[{{1,22},erl_lint,
                       {redefine_builtin_type,{function,0}}},
                      {{1,22},erl_lint,
                       {unused_type,{function,0}}}]}},
          {redef9,
           <<"-spec foo() -> fun().
              foo() -> fun() -> ok end.
             ">>,
           [],
           []}
         ],
    [] = run(Config, Ts),
    ok.

tilde_k(Config) ->
    Ts = [{tilde_k_1,
           <<"t(Map) ->
                  io:format(\"~kp\n\", [Map]),
                  io:format(\"~kP\n\", [Map,10]),
                  io:format(\"~kw\n\", [Map]),
                  io:format(\"~kW\n\", [Map,5]),
                  io:format(\"~tkp\n\", [Map]),
                  io:format(\"~klp\n\", [Map]),
                  RevCmpFun = fun erlang:'>='/2,
                  io:format(\"~Kp\n\", [RevCmpFun,Map]),
                  io:format(\"~KP\n\", [RevCmpFun,Map,10]),
                  io:format(\"~Kw\n\", [RevCmpFun,Map]),
                  io:format(\"~KW\n\", [RevCmpFun,Map,5]),
                  ok.">>,
           [],
           []},
          {tilde_k_2,
           <<"t(Map) ->
                  io:format(\"~kkp\n\", [Map]),
                  io:format(\"~kKp\n\", [Map]),
                  io:format(\"~ks\n\", [Map]),
                  ok.">>,
           [],
           {warnings,
            [{{2,29},
              erl_lint,
              {format_error,{"format string invalid (~ts)",
                             ["repeated modifier k"]}}},
             {{4,29},
              erl_lint,
              {format_error,{"format string invalid (~ts)",
                             ["conflicting modifiers ~Kkp"]}}},
             {{6,29},
              erl_lint,
              {format_error,{"format string invalid (~ts)",
                             ["invalid modifier/control combination ~ks"]}}}]}
          }
         ],
    [] = run(Config, Ts),

    ok.

match_float_zero(Config) ->
    Ts = [{float_zero_1,
           <<"t(+0.0) -> ok.\n"
             "k(-0.0) -> ok.\n">>,
           [],
           []},
          {float_zero_2,
           <<"t(0.0) -> ok.\n"
             "k({0.0}) -> ok.\n">>,
           [],
           {warnings,[{{1,23},erl_lint,match_float_zero},
                      {{2,4},erl_lint,match_float_zero}]}},
          {float_zero_3,
           <<"t(A) when A =:= 0.0 -> ok;\n" %% Should warn.
             "t(A) when A =:= {0.0} -> ok.\n" %% Should warn.
             "k(A) -> A =:= 0.0.\n" %% Should warn.
             "q(A) -> A =:= {0.0}.\n" %% Should warn.
             "z(A) when A =:= +0.0 -> ok;\n" %% Should not warn.
             "z(A) when A =:= {+0.0} -> ok.\n">>, %% Should not warn.
           [],
           {warnings,[{{1,37},erl_lint,match_float_zero},
                      {{2,18},erl_lint,match_float_zero},
                      {{3,15},erl_lint,match_float_zero},
                      {{4,16},erl_lint,match_float_zero}]}}
         ],
    [] = run(Config, Ts),

    ok.

%% GH-7655. When the module definition was missing, spurious
%% diagnostics would be emitted for each spec.
undefined_module(Config) ->
    Code = <<"-spec foo() -> 'ok'.
              foo() -> ok.
             ">>,
    {errors,[{{1,2},erl_lint,undefined_module}],[]} = run_test2(Config, Code, []),

    ok.

update_literal(Config) ->
    Ts = [{update_record_literal,
           <<"-record(a, {b}).
             t() -> #a{}#a{}#a{b=aoeu}.
             k() -> A = #a{}, A#a{}#a{b=aoeu}.">>,
           [],
           {warnings,[{{2,25},erl_lint,update_literal},
                      {{2,29},erl_lint,update_literal}]}},
          {update_map_literal_assoc,
           <<"t() -> #{}#{}#{b=>aoeu}.
              k() -> A = #{}, A#{}#{b=>aoeu}.">>,
           [],
           {warnings,[{{1,31},erl_lint,update_literal},
                      {{1,34},erl_lint,update_literal}]}},
          {update_map_literal_exact,
           <<"t() -> #{}#{}#{b:=aoeu}.
              k() -> A = #{}, A#{}#{b:=aoeu}.">>,
           [],
           {warnings,[{{1,31},erl_lint,update_literal},
                      {{1,34},erl_lint,update_literal}]}}
         ],
    [] = run(Config, Ts),

    ok.

%% For certain kinds of errors that are easily caused by typos, error 
%% messages try to suggest fixes according to jaro_similarity.
messages_with_jaro_suggestions(Config) ->
    Ts = [{on_load_fun,
           <<"-on_load(foa/0).
              foo() -> ok.">>,
           {[]},
           {error,[{{1,22},erl_lint,{undefined_on_load,{foa,0},foo}}],
            [{{2,15},erl_lint,{unused_function,{foo,0}}}]}},
          {undefined_nif,
           <<"-export([foo/1,bar/2]).
              -nifs([foa/1,bar/1]).
              -on_load(init/0).
              init() ->
                  ok = erlang:load_nif(\"./example_nif\", 0).
              foo(_X) ->
                  erlang:nif_error(nif_library_not_loaded).
              bar(_X,_Y) ->
                  erlang:nif_error(nif_library_not_loaded).">>,
           {[]},
           {errors,[{{2,16},erl_lint,{undefined_nif,{bar,1},{bar,[2]}}},
                    {{2,16},erl_lint,{undefined_nif,{foa,1},{foo,[1]}}}],[]}},
          {record_and_field,
           <<"-record(meep, { moo, muu }).
              t(State) ->
                  Var = State#meep.mo,
                  State#mee{ moo = Var }.">>,
           {[]},
           {error,[{{3,36},erl_lint,{undefined_field,meep,mo,moo}},
                   {{4,24},erl_lint,{undefined_record,mee,meep}}],
            [{{2,15},erl_lint,{unused_function,{t,1}}},
             {{3,19},erl_lint,{unused_var,'Var'}}]}},
          {unbound_var,
           <<"-record(meep, { moo, muu }).
              t(State) ->
                  Var = State#meep.moo,
                  Stat#meep{ moo = Var }.">>,
           {[]},
           {error,[{{4,19},erl_lint,{unbound_var,'Stat','State'}}],
            [{{2,15},erl_lint,{unused_function,{t,1}}}]}},
          {undefined_fun,
           <<"-export([bar/1,foo/2]).
              baz(X) -> X.
              foo(X) -> X.
              foo(X, Y, Z) -> X + Y + Z.">>,
           {[]},
           {error,[{{1,22},erl_lint,{undefined_function,{bar,1},{baz,[1]}}},
                   {{1,22},erl_lint,{undefined_function,{foo,2},{foo,[1,3]}}}],
                  [{{2,15},erl_lint,{unused_function,{baz,1}}},
                   {{3,15},erl_lint,{unused_function,{foo,1}}},
                   {{4,15},erl_lint,{unused_function,{foo,3}}}]}},
          {nowarn_undefined_fun,
           <<"-compile({nowarn_unused_function,[{an_not_used,1}]}).
              and_not_used(_) -> foo.">>,
           {[]},
           {error,[{{1,22}, erl_lint,
                    {bad_nowarn_unused_function,{an_not_used,1},{and_not_used,[1]}}}],
            [{{2,15},erl_lint,{unused_function,{and_not_used,1}}}]}},
          {bad_inline,
           <<"-compile({inline, [{foo,1},{ba,1}]}).
              foa(A) -> {A}.
              ba(A, A) -> [A].">>,
           {[]},
           {error,[{{1,22},erl_lint,{bad_inline,{ba,1},{ba,[2]}}},
                   {{1,22},erl_lint,{bad_inline,{foo,1},{foa,[1]}}}],
                  [{{2,15},erl_lint,{unused_function,{foa,1}}},
                   {{3,15},erl_lint,{unused_function,{ba,2}}}]}},
          {bad_dialyzer_attribute,
            <<"-dialyzer({nowarn_function,[foo/2,bar/1]}).
                foo(X, Y, Z) -> X + Y + Z.
                baz(A) -> A.">>,
            {[]},
            {error,[{{1,22},erl_lint,{undefined_function,{bar,1},{baz,[1]}}},
                    {{1,22},erl_lint,{undefined_function,{foo,2},{foo,[3]}}}],
                   [{{2,17},erl_lint,{unused_function,{foo,3}}},
                    {{3,17},erl_lint,{unused_function,{baz,1}}}]}}
         ],
    [] = run(Config, Ts),

    ok.

illegal_zip_generator(Config) ->
    Ts = [{not_generator,
           <<"-compile({nowarn_unused_function,[{foo,0}]}).
            foo() -> [X + Y || X <- [1,2,3,4] && Y <- [5,6,7] && X > 1].
            ">>,
           {[]},
           {errors,[{{2,68},erl_lint,illegal_zip_generator}],[]}},
           {not_generator,
           <<"-compile({nowarn_unused_function,[{bar,0}]}).
            bar() -> [X + Y || X <- [[1,2],[3,4]] && lists:sum(X) > 0 && Y <- [5,6,7]].
            ">>,
           {[]},
           {errors,[{{2,67},erl_lint,illegal_zip_generator}],[]}},
           {not_generator,
           <<"-compile({nowarn_unused_function,[{foo,0}]}).
            foo() -> [X || X <- [a, b] && F()].
            ">>,
           {[]},
           {errors,[{{2,43},erl_lint,illegal_zip_generator}],[]}},
           {not_generator,
           <<"-compile({nowarn_unused_function,[{foo,0}]}).
            foo() -> [X || a && b].
            ">>,
           {[]},
           {errors,[{{2,23},erl_lint,{unbound_var,'X'}},
                    {{2,28},erl_lint,illegal_zip_generator},
                    {{2,33},erl_lint,illegal_zip_generator}],
                    []}}
           ],
    [] = run(Config,Ts),

    ok.

%% GH-9694. Only record_info/2 should be checked for illegal_record_info
record_info_0(Config) ->
    Ts = [{record_info_0,
           <<"-export([f/0]).
              record_info() -> ok.
              f() -> record_info().
            ">>,
           [],
           []},
          {record_info_1,
           <<"-export([g/0]).
              record_info(X) -> X.
              g() -> record_info(ok).
            ">>,
           [],
           []}
         ],
    [] = run(Config, Ts),

    ok.

coverage(Config) ->
    do_coverage(),

    Ts = [{keyword_warning,
           <<"-feature(maybe_expr, disable).
              -compile(warn_keywords).
              f() -> maybe.
              g() -> 'maybe'.
            ">>,
           [],
           {warnings,[{{3,22},erl_lint,{future_feature,maybe_expr,'maybe'}}]}},

          {invalid_stuff,
           <<"-record(r, {a}).
              f() -> []().
              g() -> (no_record)#r{a=42}.
            ">>,
           [no_copt],
           {warnings,[{{2,22},erl_lint,invalid_call},
                      {{3,33},erl_lint,invalid_record}]}}
         ],
    [] = run(Config, Ts),

    ok.

%% Improve code coverage for erl_parse and erl_lint by compiling
%% all source code in STDLIB.
do_coverage() ->
    Wc = filename:join(code:lib_dir(stdlib), "src/*.erl"),
    KernelInc = filename:join(code:lib_dir(kernel), "include"),
    StdlibInc = filename:join(code:lib_dir(stdlib), "include"),
    Res = [begin
               Mod = filename:rootname(filename:basename(File)),
               Opts = [return,binary,'E',
                       {i,KernelInc},{i,StdlibInc}],
               case compile:file(File, Opts) of
                   {ok,_,_,_} ->
                       Mod
               end
           end || File <- filelib:wildcard(Wc)],
    io:format("~p\n", [Res]),
    ok.

%%%
%%% Common utilities.
%%%

rewrite([{Name,Code,[],{warnings,_}}=H|T], Subst) ->
    case Subst of
        #{Name := Opts} ->
            io:format("~s: testing with options ~p\n", [Name,Opts]),
            [{Name,Code,Opts,[]}|rewrite(T, Subst)];
        #{} ->
            [H|rewrite(T, Subst)]
    end;
rewrite([H|T], Subst) ->
    [H|rewrite(T, Subst)];
rewrite([], _Subst) ->
    [].

format_error(E) ->
    lists:flatten(erl_lint:format_error(E)).

run(Config, Tests) ->
    F = fun({N,P,Ws,E}, BadL) ->
                io:format("### ~s\n", [N]),
                case catch run_test(Config, P, Ws) of
                    E -> 
                        BadL;
                    Bad -> 
                        io:format("~nTest ~p failed. Expected~n  ~p~n"
                                  "but got~n  ~p~n", [N, E, Bad]),
			fail()
                end
        end,
    lists:foldl(F, [], Tests).

%% Compiles a test file and returns the list of warnings/errors.

get_compilation_result(Conf, Filename, Warnings) ->
    DataDir = ?datadir,
    File = filename:join(DataDir, Filename),
    {ok,Bin} = file:read_file(File++".erl"),
    FileS = binary_to_list(Bin),
    {match,[{Start,Length}|_]} = re:run(FileS, "-module.*\\n"),
    Test = lists:nthtail(Start+Length, FileS),
    case run_test(Conf, Test, Warnings) of
        {warnings, Ws} -> Ws;
        {errors,Es,Ws} -> {Es,Ws};
        [] -> []
    end.

%% Compiles a test module and returns the list of errors and warnings.

run_test(Conf, Test0, Warnings0) ->
    Test = list_to_binary(["-module(lint_test). ", Test0]),
    run_test2(Conf, Test, Warnings0).

run_test2(Conf, Test, Warnings0) ->
    Filename = "lint_test.erl",
    DataDir = ?privdir,
    File = filename:join(DataDir, Filename),
    Opts = case Warnings0 of
               {Warnings} ->		%Hairy trick to not add export_all.
                   [return|Warnings];
               Warnings ->
                   [export_all,return|Warnings]
           end,
    ok = file:write_file(File, Test),

    %% We will use the 'binary' option so that the compiler will not
    %% compare the module name to the output file name. Also, there
    %% is no reason to produce an output file since we are only
    %% interested in the errors and warnings.

    %% Print warnings, call erl_lint:format_error/1. (But note that
    %% the compiler will ignore failing calls to erl_lint:format_error/1.)
    compile:file(File, [binary,report|Opts]),

    case compile:file(File, [binary|Opts]) of
        {ok, _M, Code, Ws} when is_binary(Code) ->
            warnings(File, Ws, Test);
        {error, [{File,Es}], []} ->
            print_diagnostics(Es, Test),
	    {errors, call_format_error(Es), []};
        {error, [{File,Es}], [{File,Ws}]} ->
            print_diagnostics(Es, Test),
            print_diagnostics(Ws, Test),
	    {error, call_format_error(Es), call_format_error(Ws)};
        {error, [{File,Es1},{File,Es2}], []} ->
            print_diagnostics(Es1, Test),
            print_diagnostics(Es2, Test),
	    {errors2, Es1, Es2}
    end.

warnings(File, Ws, Source) ->
    case lists:append([W || {F, W} <- Ws, F =:= File]) of
        [] ->
	    [];
        L ->
            print_diagnostics(L, Source),
	    {warnings, call_format_error(L)}
    end.

call_format_error(L) ->
    %% Smoke test of format_error/1 to make sure that no crashes
    %% slip through.
    _ = [Mod:format_error(Term) || {_,Mod,Term} <- L],
    L.

print_diagnostics(Warnings, Source) ->
    case binary:match(Source, <<"-file(">>) of
        nomatch ->
            Lines = binary:split(Source, <<"\n">>, [global]),
            Cs = [print_diagnostic(W, Lines) || W <- Warnings],
            io:put_chars(Cs);
        _ ->
            %% There are probably fake line numbers greater than
            %% the number of actual lines.
            ok
    end.

print_diagnostic({{LineNum,Column},Mod,Data}, Lines) ->
    Line0 = lists:nth(LineNum, Lines),
    <<Line1:(Column-1)/binary,_/binary>> = Line0,
    Spaces = re:replace(Line1, <<"[^\t]">>, <<" ">>, [global]),
    CaretLine = [Spaces,"^"],
    [io_lib:format("~p:~p: ~ts\n", [LineNum,Column,Mod:format_error(Data)]),
     Line0, "\n",
     CaretLine, "\n\n"];
print_diagnostic(_, _) ->
    [].

fail() ->
    ct:fail(failed).
