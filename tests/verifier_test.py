import pytest
import math
import os
import asyncio

from utils import split, pack

@pytest.mark.asyncio
async def test_verification(verifier_factory):

    contract = verifier_factory

    pub_key_x = 13832158124891607159206519344438265232841206464687757249656316762901936390045
    pub_key_y = 105318876575084337581310001232902075227361001209292915308753938340472958469600
    public_key = (split(pub_key_x, 86), split(pub_key_y, 86))
    
    print(public_key)
    
    alpha_string = 'f60cfab7e2cb9f2d73b0c2fa4a4bf40c326a7e71fdcdee263b071276522d0eb1'
    alpha = split(int(alpha_string, 16), 128, 2)
    
    proof_x = 22917286698391534824546747559724498312126414604715826240856897816414444953358
    proof_y = 107148683414022085464959433538861831070729044100932500327882478705310528658641
    gamma_point = (split(proof_x, 86), split(proof_y, 86))

    c_int = 6171528016832641379490091338181983397
    c = split(c_int, 86)
    s_int = 4351899312632745704753590509899110872316463811676070876985781737878774270826
    s = split(s_int, 86)

    execution_info = await contract._verify(public_key, alpha, gamma_point, c, s).call()

    print(execution_info)

    res = execution_info.result[0]

    assert res == 1
