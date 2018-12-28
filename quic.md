# QUIC

[QUIC](https://www.chromium.org/quic) is a multiplexed stream transport over
UDP.  It advertises the following benefits over TCP:

- Dramatically reduced connection establishment time
- Improved congestion control
- Multiplexing without head of line blocking
- Forward error correction
- Connection migration

# Design and Specification

- [QUIC overview](https://docs.google.com/document/d/1gY9-YNDNAB1eip-RTPbqphgySwSNSDHLq9D5Bty4FSU/edit)
- [QUIC wire specification](https://docs.google.com/document/d/1WJvyZflAO2pq77yOLbp9NsGjC1CHetAXV8I0fQe-B_U/edit)
- IETF draft: [QUIC: A UDP-Based Multiplexed and Secure Transport](https://tools.ietf.org/html/draft-ietf-quic-transport-00)

# Presentation API functionality

A QUIC connection between a client and a server transmits data in
[QUIC Streams](https://tools.ietf.org/html/draft-ietf-quic-transport-00#section-6.1).
Each Stream represents a bidrectional reliable sequence of data packets, can
originate from the server or client, and has a unique integer ID.

For the Presentation API, the most common case is that the controlling user
agent plays the role of the client and the presentation display the role of the
server.

Assume that a single QUIC connection is used to transmit data between the
controlling user agent and receiver.  The following mapping could be used to
associate streams with Presentation API concepts:

- One reserved stream with ID 5 for control messages between the controlling
  user agent and receiver.
- One stream with ID >= 10 for each PresentationConnection.

Within each stream, an Open Screen specific framing would have to be defined to
allow individual messages to be extracted, similar to how
[HTTP/2 resources](https://tools.ietf.org/html/draft-ietf-quic-http-00)
are mapped to Streams.

[Issue #62](https://github.com/webscreens/openscreenprotocol/issues/62): If
WebSockets are possible on QUIC, investigate how it is done.

With this outline, once connection was established, the requirements could be
met as follows:

## Presentation Initiation

1. Send a control message on Stream 5 from the controlling user agent to the
   reciever to start the presentation with ID, URL, and a Stream ID for the
   initial presentation connection.
2. Get a reply on Stream 5 with the ID, URL, and stream ID to confirm success
   (or report an error).

## Presentation Resumption

1. Send a control message on Stream 5 from the controlling user agent to the
   receiver reconnect to a presentation with ID, URL, and a Stream ID for the
   initial presentation connection.
2. Get a reply on Stream 5 with the ID, URL, and stream ID to confirm success
   (or report an error).

## Presentation Connections

Multiple connections from a controlling user agent can be handled by assigning
unique Stream IDs, and the receiver can use stream IDs to disambiguate the
sources of incoming messages.

Either side may close the stream it uses to send messages to the destination
browsing context by setting the
[FIN flag](https://tools.ietf.org/html/draft-ietf-quic-transport-00#section-8.1)
in the final QUIC frame on the stream. It can also send a message on Stream 5
indicating the reason why the connection was closed.

## Presentation Connection Messaging

Binary or text messages can be sent on the QUIC Stream corresponding to the
presentation connection.  The framing of these messages would need to be
defined.

## Presentation Termination

A controlling user agent can send a control message with URL and ID on Stream 5
to instruct a receiver to terminate a presentation.

The receiver can send a
[RST_STREAM](https://tools.ietf.org/html/draft-ietf-quic-transport-00#section-6.6)
frame with a custom error code to inform all presentation connections that a
presentation is about to be terminated.

# Remote Playback API functionality

TBD once remote playback API requirements are set.

# Reliability

[Issue #63](https://github.com/webscreens/openscreenprotocol/issues/63): Get
reliability data.

# Latency to establish a new connection

QUIC is designed to minimize the number of round trips needed to establish or
re-establish connections.

[Issue #66](https://github.com/webscreens/openscreenprotocol/issues/66): Get
connection latency data.

# Latency to transmit messages

QUIC allows for out of order packet delivery, which may improve the latency to
deliver presentation connection messages on a congested or lossy network.

[Issue #66](https://github.com/webscreens/openscreenprotocol/issues/66): Get
message transmission latency data.

# Ease of implementation / deployment

QUIC is currently provided as part of the open source Chromium project.  The
project includes a simple QUIC server implementation (noted as not performant in
any way).  Instructions on how to check out and build it can be found
on [chromium.org](https://www.chromium.org/quic/playing-with-quic).  The
implementation does have some dependencies on Chromium core
libraries.

# Privacy

By relying on UDP, the IP addresses of both endpoints are visible to network
observers.  The plaintext portions of the authentication handshake are also
visible to observers.

Once authentication is established, the current
[QUIC crypto](https://docs.google.com/document/d/1g5nIXAIkN_Y-7XJW5K45IblHd_L2f5LTaDUDwvZ5L6g/edit)
implementation encrypts full datagrams including all QUIC stream framing
information.

# IPv4 and IPv6 support

QUIC depends only on UDP, which is supported for both IPv4 and IPv6.

# Hardware requirements

[Issue #64](https://github.com/webscreens/openscreenprotocol/issues/64): Obtain
data on hardware requirements

# Network and power efficiency

[Issue #65](https://github.com/webscreens/openscreenprotocol/issues/65): Obtain
data on network and power efficiency

# Standardization status

QUIC has a standards track specification in the
IETF [QUIC Working Group](https://datatracker.ietf.org/wg/quic/charter/).  Last
call is expected in late 2018.

*TODO:* Link appropriate IPR policy and any relevant disclosures.

# Security

QUIC does not mandate a specific security mechanism to authenticate and encrypt
the transport.  Stream 1 is reserved for authentication handshake and
implementations can plug in their own crypto protocol using this stream.

The
[current standards-track proposal](https://tools.ietf.org/html/draft-ietf-quic-tls-06)
describes how TLS 1.3 is implemented as a crypto protocol for QUIC.  As of
October 9, 2017, TLS 1.3 is currently in
[draft #21](https://tools.ietf.org/html/draft-ietf-tls-tls13-21).

# User Experience

QUIC allows human readable error messages to be sent with a
[CONNECTION_CLOSE](https://tools.ietf.org/html/draft-ietf-quic-transport-00#section-6.9)
frame.  This could be used to surface information via the Presentation API or
the user agent when a presentation connection is closed in an error state.

# Notes

QUIC is designed to be a transport for HTTP/2, so Presentation API functions
could be implemented in terms of HTTP/2.  This proposal assumes the use of
QUIC directly.
