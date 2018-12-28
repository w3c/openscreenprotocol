# Data Channel

[Data Channel](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13) is
a non-media transport protocol in the WebRTC framework, designed for exchanging
data from peer to peer. It advertises the following benefits:

- Implemented in major browsers.
- Supports heterogeneous network environments, e.g., NAT, firewall.
- Easily supports media transport for remote playback.
- Data framing format is already defined.

# Design and Specification

- [WebRTC overview](https://tools.ietf.org/html/draft-ietf-rtcweb-overview-18)
- IETF draft: [WebRTC Data Channel Establishment Protocol](https://tools.ietf.org/html/draft-ietf-rtcweb-data-protocol-09)
- IETF draft: [Data Channel](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13)

# Presentation API functionality

Data Channel is designed to be a non-media transport for WebRTC, with a built-in
sub protocol negotiation mechanism.

A Data Channel is built on top of a
[SCTP](https://tools.ietf.org/html/rfc4960)/[DTLS](https://tools.ietf.org/html/rfc6347)/UDP
protocol stack, which supports reliable data transmission. Each Data Channel has
a unique integer ID and a label.  Mutiple Data Channels can share the same DTLS
connection.

Assume that a single Data Channel is used as a control channel to transmit
control messages between the controlling user agent and receiver, and one Data
Channel is created for each presentation connection to exchange application
data.

An extra signalling channel and protocol for exchanging ICE candidates is
required to bootstrap the control channel. The bootstrapping procedure needs to
be executed before Presentation Initiation, Presentation Resumption, or
Presentation Connection Establishment.

## Presentation Initiation

1. To start a presentation, the controlling user agent sends a message to the
   receiver on the control channel with the presentation ID and URL of the
   initial presentation connection.
2. The receiver spawns a Data Channel on the same RTC connection as the control
   channel, with a unique session ID generated as the label.
3. The controlling user agent gets a reply on the control channel with the
   presentation ID, URL, and session ID to confirm success (or report an error).

## Presentation Resumption

1. To reconnect to a presentation, the controlling user agent sends a message to
   the receiver on the control channel with the presentation ID, URL, and
   session ID of the initial presentation connection.
2. If there is a corresponding presentation to be resumed, the receiver spawns a
   Data Channel on the same RTC connection as the control channel, with the
   session ID as the label.
3. The controlling user agent gets a reply on control channel with the
   presentation ID, URL, and session ID to confirm success (or report an error).

## Presentation Connection Establishment

Multiple connections from a controlling user agent can be handled by creating
unique Data Channels for each peer. A unique stream ID will be selected for
muxing/demuxing messages on the underlying SCTP transport, see
[draft-ietf-rtcweb-data-protocol-09](https://tools.ietf.org/html/draft-ietf-rtcweb-data-protocol-09#section-6).

## Presentation Connection Messaging

Binary or text messages can be sent on the Data Channel corresponding to the
presentation connection.  The framing of these messages is defined in
[draft-ietf-rtcweb-data-channel](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13#section-6.6).

Either side may close the Presentation Connection through the following procedure:
1. Send a control message with close reason on control channel to remote peer.
2. When the remote peer receives the control message, it initiates the
   [Data Channel close procedure](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13#section-6.6).
3. Close the presentation connection when the underlying Data Channel is closed.

## Presentation Termination

For controlling user agent initiated termination:
1. The controlling user agent sends a control message with the presentation URL
   and ID on the control channel to instruct a receiver to terminate a
   presentation.
2. The receiver sends a reply to all associated control channels to inform all
   remote peers that a presentation is about to be terminated.

For receiver initiated termination:
1. The receiver sends a control message to all associated control channels to
   inform all remote peers that a presentation is about to be terminated.

# Remote Playback API functionality

The WebRTC framework supports media codec negotiation and real-time media
transport.

[Issue #3](https://github.com/webscreens/openscreenprotocol/issues/3): Fill in
when Remote Playback requirements are known.

# Reliability

WebRTC is designed to be operated in a heterogeneous network environment, using
ICE for address discovery and built-in negotiation/re-negotiation mechanism.

[Issue #30](https://github.com/webscreens/openscreenprotocol/issues/30):
Get reliability data.

# Latency to establish a new connection

There are three sources of latency:
1. Connecting a reliable channel the first time for ICE negotiation.
2. Establishing the first Data Channel.
3. Adding an additional Data Channel on top of an existing peer-to-peer
   connection.

[Issue #31](https://github.com/webscreens/openscreenprotocol/issues/31):
Get connection latency data.

# Latency to transmit a message

Data Channel is based on SCTP, which allows for out of order packet delivery and
may improve the latency to deliver presentation connection messages on a
congested or lossy network.

[Issue #31](https://github.com/webscreens/openscreenprotocol/issues/31):
Get supporting data.

# Ease of implementation / deployment

Four major browsers (Chrome/Firefox/Edge/Opera) already implement and ship in
the latest release version. An open source library
[WebRTC.org](https://webrtc.org/) is ready with production level quality.

A common signaling channel/protocol for exchanging ICE candidates needs to be
defined.

# Privacy

By relying on UDP, the IP addresses of both endpoints are visible to network
observers.

DTLS is used for transport level security. Once DTLS is established, all the
control message and data will be encrypted.

# IPv4 and IPv6 support

Data Channel depends on SCTP over UDP, which is supported for both IPv4 and IPv6.

# Hardware requirements

Major desktop, laptop, and high-end mobile phone should be able to create single
RTC connection since major browser on desktop and mobile already ship WebRTC.

[Issue #32](https://github.com/webscreens/openscreenprotocol/issues/32):
Obtain data on hardware requirements.

# Network and power efficiency

Maintaining a long-lived Data Channel might not be power efficient.

[Issue #33](https://github.com/webscreens/openscreenprotocol/issues/33):
Obtain data on network and power efficiency.

# Standardization status

Data Channel has a standards track specification in the
IETF [RTCWEB Working Group](https://datatracker.ietf.org/wg/rtcweb/charter/).

Major browsers already implement and ship Data Channel with interoperability
tested.

# Security

A general security study has be done by the IETF RTCWEB working group, see
[Security Overview](https://tools.ietf.org/html/draft-ietf-rtcweb-overview-18#section-5)

The signaling channel for exchanging SDP must be encrypted to prevent a
man-in-the-middle attack.  The DTLS handshake exchanges encryption keys and sets
up an encrypted channel for SCTP.  A STUN keepalive can be introduced for
consent freshness.  An Identity Provider can be introduced for external
authentication.

# User Experience

This should be covered by the latency evaluations above.  The relevant user
experience requirements ar met by evaluating:
1. The latency to establish a presentation connection.
2. The latency to transmit an application message.
