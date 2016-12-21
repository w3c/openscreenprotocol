# Requirements for Open Screen Protocol

This document outlines functional and non-functional requirements of the Open
Screen protocol.

Functional requirements derive from the two Web APIs that the protocol will support:
- The [Presentation API](https://w3c.github.io/presentation-api/)
- The [Remote Playback API](https://w3c.github.io/remote-playback/)

Non-functional requirements address efficiency, user experience, and security
aspects of the protocols.

## Presentation API

The Presentation API allows one browser (the *controlling user agent*, or
*controller*) to discover and initiate presentation of Web content on a second
user agent (the *receiving user agent*, or *receiver*).  We use the term
*display* to refer to the entire device responsible for implementing the
*receiver*, including browser, OS, networking and screen.

A *presentation* is initated at the request of a *controlling browsing context*
(Web page), which creates a *receiving browsing context* to load a *presentation
request URL* and exchange messages with the resulting presentation.

For detailed information about the behavior of the Presentation API operations
described below, please consult the Presentation API specification.

### <a name="REQ-P1"></a>Presentation Display Availability

1. A controller must be able to discover the presence of a display connected to
the same IPv4 or IPv6 subnet and reachable by IP multicast.

2. A controller must be able to obtain the IPv4 or IPv6 address of the display,
a friendly name for the display, and an IP port number for establishing a
network transport to the display.

3. A controller must be able to determine if the receiver is reasonably capable
of displaying a specific presentation request URL.

### <a name="REQ-P2"></a>Presentation Initiation

1. The controller must be able to start a new presentation on a receiver given a
presentation request URL and a presentation ID.

### <a name="REQ-P3"></a>Presentation Resumption

1. The controller must be able to reconnect to an active presentation on the
receiver, given its presentation request URL and presentation ID.

### <a name="REQ-P4"></a>Presentation Connections

1. The controller or receiver must be able to close a connection between a
controlling browsing context and the presentation, and signal the other party
with the reason why the connection was closed (`closed` or `wentaway`).

2. Multiple controlling browsing contexts must be able to connect to a
presentation simultaneously (either from one controller, or multiple
controllers).

### <a name="REQ-P5"></a>Presentation Connection Messaging

A *message* refers to the data passed with an invocation of
`PresentationConnection.send()` by the controller or receiver.

1. Messages sent by the controller must be delivered to the receiver (or vice
versa) in a reliable and in-order fashion.

2. If a message cannot be delivered, then the controller must be able to signal
the receiver (or vice versa) that the connection should be closed with reason
`error`.

3. The controller and receiver must be able to send and receive `DOMString`
messages (represented as `string` type in ECMAScript).

4. The controller and receiver must be able to send and receive binary messages
(represented as `Blob` objects in HTML5, or `ArrayBuffer` or `ArrayBufferView`
types in ECMAScript).

### <a name="REQ-P6"></a>Presentation Termination

1. The controller must be able to signal to the receiver to terminate a
presentation, given its presentation request URL and presentation ID.

2. The receiver must be able to signal all connected controllers when a
presentation is terminated.

## Remote Playback API requirements

TBD

## Non-functional requirements

### <a name="REQ-NF1"></a>Hardware and efficiency

1. It should be possible to implement an Open Screen display using modest
hardware requirements, similar to what is found in a smart TV or streaming
device. *TODO:* Source typical CPU/memory for these types of devices.

2. It should be possible to implement an Open Screen controller on a low-end
smartphone. *TODO:* Source typical CPU/memory for these types of devices.
   
3. The discovery and connection protocols should minimize power consumption,
especially on the controller.

### <a name="REQ-NF2"></a>Privacy and Security

1. The protocol should minimize the amount of information provided to a passive
   network observer about active presentations on the receiver.
   
2. The protocol should prevent passive network attackers from learning
   presentation URLs, presentation IDs, or the content of presentation messages
   passed between controllers and receivers.
   
3. The protocol should prevent active network attackers from impersonating a
   display and observing or altering data intended for the controller or
   receiver.

### User Experience

TBD

