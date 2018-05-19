# Schemes

This document discusses the usage of schemes as a mechanism to make Open Screen Protocol (OSP) extensible and to support any kind of application in the future without the need for agreement between the vendor of controlling UA and the vendor of receiving UA, but only relying on the OSP. 

The Presentation API allows a controller page to launch a presentation page on a display using the `PresentationRequest` interface. The `PresentationRequest` constructor accepts a url or a sequence of urls of the presentation page as input. While the current Presentation API spec defines the behavior of `http` or `https` schemes, it does not forbid the usage of other schemes. For example the `cast` scheme is used in the Presentation API tests as alternative scheme to support Google Cast receivers like Chromecast and Android TV. Let us consider the following example as input for discussion:

```javascript
var urls = [
     "hbbtv:?appId=123&orgId=456&appName=myHbbTVApp&appUrl="+encodeURIComponent("https://example.com/hbbtv.html"),
     "https://example.com/presentation.html",
     "cast:1234567"
];
var request = new PresentationRequest(urls);
```

This example provides three urls with different schemes: `hbbtv`, `https` and `cast`. The controlling UA that implements the OSP should use these schemes as filter during discovery (regardless of which discovery protocol is used how filtering is implemented). Furthermore, the order of the urls in the array can be used to decide which url will be launched. 

![](images/schemes.png)

*Open Questions:*

* If a Chromecast and an HbbTV terminals are found, which option should be considered: a) The UA shows both devices in the selection dialog and after the user chooses a device, the corresponding presentation url will be selected or b) the UA shows only the HbbTV terminal in the selection dialog since it has a higher priority (order in the list).
* If option a) in previous question is considered, how to deal with devices that support both schemes `hbbtv` and `cast` for example Android TV devices? 

## Extensibility

The mechanism of using schemes in the OSP allows to extend the supported application types on receiver devices. For example Android TV can implement the OSP (receiver part) for native TV applications in the future e.g. using the scheme `android` (the TV App uses in this case a native library that implements the OSP with similar interface to Presentation API). There is no need to update/extend the controlling UA to support new schemes.



