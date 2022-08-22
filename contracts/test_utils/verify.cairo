%lang starknet

%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from lib.verify import verify
from starkware.cairo.common.uint256 import Uint256
@view
func _verify{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*}(
        public_key : EcPoint, alpha : felt, gamma_point : EcPoint, c : BigInt3, s : BigInt3) -> (
        is_valid : felt):
    alloc_locals

    let (res) = verify(public_key, alpha, gamma_point, c, s)

    return (res)
end
