# @dev Tested in https://github.com/0xNonCents/cairo-hash-tests

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, split_64, uint256_xor
from starkware.cairo.common.cairo_keccak.keccak import keccak_bigend, keccak, finalize_keccak

func Uint256_to_64bit{range_check_ptr}(input : Uint256) -> (
        one : felt, two : felt, three : felt, four : felt):
    alloc_locals

    let (lowest : felt, second_lowest : felt) = split_64(input.high)
    let (second_highest : felt, highest : felt) = split_64(input.low)

    return (one=second_highest, two=highest, three=lowest, four=second_lowest)
end

func hash_b_i{keccak_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        b_0 : Uint256, prev_b_i : Uint256, index : felt) -> (b_i : Uint256):
    alloc_locals
    let (temp : Uint256) = uint256_xor(a=b_0, b=prev_b_i)

    let (xor_first, xor_second, xor_third, xor_fourth) = Uint256_to_64bit(temp)
    let b_i : felt* = alloc()
    assert [b_i] = xor_first
    assert [b_i + 1] = xor_second
    assert [b_i + 2] = xor_third
    assert [b_i + 3] = xor_fourth
    assert [b_i + 4] = 5136728518877266433 + index
    assert [b_i + 5] = 4049635677368500831
    assert [b_i + 6] = 4198565794565736241
    assert [b_i + 7] = 6860729571969419347
    assert [b_i + 8] = 6867798526170452819
    assert [b_i + 9] = 186282431822

    let (b_i_final) = keccak{keccak_ptr=keccak_ptr}(inputs=b_i, n_bytes=77)

    return (b_i_final)
end

# follows hash_to_fp_XMDSHA256 except we use keccak pending a SHA256 builtin
# expects msg to be big endian
func expand_msg_sha_xmd{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(msg : Uint256) -> (
        one : Uint256, two : Uint256, three : Uint256, four : Uint256):
    # inputs
    # # msg of bytes, 32 byte string
    # # domain, string such as "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_"
    # # count, 4

    # expand message via SHA256XMD,
    alloc_locals
    let (local keccak_ptr_start) = alloc()
    let keccak_ptr = keccak_ptr_start

    let (first, second, third, fourth) = Uint256_to_64bit(msg)
    let b_0 : felt* = alloc()

    # b_0 = H(Z_pad || msg || l_i_b_str || I2OSP(0, 1) || DST_prime)
    assert [b_0] = 0
    assert [b_0 + 1] = 0
    assert [b_0 + 2] = 0
    assert [b_0 + 3] = 0
    assert [b_0 + 4] = 0
    assert [b_0 + 5] = 0
    assert [b_0 + 6] = 0
    assert [b_0 + 7] = 0
    assert [b_0 + 8] = first
    assert [b_0 + 9] = second
    assert [b_0 + 10] = third
    assert [b_0 + 11] = fourth
    assert [b_0 + 12] = 6007612014925447169
    assert [b_0 + 13] = 3616763562751379273
    assert [b_0 + 14] = 5573309208418400307
    assert [b_0 + 15] = 3833175991255251524
    assert [b_0 + 16] = 5935556667446091574
    assert [b_0 + 17] = 12208205451910991

    # append bytes to final string based on desired length, can be fixed for our purposes
    let (b_0_final) = keccak{keccak_ptr=keccak_ptr}(inputs=b_0, n_bytes=143)

    # b_1 = H(b_0 || I2OSP(1, 1) || DST_prime)
    let (b_0_first, b_0_second, b_0_third, b_0_fourth) = Uint256_to_64bit(b_0_final)
    let b_1 : felt* = alloc()

    assert [b_1] = b_0_first
    assert [b_1 + 1] = b_0_second
    assert [b_1 + 2] = b_0_third
    assert [b_1 + 3] = b_0_fourth
    assert [b_1 + 4] = 5136728518877266433
    assert [b_1 + 5] = 4049635677368500831
    assert [b_1 + 6] = 4198565794565736241
    assert [b_1 + 7] = 6860729571969419347
    assert [b_1 + 8] = 6867798526170452819
    assert [b_1 + 9] = 186282431822

    let (b_1_final) = keccak{keccak_ptr=keccak_ptr}(inputs=b_1, n_bytes=77)

    # b_i = H(strxor(b_0, b_(i - 1)) || I2OSP(i, 1) || DST_prime)

    let (b_i_0 : Uint256) = hash_b_i{keccak_ptr=keccak_ptr}(
        b_0=b_0_final, prev_b_i=b_1_final, index=0)
    let (b_i_1 : Uint256) = hash_b_i{keccak_ptr=keccak_ptr}(b_0=b_0_final, prev_b_i=b_i_0, index=1)
    let (b_i_2 : Uint256) = hash_b_i{keccak_ptr=keccak_ptr}(b_0=b_0_final, prev_b_i=b_i_1, index=2)

    # Call finalize once at the end to verify the soundness of the execution
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)

    return (b_1_final, b_i_0, b_i_1, b_i_2)
end
