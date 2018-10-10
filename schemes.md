# Schemes and Open Screen Protocol

This document discusses the usage of schemes as a mechanism to make Open Screen
Protocol (OSP) extensible and to support any kind of application in the future
without the need for agreement between the vendor of controlling user agent
(controlling UA) and the vendor of receiving user agent (presentation screen),
but only relying on the OSP.

The Presentation API allows a controller page to launch a presentation page on a
display using the `PresentationRequest` interface. The `PresentationRequest`
constructor accepts a URL or a sequence of URLs of the presentation page as
input. While the current Presentation API spec defines the behavior of `http` or
`https` schemes, it does not forbid the usage of other schemes. For example the
`cast` scheme is used in the Presentation API tests as alternative scheme to
support Google Cast receivers like Chromecast and Android TV. Let us consider
the following example as input for discussion:

```javascript
var urls = [
     "hbbtv:?appId=123&orgId=456&appName=myHbbTVApp&appUrl=" +
         encodeURIComponent("https://example.com/hbbtv.html"),
     "https://example.com/presentation.html",
     "cast:1234567"
];
var request = new PresentationRequest(urls);
```

This example provides three URLs with different schemes: `hbbtv`, `https` and
`cast`. The controlling UA that implements the OSP can use these schemes to
filter presentation screens during discovery (regardless of which discovery
protocol is used or how filtering is implemented). 

In order for a user to launch a presentation with a custom URL scheme, they must
have a presentation screen available that responds postively to screen
availability requests for URLs with that scheme.

If a single presentation screen supports more than one URL in a single
`PresentationRequest,` the order of URLs is used by the controlling UA to decide
which URL will be launched on that screen.  This possibility is shown in the
diagram below.  If `Receiver Device 1` advertises itself as a single
presentation screen, and the user chooses it as the target for `request`, then
the controlling UA will launch the `hbbtv:` URL on it.

![](images/schemes.png)

If the controlling page needs the user to choose which URL to present, it can
create a separate `PresentationRequest` object for each URL.  This is not
recommended, as the user should generally not care about the details of the
connection technology being used by the presentation screen.

Alternatively, the presentation screen can advertise itself as multiple Open
Screen Protocol endpoints, each of which advertises availability for a different
scheme.  In the case above, the user would see two distinct presentation screens
in its screen list, "Receiver Device 1 (HBBTv)" and "Receiver Device 1 (Cast)".
Again, this is not recommended as the user should not care about the connection
technology used by a given screen.

## Extensibility

The mechanism of using schemes in the OSP allows to extend the supported
application types on receiver devices. For example Android TV can implement the
OSP (receiver part) for native TV applications in the future e.g. using the
scheme `android` (the TV App uses in this case a native library that implements
the OSP with similar interface to Presentation API). There is no need to
update/extend the controlling UA to support new schemes, but it is up to the
vendor of controlling UA to white/blacklist specific URL schemes.

*TODO:* [Issue #93: Custom schemes and interop](https://github.com/webscreens/openscreenprotocol/issues/93)

## Scheme based filtering

As discussed before, schemes can be used as a mechanism to filter devices during
discovery. Two possible options:

1. The controlling UA sends the list requested schemes in the discovery request
   and receivers that support at least one scheme from the requested list should
   reply. Furthermore, discovery response of the receiver should include a
   sublist of supported schemes.
2. The controller UA don't send any scheme in the discovery request. The
   presentation screen should reply to any discovery request with a list of all
   supported schemes. The controlling UA matches the list of requested schemes
   with the list of supported schemes from each receiver to decide which device
   to consider.

## HbbTV scheme

The example above shows the usage of `hbbtv` scheme. Basically, all required
parameters to address an HbbTV application on the terminal can be serialized as
URL query parameters. The HbbTV URL in the example above contains the parameters
`appId` (application ID) , `orgId` (organization ID), `appName` (application
name) and `appUrl` (application URL), but other parameters can be supported in
the same way. A receiver that advertises itself (e.g. `Receiver Device 1`
depicted in the figure above) as a HbbTV terminal should use the scheme `hbbtv`
during discovery.

*TODO:* [Issue #94: Semantics of hbbtv: URLs](https://github.com/webscreens/openscreenprotocol/issues/94)

