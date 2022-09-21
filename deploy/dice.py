import os
import sys
from nile import nre

sys.path.append(os.path.join(os.path.dirname(__file__), '..')) 
def run(nre : nre.NileRuntimeEnvironment):
    # arguments oracle_addr : felt, _beacon_address : felt
    oracle_address = "0x07c7487e5bad058706d0ea5829e3eb8031e92b2c90cf31468ed0559e81abdf92"

    beacon_address = "0x4f33db6182529b2b18118b5a2a809c32b0cb41437526fe4660520b998c222a5"

    address, abi = nre.deploy(contract="dice", alias="dice", arguments=[oracle_address, beacon_address])
    print(abi, address)