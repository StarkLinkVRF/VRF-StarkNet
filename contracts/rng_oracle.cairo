%lang starknet

%builtins pedersen range_check

from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2

@contract_interface
namespace IRNGConsumer:
    func request_rng():
    end

    func will_recieve_rng(rng : felt, request_id : felt):
    end
end

struct RNGPayload:
    member randomness : Uint256
    # TODO : add signature, and possibly previous_signature
end

struct Request:
    member callback_address : felt
    member request_id : felt
end

@storage_var
func requests(index : felt) -> (req : Request):
end

@storage_var
func request_index() -> (index : felt):
end

@storage_var
func completed_index() -> (index : felt):
end

@event
func rng_recieved(randomness : Uint256):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    request_index.write(1)
    completed_index.write(1)

    return ()
end

func resolve_requests{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        curr_index : felt, end_index : felt, randomness : Uint256):
    if curr_index == end_index:
        completed_index.write(curr_index)
        return ()
    end
    let (request) = requests.read(curr_index)

    # TODO : make hash unique for each iteration
    let (hash) = hash2{hash_ptr=pedersen_ptr}(randomness.low, randomness.high)
    IRNGConsumer.will_recieve_rng(
        contract_address=request.callback_address, rng=hash, request_id=request.request_id)

    resolve_requests(curr_index + 1, end_index, randomness)
    return ()
end

@external
func resolve_rng_requests{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        rng_high : felt, rng_low : felt):
    let rng = Uint256(low=rng_low, high=rng_high)

    # TODO : verify calling address
    # TODO : verify randomness
    rng_recieved.emit(randomness=rng)

    let (start_index) = completed_index.read()
    let (end_index) = request_index.read()

    if start_index == end_index:
        return ()
    end

    resolve_requests(start_index, end_index, rng)
    return ()
end

@external
func request_rng{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        request_id : felt):
    let (caller_address) = get_caller_address()
    let (curr_index) = request_index.read()

    # TODO : verify caller against whitelist

    let (request_id) = hash2{hash_ptr=pedersen_ptr}(caller_address, curr_index)

    requests.write(curr_index, Request(callback_address=caller_address, request_id=request_id))
    request_index.write(curr_index + 1)

    return (request_id)
end
