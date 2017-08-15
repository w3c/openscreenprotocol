# Control Protocol

This document outlines a control protocol for the Presentation API and the
Remote Playback API.  It is intended to be implemented on top of one of the
proposed transport mechanisms such as [QUIC](quic.md)
or [RTCDataChannel](datachannel.md).  The control protocol is responsible for
mapping Web API operations (including application messages) onto a network
syntax for transmission between controlling user agents and presentation
screens, and ultimately between presentation controller and receiver pages.

## Requirements

* The control protocol must implement
  the [functional requirements for the Presentation API](requirements.md#presentation-api-requirements).
* The control protocol must implement
  the [functional requirements for the Remote Playback API](requirements.md#remote-playback-api-requirements).
* The control protocol must meet [non-functional requirements](requirements.md#non-functional-requirements).

## Message Transport

For the use cases described above, a message oriented control protocol is
necessary.  That means that each party should be able to transmit a sequence of
variable-length messages from the other, and have that message received as a
whole by the other party, intact and in-order.

The RTCDataChannel does support variable length messages (TODO: find a spec for
it!), although there are
[message size limits and possible interoperability issues](https://stackoverflow.com/questions/35381237/webrtc-data-channel-max-data-size).
Meanwhile, QUIC is stream-oriented and not message oriented, so a message
oriented framing must be defined on top of it.

In light of this, this control protocol will define its own message framing
format.  If the chosen transport is able to support framing natively, it may be
revised in the future to leverage that.

It is assumed that message reliability, in-order delivery, and message integrity
are ensured by the tranport and security layer, and they are not addressed here.

## Generic Message Format




## Presentation API Control Protocol

## Remote Playback API 


