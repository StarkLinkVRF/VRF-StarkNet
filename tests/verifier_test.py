import pytest
import math
import os
import asyncio

from utils import split, pack

@pytest.mark.asyncio
async def test_verification(verifier_factory):

    contract = verifier_factory

    pub_key_x = 76193333737415467666766058750631366235737736777527725219650249207405384034351
    pub_key_y = 54612086558330151575502245117328292006508190407150947628010935769662904771022
    public_key = (split(pub_key_x, 86), split(pub_key_y, 86))
    
    print(public_key)
    
    alpha_string = '268a9d47dde48af4b6e2c33932ed1c13adec25555abaa837c376af4ea2f8a94'
    alpha = int(alpha_string, 16)
    
    proof_x = 81337399269434084288598215639088053873672048945393750805525197560011674811225
    proof_y = 104613304639579741127085286652365844112497716384015480206795977328682955197035
    gamma_point = (split(proof_x, 86), split(proof_y, 86))

    c_int = 86441232732332096478190834197390845099
    c = split(c_int, 86)
    s_int = 66059766962945066339229879380846298561887058815503918374418128665360925700716
    s = split(s_int, 86)

    execution_info = await contract._verify(public_key, alpha, gamma_point, c, s).call()

    print(execution_info)

    res = execution_info.result[0]

    assert res == 1
