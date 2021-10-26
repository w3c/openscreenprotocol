# Open Screen Protocol Explainer

The Open Screen Protocol allows one networked device to discover another on the
local network, create a secure connection, and request that the other device
render an application or streaming media using Web APIs such as the
[Presentation API](https://w3c.github.io/presentation-api/) and [Remote Playback
API](https://w3c.github.io/remote-playback/).

We call devices that implement this protocol Open Screen Agents.

## Why should users care?

Currently there are several proprietary solutions that allow media accessed on
one device to be played on a different device.  Examples include [Google
Cast](https://developers.google.com/cast/), [Apple
AirPlay](https://www.apple.com/airplay/), and [Spotify
Connect](https://www.spotify.com/us/connect/).

However, the application, browser and/or OS largely determine what devices work
together for media playback.  The choice of one device, OS or browser largely
determines what other media devices are compatible for launching Web
applications and remote media playback.  This in turn may force users into using
specific devices, OSes, or browsers in order to take advantage of second screen
functionality.  It also prevents some browsers from implementing second screen
Web APIs at all.

## Why should Web developers care?

Web developers who want to integrate second screen functionality into their
applications currently need to write different code for each browser to
interface with the devices supported by that browser.  This discourages wide
adoption of remote playback functionality.  For applications that do add second
screen support, they tend to pick one device type versus integrating multiple
device-specific SDKs into their application.

One goal of Second Screen APIs is to allow developers to write one application
for remote media playback and expect it to function as expected across as many
devices and browsers as possible.

## Assumptions and Goals

The primary goal of the Open Screen Protocol is to provide a complete network
protocol to allow devices from different vendors to implement second screen
APIs and work together. 

The protocol specifically targets the [requirements of second screen Web
APIs](requirements.md): the [Remote Playback
API](https://w3c.github.io/remote-playback/) and the [Presentation
API](https://w3c.github.io/presentation-api/).

A design goal is to re-use existing network and data standards like mDNS, QUIC
and CBOR as building blocks, versus inventing our own.

The protocol also provides [security and privacy
guarantees](requirements.md#privacy-and-security), especially with regards to
other devices on the network.

We assume that the protocol should work on devices with [low-end CPUs and
constrained memory](device_specs.md), which are typical in special purpose
devices like smart TVs and connected speakers.  We also assume the protocol will
be used on [battery-powered devices](requirements.md#hardware-and-efficiency). 

## Non-Goals

A non-goal is to enable every Web application to be able to successfully render
content on every Open Screen Protocol device.  Devices have a wide range of
rendering capabilities and policies about what content they wish to support.
The protocol allows devices to indicate whether they are compatible with a
specific URL or media type.

## Alternatives Considered

We considered adopting an existing protocol like
[Google Cast](https://developers.google.com/cast/),
[DIAL](http://www.dial-multiscreen.org/home),
or [HbbTV 2.0](https://www.hbbtv.org/news-events/hbbtv-2-0-specification-released/)
instead of inventing a new protocol from scratch.  However these have significant
limitations that motivated the development of a new protocol:

  * They were not free to implement by other vendors.
  * They did not fully support the Web APIs as written.
  * They did not have a security model that met the requirements of the Web APIs.
  * They would be harder to extend to anticipated future use cases,
    like cross-LAN support, or future cross-device Web APIs.

## Protocol Overview

An interaction between Open Screen agents consists of the following phases.

*Phase 1.* Discovery and connection.

Initially, an agent _S_ [advertises itself using
mDNS](https://w3c.github.io/openscreenprotocol/#discovery) as available for
other agents to connect to.  Another agent, _C_, [initiates a connection](https://w3c.github.io/openscreenprotocol/#transport) using QUIC to the port and IP address advertised by _S_.

*Phase 2.* Authentication.

[TLS 1.3 is used to secure the
connection](https://w3c.github.io/openscreenprotocol/#tls-13) between _C_ and
_S_.  If _C_ and _S_ have not authenticated before, they negotiate one party to
present a one-time code and the other party to accept the code.  (Typically the
end user is asked to input into _C_ a code presented on the screen of
_S_.)  [SPAKE2 is used to generate a shared
secret](https://w3c.github.io/openscreenprotocol/#authentication-with-spake2)
and verify the identities of the TLS 1.3 endpoints.

*Phase 3.* Capability exchange.

Once the connection is authenticated,
[the two agents exchange capabilities](https://w3c.github.io/openscreenprotocol/#metadata),
which map to sets of messages that each agent understands.  For example, one
agent may be an initiator of media remote playback, and the other agent may be
the receiver of remote playback requests.

Some capabilities are defined by the spec corresponding to the needs of the
Remote Playback API and Presentation API.  However, the [set of capabilities is
open ended](https://w3c.github.io/openscreenprotocol/#protocol-extensions) and
may be extended to accomodate future requirements, additional Web APIs, or
device-specific features.

*Phase 4.* API-specific usage.

Once the two agents have learned each other's capabilities, they can exchange
messages at the request of Web applications through supported Web APIs.

For example, if _C_ wishes to [start a presentation](https://w3c.github.io/openscreenprotocol/#presentation-api) on _S_, it would:

1. Send a `presentation-url-availability-request` to learn if _S_ can use the URL to start a presentation.
2. Send a `presentation-start-request` to request that _S_ start a presentation with the URL.
3. Send and receive `presentation-connection-message`s to exchange messages with the active presentation.
4. Disconnect from the presentation with `presentation-connection-close-event` or request its termination with `presentation-termination-request`.

All messages that are specific to the Open Screen Protocol are encoded with CBOR
which provides a good tradeoff between performance, conciseness and Web compatibility.


## Privacy and security

The protocol is responsible for enabling a secure network connection between two
Open Screen agents. The spec includes guidelines for the presentation and
consumption of the pairing code, how agents can track other agents that have
been previously authenticated, and when an agent should be reauthenticated.

Other aspects of security and privacy for second screen applications using the
protocol are covered in other specifications, handled by specific agent
implementations, or may be in scope for future revisions of the protocol.

## Relationship to other Web specifications

[WebRTC-QUIC](https://w3c.github.io/webrtc-quic/) is a proposal to enable Web
applications to create peer-to-peer QUIC connections.  This could enable
applications to implement parts of the Open Screen Protocol in script.

[WebTransport](https://w3c.github.io/webtransport/) allows Web applications to
construct HTTP/3 connections to servers.  It may be possible to implement parts
of the Open Screen protocol in application script on top of an HTTP/3
WebTransport.

With either of these capabiliites, applications still cannot discover and
authenticate to Open Screen agents on their own.  Those aspects would need to be
handled by the user agent, or new APIs developed to enable Web applications to
take them on.
