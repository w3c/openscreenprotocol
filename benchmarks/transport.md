# Transport Protocol Benchmarks

The goal of this benchmark design is to create a controlled environment in which
we can gather data on performance, efficiency, and reliability of the two
network trasnport protocols proposed for Open Screen:

* [QUIC](../archive/quic.md)
* [RTC DataChannel](../archive/datachannel.md)

# Observables

* Network efficiency & utilization
  * Number of packets and bytes exchanged per connection established
  * Number of packets and bytes exchanged per control message
  * Number of packets and bytes exchanged per application message
  * Total packets and bytes for a typical presentation session
  * Peak number of packets and bytes sent per second
* Power efficiency
  * Total mW consumed per minute per device for a typical presentation session
* Reliability
  * Ratio of successful connections per attempt
  * Ratio of messages successfully transmitted per attempt
  * Frequency of dropped connections
* Latency
  * Time to initiate a new connection
  * Time to transmit a control message (from first byte sent to last byte received)
  * Time to transmit an application message (from first byte sent to last byte received)

# Test Environment

## Hardware and Operating System

The test hardware will be identical to that for the [discovery
benchmarks](discovery.md).

## Networking

The test network will be identical to that for the [discovery
benchmarks](discovery.md).

## Software

### QUIC

The QUIC implementation (both client and server) is part of the Chromium open
source project.  Driver binaries will need to be written to create QUIC
connections, and the result compiled for the Raspberry PI platform.

QUIC crypto will be disabled or set to a trivial implementation initially.  When
a transport authentication protocol is defined, it will be converted to use that
protocol and new data collected.

The QUIC implementation will be instrumented to log data related to the
Observables above, including (but not limited to):
* Packets and bytes sent and received per second
* Packets and bytes sent and received per message
* Packets and bytes sent and received per connection
* Timestamps a connection was initiated and when it was connected
* Timestamps a message was sent and received
* Timestamps of any errors encountered (connection failed, message failed)

A Python script will be used to start the client and server process with command
line flags to adjust behavior for a given test condition.  Data collection will
happen as described in the [discovery benchmark](discovery.md).

### RTC DataChannel

RTC DataChannel is implemented by WebRTC.  A binary driver that understands the
same command line flags as the QUIC driver will need to be written.  The driver
will include the WebRTC library and a client and server for the bootstrap
channel.

[Issue #73](https://github.com/webscreens/openscreenprotocol/issues/73): Define
boostrap mechanism for RTCDataChannel.

WebRTC exposes byte level statistics for individual data channels through its
[API](https://w3c.github.io/webrtc-stats/#dcstats-dict*), although not
packet-level statistics, which will require modification of WebRTC.

# Experimental Variables

The following variables will be adjusted and the Observables collected for each
condition.

To keep the number of conditions within reason, one set of parameters will be
adjusted and the others kept fixed.  In case the data shows interesting trends,
we can run more conditions as desired as the entire process will be automated
through scripting.

## Protocols in use

* QUIC
* Bootstrap channel + RTCDataChannel

## Device Population

* Number of controllers per receiver: 1, 2, 4, 8, 16

## Physical Positioning

We will test two conditions:

* All devices all co-located in the same room
* Controllers in one room, router in a second room, and receiver in a third room.

## Message type and sequence

We will run through the following sequence of connections and messages:

1. First controller initiates a connection to the receiver.
1. First controller initiates a presentation on the receiver.
1. First controller begins sending a sequence of messages `N` seconds apart to
   the receiver.  Each message is a random length averaging `S` bytes.
1. After a random delay averaging `M` seconds, subsequent controllers will make
   additional connections to the receiver and begin sending their own messags.
1. Receiver echoes all messages received back to the controller.

The following parameters will be varied:
* Delay between connection initiation (`M`)
* Average delay between messages (`M`)
* Average message size (`S`)

**NOTE**: For large `S`, small `M`, and multiple simultaneous controllers, we
may hit network bandwidth or platform limitations of the receiver.

# Data Collection And Analysis

For numerical values, data will be collected for a given experimental condition
N = 30 times and the 50%, 75%, and 95% values computed, as well as time series.

One experimental condition (the control) will have no connections to collect
baseline data.

# Notes / Future Work

## Mobile Device Benchmarking

See [Issue #72](https://github.com/webscreens/openscreenprotocol/issues/72).

## Multi-receiver cases

The current design considers one receiver (running one presentation) and
multiple controllers.  It may be worth considering adding a second receiver;
however, the network behavior for the trasnport layer is point-to-point and not
multicast, so we do not expect to observe any significant differences in
benchmarks for the second receiver.
