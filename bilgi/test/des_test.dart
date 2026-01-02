import '../lib/services/des_service.dart';

void main() {
  print('=== Dart DES Test ===');

  const password = '12345678';
  const message = 'Hello World!';

  print('Message: $message');
  print('Password: $password');
  print('Message length: ${message.length} bytes');
  print('');

  // Dart encrypt
  final encrypted = DesService.encryptToBase64(message, password);
  print('Dart Encrypted: $encrypted');

  // Dart decrypt
  final decrypted = DesService.decryptFromBase64(encrypted, password);
  print('Dart Decrypted: $decrypted');

  assert(message == decrypted, 'Dart encrypt/decrypt failed!');
  print('✓ Dart → Dart: SUCCESS');
  print('');

  // Python encrypted value (from Python test)
  const pythonEncrypted = '01Jk6AecyqloojNgxALBVw==';
  print('Python Encrypted: $pythonEncrypted');

  // Decrypt Python value with Dart
  final pythonDecrypted = DesService.decryptFromBase64(
    pythonEncrypted,
    password,
  );
  print('Dart decrypted Python: $pythonDecrypted');

  assert(message == pythonDecrypted, 'Python → Dart decryption failed!');
  print('✓ Python → Dart: SUCCESS');
}
