import pytest
from web3 import Web3
from utils import bytes_32_to_uint_256_little, bytes_32_to_uint_256_little, split, pack, pedersen_hash_list


@pytest.mark.asyncio
async def test_hash_inputs(hash_to_curve_factory):
   contract = hash_to_curve_factory
   
   print("empty keccak ", Web3.keccak(b'').hex()[2:])
   #fe0103032c8c31fc9f990c6b55e3865a184a4ce50e09481f2eaeb3e60ec1cea13a6ae645aa4ba4b304228a9d05087e147c9e86d84c708bbbe62bb35b28dab74492f6c72601
   
   octet = '00'
   #print('fe' + '01' +  octet * 32 + '01' + octet * 7 +'01' + '01' + '01')
   # 1 byte
   suite_string = 'fe'
   suite = bytes.fromhex(suite_string)
   # 33 bytes represent a given x (258 bits is the max bigint3) but we need octet so 34 bytes
   # example 032c8c31fc9f990c6b55e3865a184a4ce50e09481f2eaeb3e60ec1cea13a6ae645
   x_string = '032c8c31fc9f990c6b55e3865a184a4ce50e09481f2eaeb3e60ec1cea13a6ae645'
   x = bytes.fromhex(x_string)

   y_num = 12345
   print('y_num',(y_num % 2) + 2)
   y = ((y_num % 2) + 2).to_bytes(1, 'little')
   print(y)

   # alpha is uint 256 - keccak of 012345
   alpha_string  =    '88c6'
   alpha = bytes.fromhex(alpha_string)
   # 1 byte
   ctr_string = '01'
   ctr = bytes.fromhex(ctr_string)

   suite =int(suite_string, 16)
   x = split(int(x_string, 16), 86, as_list=True)
   y = split(y_num, 86, as_list=True)
   alpha = int(alpha_string, 16)
   ctr = int(ctr_string, 16)


   test_pedersen_call = await contract._hash_inputs(
      suite, (tuple(x), tuple(y)), alpha, ctr
   ).call()


   assert test_pedersen_call.result[0] ==  pedersen_hash_list([suite] + x + y + [alpha, ctr])

   