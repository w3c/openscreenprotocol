# Open Screen Control Protocol

This document describes a control protocol suitable to support the
implementation of
the [Presentation API](https://w3c.github.io/presentation-api/) and
the [Remote Playback API](https://w3c.github.io/remote-playback/).  It is
intended to be implemented on top of one of the proposed Open Screen transport
mechanisms such as [QUIC](quic.md) or [RTCDataChannel](datachannel.md).

The control protocol is responsible for mapping Web application requests and
data provided by Web applications onto a network transport for transmission
between controlling user agents and receivers (hosted on presentation displays
and remote playback devices).

This document focuses on the syntax and semantics of the network messages
themselves.  A future update will map these messages onto specific steps in the
algorithms described in the respective specifications for the Presentation API
and the Remote Playback API.

## Requirements

* The control protocol must implement
  the [functional requirements for the Presentation API](requirements.md#presentation-api-requirements).
* The control protocol must implement
  the [functional requirements for the Remote Playback API](requirements.md#remote-playback-api-requirements).
* The control protocol must meet [non-functional requirements](requirements.md#non-functional-requirements).

If an [RTCDataChannel](datachannel.md) is used as the transport, additional
messages will be required to exchange WebRTC signaling messages to establish the
channel.

## Message Transport

To meet the requirements above, a message oriented control protocol is
necessary.  That means that each party should be able to transmit a sequence of
variable-length messages from the other, and have every message received by the
other party, intact and in-order.

The RTCDataChannel supports variable length messages by virtue of
adopting [SCTP](https://tools.ietf.org/html/rfc4960) as its message transmission
protocol. The
[RTCDataChannel specification](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13)
suggests there may be
[implementation restrictions on message size](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13#section-4)
and that implementations should
[interleave messages](https://tools.ietf.org/html/draft-ietf-rtcweb-data-channel-13#section-6.6)
for fairness.

Meanwhile, QUIC is stream-oriented and not message oriented, so a message
oriented framing must be defined on top of it.  In light of this, this control
protocol defines its own message framing format.

It is assumed that reliability, in-order delivery, and message integrity are
ensured by the tranport and security layer, and they are not addressed here.
(Note that each message does have a sequence ID that allows user agents
to process messages in the order they were generated.)

## Message Format

Messages are sent among parties responsible for implementing the Presentation
API or the Remote Playback API.  The message format should allow each party to
deserialize each message as it arrives over the transport and dispatch it to
appropriate code in the implementation of each API.

## Message Flavors

Messages come in four flavors: Commands, Requests, Responses, and Events.

- Commands are unidirectional messages sent from one party to a single
  recipient.  No response is expected from the recipient.
- Requests are sent from one party to a single recipient.  That recipient must
  reply with a Response back to the initial sender that contains a reference to
  the sequence ID of the Request.
- Events are sent from a single party to one or more recipients.  No
  responses are expected from any recipient.

### Message Structure

Messages are structured as a 36 byte message header, followed by a variable
length message body.

```
Byte offset
  0           +-------------------+
              +    PROTOCOL_ID    +
  4           +-------------------+
              +      FLAGS        +
  8           +-------------------+
              +  MESSAGE_LENGTH   +
  16          +-------------------+
              +   MESSAGE_TYPE    +
  24          +-------------------+
              +   SEQUENCE_ID     +
  32          +-------------------+
              +    REQUEST_ID     +
  36          +-------------------+
              +   MESSAGE BODY    +
              .                   .
              .                   .
              .                   .
              +-------------------+
```


The overall length of a message is constrained only by the `MESSAGE_LENGTH`
field, or 2^64 - 1 bytes.  Practically speaking, messages are limited by the
memory capacity of each party, the underlying tansport, and the necessity of
transmitting messages in a reasonable amount of time.

All integers are to be represented in [network byte order](https://tools.ietf.org/html/rfc1700).


- `PROTOCOL_ID`: A 32-bit value explained below.
- `FLAGS`: A 32-bit value explained below.
- `MESSAGE_LENGTH`: A 64-bit unsigned integer that contains the number of bytes
  in the entire message (including all header fields).
- `MESSAGE_TYPE`: A 64-bit value that identifies the message content.
- `SEQUENCE_ID`: A 64-bit, positive unsigned integer that is used to uniquely
  identify messages originating from one party, and to ensure that messages are
  handled in the proper order by the recipient.
- `REQUEST_ID`: An optional 64-bit unsigned integer.  If the message flavor is a
  Response, it contains the `SEQUENCE_ID` of the Request that the response is
  replying to.  For other flavors, it is not present.

The content of the `MESSAGE_BODY` is not constrained by the generic message
structure, and must be interpreted according to the `MESSAGE_TYPE`.

**TODO:** Investigate variable length integers for `MESSAGE_LENGTH`,
`SEQUENCE_ID` to save bytes for short messages.  See
[Issue #45](https://github.com/webscreens/openscreenprotocol/issues/45).

### Protocol ID

The `PROTOCOL_ID` informs the recipient how to process the following
message, including the remaining headers.

```
Bit offset
  0           +---------------------------+
              +       PROTOCOL_TYPE       +
  16          +---------------------------+
              +       VERSION_MAJOR       +
  24          +---------------------------+
              +       VERSION_MINOR       +
  32          +---------------------------+
```

`PROTOCOL_TYPE` is a 16-bit unsigned integer that identifies the specific API,
protocol, or feature that will generate and consume this message.
Protocol type 0 is not valid, and types 1-32,767 will be reserved for publicly
defined control protocols.  We assign the following two types:

- 1 for Presentation API Control Protocol
- 2 for Remote Playback API Control Protocol

Types 32,768 - 65,535 are reserved for private or vendor-specific control
protocols.

`VERSION_MAJOR` and `VERSION_MINOR` identify the version of the control protocol
in use.  It's expected, but not required, that the same version will be used
throughout the lifetime of a connection between two user agents.  The `MAJOR`
and `MINOR` fields are 8-bit unsigned integers that specify a conventional
major.minor version number.  The smallest legal version number is 0.1.

### Version Numbers and Cross-Version Compatibility

Minor versions denote minor changes to an existing control protocol, that would
require minimal or no code changes by the controlling user agent or receiver.
It's expected that a controlling user agent using version X.Z would be able to
interoperate with a receiver supporting version X.Y, for any value of Z and Y.

Major versions indicate significant (and possibly backwards/forwards
incompatible) changes to a control protocol.  Controllers should support as many
major versions of a control protocol as there are receivers "in the field."

Through discovery, the controlling user agent should obtain the the maxmimum
protocol version supported by the receiver that is also supported by the
controlling user agent.  That version of the protocol should be used by the
controlling user agent going forward.

**TODO:** Update discovery proposals with means for controlling user agents to
discover supported protocols & versions.

### Flags

The `FLAGS` value is a 32-bit array of flags, each carrying a true/set or
false/unset value.  The table below lists the meaning of each position.

Position | Meaning when set  | Meaning when not set
---------|-------------------|---------------------
0        | Sequence ID reset | Ignored
1-31     | Reserved          | Reserved

### Sequence IDs

Sequence IDs begin at 1 and are incremented by 1 each time a message is
generated by a controlling user agent or receiver.  IDs originating from the
same source must not be duplicated.  Typically, IDs originating from the same
source will be contiguous, but this is not required; only that they are
monotonically increasing.

If the sequence ID reaches `2^64 - 1`, it will wrap around to 1 for the next
message, and that message will have its flag 0 set.

### Message Types

The `MESSAGE_TYPE` field is as follows:

```
Bit offset
  0           +---------------------------+
              +      MESSAGE_FLAVOR       +
  8           +---------------------------+
              +      MESSAGE_TYPE_ID      +
  24          +---------------------------+
              +    MESSAGE_SUBTYPE_ID     +
  40          +---------------------------+
              +        RESERVED           +
  64          +---------------------------+
```

`MESSAGE_FLAVOR` is an 8-bit unsigned integer that conveys the message flavor:

Value | Flavor
------|-------
0     | Command
1     | Request
2     | Response
3     | Event

`MESSAGE_TYPE_ID` and `MESSAGE_SUBTYPE_ID` are protocol-specific.  The
`MESSAGE_TYPE_ID` is used to group related messages together, and
`MESSAGE_SUBTYPE_ID` can distinguish individual message types within that group.

**TODO**: Define an extensions format to allow additional data to be bundled
with a defined message type.

## Presentation API Control Protocol

To outline the control protocol, we describe the messages used to implement each
of the
[Presentation API requirements](requirements.md#presentation-api-requirements).
For brevity, each message is described by its flavor, its type, its subtype, and
the structure of the message body.

### Message types

The Presentation API control protocol uses five message types according to the
functionality implemented by the message.

Message Type (hex) | Functionality
-------------------|---------------
0x0001             | Presentation Display Availability
0x0002             | Presentation Lifecycle
0x0003             | Presentation Connection Management
0x0004             | Presentation Application Messages
0x0005             | Receiver Status

### Presentation Display Availability

To meet the [Presentation Display
Availability](requirements.md#presentation-display-availability) requirement,
the controlling user agent shall generate a Presentation Display Availaiblity
Request and the receiver shall respond with a Presentation Display Availability
Response.

#### Presentation Display Availablity Request

This message is sent by a controlling user agent to find whether a receiver is
compatible with potential presentation URLs.  The request may be sent when a
controlling user agent is [monitoring the list of available presentation
displays](https://w3c.github.io/presentation-api/#dfn-monitor-the-list-of-available-presentation-displays)
(when starting a presentation or monitoring availability in the background), or
when a new presentation display is discovered.

```
Flavor:  Request
Type:    0x0001
Subtype: 0x0001

Byte Offset
  32           +-----------------------+
               +  NUM_URLS             +
  34           +-----------------------+
               +  URL_1_LENGTH         +
  38           +-----------------------+
               +  URL_1_CONTENT        +
               +-----------------------+
               +  URL_2_LENGTH         +
               +-----------------------+
               +  URL_2_CONTENT        +
               +-----------------------+
               .                       .
               +-----------------------+
               +  URL_N_LENGTH         +
               +-----------------------+
               +  URL_N_CONTENT        +
               +-----------------------+
```


- `NUM_URLS` is an unsigned positive 16-bit integer with the number of URLs
  contained in the message.
- `URL_N_LENGTH` is an unsigned 32-bit integer with the length, in bytes, of the
  Nth URL.
- `URL_N_CONTENT` is the Nth URL contained in the message, encoded according to
  [RFC 3986](https://tools.ietf.org/html/rfc3986#section-2).

Note that this request will send presentation URLs from controlling user agents
to receivers, even before the user has selected the corresponding display for
presentation.  An alternative mechanism would allow the controlling user agent
to retrieve URL patterns from a receiver that match the URLs supported by that
receiver.

**TODO**: Add messages for this based on conclusion to
[Issue #21](https://github.com/webscreens/openscreenprotocol/issues/21).

Note that the URLs sent by the Presentation Availability Request may contain
custom (non-https) schemes.  Please review [Schemes and Open Screen
Protocol](schemes.md) for how custom schemes are handled in OSP.

#### Presentation Display Availablity Response

The receiver shall send a response for each Presentation Display Availability
Request as follows.  The receiver may use the order it returns its availability
results to indicate its preference for which URL should be presented on that
display.

```
Flavor:  Response
Type:    0x0001
Subtype: 0x0002

Byte Offset
  40           +-----------------------+
               + NUM_URLS              +
  42           +-----------------------+
               + INDEX_1               +
  44           +-----------------------+
               + AVAILABILITY_RESULT_1 +
  45           +-----------------------+
               .                       .
               +-----------------------+
               + INDEX_N               +
               +-----------------------+
               + AVAILABILITY_RESULT_N +
               +-----------------------+
```

- `NUM_URLS` is an unsigned positive 16-bit integer that is identical to
  `NUM_URLS` in the corresponding Presentation Display Availability Request.
- Each `INDEX_N` is an unsigned 16-bit integer corresponding to the index
  position of the Nth URL in the Presentation Availability Request (starting
  from zero).
- Each `AVAILABILITY_RESULT_N` is an unsigned 8-bit integer containing the
  availability result for the `INDEX_N`th URL in the request.  The results are
  as follows:

Availability Result | Meaning
--------------------|--------
0                   | The URL is not compatible with the receiver.
1                   | The URL is compatible with the receiver.
10                  | The URL was not valid URL.
100                 | The availability check timed out.
101                 | The availability check failed (transient error).
102                 | The availability check failed (permanent error).
199                 | Unknown or other error processing URL.


### Presentation Lifecycle

#### Presentation Initiation Request

This message is sent by a controlling user agent to start presentation on a
receiver.  The URL must be one that has been previously reported as compatible
by that display.

```
Flavor:  Request
Type:    0x0002
Subtype: 0x0001

Byte Offset
  32           +-----------------------+
               +  PRESENTATION_ID      +
  160          +-----------------------+
               +  HEADERS_LENGTH       +
  162          +-----------------------+
               +  HEADERS_CONTENT      +
               +-----------------------+
               +  URL_LENGTH           +
               +-----------------------+
               +  URL_CONTENT          +
               +-----------------------+
```

- `PRESENTATION_ID` is a null (zero-byte) terminated ASCII string of 128 bytes
  that communicates the ID for the presentation.  Values shorter than 128 bytes
  should be zero-byte padded.
- `HEADERS_LENGTH` is a unsigned positive 16-bit integer with the length, in
  bytes, of the headers to include with the request to fetch the presentation
  URL.
- `HEADERS_CONTENT` is the content of HTTP headers to include in the request to
  fetch the presentation URL.  This field must be exactly `HEADERS_LENGTH` bytes
  in length and should follow the syntax of
  [RFC 7230](https://tools.ietf.org/html/rfc7230#section-3.2).
- The `HEADERS_CONTENT` field must include an `Accept-Language` header as
  defined in [RFC 7231](https://tools.ietf.org/html/rfc7231#section-5.3.5) that
  communicates the preferred locale for the presentation.
- `URL_LENGTH` is an unsigned positive 32-bit integer with the length, in bytes,
  of the presentation URL.
- `URL_CONTENT` is the presentation URL, encoded according to RFC 3986.  This
  field must be exactly `URL_LENGTH` bytes in length.

Note that the URL sent in the Presentation Initiation Request may contain a
custom (non-https) scheme.  Please review [Schemes and Open Screen
Protocol](schemes.md) for how custom schemes are handled in OSP.

#### Presentation Initiation Response

This message is sent by the receiver in reponse to a Presentation
Initiation Request.  It should be sent when either the receiver is ready to
receive connections to the presentation, or presentation initiation encounters
an error that prevents intiation from proceeding.

```
Flavor:  Response
Type:    0x0002
Subtype: 0x0002

Byte Offset
  40           +-----------------------+
               + PRESENTATION_ID       +
  168          +-----------------------+
               + INITIATION_RESULT     +
  169          +-----------------------+
               + HTTP_RESPONSE_CODE    +
  173          +-----------------------+
```

- `PRESENTATION_ID` is a null (zero-byte) terminated ASCII string of exactly 128
  bytes that matches the Presentation ID sent in the Request.  Values shorter
  than 128 bytes should be zero-byte padded.
- `INITIATION_RESULT` is a one-byte result code as follows:

Availability Result | Meaning
--------------------|--------
1                   | The presentation was loaded successfully.
10                  | The URL in the request was not valid URL.
100                 | The initation request timed out.
101                 | The initiation request failed (transient, non-HTTP error).
102                 | The initiation request failed (permanent, non-HTTP error).
103                 | The URL encountered an HTTP error while loading.
199                 | Unknown or other error processing initiation request.

- The `HTTP_RESPONSE_CODE` contains an unsigned 32-bit integer with the numeric
  HTTP response code resulting from loading the presentation URL for the
  request.

#### Presentation Termination Request

This message is sent by a controlling user agent to terminate a presentation.
In general, the simplest and most usable approach is to allow any connected
controlling user agent to terminate a presentation if they know its ID and URL.
There is no response to this request, instead the controlling user agent should
wait to receive the Presentation Termination Event to determine whether it was
successful.

**TODO**: If we need to return errors, then consider defining a Response.

```
Flavor:  Command
Type:    0x0002
Subtype: 0x0003

Byte Offset
  32           +-----------------------+
               +  PRESENTATION_ID      +
  40           +-----------------------+
               +  URL_LENGTH           +
               +-----------------------+
               +  URL_CONTENT          +
               +-----------------------+
               +  TERMINATION_SOURCE   +
               +-----------------------+
```

- `PRESENTATION_ID` is a null (zero-byte) terminated ASCII string of 128 bytes
  that communicates the ID for the presentation.  Values shorter than 128 bytes
  should be zero-byte padded.
- `URL_LENGTH` is an unsigned positive 32-bit integer with the length, in bytes,
  of the presentation URL.
- `URL_CONTENT` is the presentation URL, encoded according to RFC 3986.  This
  field must be exactly `URL_LENGTH` bytes in length.
- `TERMINATION_SOURCE` is a one-byte code describing the source of the
  termination request.

Termination Source | Meaning
-------------------|--------
10                 | A connected controller called `terminate()` on the connection object.
11                 | A user terminated the presentation via the controlling user agent.

Note that these codes must match up with reason codes in the Presenation
Termination Event for terminations that come from a controlling user agent.

#### Presentation Termination Event

This event is sent by the receiver to all connected controlling user agents to
inform them that a presentation has been terminated.

```
Flavor:  Event
Type:    0x0002
Subtype: 0x0004

Byte Offset
  40           +-----------------------+
               +  PRESENTATION_ID      +
  168          +-----------------------+
               +  TERMINATION_REASON   +
               ------------------------+
```

- `PRESENTATION_ID` is a null (zero-byte) terminated ASCII string of exactly 128
  bytes that communicates the ID for the presentation that was terminated.
  Values shorter than 128 bytes should be zero-byte padded.
- `TERMINATION_REASON` is a one-byte reason code as follows:

Termination Reason | Meaning
-------------------|--------
1                  | The presentation called connection.terminate().
2                  | A user terminated the presentation via the receiver or presentation display.
10                 | A connected controller called connection.terminate().
11                 | A user terminated the presentation via the controlling user agent.
20                 | A new presentation was started and replaced the current presentation.
30                 | The presentation was terminated because it was idle for too long.
31                 | The presentation was terminated because it attempted to navigate.
100                | The presentation display is powering down or the receiver is shutting down.
101                | The receiver had a fatal software error (i.e. crash).
255                | Unknown or other reason.

### Presentation Connection Management

#### Presentation Connection Request

This message is sent by a controlling user agent to a reciever to connect a
controller to a presentation.  The Presentation URL and Presentation ID should
correspond to a presentation that has been started on the receiver through a
successful Presentation Initiation Request.

```
Flavor:  Request
Type:    0x0003
Subtype: 0x0001

Byte Offset
  32           +-----------------------+
               +  PRESENTATION_ID      +
  160          +-----------------------+
               +  URL_LENGTH           +
  164          +-----------------------+
               +  URL_CONTENT          +
               +-----------------------+
```

- `PRESENTATION_ID` is a null (zero-byte) terminated ASCII string of exactly 128
  bytes that communicates the ID for the presentation.  Values shorter than 128
  bytes should be zero-byte padded.
- `URL_LENGTH` is an unsigned positive 32-bit integer with the length, in bytes,
  of the presentation URL that was sent in the corresponding Presentation
  Initiation Request.
- `URL_CONTENT` is the presentation URL, encoded according to RFC 3986.  This
  field must be exactly `URL_LENGTH` bytes in length.

### Presentation Connection Response

This message is sent by the receiver to the controlling user agent in reponse to
a Presentation Connection Request.  One should be sent for every Presentation
Connection Request regardless of whether it was successful or not.

```
Flavor:  Response
Type:    0x0003
Subtype: 0x0002

Byte Offset
  40           +-----------------------+
               + PRESENTATION_ID       +
  42           +-----------------------+
               + CONNECTION_ID         +
  46           +-----------------------+
               + CONNECTION_RESULT     +
  47           +-----------------------+
```

- `PRESENTATION_ID` is a null (zero-byte) terminated ASCII string of exactly 128
  bytes that communicates the ID for the presentation.  Values shorter than 128
  bytes should be zero-byte padded.
- `CONNECTION_ID` is a 32-bit positive integer that starts at 1 and is
  incremented by one for each successful connection to the presentation page.
  If there was an error connecting to the page, it is zero.
- `CONNECTION_RESULT` is a one-byte result code as follows:

Connection Result   | Meaning
--------------------|--------
1                   | A connection was created successfully.
10                  | The URL in the request was not valid URL.
11                  | The ID in the request was not a valid ID.
12                  | The URL and ID do not match any known presentation.
100                 | The connection request timed out.
101                 | The connection request could not be handled at this time (transient).
102                 | The connection request was refused (permanent).
103                 | The presentation is in the process of terminating and cannot accept new connections.
199                 | Unknown or other error processing connection request.

#### Presentation Connection Close Event

This message is sent by either the receiver or the controlling user agent to the
other party to notify that a presentation connection has been closed.  Note that
there is no specific response to this event, as it's main purpose is to fire a
correct `PresentationConnectionCloseEvent` on the other party's connection
object.

```
Flavor:  Event
Type:    0x0003
Subtype: 0x0003

Byte Offset
  40           +-----------------------+
               + PRESENTATION_ID       +
  42           +-----------------------+
               + CONNECTION_ID         +
  46           +-----------------------+
               + CLOSE_REASON          +
  47           +-----------------------+
               + ERROR_MESSAGE         +
  559          +-----------------------+
```

- `PRESENTATION_ID` is a null (zero-byte) terminated ASCII string of exactly 128
  bytes that communicates the ID for the presentation.  Values shorter than 128
  bytes should be zero-byte padded.
- `CONNECTION_ID` is a 32-bit positive integer that corresponds to a connection
  to between the controller and receiver.
- `CLOSE_REASON` is a one-byte reason code as follows:

Close Reason   | Meaning
---------------|--------
1              | The controller or presentation called `close()` on the connection object.
10             | The controller or presentation discarded the connection object or navigated away.
100            | The connection encountered an unrecoverable error while sending or receiving a message.

- `ERROR_MESSAGE` is an optional, null (zero-byte) terminated ASCII string of
  exactly 512 bytes describing the error that occurred handling a message.
  If it is less than 512 bytes, it should be zero padded.  If there is no
  message, it should be all zeros.

It's not expected that either party send a Close Event when encountering a
network or tranport level error, as an invalid transport would prevent the
reliable delivery of the command anyway.  Instead the user agent should fire the
`PresentationConnectionClose` event locally on connection objects based on its
observation of the network state.

**NOTE:** If the control channel and individual presentation connections use
different network connections or transports, it would make sense to enumerate
specific network errors here for the network failure of an individual
presentation connection.

### Presentation Application Message

This message is used to transmit an application message between the controller
and presentation, via the `send()` method on the connection object.

```
Flavor:  Command
Type:    0x0004
Subtype: 0x0001

Byte Offset
  32           +-----------------------+
               +  PRESENTATION_ID      +
  160          +-----------------------+
               +  CONNECTION_ID        +
  164          +-----------------------+
               +  MESSAGE_TYPE         +
  165          +-----------------------+
               +  MESSAGE_LENGTH       +
  197          +-----------------------+
               +  MESSAGE_CONTENT      +
               +-----------------------+
```

- `PRESENTATION_ID` is a null (zero-byte) terminated ASCII string of 128 bytes
  that communicates the ID for the presentation.  Values shorter than 128 bytes
  should be zero-byte padded.
- `CONNECTION_ID` is a 32-bit positive integer that corresponds to the ID of the
  receiver `PresentationConnection` that is conveying the message.
- `MESSAGE_TYPE` is a one-byte code describing the message type as follows:

Message Type | Meaning
-------------|--------
1            | Text message
2            | Binary message
3            | Empty text message

- `MESSAGE_LENGTH` is an unsigned 32-bit integer with the length, in bytes,
  of the message content.
- `MESSAGE_CONTENT` is the content of the message.  It must be exactly
  `MESSAGE_LENGTH` bytes in length. For text messages, the `MESSAGE_CONTENT`
  must correspond to a valid and non-empty UTF-8 string.  For binary messages,
  the content is arbitrary binary data.

A `MESSAGE_TYPE` of 3 corresponds to an empty string, i.e. `send('')`.
If the `MESSAGE_TYPE` is 3, the `MESSAGE_LENGTH` must be zero.

**TODO:** Do we need special handling of empty binary messages, i.e. `new
ArrayBuffer(0)`

### Presentation Receiver Status Event

This message allows the receiver to broadcast status information to all
connected controlling user agents.  It may be sent at any time, but should be
sent when the content of a Display Info or Presentation Info has changed since
the last broadcast.  The receiver may be configured to broadcast a subset of the
information in this message or none at all depending on the policies and privacy
preferences of the user.

This Receiver Status event is a composition of sub-messages.  See below for the
breakout of the sub-message formats.

```
Flavor:  Event
Type:    0x0005
Subtype: 0x0001

Byte Offset
  32           +-----------------------+
               + DISPLAY_INFO          +
  K            +-----------------------+
               + NUM_PRESENTATION_INFO +
  K+4          +-----------------------+
               + PRESENTATION_INFO_1   +
               +-----------------------+
               + ...                   +
               +-----------------------+
               + PRESENTATION_INFO_N   +
               +-----------------------+
```

### Display Info

The Display Info struct conveys information about the presentation display
device itself.  Currently this includes information about the friendly name
which may be too long to fit in a discovery protocol message.

```
Byte Offset
  0            +-----------------------+
               + FRIENDLY_NAME_LOCALE  +
  64           +-----------------------+
               + FRIENDLY_NAME_LENGTH  +
  66           +-----------------------+
               + FRIENDLY_NAME_CONTENT +
               +-----------------------+
```

- `FRIENDLY_NAME_LOCALE` is a 64-byte, zero terminated ASCII value with the
  BCP-47 language code of the friendly name.  If it is shorter than 64 bytes, it
  should be right-padded by zeroes.
- `FRIENDLY_NAME_LENGTH` is a 2-byte positive unsigned integer with the length
  of `FRIENDLY_NAME_CONTENT`.
- `FRIENDLY_NAME_CONTENT` is a valid UTF-8 encoded string with the friendly name
  of the presentation display.  It is exactly `FRIENDLY_NAME_LENGTH` bytes in
  length.

**TODO:**
[Representation of BCP-47 language tags](https://github.com/webscreens/openscreenprotocol/issues/47)

### Presentation Info

The Presentation Info struct conveys information about a running presentation.
All fields are optional.  By advertising a presentation's URL and ID, the
receiver will allow any connected controlling user agent to connect to that
presentation.

```
Byte Offset
  0            +-----------------------+
               +  PRESENTATION_ID      +
  128          +-----------------------+
               +  URL_LENGTH           +
  132          +-----------------------+
               +  URL_CONTENT          +
  K            +-----------------------+
               +  NUM_CONNECTIONS      +
  K+2          +-----------------------+
               +  TITLE_LOCALE         +
  K+66         +-----------------------+
               +  TITLE_LENGTH         +
  K+78         +-----------------------+
               +  TITLE_CONTENT        +
               +-----------------------+
```

- `PRESENTATION_ID` is a null (zero-byte) terminated ASCII string of 128 bytes
  that communicates the ID for the presentation.  Values shorter than 128 bytes
  should be zero-byte padded.  If omitted, it should be all zeros.
- `URL_LENGTH` is an unsigned positive 32-bit integer with the length, in bytes,
  of the presentation URL.  The presentation URL is omitted, it should be zero.
- `URL_CONTENT` is the presentation URL, encoded according to RFC 3986.  This
  field must be exactly `URL_LENGTH` bytes in length.  If the presentation URL
  is omitted, this field is not present.
- `NUM_CONNECTIONS` is an unsigned 2-byte integer that holds the number of
  presentation connections that are in a `connected` state.  If omitted, this
  field is zero.
- `TITLE_LOCALE` is is a 64-byte, zero terminated ASCII value with the BCP-47
  language code of the friendly name.  If it is shorter than 64 bytes, it should
  be right-padded by zeroes.  If the presentation title omitted, it is all
  zeros.
- `TITLE_LENGTH` is a 2-byte positive unsigned integer with the length
  of `TITLE_CONTENT`.  If the presentation title is omitted, this is zero.
- `TITLE_CONTENT` is a valid UTF-8 encoded string with the [title of the
  presentation document](https://html.spec.whatwg.org/multipage/semantics.html#the-title-element).
  It is exactly `TITLE_LENGTH` bytes in length.  If the presentation title is
  omitted, this field is not present.

**NOTE**: We could add a status flag to tell controlling user agents the status
of the presentation (loading/ready/terminating/terminated).

**NOTE:** We could allow the receiver to broadcast only the origin of the
presentation, not the full URL, for display purposes in the controlling user
agent.  In that case, we would need to add a flag to convey this so the
controller knows not to attempt reconnection with just the origin.

## Remote Playback API Control Protocol

**TODO:** Fill in when Remote Playback requirements are known. See
[Issue #3](https://github.com/webscreens/openscreenprotocol/issues/3).

## Design Discussion

### JSON

[JSON](http://www.json.org/) is an alternative format that could be used as a
syntax for the control protocol.  It is Web friendly and human
readable. However:

- JSON is less efficient for translating a given set of structured data to the
  wire, especially binary data.
- JSON generation and parsing requires a larger code footprint.
- JSON parsing is a potential source of security vulnerabilities.
- JSON is a very generic and untyped syntax; a full protocol specification would
  need to clearly define how to handle missing fields, non-conformant types,
  extraneous fields, quoting, and a myriad of other corner cases.  Correct
  implementations would then need to write validation code for the same.

For these reasons, this proposal does not purse JSON as a control protocol
format.  It should be straightforward to write code that translates binary
protocol messages into human readable strings for logging and debugging.

### Message Routing

It may be desirable to add additional routing data to the basic message
structure.  It's reasonable to assume that messages between controllers and
presentations are handled by the same code paths in controlling user agents and
receivers.  This routing information would be used to ensure that the messages
are sent between the correct processes (in a multi-process browser) and
ultimately to the correct browsing contexts to activate the corresponding Web
APIs.

Routing data could take the form of a source and/or target ids, which would be
assigned by user agents and mapped to individual browsing contexts within that
user agent.

If a separate transport (or transport stream) is always used to connect one
browsing context with another, then there may be no need for additional routing
at the message protocol layer.  QUIC supports the layering of streams over a
single device-to-device transport, while RTCDataChannel does not.  If we don't
include routing data, a separate RTCDataChannel would be required for each
frame-to-frame connection.

### Role Reversal

The underlying control protocol should be symmetric; meaning, that either end of
the network transport can take the role of the controlling user agent or
receiver (regardless of who discovered whom).  This could enable scenarios
whereby an application loaded on a presentation display initiates presentation
on a mobile or laptop device whose user agent implements the receiver role of
the protocol (responding to availability and presentation requests, etc.)

To fully realize this, the protocol needs to be extended with a capabilities
exchange so that each party knows what roles the other may assume (controlling
user agent, receiver, or both).

**TODO**: Add protocol support for capability/role advertisement.

### Language Tags


