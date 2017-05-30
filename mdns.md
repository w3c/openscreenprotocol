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

The following are example records that would be sent for an openscreen mDNS service
instance.

### Query

```
Class: IN
Flags: 0x0000 (Standard query)
Name:  _openscreen._quic.local
Type:  PTR (Domain name pointer)
```

### PTR

```
Class:       IN
Flags:       0x8400 (Authoritative response)
TTL:         5 minutes
Domain Name: Living Room._openscreen._quic.local
```

### SRV

```
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



### A/AAAA


# Design and specification

Multicast DNS and DNS-SD are defined by two IETF RFCs.

* [RFC 6762: Multicast DNS](https://tools.ietf.org/html/rfc6762)
* [RFC 6762: DNS-Based Service Discovery](https://tools.ietf.org/html/rfc6763)

In addition the site [dns-sd.org](http://www.dns-sd.org/) contains more
background information on the use of these protocols, and the book
[Zero Configuration Networking: The Definitive Guide](http://shop.oreilly.com/product/9780596101008.do)
contains additional documentation and example code.

# Presentation API functionality

Describe how the discovery protocol meets
[functional requirements for the Presentation API](../requirements.md#presentation-display-availability)
for presentation display availability.

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
