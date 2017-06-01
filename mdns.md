# Multicast DNS / DNS Service Discovery

Multicast DNS (mDNS) and DNS Service Discovery (DNS-SD) are two protocols that
work together to discover services over the local area network by extending
traditional Internet DNS.  (For the rest of the document we use mDNS to refer to
both.)

mDNS works on a client-server model.  Clients (listeners) send multicast DNS
queries for service records, and servers respond by broadcasting DNS records
including SRV, PTR, TXT and A/AAAA contiaining addressing information and
metadata for instances of the requested service.

Records are sent with a time-to-live (TTL).  Listeners may cache records they
receive from previous broadcasts to answer future queries locally, but should
periodically refresh these cached records before the TTL expires.

## Message Flow

The following message flow illustrates how queries and records are sent between
clients and servers.

## Example

The following are example records that could be exchanged for an openscreen mDNS
service instance.  The Query is sent from the listener (controller) and the
other records are sent as part of the response from the server (presentation
display).  The `PTR` record is sent with `SRV`, `TXT`, `A` and `AAAA` records
sent as additional records in the query response.

### Query

```
Class: IN
Flags: 0x0000 (Standard query)
Name:  _openscreen._quic.local
Type:  PTR (Domain name pointer)
```

### PTR

```
Type:        PTR
Class:       IN
Flags:       0x8400 (Authoritative response)
TTL:         5 minutes
Domain Name: Living Room._openscreen._quic.local
```

### SRV

```
Type:        SRV
Class:       IN
Service:     Living Room
Protocol:    _openscreen
Name:        _quic.local
TTL:         5 minutes
Priority:    0
Weight:      0
Port:        8009
Target:      Living Room.local
```

### TXT

```
Type:        TXT
Name:        Livng Room._openscreen._quic.local
Class:       IN
TTL:         60 minutes
Text:        nm=Living Room TV
Text:        id=9b16f21968fabb4d1d00a9f8a741a2dc
Text:        <etc>
```

### A/AAAA

```
Type:        A
Class:       IN
Name:        Living Room.local
TTL:         5 minutes
Addr:        192.168.0.3

Type:        AAAA
Class:       IN
Name:        Living Room.local
TTL:         5 minutes
Addr:        2620:0:1009:fd00:1d8a:2595:7e02:61db/64
```

# Design and specification

Multicast DNS and DNS-SD are defined by two IETF RFCs.

* [RFC 6762: Multicast DNS](https://tools.ietf.org/html/rfc6762)
* [RFC 6762: DNS-Based Service Discovery](https://tools.ietf.org/html/rfc6763)

In addition the site [dns-sd.org](http://www.dns-sd.org/) contains more
background information on the use of these protocols, and the book
[Zero Configuration Networking: The Definitive Guide](http://shop.oreilly.com/product/9780596101008.do)
contains additional documentation and example code.

# Presentation API functionality

We discuss below how mDNS meets the requirements for
[presentation display availability](requirements.md#presentation-display-availability).

## Discovery of presentation displays

mDNS allows a controller to discover presentation displays on the same local
area network running a presentation receiver service on a given IP:port.  Once
the IP:port is known, the controller can initiate a control channel to the
receiver service using QUIC, TCP, or another transport mechanism to implement
both control messaging and application messaging for the Presentation API.

## Advertisement of friendly name

mDNS allows a friendly name for the display to be provided in two ways:

1. By setting the Service (hostname) part of the `SRV` record.
2. By adding an entry to the `TXT` record, i.e. `nm=Living Room TV`.

However, advertising friendly names through DNS suffers from some inherent
limitations of the DNS protocol.

First, records are limited by the size of an Ethernet packet, effectively about
1400 bytes.  Some software and routers may further reject DNS packets over 512
bytes as invalid.  This may not be large enough to encode all friendly names and
some may require truncation.

Second, `SRV` hostnames tend to follow DNS naming conventions, which discourage
special characters and disallow Unicode.  TODO: Find out what rules actually
exist, if any.

Only `TXT` records may contain a full Unicode string in UTF-8.  `TXT` values are
limited to 255 octets, which may turn out to be a practical limitation in some
character sets.

## Query for presentation URL compatibility

There doesn't appear to be a practical way to do this over mDNS, as the mDNS
query is not easily extensible to include URLs.  It may be possible for the
presentation display to advertise URL patterns in its `TXT` record to allow
controllers to pre-filter presentation displays by URL.

For mDNS based discovery, querying for URL compatibility must be done using the
control channel established to the presentation receiver service.

# Remote Playback API functionality

Describe how the discovery protocol meets functional requirements for the Remote
Playback API.

**TODO:** Fill in when Remote Playback equirements are known.
See [Issue #3](https://github.com/webscreens/openscreenprotocol/issues/3).

# Reliability

mDNS relies on UDP multicast; individual packets (containing queries or
responses) may not be delivered.  The implementation of mDNS for
Chrome/Chromecast sends queries and responses three times each to minimize the
chance that packets are dropped.

Some operating systems (such as Mac OS X/iOS) implement their own mDNS listener,
or installed software may include an mDNS listener that binds port 5353.  A user
agent that implements its own mDNS listener may not be able to run an mDNS
listener on these systems if port 5353 is not bound for shared use.

mDNS is also subject to general issues affecting multicast discovery.  Operating
system configuration, router configuration, and firewall software may block its
operation.  Users may not even be aware of the situation, and it can be
difficult or impossible for user agents to detect what component is blocking
mDNS; users will just be unable to discover any presentation displays.

[Issue #: Share data on mDNS reliability]()

# Latency of device discovery / device removal

# Network and power efficiency

The network utilization of mDNS depends on several factors including:
* The number of controllers and presentation displays connected to the network
  at any one time
* The frequency that devices enter and leave the network
* TTL for mDNS answers and cache behavior on listeners
* The use of Known Answer suppression
* Whether all answer records can fit into a single packet

Because mDNS behavior is specified, it should be possible to construct a model
of network activity given assumptions about the factors above.

[Issue #: Obtain data on mDNS network and power efficiency]()

# Ease of implementation / deployment

## Platform support

mDNS has been supported on Mac OS X since version 10.2 (released in 2002) under
the brand name Rendezvous (later Bonjour), and iOS since its initial release
in 2007.  It has been supported in Android since version 4.1 (Jelly Bean,
released in 2012).

## Open source implementations

There are several open source implementations of mDNS listeners and servers.

Apple maintains [mDNSResponder](https://opensource.apple.com/source/mDNSResponder/),
an open source and cross-platform implementation of an mDNS listener, released
under an Apache 2.0 license.

[Avahi](https://github.com/lathiat/avahi) is another open source implementation
targeted for Linux that contains both listener and server libraries under GPL
2.1.

# IPv4 and IPv6 support

IPv6 is fully supported, as a presentation display can add AAAA records to its answers
to provide IPv6 address(es) for itself. DNS AAAA records are defined by
[RFC 3596: DNS Extensions to Support IP Version 6](https://tools.ietf.org/html/rfc3596).

# Hardware requirements

mDNS has been successfully deployed in 2002-era Apple computers, 2012-era
Android devices, Chromecast, and many other embedded devices; no hardware
compatibility constraints are anticipated.

# Standardization status

mDNS and DNS-SD are specified by two
[Proposed Standard](https://tools.ietf.org/html/rfc7127) RFCs in the IETF.
Apple has submitted IPR disclosures related to these two RFCs.  Ongoing work
continues to evolve DNS-SD in the
[dnssd](https://datatracker.ietf.org/wg/dnssd/about/) IETF working group.

# Privacy

The following information may be revealed through mDNS:
* The friendly name of the presentation display (depending on how the hostname is used).
* Existence of a presentation receiver service, and its IP address(es) and port number.
* Any additional data exposed through `TXT` records, such as:
** A full friendly name.
** Any URL patterns for compatible presentation URLs.

# Security

mDNS is not secure.  All devices on the local network can observe all other
devices and manipulate the operation of mDNS.

* Cache poisoning

[Issue #: Investigate history of mDNS related exploits.]()

# User experience

* Short friendly names.
* Latency of discovery.

# Notes

The protocol string `_openscreen._quic` is a placeholder and may not reflect any
actual protocol string chosen for mDNS.  For example, if a TCP based transport
is used it would be `_openscreen._tcp` instead.  Any chosen protocol string(s)
will need to be registered with the [IANA](https://tools.ietf.org/html/rfc6335).
