import pytest
import math
import os
import asyncio

from starkware.starkware_utils.error_handling import StarkException, StarkErrorCode
from starkware.starknet.testing.starknet import Starknet

RNG_ORACLE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/rng_oracle.cairo")
DICE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/examples/dice.cairo")
RNG_HASH_CONTRACT =  os.path.join(os.path.dirname(__file__), "../contracts/test_utils/rng_hash.cairo")

@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def starknet_factory():
    starknet = await Starknet.empty()
    return starknet

@pytest.fixture(scope="module")
async def rng_factory(starknet_factory):
    starknet = starknet_factory

    # Deploy the account contract
    rng_oracle_contract = await starknet.deploy(source=RNG_ORACLE_CONTRACT) 
    rng_consumer_contract = await starknet.deploy(source=DICE_CONTRACT, constructor_calldata=[rng_oracle_contract.contract_address])
    rng_hash_contract = await starknet.deploy(source=RNG_HASH_CONTRACT)
    return [rng_oracle_contract, rng_consumer_contract, rng_hash_contract]

def uint(low, high):
    return (high, low)

def RNGPaylod(randomness):
        return (randomness)

@pytest.mark.asyncio
async def test_resolve_rng_request(rng_factory):
    [rng_oracle_contract, rng_consumer_contract, rng_hash_contract] = rng_factory

    request_id = await rng_consumer_contract.request_rng().invoke()
    
    await rng_oracle_contract.resolve_rng_requests(rng_low=10, rng_high=0).invoke()
    
    rng = await rng_hash_contract.get_hash(high=0, low=1).invoke()
    
    latest_rng = await rng_consumer_contract.get_roll_result(request_id.result[0]).call()

    assert latest_rng.result[0] > 0 & latest_rng.result[0] <= 6

    
