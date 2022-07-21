

from copyreg import constructor
from typing import List
import asyncio
import os
import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.definitions.general_config import build_general_config, default_general_config


HASH_TO_CURVE_CONTRACT = os.path.join("contracts", "test_utils", "hash_to_curve.cairo")
VERIFIER_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/test_utils/verify.cairo")
RNG_ORACLE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/rng_oracle.cairo")
DICE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/examples/dice.cairo")


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
    contract_class = compile_starknet_files(
        files=[HASH_TO_CURVE_CONTRACT], disable_hint_validation=True
    )
    hash_to_curve_contract = await starknet.deploy(contract_class=contract_class)

    return hash_to_curve_contract

@pytest.fixture(scope="module")
async def verifier_factory(starknet_factory):
    starknet = starknet_factory

    
    # Deploy the account contract
    contract_class = compile_starknet_files(
        files=[VERIFIER_CONTRACT], disable_hint_validation=True
    )
    verifier_contract = await starknet.deploy(contract_class=contract_class)

    return verifier_contract


RNG_ORACLE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/rng_oracle.cairo")
DICE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/examples/dice.cairo")

async def deploy_contracts(starknet, public_key : list):

    contract_class = compile_starknet_files(
        files=[RNG_ORACLE_CONTRACT], disable_hint_validation=True
    )

    print("public key ", public_key)
    rng_oracle_contract = await starknet.deploy(contract_class=contract_class,  constructor_calldata=public_key)
    print("rng_oracle_contract.contract_address ", hex(rng_oracle_contract.contract_address))
    contract_class = compile_starknet_files(
        files=[DICE_CONTRACT], disable_hint_validation=True
    )
    rng_consumer_contract = await starknet.deploy(contract_class=contract_class, constructor_calldata=[rng_oracle_contract.contract_address])

    return rng_oracle_contract, rng_consumer_contract
