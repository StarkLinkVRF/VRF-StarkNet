import os
import sys
from nile import nre
sys.path.append(os.path.join(os.path.dirname(__file__), '..')) 
from tests.utils import pedersen_hash_point
def run(nre : nre.NileRuntimeEnvironment):
    # arguments oracle_addr : felt, _beacon_address : felt
    oracle_address = "0x029db164c334489eada5ca89e5fdcfa788b5f47026994c758d08aee0574177c7"

    pub_key_x = 76193333737415467666766058750631366235737736777527725219650249207405384034351
    pub_key_y = 54612086558330151575502245117328292006508190407150947628010935769662904771022

    public_key_hash = hex(pedersen_hash_point(pub_key_x, pub_key_y))

    address, abi = nre.deploy(contract="dice", alias="dice", arguments=[oracle_address, public_key_hash])
    print(abi, address)