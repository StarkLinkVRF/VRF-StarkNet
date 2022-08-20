%lang starknet

%builtins pedersen range_check bitwise

from starkware.cairo.common.uint256 import Uint256, uint256_reverse_endian
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint
from starkware.cairo.common.cairo_keccak.keccak import keccak_felts_bigend, keccak, finalize_keccak
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.math import assert_not_equal
from lib.verify import verify
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.hash import hash2

@contract_interface
namespace IRNGConsumer:
    func request_rng():
    end

    func will_recieve_rng(rng : BigInt3, request_id : felt):
    end
end

struct Request:
    member callback_address : felt
    member alpha : felt
    member public_key_hash : felt
end

@storage_var
func requests(index : felt) -> (req : Request):
end

@storage_var
func request_index() -> (index : felt):
end

@storage_var
func completed_requests(index : felt) -> (is_complete : felt):
end

@event
func request_recieved(request_index : felt, pub_key_hash : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    request_index.write(1)
    return ()
end

@external
func resolve_rng_request{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(
        request_index : felt, gamma_point : EcPoint, c : BigInt3, s : BigInt3, public_key : EcPoint):
    alloc_locals

    let (is_complete : felt) = completed_requests.read(request_index)
    assert_not_equal(is_complete, 1)

    let (request : Request) = requests.read(request_index)

    let (hash : felt) = hash2{hash_ptr=pedersen_ptr}(public_key.x.d0, public_key.x.d1) 
    let (hash : felt) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.x.d2) 
    let (hash : felt) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.y.d0)
    let (hash : felt) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.y.d1)
    let (hash : felt) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.y.d2) 

    assert request.public_key_hash = hash

    verify(public_key, request.alpha, gamma_point, c, s)

    IRNGConsumer.will_recieve_rng(
        contract_address=request.callback_address, rng=c, request_id=request_index)

    completed_requests.write(request_index, 1)

    return ()
end

@external
func request_rng{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(public_key_hash : felt) -> (request_id : felt):
    alloc_locals
    let (caller_address) = get_caller_address()
    let (curr_index) = request_index.read()

    let (alpha : felt) = hash2{hash_ptr=pedersen_ptr}(curr_index, caller_address)

    requests.write(curr_index, Request(callback_address=caller_address, alpha=alpha, public_key_hash=public_key_hash))
    request_index.write(curr_index + 1)

    request_recieved.emit(request_index=curr_index, pub_key_hash=public_key_hash)

    return (curr_index)
end


@view
func get_request{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        request_id : felt) -> (request : Request):
    let (request) = requests.read(request_id)
    return (request)
end
