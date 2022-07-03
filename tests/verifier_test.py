import pytest
import math
import os
import asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files

VERIFIER_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/verify.cairo")

@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def starknet_factory():
    starknet = await Starknet.empty()
    return starknet

@pytest.fixture(scope="module")
async def verifier_factory(starknet_factory):
    starknet = starknet_factory

    
    # Deploy the account contract
    contract_def = compile_starknet_files(
        files=[VERIFIER_CONTRACT], disable_hint_validation=True
    )
    verifier_contract = await starknet.deploy(contract_def=contract_def)

    return verifier_contract

@pytest.mark.asyncio

async def test_verification(verifier_factory):
    contract = verifier_factory

    public_key = ((0,0,0), (0,0,0))
    alpha = 1
    gamma_point = ((0,0,0), (0,0,0))
    c = ((0,0,0), (0,0,0))
    s = ((0,0,0), (0,0,0))

    execution_info = await contract.verify(public_key, alpha, gamma_point, c, s)

    print(execution_info)