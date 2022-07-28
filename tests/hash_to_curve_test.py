import pytest
from web3 import Web3
from utils import bytes_32_to_uint_256_little, bytes_32_to_uint_256_little, split, pack


@pytest.mark.asyncio
async def test_hash_to_fp(hash_to_curve_factory):
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
   alpha_string  =    '88c636879a1d6644cea4be942694b0b75a1554299249bdf92ab8edb528c96ca6'
   alpha = bytes.fromhex(alpha_string)
   # 1 byte
   ctr_string = '01'
   ctr = bytes.fromhex(ctr_string)
   # 1 bytes
   one_string  = bytes.fromhex('01')

   input_bytes = suite + one_string + y + x + alpha + ctr  

   print(len(input_bytes))
   print(input_bytes.hex())
   py_res = Web3.keccak(input_bytes)
   
   suite =int(suite_string, 16)
   x = split(int(x_string, 16), 86)
   y = split(y_num, 86)
   alpha = split(int(alpha_string, 16), 128, 2)
   ctr = int(ctr_string, 16)
   
   print('split x' , x)
   print(pack(x, 86))
   test_keccak_call = await contract._hash_inputs(
      suite, (x, y), alpha, ctr
   ).call()

   print(test_keccak_call)
   hash = test_keccak_call.result[0]

   res = hash.low.to_bytes(16, 'little').hex() + hash.high.to_bytes(16, 'little').hex()

   padded = 2 + hash.low * 2 ** 8 + hash.high * 2 ** (8 + 128)

   print(padded.to_bytes(33, 'little').hex())
   print(res)
   assert py_res.hex()[2:] ==  res

   