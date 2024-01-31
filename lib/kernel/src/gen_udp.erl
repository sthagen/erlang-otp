%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 1997-2023. All Rights Reserved.
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
-module(gen_udp).
-moduledoc """
Interface to UDP sockets.

This module provides functions for communicating with sockets using the UDP
protocol.

> #### Note {: .info }
>
> Functions that create sockets can take an optional option;
> `{inet_backend, Backend}` that, if specified, has to be the first option. This
> selects the implementation backend towards the platform's socket API.
>
> This is a _temporary_ option that will be ignored in a future release.
>
> The default is `Backend = inet` that selects the traditional `inet_drv.c`
> driver. The other choice is `Backend = socket` that selects the new `m:socket`
> module and its NIF implementation.
>
> The system default can be changed when the node is started with the
> application `kernel`'s configuration variable `inet_backend`.
>
> For `gen_udp` with `inet_backend = socket` we have tried to be as "compatible"
> as possible which has sometimes been impossible. Here is a list of cases when
> the behaviour of inet-backend `inet` (default) and `socket` are different:
>
> - The option [read_packets](`m:inet#option-read_packets`) is currently
>   _ignored_.
> - Windows require sockets (domain = `inet | inet6`) to be bound.
>
>   _Currently_ all sockets created on Windows with `inet_backend = socket` will
>   be bound. If the user does not provide an address, gen_udp will try to
>   'figure out' an address itself.
""".

-export([open/1, open/2, close/1]).
-export([send/2, send/3, send/4, send/5, recv/2, recv/3, connect/2, connect/3]).
-export([controlling_process/2]).
-export([fdopen/2]).

-include("inet_int.hrl").

-define(module_socket(Handler, Handle),
        {'$inet', (Handler), (Handle)}).

%% -define(DBG(T), erlang:display({{self(), ?MODULE, ?LINE, ?FUNCTION_NAME}, T})).

-type option() ::
        {active,          true | false | once | -32768..32767} |
        {add_membership,  membership()} |
        {broadcast,       boolean()} |
        {buffer,          non_neg_integer()} |
        {debug,           boolean()} |
        {deliver,         port | term} |
        {dontroute,       boolean()} |
        {drop_membership, membership()} |
        {exclusiveaddruse, boolean()} |
        {header,          non_neg_integer()} |
        {high_msgq_watermark, pos_integer()} |
        {low_msgq_watermark, pos_integer()} |
        {mode,            list | binary} | list | binary |
        {multicast_if,    multicast_if()} |
        {multicast_loop,  boolean()} |
        {multicast_ttl,   non_neg_integer()} |
        {priority,        non_neg_integer()} |
        {raw,
         Protocol :: non_neg_integer(),
         OptionNum :: non_neg_integer(),
         ValueBin :: binary()} |
        {read_packets,    non_neg_integer()} |
        {recbuf,          non_neg_integer()} |
        {reuseaddr,       boolean()} |
        {reuseport,       boolean()} |
        {reuseport_lb,    boolean()} |
        {sndbuf,          non_neg_integer()} |
        {tos,             non_neg_integer()} |
        {tclass,          non_neg_integer()} |
        {ttl,             non_neg_integer()} |
	{recvtos,         boolean()} |
	{recvtclass,      boolean()} |
	{recvttl,         boolean()} |
	{ipv6_v6only,     boolean()}.
-type option_name() ::
        active |
        broadcast |
        buffer |
        debug |
        deliver |
        dontroute |
        exclusiveaddruse |
        header |
        high_msgq_watermark |
        low_msgq_watermark |
        mode |
        multicast_if |
        multicast_loop |
        multicast_ttl |
        priority |
        {raw,
         Protocol :: non_neg_integer(),
         OptionNum :: non_neg_integer(),
         ValueSpec :: (ValueSize :: non_neg_integer()) |
                      (ValueBin :: binary())} |
        read_packets |
        recbuf |
        reuseaddr |
        reuseport |
        reuseport_lb |
        sndbuf |
        tos |
        tclass |
        ttl |
        recvtos |
        recvtclass |
        recvttl |
        pktoptions |
	ipv6_v6only.

-type open_option() :: {ip, inet:socket_address()}
                     | {fd, non_neg_integer()}
                     | {ifaddr, inet:socket_address()}
                     | inet:address_family()
                     | {port, inet:port_number()}
                     | {netns, file:filename_all()}
                     | {bind_to_device, binary()}
                     | option().

-doc "As returned by [`open/1,2`](`open/1`).".
-type socket() :: inet:socket().

-type ip_multicast_if()  :: inet:ip4_address().
-doc "For IPv6 this is an interface index (an integer).".
-type ip6_multicast_if() :: integer(). % interface index
-type multicast_if()     :: ip_multicast_if() | ip6_multicast_if().


%% Note that for IPv4, the tuple with size 3 is *not*
%% supported on all platforms.
%% 'ifindex' defaults to zero (0) on platforms that
%% supports the 3-tuple variant.
-doc """
The tuple with size 3 is _not_ supported on all platforms. 'ifindex' defaults to
zero (0) on platforms that supports the 3-tuple variant.
""".
-type ip_membership()  :: {MultiAddress :: inet:ip4_address(),    % multiaddr
                           Interface    :: inet:ip4_address()} |  % local addr
                          {MultiAddress :: inet:ip4_address(),    % multiaddr
                           Address      :: inet:ip4_address(),    % local addr
                           IfIndex      :: integer()}.            % ifindex
-type ip6_membership() :: {MultiAddress :: inet:ip6_address(),    % multiaddr
                           IfIndex      :: integer()}.            % ifindex
-type membership()     :: ip_membership() | ip6_membership().

-export_type([option/0, open_option/0, option_name/0, socket/0,
              multicast_if/0, ip_multicast_if/0, ip6_multicast_if/0,
              membership/0, ip_membership/0, ip6_membership/0]).


%% -- open ------------------------------------------------------------------

-doc(#{equiv => open/2}).
-spec open(Port) -> {ok, Socket} | {error, Reason} when
      Port :: inet:port_number(),
      Socket :: socket(),
      Reason :: system_limit | inet:posix().

open(Port) -> 
    open(Port, []).

-doc """
Associates a UDP port number (`Port`) with the calling process.

The following options are available:

- **`list`** - Received `Packet` is delivered as a list.

- **`binary`** - Received `Packet` is delivered as a binary.

- **`{ip, Address}`** - If the host has many network interfaces, this option
  specifies which one to use.

- **`{ifaddr, Address}`** - Same as `{ip, Address}`. If the host has many
  network interfaces, this option specifies which one to use.

  However, if this instead is an `t:socket:sockaddr_in/0` or
  `t:socket:sockaddr_in6/0` this takes precedence over any value previously set
  with the `ip` options. If the `ip` option comes _after_ the `ifaddr` option,
  it may be used to _update_ its corresponding field of the `ifaddr` option (the
  `addr` field).

- **`{fd, integer() >= 0}`** - If a socket has somehow been opened without using
  `gen_udp`, use this option to pass the file descriptor for it. If `Port` is
  not set to `0` and/or `{ip, ip_address()}` is combined with this option, the
  `fd` is bound to the specified interface and port after it is being opened. If
  these options are not specified, it is assumed that the `fd` is already bound
  appropriately.

- **`inet6`** - Sets up the socket for IPv6.

- **`inet`** - Sets up the socket for IPv4.

- **`local`** - Sets up a Unix Domain Socket. See `t:inet:local_address/0`

- **`{udp_module, module()}`** - Overrides which callback module is used.
  Defaults to `inet_udp` for IPv4 and `inet6_udp` for IPv6.

- **`{multicast_if, Address}`** - Sets the local device for a multicast socket.

- **`{multicast_loop, true | false}`** - When `true`, sent multicast packets are
  looped back to the local sockets.

- **`{multicast_ttl, Integer}`** - Option `multicast_ttl` changes the
  time-to-live (TTL) for outgoing multicast datagrams to control the scope of
  the multicasts.

  Datagrams with a TTL of 1 are not forwarded beyond the local network. Defaults
  to `1`.

- **`{add_membership, {MultiAddress, InterfaceAddress}}`** - Joins a multicast
  group.

- **`{drop_membership, {MultiAddress, InterfaceAddress}}`** - Leaves a multicast
  group.

- **`Opt`** - See `inet:setopts/2`.

The returned socket `Socket` is used to send packets from this port with
`send/4`. When UDP packets arrive at the opened port, if the socket is in an
active mode, the packets are delivered as messages to the controlling process:

```erlang
{udp, Socket, IP, InPortNo, Packet} % Without ancillary data
{udp, Socket, IP, InPortNo, AncData, Packet} % With ancillary data
```

The message contains an `AncData` field if any of the socket
[options](`t:option/0`) [`recvtos`](`m:inet#option-recvtos`),
[`recvtclass`](`m:inet#option-recvtclass`) or
[`recvttl`](`m:inet#option-recvttl`) are active, otherwise it does not.

If the socket is not in an active mode, data can be retrieved through the
[`recv/2,3`](`recv/2`) calls. Notice that arriving UDP packets that are longer
than the receive buffer option specifies can be truncated without warning.

When a socket in `{active, N}` mode (see `inet:setopts/2` for details),
transitions to passive (`{active, false}`) mode, the controlling process is
notified by a message of the following form:

```text
{udp_passive, Socket}
```

`IP` and `InPortNo` define the address from which `Packet` comes. `Packet` is a
list of bytes if option `list` is specified. `Packet` is a binary if option
`binary` is specified.

Default value for the receive buffer option is `{recbuf, 8192}`.

If `Port == 0`, the underlying OS assigns a free UDP port, use `inet:port/1` to
retrieve it.
""".
-spec open(Port, Opts) -> {ok, Socket} | {error, Reason} when
      Port   :: inet:port_number(),
      Opts   :: [inet:inet_backend() | open_option()],
      Socket :: socket(),
      Reason :: system_limit | inet:posix().

open(Port, Opts0) ->
    case inet:gen_udp_module(Opts0) of
	{?MODULE, Opts} ->
	    open1(Port, Opts);
	{GenUdpMod, Opts} ->
	    GenUdpMod:open(Port, Opts)
    end.

open1(Port, Opts0) ->
    {Mod, Opts} = inet:udp_module(Opts0),
    {ok, UP} = Mod:getserv(Port),
    Mod:open(UP, Opts).
    

%% -- close -----------------------------------------------------------------

-doc "Closes a UDP socket.".
-spec close(Socket) -> ok when
      Socket :: socket().

close(?module_socket(GenUdpMod, _) = S) when is_atom(GenUdpMod) ->
    GenUdpMod:?FUNCTION_NAME(S);
close(S) ->
    inet:udp_close(S).


%% -- send ------------------------------------------------------------------

%% Connected send

-doc """
Sends a packet on a connected socket (see
[`connect/2`](`m:gen_udp#connect-sockaddr`) and
[`connect/3`](`m:gen_udp#connect-addr-port`)).
""".
-doc(#{since => <<"OTP 24.3">>}).
-spec send(Socket, Packet) -> ok | {error, Reason} when
      Socket :: socket(),
      Packet :: iodata(),
      Reason :: not_owner | inet:posix().

send(?module_socket(GenUdpMod, _) = S, Packet)
  when is_atom(GenUdpMod) ->
    GenUdpMod:?FUNCTION_NAME(S, Packet);
send(S, Packet) when is_port(S) ->
    case inet_db:lookup_socket(S) of
	{ok, Mod} ->
	    Mod:send(S, Packet);
	Error ->
	    Error
    end.

-doc """
Sends a packet to the specified `Destination`.

This function is equivalent to
[`send(Socket, Destination, [], Packet)`](`m:gen_udp#send-4-AncData`).
""".
-doc(#{since => <<"OTP 22.1">>}).
-spec send(Socket, Destination, Packet) -> ok | {error, Reason} when
      Socket :: socket(),
      Destination :: {inet:ip_address(), inet:port_number()} |
		     inet:family_address() |
                     socket:sockaddr_in() | socket:sockaddr_in6(),
      Packet :: iodata(),
      Reason :: not_owner | inet:posix().

send(?module_socket(GenUdpMod, _) = S, Destination, Packet)
  when is_atom(GenUdpMod) ->
    GenUdpMod:?FUNCTION_NAME(S, Destination, Packet);
send(Socket, Destination, Packet) ->
    send(Socket, Destination, [], Packet).

-doc """
[](){: #send-4-1 }

Sends a packet to the specified `Host` and `Port`.

This clause is equivalent to [`send(Socket, Host, Port, [], Packet)`](`send/5`).

[](){: #send-4-AncData }

Sends a packet to the specified `Destination` with ancillary data `AncData`.

> #### Note {: .info }
>
> The ancillary data `AncData` contains options that for this single message
> override the default options for the socket, an operation that may not be
> supported on all platforms, and if so return `{error, einval}`. Using more
> than one of an ancillary data item type may also not be supported.
> `AncData =:= []` is always supported.

[](){: #send-4-3 }

Sends a packet to the specified `Destination`. Since `Destination` is complete,
`PortZero` is redundant and has to be `0`.

This is a legacy clause mostly for `Destination = {local, Binary}` where
`PortZero` is superfluous. It is equivalent to
[`send(Socket, Destination, [], Packet)`](`m:gen_udp#send-4-AncData`), the
clause right above here.
""".
-doc(#{since => <<"OTP 22.1">>}).
-spec send(Socket, Host, Port, Packet) -> ok | {error, Reason} when
      Socket :: socket(),
      Host :: inet:hostname() | inet:ip_address(),
      Port :: inet:port_number() | atom(),
      Packet :: iodata(),
      Reason :: not_owner | inet:posix();
%%%
          (Socket, Destination, AncData, Packet) -> ok | {error, Reason} when
      Socket :: socket(),
      Destination :: {inet:ip_address(), inet:port_number()} |
                     inet:family_address() |
                     socket:sockaddr_in() | socket:sockaddr_in6(),
      AncData :: inet:ancillary_data(),
      Packet :: iodata(),
      Reason :: not_owner | inet:posix();
%%%
          (Socket, Destination, PortZero, Packet) -> ok | {error, Reason} when
      Socket :: socket(),
      Destination :: {inet:ip_address(), inet:port_number()} |
                     inet:family_address(),
      PortZero :: inet:port_number(),
      Packet :: iodata(),
      Reason :: not_owner | inet:posix().

send(?module_socket(GenUdpMod, _) = S, Arg2, Arg3, Packet)
  when is_atom(GenUdpMod) ->
    GenUdpMod:?FUNCTION_NAME(S, Arg2, Arg3, Packet);

send(S, #{family := Fam} = Destination, AncData, Packet)
  when is_port(S) andalso
       ((Fam =:= inet) orelse (Fam =:= inet6)) andalso
       is_list(AncData) ->
    case inet_db:lookup_socket(S) of
        {ok, Mod} ->
            Mod:send(S, inet:ensure_sockaddr(Destination), AncData, Packet);
        Error ->
            Error
    end;
send(S, {_,_} = Destination, PortZero = AncData, Packet) when is_port(S) ->
    %% Destination is {Family,Addr} | {IP,Port},
    %% so it is complete - argument PortZero is redundant
    if
        PortZero =:= 0 ->
            case inet_db:lookup_socket(S) of
                {ok, Mod} ->
                    Mod:send(S, Destination, [], Packet);
                Error ->
                    Error
            end;
        is_integer(PortZero) ->
            %% Redundant PortZero; must be 0
            {error, einval};
        is_list(AncData) ->
            case inet_db:lookup_socket(S) of
                {ok, Mod} ->
                    Mod:send(S, Destination, AncData, Packet);
                Error ->
                    Error
            end
    end;
send(S, Host, Port, Packet) when is_port(S) ->
    send(S, Host, Port, [], Packet).

-doc """
Sends a packet to the specified `Host` and `Port`, with ancillary data
`AncData`.

Argument `Host` can be a hostname or a socket address, and `Port` can be a port
number or a service name atom. These are resolved into a `Destination` and after
that this function is equivalent to
[`send(Socket, Destination, AncData, Packet)`](`m:gen_udp#send-4-AncData`), read
there about ancillary data.
""".
-doc(#{since => <<"OTP 22.1">>}).
-spec send(Socket, Host, Port, AncData, Packet) -> ok | {error, Reason} when
      Socket :: socket(),
      Host :: inet:hostname() | inet:ip_address() | inet:local_address(),
      Port :: inet:port_number() | atom(),
      AncData :: inet:ancillary_data(),
      Packet :: iodata(),
      Reason :: not_owner | inet:posix().

send(?module_socket(GenUdpMod, _) = S, Host, Port, AncData, Packet)
  when is_atom(GenUdpMod) ->
    GenUdpMod:?FUNCTION_NAME(S, Host, Port, AncData, Packet);

send(S, Host, Port, AncData, Packet)
  when is_port(S), is_list(AncData) ->
    case inet_db:lookup_socket(S) of
	{ok, Mod} ->
	    case Mod:getaddr(Host) of
		{ok,IP} ->
		    case Mod:getserv(Port) of
			{ok,P} -> Mod:send(S, {IP,P}, AncData, Packet);
			{error,einval} -> exit(badarg);
			Error -> Error
		    end;
		{error,einval} -> exit(badarg);
		Error -> Error
	    end;
	Error ->
	    Error
    end.


%% -- recv ------------------------------------------------------------------

-doc(#{equiv => recv/3}).
-spec recv(Socket, Length) ->
                  {ok, RecvData} | {error, Reason} when
      Socket :: socket(),
      Length :: non_neg_integer(),
      RecvData :: {Address, Port, Packet} | {Address, Port, AncData, Packet},
      Address :: inet:ip_address() | inet:returned_non_ip_address(),
      Port :: inet:port_number(),
      AncData :: inet:ancillary_data(),
      Packet :: string() | binary(),
      Reason :: not_owner | inet:posix().

recv(?module_socket(GenUdpMod, _) = S, Len)
  when is_atom(GenUdpMod) andalso is_integer(Len) ->
    GenUdpMod:?FUNCTION_NAME(S, Len);
recv(S, Len) when is_port(S) andalso is_integer(Len) ->
    case inet_db:lookup_socket(S) of
	{ok, Mod} ->
	    Mod:recv(S, Len);
	Error ->
	    Error
    end.

-doc """
Receives a packet from a socket in passive mode. Optional parameter `Timeout`
specifies a time-out in milliseconds. Defaults to `infinity`.

If any of the socket [options](`t:option/0`)
[`recvtos`](`m:inet#option-recvtos`), [`recvtclass`](`m:inet#option-recvtclass`)
or [`recvttl`](`m:inet#option-recvttl`) are active, the `RecvData` tuple
contains an `AncData` field, otherwise it does not.
""".
-spec recv(Socket, Length, Timeout) ->
                  {ok, RecvData} | {error, Reason} when
      Socket :: socket(),
      Length :: non_neg_integer(),
      Timeout :: timeout(),
      RecvData :: {Address, Port, Packet} | {Address, Port, AncData, Packet},
      Address :: inet:ip_address() | inet:returned_non_ip_address(),
      Port :: inet:port_number(),
      AncData :: inet:ancillary_data(),
      Packet :: string() | binary(),
      Reason :: not_owner | timeout | inet:posix().

recv(?module_socket(GenUdpMod, _) = S, Len, Time)
  when is_atom(GenUdpMod) ->
    GenUdpMod:?FUNCTION_NAME(S, Len, Time);
recv(S, Len, Time) when is_port(S) ->
    case inet_db:lookup_socket(S) of
	{ok, Mod} ->
	    Mod:recv(S, Len, Time);
	Error ->
	    Error
    end.


%% -- connect ---------------------------------------------------------------

-doc """
[](){: #connect-sockaddr }

Connecting a UDP socket only means storing the specified (destination) socket
address, as specified by `SockAddr`, so that the system knows where to send
data.

This means that it is not necessary to specify the destination address when
sending a datagram. That is, we can use `send/2`.

It also means that the socket will only received data from this address.
""".
-doc(#{since => <<"OTP 24.3">>}).
-spec connect(Socket, SockAddr) -> ok | {error, Reason} when
      Socket   :: socket(),
      SockAddr :: socket:sockaddr_in() | socket:sockaddr_in6(),
      Reason   :: inet:posix().

connect(S, SockAddr) when is_port(S) andalso is_map(SockAddr) ->
    case inet_db:lookup_socket(S) of
	{ok, Mod} ->
            Mod:connect(S, inet:ensure_sockaddr(SockAddr));
	Error ->
	    Error
    end.

-doc """
[](){: #connect-addr-port }

Connecting a UDP socket only means storing the specified (destination) socket
address, as specified by `Address` and `Port`, so that the system knows where to
send data.

This means that it is not necessary to specify the destination address when
sending a datagram. That is, we can use `send/2`.

It also means that the socket will only received data from this address.
""".
-doc(#{since => <<"OTP 24.3">>}).
-spec connect(Socket, Address, Port) -> ok | {error, Reason} when
      Socket   :: socket(),
      Address  :: inet:socket_address() | inet:hostname(),
      Port     :: inet:port_number(),
      Reason   :: inet:posix().

connect(?module_socket(GenUdpMod, _) = S, Address, Port)
  when is_atom(GenUdpMod) ->
    GenUdpMod:?FUNCTION_NAME(S, Address, Port);

connect(S, Address, Port) when is_port(S) ->
    %% ?DBG([{address, Address}, {port, Port}]),
    case inet_db:lookup_socket(S) of
	{ok, Mod} ->
	    %% ?DBG([{mod, Mod}]),
	    case Mod:getaddr(Address) of    
		{ok, IP} ->
		    %% ?DBG([{ip, IP}]),
		    Mod:connect(S, IP, Port);
		Error ->
		    %% ?DBG(['getaddr', {error, Error}]),
		    Error
	    end;
	Error ->
	    %% ?DBG(['lookup', {error, Error}]),
	    Error
    end.


%% -- controlling_process ---------------------------------------------------

-doc """
Assigns a new controlling process `Pid` to `Socket`. The controlling process is
the process that receives messages from the socket. If called by any other
process than the current controlling process, `{error, not_owner}` is returned.
If the process identified by `Pid` is not an existing local pid,
`{error, badarg}` is returned. `{error, badarg}` may also be returned in some
cases when `Socket` is closed during the execution of this function.
""".
-spec controlling_process(Socket, Pid) -> ok | {error, Reason} when
      Socket :: socket(),
      Pid :: pid(),
      Reason :: closed | not_owner | badarg | inet:posix().

controlling_process(?module_socket(GenUdpMod, _) = S, NewOwner)
  when is_atom(GenUdpMod) ->
    GenUdpMod:?FUNCTION_NAME(S, NewOwner);

controlling_process(S, NewOwner) ->
    inet:udp_controlling_process(S, NewOwner).


%% -- fdopen ----------------------------------------------------------------

%%
%% Create a port/socket from a file descriptor
%%
-doc false.
fdopen(Fd, Opts0) ->
    {Mod,Opts} = inet:udp_module(Opts0),
    Mod:fdopen(Fd, Opts).
