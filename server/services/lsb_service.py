
from PIL import Image
import io


def extract_password_from_image(image_bytes: bytes) -> str:
    
    image = Image.open(io.BytesIO(image_bytes))
    
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    pixels = image.load()
    width, height = image.size
    
    bits_needed = 64
    bits = []
    bit_count = 0
    
    for y in range(height):
        for x in range(width):
            if bit_count >= bits_needed:
                break
            
            r, g, b = pixels[x, y]
            
            if bit_count < bits_needed:
                bits.append(r & 1)
                bit_count += 1
            
            if bit_count < bits_needed:
                bits.append(g & 1)
                bit_count += 1
            
            if bit_count < bits_needed:
                bits.append(b & 1)
                bit_count += 1
        
        if bit_count >= bits_needed:
            break
    
    password_bytes = []
    for i in range(0, 64, 8):
        byte_bits = bits[i:i+8]
        byte_value = 0
        for bit in byte_bits:
            byte_value = (byte_value << 1) | bit
        password_bytes.append(byte_value)
    
    return bytes(password_bytes).decode('utf-8')


def embed_password_in_image(image_path: str, password: str, output_path: str) -> None:
    if len(password) != 8:
        raise ValueError("Parola tam 8 karakter olmalı!")
    
    image = Image.open(image_path)
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    pixels = image.load()
    width, height = image.size
    
    bits = []
    for byte in password.encode('utf-8'):
        for i in range(7, -1, -1):
            bits.append((byte >> i) & 1)
    
    bit_index = 0
    for y in range(height):
        for x in range(width):
            if bit_index >= len(bits):
                break
            
            r, g, b = pixels[x, y]
            
            if bit_index < len(bits):
                r = (r & 0xFE) | bits[bit_index]
                bit_index += 1
            
            if bit_index < len(bits):
                g = (g & 0xFE) | bits[bit_index]
                bit_index += 1
            
            if bit_index < len(bits):
                b = (b & 0xFE) | bits[bit_index]
                bit_index += 1
            
            pixels[x, y] = (r, g, b)
        
        if bit_index >= len(bits):
            break
    
    image.save(output_path, 'PNG')


if __name__ == "__main__":
    print("=== LSB Test ===")
    
    test_image = Image.new('RGB', (100, 100), color=(128, 128, 128))
    test_image.save('/tmp/test_original.png')
    
    password = "abc12345"
    print(f"Orijinal: {password}")
    
    embed_password_in_image('/tmp/test_original.png', password, '/tmp/test_stego.png')
    
    with open('/tmp/test_stego.png', 'rb') as f:
        image_bytes = f.read()
    
    extracted = extract_password_from_image(image_bytes)
    print(f"Çıkarılan: {extracted}")
    
    assert password == extracted
    print("✓ Test başarılı!")
