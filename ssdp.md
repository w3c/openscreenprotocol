# SSDP

SSDP (Simple Service Discovery Protocol) is the first layer in the [UPnP (Universal Plug and Play) Device Architecture](http://www.upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf). It allows control points (term used in UPnP architecture for control devices like smartphones or tablets) to search for devices or services of interest on the network. The SSDP protocol is also used in other standards/specifications without using the whole UPnP stack. One example is the [DIAL (Discovery and Launch)](http://www.dial-multiscreen.org/) which is a protocol that allows second-screen devices like smartphones or tablets to discover and launch applications on first-screen devices like TVs. Another example is [HbbTV 2.0 (Hybrid broadcast broadband TV)](https://www.hbbtv.org/wp-content/uploads/2015/07/HbbTV-SPEC20-00023-001-HbbTV_2.0.1_specification_for_publication_clean.pdf) which uses DIAL as underlying protocol to discover HbbTV devices and launch HbbTV applications. In [Physical Web Project](https://github.com/google/physical-web) there is a [proposal](https://github.com/google/physical-web/blob/master/documentation/ssdp_support.md) from [Fraunhofer FOKUS](https://www.fokus.fraunhofer.de/fame) on how to use the SSDP protocol to advertise and find URLs in local network.


# Design and Specification

SSDP allows root devices (term used in UPnP architecture for devices that offer services like TVs, printers, etc.) to advertise their services to control points on the network. It also allows control points to search for devices or services of interest at any time. SSDP specifies the discovery messages that are exchanged between control points and root devices. SSDP messages contain specific information about the service/device like type, unique device identifier, etc. SSDP uses part of the header field format of HTTP 1.1 ,but it is not based on full HTTP 1.1 as it uses UDP instead of TCP and it has its own processing rules. The following sequence diagram shows the SSDP message exchange between a control point and root device.

![](images/ssdp.png) 

Message Flow:
1. the root device adverties its services on the network by sending for each service it offers a "NOTIFY" message from type "ssdp:alive" to the multicast address "239.255.255.250:1900" with all the necessary information needed to access the service. Control points listening on the multicast address receive the message and check if the service is relevent for them or not. The NT header can be used to check the type of the service. To access more information about the service/device the control point needs to access the device description (format is specified in UPnP) by making an HTTP request to the URL provided in the LOCATION header of the SSDP message. The device description is a XML document that contains information about the device/service like friendly name, capabilities, etc.
1. a control point can search for root devices at any time by sending a SEARCH message to the multicast address. The search request contains the ST (search target) header specify the type of the service the control point is looking for. All devices listing to the multicast address will receice the search message.
1. when a root device receives a search message and if it offers the requested service (by checking the ST header), it replies with a SEARCH response message only to the control point that sends the request (unicast).
1. when a service is no more available, the root device needs to advertise a "NOTIFY" message from type "ssdp:byebye" with information about the correponding service. Control points can remove the service if it is listed. 

# Evaluation

this section evaluates SSDP as discovery protocol for the OpenScreenProtocol according several functional and non-functional requirements

## Functional Requirements

We will consider the functional requirements of the Prensentation API (and later also RemotePlayback API). The functional requirement related to discovery is the ability to "Monitor Display Availability" which is described in section [6.4 Interface PresentationAvailability](https://w3c.github.io/presentation-api/#interface-presentationavailability) of the Presentation API specification. 

### Presentation API: Monitor Display Availability

The entry point in the Presentation API to monitor display availability is the [PresentationRequest](https://w3c.github.io/presentation-api/#interface-presentationrequest) interface. The algorithm [Monitoring the list of available presentation displays](https://w3c.github.io/presentation-api/#dfn-monitor-the-list-of-available-presentation-displays) is used in [PresentationRequest.start()](https://w3c.github.io/presentation-api/#dom-presentationrequest-start) an in [PresentationRequest.getAvailability()] (https://w3c.github.io/presentation-api/#dom-presentationrequest-getavailability) methods. Only presentation displays that can open at least one of the URLs passed as input in the PresentationRequest constructor should be considered. There are two methods how SSDP can be used to monitor display availability in Presentation API:

Method 1: It is similar to of SSDP as discovery in DIAL. The main steps are listed below:

* The display advertises the presentation receiver service when it is added on the network using SSDP and the service type `urn:example-org:service:osp:1` (this is just an example). The SSDP alive message contains a LOCATION header which points to the XML device description (contains friendly name, device capabilites, etc.). The display should adertise a SSDP byebye message before it is not more available. 
* The controller starts "Monitor Display Availability" algorithm by sending a SSDP search message with the service type `urn:example-org:service:osp:1` and waits for responses from devices running a presentation receiver service. The controller should wait for SSDP alive/byebye messages on the multicast address to keep the list of available displays up-to-date (e.g. when a new display in added or an exiting one is removed).  
* Each display available on the network and runs a presentation receiver service replies to the search request with a SSDP message similar to the alive message.
* The controller reads the LOCATION header for each available display and makes a HTTP GET request to get the device description XML. 
* The controller parses each device dedscription XML, reads the friendlyName of the display and checks if the display can open one of the URLs passed as input to the PresentationRequest constuctor. If yes, the device will be added to the list of available displays.
* Open questions:
    * how to send the endpoint of the receiver service: one solution is to use a HTTP header parameter in the the response of the HTTP GET request for device description. DIAL uses this solution to send the endpoint of the DIAL server in the `Application-URL` HTTP response header. Another solution is to extend the XML device description with a new element to define the endpoint.
    * How to check if the display can open a certain URL or not. One solution is to extend the XML device description with new elements to allow a display to express its capabilites and the controller can do the check. Another possible solution is to ask the receiver service using the provided endpoint by sending the presenation URLs. 

Method 2: This method uses only the SSDP messages without requesting the device description XML. Idea is to send the presentation URLs in a new header of the SSDP search message. Only receivers that can open at least one of the URLs response to the search request. The search response contains also a new header for device friendly name and another header for service endpoint (section 1.1.3 of the UPnP device architecture document allows to use vendor specific headers). The search response can still send the device desctiption URL in the Location header to stay comaptible with UPnP but controller devices dont need to use it since all necessary information are send directly in the SSDP search response. This method is more efficient since no additional HTTP calls and XML parsing is needed. Below are the steps that illustrate the idea of this method:

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

* A controller sends the following SSDP search message to the multicast address. The new header `PRESENTATION-URLS.example.org` allows the controller to send the presentation URLs to allow the  display. 

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
* The display sends the follwing SSDP message when the receiver service in not more available. There are no new headers used in the byebye message.

    ```
    NOTIFY * HTTP/1.1
    HOST: 239.255.255.250:1900
    NT: urn:example-org:service:osp:1
    NTS: ssdp:byebye
    USN: uuid:advertisement UUID
    ```

### Remote Playback API: Monitor Display Availability
TODO (it should be very similar to the Presentation API display availability but for capabilities other parameters related media formats, codecs, encryptions need to be considered)

## Non-functional Requirements

### Reliability

### Latency of device discovery / device removal

### Ease of implementation / deployment

### Security - both of the implementation, and whether it can be leveraged to enhance security of the entire protocol

### Privacy: what device information is exposed

### Network efficiency

### Power efficiency

### IPv4 and IPv6 support

### Standardization status and likelihood of successful interop
