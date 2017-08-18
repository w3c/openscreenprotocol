# Open Screen Control Protocol

This document outlines a control protocol suitable to support the implementation
of the [Presentation API](https://w3c.github.io/presentation-api/)
and the [Remote Playback API](https://w3c.github.io/remote-playback/).
It is intended to be implemented on top of one of the proposed Open Screen
transport mechanisms such as [QUIC](quic.md) or [RTCDataChannel](datachannel.md).

The control protocol is responsible for mapping Web API operations and data
provided by Web applications onto network messages for transmission between
controlling user agents and receiving user agents (or remote playback devices).

This document focuses on the syntax and semantics of the network messages
themselves.  The exact content and sequencing of the messages in response to Web
API behavior (to implement the steps of the Presentation API and Remote Playback
API) will be explained in future updates to this document.

## Requirements

* The control protocol must implement
  the [functional requirements for the Presentation API](requirements.md#presentation-api-requirements).
* The control protocol must implement
  the [functional requirements for the Remote Playback API](requirements.md#remote-playback-api-requirements).
* The control protocol must meet [non-functional requirements](requirements.md#non-functional-requirements).

## Message Transport

To meet the requirements above, a message oriented control protocol is
necessary.  That means that each party should be able to transmit a sequence of
variable-length messages from the other, and have that message received as a
whole by the other party, intact and in-order.

The RTCDataChannel does support variable length messages (**TODO:** find a spec
for it!), although there are
[message size limits and possible interoperability issues](https://stackoverflow.com/questions/35381237/webrtc-data-channel-max-data-size).
Meanwhile, QUIC is stream-oriented and not message oriented, so a message
oriented framing must be defined on top of it.  In light of this, this control
protocol will define its own message framing format.

It is assumed that reliability, in-order delivery, and message integrity
are ensured by the tranport and security layer, and they are not addressed here.

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
  that Request.
- Events are sent from a single party to one or more recipients.  No
  responses are expected from any recipient.
  
### Message Structure

Messages are structured as a 36 byte message header, followed by a variable
length message body.

```
Byte offset
  0           +-------------------+
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


- `FLAGS`: A 64-bit flag value explained below.
- `MESSAGE_LENGTH`: A 64-bit unsigned integer that contains the number of bytes
  in the entire message (including these header fields).
- `MESSAGE_TYPE`: A 64-bit value that identifies the message content.  See below for types.
- `SEQUENCE_ID`: A 64-bit, positive unsigned integer that is used to uniquely identify
  messages originating from one party, and to ensure that messages are handled
  in the proper order by the recipient.
- `REQUEST_ID`: A 64-bit unsigned integer.  If the message flavor is a Response,
  it contains the `SEQUENCE_ID` of the Request that the response is replying to.
  For other flavors, it is a zero.

The content of the `MESSAGE_BODY` is not constrained by the generic message structure and
is interpreted according to the contents of the `MESSAGE_TYPE`.

**TODOs:**
- Make REQUEST_ID optional for non-Responses when defining how messages are
  processed, to save 8 bytes.
- Shorten some header fields to 32-bit if possible to save more bytes.
- Investigate variable length integer for MESSAGE_LENGTH to save yet a few more
bytes for short messages.

### Message Flags

The `FLAGS` value contains a bitfield used to inform the recipient how to
process the following message, including the remaining headers.

```
Bit offset
  0           +---------------------------+
              +        PROTOCOL_ID        +
  16          +---------------------------+
              +  PROTOCOL_VERSION_MAJOR   +
  24          +---------------------------+
              +  PROTOCOL_VERSION_MINOR   +
  32          +---------------------------+
              +        RESERVED           +
  64          +---------------------------+
```

`PROTOCOL_ID` is a 16-bit unsigned integer that identifies the specific API,
protocol, or feature that will generate and consume this message.
Protocol ID 0 is not valid, and IDs 1-32,767 will be reserved for publicly
defined control protocols.  We assign the following two IDs:

- 1 for Presentation API Control Protocol
- 2 for Remote Playback API Control Protocol

IDs 32,768 - 65,535 are reserved for private or vendor-specific control protocols.

`PROTOCOL_VERSION_MAJOR` and `PROTOCOL_VERSION_MINOR` identify the version of
the control protocol in use.  It's expected, but not required, that the same
version will be used throughout the lifetime of a connection between two user
agents.  The `MAJOR` and `MINOR` fields are 8-bit unsigned integers that specify
a conventional major.minor version number.  The smallest legal version number is 0.1.

Bit offsets 32-63 are reserved for future use.

### Version Numbers and Cross-Version Compatibility

Minor versions denote minor changes to an existing control protocol, that would
require minimal or no code changes by the sender or receiver.  It's expected
that a sender using version X.Z would be able to interoperate with a receiver
supporting version X.Y, for any value of Z and Y.

Major versions indicate significant (and backwards/forwards incompatible)
changes to a control protocol.  Controlling user agents should support as many
major versions of a control protocol as there are receivers "in the field."

Through discovery, the controlling user agent should obtain the the maxmimum
major protocol version supported by the presentation display.  That major
version of the protocol should be used by the controller going forward.

**TODO:** Update discovery proposals with means for controllers to discover
supported protocols & versions.

### Sequence IDs

Sequence IDs begin at 1 and are incremented by 1 each time a message is
generated by a party.  IDs originating from the same source (that is, endpoint
or stream of the transport) should not be duplicated.  Typically, IDs
originating from the same source will be contiguous, but this is not required;
only that they are monotonically increasing.

**TODO:** Specify when the sequence number is reset as part of the transport
definition; should it reset across reconnections?

**TODO:** In the unlikely event that this 64-bit counter wraps around, consider
setting a flag indicating when this happends.

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

`MESSAGE_TYPE_ID` and `MESSAGE_SUBTYPE_ID` are protocol-specific.  The `TYPE_ID`
is used to group related messages together, and `SUBTYPE_ID` can distinguish
individual message types within that group.

**TODO:** Maybe we could name these MESSAGE_GROUP_ID and MESSAGE_TYPE_ID instead.

### Default, Event, and Request Message Format

Default, Event, and Request messages have no extra fields appended to the basic
message header.

### Response Message Format

Response messages have one additional header field:

```
Byte offset
  32           +-----------------------+
               +  REQUEST_SEQUENCE_ID  +
  40           +-----------------------+
```

The `REQUEST_SEQUENCE_ID` identifies the `SEQUENCE_ID` of the request that the
message is responding to.

## Presentation API Control Protocol

To outline the control protocol, we describe the messages used to implement each
of the
[Presentation API requirements](requirements.md#presentation-api-requirements).
For brevity, each message is described by its flavor, its type, its subtype, and
the structure of the message body.

### Presentation Display Availability

To meet the
[Presentation Display Availability](requirements.md#presentation-display-availability)
requirement, the sender shall generate a Presentation Display Availaiblity
Request and the receiver shall respond with a Presentation Display Availability
Response.

#### Presentation Display Availablity Request

This message is sent by a presentation controller to find whether a presentation
display is compatible with potential presentation URLs.  The request may be sent
when a controller is
[monitoring the list of available presentation displays](https://w3c.github.io/presentation-api/#dfn-monitor-the-list-of-available-presentation-displays)
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

#### Presentation Display Availablity Response

The presentation display shall send a response for each Presentation Display
Availability Request as follows.

```
Flavor:  Response
Type:    0x0001
Subtype: 0x0002

Byte Offset
  40           +-----------------------+
               + NUM_URLS              +
  42           +-----------------------+
               + AVAILABILITY_RESULT_1 +
  43           +-----------------------+
               .                       .
               +-----------------------+
               + AVAILABILITY_RESULT_N +
               +-----------------------+
```

- `NUM_URLS` is an unsigned positive 16-bit integer that matches `NUM_URLS` in
  the corresponding request.
- Each `AVAILABILITY_RESULT` is an unsigned 8-bit integer containing the
  availability result for the Nth URL in the request.
  - A result of 0 means that the URL is not compatible with the display.
  - A result of 1 means that the URL is compatible with the display.
  - Any other result represents an error processing the request, and the
    availability is unknown. **TODO**: Define error result codes.


### Presentation Intiation

### Presentation Resumption

### Presentation Connection

### Sending a Presentation Connection Message

### Terminating a Presentation

## Remote Playback API Control Protocol

**TODO:** Fill in when Remote Playback requirements are
known. See [Issue #3](issues/3).

## Design Questions

### JSON

[JSON](http://www.json.org/) is an alternative format that could be used as a
syntax for the control protocol.  It is Web friendly and human readable. However:

- JSON is less efficient for translating a given set of structured data to the
  wire, especially binary data.
- JSON generation and parsing will likely require a larger code footprint.
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
structure.  It's reasonable to assume that messages between multiple
presentation and remote playback controllers are handled in the same code paths
in the controlling and receiving user agents.  This routing information would be
used to ensure that the messages are sent between the correct processes (in a
multi-process browser) and ultimately to the correct browsing contexts to
activate the corresponding Web APIs.

Routing data could take the form of a source and/or target ids, which would be
assigned by user agents and mapped to individual browsing contexts within that
user agent.

If a separate transport (or transport stream) is always used to connect one
browsing context with another, then there may be no need for additional routing
at the message protocol layer.  QUIC supports the layering of streams over a
single device-to-device transport, while RTCDataChannel does not; so a separate
RTCDataChannel would be required for each frame-to-frame connection.
