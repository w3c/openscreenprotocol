# Data Channel

[Data Channel](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13)
is a non-media transport protocol in WebRTC framework, designed for exchanging
data from peer to peer. It advertises the following benefits:

- Implemented in major browsers (except Safari)
- Supports heterogeneous network environment e.g. NAT, firewall.
- Easily supports media transport for remote playback
- Data framing format is already defined

# Design and Specification

- [WebRTC overview](https://tools.ietf.org/html/draft-ietf-rtcweb-overview-18)
- IETF draft: [WebRTC Data Channel Establishment Protocol](https://tools.ietf.org/html/draft-ietf-rtcweb-data-protocol-09)
- IETF draft: [Data Channel](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13)

# Presentation API functionality

Data Channel is designed to be a non-media transport for WebRTC, with built-in
sub protocol negotiation mechanism defined.

A Data Channel is built on top of SCTP/DTLS/UDP protocol stack, which supports
reliable data transmition. Each Data Channel has a unique integer ID and a label.
Mutiple Data Channels can share the same DTLS connection.

Assume that a single Data Channel is used as a control channel to transmit control
messages between the controller and receiver and one Data Channel is created for each
connected Presentation Connection for transmitting application data.

An extra signalling channel and protocol for exchanging ICE candidates is required
to bootstrap the control channel. The bootstrapping procedure needs to be executed
for the first connecting to that receiver before the Presentation Initiation.

## Presentation Initiation

1. Send a control message on control channel from the controller to the display to
   start the presentation with presentation ID and URL for the initial presentation
   connection.
2. Receiver spawn a Data Channel on the same RTC connection of control channel, with
   a unique session ID generated as label.
3. Get a reply on control channel with the presentation ID ,URL, and session ID to
   confirm success (or report an error).

## Presentation Resumption

1. Send a control message on control channel from the controller to the display
   reconnect to a presentation with presentation ID ,URL, and previous session Id for
   the initial presentation connection.
2. Receiver spawn a Data Channel on the same RTC connection of control channel, with
   session ID as label, if there is a corresponding presentation to be resumed.
3. Get a reply on control channel with the presentation ID, URL, and session ID to
   confirm success (or report an error).

## Presentation Connections

Multiple connections from a controller can be handled by creating unique Data
Channels for each peer. Unique stream ID will be selected for muxing/demuxing
messages on the underlying SCTP transport, see
[draft-ietf-rtcweb-data-protocol-09](https://tools.ietf.org/html/draft-ietf-rtcweb-data-protocol-09#section-6).

## Presentation Connection Messaging

Binary or text messages can be sent on the Data Channel corresponding to the
presentation connection.  The framing of these messages is defined in
[draft-ietf-rtcweb-data-channel](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13#section-6.6).

Either side may close the Presentation Connection by following procedure:
1. Send a control message with close reason on control channel to remote peer.
2. While receiving the control message, initiate the
   [Data Channel close procedure](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13#section-6.6)
3. Consider Presentation Connection is closed while Data Channel is closed.

## Presentation Termination

For controller initiated termination:
1. A controller send a control message with URL and ID on control channel to
   instruct a display to terminate a presentation.
2. The receiver sends a reply to all associated control channels to inform all
   remote peers that a presentation is about to be terminated.

For receiver initiated termination:
1. The receiver directly sends out reply to all associated control channels to
   inform all remote peers that a presentation is about to be terminated.

# Remote Playback API functionality

WebRTC framework supports media codec negociation and real-time media transport.

**TODO:** Fill in when Remote Playback equirements are known.
See [Issue #3](https://github.com/webscreens/openscreenprotocol/issues/3).

# Reliability

WebRTC is designed to be operated on heterogeneous network environment, using
ICE for address discovery and built-in negotiation/re-negotiation mechanism.

*TODO:* Get reliability data.

# Latency to establish a new connection

There are three sources of latency:
1. Connecting a reliable channel the first time for for ICE negotiation.
2. Establishing the first Data Channel.
3. Adding an additional Data Channel on top of an existing peer-to-peer connection.

*TODO:* Get connection latency data.

# Latency to transmit a messages

Data Channel is based on SCTP, which allows for out of order packet delivery and
may improve the latency to deliver presentation connection messages on a
congested or lossy network.

*TODO:* Get supporting data.

# Ease of implementation / deployment

Four major browsers (Chrome/Firefox/Edge/Opera) already implement and ship in
the latest release version. An open source library [WebRTC.org](https://webrtc.org/)
is ready with production level quality.

A common signaling channel/protocol for exchanging ICE candidates needs to be defined.

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

*TODO*: Obtain data on hardware requirements

# Network and power efficiency

Maintain a long-lived Data Channel might not be power efficiency.

*TODO*: Obtain data on network and power efficiency

# Standardization status

Data Channel has a standards track specification in the
IETF [RTCWEB Working Group](https://datatracker.ietf.org/wg/rtcweb/charter/).

Major browsers already implement and ship with interoperability tested.

# Security

Describe security architecture and what encryption and authentication mechanisms
are supported.

A general security study has be done by IETF RTCWEB working group, see
[Security Overview](https://tools.ietf.org/html/draft-ietf-rtcweb-overview-18#section-5)

Signaling channel for exchanging SDP must be encrypted to prevent man-in-the-middle
attack.
DTLS handshake for exchanging encryption key and setup encrypted channel for SCTP.
STUN keepalive can be introduced for consent freshness.
Identity Provider can be introduced for external authentication.


# User Experience

*TODO*: To be evaluated
