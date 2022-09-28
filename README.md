# VRF-StarkNet
Contracts for verifiable randomness on StarkNet

A VRF oracle on StarkNet based on the [Internet Research Task Force vrf-spec-05](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3). The specific cryptographic suite is a modified `SECP256K1_SHA256_TAI` with a hash function of keccak rather than sha256. A compatible client for generating proofs for this suite is available [here](https://github.com/0xNonCents/vrf-client-starknet-rs).

The client to respond to rng requests is [here](https://github.com/0xNonCents/vrf-client-starknet-rs)

----
## Deployments

VRF \
[TestNet](https://goerli.voyager.online/contract/0x00f6c3362fd1ffefe6f7177acb6c0574207629ce7d2ddf2f91ea8e740b1327bb) \
[MainNet](https://goerli.voyager.online/contract/0x03eb948750baa18c8732f306171f616aa003afabf00ee9e543d9747fcdccfe4b)

Example App \
[TestNet](https://goerli.voyager.online/contract/0x03e3927d75dc47e1376ae04ace262ca21fe42aeda5dcc7672f411c3246ed5684) \
[MainNet](https://goerli.voyager.online/contract/0x0022d096be050d5838e5ff81f50151eab61affaee5e95dabe3455afebc68c248)

---

Further documentation tba. In the meantime DM Me(0xNonCents) on discord if you have questions.
