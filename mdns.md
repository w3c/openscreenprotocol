# Multicast DNS / DNS Service Discovery

Multicast DNS (mDNS) and DNS Service Discovery (DNS-SD) are two protocols that
work together to discover services over the local area network by extending
traditional Internet DNS.  (For the rest of the document we use mDNS to refer to
both.)

mDNS works on a client-server model.  Clients send multicast DNS queries for
service records, and servers respond by broadcasting DNS records including SRV,
PTR, TXT and A/AAAA contiaining addressing information and metadata for
instances of the requested service.

Records are sent with a time-to-live (TTL).  Clients may cache records they
receive from previous broadcasts to answer future queries locally, but should
periodically refresh these cached records before the TTL expires.

## Message Flow

The following message flow illustrates how queries and records are sent between
clients and servers.

## Example

The following are example records that could be exchanged for an openscreen mDNS
service instance.  The Query is sent from the client (controller) and the other
records are sent as part of the response from the server (presentation display).
The `PTR` record is sent with `SRV`, `TXT`, `A` and `AAAA` records sent as
additional records in the query response.

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

## Discovery of receiver services

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
query record is not easily extensible to encode URLs.  It may be possible for
the presentation display to provide URL patterns in its `TXT` record to allow
controllers to pre-filter presentation displays.

For mDNS based discovery, querying for URL compatibility will likely be done
using the control channel established to the presentation receiver service.

# Remote Playback API functionality

Describe how the discovery protocol meets functional requirements for the Remote
Playback API.

**TODO:** Fill in when Remote Playback equirements are known.
See [Issue #3](https://github.com/webscreens/openscreenprotocol/issues/3).

# Reliability

Data describing reliability in different network requirements.

# Latency of device discovery / device removal

Data on the latency of discovering a new display device added to the network, or
discovering that a display device was disconnected from the network.

# Network and power efficiency

Any data about power and network overhead.

# Ease of implementation / deployment

Including availability of open source implementations.

# IPv4 and IPv6 support

# Hardware requirements

The minimum specifications needed to use the discovery protocol, and whether
the devices in [Sample Device Specifications](../device_specs.md) are
sufficient.

# Standardization status

Describe standardization process, timeline, and link to working group's IPR
policy, if any.

# Privacy

What device or application information is exposed to network observers by the
discovery protocol?

# Security

Describe any impact on the security of the controller or presentation display,
including threats and potential mitigations.

# User experience

Describe any specific impact on
meeting [user experience requirements](../requirements.md#req-nf3-ux) not covered
by the points above.

# Notes
