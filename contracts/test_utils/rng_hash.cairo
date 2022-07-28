%lang starknet

%builtins pedersen range_check bitwise

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash import hash2

from starkware.cairo.common.cairo_keccak.keccak import (
    keccak_bigend, keccak, finalize_keccak, keccak_add_uint256)
from starkware.cairo.common.alloc import alloc

@view
func get_pedersen_hash{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        high : felt, low : felt) -> (res : felt):
    let (hash) = hash2{hash_ptr=pedersen_ptr}(low, high)
    return (hash)
end

@view
func get_keccak_hash{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*,  bitwise_ptr : BitwiseBuiltin*}(
        high : felt, low : felt) -> (res : Uint256):

        alloc_locals
    
        let (local keccak_ptr_start) = alloc()
        let keccak_ptr = keccak_ptr_start

        let h_string : felt* = alloc()
        assert [h_string] = high
        assert [h_string] = low
        let (h_string_final : Uint256) = keccak{keccak_ptr=keccak_ptr}(inputs=h_string, n_bytes=8)

        let h_string : felt* = alloc()
        assert [h_string] = high
        assert [h_string] = low
        let (h_string_final : Uint256) = keccak{keccak_ptr=keccak_ptr}(inputs=h_string, n_bytes=8)

        let h_string : felt* = alloc()
        assert [h_string] = high
        assert [h_string] = low
        let (h_string_final : Uint256) = keccak{keccak_ptr=keccak_ptr}(inputs=h_string, n_bytes=8)

        finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)

    return (h_string_final)
end