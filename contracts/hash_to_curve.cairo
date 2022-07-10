%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from lib.hash_to_curve import hash_inputs
from starkware.cairo.common.uint256 import Uint256
@view
func _hash_inputs{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : Uint256, ctr : felt) -> (res : Uint256):
    alloc_locals

    let (res) = hash_inputs(suite_string, public_key, alpha, ctr)

    return (res)
end
