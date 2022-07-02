from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint
from lib.hash_to_curve import hash_to_curve
from starkware.cairo.common.cairo_secp.bigint import BigInt3

func verify{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        public_key : EcPoint, alpha : felt, gamma_point : EcPoint, c : BigInt3, s : BigInt3) -> ():
    alloc_locals

    # SECP256K1_SHA256_TAI => 0xFE,
    let suite_string = 254
    let (ec_point) = hash_to_curve(suite_string, public_key, alpha)

    return ()
end
