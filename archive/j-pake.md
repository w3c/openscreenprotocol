# J-PAKE: Password-Authenticated Key Exchange by Juggling

Password-Authenticated Key Exchange by Juggling (J-PAKE) is a protocol that
allows secure key exchange channel between two remote parties over an
insecure network solely based on a shared password.

J-PAKE is standardized by IETF in
[[RFC8236](https://datatracker.ietf.org/doc/rfc8236/)], which defines two
variants of J-PAKE protocol: J-PAKE over Finite Field and J-PAKE over
Elliptic Curve. Their relationship is very similar to the relationship
between DH and ECDH.

Note that elliptic curve is generally recommended since
elliptic curve cryptography requires much shorter key length than finite field cryptography
to achieve the same level of cryptographic strength. For details, see
[ECDSA: The digital signature algorithm of a better internet](https://blog.cloudflare.com/ecdsa-the-digital-signature-algorithm-of-a-better-internet/).

## Protocol Overview

In this document Alice and Bob denote the prover and the verifier,
respectively.

### Protocol Setup

- `(gn, xn)` denotes a key pair of public key `gn` and a private key `xn`.
- Alice generates two key pairs, `(g1, x1)`, `(g2, x2)`.
- Bob generates two key pairs, `(g3, x3)`, `(g4, x4)`.
- Both Alice and Bob know the shared secret `s`.
- `H()` is a secure cryptographic hash function, e.g. SHA-256.

*TODO*: investigate the requirements for passcode, to avoid Brute-force attacks

### Two Rounds

J-PAKE protocol has two challenge rounds:

- Round 1:
  - Alice sends `g1`, `g2`, and Zero Knowledge Proof (ZKP) for `x1`, `x2` to Bob
  - Bob sends `g3`, `g4`, and ZKP for `x3`, `x4`
- Round 2:
  - Alice sends `A = f(g1, g3, g4, x2*s)` and ZKP for `x2*s`
  - Bob sends `B = f(g1, g2, g3, x4*s)` and ZKP for `x4*s`

While these two round requires 2 RTT,
[Section 4](https://tools.ietf.org/html/rfc8236#section-4) in [RFC8236]
shows the three-pass variant, i.e. 1.5 RTT protocol:

- Alice sends `g1`, `g2`, and Zero Knowledge Proof (ZKP) for `g1`, `g2` to Bob
- Bob sends `g3`, `g4`, `B = f(g1, g2, g3, x4*s)`, and ZKP for `g3`, `g4`, `x4*s`
- Alice sends `A = f(g1, g3, g4, x2*s)` and ZKP for `x2*s`

The three-pass variant would be simpler to implement, while the two-round variant
could keep symmetric protocol architecture.

*TODO*: consider which variant would be more suitable for Open Screen Protocol

### Common Key Generation

As a result of two rounds of J-PAKE protocol, both Alice and Bob can
compute the common key with `A, x2, s` or `B, x4, s`.
This step will be done when J-PAKE is used to generate common encryption key
as well as to authenticate each other.

Generally, it is recommended that the common key should finally be derived
from a Key Derivation Function (KDF). For example, TLS 1.3
[[draft-ietf-tls-tls13-28](https://tools.ietf.org/html/draft-ietf-tls-tls13-28)]
and message encryption for Web Push
[[RFC8291](https://datatracker.ietf.org/doc/rfc8291/)] uses
HMAC-based Key Derivation Function (HKDF)
[[RFC5869](https://datatracker.ietf.org/doc/rfc5869/)]
to generate the common encryption key.

*TODO*: clarify whether J-PAKE is needed for common key generation or not
in Open Screen Protocol

## Incorporating J-PAKE into Open Screen Protocol

To satisfy
[Privacy and Security requirements](requirements.md#privacy-and-security),
Open Screen Protocol uses J-PAKE protocol so that a controlling UA and a
receiving UA can authenticate each other with a passcode.

J-PAKE authentication must be done before any other communication messages.
There are a couple of possible schemes to incorporate J-PAKE protocol:

- to establish a secure connection with a self-signed certificate and
  start J-PAKE protocol to authenticate each other
- to establish a TLS/DTLS connection integrated with J-PAKE authentication

### J-PAKE over a Secure Connection with a Self-signed Certificate

Once a connection to exchange messages is established, both UAs can send
messages for J-PAKE protocol; Round 1, Round 2, etc.

*TODO*: discuss whether using a self-signed certificate could be considered
as secure or not

### TLS Integration with J-PAKE

[[draft-cragie-tls-ecjpake-01](https://datatracker.ietf.org/doc/draft-cragie-tls-ecjpake/)]
(TLS-ECJ-PAKE) proposes use of J-PAKE over Elliptic Curve as the
authentication mechanism in TLS handshake without relying PKI. However,
the Internet-Draft has already expired and has not been updated yet.

It defines the following extentions in TLS handshake:

- Sending `g1`, `g2`, and ZKP for `g1`, `g2` in ClientHello
- Sending `g3`, `g4`, and ZKP for `g3`, `g4` in ServerHello
- Sending `B`, and ZKP for `x4*s` in ServerKeyExchange
- Sending `A`, and ZKP for `x2*s` in ClientKeyExchange

On the other hand, several problems have been pointed out in the IETF TLS
working group mailing list:

- There has not been any consideration to integrate TLS-ECJ-PAKE into TLS
  1.3 yet.
  [[TLS01](https://www.ietf.org/mail-archive/web/tls/current/msg20341.html)]
- A 3 or 4 message handshake of J-PAKE would not be desirable, because
  a 2 message exchange could fall into the TLS handshake elegantly.
  [[TLS02](https://www.ietf.org/mail-archive/web/tls/current/msg20646.html)]
- It is going to move key exchange role from ClientKeyExchange to
  ClientHello, which might remove all ability to do negotiation in TLS.
  [[TLS02](https://www.ietf.org/mail-archive/web/tls/current/msg20646.html)]

Note that TLS 1.3
[[draft-ietf-tls-tls13-28](https://tools.ietf.org/html/draft-ietf-tls-tls13-28)]
offers 1- and 0-RTT handshake protocols and exchanges keys via ClientHello and
ServerHello messages.

## Open Source Implementations

- [Mbed TLS](https://github.com/ARMmbed/mbedtls) has implementation of
  TLS-ECJ-PAKE. [OpenThread](https://github.com/openthread/openthread)
  refers to Mbed TLS to incorporate TLS-ECJ-PAKE into its protocol stack.
- [Bouncy Castle Cryptography Library](https://www.bouncycastle.org/) has
  [Java implementation of J-PAKE over Finite Field](https://www.bouncycastle.org/docs/docs1.5on/org/bouncycastle/crypto/agreement/jpake/package-summary.html).
- Python 3 has implmementation of J-PAKE over Finite Field as a [Python3 module](https://pypi.org/project/jpake/).
- [NSS](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS) had
  implementation of J-PAKE over Finite Field used by Firefox Sync, but it
  was already discontinued.

## Appendix: Protocol Details

### J-PAKE over Finite Field

J-PAKE over Finite Field is based on modular exponentiation like RSA and
DSA.

- `p` and `q` denote two large primes.
- `Gq` denotes a subgroup of `Zp*` with prime order `q`.
- `g` is a generator for `Gq`.

#### J-PAKE over Finite Field: Round 1

- Alice -> Bob: `g1 = g^x1`, `g2 = g^x2`, ZKP for `x1`, `x2`
- Bob -> Alice: `g3 = g^x3`, `g4 = g^x4`, ZKP for `x3`, `x4`

Regarding a key pair `(D, d)`, ZKP for `d` is calculated by the following
steps:

- Randomly generate a key pair `(V, v)` (`0 ≤ v ≤ q-1`)
- Generate `c = H(g || V || D || User_ID)`, note that `USER_ID` can be any
  pre-shared string
- Compute `r = v - d * c mod q`

Then Alice sends `V` and `r` as ZKP for `d` to Bob.

ZKP is verified by the following steps:

- Verify `1 ≤ D ≤ p-1`, `D^q = 1 mod p`, and `D != 1 mod p`
- Verify `V = g^r * D^c mod p`

#### J-PAKE over Finite Field: Round 2

- Alice -> Bob: `A = g^((g1+g3+g4)*x2*s) mod p` and ZKP for `x2*s`
- Bob -> Alice: `B = g^((g1+g2+g3)*x4*s) mod p` and ZKP for `x4*s`

#### J-PAKE over Finite Field: Common Key Generation

- Alice computes `Ka = (B/g4^(x2*s))^x2 mod p`
- Bob computes `Kb = (A/g2^(x4*s))^x4 mod p`

Here, `Ka = Kb = g^((x1+x3)*x2*x4*s) mod p`.

### J-PAKE over Elliptic Curve

J-PAKE over Elliptic Curve may use elliptic curves like NIST P-256, P-384,
P-521, etc.

- `p` denotes a large prime.
- `E(Fp)` denotes an elliptic curve defined over a finite field `Fp`.
- `G` denotes a generator for the subgroup over `E(Fp)` of prime order `n`.

#### J-PAKE over Elliptic Curve: Round 1

- Alice -> Bob: `G1 = G x [x1]`, `G2 = G x [x2]`, ZKP for `x1`, `x2`
- Bob -> Alice: `G3 = G x [x3]`, `G4 = G x [x4]`, ZKP for `x3`, `x4`

Regarding a key pair `(D, d)`, ZKP for `d` is calculated by the following
steps:

- Randomly generate a key pair `(V, v)` (`0 ≤ v ≤ n-1`)
- Generate `c = H(G || V || D || User_ID)`, note that `USER_ID` can be any
  pre-shared string
- Compute `r = v - d * c mod n`

Then Alice sends `V` and `r` as ZKP for `d` to Bob.

ZKP is verified by the following steps:

- Verify `D` is a valid point on the curve and `D*[h]` is not the point
  at infinity (e.g. `h = 1, 2, or 4`)
- Verify `V = G x [r] + D x [c]`

#### J-PAKE over Elliptic Curve: Round 2

- Alice -> Bob: `A = (G1+G3+G4) x [x2*s]` and ZKP for `x2*s`
- Bob -> Alice: `B = (G1+G2+G3) x [x4*s]` and ZKP for `x4*s`

#### J-PAKE over Elliptic Curve: Common Key Generation

- Alice computes `Ka = (B - (G4 x [x2*s])) x [x2]`
- Bob computes `Kb = (A - (G2 x [x4*s])) x [x4]`

Here, `Ka = Kb = G x [(x1+x3)*(x2*x4*s)]`.

### Key Confirmation

[Section 5](https://tools.ietf.org/html/rfc8236#section-5) in [RFC8236]
recommends that an additional key confirmation should be performed to
achieve explicit authentication, whenever the network bandwidth allows
it. Note that while this procedure provides explicit assurance of
sharing the common encryption key, it requires one additional RTT.

*TODO*: discuss whether explicit key confirmation would really be needed or not

In detail, the following two procedures to confirm the derived key
`k'` have been proposed.

#### Key Confirmation: The first method

- Alice -> Bob: `H(H(k'))`
- Bob -> Alice: `H(k')`

Key Verification defined in
[Mozilla's protocol draft](https://wiki.mozilla.org/WebAPI/PresentationAPI:Protocol_Draft#Device_Pairing)
is based on the first method.

#### Key Confirmation: The second method

In the finite field setting:

- Alice -> Bob:
  `HMAC(k', Message_String || ID_Alice || ID_Bob || g1 || g2 || g3 || g4)`
- Bob -> Alice:
  `HMAC(k', Message_String || ID_Bob || ID_Alice || g3 || g4 || g1 || g2)`

In the elliptic curve setting:

- Alice -> Bob:
  `HMAC(k', Message_String || ID_Alice || ID_Bob || G1 || G2 || G3 || G4)`
- Bob -> Alice:
  `HMAC(k', Message_String || ID_Bob || ID_Alice || G3 || G4 || G1 || G2)`

Note that [[RFC8236](https://tools.ietf.org/html/rfc8236)] recommends
the second method because of implementation symmetry.