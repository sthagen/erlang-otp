%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2009-2024. All Rights Reserved.
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
%% This file is generated DO NOT EDIT

-module(wxGridCellNumberEditor).
-moduledoc """
Functions for wxGridCellNumberEditor class

Grid cell editor for numeric integer data.

See: `m:wxGridCellEditor`, `wxGridCellAutoWrapStringEditor` (not implemented in
wx), `m:wxGridCellBoolEditor`, `m:wxGridCellChoiceEditor`,
`wxGridCellEnumEditor` (not implemented in wx), `m:wxGridCellFloatEditor`,
`m:wxGridCellTextEditor`, `wxGridCellDateEditor` (not implemented in wx)

This class is derived (and can use functions) from: `m:wxGridCellTextEditor`
`m:wxGridCellEditor`

wxWidgets docs:
[wxGridCellNumberEditor](https://docs.wxwidgets.org/3.1/classwx_grid_cell_number_editor.html)
""".
-include("wxe.hrl").
-export([destroy/1,getValue/1,new/0,new/1,setParameters/2]).

%% inherited exports
-export([handleReturn/2,isCreated/1,parent_class/1,reset/1,setSize/2,show/2,
  show/3,startingClick/1,startingKey/2]).

-type wxGridCellNumberEditor() :: wx:wx_object().
-export_type([wxGridCellNumberEditor/0]).
%% @hidden
-doc false.
parent_class(wxGridCellTextEditor) -> true;
parent_class(wxGridCellEditor) -> true;
parent_class(_Class) -> erlang:error({badtype, ?MODULE}).

%% @equiv new([])
-spec new() -> wxGridCellNumberEditor().

new() ->
  new([]).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridcellnumbereditor.html#wxgridcellnumbereditorwxgridcellnumbereditor">external documentation</a>.
-doc """
Allows you to specify the range for acceptable data.

Values equal to -1 for both `min` and `max` indicate that no range checking
should be done.
""".
-spec new([Option]) -> wxGridCellNumberEditor() when
	Option :: {'min', integer()}
		 | {'max', integer()}.
new(Options)
 when is_list(Options) ->
  MOpts = fun({min, _min} = Arg) -> Arg;
          ({max, _max} = Arg) -> Arg;
          (BadOpt) -> erlang:error({badoption, BadOpt}) end,
  Opts = lists:map(MOpts, Options),
  wxe_util:queue_cmd(Opts,?get_env(),?wxGridCellNumberEditor_new),
  wxe_util:rec(?wxGridCellNumberEditor_new).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridcellnumbereditor.html#wxgridcellnumbereditorgetvalue">external documentation</a>.
-doc "Returns the value currently in the editor control.".
-spec getValue(This) -> unicode:charlist() when
	This::wxGridCellNumberEditor().
getValue(#wx_ref{type=ThisT}=This) ->
  ?CLASS(ThisT,wxGridCellNumberEditor),
  wxe_util:queue_cmd(This,?get_env(),?wxGridCellNumberEditor_GetValue),
  wxe_util:rec(?wxGridCellNumberEditor_GetValue).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridcellnumbereditor.html#wxgridcellnumbereditorsetparameters">external documentation</a>.
-doc """
Parameters string format is "min,max".
""".
-spec setParameters(This, Params) -> 'ok' when
	This::wxGridCellNumberEditor(), Params::unicode:chardata().
setParameters(#wx_ref{type=ThisT}=This,Params)
 when ?is_chardata(Params) ->
  ?CLASS(ThisT,wxGridCellNumberEditor),
  Params_UC = unicode:characters_to_binary(Params),
  wxe_util:queue_cmd(This,Params_UC,?get_env(),?wxGridCellNumberEditor_SetParameters).

%% @doc Destroys this object, do not use object again
-doc "Destroys the object.".
-spec destroy(This::wxGridCellNumberEditor()) -> 'ok'.
destroy(Obj=#wx_ref{type=Type}) ->
  ?CLASS(Type,wxGridCellNumberEditor),
  wxe_util:queue_cmd(Obj, ?get_env(), ?wxGridCellNumberEditor_destroy),
  ok.
 %% From wxGridCellTextEditor
 %% From wxGridCellEditor
%% @hidden
-doc false.
handleReturn(This,Event) -> wxGridCellEditor:handleReturn(This,Event).
%% @hidden
-doc false.
startingClick(This) -> wxGridCellEditor:startingClick(This).
%% @hidden
-doc false.
startingKey(This,Event) -> wxGridCellEditor:startingKey(This,Event).
%% @hidden
-doc false.
reset(This) -> wxGridCellEditor:reset(This).
%% @hidden
-doc false.
show(This,Show, Options) -> wxGridCellEditor:show(This,Show, Options).
%% @hidden
-doc false.
show(This,Show) -> wxGridCellEditor:show(This,Show).
%% @hidden
-doc false.
setSize(This,Rect) -> wxGridCellEditor:setSize(This,Rect).
%% @hidden
-doc false.
isCreated(This) -> wxGridCellEditor:isCreated(This).
