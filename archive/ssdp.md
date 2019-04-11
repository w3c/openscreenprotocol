# SSDP

This document evaluates SSDP as a discovery protocol for the Open Screen
Protocol according to several functional and non-functional requirements.

SSDP (Simple Service Discovery Protocol) is the first layer in the
[UPnP (Universal Plug and Play) Device Architecture](http://www.upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf).
It allows user devices like smartphones or tablets (called _control points_) to
search for other devices or services of interest on the network.

SSDP is also used as part of other protocols separately from the whole UPnP
stack. One such protocol
is [DIAL (DIscovery And Launch)](http://www.dial-multiscreen.org/), which allows
second-screen devices like smartphones or tablets to discover and launch
applications on first-screen devices like smart TVs, set-top boxes and game
consoles.

Another example is
[HbbTV 2.0 (Hybrid broadcast broadband TV)](https://www.hbbtv.org/resource-library/),
which extends DIAL to discover HbbTV devices and launch HbbTV applications.

[Fraunhofer FOKUS](https://www.fokus.fraunhofer.de/fame) has
[proposed](https://github.com/google/physical-web/blob/master/documentation/ssdp_support.md)
the use of SSDP to advertise and find URLs in a local area network, as part of
the [Physical Web Project](https://github.com/google/physical-web).


# Design and Specification

SSDP allows uPnP _root devices_ (that offer services like TVs, printers, etc.)
to advertise services to control points on the network. It also allows control
points to search for devices or services of interest at any time. SSDP specifies
the messages exchanged between control points and root devices.

SSDP advertisements contain specific information about the service or device,
including its type and a unique identifier.  SSDP messages adopt the header
field format of HTTP 1.1.  However, the rest of the protocol is not based on
HTTP 1.1, as it uses UDP instead of TCP and it has its own processing rules.

The following sequence diagram shows the SSDP message exchange between a control
point and root device.

![](images/ssdp.png)


## Message Flow

1. The root device advertises itself on the network by sending a `NOTIFY`
   message of type `ssdp:alive` for each service it offers to the multicast
   address `239.255.255.250:1900` with all the information needed to access that
   service.  Control points listening on the multicast address receive the
   message and check the service type (`NT`) header to determine if it is
   relevant or not.

   To obtain more information, the control point makes an HTTP request to the
   device description URL provided in the `LOCATION` header of the `NOTIFY`
   message. The device description is a XML document that contains information
   about the device like its friendly name and capabilities, as well as
   information about each of the services it offers.

1. A control point can search for root devices at any time by sending a
   `M-SEARCH` query to the same multicast address. The query contains the search
   target (`ST`) header specifying the service type the control point wants.
   All devices listening to the multicast address will receive the query.

1. When a root device receives a query, it checks the `ST` header against the
   list of services offered.  If there is a match it replies with a unicast
   `M-SEARCH` response to the control point that sent the query.

1. When a service is no longer available, the root device multicasts a `NOTIFY`
   message of type `ssdp:byebye` with `ST` set to the service type.  Control
   points can remove the service from any caches.

# Presentation API functionality

For the Presentation API, the requirement is the ability to "Monitor Display
Availability" by a controlling user agent as described in [6.4 Interface
PresentationAvailability](https://w3c.github.io/presentation-api/#interface-presentationavailability).

The entry point in the Presentation API to monitor display availability is the
[PresentationRequest](https://w3c.github.io/presentation-api/#interface-presentationrequest)
interface. The algorithm
[_monitoring the list of available presentation displays_](https://w3c.github.io/presentation-api/#dfn-monitor-the-list-of-available-presentation-displays)
is used in
[PresentationRequest.start()](https://w3c.github.io/presentation-api/#dom-presentationrequest-start)
and in
[PresentationRequest.getAvailability()](https://w3c.github.io/presentation-api/#dom-presentationrequest-getavailability).
Only presentation displays that can open at least one of the URLs passed as
input in the PresentationRequest constructor are considered available for that
request. There are at least three ways SSDP can be used to monitor display
availability for the Presentation API:

## Method 1

Similar to SSDP discovery in DIAL. The main steps are listed below:

1. The presentation display device advertises using SSDP the
   receiver when it is connected to the network with the service type
   `urn:openscreen-org:service:openscreenreceiver:1`.  The `ssdp:alive` message
   contains a `LOCATION` header which points to the XML device description,
   which includes the friendly name, device capabilities, and other device data.

    ```
    NOTIFY * HTTP/1.1
    HOST: 239.255.255.250:1900
    CACHE-CONTROL: max-age = 1800 [response lifetime]
    LOCATION: http://192.168.0.123:8080/desc.xml [device description URL]
    NTS: ssdp:alive
    SERVER: OS/version UPnP/1.0 product/version
    USN: XXX-XXX-XXX-XXX [UUID for device]
    NT: urn:openscreen-org:service:openscreenreceiver:1
    ```

1. The controlling user agent starts to monitor presentation display
   availability by sending an SSDP `M-SEARCH` query with the service type
   `urn:openscreen-org:service:openscreenreceiver:1` and waits for responses
   from presentation displays.  The controlling user agent should wait for
   `ssdp:alive` and `ssdp:byebye` messages on the multicast address to keep its
   list of available displays up-to-date when a new display is connected or an
   existing one is disconnected.

    ```
    M-SEARCH * HTTP/1.1
    HOST: 239.255.255.250:1900
    MAN: ssdp:discover
    MX: 2 [seconds to delay response]
    ST: urn:openscreen-org:service:openscreenreceiver:1
    ```

1. Each presentation display connected to the network running a receiver replies
   to the search request with a SSDP message similar to the `ssdp:alive`
   message.

    ```
    HTTP/1.1 200 OK
    CACHE-CONTROL: max-age = seconds until advertisement expires e.g. 2
    DATE: when response was generated
    LOCATION: http://192.168.0.123:8080/desc.xml [device description URL]
    SERVER: OS/version UPnP/1.0 product/version
    USN: XXX-XXX-XXX-XXX [UUID for device]
    ST: urn:openscreen-org:service:openscreenreceiver:1
    ```

1. When the controlling user agent receives a response from a newly connected
   presentation display, it issues an HTTP GET request to the URL in the
   `LOCATION` header to get the device description XML.

1. The controlling user agent parses the device description XML, extracts the
   friendly name of the display and checks if the display can open one of the
   URLs associated with an existing call to `PresentationRequest.start()` or
   `PresentationRequest.getAvailability()`.  If yes, the presentation display
   will be added to the list of available displays, and the result sent back to
   pages through the Presentation API.

1. When a presentation display is disconnected it should advertise a
   `ssdp:byebye` message.

    ```
    NOTIFY * HTTP/1.1
    HOST: 239.255.255.250:1900
    NT: urn:openscreen-org:service:openscreenreceiver:1
    NTS: ssdp:byebye
    USN: XXX-XXX-XXX-XXX [UUID for device]
    ```

*Open questions:*

1. How to advertise the endpoint of the Open Screen receiver? One
   solution is to use a HTTP header parameter in the response of the HTTP GET
   request for device description.  DIAL uses this solution to send the endpoint
   of the DIAL server in the `Application-URL` HTTP response header. Another
   solution is to extend the XML device description with a new element to define
   the endpoint.

1. How to check if the receiver can present a certain URL or not?  One solution
   is to extend the XML device description with new elements to allow a receiver
   to express its capabilities and the controlling user agent can do the
   check. Another possible solution is to ask the receiver using the provided
   endpoint by sending the presentation URLs.

## Method 2

This method uses only the SSDP messages without requiring the device description
XML. The presentation request URLs are sent by the controlling user agent in a
new header of the SSDP `M-SEARCH` message.  If a receiver can open one of the
URLs, it responds with that URL in the search response.

The search response also adds new headers for the device friendly name, the
service endpoint, and data on URL compatibility.  (Note that Section 1.1.3 of
the UPnP device architecture document allows to use vendor specific headers.)
This method is more efficient and secure since no additional HTTP calls and XML
parsing are required.

Below are the steps that illustrate this method:

1. A new presentation display that connects to the network advertises
   the following `ssdp:alive` message.

    ```
    NOTIFY * HTTP/1.1
    HOST: 239.255.255.250:1900
    CACHE-CONTROL: max-age = 1800 [response lifetime]
    NTS: ssdp:alive
    SERVER: OS/version product/version
    USN: XXX-XXX-XXX-XXX [UUID for device]
    NT: urn:openscreen-org:service:openscreenreceiver:1
    FRIENDLY-NAME.openscreen.org: TXkgUHJlc2VudGF0aW9uIERpc3BsYXk= [My Presentation Display]
    RECEIVER.openscreen.org: 192.168.1.100:3000
    PROTOCOLS.openscreen.org: cast,dial
    HOSTS.openscreen.org: www.youtube.com,www.netflix.com:1000
    ```

1. A controlling user agent sends the following SSDP search message to the
   multicast address.

    ```
    M-SEARCH * HTTP/1.1
    HOST: 239.255.255.250:1900
    MAN: "ssdp:discover"
    MX: seconds to delay response
    ST: urn:openscreen-org:service:openscreenreceiver:1
    ```

1. A presentation display that has a running presentation receiver responds to
   the following SSDP message.  The `openscreen.org` header fields have the same
   meanings as in the advertisement message.

    ```
    HTTP/1.1 200 OK
    CACHE-CONTROL: max-age = 1800 [response lifetime]
    DATE: [when response was generated]
    SERVER: [OS]/[version]
    USN: XXX-XXX-XXX-XXX [UUID for device]
    ST: urn:openscreen-org:service:openscreenreceiver:1
    FRIENDLY-NAME.openscreen.org: TXkgUHJlc2VudGF0aW9uIERpc3BsYXk= [My Presentation Display]
    RECEIVER.openscreen.org: 192.168.1.100:3000
    PROTOCOLS.openscreen.org: cast,dial
    HOSTS.openscreen.org: www.youtube.com,www.netflix.com:1000
    ```

1. The display sends the following SSDP message when the receiver is no
   longer available. There are no new headers added to the `ssdp:byebye` message.

    ```
    NOTIFY * HTTP/1.1
    HOST: 239.255.255.250:1900
    NT: urn:openscreen-org:service:openscreenreceiver:1
    NTS: ssdp:byebye
    USN: XXX-XXX-XXX-XXX [UUID for device]
    ```

### Custom headers

There are four Open Screen specific headers in the advertisement and response:

Header        | Mandatory? | Meaning
--------------|------------|---------
FRIENDLY-NAME |    Yes     | base64 encoded, UTF-8 friendly name of the presentation display.
RECEIVER      |    Yes     | The IP address:port of the presentation receiver service being advertised.
PROTOCOLS     |    No      | A comma-delimited list of additional URL protocols *other* than https that are compatible with the receiver.
HOSTS         |    No      | A comma-delimited list of URL hosts that are known to be compatible with the presentation display.

To ensure that the SSDP response fits into 1400 bytes, the HOSTS header may be
dropped or shortened.  (The advertisement example above is approximately 439
bytes.)

### Display Compatibility

The controlling user agent can use the information in the `HOSTS` and
`PROTOCOLS` headers to determine compatibility of some presentation URLs
without requiring a connection to the presentation display.  The algorithm
to use these headers is as follows:

```
Given `O`, the origin of a presentation URL:

IF the protocol of O is 'https', THEN
   IF the host of O matches any entry in HOSTS, THEN
     RETURN 'compatible'
   ELSE
     RETURN 'unknown'
ELSE IF the protocol of O does not match an entry in PROTOCOLS, THEN
   RETURN 'not compatible'
ELSE
   RETURN 'unknown'
```

If the algorithm returns `unknown,` a connection to the display and a query
with the full URL is required to determine compatibility.

## Method 3

This approach is identical to Method 2, except that presentation URL protocols
or hosts are not included in SSDP messages. Only the `RECEIVER.openscreen.org`
header is added to the search response, and additional information from the
receiver (including presentation URL compatibility) is obtained from the
application level protocol implemented on that endpoint.  The friendly name may
or may not be included in advertisements, based on a tradeoff between usability,
efficiency and privacy.

# Remote Playback API functionality

[Issue #3](https://github.com/webscreens/openscreenprotocol/issues/3): Add
requirements for Remote Playback API.

# Reliability

As UDP is unreliable, UPnP recommends sending SSDP messages 2 or 3 times with a
delay of few hundred milliseconds between messages.  In addition, the
presentation display must re-broadcast advertisements periodically prior to
expiration of the duration specified in the `CACHE-CONTROL` header (whose
minimum value is 1800s).

[Issue #68](https://github.com/webscreens/openscreenprotocol/issues/68): Get
reliability data.

# Latency of device discovery / device removal

New presentation displays added or removed can be immediately detected if the
controlling user agent listens to the multicast address for `ssdp:alive` and
`ssdp:byebye` messages.

For search requests, the latency depends on the `MX` SSDP header which contains
the maximum wait time in seconds (and must be between 1 and 5 seconds).  SSDP
responses from presentation displays should be delayed a random duration between
0 and `MX` to balance load for the controlling user agent when it processes responses.

Chrome sets an `MX` value of 2 seconds for its implementation of SSDP for DIAL
([code reference](https://cs.chromium.org/chromium/src/chrome/browser/media/router/discovery/dial/dial_service.cc?rcl=43fcb5eb66460fb63755f3a9383e4a6131afcc82&l=103)).

[Issue #69](https://github.com/webscreens/openscreenprotocol/issues/69): Collect
data on latency of discovery.

# Network efficiency

It depends on multiple factors like the number of devices in the network using
SSDP (includes devices that support DLNA, DIAL, HbbTV 2.0, etc.), the number of
services provided by each device, the interval to re-send refreshment messages
(value of `CACHE-CONTROL` header), the number of devices/applications sending
discovery messages.

# Power efficiency

This depends on many factors including the method chosen above; Methods 2 and 3
are better than Method 1 regarding power efficiency.  In Method 1, the
controlling user agent needs to create and send SSDP search requests, receive
and parse SSDP messages, make HTTP requests to get device descriptions and parse
device description XML to get friendly name and check capabilities.

In Methods 2 and 3, the controlling user agent needs only to create and send
search requests and receive and parse SSDP messages.

The way that controlling user agents search for presentation displays has an
impact on power efficiency. If a controlling user agent needs to immediately
react to connection and disconnection of presentation displays, it will need to
continuously receive data on the multicast address, including all SSDP messages
sent by other controlling user agents.  (An exception is unicast search response
messages sent to other controlling user agents.)

If the controlling user agent needs to get only a snapshot of available
displays, then it only needs to send a search message to the multicast address
and listen for search response messages for 2-10 seconds.

[Issue #26](https://github.com/webscreens/openscreenprotocol/issues/26): Get
network and power efficiency data.

# Ease of implementation / deployment

It is very easy to implement the SSDP protocol, as it is based soley on UDP and
the messages are easy to create and parse. Examples of open source implementations:
* [libupnp](http://pupnp.sourceforge.net/) (C Library)
* [peer-ssdp](https://github.com/fraunhoferfokus/peer-ssdp) (Node.js Library)

# IPv4 and IPv6 support

SSDP supports IPv4 and IPv6. "Appendix A: IP Version 6 Support" of the UPnP
Device architecture document describes all details about support for IPv6.

# Hardware requirements

The SSDP layer of uPnP has been implemented on a variety of consumer hardware
devices generations older than those listed in
the [Sample Device Specifications](device_specs.md).  It should be feasible to
implement it on the devices listed there.

# Standardization status

SSDP is part of the UPnP device architecture. The most recent version of the
specification is [UPnP Device Architecture
2.0](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v2.0.pdf) from
February 20, 2015.  The original specification for SSDP was as a standalone
[Internet Draft](https://tools.ietf.org/html/draft-cai-ssdp-v1-03) which expired
in April 2000.

UPnP/SSDP is used in many products like smart TVs, printers, gateways/routers,
NAS, and PCs. According to [DLNA](https://www.dlna.org/), there are over four
billion DLNA-certified devices available on the market. SSDP is also used in
non-DLNA certified devices that support DIAL and HbbTV 2.0, including smart TVs
and digital media receivers, as well as proprietary products like
[SONOS](http://musicpartners.sonos.com/?q=docs) and [Philips
Hue](https://www.developers.meethue.com/).

On January 1, 2016, the UPnP Forum assigned their assets to the [Open
Connectivity Foundation
(OCF)](https://openconnectivity.org/resources/specifications/upnp).  The OCF
requires [membership and
licensing](https://openconnectivity.org/certification/upnp-certification) to
access the uPnP test suite and obtain uPnP certification for a specific device.
Since Open Screen is explicitly *not* a uPnP defined service, OCF membership
should not be required for Open Screen implementers.

# Privacy

The standard UPnP device description exposes parameters about the
device/service, such as its unique identifier, friendly name, software,
manufacturer, and service endpoints. In addition, the SSDP vendor extensions
proposed in Method 2 advertise presentation URLs and friendly names to all
devices on the local area network, which may expose private information in an
unintended way.

# Security

SSDP considers local network as secure environment; any device on the local area
network can discover other devices or services.  Authentication and data privacy
must be implemented on the service or application level. In our case, the output
of discovery is a list of displays and friendly names, which are available to
all devices on the local area network.  If Method 2 is adopted, presentation
URLs and endpoints of receivers are also broadcast.  Additional security
mechanisms can be implemented during session establishment and communication.

## Security History

Unfortunately there is a long history of exploits related to inappropriate
exposure of uPnP services to the WAN and poor input handling.  The January 2013
paper by security firm Rapid7, [Unplug, Don't
Play](https://drive.google.com/open?id=0B0RlZr4vrjIKbV9FVk0yTGg5dFE) discusses
the exent of these problems.

Here is a sampling of other papers detailing security issues with uPnp/SSDP:

* [Vulnerability Note VU#357851](http://www.kb.cert.org/vuls/id/357851): UPnP requests accepted over router WAN interfaces - 30 Nov 2012
* [Millions of devices vulnerable via UPnP - Update](http://www.h-online.com/security/news/item/Millions-of-devices-vulnerable-via-UPnP-Update-1794032.html) - 30 January 2013
* [DEFCON 19 presentation](https://www.defcon.org/images/defcon-19/dc-19-presentations/Garcia/DEFCON-19-Garcia-UPnP-Mapping.pdf) about exploit - 11 September 2014

Publicly accessible uPnP devices are leveraged by malicious parties to implement
distributed denial of service attacks through SSDP amplification.  See [this
article](https://blog.cloudflare.com/ssdp-100gbps/) for a detailed explanation
of how this is done.

## Other Exploits

The CVE database currently lists
[58 vulnerability disclosures](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=UPNP)
related to uPnP in general.  Of these,
[17 vulnerability disclosures](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=SSDP)
are related specifically to improper handling of SSDP requests or responses.
These can be used to issue denial of service attacks (crashing the device) or
achieve remote code execution.

## Mitigations

Any implementation of SSDP should be code audited for security vulnerabilities,
and undergo
[fuzz testing](https://blog.chromium.org/2012/04/fuzzing-for-security.html)
to evaluate input handling.  These implementations should have careful handling
of UDP sockets to prevent WAN exposure.

Open Screen Protocol implementations of SSDP must be designed to block
amplification attacks, even in the case of firewalls that leave port 1900 open.
Specifically:

* They MUST ignore any unicast `M-SEARCH` request, that does not arrive via the
  IPv4 or IPv6 multicast address.
* They MUST ignore any `M-SEARCH` request whose source IP is not part of the
  Open Screen receiver's subnet.
* `M-SEARCH` responses MUST only be sent to IP addresses that are part of the
  Open Screen receiver's subnet.
* They MUST ignore any `M-SEARCH` request with a `ST` other than the specific
  target for Open Screen.
  * Specifically, any request for a `ST` of `ssdp:all` MUST be ignored.
* Open Screen Receivers SHOULD ignore `M-SEARCH` requests from IP addresses that
  are not [RFC1918](https://tools.ietf.org/html/rfc1918) or
  [RFC4193](https://tools.ietf.org/html/rfc4193.html) private addresses.
  Responses SHOULD be sent only to these addresses.
    * This restriction SHOULD be end user configurable, as some LANs re-use the
      public IP address space.

# Notes

* The identifiers `urn:openscreen-org:service:openscreenreceiver:1` and
  `openscreen.org` are used for illustrative purposes and may not be the
  eventual identifiers assigned for Open Screen presentation services.
