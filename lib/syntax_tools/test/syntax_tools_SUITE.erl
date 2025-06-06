%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0 OR LGPL-2.1-or-later
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
%% Alternatively, you may use this file under the terms of the GNU Lesser
%% General Public License (the "LGPL") as published by the Free Software
%% Foundation; either version 2.1, or (at your option) any later version.
%% If you wish to allow use of your version of this file only under the
%% terms of the LGPL, you should delete the provisions above and replace
%% them with the notice and other provisions required by the LGPL; see
%% <http://www.gnu.org/licenses/>. If you do not delete the provisions
%% above, a recipient may use your version of this file under the terms of
%% either the Apache License or the LGPL.
%%
%% %CopyrightEnd%

-module(syntax_tools_SUITE).

-include_lib("common_test/include/ct.hrl").

%% Test server specific exports
-export([all/0, suite/0,groups/0,init_per_suite/1, end_per_suite/1,
	 init_per_group/2,end_per_group/2]).

%% Test cases
-export([app_test/1,appup_test/1,smoke_test/1,revert/1,revert_map/1,
         revert_map_type/1,revert_preserve_pos_changes/1,
         wrapped_subtrees/1,
         t_abstract_type/1,t_erl_parse_type/1,t_type/1,
         t_epp_dodger/1,t_epp_dodger_clever/1,
         t_comment_scan/1,t_prettypr/1,test_named_fun_bind_ann/1,
         test_maybe_expr_ann/1]).

suite() -> [{ct_hooks,[ts_install_cth]}].

all() ->
    [app_test,appup_test,smoke_test,revert,revert_map,revert_map_type,
     revert_preserve_pos_changes,
     wrapped_subtrees,
     t_abstract_type,t_erl_parse_type,t_type,
     t_epp_dodger,t_epp_dodger_clever,
     t_comment_scan,t_prettypr,test_named_fun_bind_ann,
     test_maybe_expr_ann].

groups() ->
    [].

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_group(_GroupName, Config) ->
    Config.

end_per_group(_GroupName, Config) ->
    Config.

app_test(Config) when is_list(Config) ->
    ok = test_server:app_test(syntax_tools).

appup_test(Config) when is_list(Config) ->
    ok = test_server:appup_test(syntax_tools).

%% Read and parse all source in the OTP release.
smoke_test(Config) when is_list(Config) ->
    Dog = test_server:timetrap(test_server:minutes(12)),
    Wc = filename:join([code:lib_dir(),"*","src","*.erl"]),
    Fs = filelib:wildcard(Wc) ++ test_files(Config),
    io:format("~p files\n", [length(Fs)]),
    case p_run(fun smoke_test_file/1, Fs) of
        0 -> ok;
        N -> ct:fail({N,errors})
    end,
    test_server:timetrap_cancel(Dog).

smoke_test_file(File) ->
    case epp_dodger:parse_file(File) of
	{ok,Forms} ->
	    [print_error_markers(F, File) || F <- Forms],
	    ok;
	{error,Reason} ->
	    io:format("~ts: ~p\n", [File,Reason]),
	    error
    end.

print_error_markers(F, File) ->
    case erl_syntax:type(F) of
	error_marker ->
	    {L,M,Info} = erl_syntax:error_marker_info(F),
	    io:format("~ts:~p: ~ts", [File,L,M:format_error(Info)]);
	_ ->
	    ok
    end.


%% Read with erl_parse, wrap and revert with erl_syntax and check for equality.
revert(Config) when is_list(Config) ->
    Dog = test_server:timetrap(test_server:minutes(12)),
    Wc = filename:join([code:lib_dir("stdlib"),"src","*.erl"]),
    Fs = filelib:wildcard(Wc) ++ test_files(Config),
    Path = [filename:join(code:lib_dir(stdlib), "include"),
            filename:join(code:lib_dir(kernel), "include")],
    io:format("~p files\n", [length(Fs)]),
    case p_run(fun (File) -> revert_file(File, Path) end, Fs) of
        0 -> ok;
        N -> ct:fail({N,errors})
        end,
    test_server:timetrap_cancel(Dog).

revert_file(File, Path) ->
    case epp:parse_file(File, [{includes,Path},
                               res_word_option()]) of
        {ok,Fs0} ->
            Fs1 = erl_syntax:form_list(Fs0),
            Fs2 = erl_syntax_lib:map(fun (Node) -> Node end, Fs1),
            Fs3 = erl_syntax:form_list_elements(Fs2),
            Fs4 = [ erl_syntax:revert(Form) || Form <- Fs3 ],
            case compile:forms(Fs4, [report,return,strong_validation]) of
                {ok,_,_} -> ok;
                {error, [{_, [{_, epp, {moduledoc, file, _}}]}],[]} ->
                    ok;
                {error, [{_, [{_, epp, {doc, file, _}}]}],[]} ->
                    ok
            end
    end.

%% Testing bug fix for reverting map_field_assoc
revert_map(Config) when is_list(Config) ->
    Dog = test_server:timetrap(test_server:minutes(1)),
    [{map_field_assoc,16,{atom,17,name},{var,18,'Value'}}] =
    erl_syntax:revert_forms([{tree,map_field_assoc,
                             {attr,16,[],none},
			     {map_field_assoc,{atom,17,name},{var,18,'Value'}}}]),
    test_server:timetrap_cancel(Dog).

%% Testing bug fix for reverting map_field_assoc in types
revert_map_type(Config) when is_list(Config) ->
    Dog = test_server:timetrap(test_server:minutes(1)),
    Form1 = {attribute,4,record,
             {state,
              [{typed_record_field,
                {record_field,5,{atom,5,x}},
                {type,5,map,
                 [{type,5,map_field_exact,[{atom,5,y},{atom,5,z}]}]}}]}},
    Mapped1 = erl_syntax_lib:map(fun(X) -> X end, Form1),
    Form1 = erl_syntax:revert(Mapped1),
    Form2 = {attribute,4,record,
             {state,
              [{typed_record_field,
                {record_field,5,{atom,5,x}},
                {type,5,map,
                 [{type,5,map_field_assoc,[{atom,5,y},{atom,5,z}]}]}}]}},
    Mapped2 = erl_syntax_lib:map(fun(X) -> X end, Form2),
    Form2 = erl_syntax:revert(Mapped2),
    test_server:timetrap_cancel(Dog).

revert_preserve_pos_changes(Config) when is_list(Config) ->
    Dog = test_server:timetrap(test_server:minutes(1)),
    Pos0 = 1,
    Var0 = {var, Pos0, 'Var'},
    %% Adding any user annotation makes erl_syntax change to it's internal
    %% representation
    Var1 = erl_syntax:add_ann({env, []}, Var0),
    %% Change the `pos' of the node
    Pos1 = erl_anno:set_generated(true, Pos0),
    Var2 = erl_syntax:set_pos(Var1, Pos1),
    %% The must be equal when reverted
    {var, Pos1, 'Var'} = erl_syntax:revert(Var2),
    test_server:timetrap_cancel(Dog).

%% Read with erl_parse, wrap each tree node with erl_syntax and check that
%% erl_syntax:subtrees can access the wrapped node.
wrapped_subtrees(Config) when is_list(Config) ->
    Dog = test_server:timetrap(test_server:minutes(2)),
    Wc = filename:join([code:lib_dir(stdlib),"src","*.erl"]),
    Fs = filelib:wildcard(Wc) ++ test_files(Config),
    Path = [filename:join(code:lib_dir(stdlib), "include"),
            filename:join(code:lib_dir(kernel), "include")],
    io:format("~p files\n", [length(Fs)]),
    Map = fun (File) -> wrapped_subtrees_file(File, Path) end,
    case p_run(Map, Fs) of
        0 -> ok;
        N -> ct:fail({N,errors})
    end,
    test_server:timetrap_cancel(Dog).

wrapped_subtrees_file(File, Path) ->
    case epp:parse_file(File, Path, []) of
        {ok,Fs0} ->
            lists:foreach(fun wrap_each/1, Fs0)
    end.

wrap_each(Tree) ->
    % only `wrap` top-level erl_parse node
    Tree1 = erl_syntax:set_pos(Tree, erl_syntax:get_pos(Tree)),
    % assert ability to access subtrees of wrapped node with erl_syntax:subtrees/1
    case erl_syntax:subtrees(Tree1) of
        [] -> ok;
        List ->
            GrpsF = fun(Group) ->
                          lists:foreach(fun wrap_each/1, Group)
                    end,
            lists:foreach(GrpsF, List)
    end.

%% api tests

t_type(Config) when is_list(Config) ->
    F0 = fun validate_basic_type/1,
    Appl0 = fun(Name) ->
                    Atom = erl_syntax:atom(Name),
                    erl_syntax:type_application(none, Atom, [])
            end,
    User0 = fun(Name) ->
                    Atom = erl_syntax:atom(Name),
                    erl_syntax:user_type_application(Atom, [])
            end,
    ok = validate(F0,[{"tuple()", erl_syntax:tuple_type()}
                     ,{"{}", erl_syntax:tuple_type([])}
                     ,{"integer()", Appl0(integer)}
                     ,{"foo()", User0(foo)}
                     ,{"map()", erl_syntax:map_type()}
                     ,{"#{}", erl_syntax:map_type([])}
                     ,{"1..2", erl_syntax:integer_range_type
                          (erl_syntax:integer(1), erl_syntax:integer(2))}
                     ,{"<<_:1,_:_*2>>", erl_syntax:bitstring_type
                          (erl_syntax:integer(1), erl_syntax:integer(2))}
                     ,{"fun()", erl_syntax:fun_type()}
                     ]),

    F = fun validate_type/1,
    ok = validate(F,[{"{}", tuple_type, false}
                    ,{"tuple()", tuple_type, true}
                    ,{"{atom()}", tuple_type, false}
                    ,{"{atom(),integer()}", tuple_type, false}
                    ,{"integer()", type_application, false}
                    ,{"foo()", user_type_application, false}
                    ,{"foo(integer())", user_type_application, false}
                    ,{"module:function()", type_application, false}
                    ,{"map()", map_type, true}
                    ,{"#{}", map_type, false}
                    ,{"#{atom() => integer()}", map_type, false}
                    ,{"#{atom() := integer()}", map_type, false}
                    ,{"#r{}", record_type, false}
                    ,{"#r{a :: integer()}", record_type, false}
                    ,{"[]", type_application, false}
                    ,{"nil()", type_application, false}
                    ,{"[atom()]", type_application, false}
                    ,{"1..2", integer_range_type, false}
                    ,{"<<_:1,_:_*2>>", bitstring_type, false}
                    ,{"fun()", fun_type, true}
                    ,{"integer() | atom()", type_union, false}
                    ,{"A :: fun()", annotated_type, false}
                    ,{"fun((...) -> atom())", function_type, false}
                    ,{"fun((integer()) -> atom())", function_type, false}
                    ,{"V", variable, true}
                    ]),
    ok.

validate_basic_type({String, Tree}) ->
    ErlT = string_to_type(String),
    ErlT = erl_syntax:revert(Tree),
    ok.

validate_type({String, Type, Leaf}) ->
    ErlT = string_to_type(String),
    Type = erl_syntax:type(ErlT),
    Leaf = erl_syntax:is_leaf(ErlT),
    Tree = erl_syntax_lib:map(fun(Node) -> Node end, ErlT),
    Type = erl_syntax:type(Tree),
    _    = erl_syntax:meta(Tree),
    RevT = erl_syntax:revert(Tree),
    Type = erl_syntax:type(RevT),
    ok.

t_abstract_type(Config) when is_list(Config) ->
    F = fun validate_abstract_type/1,
    ok = validate(F,[{hi,atom},
		     {1,integer},
		     {1.0,float},
		     {$a,integer},
		     {[],nil},
		     {[<<1,2>>,a,b],list},
		     {[2,3,<<1,2>>,a,b],list},
		     {[$a,$b,$c],string},
		     {"hello world",string},
		     {<<1,2,3>>,binary},
                     {<<1,2,3:4>>,binary},
		     {#{a=>1,"b"=>2},map_expr},
		     {#{#{i=>1}=>1,"b"=>#{v=>2}},map_expr},
		     {{a,b,c},tuple}]),
    ok.

t_erl_parse_type(Config) when is_list(Config) ->
    F = fun validate_erl_parse_type/1,
    %% leaf types
    ok = validate(F,[{"1",integer,true},
		     {"123456789",integer,true},
		     {"$h", char,true},
		     {"3.1415", float,true},
		     {"1.33e36", float,true},
		     {"\"1.33e36: hello\"", string,true},
		     {"Var1", variable,true},
		     {"_", underscore,true},
		     {"[]", nil,true},
		     {"{}", tuple,true},
		     {"#{}",map_expr,true},
		     {"'some atom'", atom, true}]),
    %% composite types
    ok = validate(F,[{"case X of t -> t; f -> f end", case_expr,false},
		     {"try X of t -> t catch C:R -> error end", try_expr,false},
		     {"receive X -> X end", receive_expr,false},
		     {"receive M -> X1 after T -> X2 end", receive_expr,false},
		     {"catch (X)", catch_expr,false},
		     {"fun(X) -> X end", fun_expr,false},
		     {"fun Foo(X) -> X end", named_fun_expr,false},
		     {"fun foo/2", implicit_fun,false},
		     {"fun bar:foo/2", implicit_fun,false},
		     {"if X -> t; true -> f end", if_expr,false},
		     {"<<1,2,3,4>>", binary,false},
		     {"<<1,2,3,4:5>>", binary,false},
		     {"<<V1:63,V2:22/binary, V3/bits>>", binary,false},
		     {"begin X end", block_expr,false},
		     {"foo(X1,X2)", application,false},
		     {"bar:foo(X1,X2)", application,false},
		     {"[1,2,3,4]", list,false},
		     {"[1|4]", list, false},
		     {"[<<1>>,<<2>>,-2,<<>>,[more,list]]", list,false},
		     {"[1|[2|[3|[4|[]]]]]", list,false},
		     {"#{ a=>1, b=>2 }", map_expr,false},
		     {"#{3=>3}#{ a=>1, b=>2 }", map_expr,false},
		     {"#{ a:=1, b:=2 }", map_expr,false},
		     {"M#{ a=>1, b=>2 }", map_expr,false},
		     {"[V||V <- Vs]", list_comp,false},
		     {"[V||V <:- Vs]", list_comp,false},
		     {"[catch V||V <- Vs]", list_comp,false},
		     {"<< <<B>> || <<B>> <= Bs>>", binary_comp,false},
		     {"<< <<B>> || <<B>> <:= Bs>>", binary_comp,false},
		     {"<< (catch <<B>>) || <<B>> <= Bs>>", binary_comp,false},
		     {"#{K => V || {K,V} <- KVs}", map_comp,false},
		     {"#{K => V || {K,V} <:- KVs}", map_comp,false},
		     {"#{K => (catch V) || {K,V} <- KVs}", map_comp,false},
                     {"[V+W||V <- Vs && W <- Ws]", list_comp,false},
                     {"[catch V+W||V <- Vs && W <- Ws]", list_comp,false},
                     {"<< <<B>> || <<B>> <= Bs>>", binary_comp,false},
                     {"<< (catch <<B>>) || <<B>> <= Bs>>", binary_comp,false},
                     {"<< <<B:8,C:8>> || <<B>> <= Bs && <<C>> <= Cs>>", binary_comp,false},
		     {"<< (catch <<B:8,C:8>>) || <<B>> <= Bs && <<C>> <= Cs>>", binary_comp,false},
		     {"#state{ a = A, b = B}", record_expr,false},
		     {"#state{}", record_expr,false},
		     {"#s{ a = #def{ a=A }, b = B}", record_expr,false},
		     {"State#state{ a = A, b = B}", record_expr,false},
		     {"State#state.a", record_access,false},
		     {"#state.a", record_index_expr,false},
		     {"-X", prefix_expr,false},
		     {"X1 + X2", infix_expr,false},
		     {"(X1 + X2) * X3", infix_expr,false},
		     {"X1 = X2", match_expr,false},
		     {"{a,b,c}", tuple,false}]),
    ok.

%% the macro ?MODULE seems faulty
t_epp_dodger(Config) when is_list(Config) ->
    DataDir   = ?config(data_dir, Config),
    PrivDir   = ?config(priv_dir, Config),
    Filenames = test_files(),
    ok = test_epp_dodger(Filenames,DataDir,PrivDir),
    ok.

t_epp_dodger_clever(Config) when is_list(Config) ->
    DataDir   = ?config(data_dir, Config),
    PrivDir   = ?config(priv_dir, Config),
    Filenames = ["epp_dodger_clever.erl"],
    ok = test_epp_dodger_clever(Filenames,DataDir,PrivDir),
    ok.

t_comment_scan(Config) when is_list(Config) ->
    DataDir   = ?config(data_dir, Config),
    Filenames = test_files(),
    ok = test_comment_scan(Filenames,DataDir),
    ok.

t_prettypr(Config) when is_list(Config) ->
    DataDir   = ?config(data_dir, Config),
    PrivDir   = ?config(priv_dir, Config),
    Filenames = test_files(),
    ok = test_prettypr(Filenames,DataDir,PrivDir),
    ok.

%% Test bug (#4733) fix for annotating bindings for named fun expressions
test_named_fun_bind_ann(Config) when is_list(Config) ->
    Fn = {named_fun,{6,5},
            'F',
            [{clause,{6,9},
                [{var,{6,11},'Test'}],
                [],
                [{var,{7,13},'Test'}]}]},
    AnnT = erl_syntax_lib:annotate_bindings(Fn, []),
    [Env, Bound, Free] = erl_syntax:get_ann(AnnT),
    {'env',[]} = Env,
    {'bound',[]} = Bound,
    {'free',[]} = Free,

    NameVar = erl_syntax:named_fun_expr_name(AnnT),
    Name = erl_syntax:variable_name(NameVar),
    [NEnv, NBound, NFree] = erl_syntax:get_ann(NameVar),
    {'env',[]} = NEnv,
    {'bound',[Name]} = NBound,
    {'free',[]} = NFree,

    [Clause] = erl_syntax:named_fun_expr_clauses(AnnT),
    [CEnv, CBound, CFree] = erl_syntax:get_ann(Clause),
    {'env',[Name]} = CEnv,
    {'bound',['Test']} = CBound,
    {'free', []} = CFree.

%% Test annotation of maybe_expr, maybe_match_expr and else_expr (PR #8811)
test_maybe_expr_ann(Config) when is_list(Config) ->
    %% maybe
    %%  ok ?= Test,
    %%  What ?= ok,
    %%  Var = What,
    %% else
    %%  Error -> Error
    %% end.
    MaybeMatch1 = erl_syntax:maybe_match_expr(
                    erl_syntax:atom(ok),
                    erl_syntax:variable('Test')),
    MaybeMatch2 = erl_syntax:maybe_match_expr(
                    erl_syntax:variable('What'),
                    erl_syntax:atom(ok)),
    Match1 = erl_syntax:maybe_match_expr(
                    erl_syntax:variable('Var'),
                    erl_syntax:variable('What')),
    Else = erl_syntax:else_expr(
             [erl_syntax:clause(
                [erl_syntax:variable('Err')],
                'none',
               [erl_syntax:variable('Err')])
             ]),
    Maybe = erl_syntax:maybe_expr([MaybeMatch1, MaybeMatch2, Match1], Else),

    MaybeAnn = erl_syntax_lib:annotate_bindings(Maybe, []),
    [Env, Bound, Free] = erl_syntax:get_ann(MaybeAnn),
    {'env',[]} = Env,
    {'bound',[]} = Bound,
    {'free',['Test']} = Free,

    [MaybeMatchAnn1, MaybeMatchAnn2, MatchAnn1] = erl_syntax:maybe_expr_body(MaybeAnn),
    [Env1, Bound1, Free1] = erl_syntax:get_ann(MaybeMatchAnn1),
    {'env',[]} = Env1,
    {'bound',[]} = Bound1,
    {'free',['Test']} = Free1,
    [Env2, Bound2, Free2] = erl_syntax:get_ann(MaybeMatchAnn2),
    {'env',[]} = Env2,
    {'bound',['What']} = Bound2,
    {'free',[]} = Free2,
    [Env3, Bound3, Free3] = erl_syntax:get_ann(MatchAnn1),
    {'env',['What']} = Env3,
    {'bound',['Var']} = Bound3,
    {'free',['What']} = Free3,

    ElseAnn = erl_syntax:maybe_expr_else(MaybeAnn),
    [Env4, Bound4, Free4] = erl_syntax:get_ann(ElseAnn),
    {'env',[]} = Env4,
    {'bound',[]} = Bound4,
    {'free',[]} = Free4,

    %% Test that it also works when there is no else clause
    MaybeNoElse = erl_syntax:maybe_expr([MaybeMatch1, MaybeMatch2, Match1]),
    MaybeNoElseAnn = erl_syntax_lib:annotate_bindings(MaybeNoElse, []),
    [Env, Bound, Free] = erl_syntax:get_ann(MaybeNoElseAnn),
    [MaybeMatchAnn1, MaybeMatchAnn2, MatchAnn1] = erl_syntax:maybe_expr_body(MaybeNoElseAnn),
    NoElseAnn = erl_syntax:maybe_expr_else(MaybeNoElseAnn),
    [] = erl_syntax:get_ann(NoElseAnn),

    ok.

test_files(Config) ->
    DataDir = ?config(data_dir, Config),
    [ filename:join(DataDir,Filename) || Filename <- test_files() ].

test_files() ->
    ["syntax_tools_SUITE_test_module.erl",
     "syntax_tools_test.erl",
     "type_specs.erl",
     "specs_and_funs.erl"].

test_comment_scan([],_) -> ok;
test_comment_scan([File|Files],DataDir) ->
    Filename  = filename:join(DataDir,File),
    {ok, Fs0} = epp:parse_file(Filename, [], []),
    Comments  = erl_comment_scan:file(Filename),
    Fun = fun(Node) ->
		  case erl_syntax:is_form(Node) of
		      true ->
			  C1    = erl_syntax:comment(2,[" This is a form."]),
			  Node1 = erl_syntax:add_precomments([C1],Node),
			  Node1;
		      false ->
			  Node
		  end
	  end,
    Fs1 = erl_recomment:recomment_forms(Fs0, Comments),
    Fs2 = erl_syntax_lib:map(Fun, Fs1),
    io:format("File: ~ts~n", [Filename]),
    io:put_chars(erl_prettypr:format(Fs2, [{paper,  120},
					   {ribbon, 110}])),
    test_comment_scan(Files,DataDir).


test_prettypr([],_,_) -> ok;
test_prettypr([File|Files],DataDir,PrivDir) ->
    Filename  = filename:join(DataDir,File),
    Options = [res_word_option()],
    io:format("Parsing ~p~n", [Filename]),
    {ok, Fs0} = epp:parse_file(Filename, Options),
    Fs = erl_syntax:form_list(Fs0),
    PP = erl_prettypr:format(Fs, [{paper,  120}, {ribbon, 110}]),
    io:put_chars(PP),
    OutFile = filename:join(PrivDir, File),
    ok = file:write_file(OutFile,unicode:characters_to_binary(PP)),
    io:format("Parsing OutFile: ~ts~n", [OutFile]),
    {ok, Fs2} = epp:parse_file(OutFile, Options),
    case [Error || {error, _} = Error <- Fs2] of
        [] ->
            ok;
        Errors ->
            ct:fail(Errors)
    end,
    test_prettypr(Files,DataDir,PrivDir).

test_epp_dodger([], _, _) -> ok;
test_epp_dodger([Filename|Files],DataDir,PrivDir) ->
    io:format("Parsing ~p~n", [Filename]),
    Options  = [{feature, maybe_expr, enable}],
    InFile   = filename:join(DataDir, Filename),
    Parsers  = [{fun(File) -> epp_dodger:parse_file(File, Options) end,parse_file},
		{fun(File) -> epp_dodger:quick_parse_file(File,
                                                          Options) end,quick_parse_file},
		{fun (File) ->
			{ok,Dev} = file:open(File,[read]),
			Res = epp_dodger:parse(Dev, Options),
			file:close(File),
			Res
		 end, parse},
		{fun (File) ->
			{ok,Dev} = file:open(File,[read]),
			Res = epp_dodger:quick_parse(Dev, Options),
			file:close(File),
			Res
		 end, quick_parse}],
    FsForms  = parse_with(Parsers, InFile),
    ok = pretty_print_parse_forms(FsForms,PrivDir,Filename),
    test_epp_dodger(Files,DataDir,PrivDir).

test_epp_dodger_clever([], _, _) -> ok;
test_epp_dodger_clever([Filename|Files],DataDir,PrivDir) ->
    io:format("Parsing ~p~n", [Filename]),
    InFile   = filename:join(DataDir, Filename),
    Parsers  = [{fun(File) ->
                         epp_dodger:parse_file(File, [clever])
                 end, parse_file},
		{fun(File) ->
                         epp_dodger:quick_parse_file(File, [clever])
                 end, quick_parse_file}],
    FsForms  = parse_with(Parsers, InFile),
    ok = pretty_print_parse_forms(FsForms,PrivDir,Filename),
    test_epp_dodger_clever(Files,DataDir,PrivDir).

parse_with([],_) -> [];
parse_with([{Fun,ParserType}|Funs],File) ->
    {ok, Fs} = Fun(File),
    ErrorMarkers = [begin
                        print_error_markers(F, File),
                        F
                    end
                    || F <- Fs,
                       erl_syntax:type(F) =:= error_marker],
    [] = ErrorMarkers,
    [{Fs,ParserType}|parse_with(Funs,File)].

pretty_print_parse_forms([],_,_) -> ok;
pretty_print_parse_forms([{Fs0,Type}|FsForms],PrivDir,Filename) ->
    Parser  = atom_to_list(Type),
    OutFile = filename:join(PrivDir, Parser ++"_" ++ Filename),
    io:format("Pretty print ~p (~w) to ~p~n", [Filename,Type,OutFile]),
    Comment = fun (Node,{CntCase,CntTry}=Cnt) ->
		      case erl_syntax:type(Node) of
			  case_expr ->
			      C1    = erl_syntax:comment(2,["Before a case expression"]),
			      Node1 = erl_syntax:add_precomments([C1],Node),
			      C2    = erl_syntax:comment(2,["After a case expression"]),
			      Node2 = erl_syntax:add_postcomments([C2],Node1),
			      {Node2,{CntCase+1,CntTry}};
			  try_expr ->
			      C1    = erl_syntax:comment(2,["Before a try expression"]),
			      Node1 = erl_syntax:set_precomments(Node,
						     erl_syntax:get_precomments(Node) ++ [C1]),
			      C2    = erl_syntax:comment(2,["After a try expression"]),
			      Node2 = erl_syntax:set_postcomments(Node1,
						     erl_syntax:get_postcomments(Node1) ++ [C2]),
			      {Node2,{CntCase,CntTry+1}};
			  _ ->
			      {Node,Cnt}
		      end
	      end,
    Fs1 = erl_syntax:form_list(Fs0),
    {Fs2,{CC,CT}} = erl_syntax_lib:mapfold(Comment,{0,0}, Fs1),
    io:format("Commented on ~w cases and ~w tries~n", [CC,CT]),
    PP  = erl_prettypr:format(Fs2),
    ok  = file:write_file(OutFile,unicode:characters_to_binary(PP)),
    pretty_print_parse_forms(FsForms,PrivDir,Filename).


validate(_,[]) -> ok;
validate(F,[V|Vs]) ->
    ok = F(V),
    validate(F,Vs).


validate_abstract_type({Lit,Type}) ->
    Tree = erl_syntax:abstract(Lit),
    ok   = validate_special_type(Type,Tree),
    Type = erl_syntax:type(Tree),
    true = erl_syntax:is_literal(Tree),
    ErlT = erl_syntax:revert(Tree),
    Type = erl_syntax:type(ErlT),
    ok   = validate_special_type(Type,ErlT),
    Conc = erl_syntax:concrete(Tree),
    Lit  = Conc,
    ok.

validate_erl_parse_type({String,Type,Leaf}) ->
    ErlT = string_to_expr(String),
    ok   = validate_special_type(Type,ErlT),
    Type = erl_syntax:type(ErlT),
    Leaf = erl_syntax:is_leaf(ErlT),
    Tree = erl_syntax_lib:map(fun(Node) -> Node end, ErlT),
    Type = erl_syntax:type(Tree),
    _    = erl_syntax:meta(Tree),
    ok   = validate_special_type(Type,Tree),
    RevT = erl_syntax:revert(Tree),
    ok   = validate_special_type(Type,RevT),
    Type = erl_syntax:type(RevT),
    ok.

validate_special_type(string,Node) ->
    Val  = erl_syntax:string_value(Node),
    true = erl_syntax:is_string(Node,Val),
    _    = erl_syntax:string_literal(Node),
    ok;
validate_special_type(variable,Node) ->
    _ = erl_syntax:variable_literal(Node),
    ok;
validate_special_type(fun_expr,Node) ->
    A = erl_syntax:fun_expr_arity(Node),
    true = is_integer(A),
    ok;
validate_special_type(named_fun_expr,Node) ->
    A = erl_syntax:named_fun_expr_arity(Node),
    true = is_integer(A),
    ok;
validate_special_type(tuple,Node) ->
    Size = erl_syntax:tuple_size(Node),
    true = is_integer(Size),
    ok;
validate_special_type(float,Node) ->
    Str   = erl_syntax:float_literal(Node),
    Val   = list_to_float(Str),
    Val   = erl_syntax:float_value(Node),
    false = erl_syntax:is_proper_list(Node),
    false = erl_syntax:is_list_skeleton(Node),
    ok;
validate_special_type(integer,Node) ->
    Str   = erl_syntax:integer_literal(Node),
    Val   = list_to_integer(Str),
    true  = erl_syntax:is_integer(Node,Val),
    Val   = erl_syntax:integer_value(Node),
    false = erl_syntax:is_proper_list(Node),
    ok;
validate_special_type(nil,Node) ->
    true  = erl_syntax:is_proper_list(Node),
    ok;
validate_special_type(list,Node) ->
    true  = erl_syntax:is_list_skeleton(Node),
    _     = erl_syntax:list_tail(Node),
    ErrV  = erl_syntax:list_head(Node),
    false = erl_syntax:is_string(Node,ErrV),
    Norm  = erl_syntax:normalize_list(Node),
    list  = erl_syntax:type(Norm),
    case erl_syntax:is_proper_list(Node) of
	true ->
	    true = erl_syntax:is_list_skeleton(Node),
	    Compact = erl_syntax:compact_list(Node),
	    list = erl_syntax:type(Compact),
	    [_|_] = erl_syntax:list_elements(Node),
	    _  = erl_syntax:list_elements(Node),
	    N  = erl_syntax:list_length(Node),
	    true = N > 0,
	    ok;
	false ->
	    ok
    end;
validate_special_type(_,_) ->
    ok.

%%% scan_and_parse

string_to_expr(String) ->
    io:format("Str: ~p~n", [String]),
    {ok, Ts, _} = erl_scan:string(String++"."),
    {ok,[Expr]} = erl_parse:parse_exprs(Ts),
    Expr.

string_to_type(String) ->
    io:format("Str: ~p~n", [String]),
    {ok,Ts,_} = erl_scan:string("-type foo() :: "++String++".", 0),
    {ok,Form} = erl_parse:parse_form(Ts),
    {attribute,_,type,{foo,Type,_NoParms=[]}} = Form,
    Type.


p_run(Test, List) ->
    N = erlang:system_info(schedulers),
    p_run_loop(Test, List, N, [], 0).

p_run_loop(_, [], _, [], Errors) ->
    Errors;
p_run_loop(Test, [H|T], N, Refs, Errors) when length(Refs) < N ->
    {_,Ref} = erlang:spawn_monitor(fun() -> exit(Test(H)) end),
    p_run_loop(Test, T, N, [Ref|Refs], Errors);
p_run_loop(Test, List, N, Refs0, Errors0) ->
    receive
	{'DOWN',Ref,process,_,Res} ->
	    Errors = case Res of
			 ok -> Errors0;
			 error -> Errors0+1
		     end,
	    Refs = Refs0 -- [Ref],
	    p_run_loop(Test, List, N, Refs, Errors)
    end.

res_word_option() ->
    Options = [{feature, maybe_expr, enable}],
    {ok, {_Ftrs, ResWordFun}} =
        erl_features:keyword_fun(Options, fun erl_scan:f_reserved_word/1),
    {reserved_word_fun, ResWordFun}.
