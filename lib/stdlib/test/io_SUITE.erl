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
-module(io_SUITE).

-export([all/0, suite/0]).

-export([error_1/1, float_g/1, float_w/1, otp_5403/1, otp_5813/1, otp_6230/1, 
         otp_6282/1, otp_6354/1, otp_6495/1, otp_6517/1, otp_6502/1,
         manpage/1, otp_6708/1, otp_7084/0, otp_7084/1, otp_7421/1,
	 io_lib_collect_line_3_wb/1, cr_whitespace_in_string/1,
	 io_fread_newlines/1, otp_8989/1, io_lib_fread_literal/1,
	 printable_range/1, bad_printable_range/1,
	 io_lib_print_binary_depth_one/1, otp_10302/1, otp_10755/1,
         otp_10836/1, io_lib_width_too_small/1, calling_self/1,
         io_with_huge_message_queue/1, format_string/1, format_neg_zero/1,
	 maps/1, coverage/1, otp_14178_unicode_atoms/1, otp_14175/1,
         otp_14285/1, limit_term/1, otp_14983/1, otp_15103/1, otp_15076/1,
         otp_15159/1, otp_15639/1, otp_15705/1, otp_15847/1, otp_15875/1,
         github_4801/1, chars_limit/1, error_info/1, otp_17525/1,
         unscan_format_without_maps_order/1, build_text_without_maps_order/1]).

-export([pretty/2, trf/3, rfd/2]).

%%-define(debug, true).

-ifdef(debug).
-define(format(S, A), io:format(S, A)).
-define(line, put(line, ?LINE), ).
-define(config(X,Y), foo).
-define(t, test_server).
-define(privdir(_), "./io_SUITE_priv").
-else.
-include_lib("common_test/include/ct.hrl").
-define(format(S, A), ok).
-define(privdir(Conf), proplists:get_value(priv_dir, Conf)).
-endif.

suite() ->
    [{ct_hooks,[ts_install_cth]},
     {timetrap,{minutes,1}}].

all() -> 
    [error_1, float_g, float_w, otp_5403, otp_5813, otp_6230,
     otp_6282, otp_6354, otp_6495, otp_6517, otp_6502,
     manpage, otp_6708, otp_7084, otp_7421,
     io_lib_collect_line_3_wb, cr_whitespace_in_string,
     io_fread_newlines, otp_8989, io_lib_fread_literal,
     printable_range, bad_printable_range, format_neg_zero,
     io_lib_print_binary_depth_one, otp_10302, otp_10755, otp_10836,
     io_lib_width_too_small, io_with_huge_message_queue, calling_self,
     format_string, maps, coverage, otp_14178_unicode_atoms, otp_14175,
     otp_14285, limit_term, otp_14983, otp_15103, otp_15076, otp_15159,
     otp_15639, otp_15705, otp_15847, otp_15875, github_4801, chars_limit,
     error_info, otp_17525, unscan_format_without_maps_order,
     build_text_without_maps_order].

%% Error cases for output.
error_1(Config) when is_list(Config) ->
    %% We don't do erroneous output on stdout - the test server
    %% seems to catch that somehow.
    PrivDir = ?privdir(Config),
    File = filename:join(PrivDir, "slask"),
    {ok, F1} = file:open(File, [write]),
    {'EXIT', _} = (catch io:format(muttru, "hej", [])),
    {'EXIT', _} = (catch io:format(F1, pelle, "hej")),
    {'EXIT', _} = (catch io:format(F1, 1, "hej")),
    {'EXIT', _} = (catch io:format(F1, "~p~", [kaka])),
    {'EXIT', _} = (catch io:format(F1, "~m~n", [kaka])),

    %% This causes the file process to die, and it is linked to us,
    %% so we can't catch the error this easily.
    %%    {'EXIT', _} = (catch io:put_chars(F1, 666)),

    file:close(F1),
    {'EXIT', _} = (catch io:format(F1, "~p", ["hej"])),
    ok.

format_neg_zero(Config) when is_list(Config) ->
    <<NegZero/float>> = <<16#8000000000000000:64>>,
    "-0.000000"   = fmt("~f", [NegZero]),
    "-0.00000e+0" = fmt("~g", [NegZero]),
    "-0.00000e+0" = fmt("~e", [NegZero]),
    "-0.0" = io_lib_format:fwrite_g(NegZero),
    ok.

float_g(Config) when is_list(Config) ->
    ["5.00000e-2",
     "0.500000",
     "5.00000",
     "50.0000",
     "500.000",
     "5000.00",
     "5.00000e+4",
     "5.00000e+5"] = float_g_1("~g", 5.0, -2, 5),

    ["-5.0000e-2",
     "-0.50000",
     "-5.0000",
     "-50.000",
     "-500.00",
     "-5000.0",
     "-5.0000e+4",
     "-5.0000e+5"] = float_g_1("~.5g", -5.0, -2, 5),

    ["5.000e-2",
     "0.5000",
     "5.000",
     "50.00",
     "500.0",
     "5.000e+3",
     "5.000e+4",
     "5.000e+5"] = float_g_1("~.4g", 5.0, -2, 5),

    ["-5.00e-2",
     "-0.500",
     "-5.00",
     "-50.0",
     "-5.00e+2",
     "-5.00e+3",
     "-5.00e+4",
     "-5.00e+5"] = float_g_1("~.3g", -5.0, -2, 5),

    ["5.0e-2",
     "0.50",
     "5.0",
     "5.0e+1",
     "5.0e+2",
     "5.0e+3",
     "5.0e+4",
     "5.0e+5"] = float_g_1("~.2g", 5.0, -2, 5),

    case catch fmt("~.1g", [0.5]) of
	"0.5" ->
	    ["5.0e-2",
	     "0.5",
	     "5.0e+0",
	     "5.0e+1",
	     "5.0e+2",
	     "5.0e+3",
	     "5.0e+4",
	     "5.0e+5"] = float_g_1("~.1g", 5.0, -2, 5);
	{'EXIT',_} -> ok
    end,

    ["4.99999e-2",
     "0.499999",
     "4.99999",
     "49.9999",
     "499.999",
     "4999.99",
     "4.99999e+4",
     "4.99999e+5"] = float_g_1("~g", 4.9999949999, -2, 5),

    ["-5.00000e-2",
     "-0.500000",
     "-5.00000",
     "-50.0000",
     "-500.000",
     "-5000.00",
     "-5.00000e+4",
     "-5.00000e+5"] = float_g_1("~g", -4.9999950001, -2, 5),

    ok.

float_g_1(Fmt, V, Min, Max) ->
    [fmt(Fmt, [V*math:pow(10, E)]) || E <- lists:seq(Min, Max)].

float_w(Config) when is_list(Config) ->
    %% All floats that are >= float(1 bsl 53) or <= -float(1 bsl 53)
    %% should be printed with scientific notation to make it clear
    %% that the integer part can have lost precision, for example if
    %% the float was created from a float literal.
    %%
    %% All integers in the range [-2^53, 2^53] can be stored without
    %% loss of precision in an IEEE 754 64-bit double but 2^53+1
    %% cannot be stored in an IEEE 754 64-bit double without loss of
    %% precision (float((1 bsl 53)+1) =:= float(1 bsl 53)).
    %%
    %% https://stackoverflow.com/questions/1848700/biggest-integer-that-can-be-stored-in-a-double?answertab=votes#tab-top
    Nums = [-float((1 bsl 53) -1),
            -float(1 bsl 53),
            -float((1 bsl 53) + 1),
            float((1 bsl 53) -1),
            float(1 bsl 53),
            float((1 bsl 53) + 1)],


    ["-9007199254740991.0",
     "-9.007199254740992e15",
     "-9.007199254740992e15",
     "9007199254740991.0",
     "9.007199254740992e15",
     "9.007199254740992e15"] =
        [begin g_t(X), fmt("~w", [X]) end || X <- Nums],

    ok.

calling_self(Config) when is_list(Config) ->
    {'EXIT', {calling_self, _}} = (catch io:format(self(), "~p", [oops])),
    ok.

%% OTP-5403. ~s formats I/O lists and a single binary.
otp_5403(Config) when is_list(Config) ->
    "atom" = fmt("~s", [atom]),
    "binary" = fmt("~s", [<<"binary">>]),
    "atail" = fmt("~s", [["a" | <<"tail">>]]),
    "deepcharlist" = fmt("~s", [["deep",["char",["list"]]]]),
    "somebinaries" = fmt("~s", [[<<"some">>,[<<"binaries">>]]]),
    ok.

%% OTP-5813. read/3 is new.
otp_5813(Config) when is_list(Config) ->
    PrivDir = ?privdir(Config),
    File = filename:join(PrivDir, "test"),

    ok = file:write_file(File, <<"a. ">>),
    {ok, Fd} = file:open(File, [read]),
    {ok, a, 1} = io:read(Fd, '', 1),
    {eof,1} = io:read(Fd, '', 1),
    ok = file:close(Fd),

    ok = file:write_file(File, <<"[}.">>),
    {ok, Fd2} = file:open(File, [read]),
    {error,{1,_,_},1} = io:read(Fd2, '', 1),
    ok = file:close(Fd),

    file:delete(File),
    ok.

%% OTP-6230. ~p and ~P with (huge) binaries.
otp_6230(Config) when is_list(Config) ->
    %% The problem is actually huge binaries, but the small tests here
    %% just run through most of the modified code.
    "<<>>" = fmt("~P", [<<"">>,-1]),
    "<<\"hej\">>" = fmt("~P", [<<"hej">>,-1]),
    "{hej,...}" = fmt("~P", [{hej,<<"hej">>},2]),
    "{hej,<<...>>}" = fmt("~P", [{hej,<<"hej">>},3]),
    "{hej,<<\"hejs\"...>>}" = fmt("~P", [{hej,<<"hejsan">>},4]),
    "{hej,<<\"hej\">>}" = fmt("~P", [{hej,<<"hej">>},6]),
    "<<...>>" = fmt("~P", [<<"hej">>,1]),
    "<<\"hejs\"...>>" = fmt("~P", [<<"hejsan">>,2]),
    "<<\"hej\">>" = fmt("~P", [<<"hej">>,4]),
    "{hej,<<127,...>>}" =
        fmt("~P", [{hej,<<127:8,<<"hej">>/binary>>},4]),
    "{hej,<<127,104,101,...>>}" =
        fmt("~P", [{hej,<<127:8,<<"hej">>/binary>>},6]),

    B = list_to_binary(lists:duplicate(30000, $a)),
    "<<\"aaaa"++_ = fmt("~P", [B, 20000]),
    ok.

%% OTP-6282. ~p truncates strings (like binaries) depending on depth.
otp_6282(Config) when is_list(Config) ->
    "[]" = p("", 1, 20, 1),
    "[]" = p("", 1, 20, -1),
    "[...]" = p("a", 1, 20, 1),
    "\"a\"" = p("a", 1, 20, 2),
    "\"aa\"" = p("aa", 1, 20, 2),
    "\"aaa\"" = p("aaa", 1, 20, 2),
    "\"aaaa\"" = p("aaaa", 1, 20, 2),
    "\"a\"" = p("a", 1, 20, -1),
    "[97,97,1000]" = p([$a,$a,1000], 1, 20, 4),
    S1 = lists:duplicate(200,$a),
    "[...]" = p(S1, 1, 20, 1),
    true = "\"" ++ S1 ++ "\"" =:= p(S1, 1, 205, -1),
    "[97,97,1000|...]" = p([$a,$a,1000,1000], 1, 20, 4),

    "[[]]" = p([""], 1, 20, 2),
    "[[]]" = p([""], 1, 20, -1),
    "[[...]]" = p(["a"], 1, 20, 2),
    "[\"a\"]" = p(["a"], 1, 20, 3),
    "[\"aa\"]" = p(["aa"], 1, 20, 3),
    "[\"aaa\"]" = p(["aaa"], 1, 20, 3),
    "[\"a\"]" = p(["a"], 1, 20, -1),
    "[[97,97,1000]]" = p([[$a,$a,1000]], 1, 20, 5),
    "[[...]]" = p([S1], 1, 20, 2),
    true = "[\"" ++ S1 ++ "\"]" =:= p([S1], 1, 210, -1),
    "[[97,97,1000|...]]" = p([[$a,$a,1000,1000]], 1, 20, 5),

    "[\"aaaaa\"]" = p(["aaaaa"], 1, 10, 6),

    ok.

%% OTP-6354. io_lib_pretty rewritten.
otp_6354(Config) when is_list(Config) ->
    %% A few tuples:
    "{}" = p({}, 1, 20, -1),
    "..." = p({}, 1, 20, 0),
    "{}" = p({}, 1, 20, 1),
    "{}" = p({}, 1, 20, 2),
    "{a}" = p({a}, 1, 20, -1),
    "..." = p({a}, 1, 20, 0),
    "{...}" = p({a}, 1, 20, 1),
    "{a}" = p({a}, 1, 20, 2),
    "{a,b}" = p({a,b}, 1, 20, -1),
    "..." = p({a,b}, 1, 20, 0),
    "{...}" = p({a,b}, 1, 20, 1),
    "{a,...}" = p({a,b}, 1, 20, 2),
    "{a,b}" = p({a,b}, 1, 20, 3),
    "{}" = p({}, 1, 1, -1),
    "..." = p({}, 1, 1, 0),
    "{}" = p({}, 1, 1, 1),
    "{}" = p({}, 1, 1, 2),
    "{a}" = p({a}, 1, 1, -1),
    "..." = p({a}, 1, 1, 0),
    "{...}" = p({a}, 1, 1, 1),
    "{a}" = p({a}, 1, 1, 2),
    "{a,\n b}" = p({a,b}, 1, 1, -1),
    "{1,\n b}" = p({1,b}, 1, 1, -1),
    "..." = p({a,b}, 1, 1, 0),
    "{...}" = p({a,b}, 1, 1, 1),
    "{a,...}" = p({a,b}, 1, 1, 2),
    "{a,\n b}" = p({a,b}, 1, 1, 3),
    "{{}}" = p({{}}, 1, 1, 2),
    "{[]}" = p({[]}, 1, 1, 2),
    bt(<<"{1,2,a,b,{sfdsf,sdfdsfs},[sfsdf,sdfsdf]}">>,
       p({1,2,a,b,{sfdsf,sdfdsfs},[sfsdf,sdfsdf]}, -1)),
    bt(<<"{abcd,ddddd,\n      ddddd}">>,
       p({abcd,ddddd,ddddd}, 1,16, -1)),
    bt(<<"{1,2,a,b,\n {sfdsf,sdfdsfs},\n [sfsdf,sdfsdf]}">>,
       p({1,2,a,b,{sfdsf,sdfdsfs},[sfsdf,sdfsdf]}, 1, 35, 100)),
    "{1,{1,{2,3}}}" = p({1,{1,{2,3}}}, 1, 80, 100),

    bt(<<"{wwwww,{wwwww,{wwwww,{wwwww,{wwwww,lkjsldfj,klsdjfjklds,\n"
	 "                                   sdkfjdsl,sdakfjdsklj,sdkljfsdj}}}}}">>,
       p({wwwww,{wwwww,{wwwww,{wwwww,{wwwww,lkjsldfj,klsdjfjklds,
				      sdkfjdsl,sdakfjdsklj,sdkljfsdj}}}}}, -1)),

    bt(<<"{wwwww,\n"
	 "    {wwwww,\n"
	 "        {wwwww,\n"
	 "            {wwwww,\n"
	 "                {wwwww,\n"
	 "                    {lkjsldfj,\n"
	 "                        {klsdjfjklds,\n"
	 "                            {klajsljls,\n"
	 "                                #aaaaaaaaaaaaaaaaaaaaa"
	 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaa{}}}}}}}}}">>,
       p({wwwww,{wwwww,{wwwww,{wwwww,{wwwww,{lkjsldfj,
					     {klsdjfjklds,{klajsljls,
							   {aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa}}}}}}}}},
	 -1)),
    "{{...},...}" = p({{a,b},{a,b,c},{d,e,f}},1,8,2),
    %% Closing brackets and parentheses count:
    "{{a,b,c},\n {{1,2,\n   3}}}" = p({{a,b,c},{{1,2,3}}},1,11,-1),
    %% With line breaks:
    "{{a,b,c},\n [1,2,\n  3]}" = p({{a,b,c},[1,2,3]},1,10,-1),
    %% With line breaks:
    "[{{a,b,c},\n  {1,2,\n   3}}]" = p([{{a,b,c},{1,2,3}}],1,12,-1),

    %% A few lists:
    "[]" = p([], 1, 20, -1),
    "..." = p([], 1, 20, 0),
    "[]" = p([], 1, 20, 1),
    "[]" = p([], 1, 20, 2),
    "[a]" = p([a], 1, 20, -1),
    "..." = p([a], 1, 20, 0),
    "[...]" = p([a], 1, 20, 1),
    "[a]" = p([a], 1, 20, 2),
    "[a,b]" = p([a,b], 1, 20, -1),
    "..." = p([a,b], 1, 20, 0),
    "[...]" = p([a,b], 1, 20, 1),
    "[a|...]" = p([a,b], 1, 20, 2),
    "[a,b]" = p([a,b], 1, 20, 3),
    "[a|b]" = p([a|b], 1, 20, -1),
    "..." = p([a|b], 1, 20, 0),
    "[...]" = p([a|b], 1, 20, 1),
    "[a|...]" = p([a|b], 1, 20, 2),
    "[a|b]" = p([a|b], 1, 20, 3),
    "[]" = p([], 1, 1, -1),
    "..." = p([], 1, 1, 0),
    "[]" = p([], 1, 1, 1),
    "[]" = p([], 1, 1, 2),
    "[a]" = p([a], 1, 1, -1),
    "..." = p([a], 1, 1, 0),
    "[...]" = p([a], 1, 1, 1),
    "[a]" = p([a], 1, 1, 2),
    "[a,\n b]" = p([a,b], 1, 1, -1),
    "..." = p([a,b], 1, 1, 0),
    "[...]" = p([a,b], 1, 1, 1),
    "[a|...]" = p([a,b], 1, 1, 2),
    "[a,\n b]" = p([a,b], 1, 1, 3),
    "[a|\n b]" = p([a|b], 1, 1, -1),
    "..." = p([a|b], 1, 1, 0),
    "[...]" = p([a|b], 1, 1, 1),
    "[a|...]" = p([a|b], 1, 1, 2),
    "[a|\n b]" = p([a|b], 1, 1, 3),
    "[{}]" = p([{}], 1, 1, 2),
    "[[]]" = p([[]], 1, 1, 2),
    bt(<<"[1,2,a,b,{sfdsf,sdfdsfs},[sfsdf,sdfsdf]]">>,
       p([1,2,a,b,{sfdsf,sdfdsfs},[sfsdf,sdfsdf]], -1)),
    bt(<<"[1,2,a,b,\n {sfdsf,sdfdsfs},\n [sfsdf,sdfsdf]]">>,
       p([1,2,a,b,{sfdsf,sdfdsfs},[sfsdf,sdfsdf]], 1, 35, 100)),
    %% Element #8 is not printable:
    "[49," ++ _ = p("1234567"++[3,4,5,6,7], 1, 100, 9),
    %% "\"1234567\"..." = p("1234567"++[3,4,5,6,7], 1, 100, 8),

    %% A few records:
    %% -record(a, {}).
    %% -record(a, {}).
    "..." = p({a}, 0),
    "{...}" = p({a}, 1),
    "#a{}" = p({a}, 2),
    "#a{}" = p({a}, -1),
    %% -record(b, {f}).
    "{...}" = p({b}, 1),
    "..." = p({b,c}, 0),
    "{...}" = p({b,c}, 1),
    "#b{...}" = p({b,c}, 2),
    "#b{f = c}" = p({b,c}, 3),
    "#b{f = c}" = p({b,c}, -1),
    "..." = p({b,{c,d}}, 0),
    "{...}" = p({b,{c,d}}, 1),
    "#b{...}" = p({b,{c,d}}, 2),
    "#b{f = {...}}" = p({b,{c,d}}, 3),
    "#b{f = {c,...}}" = p({b,{c,d}}, 4),
    "#b{f = {c,d}}" = p({b,{c,d}}, 5),
    "#b{f = {...}}" = p({b,{b,c}}, 3),
    "#b{f = #b{...}}" = p({b,{b,c}}, 4),
    "#b{f = #b{f = c}}" = p({b,{b,c}}, 5),
    %% -record(c, {f1, f2}).
    "#c{f1 = d,f2 = e}" = p({c,d,e}, -1),
    "..." = p({c,d,e}, 0),
    "{...}" = p({c,d,e}, 1),
    "#c{...}" = p({c,d,e}, 2),
    "#c{f1 = d,...}" = p({c,d,e}, 3),
    "#c{f1 = d,f2 = e}" = p({c,d,e}, 4),
    %% -record(d, {a..., b..., c.., d...}).
    bt(<<"#d{aaaaaaaaaaaaaaaaaaaa = 1,bbbbbbbbbbbbbbbbbbbb = 2,\n"
	 "   cccccccccccccccccccc = 3,dddddddddddddddddddd = 4,\n"
	 "   eeeeeeeeeeeeeeeeeeee = 5}">>,
       p({d,1,2,3,4,5}, -1)),
    "..." = p({d,1,2,3,4,5}, 0),
    "{...}" = p({d,1,2,3,4,5}, 1),
    "#d{...}" = p({d,1,2,3,4,5}, 2),
    "#d{aaaaaaaaaaaaaaaaaaaa = 1,...}" = p({d,1,2,3,4,5}, 3),
    bt(<<"#d{aaaaaaaaaaaaaaaaaaaa = 1,bbbbbbbbbbbbbbbbbbbb = 2,...}">>,
       p({d,1,2,3,4,5}, 4)),
    bt(<<"#d{aaaaaaaaaaaaaaaaaaaa = 1,bbbbbbbbbbbbbbbbbbbb = 2,\n"
	 "   cccccccccccccccccccc = 3,...}">>,
       p({d,1,2,3,4,5}, 5)), % longer than 80 characters...
    bt(<<"#d{aaaaaaaaaaaaaaaaaaaa = 1,bbbbbbbbbbbbbbbbbbbb = 2,\n"
	 "   cccccccccccccccccccc = 3,dddddddddddddddddddd = 4,...}">>,
       p({d,1,2,3,4,5}, 6)),
    bt(<<"#d{aaaaaaaaaaaaaaaaaaaa = 1,bbbbbbbbbbbbbbbbbbbb = 2,\n"
	 "   cccccccccccccccccccc = 3,dddddddddddddddddddd = 4,\n"
	 "   eeeeeeeeeeeeeeeeeeee = 5}">>,
       p({d,1,2,3,4,5}, 7)),
    bt(<<"#rrrrr{\n"
	 "    f1 = 1,\n"
	 "    f2 = #rrrrr{f1 = a,f2 = b,f3 = c},\n"
	 "    f3 =\n"
	 "        #rrrrr{\n"
	 "            f1 = h,f2 = i,\n"
	 "            f3 =\n"
	 "                #rrrrr{\n"
	 "                    f1 = aa,\n"
	 "                    f2 =\n"
	 "                        #rrrrr{\n"
	 "                            f1 = #rrrrr{f1 = a,f2 = b,f3 = c},\n"
	 "                            f2 = 2,f3 = 3},\n"
	 "                    f3 = bb}}}">>,
       p({rrrrr,1,{rrrrr,a,b,c},{rrrrr,h,i,
				 {rrrrr,aa,{rrrrr,{rrrrr,a,b,c},
					    2,3},bb}}},
	 -1)),
    bt(<<"#d{aaaaaaaaaaaaaaaaaaaa = 1,\n"
	 "   bbbbbbbbbbbbbbbbbbbb =\n"
	 "       #d{aaaaaaaaaaaaaaaaaaaa = a,bbbbbbbbbbbbbbbbbbbb = b,\n"
	 "          cccccccccccccccccccc = c,dddddddddddddddddddd = d,\n"
	 "          eeeeeeeeeeeeeeeeeeee = e},\n"
	 "   cccccccccccccccccccc = 3,\n"
	 "   dddddddddddddddddddd =\n"
	 "       #d{aaaaaaaaaaaaaaaaaaaa = h,bbbbbbbbbbbbbbbbbbbb = i,\n"
	 "          cccccccccccccccccccc =\n"
	 "              #d{aaaaaaaaaaaaaaaaaaaa = aa,"
	 "bbbbbbbbbbbbbbbbbbbb = bb,\n"
	 "                 cccccccccccccccccccc =\n"
	 "                     #d{aaaaaaaaaaaaaaaaaaaa = 1,"
	 "bbbbbbbbbbbbbbbbbbbb = 2,\n"
	 "                        cccccccccccccccccccc = 3,"
	 "dddddddddddddddddddd = 4,\n"
	 "                        eeeeeeeeeeeeeeeeeeee = 5},\n"
	 "                 dddddddddddddddddddd = dd,"
	 "eeeeeeeeeeeeeeeeeeee = ee},\n"
	 "          dddddddddddddddddddd = k,"
	 "eeeeeeeeeeeeeeeeeeee = l},\n"
	 "   eeeeeeeeeeeeeeeeeeee = 5}">>,
       p({d,1,{d,a,b,c,d,e},3,{d,h,i,{d,aa,bb,{d,1,2,3,4,5},dd,ee},
			       k,l},5}, -1)),

    A = aaaaaaaaaaaaa,
    %% Print the record with dots at the end of the line (Ll = 80).
    "{aaaaaaa" ++ _ =
	p({A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,
								       {A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,
																 {A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,
																							   {A,{A,{ggg,{hhh,{ii,{jj,{kk,{ll,{mm,{nn,{oo,{d,1,2,3,4,5}
																												   }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
						       }}}}}}}}}}}}}}}}, 146),
    "{aaaaaaa" ++ _ =
	p({A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,
								       {A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,
																 {A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{A,
																							   {A,{A,{A,{A,{A,{ggg,{hhh,{ii,{jj,{kk,{ll,{mm,{nn,{oo,{a}
																													    }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
								}}}}}}}}}}}}}}}}}}}, 152),

    bt(<<"{aaaaaaaaaaaaa,\n"
	 "    {aaaaaaaaaaaaa,\n"
	 "        {aaaaaaaaaaaaa,\n"
	 "            {aaaaaaaaaaaaa,\n"
	 "                {aaaaaaaaaaaaa,\n"
	 "                    {aaaaaaaaaaaaa,\n"
	 "                        {g,{h,{i,{j,{k,{l,{m,{n,{o,#"
	 "d{...}}}}}}}}}}}}}}}}">>,
       p({A,{A,{A,{A,{A,{A,
			 {g,{h,{i,{j,{k,{l,{m,{n,{o,{d,1,2,3,4,5}}}}}}}}}}}}}}}}, 32)),
    bt(<<"{a,#b{f = {c,{d,{e,{f,...}}}}}}">>,
       p({a,{b,{c,{d,{e,{f,g}}}}}}, 12)),
    bt(<<"{aaaaaaaaaaaaa,\n"
	 "    {aaaaaaaaaaaaa,\n"
	 "        {aaaaaaaaaaaaa,\n"
	 "            {aaaaaaaaaaaaa,\n"
	 "                {aaaaaaaaaaaaa,\n"
	 "                    {aaaaaaaaaaaaa,\n"
	 "                        {aaaaaaaaaaaaa,\n"
	 "                            {aaaaaaaaaaaaa,\n"
	 "                                {aaaaaaaaaaaaa,#c{f1 = ddd,"
	 "f2 = eee}}}}}}}}}}">>,
       p({A,{A,{A,{A,{A,{A,{A,{A,{A,{c,ddd,eee}}}}}}}}}}, 100)),
    bt(<<"{aaaaaaaaaaaaa,\n"
	 "    {aaaaaaaaaaaaa,{aaaaaaaaaaaaa,{aaaaaaaaaaaaa,...}}}}">>,
       p({A,{A,{A,{A,{b}}}}}, 8)),
    bt(<<"{aaaaaaaaaaaaa,\n"
	 "    {aaaaaaaaaaaaa,\n"
	 "        {aaaaaaaaaaaaa,{aaaaaaaaaaaaa,{aaaaaaaaaaaaa,...}}}}}">>,
       p({A,{A,{A,{A,{A,{b}}}}}}, 10)),
    bt(<<"{aaaaaaaaaaaaa,\n"
	 "    {aaaaaaaaaaaaa,\n"
	 "        {aaaaaaaaaaaaa,\n"
	 "            {aaaaaaaaaaaaa,\n"
	 "                {aaaaaaaaaaaaa,\n"
	 "                    {aaaaaaaaaaaaa,\n"
	 "                        {aaaaaaaaaaaaa,\n"
	 "                            {aaaaaaaaaaaaa,\n"
	 "                                {aaaaaaaaaaaaa,"
	 "{aaaaaaaaaaaaa,#a{}}}}}}}}}}}">>,
       p({A,{A,{A,{A,{A,{A,{A,{A,{A,{A,{a}}}}}}}}}}}, 23)),
    bt(<<"{aaaaaaaaaaaaa,\n"
	 "    {aaaaaaaaaaaaa,\n"
	 "        {aaaaaaaaaaaaa,\n",
	 "            #rrrrr{\n"
	 "                f1 = kljlkjlksfdgkljlsdkjf,"
	 "f2 = kljkljsdaflkjlkjsdf,...}}}}">>,
       p({A,{A,{A,{rrrrr, kljlkjlksfdgkljlsdkjf,
		   kljkljsdaflkjlkjsdf,
		   asdfkldsjfklkljsdklfds}}}}, 10)),
    bt(<<"{aaaaaaaaaaaaa,\n"
	 "    {aaaaaaaaaaaaa,\n"
	 "        {aaaaaaaaaaaaa,\n"
	 "            {aaaaaaaaaaaaa,\n"
	 "                {aaaaaaaaaaaaa,\n"
	 "                    {aaaaaaaaaaaaa,\n"
	 "                        {aaaaaaaaaaaaa,\n"
	 "                            {g,{h,{i,{j,{k,{l,{m,{n,"
	 "{o,#a{}}}}}}}}}}}}}}}}}">>,
       p({A,{A,{A,{A,{A,{A,{A,
			    {g,{h,{i,{j,{k,{l,{m,{n,{o,{a}}}}}}}}}}}}}}}}}, 100)),
    bt(<<"#c{\n"
	 " f1 =\n"
	 "  #c{\n"
	 "   f1 =\n"
	 "    #c{\n"
	 "     f1 =\n"
	 "      #c{\n"
	 "       f1 =\n"
	 "        #c{\n"
	 "         f1 =\n"
	 "          #c{\n"
	 "           f1 =\n"
	 "            #c{\n"
	 "             f1 =\n"
	 "              #c{\n"
	 "               f1 =\n"
	 "                #c{\n"
	 "                 f1 = #c{f1 = #c{f1 = #c{f1 = a,"
	 "f2 = b},f2 = b},f2 = b},\n"
	 "                 f2 = b},\n"
	 "               f2 = b},\n"
	 "             f2 = b},\n"
	 "           f2 = b},\n"
	 "         f2 = b},\n"
	 "       f2 = b},\n"
	 "     f2 = b},\n"
	 "   f2 = b},\n"
	 " f2 = b}">>,
       p({c,{c,{c,{c,{c,{c,{c,{c,{c,{c,{c,{c,a,b},b},b},b},b},b},
			 b},b},b},b},b},b}, -1)),
    bt(<<"#rrrrr{\n"
	 " f1 =\n"
	 "  #rrrrr{\n"
	 "   f1 =\n"
	 "    #rrrrr{\n"
	 "     f1 =\n"
	 "      #rrrrr{\n"
	 "       f1 =\n"
	 "        {rrrrr,{rrrrr,a,#rrrrr{f1 = {rrrrr,1,2},f2 = a,"
	 "f3 = b}},b},\n"
	 "       f2 = {rrrrr,c,d},\n"
	 "       f3 = {rrrrr,1,2}},\n"
	 "     f2 = 1,f3 = 2},\n"
	 "   f2 = 3,f3 = 4},\n"
	 " f2 = 5,f3 = 6}">>,
       p({rrrrr,{rrrrr,{rrrrr,{rrrrr,{rrrrr,{rrrrr,a,{rrrrr,
						      {rrrrr,1,2},a,b}},b},{rrrrr,c,d},{rrrrr,1,2}},
			1,2},3,4},5,6}, -1)),
    "{aaa,\n {aaa," ++ _ =
        p({aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,
								       {aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,
															       {aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,
																						  {aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,{aaa,
																												{aaa,a}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}},
          1, 80, -1),

    %% A few other cases...
    "{a,#Fun<" ++ _ = lists:flatten(io_lib_pretty:print({a,fun fmt/2})),
    "#Fun<" ++ _ = io_lib_pretty:print(fun() -> foo end),
    %% No support for negative columns any more:
    "[a,\n [b,\n  c,\n  d,\n  [e,\n   f]],\n c]" =
	p([a,[b,c,d,[e,f]],c], -1, 2, 10),
    "[a,\n [b,\n  c,\n  d,\n  [e,\n   f]],\n c]" =
	p([a,[b,c,d,[e,f]],c], 0, 2, 10),
    %% 20 bytes are tried first, then the rest. Try 21 bytes:
    L = lists:duplicate(20, $a),
    %% bt(<<"<<\"aaaaaa\"\n  \"aaaaaa\"\n  \"aaaaaa\"\n  \"aaa\">>">>,
    bt(<<"<<\"aaaaaaaaaaaaaaaaaaaaa\">>">>,
       p(list_to_binary([$a | L]), 1, 10, -1)),
    "<<97," ++ _ = p(list_to_binary(L ++ [3]), 1, 10, -1),
    "<<97," ++ _ = p(list_to_binary(L ++ [3]), 1, 10, 22),

    "\"\\b\\t\\n\\v\\f\\r\\e\250\"" =
	p([8,9,10,11,12,13,27,168], 1, 40, -1),
    %% "\"\\b\\t\\n\"\n \"\\v\\f\\r\"\n \"\\e\250\"" =
    "\"\\b\\t\\n\\v\\f\\r\\e¨\"" =
	p([8,9,10,11,12,13,27,168], 1, 10, -1),
    "\"\\b\\t\\n\\v\\f\\r\\e\250\"" =
	p([8,9,10,11,12,13,27,168], 1, 40, 100),
    %% "\"\\e\\t\\nab\"\n \"cd\"" =
    "\"\\e\\t\\nabcd\"" =
	p("\e\t\nabcd", 1, 12, -1),

    %% DEL (127) is special...
    "[127]" = p("\d", 1, 10, -1),
    "[127]" = p([127], 1, 10, 100),

    "<<\"\\b\\t\\n\\v\\f\\r\\e\250\">>" =
	p(<<8,9,10,11,12,13,27,168>>, 1, 40, -1),
    "<<\"\\b\\t\\n\\v\\f\\r\\e\250\">>" =
	p(<<8,9,10,11,12,13,27,168>>, 1, 10, -1),
    "<<127>>" = p(<<127>>, 1, 10, 100),

    %% "Partial" string binaries:
    "<<\"he\"...>>" = p(list_to_binary("he"++[3]), 1, 80, 2),
    "<<\"he\"...>>" = p(list_to_binary("he"++[3]), 1, 80, 3),
    "<<104,101,3>>" = p(list_to_binary("he"++[3]), 1, 80, 4),
    "<<...>>" = p(list_to_binary([3] ++ "he"), 1, 80, 1),
    "<<3,...>>" = p(list_to_binary([3] ++ "he"), 1, 80, 2),
    "<<3,104,...>>" = p(list_to_binary([3] ++ "he"), 1, 80, 3),

    "<<\"12345678901234567890\"...>>" =
	p(list_to_binary("12345678901234567890"++[3]), 1, 80, 8),
    "<<\"12345678901234567890\"...>>" =
	p(list_to_binary("12345678901234567890"++[3]), 1, 80, 21),
    "<<49," ++ _ =
	p(list_to_binary("12345678901234567890"++[3]), 1, 80, 22),

    "{sdfsdfj,\n    23" ++ _ =
	p({sdfsdfj,23423423342.23432423}, 1, 17, -1),

    bt(<<"kljkljlksdjjlf kljalkjlsdajafasjdfj [kjljklasdf,kjlljsfd,sdfsdkjfsd,kjjsdf,jl,
                                     lkjjlajsfd|jsdf]">>,
             fmt("~w ~w ~p", 
                 [kljkljlksdjjlf,
                  kljalkjlsdajafasjdfj,
                  [kjljklasdf,kjlljsfd,sdfsdkjfsd,kjjsdf,jl,lkjjlajsfd | 
                   jsdf]])),

    %% Binaries are split as well:
    bt(<<"<<80,100,0,55,55,55,55,55,55,55,55,55,\n  "
               "55,55,55,55,55,55,55,...>>">>, 
             p(<<80,100,0,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,
                 55,55,55,55,55,55,55,55,55,55,55,55>>,1,40,20)),
    bt(<<"<<80,100,0,55,55,55,55,55,55,55,55,55,\n  "
               "55,55,55,55,55,55,55,55,55,55,55,55,\n  55,55,55,55,55,55>>">>,
             p(<<80,100,0,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,
                 55,55,55,55,55,55,55,55,55,55,55,55>>,1,40,-1)),
    "<<0,0,0,\n  ...>>" = p(<<0,0,0,0,0>>, 1, 10, 4),

    %% ~W now uses ",..." when printing tuples
    "[a,b|...]" = fmt("~W", [[a,b,c,d,e], 3]),
    "{a,b,...}" = fmt("~W", [{a,b,c,d,e}, 3]),
    ok.

%% OTP-6495. io_lib_pretty bugfix.
otp_6495(Config) when is_list(Config) ->
    bt(<<"[120,120,120,120,120,120,120,120,120,120,120,120,120,120,"
               "120,120,120,120,120]<<1>>">>,
             fmt("~w~p", ["xxxxxxxxxxxxxxxxxxx", <<1>>])),
    ok.

%% OTP-6517. The Format argument of fwrite can be a binary.
otp_6517(Config) when is_list(Config) ->
    "string" = fmt(<<"~s">>, [<<"string">>]),
    ok.

%% OTP-6502. Bits.
otp_6502(Config) when is_list(Config) ->
    bt(<<
     "[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]"
     "<<0,0,8,\n"
     "                                                                     "
     "  1:1>>">>,
             fmt("~w~p", [lists:seq(0, 25), <<17:25>>])),
    ok.

%% OTP-7421. Soft limit of 60 chars removed when pretty printing.
otp_7421(Config) when is_list(Config) ->
    bt(<<"{aa,bb,\n"
         "    c,dd,\n"
         "    eee,\n"
         "    fff}">>,
       rp({aa,bb,c,dd,eee,fff}, 1, 80, -1, 5, none)),
    bt(<<"{aa,bb,\n"
         "    c,\n"
         "    dd,\n"
         "    eee,\n"
         "    fff}">>,
       rp({aa,bb,c,dd,eee,fff}, 1, 80, -1, 4, none)),
    ok.

bt(Bin, R) ->
    R = binary_to_list(Bin).

p(Term, D) ->
    rp(Term, 1, 80, D).

p(Term, Col, Ll, D) ->
    rp(Term, Col, Ll, D, none).

rp(Term, Col, Ll, D) ->
    rp(Term, Col, Ll, D, fun rfd/2).

-define(MAXCS, 60).

rp(Term, Col, Ll, D, RF) ->
    rp(Term, Col, Ll, D, ?MAXCS, RF).

rp(Term, Col, Ll, D, M, none) ->
    rp(Term, Col, Ll, D, M, fun(_, _) -> no end);
rp(Term, Col, Ll, D, M, RF) ->
    %% io:format("~n~n*** Col = ~p Ll = ~p D = ~p~n~p~n-->~n", 
    %%           [Col, Ll, D, Term]),
    R = io_lib_pretty:print(Term, Col, Ll, D, M, RF),
    %% io:format("~s~n<--~n", [R]),
    OrigRes = lists:flatten(io_lib:format("~s", [R])),
    Args = [{column, Col}, {line_length, Ll}, {depth, D},
            {line_max_chars, M}, {record_print_fun, RF},
            %% Default values for print/[1,3,4,5,6]
            {chars_limit, -1}, {encoding, latin1},
            {strings, true}, {maps_order, undefined}],
    check_bin_p(OrigRes, Term, Args).

check_bin_p(OrigRes, Term, Args) ->
    try
        {UTF8, _, Width} = io_lib_pretty:print_bin(Term, maps:from_list(Args)),

        StartCol = proplists:get_value(column, Args, 0),
        OrigW = io_lib_format:indentation(OrigRes, StartCol),
        case Width > 0 of
            true when Width == OrigW -> ok;
            false when (StartCol - Width) == OrigW -> ok;
            _ ->
                io:format("Width fail, start: ~w got ~w correct ~w~n", [StartCol, Width, OrigW]),
                io:put_chars(OrigRes),
                io:nl(),
                io:put_chars(UTF8),
                exit(bad_width)
        end,
        true = is_binary(UTF8),
        case unicode:characters_to_list(UTF8) of
            OrigRes ->
                OrigRes;
            Other ->
                io:format("Exp: ~w~nGot: ~w~n", [OrigRes, Other]),
                io:format("Binary failed:~nio_lib_pretty:print_bin(~0p,~n   ~w). ", [Term, Args]),
                UTF8
        end
    catch _:Reason:ST ->
            io:format("Exp: ~w~n~n", [OrigRes]),
            io:format("GOT CRASH: ~p in ~p~n",[Reason, ST]),
            io:format("Binary crashed: io_lib_pretty:print_bin(~p, ~w). ", [Term, Args]),
            Reason
    end.

fmt(Fmt, Args) ->
    FormatList = io_lib:scan_format(Fmt, Args),
    {Fmt2, Args2} = io_lib:unscan_format(FormatList),
    Chars1 = lists:flatten(io_lib:build_text(FormatList)),
    Chars2 = lists:flatten(io_lib:format(Fmt2, Args2)),
    Chars3 = lists:flatten(io_lib:format(Fmt, Args)),
    Chars1 = Chars2,
    Chars2 = Chars3,
    check_bin_fmt(Chars1, Fmt, Args, []).

fmt(Fmt, Args, Opts) ->
    OrigRes = lists:flatten(io_lib:format(Fmt, Args, Opts)),
    check_bin_fmt(OrigRes, Fmt, Args, Opts).

check_bin_fmt(OrigRes, Fmt, Args, Opts) ->
    try
        Utf8 = io_lib:bformat(Fmt, Args, Opts),
        true = is_binary(Utf8),
        case unicode:characters_to_list(Utf8) of
            OrigRes ->
                OrigRes;
            Other ->
                io:format("Exp: ~w~n     ~ts~nGot: ~w~n     ~ts~n", [OrigRes, OrigRes, Other, Other]),
                io:format("Binary failed:~nio_lib:bformat(\"~ts\", ~w, ~w). ", [Fmt, Args, Opts]),
                Utf8
        end
    catch _:Reason:ST ->
            io:format("Exp: ~w~n~n", [OrigRes]),
            io:format("GOT CRASH: ~p in ~p~n",[Reason, ST]),
            io:format("Binary crashed: io_lib:bformat(\"~ts\", ~w, ~w). ", [Fmt, Args, Opts]),
            Reason
    end.

rfd(a, 0) ->
    [];
rfd(b, 1) ->
    [f];
rfd(c, 2) ->
    [f1, f2];
rfd(e, 3) ->
    [f, g, h];
rfd(d, 5) ->
    [aaaaaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbbbb,
     cccccccccccccccccccc, dddddddddddddddddddd,
     eeeeeeeeeeeeeeeeeeee];
rfd(rrrrr, 3) ->
    [f1, f2, f3];
rfd(aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, 0) ->
    [];
rfd('\x{400}', 1) ->
    ['\x{400}'];
rfd(_, _) ->
    no.

%% The examples in io(3) and io_lib(3).
manpage(Config) when is_list(Config) ->
    %% The examples that write or print only, not the ones that read...

    bt(<<"Hello world!\n">>,
             fmt("Hello world!~n", [])),
    bt(<<"|     aaaaa|bbbbb     |ccccc|\n">>, % bugfix
             fmt("|~10.5c|~-10.5c|~5c|~n", [$a, $b, $c])),
    bt(<<"|**********|\n">>,
             fmt("|~10w|~n", [{hey, hey, hey}])),
    bt(<<"|{hey,hey,h|\n">>,
             fmt("|~10s|~n", [io_lib:write({hey, hey, hey})])),

    T = [{attributes,[[{id,age,1.50000},{mode,explicit},
        {typename,"INTEGER"}], [{id,cho},{mode,explicit},{typename,'Cho'}]]},
        {typename,'Person'},{tag,{'PRIVATE',3}},{mode,implicit}],
    bt(<<"[{attributes,[[{id,age,1.5},{mode,explicit},{typename,"
               "[73,78,84,69,71,69,82]}],[{id,cho},{mode,explicit},"
               "{typename,'Cho'}]]},{typename,'Person'},{tag,{'PRIVATE',3}},"
               "{mode,implicit}]\n">>,
             fmt("~w~n", [T])),
    bt(<<"[{attributes,[[{id,age,1.5},\n"
               "               {mode,explicit},\n"
               "               {typename,\"INTEGER\"}],\n"
               "              [{id,cho},{mode,explicit},{typename,'Cho'}]]},\n"
               " {typename,'Person'},\n"
               " {tag,{'PRIVATE',3}},\n"
               " {mode,implicit}]\n">>,
             fmt("~62p~n", [T])),
    bt(<<"Here T = [{attributes,[[{id,age,1.5},\n"
               "                        {mode,explicit},\n"
               "                        {typename,\"INTEGER\"}],\n"
               "                       [{id,cho},\n"
               "                        {mode,explicit},\n"
               "                        {typename,'Cho'}]]},\n"
               "          {typename,'Person'},\n"
               "          {tag,{'PRIVATE',3}},\n"
               "          {mode,implicit}]\n">>,
              fmt("Here T = ~62p~n", [T])),
    bt(<<"[{attributes,[[{id,age,1.5},{mode,explicit},"
               "{typename,...}],[{id,cho},{mode,...},{...}]]},"
               "{typename,'Person'},{tag,{'PRIVATE',3}},{mode,implicit}]\n">>,
             fmt("~W~n", [T,9])),
    bt(<<"[{attributes,[[{id,age,1.5},{mode,explicit},{typename,...}],"
               "\n              "
               "[{id,cho},{mode,...},{...}]]},\n {typename,'Person'},\n "
               "{tag,{'PRIVATE',3}},\n {mode,implicit}]\n">>,
             fmt("~62P~n", [T,9])),

    "1F\n" = fmt("~.16B~n", [31]),
    "-10011\n" = fmt("~.2B~n", [-19]),
    "5Z\n" = fmt("~.36B~n", [5*36+35]),
    "10#31\n" = fmt("~X~n", [31,"10#"]),
    "-0x1F\n" = fmt("~.16X~n", [-31,"0x"]),
    "10#31\n" = fmt("~.10#~n", [31]),
    "-16#1F\n" = fmt("~.16#~n", [-31]),
    "abc def 'abc def'  {foo,1} A \n" =
           fmt("~s ~w ~i ~w ~c ~n",
               ['abc def', 'abc def', {foo, 1},{foo, 1}, 65]),
    %% fmt("~s", [65]),

    %% io_lib(3)
    bt(<<"{1,[2],[3],[...],...}">>,
             lists:flatten(io_lib:write({1,[2],[3],[4,5],6,7,8,9}, 5))),
    ok.

%% OTP-6708. Fewer newlines when pretty-printing.
otp_6708(Config) when is_list(Config) ->
    bt(<<"[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,\n"
               " 23,24,25,26,27,28,29|...]">>,
             p(lists:seq(1,1000), 30)),
    bt(<<"{lkjasklfjsdak,mlkasjdflksj,klasdjfklasd,jklasdfjkl,\n"
               "               jklsdjfklsd,masdfjkkl}">>,
             p({lkjasklfjsdak,mlkasjdflksj,klasdjfklasd,jklasdfjkl,
                jklsdjfklsd, masdfjkkl}, -1)),
    bt(<<"#b{f = {lkjljalksdf,jklaskfjd,kljasdlf,kljasdf,kljsdlkf,\n"
               "                    kjdd}}">>,
             p({b, {lkjljalksdf,jklaskfjd,kljasdlf,kljasdf,kljsdlkf,kjdd}}, 
               -1)),
    bt(<<"#b{f = {lkjljalksdf,jklaskfjd,kljasdlf,kljasdf,kljsdlkf,\n"
               "                    kdd}}">>,
             p({b, {lkjljalksdf,jklaskfjd,kljasdlf,kljasdf,kljsdlkf,kdd}}, 
               -1)),
    bt(<<"#e{f = undefined,g = undefined,\n"
               "   h = #e{f = 11,g = 22,h = 333}}">>,
             p({e,undefined,undefined,{e,11,22,333}}, -1)),
    bt(<<"[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21|\n"
               " apa11]">>,
             p(lists:seq(1,21) ++ apa11, -1)),
    bt(<<"[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,\n"
               " 23,\n"
               " {{abadalkjlasdjflksdajfksdklfsdjlkfdlskjflsdj"
                        "flsdjfldsdsdddd}}]">>,
          p(lists:seq(1,23) ++ 
            [{{abadalkjlasdjflksdajfksdklfsdjlkfdlskjflsdjflsdjfldsdsdddd}}],
            -1)),
    bt(<<"{lkjasdf,\n"
               "    {kjkjsd,\n"
               "        {kjsd,\n"
               "            {kljsdf,\n"
               "                {kjlsd,{dkjsdf,{kjlds,{kljsd,{kljs,"
                                   "{kljlkjsd}}}}}}}}}}">>,
             p({lkjasdf,{kjkjsd,{kjsd,
                                 {kljsdf,
                                  {kjlsd,
                                   {dkjsdf,{kjlds,
                                            {kljsd,{kljs,{kljlkjsd}}}}}}}}}},
               -1)),
    bt(<<"{lkjasdf,\n"
               "    {kjkjsd,\n"
               "        {kjsd,{kljsdf,{kjlsd,{dkjsdf,{kjlds,"
                                "{kljsd,{kljs}}}}}}}}}">>,
             p({lkjasdf,{kjkjsd,{kjsd,
                                 {kljsdf,{kjlsd,{dkjsdf,
                                                 {kjlds,{kljsd,{kljs}}}}}}}}},
               -1)),
    bt(<<"<<1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,\n"
               "  22,23>>">>,
             p(list_to_binary(lists:seq(1,23)), -1)),
    bt(<<"<<100,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,\n"
               "  27>>">>,
             p(list_to_binary([100|lists:seq(10,27)]), -1)),
    bt(<<"<<100,101,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,\n"
               "  26>>">>,
             p(list_to_binary([100,101|lists:seq(10,26)]), -1)),
    bt(<<"{{<<100,101,102,10,11,12,13,14,15,16,17,18,19,20,21,22,\n"
               "    23>>}}">>,
             p({{list_to_binary([100,101,102|lists:seq(10,23)])}}, -1)),
    bt(<<"[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22|\n"
               " ap]">>,
             p(lists:seq(1,22) ++ ap, -1)),
    bt(<<"[1,2,3,4,5,6,7,8,9,10,{},[],\n <<>>,11,12,13,14,15]">>,
             p(lists:seq(1,10) ++ [{},[],<<>>] ++ lists:seq(11,15),1,30,-1)),
    bt(<<"[ddd,ddd,\n"
               " {1},\n"
               " [1,2],\n"
               " ddd,kdfd,\n"
               " [[1,2],a,b,c],\n"
               " <<\"foo\">>,<<\"bar\">>,1,\n"
               " {2}]">>,
             p([ddd,ddd,{1},[1,2],ddd,kdfd,[[1,2],a,b,c],<<"foo">>,<<"bar">>,
                1,{2}],1,50,-1)),

    bt(<<"{dskljsadfkjsdlkjflksdjflksdjfklsdjklfjsdklfjlsdjfkl,jksd,\n"
               "                                                     "
                   "lkjsdf,kljsdf,kljsf,kljsdf,kljsdf,jkldf,jklsdf,kljsdf,\n"
               "                                                     "
                   "kljsdf,jklsdf,lkjfd,lkjsdf,kljsdf,kljsdf,lkjsdf,kljsdf,\n"
               "                                                     "
                   "lkjsdfsd,kljsdf,kjsfj}">>,
             p({dskljsadfkjsdlkjflksdjflksdjfklsdjklfjsdklfjlsdjfkl,jksd,
                lkjsdf,kljsdf,kljsf,kljsdf,kljsdf,jkldf,jklsdf,kljsdf,
                kljsdf,jklsdf,lkjfd,lkjsdf,kljsdf,kljsdf,lkjsdf,kljsdf,
                lkjsdfsd,kljsdf,kjsfj}, 1, 110, -1)),
    bt(<<"{dskljsadfkjsdlkjflksdjflksdjfklsdjklfjsdklfjlsdjfkl,"
                  "#d{aaaaaaaaaaaaaaaaaaaa = 1,\n"
               "                                                        "
                  "bbbbbbbbbbbbbbbbbbbb = 2,cccccccccccccccccccc = 3,\n"
               "                                                        "
                  "dddddddddddddddddddd = 4,eeeeeeeeeeeeeeeeeeee = 5}}">>,
             rp({dskljsadfkjsdlkjflksdjflksdjfklsdjklfjsdklfjlsdjfkl,
                 {d,1,2,3,4,5}},1,200,-1)),
    ok.

-define(ONE(N), ((1 bsl N) - 1)).
-define(ALL_ONES, ((1 bsl 52) - 1)).


otp_7084() ->
    [{timetrap,{minutes,6}}]. %% valgrind needs a lot of time

%% OTP-7084. Printing floating point numbers nicely.
otp_7084(Config) when is_list(Config) ->
    L = [{g_warm_up, fun g_warm_up/0},
         {g_big_pos_float, fun g_big_pos_float/0},
         {g_small_neg_float, fun g_small_neg_float/0},
         {g_close_to_zero, fun g_close_to_zero/0},
         {g_denormalized, fun g_denormalized/0},
         {g_normalized, fun g_normalized/0},
         {g_choice, fun g_choice/0},
         {g_ryu, fun g_ryu/0},
         {g_anomalous, fun g_anomalous/0},
         {g_misc, fun g_misc/0}],
    F = fun({M,T}) -> io:format("~p~n", [M]), T() end,
    lists:foreach(fun(T) -> F(T) end, L),
    ok.

g_warm_up() ->
    g_t(0.5),
    g_t(-0.5),
    g_t((1 bsl 55) * 0.5),
    g_t(-(1 bsl 55) * 0.5),
    g_t(1.6799127650033296e+308),
    g_t(pack(1, 0, 2#1010101010001100101000010111100101000000101100110001)),
    g_t(pack(1, 0, 2#0001010000001001110100000101010101001110010001010110)),
    g_t(234324324.23432432432432),
    ok.

g_big_pos_float() ->
    %% The greatest positive float:
    ft({{0,2046,?ONE(52)}, 100, 0}),
    ok.

g_small_neg_float() ->
    %% The least negative float:
    ft({{1,2046,?ONE(52)}, 0, 100}),
    ok.

g_close_to_zero() ->
    %% A few denormalized floats close to zero:
    ft({{0,0,0}, 100, 100}),
    g_t(pack(1, 0, 0)), % -0.0
    ok.

g_denormalized() ->
    %% Denormalized floats (mantissa carry):
%%    D = 5,
    %% Faster:
    D = 1,
    [ft({{S,0,?ONE(N)},D,D}) || S <- [0,1], N <- lists:seq(0, 52)],
    ok.

g_normalized() -> 
    %% Normalized floats (exponent carry):
%%    D = 5,
    %% Faster:
    D = 1,
    [ft({{S,E,?ONE(52)},D,D}) || S <- [0,1], E <- lists:seq(0, 2045)],
    ok.

g_choice() ->
    %% Exponent should be used when and only when the string is shorter.
    %% (g_misc/0 checks this too, and probably more throughly).
    L = [0.0003, 3.0e-5, 3.3e-5, 3.3e-4,
         314.0, 314.1, 310.0, 3.1e6, -100.0,
         3.34e4, 3.0e3, 3.34333e9, 3.3433323e10, 33433323700.0,
         0.00197963, 1.97963e-4],
    lists:foreach(fun(V) -> g_t(V) end, L),
    ok.

g_anomalous() ->
    %% These test cases come from https://github.com/microsoft/STL/blob/f1515e04fd00876137e762c08b90d9aa450859e0/tests/std/tests/P0067R5_charconv/double_to_chars_test_cases.hpp

    %% https://www.exploringbinary.com/the-shortest-decimal-string-that-round-trips-may-not-be-the-nearest/
    %% This is an exhaustive list of anomalous values
    %% Because math, these values have shortest-round-trip decimal representations containing 16 significant digits,
    %% but those decimal digits aren't what would be printed by "%.15e". For ordinary values, shortest-round-trip
    %% behaves as if it can magically pick a precision for "%.*e", finding the smallest precision that round-trips.
    %% (That is, start with the exact decimal representation, and then round it as much as possible.) These anomalous
    %% values demonstrate an exception to that mental model. They aren't being "incorrectly rounded"; instead, having
    %% the shortest output that round-trips is being prioritized. (This differs by 1 in the least significant decimal
    %% digit printed, so it's a very small difference.)

    L_anom = [6.386688990511104e+293, 5.282945311356653e+269,
              6.150157786156811e+259, 5.334411546303884e+241,
              5.386379163185535e+213, 6.483618076376552e+178,
              6.183260036827614e+172, 5.896816288783659e+166,
              5.758609657015292e+163, 5.623642243178996e+160,
              6.243497100631985e+144, 8.263199609878108e+121,
              6.455624695217272e+119, 6.156563468186638e+113,
              7.167183174968974e+103, 6.518515124270356e+91,
              6.070840288205404e+82, 6.129982163463556e+54,
              5.986310706507379e+51, 5.444517870735016e+39,
              5.316911983139664e+36, 6.189700196426902e+26,
              5.960464477539063e-08, 5.684341886080802e-14,
              6.617444900424222e-24, 6.310887241768095e-30,
              7.174648137343064e-43, 7.854549544476363e-90,
              6.653062250012736e-111, 5.075883674631299e-116,
              6.256509672447191e-148, 4.887898181599368e-150,
              5.966672584960166e-154, 5.426657103235053e-166,
              5.351097043477547e-197, 5.225680706521042e-200,
              6.083493012144512e-210, 5.940911144672375e-213,
              6.290184345309701e-235, 6.142758149716505e-238,
              7.678447687145631e-239, 5.858190679279809e-244,
              5.641232424577593e-278, 8.209073602596753e-289,
              7.291122019556398e-304, 7.120236347223045e-307],
    lists:foreach(fun(V) -> g_t(V) end, L_anom),

    %% This is an exhaustive list of almost-but-not-quite-anomalous values.
    L_quasi_anom = [6.237000967296e+290, 6.090821257125e+287,
                    8.25460204899477e+267, 5.78358058743443e+222,
                    7.1362384635298e+44, 6.10987272699921e-151,
                    5.17526350329881e-172, 6.84940421565126e-195],
    lists:foreach(fun(V) -> g_t(V) end, L_quasi_anom),

    ok.

g_ryu() ->
    %% specific white box tests that should trigger specific edge cases
    %% to the ryu algorithm see: 
    %% https://github.com/ulfjack/ryu/blob/master/ryu/tests/d2s_test.cc

    %% this list is regression tests from the ryu C ref implementation
    L_regression = [-2.109808898695963e16, 4.940656e-318, 1.18575755E-316,
                    2.989102097996e-312, 9.0608011534336e15,
                    4.708356024711512e18, 9.409340012568248e18,
                    1.2345678],
    lists:foreach(fun(V) -> g_t(V) end, L_regression),

    %% These numbers have a mantissa that is a multiple of the largest power of 5 that fits,
    %% and an exponent that causes the computation for q to result in 22, which is a corner
    %% case for Ryu.
    L_pow5 = [16#4830F0CF064DD592, 16#4840F0CF064DD592, 
              16#4850F0CF064DD592],
    lists:foreach(fun(V) -> g_t(i_2_d(V)) end, L_pow5),

    %% Test 32-bit chunking 2^32 +- 1/2
    L_32bits = [4.294967294, 4.294967295, 4.294967296, 4.294967297,
                4.294967298],
    lists:foreach(fun(V) -> g_t(V) end, L_32bits),

    %% Test 32-bit chunking 2^32 +- 1/2
    L_32bits = [4.294967294, 4.294967295, 4.294967296, 4.294967297,
                4.294967298],
    lists:foreach(fun(V) -> g_t(V) end, L_32bits),

    L = [1.2e+1, 1.23e+2, 1.234e+3, 1.2345e+4, 1.23456e+5, 1.234567e+6,
        1.2345678e+7, 1.23456789e+8, 1.23456789e+9, 1.234567895e+9,
        1.2345678901e+10, 1.23456789012e+11, 1.234567890123e+12,
        1.2345678901234e+13, 1.23456789012345e+14, 1.234567890123456e+15],
    lists:foreach(fun(V) -> g_t(V) end, L),

    %% power of 2
    L_pow2 = [8.0, 64.0, 512.0, 8192.0, 65536.0, 524288.0, 8388608.0,
             67108864.0, 536870912.0, 8589934592.0, 68719476736.0,
             549755813888.0, 8796093022208.0, 70368744177664.0,
             562949953421312.0, 9007199254740992.0],
    lists:foreach(fun(V) -> g_t(V) end, L_pow2),

    %% 1000 * power of 2
    L_pow2_1000 = [8.0e+3, 64.0e+3, 512.0e+3, 8192.0e+3, 65536.0e+3,
                  524288.0e+3, 8388608.0e+3, 67108864.0e+3, 536870912.0e+3,
                  8589934592.0e+3, 68719476736.0e+3, 549755813888.0e+3,
                  8796093022208.0e+3],
    lists:foreach(fun(V) -> g_t(V) end, L_pow2_1000),

    %% 10^15 + 10^i
    L_pow10_plus = [1.0e+15 + 1.0e+0, 1.0e+15 + 1.0e+1, 1.0e+15 + 1.0e+2,
                   1.0e+15 + 1.0e+3, 1.0e+15 + 1.0e+4, 1.0e+15 + 1.0e+5,
                   1.0e+15 + 1.0e+6, 1.0e+15 + 1.0e+7, 1.0e+15 + 1.0e+8,
                   1.0e+15 + 1.0e+9, 1.0e+15 + 1.0e+10, 1.0e+15 + 1.0e+11,
                   1.0e+15 + 1.0e+12, 1.0e+15 + 1.0e+13, 1.0e+15 + 1.0e+14],
    lists:foreach(fun(V) -> g_t(V) end, L_pow10_plus),

    %% min and max
    g_t(i_2_d(1)),
    g_t(i_2_d(16#7fefffffffffffff)),

    %% lots of trailing zeroes
    g_t(2.98023223876953125e-8),

    %% Switch to Subnormal
    g_t(2.2250738585072014e-308),

    %% special case to check for the shift to the right by 128
    L_shift = [parts_2_f(0, 4,0), parts_2_f(0, 6, (1 bsl 53) - 1),
               parts_2_f(0, 41, 0), parts_2_f(0, 40, (1 bsl 53) - 1),
               parts_2_f(0, 1077, 0), parts_2_f(0, 1076, (1 bsl 53) - 1),
               parts_2_f(0, 307, 0), parts_2_f(0, 306, (1 bsl 53) - 1),
               parts_2_f(0, 934, 16#000FA7161A4D6E0C)],
    lists:foreach(fun(V) -> g_t(V) end, L_shift),

    %% following test cases come from https://github.com/microsoft/STL/blob/f1515e04fd00876137e762c08b90d9aa450859e0/tests/std/tests/P0067R5_charconv/double_to_chars_test_cases.hpp
    %% These numbers have odd mantissas (unaffected by shifting)
    %% that are barely within the "max shifted mantissa" limit.

    L_mantissas_within_limit = [
        1801439850948197.0e1, 360287970189639.0e2, 72057594037927.0e3,
        14411518807585.0e4, 2882303761517.0e5, 576460752303.0e6,
        115292150459.0e7, 23058430091.0e8, 4611686017.0e9, 922337203.0e10,
        184467439.0e11, 36893487.0e12, 7378697.0e13, 1475739.0e14,
        295147.0e15, 59029.0e16, 11805.0e17, 2361.0e18, 471.0e19, 93.0e20,
        17.0e21, 3.0e22],
    lists:foreach(fun(V) -> g_t(V) end, L_mantissas_within_limit),

    %% These numbers have odd mantissas (unaffected by shifting)
    %% that are barely above the "max shifted mantissa" limit.
    L_mantissas_above_limit = [
        1801439850948199.0e1, 360287970189641.0e2, 72057594037929.0e3,
        14411518807587.0e4, 2882303761519.0e5, 576460752305.0e6,
        115292150461.0e7, 23058430093.0e8, 4611686019.0e9, 922337205.0e10,
        184467441.0e11, 36893489.0e12, 7378699.0e13, 1475741.0e14,
        295149.0e15, 59031.0e16, 11807.0e17, 2363.0e18, 473.0e19, 95.0e20,
        19.0e21, 5.0e22],
    lists:foreach(fun(V) -> g_t(V) end, L_mantissas_above_limit),

    L_switch = [1801439850948197.0e1, 360287970189639.0e2, 72057594037927.0e3,
                14411518807585.0e4, 2882303761517.0e5, 576460752303.0e6,
                115292150459.0e7, 23058430091.0e8, 4611686017.0e9,
                922337203.0e10, 184467439.0e11, 36893487.0e12, 7378697.0e13,
                1475739.0e14, 295147.0e15, 59029.0e16, 11805.0e17, 2361.0e18,
                471.0e19, 93.0e20, 17.0e21, 3.0e22, 1801439850948199.0e1,
                360287970189641.0e2, 72057594037929.0e3, 14411518807587.0e4,
                2882303761519.0e5, 576460752305.0e6, 115292150461.0e7,
                23058430093.0e8, 4611686019.0e9, 922337205.0e10,
                184467441.0e11, 36893489.0e12, 7378699.0e13, 1475741.0e14,
                295149.0e15, 59031.0e16, 11807.0e17, 2363.0e18, 473.0e19,
                95.0e20, 19.0e21, 5.0e22, 302230528.0e15, 302232576.0e15,
                81123342286848.0e18, 81192061763584.0e18],
    lists:foreach(fun(V) -> g_t(V) end, L_switch),

    L_edge = [123456789012345683968.0, 1.9156918820264798e-56,
              6.6564021122018745e+264, 4.91e-6, 5.547e-6],
    lists:foreach(fun(V) -> g_t(V) end, L_edge),

    ok.

i_2_d(Int) ->
    <<F:64/float>> = <<Int:64/unsigned-integer>>,
    F.

parts_2_f(S, E, M) ->
    <<F:64/float>> = <<S:1, E:11, M:52>>,
    F.

g_misc() -> 
    L_0_308 = lists:seq(0, 308),
    L_0_307 = lists:seq(0, 307),

    %% Faster:
    L_1_9 = [1,5,9],
    L_0_9 = [0,1,5,9],

    %% 1.0,10.0, ... 2.0,20.0, ... 9.0,90.0, ... -1,-10, ... -2.0,-20.0...
    [g_t(S*T*pow10(N)) || S <- [1.0, -1.0], T <- L_1_9, N <- L_0_307],

    %% 1.0,1.0/10,1.0/100,... 2.0,2.0/10,2.0/100, ... 9.0,9.0/10,9.0/100,
    %% -1.0,-1.0/10,... -9.0,-9.0/10...
    [g_t(S*T/pow10(N)) || S <- [1.0, -1.0], T <- L_1_9, N <- L_0_308],

    %% 0.0,1.0,2.0,...,9.0, 0.0,10.0,20.0,...,90.0,...
    %% 0.0,-1.0,-2.0,...,-9.0, 0.0,-10.0,-20.0,...,-90.0,...
    [g_t(S*list_to_float([D+$0]++lists:duplicate(N, $0)++".0")) ||
        S <- [1.0,-1.0], N <- lists:seq(0, 300), D <- L_0_9],

    %% 0.0,0.1,0.2,...0,9, 0.0,0.01,0.02,...,0.09,
    %% 0.0,-0.1,-0.2,...-0,9, 0.0,-0.01,-0.02,...,-0.09,
    [g_t(S*list_to_float("0."++lists:duplicate(N, $0)++[D+$0])) ||
        S <- [1.0,-1.0], N <- lists:seq(0, 300), D <- L_0_9],
    ok.

ft({{S,E,M}, L, G}) ->
    ft({pack(S, E, M), L, G});
ft({V, Less, Greater}) when is_float(V) ->
    _ = g_t(V),
    ft(V, fun inc/1, Greater),
    ft(V, fun dec/1, Less).

ft(V0, F, I) when I > 0, is_float(V0) ->
    V = F(V0),
    _ = g_t(V),
    ft(V, F, I - 1);
ft(V, _F, 0) when is_float(V) ->
    ok.

g_t(V) when is_float(V) ->
    %% io:format("Testing ~.17g~n", [V]),
    Io = fmt("~p", [V]),
    Sv = binary_to_list(iolist_to_binary(Io)),
    ok = g_t(V, Sv),
    Sv.

%% -> ok | THROW

%% Checks that Sv is the shortest, correctly rounded string that
%% converts to V when read back with list_to_float/1.
%% Note: in a few cases the least significant digit has been
%% incremented by one, namely when the correctly rounded string
%% converts to another floating point number.
g_t(V, Sv) when V > 0.0; V < 0.0 ->
    try
        g_t_1(V, Sv)
    catch throw:Reason ->
        throw({Reason, V, Sv})
    end;
g_t(Zero, Format) ->
    case <<Zero/float>> of
        <<1:1,_:63>> ->
            "-0.0" = Format,
            ok;
        <<0:1,_:63>> ->
            "0.0" = Format,
            ok
    end.

g_t_1(V, Sv) ->
    %% Check that the least significant digit is correct.
    %% If Sv is "3.14" then Sv- is "3.13" and Sv+ is "3.15".
    %% Check that |V - Sv| =< (V - Sv-) and
    %%       that |V - Sv| =< (Sv+ - V)
    Times = least_significant_digit(Sv),
    case Times of
        0 -> throw(least_significant_digit_is_zero);
        _ -> ok
    end,
    S = if V < 0 -> -1; true -> 1 end,
    SvMinus = incr_lsd(Sv, -S),
    SvPlus = incr_lsd(Sv, S),
    Svr = s2r(Sv),
    Svminusr = s2r(SvMinus),
    Svplusr = s2r(SvPlus),
    Vr = f2r(V),

    Abs_Sv_Vr = rat_abs(rat_minus(Svr, Vr)),
    Svminus_Vr = rat_minus(Vr, Svminusr),
    Svplus_Vr = rat_minus(Svplusr, Vr),
    %% The are 45 (negative) floats where SvMinus (SvPlus) is closer
    %% to V than Sv, but such that when reading SvMinus (SvPlus) wrong
    %% float would be returned.
    case rat_lte(Abs_Sv_Vr, Svminus_Vr) of
        true -> 
            ok;
        false ->  
             case list_to_float(SvMinus) of
                 V -> throw(vsminus_too_close_to_v);
                 _Vminus -> ok
             end
    end,
    case rat_lte(Abs_Sv_Vr, Svplus_Vr) of
        true -> 
            ok;
        false ->
             case list_to_float(SvPlus) of
                 V -> throw(vsplus_too_close_to_v);
                 _Vplus -> ok
             end
    end,

    %% Check that Sv is closer to V than to V- and V+.
    %% Check that |V - Sv| =< (V - V-) and
    %%       that |V - Sv| =< (V+ - V)
    %% (An alternative is  V- + V =< 2*Sv =< V + V+.)
    case inc(V) of
        inf -> 
            ok;
        Vplus ->
            Vplusr = f2r(Vplus),
            V_Vplusr = rat_minus(Vplusr, Vr),
            case rat_lte(Abs_Sv_Vr, V_Vplusr) of
                true -> ok;
                false -> throw(vplus_too_close_to_sv)
            end
    end,
    case dec(V) of
        '-inf' ->
            ok;
        Vminus ->
            Vminusr = f2r(Vminus),
            V_Vminusr = rat_minus(Vr, Vminusr),
            case rat_lte(Abs_Sv_Vr, V_Vminusr) of
                true -> ok;
                false -> throw(vminus_too_close_to_sv)
            end
    end,

    %% Check that no prefix of Sv yields V.
    %% If Sv is "3.14" then Svlow is "3.1" and Svhigh is "3.2".
    %%
    %% This is just one way of getting Svlow and Svhigh:
    if
        V < 0 ->
            SvHigh = step_lsd(Sv, -Times),
            SvLow = step_lsd(Sv, 10 - Times);
        true ->
            SvHigh = step_lsd(Sv, 10 - Times),
            SvLow = step_lsd(Sv, -Times)
    end,

    case catch list_to_float(SvLow) of
        V -> throw(low_is_v);
        _ -> ok
    end,

    case catch list_to_float(SvHigh) of
        V -> throw(high_is_v);
        _ -> ok
    end,

    %% Check that Sv has enough digits.
    case list_to_float(Sv) of
        V -> ok;
        _ -> throw(wrong_float) % cannot happen
    end,

    g_choice(Sv),

    ok.

%%% In "123450000.0", '5' is the lsd; 
%%% in "1234.0000", (the last) '0' is the lsd;
%%% in "1234.0", '4' is the lsd (the Erlang syntax requires the final zero).

%% Trailing zeroes are not significant ("3.0", "5.0e-324", "232000.0").
least_significant_digit("-"++Ds) ->
    least_significant_digit(Ds);
least_significant_digit("+"++Ds) ->
    least_significant_digit(Ds);
least_significant_digit(Ds) ->
    [MS|_E] = string:tokens(Ds, "eE"),
    lsd0(lists:reverse(MS))-$0.

lsd0("0."++Ds) ->
    lsd1(Ds);
lsd0([D | _Ds]) ->
    D.

lsd1("0"++Ds) ->
    lsd1(Ds);
lsd1([D | _Ds]) ->
    D.

step_lsd(Ds, 0) ->
    Ds;
step_lsd(Ds, N) when N > 0 ->
    NDs = incr_lsd(Ds, 1),
    step_lsd(NDs, N - 1);
step_lsd(Ds, N) when N < 0 ->
    NDs = incr_lsd(Ds, -1),
    step_lsd(NDs, N + 1).

%% Assumes Ds represents some other number than zero.
%% Increments or decrements the least significant digit.
incr_lsd("-"++Ds, I) ->
    "-"++incr_lsd(Ds, I);
incr_lsd(Ds, I) when I =:= 1; I =:= -1 -> 
    [MS|E] = string:tokens(Ds, "eE"),
    X = ["e" || true <- [E =/= []]],
    lists:flatten([incr_lsd0(lists:reverse(MS), I, []), X, E]).

incr_lsd0("0."++Ds, C, L) ->
    incr_lsd1(Ds, C, [$., $0 | L]);
incr_lsd0(Ds, C, L) ->
    incr_lsd2(Ds, C, L).

incr_lsd1("0"++Ds, C, L) ->
    incr_lsd1(Ds, C, [$0 | L]);
incr_lsd1(Ds, C, L) ->
    incr_lsd2(Ds, C, L).

incr_lsd2([], C, L) ->
    [C + $0 | L];
incr_lsd2("."++Ds, C, L) ->
    incr_lsd2(Ds, C, [$. | L]);
incr_lsd2("9"++Ds, 1=C, L) ->
    incr_lsd2(Ds, C, [$0 | L]);
incr_lsd2("0"++Ds, -1=C, L) ->
    incr_lsd2(Ds, C, [$9 | L]);
incr_lsd2([D | Ds], C, L) ->
    lists:reverse(Ds, [D + C | L]).

s2r(S) when is_list(S) ->
    case string:tokens(S, "eE") of
        [MS] ->
            s10(MS);
        [MS, ES] ->
            Mr = s10(MS),
            E = list_to_integer(ES),
            if 
                E < 0 ->
                    rat_multiply(Mr, {1,pow10(-E)});
                true ->
                    rat_multiply(Mr, {pow10(E), 1})
            end
    end.

s10("-"++S) ->
    rat_multiply({-1,1},s10(S));
s10(S) ->
    [AS, BS] = string:tokens(S, "."),
    Sc = length(BS),
    A = list_to_integer(AS),
    B = list_to_integer(BS),
    F = pow10(Sc),
    rat_multiply({1,1}, {A*F + B, F}).

pow10(X) ->
    int_pow(10, X).

int_pow(X, 0) when is_integer(X) ->
    1;
int_pow(X, N) when is_integer(X), is_integer(N), N > 0 ->
    int_pow(X, N, 1).

int_pow(X, N, R) when N < 2 ->
    R * X;
int_pow(X, N, R) ->
    int_pow(X * X, N bsr 1, case N band 1 of 1 -> R * X; 0 -> R end).

dec(F) when is_float(F) ->
    <<S:1, BE:11, M:52>> = <<F:64/float>>,
    dec({S,BE,M});
dec({1,2046,?ALL_ONES}) ->
    '-inf';
dec({S,BE,M}) when 0 =< S, S =< 1,
                   0 =< BE, BE =< 2046,
                   0 =< M, M =< ?ALL_ONES ->
    {S1,BE1,M1} = dec1(S, BE, M),
    <<F:64/float>> = <<S:1, BE:11, M:52>>,
    <<F1:64/float>> = <<S1:1, BE1:11, M1:52>>,
    true = F1 < F,
    F1.
    

dec1(0, 0, 0) ->
    dec1(1, 0, 0);
dec1(0, BE, 0) ->
    {0,BE-1,?ALL_ONES};
dec1(0, BE, M) ->
    {0,BE,M-1};
dec1(1, BE, ?ALL_ONES) ->
    {1,BE+1,0};
dec1(1, BE, M) ->
    {1,BE,M+1}.

inc(F) when is_float(F) ->
    <<S:1, BE:11, M:52>> = <<F:64/float>>,
    inc({S,BE,M});
inc({0,2046,?ALL_ONES}) ->
    inf;
inc({S,BE,M}) when 0 =< S, S =< 1,
                   0 =< BE, BE =< 2046,
                   0 =< M, M =< ?ALL_ONES ->
    {S1,BE1,M1} = inc1(S, BE, M),
    <<F:64/float>> = <<S:1, BE:11, M:52>>,
    <<F1:64/float>> = <<S1:1, BE1:11, M1:52>>,
    true = F1 > F,
    F1.

inc1(0, BE, ?ALL_ONES) ->
    {0,BE+1,0};
inc1(0, BE, M) ->
    {0,BE,M+1};
inc1(1, 0, 0) ->
    inc1(0, 0, 0);
inc1(1, BE, 0) ->
    {1,BE-1,?ALL_ONES};
inc1(1, BE, M) ->
    {1,BE,M-1}.

f2r(F) when is_float(F) ->
    <<S:1, BE:11, M:52>> = <<F:64/float>>,
    f2r({S,BE,M});
f2r({S,BE,M}) when 0 =< S, S =< 1,
                   0 =< BE, BE =< 2046,
                   0 =< M, M =< ?ALL_ONES ->
    Vr = {T,N} = f2r1(S, BE, M),
    <<F:64/float>> = <<S:1, BE:11, M:52>>,
    case catch T/N of
        {'EXIT', _} -> ok;
        TN -> true = F == TN
    end,
    Vr.

f2r1(S, 0, M) ->
    rat_multiply({sign(S),1}, {M, 1 bsl 1074});
f2r1(S, BE, M) when BE - 1075 >= 0 ->
    rat_multiply({sign(S),1}, {((1 bsl 52)+M) * (1 bsl (BE-1075)),1});
f2r1(S, BE, M) ->
    rat_multiply({sign(S),1}, {(1 bsl 52)+M, 1 bsl (1075-BE)}).

sign(0) ->
    1;
sign(1) ->
    -1.

%%% Rational numbers (very scetchy).

rat_abs({A,B}) when A < 0 ->
    {-A,B};
rat_abs({A,B}) ->
    {A,B}.

-ifdef(not_used).
rat_equal(R1, R2) ->
    R1 =:= R2.

rat_negate({A,B}) ->
    {-A,B}.

rat_divide({A,B},{C,D}) ->
    rat_multiply({A,B},{D,C}).
-endif.

rat_lte({A,B}, {C,D}) when B =/= 0, D =/= 0 ->
    A*D =< C*B.

rat_minus({A,B}, {C,D}) ->
    rat_plus({A,B}, {-C,D}).

rat_plus({A,B}, {C,D})  when B =/= 0, D =/= 0 ->
    rat_normalize({A*D+B*C, B*D}).

rat_multiply({A,B}, {C,D})  when B =/= 0, D =/= 0 ->
    rat_normalize({A * C, B * D}).

rat_normalize({T,N}) when N =/= 0 ->
    G = gcd(T, N),
    T2 = T div G,
    N2 = N div G,
    if
        T2 < 0 ->
            if 
                N2 < 0 -> {-T2,-N2};
                true -> {T2,N2}
            end;
        true ->
            if 
                N2 < 0 -> {-T2,-N2};
                true -> {T2,N2}
            end
    end.

gcd(A, 0) -> A;
gcd(A, B) -> gcd(B, A rem B).

%%% End of rational numbers.

%% Check that there is an exponent if and only if characters are saved
%% when abs(list_to_float(S)) < float(1 bsl 53) and that there is an
%% exponent when abs(list_to_float(S)) >= float(1 bsl 53).
g_choice(S) when is_list(S) ->
    ShouldAlwaysHaveExponent = abs(list_to_float(S)) >= float(1 bsl 53),
    HasExponent = lists:member($e, S) orelse lists:member($E, S),
    case ShouldAlwaysHaveExponent of
        true ->
            case HasExponent of
                true -> ok;
                false -> throw(should_have_exponent)
            end;
        false -> g_choice_small(S)
    end.

%% Check that there is an exponent if and only if characters are
%% saved. Note: this assumes floating point numbers "Erlang style"
%% (with a single zero before and after the dot, and no extra leading
%% zero in the exponent).
g_choice_small(S) when is_list(S) ->
    [MS | ES0] = string:tokens(S, "eE"),
    [IS, FS] = string:tokens(MS, "."),
    Il = length(IS),
    Fl = length(FS),
    Pre = z(MS),
    Post = z(lists:reverse(MS)),
    ES = lists:append(ES0),
    El = length(ES),
    I = list_to_integer(IS),
    if
        El =/= 0, ((I > 9) or (I < -9)) ->
            throw(too_many_digits_before_the_dot);
        El =/= 0, I =:= 0 ->
            throw(zero_before_the_dot);
        Pre =:= 0, Post > 0,   El =:= 0 -> % DDDD0000.0
            Saving = if
                         I < 0, Il =:= Post + 2 ->
                             Post;
                         I > 0, Il =:= Post + 1 ->
                             Post;
                         I =/= 0, true ->
                             Post + 1
                     end,
            Cost = 1 + length(integer_to_list(Il - 1)),
            if
                Cost < Saving ->
                    throw(with_exponent_is_shorter);
                true ->
                    ok
            end;
        Pre > 0,   Post =:= 0, El =:= 0 -> % 0.000DDDD
            Saving = if
                         Fl =:= Pre + 1 ->
                             Pre;
                         true ->
                             Pre + 1
                     end,
            Cost = 2 + length(integer_to_list(Pre + 1)),
            if
                Cost < Saving ->
                    throw(with_exponent_is_shorter);
                true ->
                    ok
            end;
        Pre =:= 0, Post =:= 0, El > 0 ->   % D.DDDeDD
            E = list_to_integer(ES),
            if 
                E >= 0 ->
                    Cost = E - (Fl - 1);
                E < 0 ->
                    Cost = -E
            end,
            Saving = length(ES) + 1,
            if
                Cost =:= Saving ->
                    throw(draw_but_choose_form_without_exponent);
                Cost < Saving ->
                    throw(without_exponent_is_shorter);
                true ->
                    ok
            end;
        Pre =:= 0, Post =:= 0, El =:= 0 -> % DDD.DDD
            ok;
        true ->
            throw(badly_formed_floating_point_string)
    end.

z("0."++Ds) ->
    length(lists:takewhile(fun(D) -> D =:= $0 end, Ds));
z(_Ds) ->
    0.

pack(Sign, Exp, Frac) ->
    <<Float:64/float>> = <<Sign:1, Exp:11, Frac:52>>,
    Float.

%% Whitebox test of io_lib:collect_line/3.
io_lib_collect_line_3_wb(Config) when is_list(Config) ->
    do_collect_line(binary, "\n"),
    do_collect_line(binary, "\r\n"),
    do_collect_line(list, "\n"),
    do_collect_line(list, "\r\n"),
    ok.

do_collect_line(Mode, Eol) ->
    First = "abcde",
    FirstNL = First++"\n",
    Second = "unterminated line",
    Data0 = First ++ Eol ++ Second,
    {Data1,Result0} = do_collect_line_combine(Mode, Data0, FirstNL, Second),
    do_collect_line_1(Mode, Data1, Result0, []),

    {Data,Result} = do_collect_line_combine(Mode, "unterm", "unterm", eof),
    do_collect_line_1(Mode, Data, Result, []).

do_collect_line_combine(binary, Data0, FirstNL, eof) ->
    {list_to_binary(Data0),
     {stop,list_to_binary(FirstNL),eof}};
do_collect_line_combine(binary, Data0, FirstNL, Second) ->
    {list_to_binary(Data0),
     {stop,list_to_binary(FirstNL),list_to_binary(Second)}};
do_collect_line_combine(list, Data0, FirstNL, Second) ->
    {Data0,{stop,FirstNL,Second}}.

do_collect_line_1(Mode, [H|T], Result, Acc0) ->
    Acc = [H|Acc0],
    Result = do_collect_line_2(lists:reverse(Acc), T),
    do_collect_line_1(Mode, T, Result, Acc);
do_collect_line_1(Mode, <<H,T/binary>>, Result, Acc0) ->
    Acc = [H|Acc0],
    Result = do_collect_line_2(list_to_binary(lists:reverse(Acc)), T),
    do_collect_line_1(Mode, T, Result, Acc);
do_collect_line_1(_Mode, [], _Result, _Acc) ->
    ok;
do_collect_line_1(_Mode, <<>>, _Result, _Acc) ->
    ok.

do_collect_line_2(Part1, Part2) ->
    Dummy = make_ref(),
    do_collect_line_3(start, [Part1,Part2,eof], Dummy).

do_collect_line_3(State0, [H|T], Dummy) ->
    case io_lib:collect_line(State0, H, Dummy) of
	{stop,Line,Rest} ->
	    {stop,Line,do_collect_line_adjust_rest(Rest, T)};
	State ->
	    do_collect_line_3(State, T, Dummy)
    end.

do_collect_line_adjust_rest(eof, []) -> eof;
do_collect_line_adjust_rest(eof, <<>>) -> eof;
do_collect_line_adjust_rest(Rest, [eof]) -> Rest;
do_collect_line_adjust_rest(Rest, [Bin|T]) when is_binary(Bin) ->
    do_collect_line_adjust_rest(<<Rest/binary,Bin/binary>>, T);
do_collect_line_adjust_rest(Rest, [List|T]) when is_list(List) ->
    do_collect_line_adjust_rest(Rest++List, T).



cr_whitespace_in_string(Config) when is_list(Config) ->
    {ok,["abc"],[]} = io_lib:fread("~s", "\rabc").



io_fread_newlines(Config) when is_list(Config) ->
    PrivDir = ?privdir(Config),
    Fname = filename:join(PrivDir, "io_fread_newlines.txt"),
    F0 = [[0,1,2,3,4,5,6,7,8,9]],
    F1 = [[0,1,2,3,4,5,6,7,8],[9]],
    F2 = [[0,1,2,3,4,5,6,7],[8,9]],
    F3 = [[0,1,2,3,4,5,6],[7,8,9]],
    F4 = [[0,1,2,3,4,5],[6,7,8,9]],
    F5 = [[0,1,2,3,4],[5,6,7,8,9]],
    F6 = [[0,1,2,3],[4,5,6,7],[8,9]],
    F7 = [[0,1,2],[3,4,5],[6,7,8],[9]],
    F8 = [[0,1],[2,3],[4,5],[6,7],[8,9]],
    F9 = [[0],[1],[2],[3],[4],[5],[6],[7],[8],[9]],
    Newlines = ["\n", "\r\n", "\r"],
    try
	io_fread_newlines_1([F0,F1,F2,F3,F4,F5,F6,F7,F8,F9],
				  Fname, Newlines)
    after
	file:delete(Fname)
    end.

io_fread_newlines_1(Fs, Fname, [Newline|Newlines]) ->
    ok = io_fread_newlines_2(Fs, Fname, Newline),
    io_fread_newlines_1(Fs, Fname, Newlines);
io_fread_newlines_1(_, _, []) -> ok.

io_fread_newlines_2([F|Fs], Fname, Newline) ->
    N1 = write_newlines_file(Fname, F, Newline),
    {F2,N2} = read_newlines_file(Fname),
    io:format("~w ~p ~w~n~n", [N1,F,N2]),
    F2 = lists:flatten(F),
    %% Intermediate newlines are not counted
    N2 = N1 - (length(F) - 1)*length(Newline),
    io_fread_newlines_2(Fs, Fname, Newline);
io_fread_newlines_2([], _, _) -> ok.


write_newlines_file(Fname, F, Newline) ->
    Bytes = list_to_binary(digit_lines(F, Newline)),
    io:format("Data: ~w~n~w~n", [Newline,Bytes]),
    ok = file:write_file(Fname, Bytes),
    size(Bytes).

digit_lines([L], _) ->
    digit_line(L);
digit_lines([L|Ls], Newline) ->
    [digit_line(L),Newline|digit_lines(Ls, Newline)].

digit_line([D]) ->
    integer_to_list(D);
digit_line([D|Ds]) ->
    [integer_to_list(D), " ", digit_line(Ds)].

read_newlines_file(Fname) ->
    {ok,Fd} = file:open(Fname, [read]),
    try {L, N0} = R0 = read_newlines(Fd, [], 0),
	case io:fread(Fd, "", "~*s~l") of
	    eof -> R0;
	    {ok,[N]} -> {L,N0+N}
	end
    after
	file:close(Fd)
    end.
    

read_newlines(Fd, Acc, N0) ->
    case io:fread(Fd, "", "~d~l") of
	{ok,[D,N]} ->
	    read_newlines(Fd, [D|Acc], N0+N);
	eof ->
	    {lists:reverse(Acc),N0}
    end.



%% OTP-8989 io:format for ~F.Ps ignores P in some cases.
otp_8989(Suite) when is_list(Suite) ->
    Hello = "Hello",
    " Hello" = fmt("~6.6s", [Hello]),
    " Hello" = fmt("~*.6s", [6,Hello]),
    " Hello" = fmt("~6.*s", [6,Hello]),
    " Hello" = fmt("~*.*s", [6,6,Hello]),
    %%
    " Hello" = fmt("~6.5s", [Hello]),
    " Hello" = fmt("~*.5s", [6,Hello]),
    " Hello" = fmt("~6.*s", [5,Hello]),
    " Hello" = fmt("~*.*s", [6,5,Hello]),
    %%
    "  Hell" = fmt("~6.4s", [Hello]),
    "  Hell" = fmt("~*.4s", [6,Hello]),
    "  Hell" = fmt("~6.*s", [4,Hello]),
    "  Hell" = fmt("~*.*s", [6,4,Hello]),
    %%
    "Hello" = fmt("~5.5s", [Hello]),
    "Hello" = fmt("~*.5s", [5,Hello]),
    "Hello" = fmt("~5.*s", [5,Hello]),
    "Hello" = fmt("~*.*s", [5,5,Hello]),
    %%
    " Hell" = fmt("~5.4s", [Hello]),
    " Hell" = fmt("~*.4s", [5,Hello]),
    " Hell" = fmt("~5.*s", [4,Hello]),
    " Hell" = fmt("~*.*s", [5,4,Hello]),
    %%
    "Hell" = fmt("~4.4s", [Hello]),
    "Hell" = fmt("~*.4s", [4,Hello]),
    "Hell" = fmt("~4.*s", [4,Hello]),
    "Hell" = fmt("~*.*s", [4,4,Hello]),
    %%
    " Hel" = fmt("~4.3s", [Hello]),
    " Hel" = fmt("~*.3s", [4,Hello]),
    " Hel" = fmt("~4.*s", [3,Hello]),
    " Hel" = fmt("~*.*s", [4,3,Hello]),
    %%
    %%
    "Hello " = fmt("~-6.6s", [Hello]),
    "Hello " = fmt("~*.6s", [-6,Hello]),
    "Hello " = fmt("~-6.*s", [6,Hello]),
    "Hello " = fmt("~*.*s", [-6,6,Hello]),
    %%
    "Hello " = fmt("~-6.5s", [Hello]),
    "Hello " = fmt("~*.5s", [-6,Hello]),
    "Hello " = fmt("~-6.*s", [5,Hello]),
    "Hello " = fmt("~*.*s", [-6,5,Hello]),
    %%
    "Hell  " = fmt("~-6.4s", [Hello]),
    "Hell  " = fmt("~*.4s", [-6,Hello]),
    "Hell  " = fmt("~-6.*s", [4,Hello]),
    "Hell  " = fmt("~*.*s", [-6,4,Hello]),
    %%
    "Hello" = fmt("~-5.5s", [Hello]),
    "Hello" = fmt("~*.5s", [-5,Hello]),
    "Hello" = fmt("~-5.*s", [5,Hello]),
    "Hello" = fmt("~*.*s", [-5,5,Hello]),
    %%
    "Hell " = fmt("~-5.4s", [Hello]),
    "Hell " = fmt("~*.4s", [-5,Hello]),
    "Hell " = fmt("~-5.*s", [4,Hello]),
    "Hell " = fmt("~*.*s", [-5,4,Hello]),
    %%
    "Hell" = fmt("~-4.4s", [Hello]),
    "Hell" = fmt("~*.4s", [-4,Hello]),
    "Hell" = fmt("~-4.*s", [4,Hello]),
    "Hell" = fmt("~*.*s", [-4,4,Hello]),
    %%
    "Hel " = fmt("~-4.3s", [Hello]),
    "Hel " = fmt("~*.3s", [-4,Hello]),
    "Hel " = fmt("~-4.*s", [3,Hello]),
    "Hel " = fmt("~*.*s", [-4,3,Hello]),
    ok.

%% OTP-9439 io_lib:fread bug for literate at end.
io_lib_fread_literal(Suite) when is_list(Suite) ->
    {more,"~d",0,""} = io_lib:fread("~d", ""),
    {error,{fread,integer}} = io_lib:fread("~d", " "),
    {more,"~d",1,""} = io_lib:fread(" ~d", " "),
    {ok,[17],"X"} = io_lib:fread(" ~d", " 17X"),
    %%
    {more,"d",0,""} = io_lib:fread("d", ""),
    {error,{fread,input}} = io_lib:fread("d", " "),
    {more,"d",1,""} = io_lib:fread(" d", " "),
    {ok,[],"X"} = io_lib:fread(" d", " dX"),
    %%
    {done,eof,_} = io_lib:fread([], eof, "~d"),
    {done,eof,_} = io_lib:fread([], eof, " ~d"),
    {more,C1} = io_lib:fread([], " \n", " ~d"),
    {done,{error,{fread,input}},_} = io_lib:fread(C1, eof, " ~d"),
    {done,{ok,[18]},""} = io_lib:fread(C1, "18\n", " ~d"),
    %%
    {done,eof,_} = io_lib:fread([], eof, "d"),
    {done,eof,_} = io_lib:fread([], eof, " d"),
    {more,C2} = io_lib:fread([], " \n", " d"),
    {done,{error,{fread,input}},_} = io_lib:fread(C2, eof, " d"),
    {done,{ok,[]},[]} = io_lib:fread(C2, "d\n", " d"),
    ok.


%% Check that the printable range set by the user actually works.
printable_range(Suite) when is_list(Suite) ->
    {ok, UPeer0, UNode0} = ?CT_PEER(["+pc", "unicode"]),
    {ok, LPeer0, LNode0} = ?CT_PEER(["+pc", "latin1"]),
    {ok, DPeer, DNode} = ?CT_PEER(),
    unicode = rpc:call(UNode0,io,printable_range,[]),
    latin1 = rpc:call(LNode0,io,printable_range,[]),
    latin1 = rpc:call(DNode,io,printable_range,[]),
    peer:stop(UPeer0),
    peer:stop(LPeer0),
    {ok, UPeer, UNode} = ?CT_PEER(["+pcunicode"]),
    {ok, LPeer, LNode} = ?CT_PEER(["+pclatin1"]),
    unicode = rpc:call(UNode,io,printable_range,[]),
    latin1 = rpc:call(LNode,io,printable_range,[]),
    PrettyOptions = [{column,1},
		     {line_length,109},
		     {depth,30},
		     {line_max_chars,60},
		     {record_print_fun,
		      fun(_,_) -> no end},
		     {encoding,unicode}],
    PrintableControls = "\t\v\b\f\e\r\n",

    1025 = print_max(UNode, [{hello, [1024,1025]},
			     PrettyOptions]),
    125 = print_max(LNode,  [{hello, [1024,1025]},
			     PrettyOptions]),
    125 = print_max(DNode,  [{hello, [1024,1025]},
			     PrettyOptions]),
    1025 = print_max(UNode, [{hello, <<1024/utf8,1025/utf8>>},
			     PrettyOptions]),
    125 = print_max(LNode,  [{hello, <<1024/utf8,1025/utf8>>},
			     PrettyOptions]),
    125 = print_max(DNode,  [{hello, <<1024/utf8,1025/utf8>>},
			     PrettyOptions]),
    $v = print_max(UNode, [PrintableControls,PrettyOptions]),
    $v = print_max(LNode, [PrintableControls,PrettyOptions]),
    $v = print_max(DNode, [PrintableControls,PrettyOptions]),
    16#10FFFF = print_max(UNode,
			  [<<16#10FFFF/utf8,"\t\v\b\f\e\r\n">>,
			   PrettyOptions]),
    $> = print_max(LNode,
		   [<<16#10FFFF/utf8,"\t\v\b\f\e\r\n">>,
		    PrettyOptions]),
    $> = print_max(DNode,
		   [<<16#10FFFF/utf8,"\t\v\b\f\e\r\n">>,
		    PrettyOptions]),

    1025 = format_max(UNode, ["~tp", [{hello, [1024,1025]}]]),
    125 = format_max(LNode,  ["~tp", [{hello, [1024,1025]}]]),
    125 = format_max(DNode,  ["~tp", [{hello, [1024,1025]}]]),
    1025 = format_max(UNode, ["~tp", [{hello, <<1024/utf8,1025/utf8>>}]]),
    125 = format_max(LNode,  ["~tp", [{hello, <<1024/utf8,1025/utf8>>}]]),
    125 = format_max(DNode,  ["~tp", [{hello, <<1024/utf8,1025/utf8>>}]]),

    $\e = format_max(UNode, ["~ts", [PrintableControls]]),
    $\e = format_max(LNode, ["~ts", [PrintableControls]]),
    $\e = format_max(DNode, ["~ts", [PrintableControls]]),

    peer:stop(UPeer),
    peer:stop(LPeer),
    peer:stop(DPeer),
    ok.

print_max(Node, Args) ->
    rpc_call_max(Node, io_lib_pretty, print, Args).

format_max(Node, Args) ->
    rpc_call_max(Node, io_lib, format, Args).

rpc_call_max(Node, io_lib_pretty=M, print=F, [A1,A2]=Args) ->
    BinAs = [A1, maps:from_list(A2)],
    Orig = lists:flatten(rpc:call(Node, M, print, Args)),
    try
        {Utf8, _, _} = rpc:call(Node, M, print_bin, BinAs),
        true = is_binary(Utf8),
        case unicode:characters_to_list(Utf8) of
            Orig ->
                lists:max(Orig);
            Other ->
                io:format("Exp: ~w~nGot: ~w~n", [Orig, Other]),
                io:format("Binary failed:~n~w:~w(~0p). ", [M, print_bin, BinAs]),
                Utf8
        end
    catch _:Reason:ST ->
            io:format("Exp: ~w~n~n", [Orig]),
            io:format("GOT CRASH: ~p in ~p~n",[Reason, ST]),
            io:format("Binary crashed: ~w:~w(~0p). ", [M, print_bin, BinAs]),
            Reason
    end;
rpc_call_max(Node, M, format=F, Args) ->
    {BinF,BinAs} = {bformat, Args},
    Orig = lists:flatten(rpc:call(Node, M, F, Args)),
    try
        Utf8 = rpc:call(Node, M, BinF, BinAs),
        true = is_binary(Utf8),
        case unicode:characters_to_list(Utf8) of
            Orig ->
                lists:max(Orig);
            Other ->
                io:format("Exp: ~w~nGot: ~w~n", [Orig, Other]),
                io:format("Binary failed:~n~w:~w(~0p). ", [M, BinF, BinAs]),
                Utf8
        end
    catch _:Reason:ST ->
            io:format("Exp: ~w~n~n", [Orig]),
            io:format("GOT CRASH: ~p in ~p~n",[Reason, ST]),
            io:format("Binary crashed: ~w:~w(~0p). ", [M, BinF, BinAs]),
            Reason
    end.


%% Make sure that a bad specification for a printable range is rejected.
bad_printable_range(Config) when is_list(Config) ->
    Cmd = ct:get_progname() ++ " +pcunnnnnicode -run erlang halt",
    P = open_port({spawn, Cmd}, [stderr_to_stdout, {line, 200}]),
    ok = receive
             {P, {data, {eol , "bad range of printable characters" ++ _}}} ->
                 ok;
             Other ->
                 Other
         %% valgrind needs a lot of time
         after 6000 ->
                   timeout
         end,
    catch port_close(P),
    flush_from_port(P),
    ok.

flush_from_port(P) ->
    receive {P, _} ->
	    flush_from_port(P)
    after 0 ->
	    ok
    end.

%% Test binaries printed with a depth of one behave correctly.
io_lib_print_binary_depth_one(Suite) when is_list(Suite) ->
    "<<>>" = fmt("~W", [<<>>, 1]),
    "<<>>" = fmt("~P", [<<>>, 1]),
    "<<...>>" = fmt("~W", [<<1>>, 1]),
    "<<...>>" = fmt("~P", [<<1>>, 1]),
    "<<...>>" = fmt("~W", [<<1:7>>, 1]),
    "<<...>>" = fmt("~P", [<<1:7>>, 1]),
    ok.

%% OTP-10302. Unicode.
otp_10302(Suite) when is_list(Suite) ->
    {ok, UPeer, UNode} = ?CT_PEER(["+pc", "unicode"]),
    {ok, LPeer, LNode} = ?CT_PEER(["+pc", "latin1"]),
    "\"\x{400}\"" = rpc:call(UNode,?MODULE,pretty,["\x{400}", -1]),
    "<<\"\x{400}\"/utf8>>" = rpc:call(UNode,?MODULE,pretty,
				      [<<"\x{400}"/utf8>>, -1]),

    "<<\"\x{400}foo\"/utf8>>" = rpc:call(UNode,?MODULE,pretty,
					 [<<"\x{400}foo"/utf8>>, 2]),
    "[1024]" = rpc:call(LNode,?MODULE,pretty,["\x{400}", -1]),
    "<<208,128>>" = rpc:call(LNode,?MODULE,pretty,[<<"\x{400}"/utf8>>, -1]),

    "<<208,...>>" = rpc:call(LNode,?MODULE,pretty,[<<"\x{400}foo"/utf8>>, 2]),
    peer:stop(UPeer),
    peer:stop(LPeer),

    "<<\"äppl\"/utf8>>" = pretty(<<"äppl"/utf8>>, 2),
    "<<\"äppl\"/utf8...>>" = pretty(<<"äpple"/utf8>>, 2),
    "<<\"apel\">>" = pretty(<<"apel">>, 2),
    "<<\"apel\"...>>" = pretty(<<"apelsin">>, 2),
    "═Ω <<\"äppl\">>" = fmt("═Ω ~tp", [<<"äppl">>]),
    "═Ω <<\"äppl\"...>>" = fmt("═Ω ~tP", [<<"äpple">>, 2]),
    "═Ω <<0,0,0,0,0,0,1,0>>" = fmt("═Ω ~p", [<<256:64/unsigned-integer>>]),
    "═Ω <<0,0,0,0,0,0,1,0>>" = fmt("═Ω ~tp", [<<256:64/unsigned-integer>>]),

    Chars = lists:seq(0, 512), % just a few...
    [] = [C || C <- Chars, S <- io_lib:write_char_as_latin1(C),
               not is_latin1(S)],
    L1 = [S || C <- Chars, S <- io_lib:write_char(C),
               not is_latin1(S)],
    L1 = lists:seq(256, 512),

    [] = [C || C <- Chars, S <- io_lib:write_string_as_latin1([C]),
               not is_latin1(S)],
    L2 = [S || C <- Chars, S <- io_lib:write_string([C]),
               not is_latin1(S)],
    L2 = lists:seq(256, 512),

    ok.

pretty(Term, Depth) when is_integer(Depth) ->
    Opts = [{column, 1}, {line_length, 20},
            {depth, Depth}, {line_max_chars, 60},
            {record_print_fun, fun rfd/2},
            {encoding, unicode}],
    pretty(Term, Opts);
pretty(Term, Opts) when is_list(Opts) ->
    R = io_lib_pretty:print(Term, Opts),
    RF = lists:flatten(R),
    RF = check_bin_p(RF, Term, Opts),
    fmt("~ts", [R]).

is_latin1(S) ->
    S >= 0 andalso S =< 255.

%% OTP-10836. ~ts extended to latin1.
otp_10836(Suite) when is_list(Suite) ->
    S = fmt("~ts", [[<<"äpple"/utf8>>, <<"äpple">>]]),
    "äppleäpple" = lists:flatten(S),
    ok.

%% OTP-10755. The 'l' modifier
otp_10755(Suite) when is_list(Suite) ->
    %% printing plain ascii characters
    S = "string",
    "\"string\"" = fmt("~p", [S]),
    "[115,116,114,105,110,103]" = fmt("~lp", [S]),
    "\"string\"" = fmt("~P", [S, 2]),
    "[115|...]" = fmt("~lP", [S, 2]),
    %% printing latin1 chars, with and without modifiers
    T = {[255],list_to_atom([255]),[a,b,c]},
    "{\"ÿ\",ÿ,[a,b,c]}" = fmt("~p", [T]),
    "{\"ÿ\",ÿ,[a,b,c]}" = fmt("~tp", [T]),
    "{[255],ÿ,[a,b,c]}" = fmt("~lp", [T]),
    "{[255],ÿ,[a,b,c]}" = fmt("~ltp", [T]),
    "{[255],ÿ,[a,b,c]}" = fmt("~tlp", [T]),
    "{\"ÿ\",ÿ,...}" = fmt("~P", [T,3]),
    "{\"ÿ\",ÿ,...}" = fmt("~tP", [T,3]),
    "{[255],ÿ,...}" = fmt("~lP", [T,3]),
    "{[255],ÿ,...}" = fmt("~ltP", [T,3]),
    "{[255],ÿ,...}" = fmt("~tlP", [T,3]),
    %% printing unicode chars, with and without modifiers
    U = {[666],list_to_atom([666]),[a,b,c]},
    "{[666],'\\x{29A}',[a,b,c]}" = fmt("~p", [U]),
    case io:printable_range() of
        unicode ->
            "{\"ʚ\",'ʚ',[a,b,c]}" = fmt("~tp", [U]),
            "{\"ʚ\",'ʚ',...}" = fmt("~tP", [U,3]);
        latin1 ->
            "{[666],'ʚ',[a,b,c]}" = fmt("~tp", [U]),
            "{[666],'ʚ',...}" = fmt("~tP", [U,3])
    end,
    "{[666],'\\x{29A}',[a,b,c]}" = fmt("~lp", [U]),
    "{[666],'ʚ',[a,b,c]}" = fmt("~ltp", [U]),
    "{[666],'ʚ',[a,b,c]}" = fmt("~tlp", [U]),
    "{[666],'\\x{29A}',...}" = fmt("~P", [U,3]),
    "{[666],'\\x{29A}',...}" = fmt("~lP", [U,3]),
    "{[666],'ʚ',...}" = fmt("~ltP", [U,3]),
    "{[666],'ʚ',...}" = fmt("~tlP", [U,3]),
    %% the compiler should catch uses of ~l with other than pP
    Text =
        "-module(l_mod).\n"
        "-export([t/0]).\n"
        "t() ->\n"
        "    S = \"string\",\n"
        "    io:format(\"~lw\", [S]),\n"
        "    io:format(\"~lW\", [S, 1]),\n"
        "    io:format(\"~ltw\", [S]),\n"
        "    io:format(\"~tlw\", [S]),\n"
        "    io:format(\"~ltW\", [S, 1]),\n"
        "    io:format(\"~tlW\", [S, 1]),\n"
        "    io:format(\"~ltp\", [S, 1]).\n",
    {ok,l_mod,[{_File,Ws}]} = compile_file("l_mod.erl", Text, Suite),
    ["format string invalid (invalid modifier/control combination ~lw)",
     "format string invalid (invalid modifier/control combination ~lW)",
     "format string invalid (invalid modifier/control combination ~lw)",
     "format string invalid (invalid modifier/control combination ~lw)",
     "format string invalid (invalid modifier/control combination ~lW)",
     "format string invalid (invalid modifier/control combination ~lW)",
     "format string invalid (conflicting modifiers ~ltp)"] =
        [lists:flatten(M:format_error(E)) || {_L,M,E} <- Ws],
    ok.

compile_file(File, Text, Config) ->
    PrivDir = ?privdir(Config),
    Fname = filename:join(PrivDir, File),
    ok = file:write_file(Fname, Text),
    try compile:file(Fname, [return])
    after ok %file:delete(Fname)
    end.

io_lib_width_too_small(_Config) ->
    "**" = fmt("~2.3w", [3.14]),
    "**" = fmt("~2.5w", [3.14]),
    ok.

%% Test that the time for a huge message queue is not
%% significantly slower than with an empty message queue.
io_with_huge_message_queue(Config) when is_list(Config) ->
    case test_server:is_cover() of
	true ->
	    {skip,"Running under cover"};
	false ->
	    do_io_with_huge_message_queue(Config)
    end.

do_io_with_huge_message_queue(Config) ->
    PrivDir = ?privdir(Config),
    File = filename:join(PrivDir, "slask"),
    {ok, F1} = file:open(File, [write]),
    Test = fun(Times) ->
		   {Time,ok} = timer:tc(fun() -> writes(Times, F1) end),
		   Time
	   end,
    {Times,EmptyTime} = calibrate(100, Test),

    [self() ! {msg,N} || N <- lists:seq(1, 500000)],
    erlang:garbage_collect(),
    FullTime = Test(Times),
    file:close(F1),
    file:delete(File),
    io:format("Number of writes: ~p", [Times]),
    io:format("Time for empty message queue: ~p", [EmptyTime]),
    io:format("Time for huge message queue: ~p", [FullTime]),

    case (FullTime+1) / (EmptyTime+1) of
	Q when Q < 10 ->
	    ok;
	Q ->
	    io:format("Q = ~p", [Q]),
	    ct:fail(failed)
    end,
    ok.

%% Make sure that the time is not too short. That could cause the
%% test case to fail.
calibrate(N, Test) when N =< 100000 ->
    case Test(N) of
	Time when Time < 50000 ->
	    calibrate(10*N, Test);
	Time ->
	    {N,Time}
    end;
calibrate(N, _) ->
    N.

writes(0, _) -> ok;
writes(N, F1) ->
    file:write(F1, "hello\n"),
    writes(N - 1, F1).

format_string(_Config) ->
    %% All but padding is tested by fmt/2.
    "xxxxxxxsss" = fmt("~10..xs", ["sss"]),
    "xxxxxxsssx" = fmt("~10.4.xs", ["sss"]),
    "xxxxxxsssx" = fmt("~10.4.*s", [$x, "sss"]),
    ok.

maps(_Config) ->
    %% Note that order in which a map is printed is arbitrary.
    %% Therefore, play it completely safe by not assuming any order
    %% in a map with more than one element.

    AOrdCmpFun = fun(A, B) -> A =< B end,
    ARevCmpFun = fun(A, B) -> B < A end,

    AtomMap1 = #{a => b},
    AtomMap2 = #{a => b, c => d},
    AtomMap3 = #{a => b, c => d, e => f},

    "#{}" = fmt("~w", [#{}]),
    "#{a => b}" = fmt("~w", [AtomMap1]),
    re_fmt(<<"#\\{(a => b|c => d),[.][.][.]\\}">>,
	     "~W", [AtomMap2, 2]),
    re_fmt(<<"#\\{(a => b|c => d|e => f),[.][.][.]\\}">>,
	   "~W", [AtomMap3, 2]),
    "#{a => b,c => d,e => f}" = fmt("~kw", [AtomMap3]),
    re_fmt(<<"#\\{(a => b|c => d|e => f),[.][.][.]\\}">>,
           "~KW", [undefined, AtomMap3, 2]),
    "#{a => b,c => d,e => f}" = fmt("~Kw", [ordered, AtomMap3]),
    "#{e => f,c => d,a => b}" = fmt("~Kw", [reversed, AtomMap3]),
    "#{a => b,c => d,e => f}" = fmt("~Kw", [AOrdCmpFun, AtomMap3]),
    "#{e => f,c => d,a => b}" = fmt("~Kw", [ARevCmpFun, AtomMap3]),

    "#{}" = fmt("~p", [#{}]),
    "#{a => b}" = fmt("~p", [AtomMap1]),
    "#{...}" = fmt("~P", [AtomMap1, 1]),
    re_fmt(<<"#\\{(a => b|c => d),[.][.][.]\\}">>,
	   "~P", [AtomMap2, 2]),
    re_fmt(<<"#\\{(a => b|c => d|e => f),[.][.][.]\\}">>,
	   "~P", [AtomMap3, 2]),
    "#{a => b,c => d,e => f}" = fmt("~kp", [AtomMap3]),
    re_fmt(<<"#\\{(a => b|c => d|e => f),[.][.][.]\\}">>,
           "~KP", [undefined, AtomMap3, 2]),
    "#{a => b,c => d,e => f}" = fmt("~Kp", [ordered, AtomMap3]),
    "#{e => f,c => d,a => b}" = fmt("~Kp", [reversed, AtomMap3]),
    "#{a => b,c => d,e => f}" = fmt("~Kp", [AOrdCmpFun, AtomMap3]),
    "#{e => f,c => d,a => b}" = fmt("~Kp", [ARevCmpFun, AtomMap3]),

    List = [{I, I * I} || I <- lists:seq(1, 64)],
    Map = maps:from_list(List),

    "#{...}" = fmt("~P", [Map, 1]),
    "#{1 => 1,...}" = fmt("~kP", [Map, 2]),
    "#{1 => 1,...}" = fmt("~KP", [ordered, Map, 2]),
    "#{64 => 4096,...}" = fmt("~KP", [reversed, Map, 2]),
    "#{1 => 1,...}" = fmt("~KP", [AOrdCmpFun, Map, 2]),
    "#{64 => 4096,...}" = fmt("~KP", [ARevCmpFun, Map, 2]),

    FloatIntegerMap = #{-1.0 => a, 0.0 => b, -1 => c, 0 => d},
    re_fmt(<<"#\\{(-1.0 => a|0.0 => b|-1 => c|0 => d),[.][.][.]\\}">>,
           "~P", [FloatIntegerMap, 2]),
    "#{-1 => c,0 => d,-1.0 => a,0.0 => b}" = fmt("~kp", [FloatIntegerMap]),
    re_fmt(<<"#\\{(-1.0 => a|0.0 => b|-1 => c|0 => d),[.][.][.]\\}">>,
           "~KP", [undefined, FloatIntegerMap, 2]),
    "#{-1 => c,0 => d,-1.0 => a,0.0 => b}" = fmt("~Kp", [ordered, FloatIntegerMap]),
    "#{0.0 => b,-1.0 => a,0 => d,-1 => c}" = fmt("~Kp", [reversed, FloatIntegerMap]),

    %% Print a map and parse it back to a map.
    S = fmt("~p\n", [Map]),
    io:format("~p\n", [S]),
    Map = parse_map(S),

    %% Smoke test of a map as key.
    MapAsKey = #{Map => "value"},
    io:format("~s\n", [fmt("~p", [MapAsKey])]),
    ok.

re_fmt(Pattern, Format, Args) ->
    S = list_to_binary(fmt(Format, Args)),
    case re:run(S, Pattern, [{capture,none}]) of
	nomatch ->
	    io:format("Pattern: ~s", [Pattern]),
	    io:format("Result:  ~s", [S]),
	    ct:fail(failed);
	match ->
	    ok
    end.

%% Parse a map consisting of integer keys and values.
parse_map(S0) ->
    S1 = parse_expect(S0, "#{"),
    {M,S2} = parse_map_1(S1),
    S = parse_expect(S2, "}"),
    S = "",
    M.

parse_map_1(S0) ->
    {Key,S1} = parse_number(S0),
    S2 = parse_expect(S1, "=>"),
    {Val,S3} = parse_number(S2),
    case S3 of
	","++S4 ->
	    S5 = parse_skip_ws(S4),
	    {Map,S} = parse_map_1(S5),
	    {Map#{Key=>Val},S};
	S ->
	    {#{Key=>Val},S}
    end.

parse_number(S) ->
    parse_number(S, none).

parse_number([C|S], Acc0) when $0 =< C, C =< $9 ->
    Acc = case Acc0 of
	      none -> 0;
	      _ when is_integer(Acc0) -> Acc0
	  end,
    parse_number(S, Acc*10+C-$0);
parse_number(S, Acc) ->
    {Acc,parse_skip_ws(S)}.

parse_expect([H|T1], [H|T2]) ->
    parse_expect(T1, T2);
parse_expect(S, []) ->
    parse_skip_ws(S).

parse_skip_ws([C|S]) when C =< $\s ->
    parse_skip_ws(S);
parse_skip_ws(S) ->
    S.

%% Cover the last uncovered lines for completeness.
coverage(_Config) ->
    S1 = io_lib_pretty:print({a,term}, fun(_, _) -> no end),
    io:format("~s\n", [S1]),

    %% The tuple of arity three will be ignored.
    S2 = io_lib_pretty:print(lists:seq(1, 100), [{depth,1,1}]),
    io:format("~s\n", [S2]),

    ok.

%% Test UTF-8 atoms.
otp_14178_unicode_atoms(_Config) ->
    "atom" = fmt("~ts", ['atom']),
    "кирилли́ческий атом" = fmt("~ts", ['кирилли́ческий атом']),
    [16#10FFFF] = fmt("~ts", ['\x{10FFFF}']),

    %% ~s must not accept code points greater than 255.
    bad_io_lib_format("~s", ['\x{100}']),
    bad_io_lib_format("~s", ['кирилли́ческий атом']),

    ok.

bad_io_lib_format(F, S) ->
    try io_lib:format(F, S) of
        _ -> ct:fail({should_fail,F,S})
    catch error:badarg -> ok
    end,
    try io_lib:bformat(F, S) of
        _ -> ct:fail({should_fail,F,S})
    catch error:badarg -> ok
    end.

otp_14175(_Config) ->
    "..." = p(#{}, 0),
    "#{}" = p(#{}, 1),
    "#{...}" = p(#{a => 1}, 1),
    "#{#{} => a}" = p(#{#{} => a}, 2),
    mt("#{a => 1,...}", p(#{a => 1, b => 2}, 2)),
    mt("#{a => 1,b => 2}", p(#{a => 1, b => 2}, -1)),

    M = #{kaaaaaaaaaaaaaaaaaaa => v1,kbbbbbbbbbbbbbbbbbbb => v2,
          kccccccccccccccccccc => v3,kddddddddddddddddddd => v4,
          keeeeeeeeeeeeeeeeeee => v5},
    "#{...}" = p(M, 1),
    mt("#{kaaaaaaaaaaaaaaaaaaaa => v1,...}", p(M, 2)),
    mt("#{kaaaaaaaaaaaaaaaaaaaa => 1,kbbbbbbbbbbbbbbbbbbbb => 2,...}",
       p(M, 3)),

    mt("#{kaaaaaaaaaaaaaaaaaaa => v1,kbbbbbbbbbbbbbbbbbbb => v2,\n"
       "  kccccccccccccccccccc => v3,...}", p(M, 4)),

    mt("#{kaaaaaaaaaaaaaaaaaaa => v1,kbbbbbbbbbbbbbbbbbbb => v2,\n"
       "  kccccccccccccccccccc => v3,kddddddddddddddddddd => v4,...}",
       p(M, 5)),

    mt("#{kaaaaaaaaaaaaaaaaaaa => v1,kbbbbbbbbbbbbbbbbbbb => v2,\n"
       "  kccccccccccccccccccc => v3,kddddddddddddddddddd => v4,\n"
       "  keeeeeeeeeeeeeeeeeee => v5}", p(M, 6)),

    weak("#{aaaaaaaaaaaaaaaaaaa => 1,bbbbbbbbbbbbbbbbbbbb => 2,\n"
         "  cccccccccccccccccccc => {3},\n"
         "  dddddddddddddddddddd => 4,eeeeeeeeeeeeeeeeeeee => 5}",
       p(#{aaaaaaaaaaaaaaaaaaa => 1,bbbbbbbbbbbbbbbbbbbb => 2,
           cccccccccccccccccccc => {3},
           dddddddddddddddddddd => 4,eeeeeeeeeeeeeeeeeeee => 5}, -1)),

    M2 = #{dddddddddddddddddddd => {1}, {aaaaaaaaaaaaaaaaaaaa} => 2,
           {bbbbbbbbbbbbbbbbbbbb} => 3,{cccccccccccccccccccc} => 4,
           {eeeeeeeeeeeeeeeeeeee} => 5},
    "#{...}" = p(M2, 1),
    weak("#{dddddddddddddddddddd => {...},...}", p(M2, 2)),
    weak("#{dddddddddddddddddddd => {1},{...} => 2,...}", p(M2, 3)),

    weak("#{dddddddddddddddddddd => {1},\n"
         "  {aaaaaaaaaaaaaaaaaaaa} => 2,\n"
         "  {...} => 3,...}", p(M2, 4)),

    weak("#{dddddddddddddddddddd => {1},\n"
         "  {aaaaaaaaaaaaaaaaaaaa} => 2,\n"
         "  {bbbbbbbbbbbbbbbbbbbb} => 3,\n"
         "  {...} => 4,...}", p(M2, 5)),

    weak("#{dddddddddddddddddddd => {1},\n"
         "  {aaaaaaaaaaaaaaaaaaaa} => 2,\n"
         "  {bbbbbbbbbbbbbbbbbbbb} => 3,\n"
         "  {cccccccccccccccccccc} => 4,\n"
         "  {...} => 5}", p(M2, 6)),

    weak("#{dddddddddddddddddddd => {1},\n"
         "  {aaaaaaaaaaaaaaaaaaaa} => 2,\n"
         "  {bbbbbbbbbbbbbbbbbbbb} => 3,\n"
         "  {cccccccccccccccccccc} => 4,\n"
         "  {eeeeeeeeeeeeeeeeeeee} => 5}", p(M2, 7)),

    M3 = #{kaaaaaaaaaaaaaaaaaaa => vuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu,
           kbbbbbbbbbbbbbbbbbbb => vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv,
           kccccccccccccccccccc => vxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,
           kddddddddddddddddddd => vyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy,
           keeeeeeeeeeeeeeeeeee => vzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz},

    mt("#{aaaaaaaaaaaaaaaaaaaa =>\n"
       "      uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu,\n"
       "  bbbbbbbbbbbbbbbbbbbb =>\n"
       "      vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv,\n"
       "  cccccccccccccccccccc =>\n"
       "      xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,\n"
       "  dddddddddddddddddddd =>\n"
       "      yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy,\n"
       "  eeeeeeeeeeeeeeeeeeee =>\n"
       "      zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz}", p(M3, -1)),

    R4 = {c,{c,{c,{c,{c,{c,{c,{c,{c,{c,{c,{c,a,b},b},b},b},b},b},
			 b},b},b},b},b},b},
    M4 = #{aaaaaaaaaaaaaaaaaaaa => R4,
           bbbbbbbbbbbbbbbbbbbb => R4,
           cccccccccccccccccccc => R4,
           dddddddddddddddddddd => R4,
           eeeeeeeeeeeeeeeeeeee => R4},

    weak("#{aaaaaaaaaaaaaaaaaaaa =>\n"
         "      #c{f1 = #c{f1 = #c{...},f2 = b},f2 = b},\n"
         "  bbbbbbbbbbbbbbbbbbbb => #c{f1 = #c{f1 = {...},...},f2 = b},\n"
         "  cccccccccccccccccccc => #c{f1 = #c{...},f2 = b},\n"
         "  dddddddddddddddddddd => #c{f1 = {...},...},\n"
         "  eeeeeeeeeeeeeeeeeeee => #c{...}}", p(M4, 7)),

    M5 = #{aaaaaaaaaaaaaaaaaaaa => R4},
    mt("#{aaaaaaaaaaaaaaaaaaaa =>\n"
       "   #c{\n"
       "    f1 =\n"
       "     #c{\n"
       "      f1 =\n"
       "       #c{\n"
       "        f1 =\n"
       "         #c{\n"
       "          f1 =\n"
       "           #c{\n"
       "            f1 =\n"
       "             #c{\n"
       "              f1 =\n"
       "               #c{\n"
       "                f1 =\n"
       "                 #c{\n"
       "                  f1 =\n"
       "                   #c{\n"
       "                    f1 = #c{f1 = #c{f1 = #c{f1 = a,f2 = b},f2 = b},"
                                        "f2 = b},\n"
       "                    f2 = b},\n"
       "                  f2 = b},\n"
       "                f2 = b},\n"
       "              f2 = b},\n"
       "            f2 = b},\n"
       "          f2 = b},\n"
       "        f2 = b},\n"
       "      f2 = b},\n"
       "    f2 = b}}", p(M5, -1)),
    ok.

%% Just check number of newlines and dots ('...').
-define(WEAK, true).

-ifdef(WEAK).

weak(S, R) ->
    (nl(S) =:= nl(R) andalso
     dots(S) =:= dots(S)).

nl(S) ->
    [C || C <- S, C =:= $\n].

dots(S) ->
    [C || C <- S, C =:= $\.].

-else. % WEAK

weak(S, R) ->
    mt(S, R).

-endif. % WEAK

%% If EXACT is defined: mt() matches strings exactly.
%%
%% if EXACT is not defined: do not match the strings exactly, but
%% compare them assuming that all map keys and all map values are
%% equal (by assuming all map keys and all map values have the same
%% length and begin with $k and $v respectively).

%-define(EXACT, true).

-ifdef(EXACT).

mt(S, R) ->
    S =:= R.

-else. % EXACT

mt(S, R) ->
    anon(S) =:= anon(R).

anon(S) ->
    {ok, Ts0, _} = erl_scan:string(S, 1, [text]),
    Ts = anon1(Ts0),
    text(Ts).

anon1([]) -> [];
anon1([{atom,Anno,Atom}=T|Ts]) ->
    case erl_anno:text(Anno) of
        "k" ++ _ ->
            NewAnno = erl_anno:set_text("key", Anno),
            [{atom,NewAnno,Atom}|anon1(Ts)];
        "v" ++ _ ->
            NewAnno = erl_anno:set_text("val", Anno),
            [{atom,NewAnno,Atom}|anon1(Ts)];
        _ ->
            [T|anon1(Ts)]
    end;
anon1([T|Ts]) ->
    [T|anon1(Ts)].

text(Ts) ->
    lists:append(text1(Ts)).

text1([]) -> [];
text1([T|Ts]) ->
    Anno = element(2, T),
    [erl_anno:text(Anno) | text1(Ts)].

-endif. % EXACT

otp_14285(_Config) ->
    UOpts = [{record_print_fun, fun rfd/2},
             {encoding, unicode}],
    LOpts = [{record_print_fun, fun rfd/2},
             {encoding, latin1}],

    RT = {'\x{400}','\x{400}'},
    "#'\x{400}'{'\x{400}' = '\x{400}'}" = pretty(RT, UOpts),
    "#'\\x{400}'{'\\x{400}' = '\\x{400}'}" = pretty(RT, LOpts),

    Chars = lists:seq(0, 512),
    [] = [C ||
             C <- Chars,
             S <- io_lib:write_atom_as_latin1(list_to_atom([C])),
             not is_latin1(S)],
    L1 = [S || C <- Chars, S <- io_lib:write_atom(list_to_atom([C])),
               not is_latin1(S)],
    L1 = lists:seq(256, 512),

    latin1_fmt("~w", ['кирилли́ческий атом']),
    latin1_fmt("~w", ['\x{10FFFF}']),
    "'кирилли́ческий атом'" = fmt("~tw", ['кирилли́ческий атом']),
    [$',16#10FFFF,$'] = fmt("~tw", ['\x{10FFFF}']),

    latin1_fmt("~W", ['кирилли́ческий атом', 13]),
    latin1_fmt("~W", ['\x{10FFFF}', 13]),
    "'кирилли́ческий атом'" = fmt("~tW", ['кирилли́ческий атом', 13]),
    [$',16#10FFFF,$'] = fmt("~tW", ['\x{10FFFF}', 13]),

    {ok, [an_atom],[]} = io_lib:fread("~a", "an_atom"),
    {ok, [an_atom],[]} = io_lib:fread("~ta", "an_atom"),
    Str = "\"ab" ++ [1089] ++ "cd\"",
    {ok, ["\"ab"], [1089]++"cd\""} = io_lib:fread("~s", Str),
    {ok, ['\"ab'], [1089]++"cd\""} = io_lib:fread("~a", Str),
    {ok,[Str], []} = io_lib:fread("~ts", Str),
    {ok,[Atom],[]} = io_lib:fread("~ta", Str),
    Str = atom_to_list(Atom),

    ok.

latin1_fmt(Fmt, Args) ->
    L = fmt(Fmt, Args),
    true = lists:all(fun is_latin1/1, L).

limit_term(_Config) ->
    {_, 2} = limt([a,b,c], 2),
    {_, 2} = limt([a,b,c], 3),
    {_, 2} = limt([a,b|c], 2),
    {_, 2} = limt([a,b|c], 3),
    {_, 2} = limt({a,b,c,[d,e]}, 2),
    {_, 2} = limt({a,b,c,[d,e]}, 3),
    {_, 2} = limt({a,b,c,[d,e]}, 4),
    T0 = [1|{a,b,c}],
    {_, 2} = limt(T0, 2),
    {_, 2} = limt(T0, 3),
    {_, 2} = limt(T0, 4),
    {_, 1} = limt(<<"foo">>, 18),
    {_, 2} = limt({"",[1,2]}, 3),
    {_, 2} = limt({"",{1,2}}, 3),
    true = limt_pp({"123456789012345678901234567890",{1,2}}, 3),
    ok = blimt(<<"123456789012345678901234567890">>),
    true = limt_pp(<<"123456789012345678901234567890">>, 3),
    {_, 2} = limt({<<"kljlkjsl">>,[1,2,3,4]}, 4),
    {_, 1} = limt(<<7:3>>, 2),
    {_, 1} = limt(<<7:21>>, 2),
    {_, 1} = limt([], 2),
    {_, 1} = limt({}, 2),
    {_, 1} = limt({"", ""}, 4),
    {_, 1} = limt(#{}, 2),
    {_, 2} = limt(#{[] => {}}, 1),
    {_, 2} = limt(#{[] => {}}, 2),
    {_, 1} = limt(#{[] => {}}, 3),
    T = #{[] => {},[a] => [b]},
    {_, 1} = limt(T, 0),
    {_, 2} = limt(T, 1),
    {_, 2} = limt(T, 2),
    {_, 2} = limt(T, 3),
    {_, 1} = limt(T, 4),
    T2 = #{[] => {},{} => []},
    {_, 2} = limt(T2, 1),
    {_, 2} = limt(T2, 2),
    {_, 1} = limt(T2, 3),
    ok.

blimt(Binary) ->
    blimt(Binary, byte_size(Binary)).

blimt(_B, 1) -> ok;
blimt(B, D) ->
    {_, 1} = limt(B, D),
    blimt(B, D - 1).

limt(Term, Depth) when is_integer(Depth) ->
    T1 = io_lib:limit_term(Term, Depth),
    S = form(Term, Depth),
    S1 = form(T1, Depth),
    OK1 = S1 =:= S,

    T2 = io_lib:limit_term(Term, Depth+1),
    S2 = form(T2, Depth),
    OK2 = S2 =:= S,

    T3 = io_lib:limit_term(Term, Depth-1),
    S3 = form(T3, Depth),
    OK3 = S3 =/= S,

    R = case {OK1, OK2, OK3} of
            {true, true, true} -> 2;
            {true, true, false} -> 1;
            _ -> 0
        end,
    {{S, S1, S2}, R}.

form(Term, Depth) ->
    lists:flatten(fmt("~W", [Term, Depth])).

limt_pp(Term, Depth) when is_integer(Depth) ->
    T1 = io_lib:limit_term(Term, Depth),
    S = pp(Term, Depth),
    S1 = pp(T1, Depth),
    S1 =:= S.

pp(Term, Depth) ->
    lists:flatten(fmt("~P", [Term, Depth])).

otp_14983(_Config) ->
    trunc_depth(-1, fun trp/3),
    trunc_depth(10, fun trp/3),
    trunc_depth(-1, fun trw/3),
    trunc_depth(10, fun trw/3),
    trunc_depth_p(-1),
    trunc_depth_p(10),
    trunc_string(),
    ok.

trunc_string() ->
    "str " = trf("str ", [], 10),
    "str str" = trf("str ~s", ["str"], 6),
    "str ..." = trf("str ~s", ["str1"], 6),
    "str str" = trf("str ~s", ["str"], 7),
    "str str" = trf("str ~8s", ["str"], 6),
    "str ..." = trf("str ~8s", ["str1"], 6),
    {ok, UPeer, UNode} = ?CT_PEER(["+pc", "unicode"]),
    U = "кирилли́ческий атом",
    UFun = fun(Format, Args, CharsLimit) ->
                   rpc:call(UNode,
                            ?MODULE, trf, [Format, Args, CharsLimit])
           end,
    "str кир" = UFun("str ~3ts", [U], 7),
    "str ..." = UFun("str ~3ts", [U], 6),
    "str ..." = UFun("str ~30ts", [U], 6),
    "str кир..." = UFun("str ~30ts", [U], 10),
    "str кирилл..." = UFun("str ~30ts", [U], 13),
    "str кирилли́..." = UFun("str ~30ts", [U], 14),
    "str кирилли́ч..." = UFun("str ~30ts", [U], 15),
    "\"кирилли́ческ\"..." = UFun("~tp", [U], 13),
    BU = <<"кирилли́ческий атом"/utf8>>,
    "<<\"кирилли́\"/utf8...>>" = UFun("~tp", [BU], 20),
    "<<\"кирилли́\"/utf8...>>" = UFun("~tp", [BU], 21),
    "<<\"кирилли́ческ\"/utf8...>>" = UFun("~tp", [BU], 22),
    peer:stop(UPeer).

trunc_depth(D, Fun) ->
    "..." = Fun("", D, 0),
    "[]" = Fun("", D, 1),

    "#{}" = Fun(#{}, D, 1),
    "#{a => 1}" = Fun(#{a => 1}, D, 7),
    "#{...}" = Fun(#{a => 1}, D, 5),
    "#{a => 1}" = Fun(#{a => 1}, D, 6),
    A = lists:seq(1, 1000),
    M = #{A => A, {A,A} => {A,A}},
    "#{...}" = Fun(M, D, 6),
    "#{{...} => {...},...}" = Fun(M, D, 7),
    "#{{[...],...} => {[...],...},...}" = Fun(M, D, 22),
    "#{{[...],...} => {[...],...},[...] => [...]}" = Fun(M, D, 31),
    "#{{[...],...} => {[...],...},[1|...] => [...]}" = Fun(M, D, 33),
    "#{{[1|...],[...]} => {[1|...],[...]},[1,2|...] => [...]}" =
        Fun(M, D, 50),

    "..." = Fun({c, 1, 2}, D, 0),
    "{...}" = Fun({c, 1, 2}, D, 1),

    "..." = Fun({}, D, 0),
    "{}" = Fun({}, D, 1),
    T = {A, A, A},
    "{...}" = Fun(T, D, 5),
    "{[...],...}" = Fun(T, D, 6),
    "{[1|...],[...],...}" = Fun(T, D, 12),
    "{[1,2|...],[1|...],...}" = Fun(T, D, 20),
    "{[1,2|...],[1|...],[...]}" = Fun(T, D, 21),
    "{[1,2,3|...],[1,2|...],[1|...]}" = Fun(T, D, 28),

    "{[1],[1,2|...]}" = Fun({[1],[1,2,3,4]}, D, 14).

trunc_depth_p(D) ->
    UOpts = [{record_print_fun, fun rfd/2},
             {encoding, unicode}],
    LOpts = [{record_print_fun, fun rfd/2},
             {encoding, latin1}],
    trunc_depth_p(D, UOpts),
    trunc_depth_p(D, LOpts).

trunc_depth_p(D, Opts) ->
    "[...]" = trp("abcdefg", D, 4, Opts),
    "\"abc\"..." = trp("abcdefg", D, 5, Opts),
    "\"abcdef\"..." = trp("abcdefg", D, 8, Opts),
    "\"abcdefg\"" = trp("abcdefg", D, 9, Opts),
    "\"abcdefghijkl\"" = trp("abcdefghijkl", D, -1, Opts),
    AZ = lists:seq($A, $Z),
    AZb = list_to_binary(AZ),
    AZbS = "<<\"" ++ AZ ++ "\">>",
    AZbS = trp(AZb, D, -1),
    "<<\"ABCDEFGH\"...>>" = trp(AZb, D, 17, Opts), % 4 chars even if D = -1...
    "<<\"ABCDEFGHIJKL\"...>>" = trp(AZb, D, 18, Opts),
    B1 = <<"abcdef",0:8>>,
    "<<\"ab\"...>>" = trp(B1, D, 8, Opts),
    "<<\"abcdef\"...>>" = trp(B1, D, 14, Opts),
    "<<97,98,99,100,...>>" = trp(B1, D, 16, Opts),
    "<<97,98,99,100,101,102,0>>" = trp(B1, D, -1, Opts),
    B2 = <<AZb/binary,0:8>>,
    "<<\"AB\"...>>" = trp(B2, D, 8, Opts),
    "<<\"ABCDEFGH\"...>>" = trp(B2, D, 14, Opts),
    "<<65,66,67,68,69,70,71,72,0>>" = trp(<<"ABCDEFGH",0:8>>, D, -1, Opts),
    "<<97,0,107,108,...>>" = trp(<<"a",0:8,"kllkjlksdjfsj">>, D, 20, Opts),

    A = lists:seq(1, 1000),
    "#c{...}" = trp({c, 1, 2}, D, 6),
    "#c{...}" = trp({c, 1, 2}, D, 7),
    "#c{f1 = [...],...}" = trp({c, A, A}, D, 18),
    "#c{f1 = [1|...],f2 = [...]}" = trp({c, A, A}, D, 19),
    "#c{f1 = [1,2|...],f2 = [1|...]}" = trp({c, A, A}, D, 31),
    "#c{f1 = [1,2,3|...],f2 = [1,2|...]}" = trp({c, A, A}, D, 32).

trp(Term, D, T) ->
    trp(Term, D, T, [{record_print_fun, fun rfd/2}]).

trp(Term, D, T, Opts) ->
    R = io_lib_pretty:print(Term, [{depth, D}, {chars_limit, T}|Opts]),
    FR = lists:flatten(R),
    FR = check_bin_p(FR, Term, [{depth, D}, {chars_limit, T}|Opts]),
    lists:flatten(io_lib:format("~s", [R])).

trw(Term, D, T) ->
    lists:flatten(fmt("~W", [Term, D], [{chars_limit, T}])).

trf(Format, Args, T) ->
    trf(Format, Args, T, [{record_print_fun, fun rfd/2}]).

trf(Format, Args, T, Opts) ->
    lists:flatten(fmt(Format, Args, [{chars_limit, T}|Opts])).

otp_15103(_Config) ->
    T = lists:duplicate(5, {a,b,c}),

    S1 = fmt("~0p", [T]),
    "[{a,b,c},{a,b,c},{a,b,c},{a,b,c},{a,b,c}]" = lists:flatten(S1),
    S2 = fmt("~-0p", [T]),
    "[{a,b,c},{a,b,c},{a,b,c},{a,b,c},{a,b,c}]" = lists:flatten(S2),
    S3 = fmt("~1p", [T]),
    "[{a,\n  b,\n  c},\n {a,\n  b,\n  c},\n {a,\n  b,\n  c},\n {a,\n  b,\n"
    "  c},\n {a,\n  b,\n  c}]" = lists:flatten(S3),

    S4 = fmt("~0P", [T, 5]),
    "[{a,b,c},{a,b,...},{a,...},{...}|...]" = lists:flatten(S4),
    S5 = fmt("~1P", [T, 5]),
    "[{a,\n  b,\n  c},\n {a,\n  b,...},\n {a,...},\n {...}|...]" =
        lists:flatten(S5),
    ok.

otp_15159(_Config) ->
    "[atom]" =
        lists:flatten(fmt("~p", [[atom]], [{chars_limit,5}])),
    ok.

otp_15076(_Config) ->
    ok = bad_io_lib_format("~c", [a]),
    L = io_lib:scan_format("~c", [a]),
    {"~c", [a]} = io_lib:unscan_format(L),
    {'EXIT', {badarg, _}} = (catch io_lib:build_text(L)),
    {'EXIT', {badarg, _}} = (catch io_lib:build_text(L, [])),
    ok.

otp_15639(_Config) ->
    L = lists:duplicate(10, "a"),
    LOpts = [{encoding, latin1},  {chars_limit, 10}],
    UOpts = [{encoding, unicode}, {chars_limit, 10}],
    "[[...]|...]" = pretty(L, LOpts),
    "[[...]|...]" = pretty(L, UOpts),
    "[\"a\",[...]|...]" =
        pretty(L, [{chars_limit, 12}, {encoding, latin1}]),
    "[\"a\",[...]|...]" =
        pretty(L, [{chars_limit, 12}, {encoding, unicode}]),

    %% Latin-1
    "\"12345678\"" = pretty("12345678", LOpts),
    "\"12345678\"..." = pretty("123456789", LOpts),
    "\"\\r\\n123456\"..." = pretty("\r\n1234567", LOpts),
    "\"\\r1234567\"..." = pretty("\r12345678", LOpts),
    "\"\\r\\n123456\"..." = pretty("\r\n12345678", LOpts),
    "\"12345678\"..." = pretty("12345678"++[x], LOpts),
    "[49,50|...]" = pretty("1234567"++[x], LOpts),
    "[49,x]" = pretty("1"++[x], LOpts),
    "[[...]|...]" = pretty(["1","2","3","4","5","6","7","8"], LOpts),
    %% Unicode
    "\"12345678\"" = pretty("12345678", UOpts),
    "\"12345678\"..." = pretty("123456789", UOpts),
    "\"\\r\\n1234567\"" = pretty("\r\n1234567", UOpts),
    "\"\\r1234567\"..." = pretty("\r12345678", UOpts),
    "\"\\r\\n1234567\"..." = pretty("\r\n12345678", UOpts),
    "[49,50|...]" = pretty("12345678"++[x], UOpts),
    "\"12345678\"..." = pretty("123456789"++[x], UOpts),
    "[[...]|...]" = pretty(["1","2","3","4","5","6","7","8"], UOpts),
    ok.

otp_15705(_Config) ->
    L = [<<"an">>,["at"],[["om"]]],
    "..." = trf("~s", [L], 0),
    "..." = trf("~s", [L], 1),
    "..." = trf("~s", [L], 2),
    "..." = trf("~s", [L], 3),
    "a..." = trf("~s", [L], 4),
    "an..." = trf("~s", [L], 5),
    "anatom" = trf("~s", [L], 6),
    L2 = ["a",[<<"na">>],[["tom"]]],
    "..." = trf("~s", [L2], 3),
    "a..." = trf("~s", [L2], 4),
    "an..." = trf("~s", [L2], 5),
    "anatom" = trf("~s", [L2], 6),

    A = [[<<"äpple"/utf8>>, "plus", <<"äpple">>]],
    "äp..." = trf("~ts", [A], 5),
    "äppleplusäpple" = trf("~ts", [A], 14),
    U = [["ки"],"рилл","и́ческий атом"],
    "ки..." = trf("~ts", [U], 5),
    "кирилли́ческий..." = trf("~ts", [U], 16),
    "кирилли́ческий атом" = trf("~ts", [U], 20),

    "|кирилли́чес|" = trf("|~10ts|", [U], -1),
    ok.

otp_15847(_Config) ->
    T = {someRecord,<<"1234567890">>,some,more},
    "{someRecord,<<...>>,...}" =
        pretty(T, [{chars_limit,20}, {encoding,latin1}]),
    ok.

otp_15875(_Config) ->
    %% This test is moot due to the fix in GH-4842.
    S = fmt("~tp", [[{0, [<<"00">>]}]], [{chars_limit, 18}]),
    "[{0,[<<\"00\">>]}]" = lists:flatten(S).


github_4801(_Config) ->
	  <<"{[81.6]}">> = iolist_to_binary(fmt("~p", [{[81.6]}], [{chars_limit,40}])).

%% GH-4824, GH-4842, OTP-17459.
chars_limit(_Config) ->
    List = fun R(I) ->
                   case I =:= 0 of true -> 0; false -> [I, R(I-1)] end
           end,
    Tuple = fun R(I) ->
                   case I =:= 0 of true -> 0; false -> {I, R(I-1)} end
           end,
    Map = fun R(I) ->
                   case I =:= 0 of true -> 0; false -> #{I => R(I-1)} end
           end,
    Record = fun R(I) ->
                   case I =:= 0 of true -> 0; false -> {b, R(I-1)} end
           end,
    Test = fun (F, N, Lim) ->
                   Opts = [{chars_limit, Lim},
                           {record_print_fun, fun rfd/2}],
                   [_|_] = RL = io_lib_pretty:print(F(N), Opts),
                   check_bin_p(lists:flatten(RL),F(N), Opts)
           end,
    %% Used to loop:
    Test(List, 1000, 1000),
    Test(Tuple, 1000, 1000),
    Test(Map, 1000, 1000),
    Test(Record, 1000, 1000),

    %% Misc sizes and char limits:
    _ = [Test(What, N, CL) ||
            N <- lists:seq(1, 50),
            CL <- lists:seq(N, N*3),
            What <- [List, Tuple, Map, Record]
        ],
    ok.

error_info(Config) ->

    PrivDir = proplists:get_value(priv_dir, Config),
    TmpFile = filename:join(PrivDir,?FUNCTION_NAME),

    FullDev =
        fun() ->
                case file:read_file_info("/dev/full") of
                    {ok, _} ->
                        {ok, Dev} = file:open("/dev/full", [write]),
                        Dev;
                    _ ->
                        dummy_full_device()
                end
        end,

    UnknownDev = fun dummy_unknown_error_device/0,

    Latin1Dev = fun() ->
                        {ok, Dev} = file:open(TmpFile, [read, write, {encoding, latin1}]),
                        Dev
                end,

    UnicodeDev = fun() ->
                        {ok, Dev} = file:open(TmpFile, [read, write, {encoding, unicode}]),
                        Dev
                end,

    DeadDev = spawn(fun() -> ok end),

    UserDev = fun() -> whereis(user) end,
    FileDev = FullDev,
    TestServerDev = fun() -> group_leader() end,
    ApplicationMasterDev =
        fun() ->
                {_,GL} = process_info(whereis(kernel_sup),group_leader),
                GL
        end,
    GroupDev = TestServerDev,
    StandardError = fun() -> whereis(standard_error) end,

    L = [
         {put_chars,[DeadDev,"test"],[{1,"terminated"}]},
         {put_chars,["test"],[{gl,DeadDev},{general,"terminated"}]},
         {put_chars,[?MODULE,"test"],[{1,"does not exist"}]},
         {put_chars,[FullDev(),"test"], [{1,"no space left on device"}]},
         {put_chars,["test"], [{gl,FullDev()},{general,"no space left on device"}]},
         {put_chars,[Latin1Dev(),"Спутник-1"], [{1,"transcode"}]},
         {put_chars,[a], [{1,"not valid character data"}]},
         {put_chars,[UnicodeDev(), <<222>>], [{1,"transcode"}]},
         {put_chars,[<<1:1>>], [{1,"not valid character data"}]},
         {put_chars,[UnknownDev(),"test"], [{general,"unknown error: 'Спутник-1'"}]},
         {put_chars,["test"], [{gl,UnknownDev()},{general,"unknown error: 'Спутник-1'"}]},
         {put_chars,[self(),"test"],[{1,"the device is not allowed to be the current process"}]},
         {put_chars,["test"],[{gl,self()},{general,"the device is not allowed to be the current process"}]},

         {write,[DeadDev,"test"],[{1,"terminated"}]},
         {write,["test"],[{gl,DeadDev},{general,"terminated"}]},
         {write,[?MODULE,"test"],[{1,"does not exist"}]},
         {write,[FullDev(),"test"], [{1,"no space left on device"}]},
         {write,["test"], [{gl,FullDev()},{general,"no space left on device"}]},
         {write,[UnknownDev(),"test"], [{general,"unknown error: 'Спутник-1'"}]},
         {write,["test"], [{gl,UnknownDev()},{general,"unknown error: 'Спутник-1'"}]},

         {nl,[DeadDev],[{1,"terminated"}]},
         {nl,[?MODULE],[{1,"does not exist"}]},
         {nl,[],[{gl,DeadDev},{general,"terminated"}]},
         {nl,[FullDev()], [{1,"no space left on device"}]},
         {nl,[], [{gl,FullDev()},{general,"no space left on device"}]},
         {nl,[UnknownDev()], [{general,"unknown error: 'Спутник-1'"}]},
         {nl,[], [{gl,UnknownDev()},{general,"unknown error: 'Спутник-1'"}]},

         [[{Format,[DeadDev,"test",[]],   [{1,"terminated"}]},
           {Format,["test",[{gl,DeadDev},  {general,"terminated"}]]},
           {Format,[?MODULE,"test",[]],   [{1,"does not exist"}]},
           {Format,[FullDev(),"test",[]], [{1,"no space left on device"}]},
           {Format,["test"], [{gl,FullDev()},{general,"no space left on device"}]},
           {Format,[standard_io,"test"],  [{1,"wrong number of arguments"},
                                           {general,"possibly missing argument list"}]},
           {Format,[UnknownDev(),"test",[]], [{general,"unknown error: 'Спутник-1'"}]},

           %% Test a latin1 device
           {Format,[Latin1Dev(), "~ts", [<<"Спутник-1"/utf8>>]],[{1,"transcode"}]},
           {Format,["~ts", [<<"Спутник-1"/utf8>>]],[{gl,Latin1Dev()},{general,"transcode"}]},

           %% The format error is reported differently
           %% depending on the current group_leader.
           %% The different group leaders we test are:
           %%  * file_io_server
           %%  * standard_error
           %%  * test_server_gl
           %%  * user
           %%  * application_master
           %%  * ssh_cli (TODO)
           %%  * eunit (TODO)
           %%  * group (TODO)
           [ [{Format,[Device(),make_ref(),[]],    [{2,"format string"}]},
              {Format,[Device(),"~p",make_ref()],  [{3, "not a list"}]},
              {Format,[make_ref(),[]],[{gl,Device()},{1,"format string"}]},
              {Format,["~p",make_ref()],[{gl,Device()},{2, "not a list"}]}]
             || Device <- [UserDev, FileDev, TestServerDev, StandardError,
                           GroupDev, ApplicationMasterDev]],

           %% Test number of arguments
           {Format,["~p",["Sputnik-1","Laika"]],[{1,"wrong number of arguments"}]},
           {Format,[standard_io, "~p",["Sputnik-1","Laika"]],[{2,"wrong number of arguments"}]},

           %% Test different formatting strings
           {Format,["~B",["Sputnik-1"]],[{2,"1 must be of type integer"}]},
           {Format,[standard_io, "~B",["Sputnik-1"]],[{3,"1 must be of type integer"}]},
           {Format,["~b",["Sputnik-1"]],[{2,"1 must be of type integer"}]},
           {Format,["~*b",["Sputnik-1",16]],[{2,"1 must be of type integer"}]},
           {Format,["~*f",[1.0,1]],[{2,"1 must be of type integer\\n.*2 must be of type float"}]},
           {Format,["~1.*f",[1.0,1]],[{2,"1 must be of type integer\\n.*2 must be of type float"}]},
           {Format,["~*.*f",[a,b,c]],[{2,"1 must be of type integer\\n.*"
                                       "2 must be of type integer\\n.*"
                                       "3 must be of type float"}]},
           {Format,["~s",["Спутник-1"]],[{1,"failed to format string"}]},
           {Format,["~s",[1]],[{2,"1 must be of type string"}]},
           {Format,["~s~s",[a,1]],[{2,"2 must be of type string"}]},
           {Format,["~s",[[a]]],[{2,"1 must be of type string"}]},

	   %% Ensure error messages contain the correct reason (GH-8568)
	   {Format, ["~ltkKltkKp", []], [{1,"wrong number of arguments"}]},
	   {Format, ["~ltkKltkKm", [undefined, ordered, a]], [{1,"format string"}]},
	   {Format, ["~ltkKltkKb", [undefined, ordered, a]], [{2,"3 must be of type integer"}]},
	   {Format, ["~ltkKp", [foo, #{a => b}]], [{2,"1 must be 'undefined', 'ordered', 'reversed', or a fun that takes two arguments"}]}
	  ]
	  || Format <- [format,fwrite]]

        ],

    error_info_lib:test_error_info(io, lists:flatten(L), [allow_nyi]).

dummy_full_device() ->
    dummy_device(enospc).
dummy_unknown_error_device() ->
    dummy_device('Спутник-1').

dummy_device(Error) ->
    spawn_link(
      fun() ->
              receive
                  {io_request, From, ReplyAs, {put_chars, _Encoding, _Chars}} ->
                      From ! {io_reply, ReplyAs, {error, Error}};
                  {io_request, From, ReplyAs, {put_chars, _Encoding, M, F, As}} ->
                      try apply(M, F, As) of
                          _ ->
                              From ! {io_reply, ReplyAs, {error, Error}}
                      catch _:_ ->
                              From ! {io_reply, ReplyAs, {error, format}}
                      end
              end
      end).

%% GH-5053. 'chars_limit' bug.
otp_17525(_Config) ->
    L = [{xxxxxxxxx,aaaa},
         {yyyyyyyyyyyy,1},
         {eeeeeeeeeeeee,bbbb},
         {ddddddddd,1111111111},
         {gggggggggggggggggggg,cccc},
         {uuuuuuuuuuuu,11}],
    S = fmt("aaaaaaaaaaaaaaaaaa ~p bbbbbbbbbbb ~p",
            ["cccccccccccccccccccccccccccccccccccccc", L],
            [{chars_limit, 155}]),
    Corr = "aaaaaaaaaaaaaaaaaa \"cccccccccccccccccccccccccccccccccccccc\" bbbbbbbbbbb [{xxxxxxxxx,\n"
        "                                                                          aaaa},\n"
        "                                                                         {yyyyyyyyyyyy,\n"
        "                                                                          1},\n"
        "                                                                         {eeeeeeeeeeeee,\n"
        "                                                                          bbbb},\n"
        "                                                                         {ddddddddd,\n"
        "                                                                          1111111111},\n"
        "                                                                         {...}|...]",
    Corr = lists:flatten(S),
    ok.

unscan_format_without_maps_order(_Config) ->
    FormatSpec = #{
        adjust => right,
        args => [[<<"1">>]],
        control_char => 115,
        encoding => unicode,
        pad_char => 32,
        precision => none,
        strings => true,
        width => none
    },
    {"~ts",[[<<"1">>]]} = io_lib:unscan_format([FormatSpec]).

build_text_without_maps_order(_Config) ->
    FormatSpec = #{
        adjust => right,
        args => [[<<"1">>]],
        control_char => 115,
        encoding => unicode,
        pad_char => 32,
        precision => none,
        strings => true,
        width => none
    },
    [["1"]] = io_lib:build_text([FormatSpec]).
