# Requirements for Open Screen Protocol

This document outlines the functional and non-functional requirements of the
Open Screen protocol.

Functional requirements derive from the two Web APIs that the protocol will support:
- The [Presentation API](https://w3c.github.io/presentation-api/)
- The [Remote Playback API](https://w3c.github.io/remote-playback/)

## Presentation API

The Presentation API allows one browser (the _controlling user agent_, or
_controller_) to discover and initiate presentation of a Web document on a
second user agent (the _receiving user agent_, or _receiver_).  We use the term
_display_ to refer the entire device responsible for implementing the
_receiver_, including OS, networking and display.

### <a name="REQ-D01"></a>REQ-P1: Presentation Display Availability

1. A controller must be able to discover the presence of a display connected to
the same IPv4 or IPv6 subnet and reachable by IP multicast.

2. A controller must be able to obtain the IPv4 or IPv6 address of the receiver,
a friendly name for the display, and an IP port number for establishing a
network transport to the receiver.

3. A controller must be able to determine if the receiver is capable of
displaying a specific presentation request URL.

### <a name="REQ-D02"></a>REQ-D02: Presentation Connections

1. The controller must be able to start a new presentation on a receiver given a
presentation request URL and a presentation ID.

2. The controller must be able to connect a controlling browsing context to a
running presentation on the receiver, given a presentation request URL and
presentation ID.

3. The controller or receiver must be able to close a connection between a
controlling browsing context and a presentation, and signal the other context
with the reason why the connection was closed (`closed` or `wentaway`).

### <a name="REQ-R03"></a>REQ-D03: Presentation Connection Messaging

A _message_ refers to the data passed with an invocation of
`PresentationConnection.send()` by the controller or receiver.

1. Messages sent by the controller must be delivered to the
receiver (or vice versa) in a reliable and in-order fashion.

2. If a message cannot be delivered, then the controller and receiver must be
able signal both browsing contexts that the connection was closed with reason `error`.

3. The controller and receiver must be able to send and receive `DOMString` messages
(represented as `string` in ECMAScript).

4. The controller and receiver must be able to send and receive binary messages
(represented as `Blob` in HTML5, or `ArrayBuffer` or `ArrayBufferView` in
ECMAScript).

### <a name="REQ-D04"></a>REQ-D04: Presentation Termination

1. The controller must be able to signal to the receiver to terminate a
presentation, given its presentation request URL and presentation ID.

2. The receiver must be able to signal all connected controllers that the
presentation was terminated.
