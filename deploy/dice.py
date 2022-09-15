import os
import sys
from nile import nre
sys.path.append(os.path.join(os.path.dirname(__file__), '..')) 
def run(nre : nre.NileRuntimeEnvironment):
    # arguments oracle_addr : felt, _beacon_address : felt
    oracle_address = "0x0166549627a16bde2c316870e53d36d62a7b21aaad81dd48fda4286b61e284bd"

    beacon_address = "0x0266eD55Be7054c74Db3F8Ec2E79C728056C802a11481fAD0E91220139B8916A"

    address, abi = nre.deploy(contract="dice", alias="dice", arguments=[oracle_address, beacon_address])
    print(abi, address)