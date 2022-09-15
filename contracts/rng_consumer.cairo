%lang starknet

%builtins pedersen range_check

from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_secp.bigint import BigInt3

@contract_interface
namespace IRNGOracle {
    func request_rng(beacon_address: felt) -> (requestId: felt) {
    }
}

@storage_var
func oracle_address() -> (addr: felt) {
}

@storage_var
func beacon_address() -> (address: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    oracle_addr: felt, _beacon_address: felt
) {
    oracle_address.write(oracle_addr);
    beacon_address.write(_beacon_address);

    return ();
}

@external
func request_rng{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    request_id: felt
) {
    let (oracle) = oracle_address.read();
    let (_beacon_address) = beacon_address.read();
    let (request_id) = IRNGOracle.request_rng(
        contract_address=oracle, beacon_address=_beacon_address
    );
    return (request_id,);
}

@external
func will_recieve_rng{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rng: BigInt3, request_id: felt
) {
    let (oracle) = oracle_address.read();
    let (caller_address) = get_caller_address();

    assert oracle = caller_address;

    // # Do something with RNG

    return ();
}
