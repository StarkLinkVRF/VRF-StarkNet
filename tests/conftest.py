

from copyreg import constructor
from typing import List
import asyncio
import os
import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.definitions.general_config import build_general_config, default_general_config

from utils import Account, State
from signers import MockSigner


HASH_TO_CURVE_CONTRACT = os.path.join("contracts", "test_utils", "hash_to_curve.cairo")
VERIFIER_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/test_utils/verify.cairo")
RNG_ORACLE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/starklink_randomness.cairo")
DICE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/examples/dice.cairo")
HASH_CONTRACT = os.path.join("contracts", "test_utils", "rng_hash.cairo")
CONVERSIONS_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/test_utils/conversions.cairo")

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
async def hash_factory(starknet_factory):

    starknet = starknet_factory

    # Deploy the account contract
    contract_class = compile_starknet_files(
        files=[HASH_CONTRACT], disable_hint_validation=True
    )
    hash_contract = await starknet.deploy(contract_class=contract_class)

    return hash_contract

@pytest.fixture(scope="module")
async def conversions_factory(starknet_factory):
    starknet = starknet_factory

    # Deploy the account contract
    contract_class = compile_starknet_files(
        files=[CONVERSIONS_CONTRACT], disable_hint_validation=True
    )
    return await starknet.deploy(contract_class=contract_class)

    


RNG_ORACLE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/starklink_randomness.cairo")
DICE_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/examples/dice.cairo")

async def deploy_contracts(starknet, public_key_hash, fee_address=0, fee_amount_high=0, fee_amount_low=0):

    contract_class = compile_starknet_files(
        files=[RNG_ORACLE_CONTRACT], disable_hint_validation=True
    )

    rng_oracle_contract = await starknet.deploy(
    contract_class=contract_class, 
    constructor_calldata=[fee_address,fee_amount_high,fee_amount_low,]
    )
    
    contract_class = compile_starknet_files(
        files=[DICE_CONTRACT], disable_hint_validation=True
    )
    rng_consumer_contract = await starknet.deploy(contract_class=contract_class, constructor_calldata=[rng_oracle_contract.contract_address, public_key_hash])

    return rng_oracle_contract, rng_consumer_contract


signer = MockSigner(123456789987654321)

async def oracle_init(starknet, fee_address=0, fee_amount_high=0, fee_amount_low=0):
    
    owner = await Account.deploy(signer.public_key, starknet)

    oracle_class = compile_starknet_files(
        files=[RNG_ORACLE_CONTRACT], disable_hint_validation=True
    )

    oracle_contract = await starknet.deploy(
        contract_class=oracle_class,
        constructor_calldata=[fee_address,fee_amount_high,fee_amount_low, owner.contract_address]
    )

    not_owner = await Account.deploy(signer.public_key, starknet)
    return starknet, oracle_contract, owner, not_owner


async def dice_init(starknet, oracle_address, beacon_address):
    
    contract_class = compile_starknet_files(
        files=[DICE_CONTRACT], disable_hint_validation=True
    )
    dice_contract = await starknet.deploy(contract_class=contract_class, constructor_calldata=[oracle_address, beacon_address])

    return starknet, dice_contract

@pytest.fixture(scope="module")
@pytest.mark.asyncio
async def contract_mocks(starknet_factory):

    starknet, oracle_contract, owner, not_owner = await oracle_init(starknet_factory)

    starknet, dice = await dice_init(starknet, oracle_contract.contract_address, owner.contract_address)

    return(starknet, oracle_contract, dice, owner, not_owner)
