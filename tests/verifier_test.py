import pytest
import math
import os
import asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files
from utils import split, pack

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

    a = 115792089237316195423570985008687907853269984665640564039457584007908834671663

    g1 = int('79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798' , 16)
    g2 = int('483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8' , 16)
    print(split(a))
    print(split(g1, 86))
    print(split(g2, 86))

    print('v', pack((7399437568356079396133352, 34729230239831676488781517, 3198524048763018255218882), 86))

    contract = verifier_factory

    pub_key_x = 20149468923017862635785269351026469201343513335253737999994330121872194856517
    pub_key_y = 45558802482409728232371975206855032011893935284936184167394243449917294149765
    public_key = (split(pub_key_x, 86), split(pub_key_y, 86))
    
    alpha_string = 'aa4ba4b304228a9d05087e147c9e86d84c708bbbe62bb35b28dab74492f6c726'
    alpha = split(int(alpha_string, 16), 128, 2)
    
    proof_x = 108387273570301396990338919180268941043257366066192973822661636490765034661293
    proof_y = 48066592604551414684761729733175769812806261614417844916697164503346734579279
    gamma_point = (split(proof_x, 86), split(proof_y, 86))

    #aa9d5c7d7c62e36035b27d1543e1c7121876a702037b472df0421ced5ef1e16a
    #485836EB6F1DDF24EE0BB0683682A692
    #485836eb6f1ddf24ee0bb0683682a692723fd4c4d12d777bf27e13e9c9443d79
    c_int = 96162451723190744430606610677905925778
    c = split(c_int, 86)
    s_int = 58767353320323650622731727363566842385256743775061957428206921295141466037780
    s = split(s_int, 86)

    execution_info = await contract._verify(public_key, alpha, gamma_point, c, s).call()

    print(execution_info)

    res = execution_info.result[0]

    assert res == 1
