%lang starknet

%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from lib.hash_to_curve import get_pedersen_hash, hash_to_curve
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_keccak.keccak import finalize_keccak
@view
func _hash_inputs{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : felt, ctr : felt) -> (res : felt):
    alloc_locals

    let (local keccak_ptr_start) = alloc()
    let keccak_ptr = keccak_ptr_start
    let (res) = get_pedersen_hash(suite_string, public_key, alpha, ctr)

    return (res)
end

@view
func _hash_to_curve{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : felt) -> (res : EcPoint):
    alloc_locals

    let (res) = hash_to_curve(suite_string, public_key, alpha)

    return (res)
end
