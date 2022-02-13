# VRF-StarkNet
Contracts for verifiable randomness on StarkNet


[Motivation](https://hackmd.io/@plyL18hXRUWjalLcgt3rLg/Sy4MY981q)

Deployed on StarkNet Testnet
```
Dice Game : 0x01837c5fa18244deb1723bf2512c2b1657d4c7f085d894277d53471be4e5bd6f
Oracle : 0x0478aee025806b6058a60832758cf8dfca36265d28478ce17e6c8148d98ca926
``
[Example Dice roll transaction](https://goerli.voyager.online/tx/0x176ccd696901a2b016579764eda165e42073eb36a2daf9787c848e5ba455fe2#events)
Call `request_rng` on the Dice Game contract
Then `resolve_rng_requests` on the Oracle contract
Wait for details of `resolve_rng_requests` to be posted on chain

Further documentation tba. In the meantime DM Me(0xNonCents) on discord if you have questions.
