%lang starknet

%builtins pedersen range_check

from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.cairo_builtins import HashBuiltin

struct DrandPayload:
    member randomness : Uint256
    # TODO : add signature, and possibly previous_signature
end

@contract_interface
namespace IRNGOracle:
    func recieve_rng(amount : DrandPayload):
    end

    func request_rng():
    end
end

@storage_var
func oracle_address() -> (addr : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        op_address : felt):
    oracle_address.write(oracle_addr)

    return ()
end

@external
func request_rng{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        request_id : felt):
    let (oracle) = oracle_address.read()
    let (request_id) = IRNGOracle.request_rng(contract_address=oracle)
    return (request_id)
end

@external
func will_recieve_rng{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        rng : felt, request_id : felt):
    let (oracle) = oracle_address.read()
    let (caller_address) = get_caller_address()

    assert oracle = caller_address

    # # Do something with RNG

    return ()
end
