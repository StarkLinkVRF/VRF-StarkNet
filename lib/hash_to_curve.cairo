from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256, split_64, uint256_xor

from lib.uint384 import Uint384, uint384_lib
from lib.uint384_extension import Uint768

from starkware.cairo.common.cairo_secp.ec import EcPoint
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.cairo_keccak.keccak import keccak_bigend, keccak, finalize_keccak
from lib.field_arithmetic import field_arithmetic_lib
from starkware.cairo.common.alloc import alloc
from lib.uint384_extension import uint384_extension_lib

func get_secp_modulus() -> (secp_modulus : Uint384):
    return (
        secp_modulus=Uint384(
        d0=248144347276217270074328348468568277313,
        d1=340282366920938463463374607431768211454,
        d2=0
        ))
end

func hash_inputs{keccak_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : felt) -> (res : Uint256):
    alloc_locals

    # TODO is y in there?

    let (pk_string_one : felt, pk_string_two : felt, pk_string_three : felt, pk_string_four : felt,
        pk_string_five : felt, pk_string_six : felt) = BigInt3_to_64bit(public_key.x)

    let one_string = 1

    let (local keccak_ptr_start) = alloc()
    let keccak_ptr = keccak_ptr_start

    let h_string : felt* = alloc()

    # h_string = Hash(suite_string || one_string || PK_string ||alpha_string)
    assert [h_string] = suite_string
    assert [h_string + 1] = one_string
    assert [h_string + 2] = pk_string_one
    assert [h_string + 3] = pk_string_two
    assert [h_string + 4] = pk_string_three
    assert [h_string + 5] = pk_string_four
    assert [h_string + 6] = pk_string_five
    assert [h_string + 7] = pk_string_six
    assert [h_string + 8] = alpha

    let (h_string_final : Uint256) = keccak{keccak_ptr=keccak_ptr}(inputs=h_string, n_bytes=36)
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)
    return (h_string_final)
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

func arbitrary_string_to_point{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        hash : Uint256, n : felt) -> (success : felt, res : EcPoint):
    alloc_locals
    let two = 2
    let x_p = Uint384(d0=hash.high, d1=hash.low, d2=0)

    let (secp_modulus) = get_secp_modulus()
    let (x_cubed) = field_arithmetic_lib.pow(x_p, Uint384(d0=3, d1=0, d2=0), secp_modulus)
    let (alpha) = field_arithmetic_lib.add(x_cubed, Uint384(d0=7, d1=0, d2=0), secp_modulus)

    let generator = Uint384(2, 0, 0)
    let (success, beta) = field_arithmetic_lib.get_square_root(alpha, secp_modulus, generator)
    if success == 1:
        # let (beta_is_zero) = uint384_lib.eq(beta, Uint384(d0=0,d1=0,d2=0))

        # if beta_is_zero == 1:
        #    return (success=1, res=EcPoint(x=x, y=beta))
        # end

        let (y) = uint384_lib.sub(x_p, beta)

        return (success=1, res=EcPoint(x=x_p, y=y))
    end

    return (success=0, res=EcPoint(x=BigInt3(d0=0, d1=0, d2=0), y=BigInt3(d0=0, d1=0, d2=0)))
end

const thirst_two_bits = ((2 ** 32) - 1)
const last_thirst_two_bits = ((2 ** 32) - 1)
# Truncates bits, use only if field_modulus of previous field arithmatic ops is <= 258bits
func bigint3_to_uint384(in : BigInt3) -> (out : Uint384):
    alloc_locals

    let limb_one = bitwise_and(in.d1, thirst_two_bits)
end

func uint256ToUint384(in : Uint256) -> (out : Uint384):
    return (out=Uint384(d0=in.high, d1=in.low, d2=0))
end

func try_and_increment{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : felt, ctrl : felt) -> (
        point_on_curve : EcPoint):
    alloc_locals

    let (h_message) = hash_inputs(suite_string, public_key, alpha)
    let (success, res) = arbitrary_string_to_point(h_message, alpha, ctrl)

    if success == 1:
        return (res)
    end

    let (res) = try_and_increment(suite_string, public_key, alpha, ctrl + 1)

    return (res)
end

func hash_to_curve{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        suite_string : felt, public_key : EcPoint, alpha : felt) -> (point_on_curve : EcPoint):
    alloc_locals

    let (res) = try_and_increment(suite_string, public_key, alpha, 1)

    return (res)
end

func BigInt3_to_64bit{range_check_ptr}(input : BigInt3) -> (
        one : felt, two : felt, three : felt, four : felt, five : felt, six : felt):
    alloc_locals

    let (lowest : felt, second_lowest : felt) = split_64(input.d0)
    let (fourth_highest : felt, third_highest : felt) = split_64(input.d1)
    let (second_highest : felt, highest : felt) = split_64(input.d2)

    return (
        one=second_highest,
        two=highest,
        three=fourth_highest,
        four=third_highest,
        five=second_lowest,
        six=lowest)
end

func hash_points{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        H : EcPoint, Gamma : EcPoint, U : EcPoint, V : EcPoint) -> (res : Uint256):
    alloc_locals

    let two = 2
    return (res=Uint256(low=0, high=0))
end
