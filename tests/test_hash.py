import pytest
from web3 import Web3
from utils import bytes_32_to_uint_256_little, bytes_32_to_uint_256_little, split, pack


@pytest.mark.asyncio
async def test_hash_to_fp(hash_factory):
    contract = hash_factory
   
    test_pedersen_call = await contract.get_pedersen_hash(
        100, 100
    ).call()

    print(test_pedersen_call)
   
    test_keccak_call = await contract.get_keccak_hash(
        100, 100
    ).call()

    print(test_keccak_call)
