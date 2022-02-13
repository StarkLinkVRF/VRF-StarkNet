%lang starknet

%builtins pedersen range_check

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2

@view
func get_hash{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        high : felt, low : felt) -> (res : felt):
    let (hash) = hash2{hash_ptr=pedersen_ptr}(low, high)
    return (hash)
end
