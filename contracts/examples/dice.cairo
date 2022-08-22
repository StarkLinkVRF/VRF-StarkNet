%lang starknet

%builtins pedersen range_check

from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, split_felt
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.hash import hash2

@contract_interface
namespace IRNGOracle:
    func request_rng(beacon_address : felt) -> (requestId : felt):
    end
end

@storage_var
func oracle_address() -> (addr : felt):
end

@storage_var
func beacon_address() -> (address : felt):
end

@storage_var
func roll_results(id : felt) -> (result : felt):
end

@event
func rng_request_resolved(rng : BigInt3, request_id : felt, result : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        oracle_addr : felt, _beacon_address : felt):
    oracle_address.write(oracle_addr)
    beacon_address.write(_beacon_address)

    return ()
end

@external
func request_rng{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        request_id : felt):
    let (oracle) = oracle_address.read()
    let (_beacon_address) = beacon_address.read()
    let (request_id) = IRNGOracle.request_rng(contract_address=oracle, beacon_address=_beacon_address)
    return (request_id)
end

func roll_dice{syscall_ptr : felt*, range_check_ptr}(rng : felt) -> (roll : felt):
    # Take the lower 128 bits of the random string
    let (_, low) = split_felt(rng)
    let (_, roll) = unsigned_div_rem(low, 6)
    return (roll + 1)
end

@external
func will_recieve_rng{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        rng : BigInt3, request_id : felt):
    let (oracle) = oracle_address.read()
    let (caller_address) = get_caller_address()

    assert oracle = caller_address

    let (roll) = roll_dice(rng.d0)

    roll_results.write(request_id, roll)

    rng_request_resolved.emit(rng, request_id, roll)
    return ()
end

@view
func get_roll_result{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        id : felt) -> (roll : felt):
    let (roll) = roll_results.read(id)
    return (roll)
end
