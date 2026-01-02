
import base64
from Crypto.Cipher import DES


def pad_password(password: str) -> bytes:
    password_bytes = password.encode('utf-8')
    key = bytearray(8)
    for i in range(8):
        if i < len(password_bytes):
            key[i] = password_bytes[i]
        else:
            key[i] = 0x00
    return bytes(key)


def pkcs7_pad(data: bytes, block_size: int = 8) -> bytes:
    padding_length = block_size - (len(data) % block_size)
    if padding_length == 0:
        padding_length = block_size
    padding = bytes([padding_length] * padding_length)
    return data + padding


def pkcs7_unpad(data: bytes) -> bytes:
    if not data:
        return data
    padding_length = data[-1]
    if not isinstance(padding_length, int) or padding_length < 1 or padding_length > 8:
        return data
    
    if all(b == padding_length for b in data[-padding_length:]):
        return data[:-padding_length]
    return data


def des_encrypt(plain_text: str, password: str) -> str:
    key = pad_password(password)
    plain_bytes = plain_text.encode('utf-8')
    
    padded_data = pkcs7_pad(plain_bytes, 8)
    
    cipher = DES.new(key, DES.MODE_ECB)
    encrypted_bytes = cipher.encrypt(padded_data)
    
    return base64.b64encode(encrypted_bytes).decode('utf-8')


def des_decrypt(cipher_b64: str, password: str) -> str:
    key = pad_password(password)
    encrypted_bytes = base64.b64decode(cipher_b64)
    
    cipher = DES.new(key, DES.MODE_ECB)
    decrypted_padded = cipher.decrypt(encrypted_bytes)
    
    decrypted_bytes = pkcs7_unpad(decrypted_padded)
    
    return decrypted_bytes.decode('utf-8')


if __name__ == "__main__":
    print("=== DES Test ===")
    password = "12345678"
    mesaj = "Hello World!"
    
    print(f"Message: {mesaj}")
    print(f"Password: {password}")
    print(f"Message length: {len(mesaj)} bytes")
    print()
    
    encrypted = des_encrypt(mesaj, password)
    print(f"Encrypted: {encrypted}")
    
    decrypted = des_decrypt(encrypted, password)
    print(f"Decrypted: {decrypted}")
    
    assert mesaj == decrypted
    print("✓ Python → Python: SUCCESS")
