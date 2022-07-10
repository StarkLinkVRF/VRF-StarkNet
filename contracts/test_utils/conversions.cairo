%lang starknet

%builtins range_check bitwise

from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash import hash2
from lib.hash_to_curve import bigint3_to_uint384, uint384_to_bigint3
from lib.uint384 import Uint384

@view
func _bigint3_to_uint384{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(in : BigInt3) -> (
        out : Uint384):
    let (out) = bigint3_to_uint384(in)
    return (out)
end

@view
func _uint384_to_bigint3{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(in : Uint384) -> (
        out : BigInt3):
    let (out) = uint384_to_bigint3(in)
    return (out)
end
