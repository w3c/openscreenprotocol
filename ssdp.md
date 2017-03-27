# SSDP

SSDP (Simple Service Discovery Protocol) is the first layer in the [UPnP (Universal Plug and Play) Device Architecture](http://www.upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf). It allows control points (term used in UPnP architecture for control devices like smartphones or tablets) to search for devices or services of interest on the network. The SSDP protocol is also used in other standards/specifications without using the whole UPnP stack. 

One example is the [DIAL (Discovery and Launch)](http://www.dial-multiscreen.org/) which is a protocol that allows second-screen devices like smartphones or tablets to discover and launch applications on first-screen devices like TVs. 

Another example is [HbbTV 2.0 (Hybrid broadcast broadband TV)](https://www.hbbtv.org/wp-content/uploads/2015/07/HbbTV-SPEC20-00023-001-HbbTV_2.0.1_specification_for_publication_clean.pdf) which uses DIAL as underlying protocol to discover HbbTV devices and launch HbbTV applications. 

In [Physical Web Project](https://github.com/google/physical-web) there is a [proposal](https://github.com/google/physical-web/blob/master/documentation/ssdp_support.md) from [Fraunhofer FOKUS](https://www.fokus.fraunhofer.de/fame) on how to use the SSDP protocol to advertise and find URLs in local network.


## Design and Specification

SSDP allows root devices (term used in UPnP architecture for devices that offer services like TVs, printers, etc.) to advertise their services to control points on the network. It also allows control points to search for devices or services of interest at any time. SSDP specifies the discovery messages that are exchanged between control points and root devices. 

SSDP messages contain specific information about the service/device like type, unique device identifier, etc. SSDP uses part of the header field format of HTTP 1.1 ,but it is not based on full HTTP 1.1 as it uses UDP instead of TCP and it has its own processing rules. 

The following sequence diagram shows the SSDP message exchange between a control point and root device.

![](images/ssdp.png) 

Message Flow:
1. the root device advertises its services on the network by sending for each service it offers a "NOTIFY" message from type "ssdp:alive" to the multicast address "239.255.255.250:1900" with all the necessary information needed to access the service. Control points listening on the multicast address receive the message and check if the service is relevant for them or not. The NT header can be used to check the type of the service. To access more information about the service/device the control point needs to access the device description (format is specified in UPnP) by making an HTTP request to the URL provided in the LOCATION header of the SSDP message. The device description is a XML document that contains information about the device/service like friendly name, capabilities, etc.
1. a control point can search for root devices at any time by sending a SEARCH message to the multicast address. The search request contains the ST (search target) header specify the type of the service the control point is looking for. All devices listing to the multicast address will receive the search message.
1. when a root device receives a search message and if it offers the requested service (by checking the ST header), it replies with a SEARCH response message only to the control point that sends the request (unicast).
1. when a service is no more available, the root device needs to advertise a "NOTIFY" message from type "ssdp:byebye" with information about the corresponding service. Control points can remove the service if it is listed. 

## Evaluation

This section evaluates SSDP as discovery protocol for the Open Screen Protocol according several functional and non-functional requirements

### Functional Requirements

We will consider the functional requirements of the Presentation API (and later also Remote Playback API). The functional requirement related to discovery is the ability to "Monitor Display Availability" which is described in section [6.4 Interface PresentationAvailability](https://w3c.github.io/presentation-api/#interface-presentationavailability) of the Presentation API specification. 

#### Presentation API: Monitor Display Availability

The entry point in the Presentation API to monitor display availability is the [PresentationRequest](https://w3c.github.io/presentation-api/#interface-presentationrequest) interface. The algorithm [Monitoring the list of available presentation displays](https://w3c.github.io/presentation-api/#dfn-monitor-the-list-of-available-presentation-displays) is used in [PresentationRequest.start()](https://w3c.github.io/presentation-api/#dom-presentationrequest-start) an in [PresentationRequest.getAvailability()] (https://w3c.github.io/presentation-api/#dom-presentationrequest-getavailability) methods. Only presentation displays that can open at least one of the URLs passed as input in the PresentationRequest constructor should be considered. There are two methods how SSDP can be used to monitor display availability in Presentation API:

**Method 1**: It is similar to of SSDP as discovery in DIAL. The main steps are listed below:

* The display advertises the presentation receiver service when it is added on the network using SSDP and the service type `urn:example-org:service:osp:1` (this is just an example). The SSDP alive message contains a LOCATION header which points to the XML device description (contains friendly name, device capabilities, etc.). 

    ```
    NOTIFY * HTTP/1.1
    HOST: 239.255.255.250:1900
    CACHE-CONTROL: max-age = seconds until advertisement expires e.g. 1800
    LOCATION: URL of the device description e.g. http://192.168.0.123:8080/desc.xml
    NTS: ssdp:alive
    SERVER: OS/version UPnP/1.0 product/version
    USN: advertisement UUID
    NT: urn:example-org:service:osp:1
    ```
* The controller starts "Monitor Display Availability" algorithm by sending a SSDP search message with the service type `urn:example-org:service:osp:1` and waits for responses from devices running a presentation receiver service. The controller should wait for SSDP alive/byebye messages on the multicast address to keep the list of available displays up-to-date (e.g. when a new display in added or an existing one is removed).

    ```
    M-SEARCH * HTTP/1.1
    HOST: 239.255.255.250:1900
    MAN: "ssdp:discover"
    MX: seconds to delay response e.g. 2
    ST: urn:example-org:service:osp:1
    ```
* Each display available on the network and runs a presentation receiver service replies to the search request with a SSDP message similar to the alive message.

    ```
    HTTP/1.1 200 OK
    CACHE-CONTROL: max-age = seconds until advertisement expires e.g. 2
    DATE: when response was generated
    LOCATION: URL of the device description e.g. http://192.168.0.123:8080/desc.xml
    SERVER: OS/version UPnP/1.0 product/version
    USN: advertisement UUID
    ST: urn:example-org:service:osp:1
    ```
* The controller reads the LOCATION header for each available display and makes a HTTP GET request to get the device description XML.
* The controller parses each device description XML, reads the friendly Name of the display and checks if the display can open one of the URLs passed as input to the PresentationRequest constuctor. If yes, the device will be added to the list of available displays.
* The display should advertise a SSDP byebye message before it is not more available.

    ```
    NOTIFY * HTTP/1.1
    HOST: 239.255.255.250:1900
    NT: urn:example-org:service:osp:1
    NTS: ssdp:byebye
    USN: advertisement UUID
    ```
* Open questions:
    * How to send the endpoint of the receiver service: one solution is to use a HTTP header parameter in the response of the HTTP GET request for device description. DIAL uses this solution to send the endpoint of the DIAL server in the `Application-URL` HTTP response header. Another solution is to extend the XML device description with a new element to define the endpoint.
    * How to check if the display can open a certain URL or not. One solution is to extend the XML device description with new elements to allow a display to express its capabilities and the controller can do the check. Another possible solution is to ask the receiver service using the provided endpoint by sending the presentation URLs. 

**Method 2**: This method uses only the SSDP messages without requesting the device description XML. Idea is to send the presentation URLs in a new header of the SSDP search message. Only receivers that can open at least one of the URLs response to the search request. The search response contains also a new header for device friendly name and another header for service endpoint (section 1.1.3 of the UPnP device architecture document allows to use vendor specific headers). The search response can still send the device description URL in the Location header to stay compatible with UPnP but controller devices don’t need to use it since all necessary information are send directly in the SSDP search response. This method is more efficient since no additional HTTP calls and XML parsing is needed. Below are the steps that illustrate the idea of this method:

* New display with presentation receiver service that appears on the network advertises the following SSDP alive message. The new header `FRIENDLY-NAME.example.org` is used for friendly name and `PRESENTATION-ENDPOINT.example.org` for endpoint of the receiver service. The value `urn:example-org:service:osp:1` of header `NT` is used for presentation receiver service.

    ```
    NOTIFY * HTTP/1.1
    HOST: 239.255.255.250:1900
    CACHE-CONTROL: max-age = seconds until advertisement expires
    LOCATION: URL of the device description
    NTS: ssdp:alive
    SERVER: OS/version UPnP/1.0 product/version
    USN: advertisement UUID
    NT: urn:example-org:service:osp:1
    FRIENDLY-NAME.example.org: My Presentation Display
    PRESENTATION-ENDPOINT.example.org: 192.168.1.100:3000
    ```

* A controller sends the following SSDP search message to the multicast address. The new header `PRESENTATION-URLS.example.org` allows the controller to send the presentation URLs to the display. 

    ```
    M-SEARCH * HTTP/1.1
    HOST: 239.255.255.250:1900
    MAN: "ssdp:discover"
    MX: seconds to delay response
    ST: urn:example-org:service:osp:1
    PRESENTATION-URLS.example.org: http://example.com/foo.html, http://example.com/bar.html
    ```
* A display that can open one of the URLs replies (unicast) with the following SSDP message. The new SSDP header `SUPPORTED-URLS.example.org` contains the URLs the receiver can open from the list of the URLs `PRESENTATION-URLS.example.org` sent in the search SSDP message.

    ```
    HTTP/1.1 200 OK
    CACHE-CONTROL: max-age = seconds until advertisement expires
    DATE: when response was generated
    LOCATION: URL of the device description
    SERVER: OS/version UPnP/1.0 product/version
    USN: advertisement UUID
    ST: urn:example-org:service:osp:1
    FRIENDLY-NAME.example.org: My Presentation Display
    PRESENTATION-ENDPOINT.example.org: 192.168.1.100:3000
    SUPPORTED-URLS.example.org: http://example.com/foo.html
    ```
* The display sends the following SSDP message when the receiver service in not more available. There are no new headers used in the byebye message.

    ```
    NOTIFY * HTTP/1.1
    HOST: 239.255.255.250:1900
    NT: urn:example-org:service:osp:1
    NTS: ssdp:byebye
    USN: advertisement UUID
    ```

#### Remote Playback API: Monitor Display Availability
TODO (it should be very similar to the Presentation API display availability but for capabilities other parameters related media formats, codecs, encryptions need to be considered)

### Non-functional Requirements

#### Reliability

UPnP recommend due to the unreliable nature of UDP to send the SSDP messages more than once (and max three times to avoid network congestion) with some delay of few hundred milliseconds. In addition, the device must re-send its advertisements periodically prior to expiration of the duration specified in
the `CACHE-CONTROL` header (minimum value is 1800s).  

#### Latency of device discovery / device removal

New devices added or removed can be immediately detected if the controller listens to the multicast address for "ssdp:alive" and "ssdp:byebye" messages. For search requests the latency depends on the `MX` SSDP header which contains the maximum wait time in seconds. According to UPnP specification, it must be greater than or equal to 1 and should be less than 5 inclusive. SSDP responses should be delayed a random duration between 0 and the value of `MX` to balance load for the controller when it processes responses.

#### Ease of implementation / deployment

It is very easy to implement the SSDP protocol. It is based on UDP and the messages are easy to create and parse. [peer-ssdp](https://github.com/fraunhoferfokus/peer-ssdp) is a open source implementation for Node.js by Fraunhofer FOKUS and shows how easy to implement the protocol. Another implementation by Fraunhofer FOKUS for Android (part of a [cordova plugin](https://github.com/fraunhoferfokus/cordova-plugin-hbbtv/tree/master/src/android/ssdp)) is also available. 

#### Security - both of the implementation, and whether it can be leveraged to enhance security of the entire protocol

SSDP consider local network as secure environment. Any device on the network can discover other devices or services. Security can be implemented on service level. In our case the output of the discovery is a list of displays that contain friendly names and endpoints of presentation receiver services. Any security mechanism can be implemented during session establishment and communication independent from the method used for discovery. 

#### Privacy: what device information is exposed

The standard UPnP device description exposes parameters about the device/service like unique identifier, friendly name, software, manufacturer, service endpoints, etc.

#### Network efficiency

It depends on multiple factors like the number of devices in the network using SSDP (includes devices that support DLNA, DIAL, HbbTV 2.0, etc.), the number of services provided by each device, the interval to re-send refreshment messages (value of `CACHE-CONTROL` header), the number of devices/applications sending discovery messages.

#### Power efficiency

This depends on many factors like the used method (see section [Presentation API: Monitor Display Availability](#presentation-api-monitor-display-availability)), number of devices in the Network using UPnP/DIAL and the way how to monitor the display availability.

* regarding the used method, "Method 2" is better than "Method 1" regarding power efficiency. In Method 1 the controller needs to create and send SSDP search requests, receive and parse SSDP messages, make HTTP requests to get device descriptions and parse device description XML to get friendly name and check capabilities. In method 2 the controller needs only to create and send search requests and receive and parse SSDP messages. 
* The way how controllers search for presentation displays has an impact on power efficiency. If a controller needs to immediately react to appearance/disappearance of presentation displays, it needs to listen to the multicast address. This means the controller will receive and need to parse all kind of SSDP messages even search requests sent by other controllers. One exception are unicast search response messages sent to other controllers. If the controller needs to get only a snapshot of available displays, then it only needs to send a search message to the multicast address and listen only to search response messages.

#### IPv4 and IPv6 support

SSDP supports IPv4 and IPv6. "Appendix A: IP Version 6 Support" of the UPnP Device architecture document describes all details about usage of IPv6.

#### Standardization status and likelihood of successful interop

SSDP is part of the UPnP device architecture. Last version of the specification is [UPnP Device Architecture 2.0](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v2.0.pdf) from February 20, 2015. UPnP Forum assigned their assets to the [Open Connectivity Foundation (OCF)](https://openconnectivity.org/resources/specifications/upnp) since January 1, 2016. UPnP/SSDP is used in many products like Smart TVs, printers, Gateways/Routers, NAS, PCs, etc. According to [DLNA](https://www.dlna.org/), there are over four billion certified devices available on the market. There are also non-DLNA certified devices that use UPnP/SSDP like Smart TVs and digital media receivers that support DIAL and HbbTV 2.0 and other products like [SONOS](http://musicpartners.sonos.com/?q=docs), [Philips Hue](https://www.developers.meethue.com/) and many others.