

from typing import List
import asyncio
import os
import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.definitions.general_config import build_general_config, default_general_config


HASH_TO_CURVE_CONTRACT = os.path.join("contracts", "hash_to_curve.cairo")

@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope="module")
async def starknet_factory():
    MAX_STEPS = 10 ** 60
    default_config = default_general_config
    default_config['invoke_tx_max_n_steps'] = MAX_STEPS
    config = build_general_config(default_config)
    starknet = await Starknet.empty(config)
    return starknet


@pytest.fixture(scope="module")
async def hash_to_curve_factory(starknet_factory):

    starknet = starknet_factory

    # Deploy the account contract
    contract_def = compile_starknet_files(
        files=[HASH_TO_CURVE_CONTRACT], disable_hint_validation=True
    )
    hash_to_curve_contract = await starknet.deploy(contract_def=contract_def)

    return hash_to_curve_contract

