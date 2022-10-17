// @title StarkLink Randomness Consumer
// @author 0xNonCents
// @notice the base contract to request and recieve randomness from the Starklink Oracle

%lang starknet

%builtins pedersen range_check

from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_secp.bigint import BigInt3

// @notice the interface for the StarkLink Randomness Oracle
@contract_interface
namespace IStarkLinkRandomness {
    func request_rng(beacon_address: felt) -> (request_id: felt) {
    }
}

@storage_var
func oracle_address() -> (addr: felt) {
}

@storage_var
func beacon_address() -> (address: felt) {
}

// @param oracle_addr, the address of the StarkLink Oracle
// @param beacon_address, the address of the randomness beacon, should be a wallet address
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _oracle_address: felt, _beacon_address: felt
) {
    oracle_address.write(_oracle_address);
    beacon_address.write(_beacon_address);

    return ();
}

// @notice use this method to request randomness
// @return request id, used to keep track of a given randomness request
@external
func request_randomness{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    request_id: felt
) {
    let (oracle) = oracle_address.read();
    let (_beacon_address) = beacon_address.read();
    let (request_id) = IStarkLinkRandomness.request_rng(
        contract_address=oracle, beacon_address=_beacon_address
    );
    return (request_id,);
}

@external
func will_receive_randomness{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rng: BigInt3, request_id: felt
) {
    let (oracle) = oracle_address.read();
    let (caller_address) = get_caller_address();

    assert oracle = caller_address;

    // # Do something with RNG

    return ();
}
