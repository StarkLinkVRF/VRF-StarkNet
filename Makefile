# Build and test
build :; nile compile
test  :; pytest tests/
deploy_oracle :; nile compile contracts/rng_oracle.cairo --disable-hint-validation && nile deploy --network goerli rng_oracle 56813112444515337030909853 65493416683031957558705499 2310631506289082809134561 75125512359079384286741984 66304133423307996799370298 17593286038527564039855464
deploy_dice :; nile compile contracts/examples/dice.cairo && nile deploy dice 1580029050699134120620503182540170752157749775081528336811532551277496133906


deploy_oracle_mainnet :; nile compile contracts/rng_oracle.cairo --disable-hint-validation && nile deploy --network mainnet rng_oracle 56813112444515337030909853 65493416683031957558705499 2310631506289082809134561 75125512359079384286741984 66304133423307996799370298 17593286038527564039855464


compile_oracle :; starknet-compile contracts/rng_oracle.cairo \
    --output artifacts/rng_oracle.json \
    --abi artifacts/abis/contract_abi.json