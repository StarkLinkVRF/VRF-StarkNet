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
from lib.hash_to_curve import bigint3_to_uint384, BigInt3_to_64bit, split_64_bits

const eight_bits_shift = 2 ** 8
const first_shift = 2 ** 24
const second_shift = first_shift * eight_bits_shift
const third_shift = second_shift * eight_bits_shift
const fourth_shift = third_shift * eight_bits_shift

const first_pad = 40
const second_pad = first_pad - 8
const third_pad = second_pad - 8
const fourth_pad = third_pad - 8
func point_to_string_inner_split_seven_one{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        in : felt) -> (first_bytes : felt, last_byte):
    alloc_locals
    let (first_seven_bytes, _) = unsigned_div_rem(in, first_shift)
    let (last_byte) = bitwise_and(in, first_shift - 1)
    return (first_seven_bytes, last_byte)
end

func point_to_string_one{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(point : EcPoint) -> (
        p1 : felt, p2 : felt, leftover_byte : felt):
    alloc_locals

    let two_string = 2
    let suite_string = 254
    let (y_as_uint384) = bigint3_to_uint384(point.y)
    let (_, y_mod_2) = uint384_lib.unsigned_div_rem(y_as_uint384, Uint384(d0=2, d1=0, d2=0))

    let y_octet = y_mod_2.d0 + 2

    let (pk_string_one : felt, pk_string_two : felt, pk_string_three : felt, pk_string_four : felt,
        pk_string_five : felt, pk_string_six : felt) = BigInt3_to_64bit(point.x)

    let (str_two_seven_bytes, str_two_last_byte) = point_to_string_inner_split_seven_one(
        pk_string_four)
    let (str_three_seven_bytes, str_three_last_byte) = point_to_string_inner_split_seven_one(
        pk_string_three)

    let first_64_bits = str_two_seven_bytes + y_octet * 2 ** 40 + two_string * 2 ** 48 + suite_string * 2 ** 56
    let second_64_bits = str_three_seven_bytes + str_two_last_byte * 2 ** 40

    let p1 = first_64_bits * 2 ** 64 + second_64_bits

    let (str_five_seven_bytes, str_five_last_byte) = point_to_string_inner_split_seven_one(
        pk_string_five)
    let (str_six_seven_bytes, str_six_last_byte) = point_to_string_inner_split_seven_one(
        pk_string_six)

    let third_64_bits = str_five_seven_bytes + str_three_last_byte * 2 ** 40
    let fourth_64_bits = str_six_seven_bytes + str_five_last_byte * 2 ** 40

    let p2 = third_64_bits * 2 ** 64 + fourth_64_bits

    return (p1, p2, str_six_last_byte)
end

func point_to_string_inner_split_six_two{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        in : felt) -> (first_bytes : felt, last_byte):
    alloc_locals
    let (first_seven_bytes, _) = unsigned_div_rem(in, second_shift)
    let (last_byte) = bitwise_and(in, second_shift - 1)
    return (first_seven_bytes, last_byte)
end

func point_to_string_two{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        in_byte : felt, point : EcPoint) -> (p1 : felt, p2 : felt, leftover_bytes : felt):
    alloc_locals
    let (y_as_uint384) = bigint3_to_uint384(point.y)
    let (_, y_mod_2) = uint384_lib.unsigned_div_rem(y_as_uint384, Uint384(d0=2, d1=0, d2=0))

    let y_octet = y_mod_2.d0 + 2

    let (pk_string_one : felt, pk_string_two : felt, pk_string_three : felt, pk_string_four : felt,
        pk_string_five : felt, pk_string_six : felt) = BigInt3_to_64bit(point.x)

    let (str_two_six_bytes, str_two_two_bytes) = point_to_string_inner_split_six_two(pk_string_four)
    let (str_three_six_bytes, str_three_two_bytes) = point_to_string_inner_split_six_two(
        pk_string_three)

    let first_64_bits = str_two_six_bytes + y_octet * 2 ** 32 + in_byte * 2 ** 40
    let second_64_bits = str_three_six_bytes + str_two_two_bytes * 2 ** 32

    let p1 = first_64_bits * 2 ** 64 + second_64_bits

    let (str_five_six_bytes, str_five_two_bytes) = point_to_string_inner_split_six_two(
        pk_string_five)
    let (str_six_six_bytes, str_six_two_bytes) = point_to_string_inner_split_six_two(pk_string_six)

    let third_64_bits = str_five_six_bytes + str_three_two_bytes * 2 ** 32
    let fourth_64_bits = str_six_six_bytes + str_five_two_bytes * 2 ** 32

    let p2 = third_64_bits * 2 ** 64 + fourth_64_bits

    return (p1, p2, str_six_two_bytes)
end

func point_to_string_inner_split_five_three{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        in : felt) -> (first_bytes : felt, last_byte):
    alloc_locals
    let (first_five_bytes, _) = unsigned_div_rem(in, third_shift)
    let (last_three_byte) = bitwise_and(in, third_shift - 1)
    return (first_five_bytes, last_three_byte)
end

func point_to_string_three{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        in_bytes : felt, point : EcPoint) -> (p1 : felt, p2 : felt, leftover_bytes : felt):
    alloc_locals
    let (y_as_uint384) = bigint3_to_uint384(point.y)
    let (_, y_mod_2) = uint384_lib.unsigned_div_rem(y_as_uint384, Uint384(d0=2, d1=0, d2=0))

    let y_octet = y_mod_2.d0 + 2

    let (pk_string_one : felt, pk_string_two : felt, pk_string_three : felt, pk_string_four : felt,
        pk_string_five : felt, pk_string_six : felt) = BigInt3_to_64bit(point.x)

    let (str_two_five_bytes, str_two_three_bytes) = point_to_string_inner_split_five_three(
        pk_string_four)
    let (str_three_five_bytes, str_three_three_bytes) = point_to_string_inner_split_five_three(
        pk_string_three)

    let first_64_bits = str_two_five_bytes + y_octet * 2 ** 24 + in_bytes * 2 ** 32
    let second_64_bits = str_three_five_bytes + str_two_three_bytes * 2 ** 24

    let p1 = first_64_bits * 2 ** 64 + second_64_bits

    let (str_five_five_bytes, str_five_three_bytes) = point_to_string_inner_split_five_three(
        pk_string_five)
    let (str_six_five_bytes, str_six_three_bytes) = point_to_string_inner_split_five_three(
        pk_string_six)

    let third_64_bits = str_five_five_bytes + str_three_three_bytes * 2 ** 24
    let fourth_64_bits = str_six_five_bytes + str_five_three_bytes * 2 ** 24

    let p2 = third_64_bits * 2 ** 64 + fourth_64_bits

    return (p1, p2, str_six_three_bytes)
end

func point_to_string_inner_split_five_four{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        in : felt) -> (first_bytes : felt, last_byte):
    alloc_locals
    let (first_five_bytes, _) = unsigned_div_rem(in, fourth_shift)
    let (last_three_byte) = bitwise_and(in, fourth_shift - 1)
    return (first_five_bytes, last_three_byte)
end

func point_to_string_four{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        in_bytes : felt, point : EcPoint) -> (p1 : felt, p2 : felt, leftover_bytes : felt):
    alloc_locals
    let (y_as_uint384) = bigint3_to_uint384(point.y)
    let (_, y_mod_2) = uint384_lib.unsigned_div_rem(y_as_uint384, Uint384(d0=2, d1=0, d2=0))

    let y_octet = y_mod_2.d0 + 2

    let (pk_string_one : felt, pk_string_two : felt, pk_string_three : felt, pk_string_four : felt,
        pk_string_five : felt, pk_string_six : felt) = BigInt3_to_64bit(point.x)

    let (str_two_five_bytes, str_two_three_bytes) = point_to_string_inner_split_five_four(
        pk_string_four)
    let (str_three_five_bytes, str_three_three_bytes) = point_to_string_inner_split_five_four(
        pk_string_three)

    let first_64_bits = str_two_five_bytes + y_octet * 2 ** 16 + in_bytes * 2 ** 24
    let second_64_bits = str_three_five_bytes + str_two_three_bytes * 2 ** 16

    let p1 = first_64_bits * 2 ** 64 + second_64_bits

    let (str_five_five_bytes, str_five_three_bytes) = point_to_string_inner_split_five_four(
        pk_string_five)
    let (str_six_five_bytes, str_six_three_bytes) = point_to_string_inner_split_five_four(
        pk_string_six)

    let third_64_bits = str_five_five_bytes + str_three_three_bytes * 2 ** 16
    let fourth_64_bits = str_six_five_bytes + str_five_three_bytes * 2 ** 16

    let p2 = third_64_bits * 2 ** 64 + fourth_64_bits

    return (p1, p2, str_six_three_bytes)
end

func hash_points{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        H : EcPoint, Gamma : EcPoint, U : EcPoint, V : EcPoint) -> (res : Uint256):
    alloc_locals

    let cipher = 254
    let two = 2

    let (p1, p2, b1) = point_to_string_one(H)
    let (p3, p4, b2) = point_to_string_two(b1, Gamma)
    let (p5, p6, b3) = point_to_string_three(b2, U)
    let (p7, p8, b4) = point_to_string_four(b3, V)

    let (local keccak_ptr_start) = alloc()
    let keccak_ptr = keccak_ptr_start

    let h_string : felt* = alloc()

    let (p1_reverse) = word_reverse_endian(p1)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 64)

    %{
        def pack256(z, num_bits_shift: int = 128 ) -> int:
            limbs = (z.low, z.high)
            return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))
        print('p1 ... p8')
        print(hex(ids.p1))
        print(hex(ids.p2))
        print(hex(ids.p3))
        print(hex(ids.p4))
        print(hex(ids.p5))
        print(hex(ids.p6))
        print(hex(ids.p7))
        print(hex(ids.p8))
        print(hex(ids.b4))

        string = hex(ids.p1)[2:] + hex(ids.p2)[2:] + hex(ids.p3)[2:] + hex(ids.p4)[2:] + hex(ids.p5)[2:] + hex(ids.p6)[2:] + hex(ids.p7)[2:] + hex(ids.p8)[2:] + hex(ids.b4)[2:] 
        print("hex string input", string)
    %}
    assert [h_string] = p1_1
    assert [h_string + 1] = p1_2

    let (p1_reverse) = word_reverse_endian(p2)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 64)
    assert [h_string + 2] = p1_1
    assert [h_string + 3] = p1_2

    let (p1_reverse) = word_reverse_endian(p3)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 64)
    assert [h_string + 4] = p1_1
    assert [h_string + 5] = p1_2

    let (p1_reverse) = word_reverse_endian(p4)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 64)
    assert [h_string + 6] = p1_1
    assert [h_string + 7] = p1_2

    let (p1_reverse) = word_reverse_endian(p5)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 64)
    assert [h_string + 8] = p1_1
    assert [h_string + 9] = p1_2

    let (p1_reverse) = word_reverse_endian(p6)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 64)
    assert [h_string + 10] = p1_1
    assert [h_string + 11] = p1_2

    let (p1_reverse) = word_reverse_endian(p7)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 64)
    assert [h_string + 12] = p1_1
    assert [h_string + 13] = p1_2

    let (p1_reverse) = word_reverse_endian(p8)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 64)
    assert [h_string + 14] = p1_1
    assert [h_string + 15] = p1_2

    let (p1_reverse) = word_reverse_endian(b4)
    let (p1_2, p1_1) = unsigned_div_rem(p1_reverse, 2 ** 80)

    %{ print( ids.p1_2) %}
    assert [h_string + 16] = p1_2

    let (h_string_final : Uint256) = keccak{keccak_ptr=keccak_ptr}(inputs=h_string, n_bytes=134)

    let (big_end_h_string : Uint256) = uint256_reverse_endian(h_string_final)
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)

    return (big_end_h_string)
end
