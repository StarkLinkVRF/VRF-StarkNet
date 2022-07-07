from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint, ec_mul, ec_add, ec_negate
from lib.hash_to_curve import hash_to_curve, get_generator
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.uint256 import Uint256

func verify{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        public_key : EcPoint, alpha : Uint256, gamma_point : EcPoint, c : BigInt3, s : BigInt3) -> (
        is_valid : felt):
    alloc_locals

    %{
        def pack(z, num_bits_shift: int = 128) -> int:
            limbs = (z.d0, z.d1, z.d2)
            return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))
    %}

    # SECP256K1_SHA256_TAI => 0xFE,
    let suite_string = 254
    let (H) = hash_to_curve(suite_string, public_key, alpha)
    %{ print("done hash to curve") %}
    let (B) = get_generator()
    let (s_mul_B) = ec_mul(B, s)
    %{
        ux = pack(ids.s_mul_B.x, 86)
        uy = pack(ids.s_mul_B.y, 86)

        print('s_mul_B')
        print(ux)
        print(uy)
    %}
    let (c_mul_Y) = ec_mul(public_key, c)
    %{
        ux = pack(ids.c_mul_Y.x, 86)
        uy = pack(ids.c_mul_Y.y, 86)

        print('c_mul_Y')
        print(ux)
        print(uy)
    %}
    let (negated_c_mul_Y) = ec_negate(c_mul_Y)
    %{
        ux = pack(ids.negated_c_mul_Y.x, 86)
        uy = pack(ids.negated_c_mul_Y.y, 86)

        print('negated_c_mul_Y')
        print(ux)
        print(uy)
    %}
    let (U) = ec_add(s_mul_B, negated_c_mul_Y)
    %{
        ux = pack(ids.U.x, 86)
        uy = pack(ids.U.y, 86)

        print('u')
        print(ux)
        print(uy)
    %}
    let (s_mul_H) = ec_mul(H, s)
    let (c_mul_gamma) = ec_mul(gamma_point, c)
    let (negated_c_mul_gamma) = ec_negate(c_mul_gamma)

    let (V) = ec_add(s_mul_H, negated_c_mul_gamma)

    %{
        vx = pack(ids.V.x, 86)
        vy = pack(ids.V.y, 86)

        print('v')
        print(vx)
        print(vy)
    %}

    %{
        from web3 import Web3 
        hx = pack(ids.H.x, 86)
        gx = pack(ids.gamma_point.x, 86)
        init_str = bytes.fromhex('fe02')
        input = init_str + hx.to_bytes(32, 'big') + gx.to_bytes(32, 'big') + ux.to_bytes(32, 'big') + vx.to_bytes(32, 'big')
        print( Web3.keccak(input).hex()[2:])
    %}

    return (0)
end
