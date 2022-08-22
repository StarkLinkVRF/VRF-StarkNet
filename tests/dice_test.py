import pytest

from conftest import deploy_contracts
from utils import split, pedersen_hash_point

def uint(low, high):
    return (high, low)

def RNGPaylod(randomness):
        return (randomness)

@pytest.mark.asyncio
async def test_resolve_rng_request(starknet_factory):
    
    pub_key_x = 76193333737415467666766058750631366235737736777527725219650249207405384034351
    pub_key_y = 54612086558330151575502245117328292006508190407150947628010935769662904771022

    public_key_hash = pedersen_hash_point(pub_key_x, pub_key_y)
    rng_oracle_contract, rng_consumer_contract = await deploy_contracts(starknet_factory, public_key_hash)

    request_id = await rng_consumer_contract.request_rng().invoke()
    request_index = request_id.result[0]

    alpha_string = 'f60cfab7e2cb9f2d73b0c2fa4a4bf40c326a7e71fdcdee263b071276522d0eb1'
    alpha = split(int(alpha_string, 16), 128, 2)
    
    proof_x = 81337399269434084288598215639088053873672048945393750805525197560011674811225
    proof_y = 104613304639579741127085286652365844112497716384015480206795977328682955197035
    gamma_point = (split(proof_x, 86), split(proof_y, 86))

    c_int = 86441232732332096478190834197390845099
    c = split(c_int, 86)
    s_int = 66059766962945066339229879380846298561887058815503918374418128665360925700716
    s = split(s_int, 86)
    await rng_oracle_contract.resolve_rng_request(request_index, gamma_point, c, s,(split(pub_key_x, 86, 3), split(pub_key_y, 86, 3))).invoke()    
    latest_rng = await rng_consumer_contract.get_roll_result(request_index).call()
    assert latest_rng.result[0] > 0 & latest_rng.result[0] <= 6

    
