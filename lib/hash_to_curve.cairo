from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256, split_64, uint256_xor, word_reverse_endian, uint256_reverse_endian)

from lib.uint384 import Uint384, uint384_lib
from lib.uint384_extension import Uint768

from starkware.cairo.common.cairo_secp.ec import EcPoint
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.cairo_keccak.keccak import (
    keccak_bigend, keccak, finalize_keccak, keccak_add_uint256)
from lib.field_arithmetic import field_arithmetic_lib
from starkware.cairo.common.alloc import alloc
from lib.uint384_extension import uint384_extension_lib
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import unsigned_div_rem

func get_secp_modulus() -> (secp_modulus : Uint384): 
    return (
        secp_modulus=Uint384(
        d0=340282366920938463463374607427473243183,
        d1=340282366920938463463374607431768211455,
        d2=0
        ))
end

# compute octets one || two || three || four as a little endian 64 bit number
func octets_to_64_bits_little_indian(one : felt, two : felt, three : felt, four : felt) -> (
        res : felt):
    return (res=four * 2 ** 32 + three * 2 ** 16 + two * 2 ** 8 + one)
end

func octets_to_64_bits(one : felt, two : felt, three : felt, four : felt) -> (res : felt):
    return (res=one * 2 ** 32 + two * 2 ** 16 + three * 2 ** 8 + four)
end

func bits64_to_uint256(one : felt, two : felt, three : felt, four : felt) -> (res : Uint256):
    return (res=Uint256(low=one + two * 2 ** 64, high=three + four * 2 ** 64))
end

const thirty_two_bits = 2 ** 32
func split_64_bits{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(in : felt) -> (
        five_bytes : felt, three_bytes):
    alloc_locals
    let (first_four_bytes, _) = unsigned_div_rem(in, thirty_two_bits)
    let (second_four_bytes) = bitwise_and(in, thirty_two_bits - 1)
    return (first_four_bytes, second_four_bytes)
end

func split_128_bits{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(in : felt) -> (
        five_bytes : felt, three_bytes):
    alloc_locals
    let (four_bytes) = bitwise_and(in, thirty_two_bits - 1)
    let (twelve_bytes, _) = unsigned_div_rem(in, thirty_two_bits)
    return (twelve_bytes, four_bytes)
end

func hash_inputs{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, keccak_ptr : felt*}(
        suite_string : felt, public_key : EcPoint, alpha : Uint256, ctr : felt) -> (res : Uint256):
    alloc_locals
    let (y_as_uint384) = bigint3_to_uint384(public_key.y)
    let (_, y_mod_2) = uint384_lib.unsigned_div_rem(y_as_uint384, Uint384(d0=2, d1=0, d2=0))

    let y_octet = y_mod_2.d0 + 2

    let (pk_string_one : felt, pk_string_two : felt, pk_string_three : felt, pk_string_four : felt,
        pk_string_five : felt, pk_string_six : felt) = BigInt3_to_64bit(public_key.x)

    let one_string = 1

    let h_string : felt* = alloc()

    # h_string = Hash(suite_string || one_string || PK_string ||alpha_string)

    let (str_two_five_bytes, str_two_three_bytes) = split_64_bits(pk_string_four)
    let (str_three_five_bytes, str_three_three_bytes) = split_64_bits(pk_string_three)

    # TODO remove pk_string_one, it will always be zero!
    # pk_string_one is one byte long
    # each 64 bit segment is split into (3 and 5 bytes) and then are recombined
    # suite_string || one_string || y_octet || pk_string_first_byte || five_bytes_pk_string_two| three_bytes_pk_string_two || five_bytes_pk_string_three...
    let first_64_bits = str_two_five_bytes + pk_string_one * 2 ** 32 + y_octet * 2 ** 40 + one_string * 2 ** 48 + suite_string * 2 ** 56
    let second_64_bits = str_three_five_bytes + str_two_three_bytes * 2 ** 32

    let p1 = first_64_bits * 2 ** 64 + second_64_bits

    let (str_five_five_bytes, str_five_three_bytes) = split_64_bits(pk_string_five)
    let (str_six_five_bytes, str_six_three_bytes) = split_64_bits(pk_string_six)

    let third_64_bits = str_five_five_bytes + str_three_three_bytes * 2 ** 32
    let fourth_64_bits = str_six_five_bytes + str_five_three_bytes * 2 ** 32

    let p2 = third_64_bits * 2 ** 64 + fourth_64_bits

    let (alpha_high_thirteen_bytes, alpha_high_three_bytes) = split_128_bits(alpha.high)

    let p3 = alpha_high_thirteen_bytes + str_six_three_bytes * 2 ** 96

    let (alpha_low_thirteen_bytes, alpha_low_three_bytes) = split_128_bits(alpha.low)

    let p4 = alpha_low_thirteen_bytes + alpha_high_three_bytes * 2 ** 96

    let p5 = ctr + alpha_low_three_bytes * 2 ** 8

    let (p1_reverse) = word_reverse_endian(p1)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 64)
    assert [h_string] = p1_1
    assert [h_string + 1] = p1_2

    let (p2_reverse) = word_reverse_endian(p2)
    let (p2_2, p2_1) = unsigned_div_rem(p2_reverse, 2 ** 64)
    assert [h_string + 2] = p2_1
    assert [h_string + 3] = p2_2

    let (p3_reverse) = word_reverse_endian(p3)
    let (p3_2, p3_1) = unsigned_div_rem(p3_reverse, 2 ** 64)
    assert [h_string + 4] = p3_1
    assert [h_string + 5] = p3_2

    let (p4_reverse) = word_reverse_endian(p4)
    let (p4_2, p4_1) = unsigned_div_rem(p4_reverse, 2 ** 64)
    assert [h_string + 6] = p4_1
    assert [h_string + 7] = p4_2

    let (p5_reverse) = word_reverse_endian(p5)
    let (p5_2, p5_1) = unsigned_div_rem(p5_reverse, 2 ** 88)
    assert [h_string + 8] = p5_2

    let (h_string_final : Uint256) = keccak{keccak_ptr=keccak_ptr}(inputs=h_string, n_bytes=69)

    let (big_end_h_string : Uint256) = uint256_reverse_endian(h_string_final)
    return (big_end_h_string)
end

const gx1 = 17117865558768631194064792
const gx2 = 12501176021340589225372855
const gx3 = 9198697782662356105779718

const gy1 = 6441780312434748884571320
const gy2 = 57953919405111227542741658
const gy3 = 5457536640262350763842127

func get_generator() -> (res : EcPoint):
    return (res=EcPoint(x=BigInt3(d0=gx1, d1=gx2, d2=gx3), y=BigInt3(d0=gy1, d1=gy2, d2=gy3)))
end

func arbitrary_string_to_point{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(hash : Uint256) -> (
        success : felt, res : EcPoint):
    alloc_locals
    # Appends two at 256 bit
    let x_p = Uint384(d0=hash.low, d1=hash.high, d2=0)

    let (secp_modulus) = get_secp_modulus()
    let (x_cubed) = field_arithmetic_lib.pow(x_p, Uint384(d0=3, d1=0, d2=0), secp_modulus)
    let (alpha) = field_arithmetic_lib.add(x_cubed, Uint384(d0=7, d1=0, d2=0), secp_modulus)

    let generator = Uint384(5, 0, 0)
    let (success, beta) = field_arithmetic_lib.get_square_root(alpha, secp_modulus, generator)

    if success == 1:
        # let (beta_is_zero) = uint384_lib.eq(beta, Uint384(d0=0,d1=0,d2=0))

        # if beta_is_zero == 1:
        #    return (success=1, res=EcPoint(x=x, y=beta))
        # end
        # let (secp_modulus) = get_secp_modulus()
        # let (y) = uint384_lib.sub(secp_modulus, beta)
        let (_, beta_is_odd) = uint384_lib.unsigned_div_rem(beta, Uint384(d0=2, d1=0, d2=0))

        if beta_is_odd.d0 == 1:
            let (secp_modulus) = get_secp_modulus()
            let (y) = uint384_lib.sub(secp_modulus, beta)
            let (x_bigint3) = uint384_to_bigint3(x_p)
            let (y_bigint3) = uint384_to_bigint3(y)
            return (success=1, res=EcPoint(x=x_bigint3, y=y_bigint3))
        else:
            let (x_bigint3) = uint384_to_bigint3(x_p)
            let (y_bigint3) = uint384_to_bigint3(beta)
            return (success=1, res=EcPoint(x=x_bigint3, y=y_bigint3))
        end
    end

    return (success=0, res=EcPoint(x=BigInt3(d0=0, d1=0, d2=0), y=BigInt3(d0=0, d1=0, d2=0)))
end

const bigint3_base = 2 ** 86
const mask_shift = 2 ** 42
const d1_shift = 2 ** 44
const d2_shift = 2 ** 84

func bigint3_to_uint384{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(in : BigInt3) -> (
        out : Uint384):
    alloc_locals

    let (bottom_d1 : felt) = bitwise_and(in.d1, mask_shift - 1)
    let d0 = in.d0 + bottom_d1 * bigint3_base

    let (top_d1, _) = unsigned_div_rem(in.d1, mask_shift)

    let (d1_part_two) = bitwise_and(in.d2, d2_shift - 1)

    let d1 = top_d1 + d1_part_two * d1_shift

    let (d2_shifted, _) = unsigned_div_rem(in.d2, d2_shift)

    return (Uint384(d0=d0, d1=d1, d2=d2_shifted))
end

# Truncates bits, use only if field_modulus of previous field arithmatic ops is <= 258bits
func uint384_to_bigint3{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(in : Uint384) -> (
        out : BigInt3):
    alloc_locals

    let (d0) = bitwise_and(in.d0, bigint3_base - 1)
    let (bottom_d1, _) = unsigned_div_rem(in.d0, bigint3_base)

    let (top_d1) = bitwise_and(in.d1, d1_shift - 1)

    let d1 = bottom_d1 + top_d1 * mask_shift

    let (bottom_d2, _) = unsigned_div_rem(in.d1, d1_shift)

    let d2 = bottom_d2 + in.d2 * (2 ** 84)
    return (BigInt3(d0=d0, d1=d1, d2=d2))
end

func uint256ToUint384(in : Uint256) -> (out : Uint384):
    return (out=Uint384(d0=in.high, d1=in.low, d2=0))
end

func try_and_increment{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, keccak_ptr : felt*}(
        suite_string : felt, public_key : EcPoint, alpha : Uint256, ctrl : felt) -> (
        point_on_curve : EcPoint):
    alloc_locals

    let (h_message) = hash_inputs{keccak_ptr=keccak_ptr}(suite_string, public_key, alpha, ctrl)
    let (success, res) = arbitrary_string_to_point(h_message)

    if success == 1:
        return (res)
    end

    let (res) = try_and_increment{keccak_ptr=keccak_ptr}(suite_string, public_key, alpha, ctrl + 1)

    return (res)
end

func hash_to_curve{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : Uint256) -> (point_on_curve : EcPoint):
    alloc_locals

    let (local keccak_ptr_start) = alloc()
    let keccak_ptr = keccak_ptr_start

    let (res) = try_and_increment{keccak_ptr=keccak_ptr}(suite_string, public_key, alpha, 0)
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)
    return (res)
end

func BigInt3_to_64bit{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(input : BigInt3) -> (
        one : felt, two : felt, three : felt, four : felt, five : felt, six : felt):
    alloc_locals

    let (as_uint384) = bigint3_to_uint384(input)

    let (lowest : felt, second_lowest : felt) = split_64(as_uint384.d0)
    let (fourth_highest : felt, third_highest : felt) = split_64(as_uint384.d1)
    let (second_highest : felt, highest : felt) = split_64(as_uint384.d2)

    return (
        one=second_highest,
        two=highest,
        three=fourth_highest,
        four=third_highest,
        five=second_lowest,
        six=lowest)
end
