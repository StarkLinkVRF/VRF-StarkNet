# @Title 384bit-prime-field-arithmetic-cairo - https://github.com/NethermindEth/384bit-prime-field-arithmetic-cairo
# @Author Albert Garreta, 0xNonCents

from starkware.cairo.common.bitwise import bitwise_and, bitwise_or, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.math import assert_in_range, assert_le, assert_nn_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.pow import pow
from starkware.cairo.common.registers import get_ap, get_fp_and_pc
# Import uint384 files (path may change in the future)
from lib.uint384 import uint384_lib, Uint384, ALL_ONES

# Functions for operating 384-bit integers with 768-bit integers

# Represents an integer in the range [0, 2^768).
# NOTE: As in Uint256 and Uint384, all functions expect each d_0, d_1, ..., d_5 to be less than 2**128
struct Uint768:
    member d0 : felt
    member d1 : felt
    member d2 : felt
    member d3 : felt
    member d4 : felt
    member d5 : felt
end

namespace uint384_extension_lib:
    # Adds a 768-bit integer and a 384-bit integer. Returns the result as a 768-bit integer and the (1-bit) carry.
    func add_uint768_and_uint384{range_check_ptr}(a : Uint768, b : Uint384) -> (
            res : Uint768, carry : felt):
        alloc_locals

        let a_low = Uint384(d0=a.d0, d1=a.d1, d2=a.d2)
        let a_high = Uint384(d0=a.d3, d1=a.d4, d2=a.d5)

        let (sum_low, carry0) = uint384_lib.add(a_low, b)

        local res : Uint768

        res.d0 = sum_low.d0
        res.d1 = sum_low.d1
        res.d2 = sum_low.d2

        let (a_high_plus_carry, carry1) = uint384_lib.add(a_high, Uint384(carry0, 0, 0))

        res.d3 = a_high_plus_carry.d0
        res.d4 = a_high_plus_carry.d1
        res.d5 = a_high_plus_carry.d2

        return (res, carry1)
    end

    # Multiplies a 768-bit integer and a 384-bit integer.
    # Returns the result (1152 bits) as a 768-bit integer (the lower bits of the result) and
    # a 384-bit integer (the higher bits of the result)
    func mul_uint768_by_uint384{range_check_ptr}(a : Uint768, b : Uint384) -> (
            low : Uint768, high : Uint384):
        alloc_locals
        let a_low = Uint384(d0=a.d0, d1=a.d1, d2=a.d2)
        let a_high = Uint384(d0=a.d3, d1=a.d4, d2=a.d5)

        let (low_low, low_high) = uint384_lib.mul(a_low, b)
        let (high_low, high_high) = uint384_lib.mul(a_high, b)

        let (sum_low_high_and_high_low : Uint384, carry0 : felt) = uint384_lib.add(
            low_high, high_low)

        assert_le(carry0, 2)

        let (high_high_with_carry : Uint384, carry1 : felt) = uint384_lib.add(
            high_high, Uint384(carry0, 0, 0))
        assert carry1 = 0

        local res_low : Uint768
        local res_high : Uint384

        res_low.d0 = low_low.d0
        res_low.d1 = low_low.d1
        res_low.d2 = low_low.d2

        res_low.d3 = sum_low_high_and_high_low.d0
        res_low.d4 = sum_low_high_and_high_low.d1
        res_low.d5 = sum_low_high_and_high_low.d2

        res_high.d0 = high_high_with_carry.d0
        res_high.d1 = high_high_with_carry.d1
        res_high.d2 = high_high_with_carry.d2

        return (low=res_low, high=res_high)
    end

    # Unsigned integer division between a 768-bit integer and a 384-bit integer. Returns the quotient (768 bits) and the remainder (384 bits).
    # Conforms to EVM specifications: division by 0 yields 0.
    func unsigned_div_rem_uint768_by_uint384{range_check_ptr}(a : Uint768, div : Uint384) -> (
            quotient : Uint768, remainder : Uint384):
        alloc_locals
        local quotient : Uint768
        local remainder : Uint384

        # If div == 0, return (0, 0).
        if div.d0 + div.d1 + div.d2 == 0:
            return (quotient=Uint768(0, 0, 0, 0, 0, 0), remainder=Uint384(0, 0, 0))
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
                
            def pack_extended(z, num_bits_shift: int) -> int:
                limbs = (z.d0, z.d1, z.d2, z.d3, z.d4, z.d5)
                return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))

            a = pack_extended(ids.a, num_bits_shift = 128)
            div = pack(ids.div, num_bits_shift = 128)

            quotient, remainder = divmod(a, div)

            quotient_split = split(quotient, num_bits_shift=128, length=6)

            ids.quotient.d0 = quotient_split[0]
            ids.quotient.d1 = quotient_split[1]
            ids.quotient.d2 = quotient_split[2]
            ids.quotient.d3 = quotient_split[3]
            ids.quotient.d4 = quotient_split[4]
            ids.quotient.d5 = quotient_split[5]

            remainder_split = split(remainder, num_bits_shift=128, length=3)
            ids.remainder.d0 = remainder_split[0]
            ids.remainder.d1 = remainder_split[1]
            ids.remainder.d2 = remainder_split[2]
        %}

        return (quotient=quotient, remainder=remainder)
    end

    func eq{range_check_ptr}(a : Uint768, b : Uint768) -> (res : felt):
        if a.d5 != b.d5:
            return (0)
        end
        if a.d4 != b.d4:
            return (0)
        end
        if a.d3 != b.d3:
            return (0)
        end
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

    func bit_and{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(a : Uint768, b : Uint768) -> (
            res : Uint768):
        let (d0) = bitwise_and(a.d0, b.d0)
        let (d1) = bitwise_and(a.d1, b.d1)
        let (d2) = bitwise_and(a.d2, b.d2)
        let (d3) = bitwise_and(a.d3, b.d3)
        let (d4) = bitwise_and(a.d4, b.d4)
        let (d5) = bitwise_and(a.d5, b.d5)
        return (Uint768(d0, d1, d2, d3, d4, d5))
    end
end
