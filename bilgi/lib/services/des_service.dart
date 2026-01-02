import 'dart:convert';
import 'dart:typed_data';
import 'package:dart_des/dart_des.dart';

class DesService {
  static Uint8List _derive8ByteKey(String password) {
    final bytes = utf8.encode(password);
    final key = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      key[i] = (i < bytes.length) ? bytes[i] : 0x00;
    }
    return key;
  }

  static String encryptToBase64(String plainText, String passwordKey) {
    final keyBytes = _derive8ByteKey(passwordKey);

    final des = DES(
      key: keyBytes,
      mode: DESMode.ECB,
      paddingType: DESPaddingType.PKCS7,
    );

    final plainBytes = utf8.encode(plainText); //byte a çevir

    final encryptedBytes = des.encrypt(plainBytes); // Şifreleme

    return base64Encode(encryptedBytes); // base64 e çevir
  }

  static String decryptFromBase64(String base64CipherText, String passwordKey) {
    final keyBytes = _derive8ByteKey(passwordKey);

    final des = DES(
      key: keyBytes,
      mode: DESMode.ECB,
      paddingType: DESPaddingType.PKCS7,
    );

    final encryptedBytes = base64Decode(base64CipherText);

    final decryptedBytes = des.decrypt(encryptedBytes);

    return utf8.decode(decryptedBytes);
  }
}
