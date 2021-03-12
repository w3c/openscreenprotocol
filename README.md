## Open Screen Protocol

This repository is used to incubate and develop the
[Open Screen Protocol](https://w3c.github.io/openscreenprotocol/),
which is a suite of network protocols that allow user agents to
implement the [Presentation API](https://w3c.github.io/presentation-api/)
and [Remote Playback API](https://w3c.github.io/remote-playback/)
in an interoperable fashion.

This work is in scope for the
[W3C Second Screen Working Group](https://www.w3.org/2014/secondscreen/)
([Charter](https://www.w3.org/2014/secondscreen/charter-2020.html)).

Please refer to the group's [Work Mode](https://www.w3.org/wiki/Second_Screen/Work_Mode)
for instructions on how to contribute.

The protocol will meet the
[functional and non-functional requirements](requirements.md) of the
respective APIs as well as [hardware requirements](device_specs.md)
for prospective implementations.

### Submitted Proposals

The group is currently evaluating proposals to implement different
aspects of the Open Screen Protocol.  The following proposals have been
submitted:

- Discovery
  - [SSDP](archive/ssdp.md)
  - [mDNS / DNS-SD](archive/mdns.md)
- Transport
  - [QUIC](archive/quic.md)
  - [WebRTC Data Channel](archive/datachannel.md)
- [Control Protocol](archive/control_protocol.md)
- Authentication
  ([Issue #13](https://github.com/w3c/openscreenprotocol/issues/13))

### Background Information

The excellent
[Discovery and Pairing Literature Review](https://github.com/bbc/device-discovery-pairing/blob/master/document.md)
by [@chrisn](https://github.com/chrisn) and [@libbymiller](https://github.com/libbymiller) covers a wide range of technologies for interconnection among personal devices, including mDNS/DNS-SD and SSDP.
