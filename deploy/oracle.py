from nile import nre

def run(nre : nre.NileRuntimeEnvironment):
    # arguments _fee_address : felt, _fee_amount : Uint256, owner_address : felt

    #eth address
    fee_address = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
    fee_amount_low = "0"
    fee_amount_high =  "0"

    #set your address here
    owner_address = "0x4f33db6182529b2b18118b5a2a809c32b0cb41437526fe4660520b998c222a5"
    
    address, abi = nre.deploy(contract="rng_oracle", alias="rng_oracle", arguments=[fee_address, fee_amount_low, fee_amount_high, owner_address])
    print(abi, address)