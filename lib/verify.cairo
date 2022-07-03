from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint, ec_mul, ec_add, ec_negate
from lib.hash_to_curve import hash_to_curve, get_generator
from starkware.cairo.common.cairo_secp.bigint import BigInt3

func verify{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        public_key : EcPoint, alpha : felt, gamma_point : EcPoint, c : BigInt3, s : BigInt3) -> (
        is_valid : felt):
    alloc_locals

    # SECP256K1_SHA256_TAI => 0xFE,
    let suite_string = 254
    let (H) = hash_to_curve(suite_string, public_key, alpha)

    let (B) = get_generator()
    let (s_mul_B) = ec_mul(s, B)
    let (c_mul_Y) = ec_mul(c, public_key)

    let (negated_c_mul_Y) = ec_negate(s_mul_B)

    let (U) = ec_add(s_mul_B, negated_c_mul_Y)

    let (s_mul_H) = ec_mul(s, H)
    let (c_mul_gamma) = ec_mul(c, gamma_point)
    let (negated_c_mul_gamma) = ec_negate(c_mul_gamma)

    let (V) = ec_add(s_mul_H, negated_c_mul_gamma)

    return (0)
end
