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

## Message Flow

The following message flow illustrates how queries and records are sent between
mDNS listeners and responders.  The listener begins by multicasting a QUERY to
the multicast address 224.0.0.251:5300.  Responders that receive the request
respond by multicasting resource records to the same address.  (The class, flags
and TTL of these records are omitted for brevity.)

If a responder is about to disconnect from the network, it multicasts the same
records with a TTL of 0.  This instructs listeners that may have cached the
records to discard them.

![](images/mdns.png)

If a responder has updated information to propagate to listeners (for example, a
change in TXT data or IP address), or it has just connected to a network, it can
send an unsolicited multicast of its current resource records with the "cache
flush" bit set to 1.  Listeners will overwrite any existing cached records for
that host.  More details on cache flush semantics can be found in
[RFC 6762 Section 10.2](https://tools.ietf.org/html/rfc6762#section-10.2).

## Example

The following are example records that could be exchanged between a controlling
user agent and a presentation display using mDNS.  The Query is sent from the
controlling user agent, and other records are sent as part of the answer from
the presentation display.  Typically all answer records are sent together if
they fit into one packet.  All records below have class `IN`. The friendly
names, TTLs, and text record contents are examples for illustration.

### Query

```
Flags: 0x0000 (Standard query)
Name:  _openscreen._quic.local
Type:  PTR (Domain name pointer)
```

### PTR

A `PTR` record is a pointer to a specific domain name that can be further
resolved.

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
* [RFC 6763: DNS-Based Service Discovery](https://tools.ietf.org/html/rfc6763)

In addition the site [dns-sd.org](http://www.dns-sd.org/) contains more
background information on the use of these protocols, and the book
[Zero Configuration Networking: The Definitive Guide](http://shop.oreilly.com/product/9780596101008.do)
contains additional documentation and example code.

# Presentation API functionality

We discuss below how mDNS meets the requirements for
[presentation display availability](requirements.md#presentation-display-availability).

## Discovery of presentation displays

mDNS allows a controlling user agent to discover presentation displays on the
same local area network running a receiver on a given
IP:port.  mDNS does not support reliable message exchange, so once the IP:port
is known, the controlling user agent will initiate a control channel to the
receiver using QUIC, TCP, or another reliable transport protocol.  The
control channel can then be used for control of presentations and/or
`PresentationConnection` messaging.

## Advertisement of friendly name

mDNS allows a friendly name for the presentation display to be provided in two
ways:

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

Only `TXT` records may contain a full Unicode string in UTF-8.  Individual `TXT`
values are limited to 255 octets, which may turn out to be a practical
limitation in some character sets.

## Query for presentation URL compatibility

There doesn't appear to be a practical way to do this over mDNS, as an mDNS
query record is not easily extensible to include URLs.  It may be possible for
the presentation display to advertise URL patterns in its `TXT` record to allow
controlling user agents to pre-filter presentation displays by URL.

For mDNS based discovery, querying for URL compatibility must be done using a
separate control channel established to the receiver.

# Remote Playback API functionality

Describe how the discovery protocol meets functional requirements for the Remote
Playback API.

**TODO:** Fill in when Remote Playback requirements are
known. See
[Issue #3](https://github.com/webscreens/openscreenprotocol/issues/3).

# Reliability

## Protocol issues

mDNS relies on UDP multicast; individual packets (containing queries or
answers) may not be delivered.  The implementation of mDNS for
Chrome/Chromecast sends queries and answers three times each to minimize the
chance that packets are dropped.

There is a risk that listeners have cached data from previous answers that is
out of date (providing the wrong host name, IP address or other metadata).  The
mDNS protocol addresses cache coherency by several mechanisms:
* Responders should send unsolicited multicasts of updated data with the "cache
  flush" bit set.
* Listeners should attempt to revalidate cached records at 80%, 90%, and 95% of
  TTL lifetime.
* If there are other listeners connected to the same network, the listener will
  also receive multicast responses to their queries, and can use them to
  maintain its cached records.
* The listener should aggressively flush cached records on a network topology
  change (interface up/down, change of WiFi SSID, etc.)

There is also a risk that listeners will cache records for a presentation
display that is no longer connected to the network, especially if the display
was abruptly disconnected.  This can be mitigated by using other signals, such
as disconnection or keep-alive failure of the control channel, to track when a
presentation display has disconnected.

## Platform issues

Some operating systems (such as Mac OS X/iOS) implement their own mDNS listener,
or installed software may include an mDNS listener that binds port 5353.  A user
agent that implements its own mDNS listener may not be able to run an mDNS
listener on these systems if port 5353 is not bound for shared use.

mDNS is also subject to general issues affecting multicast discovery.  Operating
system configuration, router configuration, and firewall software may block its
operation.  Users may not even be aware of the situation, and it can be
difficult or impossible for user agents to determine what component is blocking
mDNS; users will just be unable to discover any presentation displays.

[Issue #37](https://github.com/webscreens/openscreenprotocol/issues/37): Get
reliability data.

## Record caching

One interesting aspect of mDNS is the ability for intervening layers of software
between the controlling user agent and the presentation display (such as the
underlying controlling user agent OS or the router firmware) to cache mDNS
records and respond to queries, even if the original presentation display is
unable to communicate directly with the controlling user agent.  If this is
implemented with correct support for cache coherency, this may improve
reliability by making mDNS more tolerant of transient network interruptions.

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

[Issue #69](https://github.com/webscreens/openscreenprotocol/issues/69): Collect
data on latency of discovery.

# Network and power efficiency

The network utilization of mDNS depends on several factors including:
* The number of controlling user agents and presentation displays connected to
  the network at any one time.
* The frequency that devices enter and leave the network.
* TTL for mDNS answers and cache behavior on listeners.
* The use of Known Answer suppression, which allows listeners to include
  currently cached resource records with their queries.
* Whether all answer records can fit into a single packet.

Because mDNS behavior is specified, it should be possible to construct a model
of network activity given assumptions about the factors above.

[Issue #38](https://github.com/webscreens/openscreenprotocol/issues/38): Get
network and power efficiency data.

# Ease of implementation / deployment

## Platform support

mDNS has been supported on Mac OS X since version 10.2 (released in 2002) under
the brand name Rendezvous (now Bonjour), and iOS since its initial release
in 2007.  It has been supported in Android since version 4.1 (Jelly Bean,
released in 2012). On Windows, mDNS is supported for UWP applications in
Windows 10 via
[advertisement](https://docs.microsoft.com/en-us/uwp/api/Windows.Networking.ServiceDiscovery.Dnssd)
and
[device enumeration](https://docs.microsoft.com/en-us/uwp/api/windows.devices.enumeration)
APIs. It is also supported in Chrome OS for Chrome apps via
[chrome.mdns](https://developer.chrome.com/apps/mdns).

## Open source implementations

There are several open source implementations of mDNS listeners and responders.

Apple maintains [mDNSResponder](https://opensource.apple.com/source/mDNSResponder/),
an open source and cross-platform implementation of mDNS, released under an
Apache 2.0 license.

[Avahi](https://github.com/lathiat/avahi) is another open source implementation
of mDNS targeted for Linux under GPL 2.1.

# IPv4 and IPv6 support

IPv6 is fully supported, as a presentation display can add AAAA records to its
answers to provide IPv6 address(es) for itself. DNS AAAA records are defined by
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
* IP address(es) and port numbers of a receiver.
* Additional data exposed through `TXT` records, such as:
  * A full friendly name.
  * URL patterns for compatible presentation URLs.

# Security

mDNS is not secure.  All devices on the local network can observe all other
devices and manipulate the operation of mDNS.  An active attacker with access to
the same LAN can either hide the existence of presentation displays (denial of
service), present false information about displays that do exist (spoofing), or
respond as a fake display/browser and try to get a browser/display to interact
with it (spoofing).

These issues must be mitigated by other security features of Open Screen such as
device authentication and transport security.

## Security History

The [CVE database](https://cve.mitre.org/index.html) has at least 23 past
vulnerability disclosures related to mDNS.  They can be broken down into the
following categories.

### Denial of Service

The most common vulnerability occured when the mDNS responder was unable to
handle an invalid request, resulting in an application crash or other denial of
service.

* [CVE-2006-2288](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-2288)
* [CVE-2007-0613](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-0613)
* [CVE-2007-0614](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-0614)
* [CVE-2007-0710](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-0710)
* [CVE-2008-2326](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-2326)
* [CVE-2008-5081](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-5081)
* [CVE-2009-0758](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2009-0758)
* [CVE-2011-1002](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2011-1002)
* [CVE-2013-1141](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2013-1141)
* [CVE-2014-3357](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-3357)
* [CVE-2014-3358](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-3358)
* [CVE-2015-0650](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-0650)
* [CVE-2017-6520](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-6520)

### WAN mDNS responses

Some mDNS responders were vulnerable because they answered unicast mDNS queries
on their WAN interface, allowing a remote host to query for LAN internal
services and possibly disrupt LAN service discovery through denial of service
attacks.

* [CVE-2015-1892](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-1892)
* [CVE-2015-2809](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-2809)
* [CVE-2015-6586](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-6586)

### Arbitrary Code Execution

These are the most serious attacks that could lead to a temporary or persistent
exploit of the presentation display by permitting arbitrary code execution.
Below there is a one-line summary of the nature of the exploit when known.

* [CVE-2007-3744](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-3744) -
Related to a port mapping protocol, not mDNS itself.
* [CVE-2007-3828](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-3828)
* [CVE-2008-0989](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-0989) -
Format string issue with local hostnames.
* [CVE-2015-7987](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-7987) -
Multiple buffer overflows.
* [CVE-2015-7988](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-7988)

### Other

* [CVE-2008-3630](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-3630)
* [CVE-2014-3290](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-3290)

### Analysis

Based on the vulnerability history, mDNS carries a potential risk of two
intersecting vulnerabilities creating a new remote exploit vector:
1. Presentation display's mDNS responder listens for mDNS queries that originate
   from the WAN.
2. Presentation display's mDNS responder allows remote code execution through a
   malformed query.

To mitigate these risks, any implementation of an mDNS responder should leverage
good security practices, including but not limited to:

* Sandboxing the process that hosts the mDNS responder to prevent exploits from
  gaining access to priveleged system APIs.
* Network and OS-level firewalls to block mDNS queries originating from the WAN.
* Regular security audits of the mDNS responder code, including fuzz testing to
  proble handling of malformed input.
* Regular software updates to patch known vulnerabilities.

# User experience

* As mentioned in _Reliability_, mDNS may be blocked by system or network
  configuration, and it is difficult for end users to diagnose when it fails.

* As mentioned in _Advertisement of friendly name_, the friendly name discovered
  through mDNS may be truncated because of DNS record size limitations.

* As mentioned in _Latency of device removal_, DNS caching induces a delay
  between the disconnection of a presentation display and controlling user
  agents updating their display availability information.

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
presentation displays for controlling user agents that are not connected to the
same LAN.
