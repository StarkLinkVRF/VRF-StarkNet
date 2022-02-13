import pytest
import math
import os
import asyncio

from starkware.starkware_utils.error_handling import StarkException, StarkErrorCode
from starkware.starknet.testing.starknet import Starknet

RNG_ORACLE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/rng_oracle.cairo")
RNG_CONSUMER_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/rng_consumer.cairo")
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
    rng_consumer_contract = await starknet.deploy(source=RNG_CONSUMER_CONTRACT, constructor_calldata=[rng_oracle_contract.contract_address])
    rng_hash_contract = await starknet.deploy(source=RNG_HASH_CONTRACT)
    return [rng_oracle_contract, rng_consumer_contract, rng_hash_contract]


#@pytest.mark.asyncio
async def test_request_rng_requests(rng_factory):
    [rng_oracle_contract, rng_consumer_contract, _] = rng_factory

    request_index = await rng_oracle_contract.get_request_index().invoke()
    assert request_index.result[0] == 1

    await rng_consumer_contract.request_rng().invoke()

    request_index = await rng_oracle_contract.get_request_index().invoke()
    assert request_index.result[0] == 2

    request = await rng_oracle_contract.get_request(1).invoke()
    assert request.result[0].callback_address == rng_consumer_contract.contract_address


def uint(low, high):
    return (high, low)

def RNGPaylod(randomness):
        return (randomness)

#@pytest.mark.asyncio
async def test_resolve_rng_request(rng_factory):
    [rng_oracle_contract, rng_consumer_contract, rng_hash_contract] = rng_factory

    await rng_consumer_contract.request_rng().invoke()
    
    RNGPaylod(randomness=(0,1))
    await rng_oracle_contract.resolve_rng_requests(rng_low=1, rng_high=0).invoke()

    latest_rng = await rng_consumer_contract.get_latest_rng().invoke()
    rng = await rng_hash_contract.get_hash(high=0, low=1).invoke()
    assert latest_rng.result[0] == rng.result[0]
    
