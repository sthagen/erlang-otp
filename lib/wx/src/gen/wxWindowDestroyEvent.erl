%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2008-2024. All Rights Reserved.
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

-module(wxWindowDestroyEvent).
-moduledoc """
Functions for wxWindowDestroyEvent class

This event is sent as early as possible during the window destruction process.

For the top level windows, as early as possible means that this is done by
`m:wxFrame` or `m:wxDialog` destructor, i.e. after the destructor of the derived
class was executed and so any methods specific to the derived class can't be
called any more from this event handler. If you need to do this, you must call
`wxWindow::SendDestroyEvent()` (not implemented in wx) from your derived class
destructor.

For the child windows, this event is generated just before deleting the window
from `wxWindow:'Destroy'/1` (which is also called when the parent window is
deleted) or from the window destructor if operator `delete` was used directly
(which is not recommended for this very reason).

It is usually pointless to handle this event in the window itself but it ca be
very useful to receive notifications about the window destruction in the parent
window or in any other object interested in this window.

See:
[Overview events](https://docs.wxwidgets.org/3.1/overview_events.html#overview_events),
`m:wxWindowCreateEvent`

This class is derived (and can use functions) from: `m:wxCommandEvent`
`m:wxEvent`

wxWidgets docs:
[wxWindowDestroyEvent](https://docs.wxwidgets.org/3.1/classwx_window_destroy_event.html)
""".
-include("wxe.hrl").
-export([]).

%% inherited exports
-export([getClientData/1,getExtraLong/1,getId/1,getInt/1,getSelection/1,getSkipped/1,
  getString/1,getTimestamp/1,isChecked/1,isCommandEvent/1,isSelection/1,
  parent_class/1,resumePropagation/2,setInt/2,setString/2,shouldPropagate/1,
  skip/1,skip/2,stopPropagation/1]).

-type wxWindowDestroyEvent() :: wx:wx_object().
-include("wx.hrl").
-type wxWindowDestroyEventType() :: 'destroy'.
-export_type([wxWindowDestroyEvent/0, wxWindowDestroy/0, wxWindowDestroyEventType/0]).
%% @hidden
-doc false.
parent_class(wxCommandEvent) -> true;
parent_class(wxEvent) -> true;
parent_class(_Class) -> erlang:error({badtype, ?MODULE}).

 %% From wxCommandEvent
%% @hidden
-doc false.
setString(This,String) -> wxCommandEvent:setString(This,String).
%% @hidden
-doc false.
setInt(This,IntCommand) -> wxCommandEvent:setInt(This,IntCommand).
%% @hidden
-doc false.
isSelection(This) -> wxCommandEvent:isSelection(This).
%% @hidden
-doc false.
isChecked(This) -> wxCommandEvent:isChecked(This).
%% @hidden
-doc false.
getString(This) -> wxCommandEvent:getString(This).
%% @hidden
-doc false.
getSelection(This) -> wxCommandEvent:getSelection(This).
%% @hidden
-doc false.
getInt(This) -> wxCommandEvent:getInt(This).
%% @hidden
-doc false.
getExtraLong(This) -> wxCommandEvent:getExtraLong(This).
%% @hidden
-doc false.
getClientData(This) -> wxCommandEvent:getClientData(This).
 %% From wxEvent
%% @hidden
-doc false.
stopPropagation(This) -> wxEvent:stopPropagation(This).
%% @hidden
-doc false.
skip(This, Options) -> wxEvent:skip(This, Options).
%% @hidden
-doc false.
skip(This) -> wxEvent:skip(This).
%% @hidden
-doc false.
shouldPropagate(This) -> wxEvent:shouldPropagate(This).
%% @hidden
-doc false.
resumePropagation(This,PropagationLevel) -> wxEvent:resumePropagation(This,PropagationLevel).
%% @hidden
-doc false.
isCommandEvent(This) -> wxEvent:isCommandEvent(This).
%% @hidden
-doc false.
getTimestamp(This) -> wxEvent:getTimestamp(This).
%% @hidden
-doc false.
getSkipped(This) -> wxEvent:getSkipped(This).
%% @hidden
-doc false.
getId(This) -> wxEvent:getId(This).
