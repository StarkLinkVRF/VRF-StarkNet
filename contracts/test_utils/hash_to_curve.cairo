%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from lib.hash_to_curve import hash_inputs, hash_to_curve
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_keccak.keccak import finalize_keccak
@view
func _hash_inputs{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : Uint256, ctr : felt) -> (res : Uint256):
    alloc_locals

    let (local keccak_ptr_start) = alloc()
    let keccak_ptr = keccak_ptr_start
    let (res) = hash_inputs{keccak_ptr=keccak_ptr}(suite_string, public_key, alpha, ctr)

    #finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)

    return (res)
end

@view
func _hash_to_curve{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : Uint256) -> (res : EcPoint):
    alloc_locals

    let (res) = hash_to_curve(suite_string, public_key, alpha)

    return (res)
end
