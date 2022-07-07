import pytest
import math
import os
import asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files

VERIFIER_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/test_utils/conversions.cairo")

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


def split(num: int, num_bits_shift: int = 128, length: int = 3):
    a = []
    for _ in range(length):
        a.append(num & ((1 << num_bits_shift) - 1))
        num = num >> num_bits_shift
    return tuple(a)

def pack(z, num_bits_shift: int = 128) -> int:
    limbs = list(z)
    return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))

@pytest.mark.asyncio
async def test_bigint3_to_uint384(verifier_factory):
    contract = verifier_factory

    num = 367525736634966448906498224377090192761153467332175430118367082145611583776325

    input = split(num, 86, 3)
    print(input)
    execution_info = await contract._bigint3_to_uint384(input).call()

    res = pack(execution_info.result[0])
    print("test")
    print(pack(input, 86))
    print(res)
    print(num)
    assert pack(input, 86) == res == num
    
@pytest.mark.skip(reason="none")
@pytest.mark.asyncio
async def test_uint384_to_bigint3(verifier_factory):
    contract = verifier_factory

    num = 2 ** 256 - 1

    input = split(num)
    print(input)
    execution_info = await contract._uint384_to_bigint3(input).call()

    print(execution_info.result[0])
    res = pack(execution_info.result[0], 86)
    
    print(num)
    print(res)
    assert num == res