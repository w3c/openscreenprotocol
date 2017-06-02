# Multicast DNS / DNS Service Discovery

Multicast DNS (mDNS) and DNS Service Discovery (DNS-SD) are two protocols that
work together to discover services over the local area network by extending
traditional Internet DNS.  (For the rest of this document we use mDNS to refer
to both protocols used together.)

mDNS works on a client-server model.  Clients (listeners) send multicast DNS
queries for records representing service instances, and servers (responders)
answer by multicasting matching records that have been registered for each
instance including SRV, PTR, TXT and A/AAAA.  These records contain addressing
information and metadata for instances of the requested service.

Records are sent with a time-to-live (TTL).  Listeners may cache records they
receive from previous multicasts to answer future queries locally, but should
periodically refresh these cached records before the TTL expires.

## Architecture

**TODO**: Add diagram

## Message Flow

The following message flow illustrates how queries and records are sent between
mDNS listeners and responders.

**TODO**: Add diagram.

## Example

The following are example records that could be exchanged between a controller
and an openscreen display using mDNS.  The Query is sent from the controller,
and other records are sent as part of the answer from the presentation display.
Typically all answer records are sent together if they fit into one packet.  All
records below have class `IN`. The friendly names, TTLs, and text record
contents are examples for illustration.

### Query

```
Flags: 0x0000 (Standard query)
Name:  _openscreen._quic.local
Type:  PTR (Domain name pointer)
```

### PTR

A `PTR` record is a pointer to a specific domain name that can be further resolved.

```
Type:        PTR
Flags:       0x8400 (Authoritative response)
TTL:         5 minutes
Domain Name: Living Room._openscreen._quic.local
```

### SRV

A `SRV` record names a service instance running a specific protocol on a port,
in this case the `Living Room` instance running `_openscreen` on port 8009.

```
Type:        SRV
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

A `TXT` record has arbitrary data about a domain name in a `key`=`value` format
with two-letter keys
([RFC 6763 Section 6](https://tools.ietf.org/html/rfc6763#section-6)).
In this form, values are limited to 252 bytes.

```
Type:        TXT
Name:        Livng Room._openscreen._quic.local
TTL:         60 minutes
Text:        nm=Living Room TV
Text:        id=9b16f21968fabb4d1d00a9f8a741a2dc
Text:        <etc>
```

### A/AAAA

`A` and `AAAA` records contain IP addresses for the named entity.

```
Type:        A
Name:        Living Room.local
TTL:         5 minutes
Addr:        192.168.0.3

Type:        AAAA
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

First, practically speaking answers are limited by the size of an Ethernet
packet, effectively about 1400 bytes.  Some software and routers may further
reject DNS packets over 512 bytes as invalid.  This may not be large enough to
encode all friendly names and some may require truncation.

Second, `SRV` hostnames tend to follow DNS naming conventions, which discourage
special characters and disallow Unicode.

**TODO**: Find out what rules actually exist, if any.

Only `TXT` records may contain a full Unicode string in UTF-8.  Individual `TXT`
values are limited to 255 octets, which may turn out to be a practical
limitation in some character sets.

**TODO**: Find out if that is true.

## Query for presentation URL compatibility

There doesn't appear to be a practical way to do this over mDNS, as an mDNS
query record is not easily extensible to include URLs.  It may be possible for
the presentation display to advertise URL patterns in its `TXT` record to allow
controllers to pre-filter presentation displays by URL.

For mDNS based discovery, querying for URL compatibility must be done using a
separate control channel established to the presentation receiver service.

# Remote Playback API functionality

Describe how the discovery protocol meets functional requirements for the Remote
Playback API.

**TODO:** Fill in when Remote Playback equirements are
known. See [Issue #3](issues/3).

# Reliability

mDNS relies on UDP multicast; individual packets (containing queries or
answers) may not be delivered.  The implementation of mDNS for
Chrome/Chromecast sends queries and answers three times each to minimize the
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

[Issue #37: Share data on mDNS reliability](issues/37)

## Record caching

One interesting aspect of mDNS is the ability for intervening layers of software
between the controller and the presentation display (such as the underlying
controller OS or the router firmware) to cache mDNS records and respond to
queries, even if the original presentation display is unable to communicate
directly with the controller.  If this were implemented correctly, this may
improve reliability by making mDNS more tolerant of transient network
interruptions.

# Latency of device discovery / device removal

When a presentation display connects to a network, it must advertise itself by
repeately multicasting its resource records with the "cache flush" bit set to 1
([RFC 6762 Section 8.3](https://tools.ietf.org/html/rfc6762#section-8.3)).  This
should give listeners the opporunity to discover newly available displays
shortly after they are attached to a network.  However, to meet the requirements
of the specification, a probing step must be completed first to break any naming
ties, which will introduce a delay.

When presentation display is disconnected from a network, it should similarly
advertise a "goodbye" packet that updates its resource records with a TTL of
zero ([RFC 6762 Section 10.1](https://tools.ietf.org/html/rfc6762#section-10.1)).
If things "work as expected", listeners will delete these records from
their cache on receipt and promptly show the presentation display as
unavailable.

If the presentation display is abruptly disconnected from the network and is not
able to transmit a goodbye packet, listeners must wait for the expiration of
their cached records to show the display as unavailable.  This depends on the
TTL set with these records.

# Network and power efficiency

The network utilization of mDNS depends on several factors including:
* The number of controllers and presentation displays connected to the network
  at any one time.
* The frequency that devices enter and leave the network.
* TTL for mDNS answers and cache behavior on listeners.
* The use of Known Answer suppression, which allows listeners to include
  currently cached resource records with their queries.
* Whether all answer records can fit into a single packet.

Because mDNS behavior is specified, it should be possible to construct a model
of network activity given assumptions about the factors above.

[Issue #38: Obtain data on mDNS network and power efficiency](issues/38)

# Ease of implementation / deployment

## Platform support

mDNS has been supported on Mac OS X since version 10.2 (released in 2002) under
the brand name Rendezvous (later Bonjour), and iOS since its initial release
in 2007.  It has been supported in Android since version 4.1 (Jelly Bean,
released in 2012).

## Open source implementations

There are several open source implementations of mDNS listeners and responders.

Apple maintains [mDNSResponder](https://opensource.apple.com/source/mDNSResponder/),
an open source and cross-platform implementation of mDNS, released under an
Apache 2.0 license.

[Avahi](https://github.com/lathiat/avahi) is another open source implementation
of mDNS targeted for Linux under GPL 2.1.

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
* The friendly name of the presentation display.
* IP address(es) and port numbers of a presentation receiver service.
* Additional data exposed through `TXT` records, such as:
  * A full friendly name.
  * URL patterns for compatible presentation URLs.

# Security

mDNS is not secure.  All devices on the local network can observe all other
devices and manipulate the operation of mDNS.  An active attacker with access to
the same LAN can either hide the existence of presentation displays (denial of
service), present false information about displays that do exist (spoofing), or
respond as a fake display and try to get the browser to interact with it
(spoofing).

These issues must be migated by other security aspects of Open Screen such as
device authentication and transport security.

[Issue #39: Investigate history of mDNS related exploits.](issues/39)

# User experience

* As mentioned in _Reliability_, mDNS may be blocked by system or network
  configuration, and it is difficult for end users to diagnose when it fails.

* As mentioned in _Advertisement of friendly name_, the friendly name discovered
  through mDNS may be truncated because of DNS record size limitations.

* As mentioned in _Latency of device removal_, DNS caching induces a delay
  between the disconnection of a presentation display and controllers updating
  their screen availability information.

# Notes

The protocol string `_openscreen._quic` is a placeholder and may not reflect any
actual protocol string chosen for mDNS.  For example, if a TCP based transport
is used it would be `_openscreen._tcp` instead.  Any chosen protocol string(s)
will need to be registered with the [IANA](https://tools.ietf.org/html/rfc6335).

DNS service discovery (DNS-SD) is not limited to LAN multicast; service
discovery can also use unicast DNS mechanisms that exist currently for the
Internet, as proposed in e.g.
[Hybrid Unicast/Multicast DNS-Based Service Discovery](https://tools.ietf.org/html/draft-cheshire-mdnsext-hybrid-02).
A mechanism such as this could be used to enable 'guest mode' discovery of
presentation displays for controllers that are not connected to the same
LAN.

