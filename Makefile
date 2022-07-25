# Build and test
build :; nile compile
test  :; pytest tests/
deploy_oracle :; nile compile contracts/rng_oracle.cairo && nile deploy --network $(env) rng_oracle 56813112444515337030909853 65493416683031957558705499 2310631506289082809134561 75125512359079384286741984 66304133423307996799370298 17593286038527564039855464
deploy_dice :; nile compile contracts/examples/dice.cairo && nile deploy dice 1580029050699134120620503182540170752157749775081528336811532551277496133906


deploy_oracle_mainnet :; nile compile contracts/rng_oracle.cairo --disable-hint-validation && nile deploy --network mainnet rng_oracle 56813112444515337030909853 65493416683031957558705499 2310631506289082809134561 75125512359079384286741984 66304133423307996799370298 17593286038527564039855464


declare_oracle_testnet :; starknet declare --network alpha-goerli --contract artifacts/rng_oracle.json

deploy_oracle_testnet :; starknet deploy --network alpha-goerli --class_hash 0x7da1591e2f2fa7a0935d90e85ac13d9f9d5ac32229bc58f8d4ed5ce486a4df6 --account test_account \
 --inputs 56813112444515337030909853 65493416683031957558705499 2310631506289082809134561 75125512359079384286741984 66304133423307996799370298 17593286038527564039855464 


declare_dice_testnet :; starknet declare --network alpha-goerli --contract artifacts/dice.json

deploy_dice_testnet :; starknet deploy --network alpha-goerli --class_hash 0x456414132b6fe4add9548a4caf976ff893e16228b60a7780f6bdf999bebdc8a --account test_account \
 --inputs 2376130654481539605278064634536241026607171242675584199684703795189313581234