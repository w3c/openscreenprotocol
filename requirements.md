# Requirements for Open Screen Protocol

This document outlines functional and non-functional requirements of the Open
Screen protocol.

Functional requirements derive from the two Web APIs that the protocol will support:
- The [Presentation API](https://w3c.github.io/presentation-api/)
- The [Remote Playback API](https://w3c.github.io/remote-playback/)

Non-functional requirements address efficiency, user experience, and security
aspects of the protocols.

## Presentation API Requirements

The Presentation API allows one browser
(the [*controlling user agent*](https://w3c.github.io/presentation-api/#dfn-controlling-user-agent),
or *controller*) to discover and initiate presentation of Web content on a
second user agent (the
[*receiving user agent*](https://w3c.github.io/presentation-api/#receiving-user-agent),
or *receiver*).  We use the term
[*display*](https://w3c.github.io/presentation-api/#dfn-presentation-display) to
refer to the entire device responsible for implementing the *receiver*,
including browser, OS, networking and screen.

A *presentation* is initated at the request of a
[*controlling browsing context*](https://w3c.github.io/presentation-api/#dfn-controlling-browsing-context)
(Web page), which creates a
[*receiving browsing context*](https://w3c.github.io/presentation-api/#dfn-receiving-browsing-context)
to load a
[*presentation request URL*](https://w3c.github.io/presentation-api/#dfn-presentation-url)
and exchange messages with the resulting presentation.

For detailed information about the behavior of the Presentation API operations
described below, please consult the Presentation API specification.

### <a name="req-p1-availability"></a>Presentation Display Availability

1. A controller must be able to discover the presence of a display connected to
   the same IPv4 or IPv6 subnet and reachable by IP multicast.

2. A controller must be able to obtain the IPv4 or IPv6 address of the display,
   a friendly name for the display, and an IP port number for establishing a
   network transport to the display.

3. A controller must be able to determine if the receiver is reasonably capable
   of displaying a specific presentation request URL.

### <a name="req-p2-initiation"></a>Presentation Initiation

1. The controller must be able to start a new presentation on a receiver given a
   presentation request URL and presentation ID.

### <a name="req-p3-resumption"></a>Presentation Resumption

1. The controller must be able to reconnect to an active presentation on the
   receiver, given its presentation request URL and presentation ID.

### <a name="req-p4-connections"></a>Presentation Connections

1. The controller or receiver must be able to close a connection between a
   controlling browsing context and the presentation, and signal the other party
   with the reason why the connection was closed (`closed` or `wentaway`).

2. Multiple controlling browsing contexts must be able to connect to a
   presentation simultaneously (either from one controller, or multiple
   controllers).

### <a name="req-p5-messaging"></a>Presentation Connection Messaging

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
   (represented as `Blob` objects in HTML5, or `ArrayBuffer` or
   `ArrayBufferView` types in ECMAScript).

### <a name="req-p6-termination"></a>Presentation Termination

1. The controller must be able to signal to the receiver to terminate a
   presentation, given its presentation request URL and presentation ID.

2. The receiver must be able to signal all connected controllers when a
   presentation is terminated.

## Remote Playback API Requirements

TBD

## Non-functional Requirements

### <a name="req-nf1-hardware"></a>Hardware and Efficiency

1. It should be possible to implement an Open Screen display using modest
   hardware requirements, similar to what is found in a smart TV or streaming
   device. See the [Device Specifications](device_specs.md) document for
   expected receiver device specifications.

2. It should be possible to implement an Open Screen controller on a low-end
   smartphone. the [Device Specifications](device_specs.md) document for
   expected controller device specifications.
   
3. The discovery and connection protocols should minimize power consumption,
   especially on the controller which is likely to be battery powered.

### <a name="req-nf2-privacy-security"></a>Privacy and Security

1. The protocol should minimize the amount of information provided to a passive
   network observer about the identity of the controller or activity on the
   receiver.
   
2. The protocol should prevent passive network observers from learning
   presentation URLs, presentation IDs, or the content of presentation messages
   passed between controllers and receivers.
   
3. The protocol should prevent active network attackers from impersonating a
   display and observing or altering data intended for the controller or
   receiver.

###  <a name="req-nf3-ux"></a>User Experience

1. The controller should be able to discover quickly a when display becomes
   available or unavailable (i.e. when it connects or disconnects from the
   network).
   
2. The controller should present sensible information to the user when a
   protocol operation fails.  For example, if a controller is unable to start a
   presentation, it should be possible to report in the controller interface if
   it was a network error, authentication error, or the presentation content
   failed to load.

3. The controller should be able to remember authenticated displays.  This means it
   is not required for the user to intervene and re-authenticate each time the
   controller connects to a pre-authenticated display.

4. Message latency between the controlling browsing context and a presentation
   should be minimized to permit interactive use.  For example, it should be
   comfortable to type in a form in the controlling page and having the text
   appear in the presentation.  Real-time latency for gaming or mouse use is
   ideal, but not a requirement.
   
5. The controller initiating presentation should communicate its preferred
   locale to the display, so it can render the presentation content in that
   locale.
   


