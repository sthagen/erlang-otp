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

-module(wxGridBagSizer).
-moduledoc """
Functions for wxGridBagSizer class

A `m:wxSizer` that can lay out items in a virtual grid like a
`m:wxFlexGridSizer` but in this case explicit positioning of the items is
allowed using `wxGBPosition` (not implemented in wx), and items can optionally
span more than one row and/or column using `wxGBSpan` (not implemented in wx).

This class is derived (and can use functions) from: `m:wxFlexGridSizer`
`m:wxGridSizer` `m:wxSizer`

wxWidgets docs:
[wxGridBagSizer](https://docs.wxwidgets.org/3.1/classwx_grid_bag_sizer.html)
""".
-include("wxe.hrl").
-export([add/2,add/3,add/4,add/5,calcMin/1,checkForIntersection/2,checkForIntersection/3,
  checkForIntersection/4,destroy/1,findItem/2,findItemAtPoint/2,findItemAtPosition/2,
  findItemWithData/2,getCellSize/3,getEmptyCellSize/1,getItemPosition/2,
  getItemSpan/2,new/0,new/1,setEmptyCellSize/2,setItemPosition/3,setItemSpan/3]).

%% inherited exports
-export([addGrowableCol/2,addGrowableCol/3,addGrowableRow/2,addGrowableRow/3,
  addSpacer/2,addStretchSpacer/1,addStretchSpacer/2,clear/1,clear/2,
  detach/2,fit/2,fitInside/2,getChildren/1,getCols/1,getFlexibleDirection/1,
  getHGap/1,getItem/2,getItem/3,getMinSize/1,getNonFlexibleGrowMode/1,
  getPosition/1,getRows/1,getSize/1,getVGap/1,hide/2,hide/3,insert/3,insert/4,
  insert/5,insertSpacer/3,insertStretchSpacer/2,insertStretchSpacer/3,
  isShown/2,layout/1,parent_class/1,prepend/2,prepend/3,prepend/4,prependSpacer/2,
  prependStretchSpacer/1,prependStretchSpacer/2,recalcSizes/1,remove/2,
  removeGrowableCol/2,removeGrowableRow/2,replace/3,replace/4,setCols/2,
  setDimension/3,setDimension/5,setFlexibleDirection/2,setHGap/2,setItemMinSize/3,
  setItemMinSize/4,setMinSize/2,setMinSize/3,setNonFlexibleGrowMode/2,
  setRows/2,setSizeHints/2,setVGap/2,setVirtualSizeHints/2,show/2,show/3,
  showItems/2]).

-type wxGridBagSizer() :: wx:wx_object().
-export_type([wxGridBagSizer/0]).
%% @hidden
-doc false.
parent_class(wxFlexGridSizer) -> true;
parent_class(wxGridSizer) -> true;
parent_class(wxSizer) -> true;
parent_class(_Class) -> erlang:error({badtype, ?MODULE}).

%% @equiv new([])
-spec new() -> wxGridBagSizer().

new() ->
  new([]).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizerwxgridbagsizer">external documentation</a>.
-doc """
Constructor, with optional parameters to specify the gap between the rows and
columns.
""".
-spec new([Option]) -> wxGridBagSizer() when
	Option :: {'vgap', integer()}
		 | {'hgap', integer()}.
new(Options)
 when is_list(Options) ->
  MOpts = fun({vgap, _vgap} = Arg) -> Arg;
          ({hgap, _hgap} = Arg) -> Arg;
          (BadOpt) -> erlang:error({badoption, BadOpt}) end,
  Opts = lists:map(MOpts, Options),
  wxe_util:queue_cmd(Opts,?get_env(),?wxGridBagSizer_new),
  wxe_util:rec(?wxGridBagSizer_new).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizeradd">external documentation</a>.
-spec add(This, Item) -> wxSizerItem:wxSizerItem() when
	This::wxGridBagSizer(), Item::wxGBSizerItem:wxGBSizerItem().
add(#wx_ref{type=ThisT}=This,#wx_ref{type=ItemT}=Item) ->
  ?CLASS(ThisT,wxGridBagSizer),
  ?CLASS(ItemT,wxGBSizerItem),
  wxe_util:queue_cmd(This,Item,?get_env(),?wxGridBagSizer_Add_1),
  wxe_util:rec(?wxGridBagSizer_Add_1).

%% @equiv add(This,Window,Pos, [])
-spec add(This, Window, Pos) -> wxSizerItem:wxSizerItem() when
	This::wxGridBagSizer(), Window::wxWindow:wxWindow() | wxSizer:wxSizer(), Pos::{R::integer(), C::integer()}.

add(This,Window,{PosR,PosC} = Pos)
 when is_record(This, wx_ref),is_record(Window, wx_ref),is_integer(PosR),is_integer(PosC) ->
  add(This,Window,Pos, []).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizeradd">external documentation</a>.
%% <br /> Also:<br />
%% add(This, Window, Pos, [Option]) -> wxSizerItem:wxSizerItem() when<br />
%% 	This::wxGridBagSizer(), Window::wxWindow:wxWindow() | wxSizer:wxSizer(), Pos::{R::integer(), C::integer()},<br />
%% 	Option :: {'span', {RS::integer(), CS::integer()}}<br />
%% 		 | {'flag', integer()}<br />
%% 		 | {'border', integer()}<br />
%% 		 | {'userData', wx:wx_object()}.<br />
%% 
-doc """
Adds the given item to the given position.

Return: A valid pointer if the item was successfully placed at the given
position, or NULL if something was already there.
""".
-spec add(This, Width, Height, Pos) -> wxSizerItem:wxSizerItem() when
	This::wxGridBagSizer(), Width::integer(), Height::integer(), Pos::{R::integer(), C::integer()};
      (This, Window, Pos, [Option]) -> wxSizerItem:wxSizerItem() when
	This::wxGridBagSizer(), Window::wxWindow:wxWindow() | wxSizer:wxSizer(), Pos::{R::integer(), C::integer()},
	Option :: {'span', {RS::integer(), CS::integer()}}
		 | {'flag', integer()}
		 | {'border', integer()}
		 | {'userData', wx:wx_object()}.

add(This,Width,Height,{PosR,PosC} = Pos)
 when is_record(This, wx_ref),is_integer(Width),is_integer(Height),is_integer(PosR),is_integer(PosC) ->
  add(This,Width,Height,Pos, []);
add(#wx_ref{type=ThisT}=This,#wx_ref{type=WindowT}=Window,{PosR,PosC} = Pos, Options)
 when is_integer(PosR),is_integer(PosC),is_list(Options) ->
  ?CLASS(ThisT,wxGridBagSizer),
  IswxWindow = ?CLASS_T(WindowT,wxWindow),
  IswxSizer = ?CLASS_T(WindowT,wxSizer),
  WindowType = if
    IswxWindow ->   wxWindow;
    IswxSizer ->   wxSizer;
    true -> error({badarg, WindowT})
  end,
  MOpts = fun({span, {_spanRS,_spanCS}} = Arg) -> Arg;
          ({flag, _flag} = Arg) -> Arg;
          ({border, _border} = Arg) -> Arg;
          ({userData, #wx_ref{type=UserDataT}} = Arg) ->   ?CLASS(UserDataT,wx),Arg;
          (BadOpt) -> erlang:error({badoption, BadOpt}) end,
  Opts = lists:map(MOpts, Options),
  wxe_util:queue_cmd(This,wx:typeCast(Window, WindowType),Pos, Opts,?get_env(),?wxGridBagSizer_Add_3),
  wxe_util:rec(?wxGridBagSizer_Add_3).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizeradd">external documentation</a>.
-doc """
Adds a spacer to the given position.

`width` and `height` specify the dimension of the spacer to be added.

Return: A valid pointer if the spacer was successfully placed at the given
position, or NULL if something was already there.
""".
-spec add(This, Width, Height, Pos, [Option]) -> wxSizerItem:wxSizerItem() when
	This::wxGridBagSizer(), Width::integer(), Height::integer(), Pos::{R::integer(), C::integer()},
	Option :: {'span', {RS::integer(), CS::integer()}}
		 | {'flag', integer()}
		 | {'border', integer()}
		 | {'userData', wx:wx_object()}.
add(#wx_ref{type=ThisT}=This,Width,Height,{PosR,PosC} = Pos, Options)
 when is_integer(Width),is_integer(Height),is_integer(PosR),is_integer(PosC),is_list(Options) ->
  ?CLASS(ThisT,wxGridBagSizer),
  MOpts = fun({span, {_spanRS,_spanCS}} = Arg) -> Arg;
          ({flag, _flag} = Arg) -> Arg;
          ({border, _border} = Arg) -> Arg;
          ({userData, #wx_ref{type=UserDataT}} = Arg) ->   ?CLASS(UserDataT,wx),Arg;
          (BadOpt) -> erlang:error({badoption, BadOpt}) end,
  Opts = lists:map(MOpts, Options),
  wxe_util:queue_cmd(This,Width,Height,Pos, Opts,?get_env(),?wxGridBagSizer_Add_4),
  wxe_util:rec(?wxGridBagSizer_Add_4).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizercalcmin">external documentation</a>.
-doc "Called when the managed size of the sizer is needed or when layout needs done.".
-spec calcMin(This) -> {W::integer(), H::integer()} when
	This::wxGridBagSizer().
calcMin(#wx_ref{type=ThisT}=This) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,?get_env(),?wxGridBagSizer_CalcMin),
  wxe_util:rec(?wxGridBagSizer_CalcMin).

%% @equiv checkForIntersection(This,Item, [])
-spec checkForIntersection(This, Item) -> boolean() when
	This::wxGridBagSizer(), Item::wxGBSizerItem:wxGBSizerItem().

checkForIntersection(This,Item)
 when is_record(This, wx_ref),is_record(Item, wx_ref) ->
  checkForIntersection(This,Item, []).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizercheckforintersection">external documentation</a>.
%% <br /> Also:<br />
%% checkForIntersection(This, Item, [Option]) -> boolean() when<br />
%% 	This::wxGridBagSizer(), Item::wxGBSizerItem:wxGBSizerItem(),<br />
%% 	Option :: {'excludeItem', wxGBSizerItem:wxGBSizerItem()}.<br />
%% 
-doc """
Look at all items and see if any intersect (or would overlap) the given item.

Returns true if so, false if there would be no overlap. If an `excludeItem` is
given then it will not be checked for intersection, for example it may be the
item we are checking the position of.
""".
-spec checkForIntersection(This, Pos, Span) -> boolean() when
	This::wxGridBagSizer(), Pos::{R::integer(), C::integer()}, Span::{RS::integer(), CS::integer()};
      (This, Item, [Option]) -> boolean() when
	This::wxGridBagSizer(), Item::wxGBSizerItem:wxGBSizerItem(),
	Option :: {'excludeItem', wxGBSizerItem:wxGBSizerItem()}.

checkForIntersection(This,{PosR,PosC} = Pos,{SpanRS,SpanCS} = Span)
 when is_record(This, wx_ref),is_integer(PosR),is_integer(PosC),is_integer(SpanRS),is_integer(SpanCS) ->
  checkForIntersection(This,Pos,Span, []);
checkForIntersection(#wx_ref{type=ThisT}=This,#wx_ref{type=ItemT}=Item, Options)
 when is_list(Options) ->
  ?CLASS(ThisT,wxGridBagSizer),
  ?CLASS(ItemT,wxGBSizerItem),
  MOpts = fun({excludeItem, #wx_ref{type=ExcludeItemT}} = Arg) ->   ?CLASS(ExcludeItemT,wxGBSizerItem),Arg;
          (BadOpt) -> erlang:error({badoption, BadOpt}) end,
  Opts = lists:map(MOpts, Options),
  wxe_util:queue_cmd(This,Item, Opts,?get_env(),?wxGridBagSizer_CheckForIntersection_2),
  wxe_util:rec(?wxGridBagSizer_CheckForIntersection_2).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizercheckforintersection">external documentation</a>.
-spec checkForIntersection(This, Pos, Span, [Option]) -> boolean() when
	This::wxGridBagSizer(), Pos::{R::integer(), C::integer()}, Span::{RS::integer(), CS::integer()},
	Option :: {'excludeItem', wxGBSizerItem:wxGBSizerItem()}.
checkForIntersection(#wx_ref{type=ThisT}=This,{PosR,PosC} = Pos,{SpanRS,SpanCS} = Span, Options)
 when is_integer(PosR),is_integer(PosC),is_integer(SpanRS),is_integer(SpanCS),is_list(Options) ->
  ?CLASS(ThisT,wxGridBagSizer),
  MOpts = fun({excludeItem, #wx_ref{type=ExcludeItemT}} = Arg) ->   ?CLASS(ExcludeItemT,wxGBSizerItem),Arg;
          (BadOpt) -> erlang:error({badoption, BadOpt}) end,
  Opts = lists:map(MOpts, Options),
  wxe_util:queue_cmd(This,Pos,Span, Opts,?get_env(),?wxGridBagSizer_CheckForIntersection_3),
  wxe_util:rec(?wxGridBagSizer_CheckForIntersection_3).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizerfinditem">external documentation</a>.
-doc """
Find the sizer item for the given window or subsizer, returns NULL if not found.

(non-recursive)
""".
-spec findItem(This, Window) -> wxGBSizerItem:wxGBSizerItem() when
	This::wxGridBagSizer(), Window::wxWindow:wxWindow() | wxSizer:wxSizer().
findItem(#wx_ref{type=ThisT}=This,#wx_ref{type=WindowT}=Window) ->
  ?CLASS(ThisT,wxGridBagSizer),
  IswxWindow = ?CLASS_T(WindowT,wxWindow),
  IswxSizer = ?CLASS_T(WindowT,wxSizer),
  WindowType = if
    IswxWindow ->   wxWindow;
    IswxSizer ->   wxSizer;
    true -> error({badarg, WindowT})
  end,
  wxe_util:queue_cmd(This,wx:typeCast(Window, WindowType),?get_env(),?wxGridBagSizer_FindItem),
  wxe_util:rec(?wxGridBagSizer_FindItem).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizerfinditematpoint">external documentation</a>.
-doc """
Return the sizer item located at the point given in pt, or NULL if there is no
item at that point.

The (x,y) coordinates in `pt` correspond to the client coordinates of the window
using the sizer for layout. (non-recursive)
""".
-spec findItemAtPoint(This, Pt) -> wxGBSizerItem:wxGBSizerItem() when
	This::wxGridBagSizer(), Pt::{X::integer(), Y::integer()}.
findItemAtPoint(#wx_ref{type=ThisT}=This,{PtX,PtY} = Pt)
 when is_integer(PtX),is_integer(PtY) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,Pt,?get_env(),?wxGridBagSizer_FindItemAtPoint),
  wxe_util:rec(?wxGridBagSizer_FindItemAtPoint).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizerfinditematposition">external documentation</a>.
-doc """
Return the sizer item for the given grid cell, or NULL if there is no item at
that position.

(non-recursive)
""".
-spec findItemAtPosition(This, Pos) -> wxGBSizerItem:wxGBSizerItem() when
	This::wxGridBagSizer(), Pos::{R::integer(), C::integer()}.
findItemAtPosition(#wx_ref{type=ThisT}=This,{PosR,PosC} = Pos)
 when is_integer(PosR),is_integer(PosC) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,Pos,?get_env(),?wxGridBagSizer_FindItemAtPosition),
  wxe_util:rec(?wxGridBagSizer_FindItemAtPosition).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizerfinditemwithdata">external documentation</a>.
-doc """
Return the sizer item that has a matching user data (it only compares pointer
values) or NULL if not found.

(non-recursive)
""".
-spec findItemWithData(This, UserData) -> wxGBSizerItem:wxGBSizerItem() when
	This::wxGridBagSizer(), UserData::wx:wx_object().
findItemWithData(#wx_ref{type=ThisT}=This,#wx_ref{type=UserDataT}=UserData) ->
  ?CLASS(ThisT,wxGridBagSizer),
  ?CLASS(UserDataT,wx),
  wxe_util:queue_cmd(This,UserData,?get_env(),?wxGridBagSizer_FindItemWithData),
  wxe_util:rec(?wxGridBagSizer_FindItemWithData).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizergetcellsize">external documentation</a>.
-doc """
Get the size of the specified cell, including hgap and vgap.

Only valid after window layout has been performed.
""".
-spec getCellSize(This, Row, Col) -> {W::integer(), H::integer()} when
	This::wxGridBagSizer(), Row::integer(), Col::integer().
getCellSize(#wx_ref{type=ThisT}=This,Row,Col)
 when is_integer(Row),is_integer(Col) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,Row,Col,?get_env(),?wxGridBagSizer_GetCellSize),
  wxe_util:rec(?wxGridBagSizer_GetCellSize).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizergetemptycellsize">external documentation</a>.
-doc "Get the size used for cells in the grid with no item.".
-spec getEmptyCellSize(This) -> {W::integer(), H::integer()} when
	This::wxGridBagSizer().
getEmptyCellSize(#wx_ref{type=ThisT}=This) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,?get_env(),?wxGridBagSizer_GetEmptyCellSize),
  wxe_util:rec(?wxGridBagSizer_GetEmptyCellSize).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizergetitemposition">external documentation</a>.
%% <br /> Also:<br />
%% getItemPosition(This, Index) -> {R::integer(), C::integer()} when<br />
%% 	This::wxGridBagSizer(), Index::integer().<br />
%% 
-spec getItemPosition(This, Window) -> {R::integer(), C::integer()} when
	This::wxGridBagSizer(), Window::wxWindow:wxWindow() | wxSizer:wxSizer();
      (This, Index) -> {R::integer(), C::integer()} when
	This::wxGridBagSizer(), Index::integer().
getItemPosition(#wx_ref{type=ThisT}=This,#wx_ref{type=WindowT}=Window) ->
  ?CLASS(ThisT,wxGridBagSizer),
  IswxWindow = ?CLASS_T(WindowT,wxWindow),
  IswxSizer = ?CLASS_T(WindowT,wxSizer),
  WindowType = if
    IswxWindow ->   wxWindow;
    IswxSizer ->   wxSizer;
    true -> error({badarg, WindowT})
  end,
  wxe_util:queue_cmd(This,wx:typeCast(Window, WindowType),?get_env(),?wxGridBagSizer_GetItemPosition_1_0),
  wxe_util:rec(?wxGridBagSizer_GetItemPosition_1_0);
getItemPosition(#wx_ref{type=ThisT}=This,Index)
 when is_integer(Index) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,Index,?get_env(),?wxGridBagSizer_GetItemPosition_1_1),
  wxe_util:rec(?wxGridBagSizer_GetItemPosition_1_1).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizergetitemspan">external documentation</a>.
%% <br /> Also:<br />
%% getItemSpan(This, Index) -> {RS::integer(), CS::integer()} when<br />
%% 	This::wxGridBagSizer(), Index::integer().<br />
%% 
-spec getItemSpan(This, Window) -> {RS::integer(), CS::integer()} when
	This::wxGridBagSizer(), Window::wxWindow:wxWindow() | wxSizer:wxSizer();
      (This, Index) -> {RS::integer(), CS::integer()} when
	This::wxGridBagSizer(), Index::integer().
getItemSpan(#wx_ref{type=ThisT}=This,#wx_ref{type=WindowT}=Window) ->
  ?CLASS(ThisT,wxGridBagSizer),
  IswxWindow = ?CLASS_T(WindowT,wxWindow),
  IswxSizer = ?CLASS_T(WindowT,wxSizer),
  WindowType = if
    IswxWindow ->   wxWindow;
    IswxSizer ->   wxSizer;
    true -> error({badarg, WindowT})
  end,
  wxe_util:queue_cmd(This,wx:typeCast(Window, WindowType),?get_env(),?wxGridBagSizer_GetItemSpan_1_0),
  wxe_util:rec(?wxGridBagSizer_GetItemSpan_1_0);
getItemSpan(#wx_ref{type=ThisT}=This,Index)
 when is_integer(Index) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,Index,?get_env(),?wxGridBagSizer_GetItemSpan_1_1),
  wxe_util:rec(?wxGridBagSizer_GetItemSpan_1_1).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizersetemptycellsize">external documentation</a>.
-doc "Set the size used for cells in the grid with no item.".
-spec setEmptyCellSize(This, Sz) -> 'ok' when
	This::wxGridBagSizer(), Sz::{W::integer(), H::integer()}.
setEmptyCellSize(#wx_ref{type=ThisT}=This,{SzW,SzH} = Sz)
 when is_integer(SzW),is_integer(SzH) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,Sz,?get_env(),?wxGridBagSizer_SetEmptyCellSize).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizersetitemposition">external documentation</a>.
%% <br /> Also:<br />
%% setItemPosition(This, Index, Pos) -> boolean() when<br />
%% 	This::wxGridBagSizer(), Index::integer(), Pos::{R::integer(), C::integer()}.<br />
%% 
-spec setItemPosition(This, Window, Pos) -> boolean() when
	This::wxGridBagSizer(), Window::wxWindow:wxWindow() | wxSizer:wxSizer(), Pos::{R::integer(), C::integer()};
      (This, Index, Pos) -> boolean() when
	This::wxGridBagSizer(), Index::integer(), Pos::{R::integer(), C::integer()}.
setItemPosition(#wx_ref{type=ThisT}=This,#wx_ref{type=WindowT}=Window,{PosR,PosC} = Pos)
 when is_integer(PosR),is_integer(PosC) ->
  ?CLASS(ThisT,wxGridBagSizer),
  IswxWindow = ?CLASS_T(WindowT,wxWindow),
  IswxSizer = ?CLASS_T(WindowT,wxSizer),
  WindowType = if
    IswxWindow ->   wxWindow;
    IswxSizer ->   wxSizer;
    true -> error({badarg, WindowT})
  end,
  wxe_util:queue_cmd(This,wx:typeCast(Window, WindowType),Pos,?get_env(),?wxGridBagSizer_SetItemPosition_2_0),
  wxe_util:rec(?wxGridBagSizer_SetItemPosition_2_0);
setItemPosition(#wx_ref{type=ThisT}=This,Index,{PosR,PosC} = Pos)
 when is_integer(Index),is_integer(PosR),is_integer(PosC) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,Index,Pos,?get_env(),?wxGridBagSizer_SetItemPosition_2_1),
  wxe_util:rec(?wxGridBagSizer_SetItemPosition_2_1).

%% @doc See <a href="http://www.wxwidgets.org/manuals/2.8.12/wx_wxgridbagsizer.html#wxgridbagsizersetitemspan">external documentation</a>.
%% <br /> Also:<br />
%% setItemSpan(This, Index, Span) -> boolean() when<br />
%% 	This::wxGridBagSizer(), Index::integer(), Span::{RS::integer(), CS::integer()}.<br />
%% 
-spec setItemSpan(This, Window, Span) -> boolean() when
	This::wxGridBagSizer(), Window::wxWindow:wxWindow() | wxSizer:wxSizer(), Span::{RS::integer(), CS::integer()};
      (This, Index, Span) -> boolean() when
	This::wxGridBagSizer(), Index::integer(), Span::{RS::integer(), CS::integer()}.
setItemSpan(#wx_ref{type=ThisT}=This,#wx_ref{type=WindowT}=Window,{SpanRS,SpanCS} = Span)
 when is_integer(SpanRS),is_integer(SpanCS) ->
  ?CLASS(ThisT,wxGridBagSizer),
  IswxWindow = ?CLASS_T(WindowT,wxWindow),
  IswxSizer = ?CLASS_T(WindowT,wxSizer),
  WindowType = if
    IswxWindow ->   wxWindow;
    IswxSizer ->   wxSizer;
    true -> error({badarg, WindowT})
  end,
  wxe_util:queue_cmd(This,wx:typeCast(Window, WindowType),Span,?get_env(),?wxGridBagSizer_SetItemSpan_2_0),
  wxe_util:rec(?wxGridBagSizer_SetItemSpan_2_0);
setItemSpan(#wx_ref{type=ThisT}=This,Index,{SpanRS,SpanCS} = Span)
 when is_integer(Index),is_integer(SpanRS),is_integer(SpanCS) ->
  ?CLASS(ThisT,wxGridBagSizer),
  wxe_util:queue_cmd(This,Index,Span,?get_env(),?wxGridBagSizer_SetItemSpan_2_1),
  wxe_util:rec(?wxGridBagSizer_SetItemSpan_2_1).

%% @doc Destroys this object, do not use object again
-doc "Destroys the object.".
-spec destroy(This::wxGridBagSizer()) -> 'ok'.
destroy(Obj=#wx_ref{type=Type}) ->
  ?CLASS(Type,wxGridBagSizer),
  wxe_util:queue_cmd(Obj, ?get_env(), ?DESTROY_OBJECT),
  ok.
 %% From wxFlexGridSizer
%% @hidden
-doc false.
setNonFlexibleGrowMode(This,Mode) -> wxFlexGridSizer:setNonFlexibleGrowMode(This,Mode).
%% @hidden
-doc false.
setFlexibleDirection(This,Direction) -> wxFlexGridSizer:setFlexibleDirection(This,Direction).
%% @hidden
-doc false.
removeGrowableRow(This,Idx) -> wxFlexGridSizer:removeGrowableRow(This,Idx).
%% @hidden
-doc false.
removeGrowableCol(This,Idx) -> wxFlexGridSizer:removeGrowableCol(This,Idx).
%% @hidden
-doc false.
getNonFlexibleGrowMode(This) -> wxFlexGridSizer:getNonFlexibleGrowMode(This).
%% @hidden
-doc false.
getFlexibleDirection(This) -> wxFlexGridSizer:getFlexibleDirection(This).
%% @hidden
-doc false.
addGrowableRow(This,Idx, Options) -> wxFlexGridSizer:addGrowableRow(This,Idx, Options).
%% @hidden
-doc false.
addGrowableRow(This,Idx) -> wxFlexGridSizer:addGrowableRow(This,Idx).
%% @hidden
-doc false.
addGrowableCol(This,Idx, Options) -> wxFlexGridSizer:addGrowableCol(This,Idx, Options).
%% @hidden
-doc false.
addGrowableCol(This,Idx) -> wxFlexGridSizer:addGrowableCol(This,Idx).
 %% From wxGridSizer
%% @hidden
-doc false.
setVGap(This,Gap) -> wxGridSizer:setVGap(This,Gap).
%% @hidden
-doc false.
setRows(This,Rows) -> wxGridSizer:setRows(This,Rows).
%% @hidden
-doc false.
setHGap(This,Gap) -> wxGridSizer:setHGap(This,Gap).
%% @hidden
-doc false.
setCols(This,Cols) -> wxGridSizer:setCols(This,Cols).
%% @hidden
-doc false.
getVGap(This) -> wxGridSizer:getVGap(This).
%% @hidden
-doc false.
getRows(This) -> wxGridSizer:getRows(This).
%% @hidden
-doc false.
getHGap(This) -> wxGridSizer:getHGap(This).
%% @hidden
-doc false.
getCols(This) -> wxGridSizer:getCols(This).
 %% From wxSizer
%% @hidden
-doc false.
showItems(This,Show) -> wxSizer:showItems(This,Show).
%% @hidden
-doc false.
show(This,Window, Options) -> wxSizer:show(This,Window, Options).
%% @hidden
-doc false.
show(This,Window) -> wxSizer:show(This,Window).
%% @hidden
-doc false.
setSizeHints(This,Window) -> wxSizer:setSizeHints(This,Window).
%% @hidden
-doc false.
setItemMinSize(This,Window,Width,Height) -> wxSizer:setItemMinSize(This,Window,Width,Height).
%% @hidden
-doc false.
setItemMinSize(This,Window,Size) -> wxSizer:setItemMinSize(This,Window,Size).
%% @hidden
-doc false.
setMinSize(This,Width,Height) -> wxSizer:setMinSize(This,Width,Height).
%% @hidden
-doc false.
setMinSize(This,Size) -> wxSizer:setMinSize(This,Size).
%% @hidden
-doc false.
setDimension(This,X,Y,Width,Height) -> wxSizer:setDimension(This,X,Y,Width,Height).
%% @hidden
-doc false.
setDimension(This,Pos,Size) -> wxSizer:setDimension(This,Pos,Size).
%% @hidden
-doc false.
replace(This,Oldwin,Newwin, Options) -> wxSizer:replace(This,Oldwin,Newwin, Options).
%% @hidden
-doc false.
replace(This,Oldwin,Newwin) -> wxSizer:replace(This,Oldwin,Newwin).
%% @hidden
-doc false.
remove(This,Index) -> wxSizer:remove(This,Index).
%% @hidden
-doc false.
prependStretchSpacer(This, Options) -> wxSizer:prependStretchSpacer(This, Options).
%% @hidden
-doc false.
prependStretchSpacer(This) -> wxSizer:prependStretchSpacer(This).
%% @hidden
-doc false.
prependSpacer(This,Size) -> wxSizer:prependSpacer(This,Size).
%% @hidden
-doc false.
prepend(This,Width,Height, Options) -> wxSizer:prepend(This,Width,Height, Options).
%% @hidden
-doc false.
prepend(This,Width,Height) -> wxSizer:prepend(This,Width,Height).
%% @hidden
-doc false.
prepend(This,Item) -> wxSizer:prepend(This,Item).
%% @hidden
-doc false.
layout(This) -> wxSizer:layout(This).
%% @hidden
-doc false.
recalcSizes(This) -> wxSizer:recalcSizes(This).
%% @hidden
-doc false.
isShown(This,Window) -> wxSizer:isShown(This,Window).
%% @hidden
-doc false.
insertStretchSpacer(This,Index, Options) -> wxSizer:insertStretchSpacer(This,Index, Options).
%% @hidden
-doc false.
insertStretchSpacer(This,Index) -> wxSizer:insertStretchSpacer(This,Index).
%% @hidden
-doc false.
insertSpacer(This,Index,Size) -> wxSizer:insertSpacer(This,Index,Size).
%% @hidden
-doc false.
insert(This,Index,Width,Height, Options) -> wxSizer:insert(This,Index,Width,Height, Options).
%% @hidden
-doc false.
insert(This,Index,Width,Height) -> wxSizer:insert(This,Index,Width,Height).
%% @hidden
-doc false.
insert(This,Index,Item) -> wxSizer:insert(This,Index,Item).
%% @hidden
-doc false.
hide(This,Window, Options) -> wxSizer:hide(This,Window, Options).
%% @hidden
-doc false.
hide(This,Window) -> wxSizer:hide(This,Window).
%% @hidden
-doc false.
getMinSize(This) -> wxSizer:getMinSize(This).
%% @hidden
-doc false.
getPosition(This) -> wxSizer:getPosition(This).
%% @hidden
-doc false.
getSize(This) -> wxSizer:getSize(This).
%% @hidden
-doc false.
getItem(This,Window, Options) -> wxSizer:getItem(This,Window, Options).
%% @hidden
-doc false.
getItem(This,Window) -> wxSizer:getItem(This,Window).
%% @hidden
-doc false.
getChildren(This) -> wxSizer:getChildren(This).
%% @hidden
-doc false.
fitInside(This,Window) -> wxSizer:fitInside(This,Window).
%% @hidden
-doc false.
setVirtualSizeHints(This,Window) -> wxSizer:setVirtualSizeHints(This,Window).
%% @hidden
-doc false.
fit(This,Window) -> wxSizer:fit(This,Window).
%% @hidden
-doc false.
detach(This,Window) -> wxSizer:detach(This,Window).
%% @hidden
-doc false.
clear(This, Options) -> wxSizer:clear(This, Options).
%% @hidden
-doc false.
clear(This) -> wxSizer:clear(This).
%% @hidden
-doc false.
addStretchSpacer(This, Options) -> wxSizer:addStretchSpacer(This, Options).
%% @hidden
-doc false.
addStretchSpacer(This) -> wxSizer:addStretchSpacer(This).
%% @hidden
-doc false.
addSpacer(This,Size) -> wxSizer:addSpacer(This,Size).
