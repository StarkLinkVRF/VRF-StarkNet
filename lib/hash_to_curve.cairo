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
from starkware.cairo.common.math import unsigned_div_rem, split_felt
from starkware.cairo.common.hash import hash2

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


func get_pedersen_hash{range_check_ptr, pedersen_ptr : HashBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : felt, ctr : felt) -> (res : felt):
    let (hash) = hash2{hash_ptr=pedersen_ptr}(suite_string, public_key.x.d0)
    let (hash) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.x.d1)
    let (hash) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.x.d2)
    let (hash) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.y.d0)
    let (hash) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.y.d1)
    let (hash) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.y.d2)
    let (hash) = hash2{hash_ptr=pedersen_ptr}(hash, alpha)
    let (hash) = hash2{hash_ptr=pedersen_ptr}(hash, ctr)

    return (hash)
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

func arbitrary_string_to_point{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(hash : felt) -> (
        success : felt, res : EcPoint):
    alloc_locals
    # Appends two at 256 bit
    let (high, low) = split_felt(hash)
    let x_p = Uint384(d0=low, d1=high, d2=0)

    let (secp_modulus) = get_secp_modulus()
    let (x_cubed) = field_arithmetic_lib.pow(x_p, Uint384(d0=3, d1=0, d2=0), secp_modulus)
    let (alpha) = field_arithmetic_lib.add(x_cubed, Uint384(d0=7, d1=0, d2=0), secp_modulus)

    let generator = Uint384(5, 0, 0)
    let (success, beta) = field_arithmetic_lib.get_square_root(alpha, secp_modulus, generator)

    if success == 1:
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

func try_and_increment{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : felt, ctrl : felt) -> (
        point_on_curve : EcPoint):
    alloc_locals

    let (h_message : felt) = get_pedersen_hash(suite_string, public_key, alpha, ctrl)
    
    let (success, res) = arbitrary_string_to_point(h_message)

    if success == 1:
        return (res)
    end

    let (res) = try_and_increment(suite_string, public_key, alpha, ctrl + 1)

    return (res)
end

func hash_to_curve{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : felt) -> (point_on_curve : EcPoint):
    alloc_locals

    let (res) = try_and_increment(suite_string, public_key, alpha, 0)
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
