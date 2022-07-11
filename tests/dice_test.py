import pytest

from conftest import deploy_contracts
from utils import split

def uint(low, high):
    return (high, low)

def RNGPaylod(randomness):
        return (randomness)

@pytest.mark.asyncio
async def test_resolve_rng_request(starknet_factory):
    
    pub_key_x = 20149468923017862635785269351026469201343513335253737999994330121872194856517
    pub_key_y = 45558802482409728232371975206855032011893935284936184167394243449917294149765
    public_key = (split(pub_key_x, 86), split(pub_key_y, 86))
    print("1")
    rng_oracle_contract, rng_consumer_contract = await deploy_contracts(starknet_factory, public_key)

    print("2")
    request_id = await rng_consumer_contract.request_rng().invoke()
    request_index = request_id.result[0]

    alpha_string = 'aa4ba4b304228a9d05087e147c9e86d84c708bbbe62bb35b28dab74492f6c726'
    alpha = split(int(alpha_string, 16), 128, 2)
    
    proof_x = 108387273570301396990338919180268941043257366066192973822661636490765034661293
    proof_y = 48066592604551414684761729733175769812806261614417844916697164503346734579279
    gamma_point = (split(proof_x, 86), split(proof_y, 86))

    c_int = 96162451723190744430606610677905925778
    c = split(c_int, 86)
    s_int = 58767353320323650622731727363566842385256743775061957428206921295141466037780
    s = split(s_int, 86)
    print("3")
    await rng_oracle_contract.resolve_rng_request(request_index, gamma_point, c, s).invoke()    
    print("4")
    latest_rng = await rng_consumer_contract.get_roll_result().call()
    print("5")
    assert latest_rng.result[0] > 0 & latest_rng.result[0] <= 6

    
