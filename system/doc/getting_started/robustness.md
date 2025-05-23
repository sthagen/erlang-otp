<!--
%CopyrightBegin%

SPDX-License-Identifier: Apache-2.0

Copyright Ericsson AB 2023-2025. All Rights Reserved.

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
# Robustness

Several things are wrong with the messenger example in
[A Larger Example](conc_prog.md#ex). For example, if a node where a user is
logged on goes down without doing a logoff, the user remains in the server's
`User_List`, but the client disappears. This makes it impossible for the user to
log on again as the server thinks the user already is logged on.

Or what happens if the server goes down in the middle of sending a message,
leaving the sending client hanging forever in the `await_result` function?

## Time-outs

Before improving the messenger program, let us look at some general principles,
using the ping pong program as an example. Recall that when "ping" finishes, it
tells "pong" that it has done so by sending the atom `finished` as a message to
"pong" so that "pong" can also finish. Another way to let "pong" finish is to
make "pong" exit if it does not receive a message from ping within a certain
time. This can be done by adding a _time-out_ to `pong` as shown in the
following example:

```erlang
-module(tut19).

-export([start_ping/1, start_pong/0,  ping/2, pong/0]).

ping(0, Pong_Node) ->
    io:format("ping finished~n", []);

ping(N, Pong_Node) ->
    {pong, Pong_Node} ! {ping, self()},
    receive
        pong ->
            io:format("Ping received pong~n", [])
    end,
    ping(N - 1, Pong_Node).

pong() ->
    receive
        {ping, Ping_PID} ->
            io:format("Pong received ping~n", []),
            Ping_PID ! pong,
            pong()
    after 5000 ->
            io:format("Pong timed out~n", [])
    end.

start_pong() ->
    register(pong, spawn(tut19, pong, [])).

start_ping(Pong_Node) ->
    spawn(tut19, ping, [3, Pong_Node]).
```

After this is compiled and the file `tut19.beam` is copied to the necessary
directories, the following is seen on (pong@kosken):

```text
(pong@kosken)1> tut19:start_pong().
true
Pong received ping
Pong received ping
Pong received ping
Pong timed out
```

And the following is seen on (ping@gollum):

```text
(ping@gollum)1> tut19:start_ping(pong@kosken).
<0.36.0>
Ping received pong
Ping received pong
Ping received pong
ping finished
```

The time-out is set in:

```erlang
pong() ->
    receive
        {ping, Ping_PID} ->
            io:format("Pong received ping~n", []),
            Ping_PID ! pong,
            pong()
    after 5000 ->
            io:format("Pong timed out~n", [])
    end.
```

The time-out (`after 5000`) is started when `receive` is entered. The time-out
is canceled if `{ping,Ping_PID}` is received. If `{ping,Ping_PID}` is not
received, the actions following the time-out are done after 5000 milliseconds.
`after` must be last in the `receive`, that is, preceded by all other message
reception specifications in the `receive`. It is also possible to call a
function that returned an integer for the time-out:

```erlang
after pong_timeout() ->
```

In general, there are better ways than using time-outs to supervise parts of a
distributed Erlang system. Time-outs are usually appropriate to supervise
external events, for example, if you have expected a message from some external
system within a specified time. For example, a time-out can be used to log a
user out of the messenger system if they have not accessed it for, say, ten
minutes.

## Error Handling

Before going into details of the supervision and error handling in an Erlang
system, let us see how Erlang processes terminate, or in Erlang terminology,
_exit_.

A process which executes [`exit(normal)`](`exit/1`) or simply runs out of things
to do has a _normal_ exit.

A process which encounters a runtime error (for example, divide by zero, bad
match, trying to call a function that does not exist and so on) exits with an
error, that is, has an _abnormal_ exit. A process which executes
[exit(Reason)](`erlang:exit/1`) where `Reason` is any Erlang term except the
atom `normal`, also has an abnormal exit.

An Erlang process can set up links to other Erlang processes. If a process calls
[link(Other_Pid)](`erlang:link/1`) it sets up a bidirectional link between
itself and the process called `Other_Pid`. When a process terminates, it sends
something called a _signal_ to all the processes it has links to.

The signal carries information about the pid it was sent from and the exit
reason.

The default behaviour of a process that receives a normal exit is to ignore the
signal.

The default behaviour in the two other cases (that is, abnormal exit) above is
to:

- Bypass all messages to the receiving process.
- Kill the receiving process.
- Propagate the same error signal to the links of the killed process.

In this way you can connect all processes in a transaction together using links.
If one of the processes exits abnormally, all the processes in the transaction
are killed. As it is often wanted to create a process and link to it at the same
time, there is a special BIF, [spawn_link](`erlang:spawn_link/1`) that does the
same as `spawn`, but also creates a link to the spawned process.

Now an example of the ping pong example using links to terminate "pong":

```erlang
-module(tut20).

-export([start/1,  ping/2, pong/0]).

ping(N, Pong_Pid) ->
    link(Pong_Pid),
    ping1(N, Pong_Pid).

ping1(0, _) ->
    exit(ping);

ping1(N, Pong_Pid) ->
    Pong_Pid ! {ping, self()},
    receive
        pong ->
            io:format("Ping received pong~n", [])
    end,
    ping1(N - 1, Pong_Pid).

pong() ->
    receive
        {ping, Ping_PID} ->
            io:format("Pong received ping~n", []),
            Ping_PID ! pong,
            pong()
    end.

start(Ping_Node) ->
    PongPID = spawn(tut20, pong, []),
    spawn(Ping_Node, tut20, ping, [3, PongPID]).
```

```text
(s1@bill)3> tut20:start(s2@kosken).
Pong received ping
<3820.41.0>
Ping received pong
Pong received ping
Ping received pong
Pong received ping
Ping received pong
```

This is a slight modification of the ping pong program where both processes are
spawned from the same `start/1` function, and the "ping" process can be spawned
on a separate node. Notice the use of the `link` BIF. "Ping" calls
[`exit(ping)`](`exit/1`) when it finishes and this causes an exit signal to be
sent to "pong", which also terminates.

It is possible to modify the default behaviour of a process so that it does not
get killed when it receives abnormal exit signals. Instead, all signals are
turned into normal messages on the format `{'EXIT',FromPID,Reason}` and added to
the end of the receiving process' message queue. This behaviour is set by:

```erlang
process_flag(trap_exit, true)
```

There are several other process flags, see [erlang(3)](`erlang:process_flag/2`).
Changing the default behaviour of a process in this way is usually not done in
standard user programs, but is left to the supervisory programs in OTP. However,
the ping pong program is modified to illustrate exit trapping.

```erlang
-module(tut21).

-export([start/1,  ping/2, pong/0]).

ping(N, Pong_Pid) ->
    link(Pong_Pid),
    ping1(N, Pong_Pid).

ping1(0, _) ->
    exit(ping);

ping1(N, Pong_Pid) ->
    Pong_Pid ! {ping, self()},
    receive
        pong ->
            io:format("Ping received pong~n", [])
    end,
    ping1(N - 1, Pong_Pid).

pong() ->
    process_flag(trap_exit, true),
    pong1().

pong1() ->
    receive
        {ping, Ping_PID} ->
            io:format("Pong received ping~n", []),
            Ping_PID ! pong,
            pong1();
        {'EXIT', From, Reason} ->
            io:format("pong exiting, got ~p~n", [{'EXIT', From, Reason}])
    end.

start(Ping_Node) ->
    PongPID = spawn(tut21, pong, []),
    spawn(Ping_Node, tut21, ping, [3, PongPID]).
```

```text
(s1@bill)1> tut21:start(s2@gollum).
<3820.39.0>
Pong received ping
Ping received pong
Pong received ping
Ping received pong
Pong received ping
Ping received pong
pong exiting, got {'EXIT',<3820.39.0>,ping}
```

## The Larger Example with Robustness Added

Let us return to the messenger program and add changes to make it more robust:

```erlang
%%% Message passing utility.
%%% User interface:
%%% login(Name)
%%%     One user at a time can log in from each Erlang node in the
%%%     system messenger: and choose a suitable Name. If the Name
%%%     is already logged in at another node or if someone else is
%%%     already logged in at the same node, login will be rejected
%%%     with a suitable error message.
%%% logoff()
%%%     Logs off anybody at that node
%%% message(ToName, Message)
%%%     sends Message to ToName. Error messages if the user of this
%%%     function is not logged on or if ToName is not logged on at
%%%     any node.
%%%
%%% One node in the network of Erlang nodes runs a server which maintains
%%% data about the logged on users. The server is registered as "messenger"
%%% Each node where there is a user logged on runs a client process registered
%%% as "mess_client"
%%%
%%% Protocol between the client processes and the server
%%% ----------------------------------------------------
%%%
%%% To server: {ClientPid, logon, UserName}
%%% Reply {messenger, stop, user_exists_at_other_node} stops the client
%%% Reply {messenger, logged_on} logon was successful
%%%
%%% When the client terminates for some reason
%%% To server: {'EXIT', ClientPid, Reason}
%%%
%%% To server: {ClientPid, message_to, ToName, Message} send a message
%%% Reply: {messenger, stop, you_are_not_logged_on} stops the client
%%% Reply: {messenger, receiver_not_found} no user with this name logged on
%%% Reply: {messenger, sent} Message has been sent (but no guarantee)
%%%
%%% To client: {message_from, Name, Message},
%%%
%%% Protocol between the "commands" and the client
%%% ----------------------------------------------
%%%
%%% Started: messenger:client(Server_Node, Name)
%%% To client: logoff
%%% To client: {message_to, ToName, Message}
%%%
%%% Configuration: change the server_node() function to return the
%%% name of the node where the messenger server runs

-module(messenger).
-export([start_server/0, server/0,
         logon/1, logoff/0, message/2, client/2]).

%%% Change the function below to return the name of the node where the
%%% messenger server runs
server_node() ->
    messenger@super.

%%% This is the server process for the "messenger"
%%% the user list has the format [{ClientPid1, Name1},{ClientPid22, Name2},...]
server() ->
    process_flag(trap_exit, true),
    server([]).

server(User_List) ->
    receive
        {From, logon, Name} ->
            New_User_List = server_logon(From, Name, User_List),
            server(New_User_List);
        {'EXIT', From, _} ->
            New_User_List = server_logoff(From, User_List),
            server(New_User_List);
        {From, message_to, To, Message} ->
            server_transfer(From, To, Message, User_List),
            io:format("list is now: ~p~n", [User_List]),
            server(User_List)
    end.

%%% Start the server
start_server() ->
    register(messenger, spawn(messenger, server, [])).

%%% Server adds a new user to the user list
server_logon(From, Name, User_List) ->
    %% check if logged on anywhere else
    case lists:keymember(Name, 2, User_List) of
        true ->
            From ! {messenger, stop, user_exists_at_other_node},  %reject logon
            User_List;
        false ->
            From ! {messenger, logged_on},
            link(From),
            [{From, Name} | User_List]        %add user to the list
    end.

%%% Server deletes a user from the user list
server_logoff(From, User_List) ->
    lists:keydelete(From, 1, User_List).


%%% Server transfers a message between user
server_transfer(From, To, Message, User_List) ->
    %% check that the user is logged on and who he is
    case lists:keysearch(From, 1, User_List) of
        false ->
            From ! {messenger, stop, you_are_not_logged_on};
        {value, {_, Name}} ->
            server_transfer(From, Name, To, Message, User_List)
    end.

%%% If the user exists, send the message
server_transfer(From, Name, To, Message, User_List) ->
    %% Find the receiver and send the message
    case lists:keysearch(To, 2, User_List) of
        false ->
            From ! {messenger, receiver_not_found};
        {value, {ToPid, To}} ->
            ToPid ! {message_from, Name, Message},
            From ! {messenger, sent}
    end.

%%% User Commands
logon(Name) ->
    case whereis(mess_client) of
        undefined ->
            register(mess_client,
                     spawn(messenger, client, [server_node(), Name]));
        _ -> already_logged_on
    end.

logoff() ->
    mess_client ! logoff.

message(ToName, Message) ->
    case whereis(mess_client) of % Test if the client is running
        undefined ->
            not_logged_on;
        _ -> mess_client ! {message_to, ToName, Message},
             ok
end.

%%% The client process which runs on each user node
client(Server_Node, Name) ->
    {messenger, Server_Node} ! {self(), logon, Name},
    await_result(),
    client(Server_Node).

client(Server_Node) ->
    receive
        logoff ->
            exit(normal);
        {message_to, ToName, Message} ->
            {messenger, Server_Node} ! {self(), message_to, ToName, Message},
            await_result();
        {message_from, FromName, Message} ->
            io:format("Message from ~p: ~p~n", [FromName, Message])
    end,
    client(Server_Node).

%%% wait for a response from the server
await_result() ->
    receive
        {messenger, stop, Why} -> % Stop the client
            io:format("~p~n", [Why]),
            exit(normal);
        {messenger, What} ->  % Normal response
            io:format("~p~n", [What])
    after 5000 ->
            io:format("No response from server~n", []),
            exit(timeout)
    end.
```

The following changes are added:

The messenger server traps exits. If it receives an exit signal,
`{'EXIT',From,Reason}`, this means that a client process has terminated or is
unreachable for one of the following reasons:

- The user has logged off (the "logoff" message is removed).
- The network connection to the client is broken.
- The node on which the client process resides has gone down.
- The client processes has done some illegal operation.

If an exit signal is received as above, the tuple `{From,Name}` is deleted from
the servers `User_List` using the `server_logoff` function. If the node on which
the server runs goes down, an exit signal (automatically generated by the
system) is sent to all of the client processes:
`{'EXIT',MessengerPID,noconnection}` causing all the client processes to
terminate.

Also, a time-out of five seconds has been introduced in the `await_result`
function. That is, if the server does not reply within five seconds (5000 ms),
the client terminates. This is only needed in the logon sequence before the
client and the server are linked.

An interesting case is if the client terminates before the server links to it.
This is taken care of because linking to a non-existent process causes an exit
signal, `{'EXIT',From,noproc}`, to be automatically generated. This is as if the
process terminated immediately after the link operation.
