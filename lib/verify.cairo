from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint, ec_mul, ec_add, ec_negate
from lib.hash_to_curve import hash_to_curve, get_generator
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.uint256 import Uint256
from lib.hash_points import hash_points

func verify{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        public_key : EcPoint, alpha : Uint256, gamma_point : EcPoint, c : BigInt3, s : BigInt3) -> (
        is_valid : felt):
    alloc_locals

    %{
        def pack86(z, num_bits_shift: int = 86 ) -> int:
            limbs = (z.d0, z.d1, z.d2)
            return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))
        def point_to_string(point):
            p = 115792089237316195423570985008687907853269984665640564039457584007908834671663
            x = pack86(point.x, 86)
            y = pack86(point.y, 86)

            y = (y % 2) + 2
            string = y.to_bytes(1, 'big') + x.to_bytes(32, 'big')
            return string
    %}

    # SECP256K1_SHA256_TAI => 0xFE,
    let suite_string = 254
    let (H) = hash_to_curve(suite_string, public_key, alpha)
    %{ print("done hash to curve") %}
    let (B) = get_generator()
    let (s_mul_B) = ec_mul(B, s)
    %{
        h = point_to_string(ids.H)
        ux = pack86(ids.s_mul_B.x, 86)
        uy = pack86(ids.s_mul_B.y, 86)

        print('s_mul_B')
        print(ux)
        print(uy)
    %}
    let (c_mul_Y) = ec_mul(public_key, c)
    %{
        ux = pack86(ids.c_mul_Y.x, 86)
        uy = pack86(ids.c_mul_Y.y, 86)

        print('c_mul_Y')
        print(ux)
        print(uy)
    %}
    let (negated_c_mul_Y) = ec_negate(c_mul_Y)
    %{
        ux = pack86(ids.negated_c_mul_Y.x, 86)
        uy = pack86(ids.negated_c_mul_Y.y, 86)

        print('negated_c_mul_Y')
        print(ux)
        print(uy)
    %}
    let (U) = ec_add(s_mul_B, negated_c_mul_Y)
    %{
        ux = pack86(ids.U.x, 86)
        uy = pack86(ids.U.y, 86)
        u = point_to_string(ids.U)
        print('u')
        print(ux)
        print(uy)
    %}
    let (s_mul_H) = ec_mul(H, s)
    let (c_mul_gamma) = ec_mul(gamma_point, c)
    let (negated_c_mul_gamma) = ec_negate(c_mul_gamma)

    let (V) = ec_add(s_mul_H, negated_c_mul_gamma)

    %{
        vx = pack86(ids.V.x, 86)
        vy = pack86(ids.V.y, 86)

        print('v')
        print(ids.V.x.d0)
        print(ids.V.x.d1)
        print(ids.V.x.d2)
        print('calc ' ,ids.V.x.d0 + ids.V.x.d1 * 2 ** 86 + ids.V.x.d2 * 2 ** 172)
        print(vx)
        print(vy)
    %}

    %{
        from web3 import Web3 

        g = point_to_string(ids.gamma_point) 

        v = point_to_string(ids.V)

        print('h ' + h.hex()[2:])
        print('g ' + g.hex()[2:])
        print('u ' + u.hex()[2:])
        print('v ' + v.hex()[2:])
        init_str = bytes.fromhex('fe02')
        input = init_str + h + g + u + v
        print(input.hex())
        print('c\'', Web3.keccak(input).hex()[2:])
    %}

    let (_c) = hash_points(H, gamma_point, U, V)

    %{
        def pack256(z, num_bits_shift: int = 128 ) -> int:
            limbs = (z.low, z.high)
            return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))

        print('our res ',hex(pack256(ids._c)))
    %}

    assert _c.high = c.d0 + c.d1 * 2 ** 86

    %{
        print('c decimal' , ids.c.d0 + ids.c.d1 * 2 ** 86)
        print('c\' decimal' , ids._c.high)
    %}
    return (1)
end
