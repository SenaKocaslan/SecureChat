import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class StegoService {
  static Uint8List embedText(Uint8List imageBytes, String secret) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Resim decode edilemedi');
    }

    final secretBytes = utf8.encode(secret);
    if (secretBytes.length != 8) {
      throw Exception('Şifre tam 8 karakter olmalı');
    }
    final totalBits = secretBytes.length * 8; // 64 bit
    final capacity = image.width * image.height * 3;
    if (totalBits > capacity) {
      throw Exception('Resim çok küçük, veri sığmıyor');
    }

    int bitIndex = 0;

    int getBit(int byte, int bit) => (byte >> (7 - bit)) & 1;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);

        int r = p.r.toInt();
        int g = p.g.toInt();
        int b = p.b.toInt();

        for (int c = 0; c < 3; c++) {
          if (bitIndex >= totalBits) break;

          final bytePos = bitIndex ~/ 8;
          final bitPos = bitIndex % 8;
          final bit = getBit(secretBytes[bytePos], bitPos);

          if (c == 0) r = (r & 0xFE) | bit;
          if (c == 1) g = (g & 0xFE) | bit;
          if (c == 2) b = (b & 0xFE) | bit;

          bitIndex++;
        }

        image.setPixelRgb(x, y, r, g, b);
        if (bitIndex >= totalBits) break;
      }
      if (bitIndex >= totalBits) break;
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  static String extractText(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Resim decode edilemedi');
    }

    const passwordLength = 8;
    final secretBytes = Uint8List(passwordLength);
    int bitIndex = 0;

    void setSecretBit(int bytePos, int bitPos, int bit) {
      secretBytes[bytePos] |= (bit << (7 - bitPos));
    }

    outerLoop:
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);

        int r = p.r.toInt();
        int g = p.g.toInt();
        int b = p.b.toInt();

        for (int c = 0; c < 3; c++) {
          if (bitIndex >= passwordLength * 8) break outerLoop;

          final bytePos = bitIndex ~/ 8;
          final bitPos = bitIndex % 8;

          int bit;
          if (c == 0) {
            bit = r & 1;
          } else if (c == 1) {
            bit = g & 1;
          } else {
            bit = b & 1;
          }

          setSecretBit(bytePos, bitPos, bit);
          bitIndex++;
        }
      }
    }

    return utf8.decode(secretBytes);
  }
}
