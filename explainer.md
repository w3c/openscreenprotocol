# Open Screen Protocol Explainer

The Open Screen Protocol is a standard way for two agents to discover each other
on the local network, create a secure network connection, and allow an
application on one agent to render media on the other.

This capability allows users to discover media on one device (such as a laptop
or smartphone) and play it on another device (such as a smart TV, set top box,
or connected speaker).   We call this scenario "second screen" functionality.

## Why should users care?

Currently there are many solutions that allow media accessed on one device to be
played on a different device.  Examples include [Google
Cast](https://developers.google.com/cast/), [Apple
AirPlay](https://www.apple.com/airplay/), and [Spotify
Connect](https://www.spotify.com/us/connect/).

However, the application, browser and/or OS largely determine what devices work
together for media playback.  Users can't be easily guaranteed that the content
that they watch and the browser they choose will be able to interface with the
smart TV or speaker that they have or want.

## Why should Web developers care?

Web developers who want to integrate second screen functionality into their
applications need to write different code for each browser to interface with the
devices supported by that browser.  This discourages wide adoption of remote
playback functionality.  For applications that do add second screen support,
they tend to pick one device type versus integrating multiple device-specific
SDKs into their application.

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

We considered adopting an existing protocol like [Google
Cast](https://developers.google.com/cast/) or [HbbTV
2.0](https://www.hbbtv.org/news-events/hbbtv-2-0-specification-released/)
instead of inventing a new protocol from scratch.  However these had limitations
that made them less than ideal:

  * They were not free to implement by other vendors.
  * They did not fully support the Web APIs as written.
  * They did not have a security model that met the requirements of the Web APIs.
  * They would be harder to extend to anticipated future use cases,
    like cross-LAN support or real-time streaming.

## Sample Open Screen Protocol session

As the protocol is not directly exposed to the Web application, we create a
sample session of CBOR messages that two devices might exchange in response to
use of the Web APIs.  (Complete sample code for the Web APIs themselves can
be found in the respective specifications.)

Web application:

```
const p = new PresentationRequest("https://www.example.com");
let availability;
p.getAvailability().then(a => availability = a);
```

At this point the user agent has received a request to search for devices
capable of displaying `https://www.example.com`.  It uses mDNS to search for
Open Screen Protocol endpoints on the LAN and initiates a QUIC connection if it finds one.

If this is the first time connecting to the endpoint, it exchanges
authentication messages with it.  The user is required to type a password to
authenticate that the endpoint is the intended target.


Open Screen Messages:

```
TODO
```

Web application:

```
let connection;
p.start().then(c => connection = c);
c.send("Hello there!");
```

Open Screen Messages:

```
TODO
```

The user may choose to disconnect the page from the presentation once started.

Web application:

```
c.close();
```

Open Screen Messages:

```
TODO
```

Then the user chooses to terminate the presentation, for example by clicking a
button in the UI.

Open Screen Messages:

```
TODO
```

A session for the Remote Playback API is similar. However, instead of exchanging
application messages, the agents exchange messages with media controls and media
playback state.
