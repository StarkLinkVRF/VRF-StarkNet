# VRF-StarkNet
Contracts for verifiable randomness on StarkNet

A VRF oracle on StarkNet based on the [Internet Research Task Force vrf-spec-05](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3). The specific cryptographic suite is a modified `SECP256K1_SHA256_TAI` with a hash function of keccak rather than sha256. A compatible client for generating proofs for this suite is available [here](https://github.com/0xNonCents/vrf-client-starknet-rs).

The client to respond to rng requests is [here](https://github.com/0xNonCents/vrf-client-starknet-rs)

----
[Testnet VRF Oracle](https://goerli.voyager.online/contract/0x0746077cd8eb9cce682daf051bb1fec88f3ba7c6e75e2413bb09a210ab9a2514#writeContract)

[Example VRF Consumer](https://goerli.voyager.online/contract/0x039ba117523ce21318c4c39eb58b3c9789a03199afdfb777a2be7672dc8499f6#writeContract)

Call `request_rng` on the Dice Game contract

Then `resolve_rng_requests` on the Oracle contract

Wait for details of `resolve_rng_requests` to be posted on chain

---

Further documentation tba. In the meantime DM Me(0xNonCents) on discord if you have questions.
