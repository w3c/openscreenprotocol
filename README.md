## Open Screen Protocol

This repository is used to incubate and develop specifications of network
protocols that implement the
[Presentation API](https://w3c.github.io/presentation-api/) and
[Remote Playback API](https://w3c.github.io/remote-playback/).

This work is in scope for the
[W3C Second Screen Community Group](https://www.w3.org/community/webscreens/)
([Charter](https://webscreens.github.io/cg-charter/)).

The protocol will meet the
[functional and non-functional requirements](requirements.md) of the
respective APIs as well as [hardware requirements](device_specs.md)
for prospective implementations.

### Submitted Proposals

The community group is currently evaluating proposals to implement different
aspects of the Open Screen Protocol.  The following proposals have been
submitted:

- Discovery
  - [SSDP](ssdp.md)
  - [mDNS / DNS-SD](mdns.md)
- Transport
  - [QUIC](quic.md)
  - [WebRTC Data Channel](datachannel.md)
- [Control Protocol](control_protocol.md)
- Authentication ([Issue #13](https://github.com/webscreens/openscreenprotocol/issues/13))

### Background Information

The excellent
[Discovery and Pairing Literature Review](https://github.com/bbc/device-discovery-pairing)
by [@chrisn](https://github.com/chrisn) and [@libbymiller](https://github.com/libbymiller) covers a wide range of technologies for interconnection among personal devices, including mDNS/DNS-SD and SSDP.
