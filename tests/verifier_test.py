import pytest
import math
import os
import asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files
from utils import split

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

    pub_key_x = 20149468923017862635785269351026469201343513335253737999994330121872194856517
    pub_key_y = 45558802482409728232371975206855032011893935284936184167394243449917294149765
    public_key = (split(pub_key_x, 86), split(pub_key_y, 86))
    
    alpha_string = 'aa4ba4b304228a9d05087e147c9e86d84c708bbbe62bb35b28dab74492f6c726'
    alpha = split(int(alpha_string, 16), 128, 2)
    
    proof_x = 61161709921097173805227263462143573869399623567185626884402041611041001159540
    proof_y = 87708755026680130231787585311032344639450737909366683924448043242987816610322
    gamma_point = (split(proof_x, 86), split(proof_y, 86))

    #36a4c5f9dd96e31e60f49675f6755bca3f0cfd5d68ccf2352beec2ceeb302741
    #86A77BB7CCBD086BA3E0063B85B6AF26
    c_int = 178986174309052501196914146948637175590
    c = split(c_int, 86)
    s_int = 49796476285094980251866483569327683831247581392648070262347308917986955046495
    s = split(s_int, 86)

    execution_info = await contract._verify(public_key, alpha, gamma_point, c, s).call()

    print(execution_info)

    res = execution_info.result[0]

    assert res == 1

    exit(1)