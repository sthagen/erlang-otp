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

# TLS/DTLS Protocol Overview

## Purpose

Transport Layer Security (TLS) and its predecessor, the Secure Sockets Layer
(SSL), are cryptographic protocols designed to provide communications security
over a computer network. The protocols use X.509 certificates and hence public
key (asymmetric) cryptography to authenticate the counterpart with whom they
communicate, and to exchange a symmetric key for payload encryption. The
protocol provides data/message confidentiality (encryption), integrity (through
message authentication code checks) and host verification (through certificate
path validation). DTLS (Datagram Transport Layer Security) that is based on TLS
but datagram oriented instead of stream oriented.

# Erlang Support

The Erlang SSL application implements the TLS/DTLS protocol for the currently
supported versions, see the `m:ssl` manual page.

By default TLS is run over the TCP/IP protocol even though you can plug in any
other reliable transport protocol with the same Application Programming
Interface (API) as the `gen_tcp` module in Kernel. DTLS is by default run over
UDP/IP, which means that application data has no delivery guarantees. Other
transports, such as SCTP, may be supported in future releases.

If a client and a server wants to use an upgrade mechanism, such as defined by
RFC 2817, to upgrade a regular TCP/IP connection to a TLS connection, this is
supported by the Erlang SSL application API. This can be useful for, for
example, supporting HTTP and HTTPS on the same port and implementing virtual
hosting. Note this is a TLS feature only.

## Security Overview

To achieve authentication and privacy, the client and server perform a TLS/DTLS
handshake procedure before transmitting or receiving any data. During the
handshake, they agree on a protocol version and cryptographic algorithms,
generate shared secrets using public key cryptographies, and optionally
authenticate each other with digital certificates.

## Data Privacy and Integrity

A _symmetric key_ algorithm has one key only. The key is used for both
encryption and decryption. These algorithms are fast, compared to public key
algorithms (using two keys, one public and one private) and are therefore
typically used for encrypting bulk data.

The keys for the symmetric encryption are generated uniquely for each connection
and are based on a secret negotiated in the TLS/DTLS handshake.

The TLS/DTLS handshake protocol and data transfer is run on top of the TLS/DTLS
Record Protocol, which uses a keyed-hash Message Authenticity Code (MAC), or a
Hash-based MAC (HMAC), to protect the message data integrity. From the TLS RFC:
"A Message Authentication Code is a one-way hash computed from a message and
some secret data. It is difficult to forge without knowing the secret data. Its
purpose is to detect if the message has been altered."

## Digital Certificates

A certificate is similar to a driver's license, or a passport. The holder of the
certificate is called the _subject_. The certificate is signed with the private
key of the issuer of the certificate. A chain of trust is built by having the
issuer in its turn being certified by another certificate, and so on, until you
reach the so called root certificate, which is self-signed, that is, issued by
itself.

Certificates are issued by Certification Authorities (CAs) only. A handful of
top CAs in the world issue root certificates. You can examine several of these
certificates by clicking through the menus of your web browser.

## Peer Authentication

Authentication of the peer is done by public key path validation as defined in
RFC 3280. This means basically the following:

- Each certificate in the certificate chain is issued by the previous one.
- The certificates attributes are valid.
- The root certificate is a trusted certificate that is present in the trusted
  certificate database kept by the peer.

The server always sends a certificate chain as part of the TLS handshake, but
the client only sends one if requested by the server. If the client does not
have an appropriate certificate, it can send an "empty" certificate to the
server.

The client can choose to accept some path evaluation errors, for example, a web
browser can ask the user whether to accept an unknown CA root certificate. The
server, if it requests a certificate, does however not accept any path
validation errors. It is configurable if the server is to accept or reject an
"empty" certificate as response to a certificate request.

## TLS Sessions - Prior to TLS-1.3

From the TLS RFC: "A TLS session is an association between a client and a
server. Sessions are created by the handshake protocol. Sessions define a set of
cryptographic security parameters, which can be shared among multiple
connections. Sessions are used to avoid the expensive negotiation of new
security parameters for each connection."

Session data is by default kept by the SSL application in a memory storage,
hence session data is lost at application restart or takeover. Users can define
their own callback module to handle session data storage if persistent data
storage is required. Session data is also invalidated when session database
exceeds its limit or 24 hours after being saved (RFC max lifetime
recommendation). The amount of time the session data is to be saved can be
configured.

By default the TLS/DTLS clients try to reuse an available session and by default
the TLS/DTLS servers agree to reuse sessions when clients ask for it. See also
[Session Reuse Prior to TLS-1.3](using_ssl.md#session-reuse-prior-to-tls-1-3)

## TLS-1.3 session tickets

In TLS 1.3 the session reuse is replaced by a new session tickets mechanism
based on the prior to shared key concept. This mechanism also obsoletes the session
tickets from RFC5077, not implemented by this application. See also
[Session Tickets and Session Resumption in TLS-1.3](using_ssl.md#session-tickets-and-session-resumption-in-tls-1-3)
