from starkware.cairo.common.bitwise import bitwise_and, bitwise_or, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.math import assert_in_range, assert_le, assert_nn_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
# from starkware.cairo.common.uint256 import word_reverse_endian
from starkware.cairo.common.pow import pow
from starkware.cairo.common.registers import get_ap, get_fp_and_pc

# This library is adapted from Cairo's common library Uint256 and it follows it as closely as possible.
# The library implements basic operations between 384-bit integers.
# Most operations use unsigned integers. Only a few operations are implemented for signed integers

# Represents an integer in the range [0, 2^384).
struct Uint384:
    # The low 128 bits of the value.
    member d0 : felt
    # The middle 128 bits of the value.
    member d1 : felt
    # The # 128 bits of the value.
    member d2 : felt
end

const SHIFT = 2 ** 128
const ALL_ONES = 2 ** 128 - 1
const HALF_SHIFT = 2 ** 64

namespace uint384_lib:
    # Verifies that the given integer is valid.
    func check{range_check_ptr}(a : Uint384):
        [range_check_ptr] = a.d0
        [range_check_ptr + 1] = a.d1
        [range_check_ptr + 2] = a.d2
        let range_check_ptr = range_check_ptr + 3
        return ()
    end

    # Arithmetics.

    # Adds two integers. Returns the result as a 384-bit integer and the (1-bit) carry.
    func add{range_check_ptr}(a : Uint384, b : Uint384) -> (res : Uint384, carry : felt):
        alloc_locals
        local res : Uint384
        local carry_d0 : felt
        local carry_d1 : felt
        local carry_d2 : felt
        %{
            sum_d0 = ids.a.d0 + ids.b.d0
            ids.carry_d0 = 1 if sum_d0 >= ids.SHIFT else 0
            sum_d1 = ids.a.d1 + ids.b.d1 + ids.carry_d0
            ids.carry_d1 = 1 if sum_d1 >= ids.SHIFT else 0
            sum_d2 = ids.a.d2 + ids.b.d2 + ids.carry_d1
            ids.carry_d2 = 1 if sum_d2 >= ids.SHIFT else 0
        %}

        # Either 0 or 1
        assert carry_d0 * carry_d0 = carry_d0
        assert carry_d1 * carry_d1 = carry_d1
        assert carry_d2 * carry_d2 = carry_d2

        assert res.d0 = a.d0 + b.d0 - carry_d0 * SHIFT
        assert res.d1 = a.d1 + b.d1 + carry_d0 - carry_d1 * SHIFT
        assert res.d2 = a.d2 + b.d2 + carry_d1 - carry_d2 * SHIFT

        check(res)

        return (res, carry_d2)
    end

    # Splits a field element in the range [0, 2^192) to its low 64-bit and high 128-bit parts.
    func split_64{range_check_ptr}(a : felt) -> (low : felt, high : felt):
        alloc_locals
        local low : felt
        local high : felt

        %{
            ids.low = ids.a & ((1<<64) - 1)
            ids.high = ids.a >> 64
        %}
        assert a = low + high * HALF_SHIFT
        assert [range_check_ptr + 0] = low
        assert [range_check_ptr + 1] = HALF_SHIFT - 1 - low
        assert [range_check_ptr + 2] = high
        let range_check_ptr = range_check_ptr + 3
        return (low, high)
    end

    # Multiplies two integers. Returns the result as two 384-bit integers: the result has 2*384 bits,
    # the returned integers represent the lower 384-bits and the higher 384-bits, respectively.
    func mul{range_check_ptr}(a : Uint384, b : Uint384) -> (low : Uint384, high : Uint384):
        alloc_locals
        let (a0, a1) = split_64(a.d0)
        let (a2, a3) = split_64(a.d1)
        let (a4, a5) = split_64(a.d2)
        let (b0, b1) = split_64(b.d0)
        let (b2, b3) = split_64(b.d1)
        let (b4, b5) = split_64(b.d2)

        let (res0, carry) = split_64(a0 * b0)
        let (res1, carry) = split_64(a1 * b0 + a0 * b1 + carry)
        let (res2, carry) = split_64(a2 * b0 + a1 * b1 + a0 * b2 + carry)
        let (res3, carry) = split_64(a3 * b0 + a2 * b1 + a1 * b2 + a0 * b3 + carry)
        let (res4, carry) = split_64(a4 * b0 + a3 * b1 + a2 * b2 + a1 * b3 + a0 * b4 + carry)
        let (res5, carry) = split_64(
            a5 * b0 + a4 * b1 + a3 * b2 + a2 * b3 + a1 * b4 + a0 * b5 + carry)
        let (res6, carry) = split_64(a5 * b1 + a4 * b2 + a3 * b3 + a2 * b4 + a1 * b5 + carry)
        let (res7, carry) = split_64(a5 * b2 + a4 * b3 + a3 * b4 + a2 * b5 + carry)
        let (res8, carry) = split_64(a5 * b3 + a4 * b4 + a3 * b5 + carry)
        let (res9, carry) = split_64(a5 * b4 + a4 * b5 + carry)
        let (res10, carry) = split_64(a5 * b5 + carry)

        return (
            low=Uint384(d0=res0 + HALF_SHIFT * res1, d1=res2 + HALF_SHIFT * res3, d2=res4 + HALF_SHIFT * res5),
            high=Uint384(d0=res6 + HALF_SHIFT * res7, d1=res8 + HALF_SHIFT * res9, d2=res10 + HALF_SHIFT * carry))
    end

    # Multiplies two integers. Returns the result as two 256-bit integers (low and high parts).
    # func mul{range_check_ptr}(a : Uint384, b : Uint384) -> (low : Uint384, high : Uint384):
    #     alloc_locals
    #
    #     let (res0, carry) = split_128(a.d0 * b.d0)
    #     let (res1, carry) = split_128(a.d1 * b.d0 + a.d0 * b.d1 + carry)
    #     let (res2, carry) = split_128(a.d2 * b.d0 + a.d1 * b.d1  + a.d0 * b.d2 + carry)
    #     let (res3, carry) = split_128(a.d2 * b.d1 + a.d1 * b.d2  + carry)
    #     let (res4, carry) = split_128(a.d2 * b.d2  + carry)
    #     return (low=Uint384(d0=res0, d1=res1, d2 = res2), high=Uint384(d0=res3, d1=res4, d2=carry))
    # end

    # Returns the floor value of the square root of a Uint384 integer.
    func sqrt{range_check_ptr}(a : Uint384) -> (res : Uint384):
        alloc_locals
        let (__fp__, _) = get_fp_and_pc()
        local root : Uint384

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
            root = isqrt(a)
            assert 0 <= root < 2 ** 192
            root_split = split(root, num_bits_shift=128, length=3)
            ids.root.d0 = root_split[0]
            ids.root.d1 = root_split[1]
            ids.root.d2 = root_split[2]
        %}

        # Verify that 0 <= root < 2**192.
        assert root.d2 = 0
        [range_check_ptr] = root.d0

        # Check that 0 <= d1 < 2**64, equivalent to checking 0<= d1*2**64 < 2**128
        assert [range_check_ptr + 1] = (root.d1) * (2 ** 64) + 1
        let range_check_ptr = range_check_ptr + 2

        # Verify that n >= root**2.
        let (root_squared, carry) = mul(root, root)
        assert carry = Uint384(0, 0, 0)
        let (check_lower_bound) = le(root_squared, a)
        assert check_lower_bound = 1

        # Verify that n <= (root+1)**2 - 1.
        # In the case where root = 2**192 - 1, we will have next_root_squared=0, since
        # (root+1)**2 = 2**384. Therefore next_root_squared - 1 = 2**384 - 1, as desired.
        let (next_root, add_carry) = add(root, Uint384(1, 0, 0))
        assert add_carry = 0
        let (next_root_squared, _) = mul(next_root, next_root)
        let (next_root_squared_minus_one) = sub(next_root_squared, Uint384(1, 0, 0))
        let (check_upper_bound) = le(a, next_root_squared_minus_one)
        assert check_upper_bound = 1

        return (res=root)
    end

    # Returns 1 if the first unsigned integer is less than the second unsigned integer.
    func lt{range_check_ptr}(a : Uint384, b : Uint384) -> (res):
        if a.d2 == b.d2:
            if a.d1 == b.d1:
                return is_le(a.d0 + 1, b.d0)
            end
            return is_le(a.d1 + 1, b.d1)
        end
        return is_le(a.d2 + 1, b.d2)
    end

    # Returns 1 if the first signed integer is less than the second signed integer.
    func signed_lt{range_check_ptr}(a : Uint384, b : Uint384) -> (res):
        let (a, _) = add(a, Uint384(d0=0, d1=0, d2=2 ** 127))
        let (b, _) = add(b, Uint384(d0=0, d1=0, d2=2 ** 127))
        return lt(a, b)
    end

    # Returns 1 if the first unsigned integer is less than or equal to the second unsigned integer.
    func le{range_check_ptr}(a : Uint384, b : Uint384) -> (res):
        let (not_le) = lt(a=b, b=a)
        return (1 - not_le)
    end

    # Returns 1 if the first signed integer is less than or equal to the second signed integer.
    func signed_le{range_check_ptr}(a : Uint384, b : Uint384) -> (res):
        let (not_le) = signed_lt(a=b, b=a)
        return (1 - not_le)
    end

    # TODO: do we need to use `@known_ap_change` here?
    # Returns 1 if the signed integer is nonnegative.
    @known_ap_change
    func signed_nn{range_check_ptr}(a : Uint384) -> (res):
        %{ memory[ap] = 1 if 0 <= (ids.a.d2 % PRIME) < 2 ** 127 else 0 %}
        jmp non_negative if [ap] != 0; ap++

        assert [range_check_ptr] = a.d2 - 2 ** 127
        let range_check_ptr = range_check_ptr + 1
        return (res=0)

        non_negative:
        assert [range_check_ptr] = a.d2 + 2 ** 127
        let range_check_ptr = range_check_ptr + 1
        return (res=1)
    end

    # Returns 1 if the first signed integer is less than or equal to the second signed integer
    # and is greater than or equal to zero.
    func signed_nn_le{range_check_ptr}(a : Uint384, b : Uint384) -> (res):
        let (is_le) = signed_le(a=a, b=b)
        if is_le == 0:
            return (res=0)
        end
        let (is_nn) = signed_nn(a=a)
        return (res=is_nn)
    end

    # Unsigned integer division between two integers. Returns the quotient and the remainder.
    # Conforms to EVM specifications: division by 0 yields 0.
    func unsigned_div_rem{range_check_ptr}(a : Uint384, div : Uint384) -> (
            quotient : Uint384, remainder : Uint384):
        alloc_locals
        local quotient : Uint384
        local remainder : Uint384

        # If div == 0, return (0, 0, 0).
        if div.d0 + div.d1 + div.d2 == 0:
            return (quotient=Uint384(0, 0, 0), remainder=Uint384(0, 0, 0))
        end

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
            div = pack(ids.div, num_bits_shift = 128)
            quotient, remainder = divmod(a, div)

            quotient_split = split(quotient, num_bits_shift=128, length=3)
            assert len(quotient_split) == 3

            ids.quotient.d0 = quotient_split[0]
            ids.quotient.d1 = quotient_split[1]
            ids.quotient.d2 = quotient_split[2]

            remainder_split = split(remainder, num_bits_shift=128, length=3)
            ids.remainder.d0 = remainder_split[0]
            ids.remainder.d1 = remainder_split[1]
            ids.remainder.d2 = remainder_split[2]
        %}
        let (res_mul : Uint384, carry : Uint384) = mul(quotient, div)
        assert carry = Uint384(0, 0, 0)

        let (check_val : Uint384, add_carry : felt) = add(res_mul, remainder)
        assert check_val = a
        assert add_carry = 0

        let (is_valid) = lt(remainder, div)
        assert is_valid = 1
        return (quotient=quotient, remainder=remainder)
    end

    # Returns the bitwise NOT of an integer.
    func not{range_check_ptr}(a : Uint384) -> (res : Uint384):
        return (Uint384(d0=ALL_ONES - a.d0, d1=ALL_ONES - a.d1, d2=ALL_ONES - a.d2))
    end

    # Returns the negation of an integer.
    # Note that the negation of -2**383 is -2**383.
    func neg{range_check_ptr}(a : Uint384) -> (res : Uint384):
        let (not_num) = not(a)
        let (res, _) = add(not_num, Uint384(d0=1, d1=0, d2=0))
        return (res)
    end

    # Conditionally negates an integer.
    func cond_neg{range_check_ptr}(a : Uint384, should_neg) -> (res : Uint384):
        if should_neg != 0:
            return neg(a)
        else:
            return (res=a)
        end
    end

    # Signed integer division between two integers. Returns the quotient and the remainder.
    # Conforms to EVM specifications.
    # See ethereum yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf, page 29).
    # Note that the remainder may be negative if one of the inputs is negative and that
    # (-2**383) / (-1) = -2**383 because 2**383 is out of range.
    func signed_div_rem{range_check_ptr}(a : Uint384, div : Uint384) -> (
            quot : Uint384, rem : Uint384):
        alloc_locals

        # When div=-1, simply return -a.
        if div.d0 == SHIFT - 1:
            if div.d1 == SHIFT - 1:
                if div.d2 == SHIFT - 1:
                    let (quot) = neg(a)
                    return (quot, Uint384(0, 0, 0))
                end
            end
        end

        # Take the absolute value of a.
        let (local a_sign) = is_le(2 ** 127, a.d2)
        local range_check_ptr = range_check_ptr
        let (local a) = cond_neg(a, should_neg=a_sign)

        # Take the absolute value of div.
        let (local div_sign) = is_le(2 ** 127, div.d2)
        local range_check_ptr = range_check_ptr
        let (div) = cond_neg(div, should_neg=div_sign)

        # Unsigned division.
        let (local quot, local rem) = unsigned_div_rem(a, div)
        local range_check_ptr = range_check_ptr

        # Fix the remainder according to the sign of a.
        let (rem) = cond_neg(rem, should_neg=a_sign)

        # Fix the quotient according to the signs of a and div.
        if a_sign == div_sign:
            return (quot=quot, rem=rem)
        end
        let (local quot_neg) = neg(quot)

        return (quot=quot_neg, rem=rem)
    end

    # Subtracts two integers. Returns the result as a 384-bit integer.
    func sub{range_check_ptr}(a : Uint384, b : Uint384) -> (res : Uint384):
        let (b_neg) = neg(b)
        let (res, _) = add(a, b_neg)
        return (res)
    end

    # Return true if both integers are equal.
    func eq{range_check_ptr}(a : Uint384, b : Uint384) -> (res : felt):
        if a.d2 != b.d2:
            return (0)
        end
        if a.d1 != b.d1:
            return (0)
        end
        if a.d0 != b.d0:
            return (0)
        end
        return (1)
    end

    # Return true if a = 0
    func is_zero{range_check_ptr}(a : Uint384) -> (res : felt):
        let (is_a_zero) = eq(a, Uint384(0, 0, 0))
        if is_a_zero == 1:
            return (1)
        else:
            return (0)
        end
    end

    # Computes the bitwise XOR of 2 uint256 integers.
    func xor{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(a : Uint384, b : Uint384) -> (
            res : Uint384):
        let (d0) = bitwise_xor(a.d0, b.d0)
        let (d1) = bitwise_xor(a.d1, b.d1)
        let (d2) = bitwise_xor(a.d2, b.d2)
        return (Uint384(d0, d1, d2))
    end

    # Computes the bitwise AND of 2 uint384 integers.
    # NOTE: `and` will be a reserved word in future Cairo versions, so we cannot call this function `and`
    func bit_and{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(a : Uint384, b : Uint384) -> (
            res : Uint384):
        let (d0) = bitwise_and(a.d0, b.d0)
        let (d1) = bitwise_and(a.d1, b.d1)
        let (d2) = bitwise_and(a.d2, b.d2)
        return (Uint384(d0, d1, d2))
    end

    # Computes the bitwise OR of 2 uint384 integers.
    func or{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(a : Uint384, b : Uint384) -> (
            res : Uint384):
        let (d0) = bitwise_or(a.d0, b.d0)
        let (d1) = bitwise_or(a.d1, b.d1)
        let (d2) = bitwise_or(a.d2, b.d2)
        return (Uint384(d0, d1, d2))
    end

    # Computes 2**exp % 2**384 as a uint384 integer.
    func pow2{range_check_ptr}(exp : Uint384) -> (res : Uint384):
        # If exp >= 384, the result will be zero modulo 2**384.
        # We can hence assume that exp.d0 = exp.d1 = exp.d2 = 0
        let (res) = lt(exp, Uint384(384, 0, 0))
        if res == 0:
            return (Uint384(0, 0, 0))
        end

        let (res) = is_le(exp.d0, 127)
        if res != 0:
            let (x) = pow(2, exp.d0)
            return (Uint384(x, 0, 0))
        else:
            let (res) = is_le(exp.d0, 255)
            if res != 0:
                let (x) = pow(2, exp.d0 - 128)
                return (Uint384(0, x, 0))
            else:
                let (x) = pow(2, exp.d0 - 256)
                return (Uint384(0, 0, x))
            end
        end
    end

    # Computes the logical left shift of a uint384 integer.
    func shl{range_check_ptr}(a : Uint384, b : Uint384) -> (res : Uint384):
        let (c) = pow2(b)
        let (res, _) = mul(a, c)
        return (res)
    end

    # Computes the logical right shift of a uint384 integer.
    func shr{range_check_ptr}(a : Uint384, b : Uint384) -> (res : Uint384):
        let (c) = pow2(b)
        let (res, _) = unsigned_div_rem(a, c)
        return (res)
    end

    # Reverses byte endianness of a uint384 integer.
    func reverse_endian{bitwise_ptr : BitwiseBuiltin*}(num : Uint384) -> (res : Uint384):
        alloc_locals
        let (d0) = word_reverse_endian(num.d0)
        let (local d1) = word_reverse_endian(num.d1)
        let (d2) = word_reverse_endian(num.d2)

        return (res=Uint384(d0=d2, d1=d1, d2=d0))
    end
end

# Copied from Cairo's common library since for some reason I couldn't import it
func word_reverse_endian{bitwise_ptr : BitwiseBuiltin*}(word : felt) -> (res : felt):
    # Step 1.
    assert bitwise_ptr[0].x = word
    assert bitwise_ptr[0].y = 0x00ff00ff00ff00ff00ff00ff00ff00ff
    tempvar word = word + (2 ** 16 - 1) * bitwise_ptr[0].x_and_y
    # Step 2.
    assert bitwise_ptr[1].x = word
    assert bitwise_ptr[1].y = 0x00ffff0000ffff0000ffff0000ffff00
    tempvar word = word + (2 ** 32 - 1) * bitwise_ptr[1].x_and_y
    # Step 3.
    assert bitwise_ptr[2].x = word
    assert bitwise_ptr[2].y = 0x00ffffffff00000000ffffffff000000
    tempvar word = word + (2 ** 64 - 1) * bitwise_ptr[2].x_and_y
    # Step 4.
    assert bitwise_ptr[3].x = word
    assert bitwise_ptr[3].y = 0x00ffffffffffffffff00000000000000
    tempvar word = word + (2 ** 128 - 1) * bitwise_ptr[3].x_and_y

    let bitwise_ptr = bitwise_ptr + 4 * BitwiseBuiltin.SIZE
    return (res=word / 2 ** (8 + 16 + 32 + 64))
end
