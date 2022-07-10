# VRF-StarkNet
Contracts for verifiable randomness on StarkNet

A VRF oracle on StarkNet based on the [Internet Research Task Force vrf-spec-05](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3). The specific cryptographic suite is a modified `SECP256K1_SHA256_TAI` with a hash function of keccak rather than sha256. A compatible client for generating proofs for this suite is available [here](https://github.com/0xNonCents/vrf-client-starknet-rs).
 
**Requires hints coming in the next version of cairo to be deployed**

----

[Example Dice roll transaction](https://goerli.voyager.online/tx/0x176ccd696901a2b016579764eda165e42073eb36a2daf9787c848e5ba455fe2#events)

Call `request_rng` on the Dice Game contract

Then `resolve_rng_requests` on the Oracle contract

Wait for details of `resolve_rng_requests` to be posted on chain

---

Further documentation tba. In the meantime DM Me(0xNonCents) on discord if you have questions.
