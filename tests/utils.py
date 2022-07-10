
from starkware.cairo.common.hash_state import compute_hash_on_elements
from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.public.abi import get_selector_from_name
from typing import List, Callable

class Signer():
    """
    Utility for sending signed transactions to an Account on Starknet.
    Parameters
    ----------
    private_key : int
    Examples
    ---------
    Constructing a Singer object
    >>> signer = Signer(1234)
    Sending a transaction
    >>> await signer.send_transaction(account, 
                                      account.contract_address, 
                                      'set_public_key', 
                                      [other.public_key]
                                     )
    """

    def __init__(self, private_key):
        self.private_key = private_key
        self.public_key = private_to_stark_key(private_key)

    def sign(self, message_hash):
        return sign(msg_hash=message_hash, priv_key=self.private_key)

    async def send_transaction(self, account, to, selector_name, calldata, nonce=None):
        if nonce is None:
            execution_info = await account.get_nonce().call()
            nonce, = execution_info.result

        selector = get_selector_from_name(selector_name)
        message_hash = hash_message(
            account.contract_address, to, selector, calldata, nonce)
        sig_r, sig_s = self.sign(message_hash)

        return await account.execute(to, selector, calldata, nonce).invoke(signature=[sig_r, sig_s])

def hash_message(sender, to, selector, calldata, nonce):
    message = [
        sender,
        to,
        selector,
        compute_hash_on_elements(calldata),
        nonce
    ]
    return compute_hash_on_elements(message)


def bitwise_or_bytes(var, key):
    return bytes(a ^ b for a, b in zip(var, key))

def split(num: int, num_bits_shift: int = 128, length: int = 3) -> List[int]:
    a = []
    for _ in range(length):
        a.append(num & ((1 << num_bits_shift) - 1))
        num = num >> num_bits_shift
    return tuple(a)

def pack(z, num_bits_shift: int = 128) -> int:
    limbs = list(z)
    return sum(limb << (num_bits_shift * i) for i, limb in enumerate(limbs))


bytes_to_int_little: Callable[[bytes], int] = lambda word: int.from_bytes(word, "little")

bytes_32_to_uint_256_little : Callable[[bytes], tuple] = lambda word : split(bytes_to_int_little(word), 128, 2)
