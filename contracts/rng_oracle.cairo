%lang starknet

%builtins pedersen range_check bitwise

from starkware.cairo.common.uint256 import Uint256, uint256_reverse_endian, uint256_lt
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.cairo_secp.ec import EcPoint
from starkware.cairo.common.cairo_keccak.keccak import keccak_felts_bigend, keccak, finalize_keccak
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.math import assert_not_equal
from lib.verify import verify
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.hash import hash2
from lib.openzeppelin.ownable import Ownable
from lib.openzeppelin.IERC20 import IERC20

@contract_interface
namespace IRNGConsumer {
    func request_rng() {
    }

    func will_recieve_rng(rng: BigInt3, request_id: felt) {
    }
}

struct Request {
    callback_address: felt,
    alpha: felt,
    public_key_hash: felt,
}

@storage_var
func requests(index: felt) -> (req: Request) {
}

@storage_var
func request_index() -> (index: felt) {
}

@storage_var
func completed_requests(index: felt) -> (is_complete: felt) {
}

@storage_var
func fee_amount() -> (fee: Uint256) {
}

@storage_var
func fee_address() -> (fee: felt) {
}

@storage_var
func recievable_beacons(recievable_address: felt) -> (public_key_hash: felt) {
}

@event
func request_recieved(request_index: felt, pub_key_hash: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _fee_address: felt, _fee_amount: Uint256, owner_address: felt
) {
    request_index.write(1);
    fee_address.write(_fee_address);
    fee_amount.write(_fee_amount);
    Ownable.initializer(owner_address);

    return ();
}

// Admin Methods
@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();

    return (owner,);
}

@external
func transfer_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_owner: felt
) {
    Ownable.transfer_ownership(new_owner);
    return ();
}

@external
func renounce_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

// Fee Methods
@external
func set_fee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(fee: Uint256) -> () {
    Ownable.assert_only_owner();
    fee_amount.write(fee);

    return ();
}

@external
func set_fee_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fee_token_address: felt
) -> () {
    Ownable.assert_only_owner();
    fee_address.write(fee_token_address);

    return ();
}

@external
func resolve_rng_request{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(request_index: felt, gamma_point: EcPoint, c: BigInt3, s: BigInt3, public_key: EcPoint) {
    alloc_locals;

    let (is_complete: felt) = completed_requests.read(request_index);
    assert_not_equal(is_complete, 1);

    let (request: Request) = requests.read(request_index);

    let (hash: felt) = hash2{hash_ptr=pedersen_ptr}(public_key.x.d0, public_key.x.d1);
    let (hash: felt) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.x.d2);
    let (hash: felt) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.y.d0);
    let (hash: felt) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.y.d1);
    let (hash: felt) = hash2{hash_ptr=pedersen_ptr}(hash, public_key.y.d2);

    assert request.public_key_hash = hash;

    verify(public_key, request.alpha, gamma_point, c, s);

    IRNGConsumer.will_recieve_rng(
        contract_address=request.callback_address, rng=c, request_id=request_index
    );

    completed_requests.write(request_index, 1);

    return ();
}

@external
func request_rng{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beacon_address: felt) -> (request_id: felt) {
    alloc_locals;

    let (caller_address) = get_caller_address();
    let (public_key_hash) = recievable_beacons.read(beacon_address);
    let (amount) = fee_amount.read();

    let (fee_is_not_zero) = uint256_lt(Uint256(0, 0), amount);

    if (fee_is_not_zero == 1) {
        let (token_address) = fee_address.read();
        IERC20.transferFrom(token_address, caller_address, beacon_address, amount);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    let (curr_index) = request_index.read();

    let (alpha: felt) = hash2{hash_ptr=pedersen_ptr}(curr_index, 0);

    requests.write(
        curr_index,
        Request(callback_address=caller_address, alpha=alpha, public_key_hash=public_key_hash),
    );
    request_index.write(curr_index + 1);

    request_recieved.emit(request_index=curr_index, pub_key_hash=public_key_hash);

    return (curr_index,);
}

@external
func set_beacon_public_key_hash{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(public_key_hash: felt) {
    let (caller_address) = get_caller_address();
    recievable_beacons.write(caller_address, public_key_hash);

    return ();
}
@view
func get_request{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    request_id: felt
) -> (request: Request) {
    let (request) = requests.read(request_id);
    return (request,);
}


@view
func get_beacon_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    beacon_address: felt
) -> (public_key_hash: felt) {
    let (public_key_hash) = recievable_beacons.read(beacon_address);
    return (public_key_hash,);
}