## Open Screen Protocol

This repository is used to develop
the [Open Screen Application Protocol](https://www.w3.org/TR/openscreen-application/)
and [Open Screen Network Protocol](https://www.w3.org/TR/openscreen-network/), a suite of
network protocols that allow user agents to implement the [Presentation
API](https://www.w3.org/TR/presentation-api/) and [Remote Playback
API](https://www.w3.org/TR/remote-playback/) in an interoperable fashion.

The [explainer](explainer.md) goes into more depth regarding the motivation, and
rationale, and design choices for the protocol.

This work is in scope for the [W3C Second Screen Working
Group](https://www.w3.org/2014/secondscreen/)
([Charter](https://www.w3.org/2024/05/charter-secondscreen-wg.html)).

Please refer to the group's [Work
Mode](https://www.w3.org/wiki/Second_Screen/Work_Mode) for instructions on how
to contribute.

The protocol will meet the [functional and non-functional
requirements](requirements.md) of the respective APIs as well as [hardware
requirements](device_specs.md) for prospective implementations.

### Status

The protocol is considered to be complete for the requirements above.  It will
be published as a First Public Working Draft in mid-March 2021.  The remaining
issues on the draft are tagged
[_v1-spec_](https://github.com/w3c/openscreenprotocol/labels/v1-spec) in GitHub
and noted [inline in the
spec](https://w3c.github.io/openscreenprotocol/#issues-index).

### Related technologies

The Open Screen Protocol is built on the following standardized technologies:

- [mDNS](https://tools.ietf.org/html/rfc6762)/[DNS-SD](https://tools.ietf.org/html/rfc6763)
  to allow networked devices that support OSP (Open Screen agents) to discover
  each other;
- [TLS 1.3](https://tools.ietf.org/html/rfc8446) and a Password-Authenticated
  Key Exchange
  ([PAKE](https://datatracker.ietf.org/doc/draft-irtf-cfrg-spake2/)) to create a
  secure channel between agents;
- [QUIC](https://datatracker.ietf.org/doc/draft-ietf-quic-transport/) to
  transport data and media between agents;
- [CBOR](https://tools.ietf.org/html/rfc8949) to encode structured data and
  media on-the-wire.

### Background Information

The excellent [Discovery and Pairing Literature
Review](https://github.com/bbc/device-discovery-pairing/blob/master/document.md)
by [@chrisn](https://github.com/chrisn) and
[@libbymiller](https://github.com/libbymiller) covers a wide range of existing
technologies for ad-hoc interconnection among networked devices, including
mDNS/DNS-SD and SSDP.
