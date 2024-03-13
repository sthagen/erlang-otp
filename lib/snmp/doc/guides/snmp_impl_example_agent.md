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
# Agent Implementation Example

This _Implementation Example_ section describes how an MIB can be implemented
with the SNMP Development Toolkit.

The example shown can be found in the toolkit distribution.

The agent is configured with the configuration tool, using default suggestions
for everything but the manager node.

## MIB

The MIB used in this example is called EX1-MIB. It contains two objects, a
variable with a name and a table with friends.

```text
EX1-MIB DEFINITIONS ::= BEGIN

          IMPORTS
                  experimental   FROM RFC1155-SMI
                  RowStatus      FROM STANDARD-MIB
                  DisplayString  FROM RFC1213-MIB
                  OBJECT-TYPE    FROM RFC-1212
                  ;

          example1       OBJECT IDENTIFIER ::= { experimental 7 }

          myName OBJECT-TYPE
              SYNTAX  DisplayString (SIZE (0..255))
              ACCESS  read-write
              STATUS  mandatory
              DESCRIPTION
                      "My own name"
              ::= { example1 1 }

          friendsTable OBJECT-TYPE
              SYNTAX  SEQUENCE OF FriendsEntry
              ACCESS  not-accessible
              STATUS  mandatory
              DESCRIPTION
                      "A list of friends."
              ::= { example1 4 }

          friendsEntry OBJECT-TYPE
              SYNTAX  FriendsEntry
              ACCESS  not-accessible
              STATUS  mandatory
              DESCRIPTION
                      ""
              INDEX   { fIndex }
              ::= { friendsTable 1 }

          FriendsEntry ::=
              SEQUENCE {
                   fIndex
                      INTEGER,
                   fName
                      DisplayString,
                   fAddress
                      DisplayString,
                   fStatus
                      RowStatus              }

          fIndex OBJECT-TYPE
              SYNTAX  INTEGER
              ACCESS  not-accessible
              STATUS  mandatory
               DESCRIPTION
                      "number of friend"
              ::= { friendsEntry 1 }

          fName OBJECT-TYPE
              SYNTAX  DisplayString (SIZE (0..255))
              ACCESS  read-write
              STATUS  mandatory
              DESCRIPTION
                      "Name of friend"
              ::= { friendsEntry 2 }

          fAddress OBJECT-TYPE
              SYNTAX  DisplayString (SIZE (0..255))
              ACCESS  read-write
              STATUS  mandatory
              DESCRIPTION
                      "Address of friend"
              ::= { friendsEntry 3 }

           fStatus OBJECT-TYPE
              SYNTAX      RowStatus
              ACCESS      read-write
              STATUS      mandatory
              DESCRIPTION
                      "The status of this conceptual row."
              ::= { friendsEntry 4 }

          fTrap TRAP-TYPE
              ENTERPRISE  example1
              VARIABLES   { myName, fIndex }
              DESCRIPTION
                      "This trap is sent when something happens to
                      the friend specified by fIndex."
              ::= 1
END
```

## Default Implementation

Without writing any instrumentation functions, we can compile the MIB and use
the default implementation of it. Recall that MIBs imported by "EX1-MIB.mib"
must be present and compiled in the current directory
("./STANDARD-MIB.bin","./RFC1213-MIB.bin") when compiling.

```erlang
unix> erl -config ./sys
1> application:start(snmp).
ok
2> snmpc:compile("EX1-MIB").
No accessfunction for 'friendsTable', using default.
No accessfunction for 'myName', using default.
{ok, "EX1-MIB.bin"}
3> snmpa:load_mibs(snmp_master_agent, ["EX1-MIB"]).
ok
```

This MIB is now loaded into the agent, and a manager can ask questions. As an
example of this, we start another Erlang system and the simple Erlang manager in
the toolkit:

```erlang
1> snmp_test_mgr:start_link([{agent,"dront.ericsson.se"},{community,"all-rights"},
 %% making it understand symbolic names: {mibs,["EX1-MIB","STANDARD-MIB"]}]).
{ok, <0.89.0>}
%% a get-next request with one OID.
2> snmp_test_mgr:gn([[1,3,6,1,3,7]]).
ok
* Got PDU:
[myName,0] = []
%% A set-request (now using symbolic names for convenience)
3> snmp_test_mgr:s([{[myName,0], "Martin"}]).
ok
* Got PDU:
[myName,0] = "Martin"
%% Try the same get-next request again
4> snmp_test_mgr:gn([[1,3,6,1,3,7]]).
ok
* Got PDU:
[myName,0] = "Martin"
%% ... and we got the new value.
%% you can event do row operations. How to add a row:
5> snmp_test_mgr:s([{[fName,0], "Martin"}, {[fAddress,0],"home"}, {[fStatus,0],4}]).
 %% createAndGo
ok
* Got PDU:
[fName,0] = "Martin"
[fAddress,0] = "home"
[fStatus,0] = 4
6> snmp_test_mgr:gn([[myName,0]]).
ok
* Got PDU:
[fName,0] = "Martin"
7> snmp_test_mgr:gn().
ok
* Got PDU:
[fAddress,0] = "home"
8> snmp_test_mgr:gn().
ok
* Got PDU:
[fStatus,0] = 1
9>
```

## Manual Implementation

The following example shows a "manual" implementation of the EX1-MIB in Erlang.
In this example, the values of the objects are stored in an Erlang server. The
server has a 2-tuple as loop data, where the first element is the value of
variable `myName`, and the second is a sorted list of rows in the table
`friendsTable`. Each row is a 4-tuple.

> #### Note {: .info }
>
> There are more efficient ways to create tables manually, i.e. to use the
> module `snmp_index`.

### Code

```erlang
-module(ex1).
-author('dummy@flop.org').
%% External exports
-export([start/0, my_name/1, my_name/2, friends_table/3]).
%% Internal exports
-export([init/0]).
-define(status_col, 4).
-define(active, 1).
-define(notInService, 2).
-define(notReady, 3).
-define(createAndGo, 4).   % Action; written, not read
-define(createAndWait, 5). % Action; written, not read
-define(destroy, 6).       % Action; written, not read
start() ->
    spawn(ex1, init, []).
%%----------------------------------------------------------------
%% Instrumentation function for variable myName.
%% Returns: (get) {value, Name}
%%          (set) noError
%%----------------------------------------------------------------
my_name(get) ->
    ex1_server ! {self(), get_my_name},
    Name = wait_answer(),
    {value, Name}.
my_name(set, NewName) ->
    ex1_server ! {self(), {set_my_name, NewName}},
    noError.
%%----------------------------------------------------------------
%% Instrumentation function for table friendsTable.
%%----------------------------------------------------------------
friends_table(get, RowIndex, Cols) ->
    case get_row(RowIndex) of
   {ok, Row} ->
        get_cols(Cols, Row);
   _  ->
        {noValue, noSuchInstance}
    end;
friends_table(get_next, RowIndex, Cols) ->
    case get_next_row(RowIndex) of
   {ok, Row} ->
        get_next_cols(Cols, Row);
   _  ->
       case get_next_row([]) of
     {ok, Row} ->
         % Get next cols from first row.
         NewCols = add_one_to_cols(Cols),
         get_next_cols(NewCols, Row);
     _  ->
        end_of_table(Cols)
        end
    end;
%%----------------------------------------------------------------
%% If RowStatus is set, then:
%%    *) If set to destroy, check that row does exist
%%    *) If set to createAndGo, check that row does not exist AND
%%         that all columns are given values.
%%    *) Otherwise, error (for simplicity).
%% Otherwise, row is modified; check that row exists.
%%----------------------------------------------------------------
friends_table(is_set_ok, RowIndex, Cols) ->
    RowExists =
   case get_row(RowIndex) of
        {ok, _Row} -> true;
       _ -> false
   end,
    case is_row_status_col_changed(Cols) of
   {true, ?destroy} when RowExists == true ->
        {noError, 0};
   {true, ?createAndGo} when RowExists == false,
                                 length(Cols) == 3 ->
        {noError, 0};
   {true, _} ->
       {inconsistentValue, ?status_col};
   false when RowExists == true ->
        {noError, 0};
   _ ->
        [{Col, _NewVal} | _Cols] = Cols,
       {inconsistentName, Col}
      end;
friends_table(set, RowIndex, Cols) ->
    case is_row_status_col_changed(Cols) of
   {true, ?destroy} ->
        ex1_server ! {self(), {delete_row, RowIndex}};
   {true, ?createAndGo} ->
       NewRow = make_row(RowIndex, Cols),
        ex1_server ! {self(), {add_row, NewRow}};
   false ->
       {ok, Row} = get_row(RowIndex),
        NewRow = merge_rows(Row, Cols),
    ex1_server ! {self(), {delete_row, RowIndex}},
       ex1_server ! {self(), {add_row, NewRow}}
   end,
    {noError, 0}.

%%----------------------------------------------------------------
%% Make a list of {value, Val} of the Row and Cols list.
%%----------------------------------------------------------------
get_cols([Col | Cols], Row) ->
    [{value, element(Col, Row)} | get_cols(Cols, Row)];
get_cols([], _Row) ->
    [].
%%----------------------------------------------------------------
%% As get_cols, but the Cols list may contain invalid column
%% numbers. If it does, we must find the next valid column,
%% or return endOfTable.
%%----------------------------------------------------------------
get_next_cols([Col | Cols], Row) when Col < 2 ->
    [{[2, element(1, Row)], element(2, Row)} |
     get_next_cols(Cols, Row)];
get_next_cols([Col | Cols], Row) when Col > 4 ->
    [endOfTable |
     get_next_cols(Cols, Row)];
get_next_cols([Col | Cols], Row) ->
    [{[Col, element(1, Row)], element(Col, Row)} |
     get_next_cols(Cols, Row)];
get_next_cols([], _Row) ->
    [].
%%----------------------------------------------------------------
%% Make a list of endOfTable with as many elems as Cols list.
%%----------------------------------------------------------------
end_of_table([Col | Cols]) ->
    [endOfTable | end_of_table(Cols)];
end_of_table([]) ->
    [].
add_one_to_cols([Col | Cols]) ->
    [Col + 1 | add_one_to_cols(Cols)];
add_one_to_cols([]) ->
    [].
is_row_status_col_changed(Cols) ->
    case lists:keysearch(?status_col, 1, Cols) of
   {value, {?status_col, StatusVal}} ->
        {true, StatusVal};
   _ -> false
    end.
get_row(RowIndex) ->
    ex1_server ! {self(), {get_row, RowIndex}},
    wait_answer().
get_next_row(RowIndex) ->
    ex1_server ! {self(), {get_next_row, RowIndex}},
    wait_answer().
wait_answer() ->
    receive
   {ex1_server, Answer} ->
     Answer
    end.
%%%---------------------------------------------------------------
%%% Server code follows
%%%---------------------------------------------------------------
init() ->
    register(ex1_server, self()),
    loop("", []).

loop(MyName, Table) ->
    receive
   {From, get_my_name} ->
        From ! {ex1_server, MyName},
       loop(MyName, Table);
   {From, {set_my_name, NewName}} ->
        loop(NewName, Table);
   {From, {get_row, RowIndex}} ->
       Res = table_get_row(Table, RowIndex),
       From ! {ex1_server, Res},
       loop(MyName, Table);
   {From, {get_next_row, RowIndex}} ->
       Res = table_get_next_row(Table, RowIndex),
        From ! {ex1_server, Res},
       loop(MyName, Table);
   {From, {delete_row, RowIndex}} ->
    NewTable = table_delete_row(Table, RowIndex),
       loop(MyName, NewTable);
   {From, {add_row, NewRow}} ->
       NewTable = table_add_row(Table, NewRow),
       loop(MyName, NewTable)
    end.
%%%---------------------------------------------------------------
%%% Functions for table operations. The table is represented as
%%% a list of rows.
%%%---------------------------------------------------------------
table_get_row([{Index, Name, Address, Status} | _], [Index]) ->
    {ok, {Index, Name, Address, Status}};
table_get_row([H | T], RowIndex) ->
    table_get_row(T, RowIndex);
table_get_row([], _RowIndex) ->
    no_such_row.
table_get_next_row([Row | T], []) ->
    {ok, Row};
table_get_next_row([Row | T], [Index | _])
when element(1, Row) > Index ->
    {ok, Row};
table_get_next_row([Row | T], RowIndex) ->
    table_get_next_row(T, RowIndex);
table_get_next_row([], RowIndex) ->
    endOfTable.
table_delete_row([{Index, _, _, _} | T], [Index]) ->
    T;
table_delete_row([H | T], RowIndex) ->
    [H | table_delete_row(T, RowIndex)];
table_delete_row([], _RowIndex) ->
    [].
table_add_row([Row | T], NewRow)
  when element(1, Row) > element(1, NewRow) ->
    [NewRow, Row | T];
table_add_row([H | T], NewRow) ->
    [H | table_add_row(T, NewRow)];
table_add_row([], NewRow) ->
    [NewRow].
make_row([Index], [{2, Name}, {3, Address} | _]) ->
    {Index, Name, Address, ?active}.
merge_rows(Row, [{Col, NewVal} | T]) ->
    merge_rows(setelement(Col, Row, NewVal), T);
merge_rows(Row, []) ->
    Row.
```

### Association File

The association file `EX1-MIB.funcs` for the real implementation looks as
follows:

```erlang
{myName, {ex1, my_name, []}}.
{friendsTable, {ex1, friends_table, []}}.
```

### Transcript

To use the real implementation, we must recompile the MIB and load it into the
agent.

```erlang
1> application:start(snmp).
ok
2> snmpc:compile("EX1-MIB").
{ok,"EX1-MIB.bin"}
3> snmpa:load_mibs(snmp_master_agent, ["EX1-MIB"]).
ok
4> ex1:start().
<0.115.0>
%% Now all requests operates on this "real" implementation.
%% The output from the manager requests will *look* exactly the
%% same as for the default implementation.
```

### Trap Sending

How to send a trap by sending the `fTrap` from the master agent is shown in this
section. The master agent has the MIB `EX1-MIB` loaded, where the trap is
defined. This trap specifies that two variables should be sent along with the
trap, `myName` and `fIndex`. `fIndex` is a table column, so we must provide its
value and the index for the row in the call to `snmpa:send_notification2/3`. In the
example below, we assume that the row in question is indexed by 2 (the row with
`fIndex` 2).

we use a simple Erlang SNMP manager, which can receive traps.

```erlang
[MANAGER]
1> snmp_test_mgr:start_link([{agent,"dront.ericsson.se"},{community,"public"}
 %% does not have write-access
1>{mibs,["EX1-MIB","STANDARD-MIB"]}]).
{ok, <0.100.0>}
2> snmp_test_mgr:s([{[myName,0], "Klas"}]).
ok
* Got PDU:
Received a trap:
      Generic: 4       %% authenticationFailure
   Enterprise: [iso,2,3]
     Specific: 0
   Agent addr: [123,12,12,21]
    TimeStamp: 42993
2>
[AGENT]
3> SendOpts = [{receiver, no_receiver}, {varbinds, [{fIndex,[2],2}]}, {name, "standard trap"}, {context, ""}],
4> snmpa:send_notification2(snmp_master_agent, fTrap, SendOpts).
[MANAGER]
2>
* Got PDU:
Received a trap:
      Generic: 6
   Enterprise: [example1]
     Specific: 1
   Agent addr: [123,12,12,21]
    TimeStamp: 69649
[myName,0] = "Martin"
[fIndex,2] = 2
2>
```
