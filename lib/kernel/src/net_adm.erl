%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 1996-2024. All Rights Reserved.
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
-module(net_adm).
-moduledoc """
Various Erlang net administration routines.

This module contains various network utility functions.

## Files

File `.hosts.erlang` consists of a number of host names written as Erlang terms.
It is looked for in the current work directory, the user's home directory, and
`$OTPROOT` (the root directory of Erlang/OTP), in that order.

The format of file `.hosts.erlang` must be one host name per line. The host
names must be within quotes.

_Example:_

```text
'super.eua.ericsson.se'.
'renat.eua.ericsson.se'.
'grouse.eua.ericsson.se'.
'gauffin1.eua.ericsson.se'.
^ (new line)
```
""".
-export([host_file/0,
	 localhost/0,
	 names/0, names/1,
	 ping_list/1,
	 world/0,world/1,
	 world_list/1, world_list/2,
	 dns_hostname/1,
	 ping/1]).

%%------------------------------------------------------------------------

-type verbosity() :: 'silent' | 'verbose'.

%%------------------------------------------------------------------------

%% Try to read .hosts.erlang file in 
%% 1. cwd , 2. $HOME 3. init:root_dir() 

-doc """
Reads file `.hosts.erlang`, see section [Files](`m:net_adm#module-files`). Returns the
hosts in this file as a list. Returns `{error, Reason}` if the file cannot be
read or the Erlang terms on the file cannot be interpreted.
""".
-spec host_file() -> Hosts | {error, Reason} when
      Hosts :: [Host :: atom()],
      %% Copied from file:path_consult/2:
      Reason :: file:posix() | badarg | terminated | system_limit
              | {Line :: integer(), Mod :: module(), Term :: term()}.

host_file() ->
    Home = case init:get_argument(home) of
	       {ok, [[H]]} -> [H];
	       _ -> []
	   end,
    case file:path_consult(["."] ++ Home ++ [code:root_dir()], ".hosts.erlang") of
	{ok, Hosts, _} -> Hosts;
	Error -> Error
    end.
	
%% Check whether a node is up or down
%%  side effect: set up a connection to Node if there not yet is one.

-doc """
Sets up a connection to `Node`. Returns `pong` if it is successful, otherwise
`pang`.
""".
-spec ping(Node) -> pong | pang when
      Node :: atom().

ping(Node) when is_atom(Node) ->
    case catch gen:call({net_kernel, Node},
			'$gen_call',
			{is_auth, node()},
			infinity) of
	{ok, yes} -> pong;
	_ ->
	    erlang:disconnect_node(Node),
	    pang
    end.

-doc """
Returns the name of the local host. If Erlang was started with command-line flag
`-name`, `Name` is the fully qualified name.
""".
-spec localhost() -> Name when
      Name :: string().

localhost() ->
    {ok, Host} = inet:gethostname(),
    case inet_db:res_option(domain) of
	"" -> Host;
	Domain -> Host ++ "." ++ Domain
    end.


-doc(#{equiv => names(net_adm:localhost())}).
-spec names() -> {ok, [{Name, Port}]} | {error, Reason} when
      Name :: string(),
      Port :: non_neg_integer(),
      Reason :: address | file:posix().

names() ->
    names(localhost()).


-doc """
Returns the names and associated port numbers of the Erlang nodes that `epmd`
registered at the specified host.

Similar to `epmd -names`, see [`erts:epmd`](`e:erts:epmd_cmd.md`).

Returns `{error, address}` if `epmd` is not operational.

_Example:_

```erlang
(arne@dunn)1> net_adm:names().
{ok,[{"arne",40262}]}
```
""".
-spec names(Host) -> {ok, [{Name, Port}]} | {error, Reason} when
      Host :: atom() | string() | inet:ip_address(),
      Name :: string(),
      Port :: non_neg_integer(),
      Reason :: address | file:posix().

names(Hostname) ->
    ErlEpmd = net_kernel:epmd_module(),
    ErlEpmd:names(Hostname).

-doc """
Returns the official name of `Host`, or `{error, Host}` if no such name is
found. See also `m:inet`.
""".
-spec dns_hostname(Host) -> {ok, Name} | {error, Host} when
      Host :: atom() | string(),
      Name :: string().

dns_hostname(Hostname) ->
    case inet:gethostbyname(Hostname) of
	{ok,{hostent, Name, _ , _Af, _Size, _Addr}} ->
	    {ok, Name};
	_ ->
	    {error, Hostname}
    end.

%% A common situation in "life" is to have a configuration file with a list
%% of nodes, and then at startup, all nodes in the list are ping'ed
%% this can lead to no end of troubles if two disconnected nodes
%% simultaneously ping each other.
%% Use this function in order to do it safely.
%% It assumes a working global.erl which ensures a fully 
%% connected network.
%% Had the erlang runtime system been able to fully cope with 
%% the possibility of two simultaneous (unix) connects, this function would
%% merley  be lists:map({net_adm, ping}, [], Nodelist).
%% It is also assumed, that the same (identical) Nodelist is given to all
%% nodes which are to perform this call (possibly simultaneously).
%% Even this code has a flaw, and that is the case where two
%% nodes simultaneously and without *any* other already 
%% running nodes execute this code. :-(

-doc false.
-spec ping_list([atom()]) -> [atom()].

ping_list(Nodelist) ->
    ok = net_kernel:monitor_nodes(true),
    Sofar = ping_first(Nodelist, nodes()),
    collect_new(Sofar, Nodelist).

ping_first([], _S) ->
    [];
ping_first([Node|Nodes], S) ->
    case lists:member(Node, S) of
	true -> [Node | ping_first(Nodes, S)];
	false ->
	    case ping(Node) of
		pong -> [Node];
		pang -> ping_first(Nodes, S)
	    end
    end.

collect_new(Sofar, Nodelist) ->
    receive
	{nodeup, Node} ->
	    case lists:member(Node, Nodelist) of
		true ->
		    collect_new(Sofar, Nodelist);
		false ->
		    collect_new([Node | Sofar], Nodelist)
	    end
    after 3000 ->
	    ok = net_kernel:monitor_nodes(false),
	    Sofar
    end.

%% This function polls a set of hosts according to a file called
%% .hosts.erlang that need to reside either in the current directory
%% or in your home directory. (The current directory is tried first.)
%% world() returns a list of all nodes on the network that can be 
%% found (including ourselves). Note: the $HOME variable is inspected.
%%
%% Added possibility to supply a list of hosts instead of reading
%% the .hosts.erlang file. 971016 patrik@erix.ericsson.se
%% e.g. 
%% net_adm:world_list(['elrond.du.etx.ericsson.se', 'thorin.du.etx.ericsson.se']). 

-doc(#{equiv => world(silent)}).
-spec world() -> [node()].

world() ->
    world(silent).

-doc """
Calls [`names(Host)`](`names/1`) for all hosts that are specified in the Erlang
host file `.hosts.erlang`, collects the replies, and then evaluates
[`ping(Node)`](`ping/1`) on all those nodes. Returns the list of all nodes that
are successfully pinged.

If `Arg == verbose`, the function writes information about which nodes it is
pinging to `stdout`.

This function can be useful when a node is started, and the names of the other
network nodes are not initially known.

Returns `{error, Reason}` if `host_file/0` returns `{error, Reason}`.
""".
-spec world(Arg) -> [node()] when
      Arg :: verbosity().

world(Verbose) ->
    case net_adm:host_file() of
        {error,R} -> exit({error, R});
        Hosts -> expand_hosts(Hosts, Verbose)
    end.

-doc(#{equiv => world_list(Hosts, silent)}).
-spec world_list(Hosts) -> [node()] when
      Hosts :: [atom()].

world_list(Hosts) when is_list(Hosts) ->
    expand_hosts(Hosts, silent).

-doc """
Same as [`world/0,1`](`world/1`), but the hosts are specified as argument
instead of being read from `.hosts.erlang`.
""".
-spec world_list(Hosts, Arg) -> [node()] when
      Hosts :: [atom()],
      Arg :: verbosity().

world_list(Hosts, Verbose) when is_list(Hosts) ->
    expand_hosts(Hosts, Verbose).

expand_hosts(Hosts, Verbose) ->
    lists:flatten(collect_nodes(Hosts, Verbose)).

collect_nodes([], _) -> [];
collect_nodes([Host|Tail], Verbose) ->
    case collect_host_nodes(Host, Verbose) of
        nil ->
            collect_nodes(Tail, Verbose);
        L ->
            [L|collect_nodes(Tail, Verbose)]
    end.

collect_host_nodes(Host, Verbose) ->
    case names(Host) of
	{ok, Namelist} ->
	    do_ping(Namelist, atom_to_list(Host), Verbose);
	_ ->
	    nil
    end.

do_ping(Names, Host0, Verbose) ->
    case longshort(Host0) of
	ignored -> [];
	Host -> do_ping_1(Names, Host, Verbose)
    end.

do_ping_1([], _Host, _Verbose) ->
    [];
do_ping_1([{Name, _} | Rest], Host, Verbose) ->
    Node = list_to_atom(Name ++ "@" ++ longshort(Host)),
    verbose(Verbose, "Pinging ~w -> ", [Node]),
    Result = ping(Node),
    verbose(Verbose, "~p\n", [Result]),
    case Result of
	pong ->
	    [Node | do_ping_1(Rest, Host, Verbose)];
	pang ->
	    do_ping_1(Rest, Host, Verbose)
    end.

verbose(verbose, Format, Args) ->
    io:format(Format, Args);
verbose(_, _, _) ->
    ok.

longshort(Host) ->
    case net_kernel:longnames() of
	false -> uptodot(Host);
	true -> Host;
	ignored -> ignored
    end.

uptodot([$.|_]) -> [];
uptodot([])-> [];
uptodot([H|T]) -> [H|uptodot(T)].
