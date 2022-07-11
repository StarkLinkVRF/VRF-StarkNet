# From https://github.com/NethermindEth/384bit-prime-field-arithmetic-cairo
# @Author Albert Garreta, 0xNonCents

from starkware.cairo.common.bitwise import bitwise_and, bitwise_or, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.math import assert_in_range, assert_le, assert_nn_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.pow import pow
from starkware.cairo.common.registers import get_ap, get_fp_and_pc
# Import uint384 files (path may change in the future)
from lib.uint384 import uint384_lib, Uint384
from lib.uint384_extension import uint384_extension_lib, Uint768

# Functions for operating elements in a finite field F_p (i.e. modulo a prime p), with p of at most 384 bits

namespace field_arithmetic_lib:
    # Computes (a + b) modulo p .
    func add{range_check_ptr}(a : Uint384, b : Uint384, p : Uint384) -> (res : Uint384):
        let (sum : Uint384, carry) = uint384_lib.add(a, b)
        let sum_with_carry : Uint768 = Uint768(sum.d0, sum.d1, sum.d2, carry, 0, 0)

        let (quotient : Uint768,
            remainder : Uint384) = uint384_extension_lib.unsigned_div_rem_uint768_by_uint384(
            sum_with_carry, p)
        return (remainder)
    end

    # Computes (a - b) modulo p .
    # NOTE: Expects a and b to be reduced modulo p (i.e. between 0 and p-1). The function will revert if a > p.
    # NOTE: To reduce a, take the remainder of uint384_lin.unsigned_div_rem(a, p), and similarly for b.
    # @dev First it computes res =(a-b) mod p in a hint and then checks outside of the hint that res + b = a modulo p
    func sub_reduced_a_and_reduced_b{range_check_ptr}(a : Uint384, b : Uint384, p : Uint384) -> (
            res : Uint384):
        alloc_locals
        local res : Uint384
        %{
            def split(num: int, num_bits_shift: int, length: int):
                a = []
                for _ in range(length):
                    a.append( num & ((1 << num_bits_shift) - 1) )
                    num = num >> num_bits_shift 
                return tuple(a)

            def pack(z, num_bits_shift: int) -> int:
                limbs = (z.d0, z.d1, z.d2)
                return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))

            a = pack(ids.a, num_bits_shift = 128)
            b = pack(ids.b, num_bits_shift = 128)
            p = pack(ids.p, num_bits_shift = 128)

            res = (a - b) % p


            res_split = split(res, num_bits_shift=128, length=3)

            ids.res.d0 = res_split[0]
            ids.res.d1 = res_split[1]
            ids.res.d2 = res_split[2]
        %}
        let (b_plus_res) = add(b, res, p)
        assert b_plus_res = a
        return (res)
    end

    # Computes a * b modulo p
    func mul{range_check_ptr}(a : Uint384, b : Uint384, p : Uint384) -> (res : Uint384):
        alloc_locals
        local remainder : Uint384
        %{
            from starkware.python.math_utils import isqrt

            def split(num: int, num_bits_shift: int, length: int):
                a = []
                for _ in range(length):
                    a.append( num & ((1 << num_bits_shift) - 1) )
                    num = num >> num_bits_shift 
                return tuple(a)

            def pack(z, num_bits_shift: int) -> int:
                limbs = (z.d0, z.d1, z.d2)
                return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))

            a = pack(ids.a, num_bits_shift=128)
            b = pack(ids.b, num_bits_shift=128)
            p = pack(ids.p, num_bits_shift=128)
            product = (a * b) % p
            product_split = split(product, num_bits_shift=128, length=3)
            ids.remainder.d0 = product_split[0]
            ids.remainder.d1 = product_split[1]
            ids.remainder.d2 = product_split[2]
        %}
        return (remainder)
    end

    # Computes a * b^{-1} modulo p
    # NOTE: The modular inverse of b modulo p is computed in a hint and verified outside the hind with a multiplicaiton
    func div{range_check_ptr}(a : Uint384, b : Uint384, p : Uint384) -> (res : Uint384):
        alloc_locals
        local b_inverse_mod_p : Uint384
        %{
            def split(num: int, num_bits_shift: int, length: int):
                a = []
                for _ in range(length):
                    a.append( num & ((1 << num_bits_shift) - 1) )
                    num = num >> num_bits_shift 
                return tuple(a)

            def pack(z, num_bits_shift: int) -> int:
                limbs = (z.d0, z.d1, z.d2)
                return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))

            a = pack(ids.a, num_bits_shift = 128)
            b = pack(ids.b, num_bits_shift = 128)
            p = pack(ids.p, num_bits_shift = 128)
            b_inverse_mod_p = pow(b, -1, p)
            a_div_b = (a* b_inverse_mod_p) % p

            b_inverse_mod_p_split = split(b_inverse_mod_p, num_bits_shift=128, length=3)

            ids.b_inverse_mod_p.d0 = b_inverse_mod_p_split[0]
            ids.b_inverse_mod_p.d1 = b_inverse_mod_p_split[1]
            ids.b_inverse_mod_p.d2 = b_inverse_mod_p_split[2]
        %}
        let (b_times_b_inverse) = mul(b, b_inverse_mod_p, p)
        assert b_times_b_inverse = Uint384(1, 0, 0)

        let (res : Uint384) = mul(a, b_inverse_mod_p, p)
        return (res)
    end

    # Computes (a**exp) % p. Uses the fast exponentiation algorithm, so it takes at most 384 squarings: https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    func pow{range_check_ptr}(a : Uint384, exp : Uint384, p : Uint384) -> (res : Uint384):
        alloc_locals
        let (is_exp_zero) = uint384_lib.eq(exp, Uint384(0, 0, 0))

        if is_exp_zero == 1:
            return (Uint384(1, 0, 0))
        end

        let (is_exp_one) = uint384_lib.eq(exp, Uint384(1, 0, 0))
        if is_exp_one == 1:
            # If exp = 1, it is possible that `a` is not reduced mod p,
            # so we check and reduce if necessary
            let (is_a_lt_p) = uint384_lib.lt(a, p)
            if is_a_lt_p == 1:
                return (a)
            else:
                let (quotient, remainder) = uint384_lib.unsigned_div_rem(a, p)
                return (remainder)
            end
        end

        let (exp_div_2, remainder) = uint384_lib.unsigned_div_rem(exp, Uint384(2, 0, 0))
        let (is_remainder_zero) = uint384_lib.eq(remainder, Uint384(0, 0, 0))

        if is_remainder_zero == 1:
            # NOTE: Code is repeated in the if-else to avoid declaring a_squared as a local variable
            let (a_squared : Uint384) = mul(a, a, p)
            let (res) = pow(a_squared, exp_div_2, p)
            return (res)
        else:
            let (a_squared : Uint384) = mul(a, a, p)
            let (res) = pow(a_squared, exp_div_2, p)
            let (res_mul) = mul(a, res, p)
            return (res_mul)
        end
    end

    # WARNING: Will be deprecated
    # Checks if x is a square in F_q, i.e. x ≅ y**2 (mod q) for some y
    # `p_minus_one_div_2` is (p-1)/2. It is passed as an argument rather than computed, since for most applications
    # p (and thus (p-1)/2) will be hardcoded and this library wrapped around with p fixed to the hardcoded value
    func is_square_non_optimized{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
            x : Uint384, p : Uint384, p_minus_one_div_2 : Uint384) -> (bool : felt):
        alloc_locals
        let (is_x_zero) = uint384_lib.eq(x, Uint384(0, 0, 0))
        if is_x_zero == 1:
            return (1)
        end
        # let (p_minus_one_div_2 : Uint384) = get_p_minus_one_div_2()
        let (res : Uint384) = pow(x, p_minus_one_div_2, p)
        let (is_res_zero) = uint384_lib.eq(res, Uint384(0, 0, 0))
        let (is_res_one) = uint384_lib.eq(res, Uint384(1, 0, 0))
        if is_res_one == 1:
            return (1)
        else:
            return (0)
        end
    end

    func get_square_root{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
            x : Uint384, p : Uint384, generator : Uint384) -> (success : felt, res : Uint384):
        alloc_locals

        # TODO: Create an equality function within field_arithmetic to avoid overflow bugs
        let (is_zero) = uint384_lib.eq(x, Uint384(0, 0, 0))
        if is_zero == 1:
            return (1, Uint384(0, 0, 0))
        end

        local success_x : felt
        local success_gx : felt
        local sqrt_x : Uint384
        local sqrt_gx : Uint384

        # Compute square roots in a hint
        %{
            from starkware.python.math_utils import is_quad_residue, sqrt

            def split(num: int, num_bits_shift: int = 128, length: int = 3):
                a = []
                for _ in range(length):
                    a.append( num & ((1 << num_bits_shift) - 1) )
                    num = num >> num_bits_shift 
                return tuple(a)

            def pack(z, num_bits_shift: int = 128) -> int:
                limbs = (z.d0, z.d1, z.d2)
                return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))

            print("0") 
            generator = pack(ids.generator)
            x = pack(ids.x)
            p = pack(ids.p)
            print(x)
            success_x = is_quad_residue(x, p)
            root_x = sqrt(x, p) if success_x else None
            success_gx = is_quad_residue(generator*x, p)
            root_gx = sqrt(generator*x, p) if success_gx else None
            print("three")

            # Check that one is 0 and the other is 1
            print("success_x", success_x)
            print("success_gx", success_gx)  
            if x != 0:
                assert success_x + success_gx ==1
            print("root_x", root_x)
            print("root_gx", root_gx)  
            # `None` means that no root was found, but we need to transform these into a felt no matter what
            if root_x == None:
                root_x = 0
            if root_gx == None:
                root_gx = 0
            ids.success_x = success_x
            ids.success_gx =success_gx
            split_root_x = split(root_x)
            split_root_gx = split(root_gx)
            ids.sqrt_x.d0 = split_root_x[0]
            ids.sqrt_x.d1 = split_root_x[1]
            ids.sqrt_x.d2 = split_root_x[2]
            ids.sqrt_gx.d0 = split_root_gx[0]
            ids.sqrt_gx.d1 = split_root_gx[1]
            ids.sqrt_gx.d2 = split_root_gx[2]
            print("done")
        %}

        # Verify that the values computed in the hint are what they are supposed to be
        let (gx : Uint384) = mul(generator, x, p)
        if success_x == 1:
            let (sqrt_x_squared : Uint384) = mul(sqrt_x, sqrt_x, p)
            # Note these checks may fail if the input x does not satisfy 0<= x < p
            # TODO: Create a equality function within field_arithmetic to avoid overflow bugs
            let (check_x) = uint384_lib.eq(x, sqrt_x_squared)
            assert check_x = 1
        else:
            # In this case success_gx = 1
            let (sqrt_gx_squared : Uint384) = mul(sqrt_gx, sqrt_gx, p)
            let (check_gx) = uint384_lib.eq(gx, sqrt_gx_squared)
            assert check_gx = 1
        end

        # Return the appropriate values
        if success_x == 0:
            # No square roots were found
            # Note that Uint384(0, 0, 0) is not a square root here, but something needs to be returned
            return (0, Uint384(0, 0, 0))
        else:
            return (1, sqrt_x)
        end
    end

    func eq(a : Uint384, b : Uint384) -> (bool : felt):
        let (is_a_equal_b) = uint384_lib.eq(a, b)
        if is_a_equal_b == 1:
            return (1)
        else:
            return (0)
        end
    end

    func is_zero(a : Uint384) -> (bool : felt):
        let (is_a_zero) = uint384_lib.is_zero(a)
        if is_a_zero == 1:
            return (1)
        else:
            return (0)
        end
    end
end
