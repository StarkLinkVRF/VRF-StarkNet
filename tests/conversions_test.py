import pytest
from utils import split, pack
@pytest.mark.asyncio
async def test_bigint3_to_uint384(conversions_factory):
    contract = conversions_factory

    num = 367525736634966448906498224377090192761153467332175430118367082145611583776325

    input = split(num, 86, 3)
    print(input)
    execution_info = await contract._bigint3_to_uint384(input).call()

    res = pack(execution_info.result[0])
    print(pack(input, 86))
    print(res)
    print(num)
    assert pack(input, 86) == res == num
    
@pytest.mark.asyncio
async def test_uint384_to_bigint3(conversions_factory):
    contract = conversions_factory

    num = 2 ** 256 - 1

    input = split(num)
    print(input)
    execution_info = await contract._uint384_to_bigint3(input).call()

    print(execution_info.result[0])
    res = pack(execution_info.result[0], 86)
    
    print(num)
    print(res)
    assert num == res