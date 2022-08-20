import pytest

from conftest import deploy_contracts
from utils import split, pedersen_hash_point

def uint(low, high):
    return (high, low)

def RNGPaylod(randomness):
        return (randomness)

@pytest.mark.asyncio
async def test_resolve_rng_request(starknet_factory):
    
    pub_key_x = 20149468923017862635785269351026469201343513335253737999994330121872194856517
    pub_key_y = 45558802482409728232371975206855032011893935284936184167394243449917294149765


    public_key_hash = pedersen_hash_point(pub_key_x, pub_key_y)
    rng_oracle_contract, rng_consumer_contract = await deploy_contracts(starknet_factory, public_key_hash)

    request_id = await rng_consumer_contract.request_rng().invoke()
    request_index = request_id.result[0]

    alpha_string = 'f60cfab7e2cb9f2d73b0c2fa4a4bf40c326a7e71fdcdee263b071276522d0eb1'
    alpha = split(int(alpha_string, 16), 128, 2)
    
    proof_x = 88891765849565571414965223167720997487165670036782477185956645331723164272116
    proof_y = 77707286673583607458729854077033573857836205733434442047337519916364519454446
    gamma_point = (split(proof_x, 86), split(proof_y, 86))

    c_int = 160832113039443480658053119455655547190
    c = split(c_int, 86)
    s_int = 92956457400500151771403164258859910225239768027869754646624900934283469522214
    s = split(s_int, 86)
    await rng_oracle_contract.resolve_rng_request(request_index, gamma_point, c, s,(split(pub_key_x, 86, 3), split(pub_key_y, 86, 3))).invoke()    
    latest_rng = await rng_consumer_contract.get_roll_result(request_index).call()
    assert latest_rng.result[0] > 0 & latest_rng.result[0] <= 6

    
