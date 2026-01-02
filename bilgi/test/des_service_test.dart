import 'package:flutter_test/flutter_test.dart';
import 'package:bilgi/services/des_service.dart';

void main() {
  test('DES encryption and decryption test', () {
    const password = '12345678'; // 8 byte password
    const plainText = 'Merhaba, bu bir test mesajıdır!';

    // Şifrele
    final encrypted = DesService.encryptToBase64(plainText, password);
    print('Encrypted: $encrypted');

    // Deşifrele
    final decrypted = DesService.decryptFromBase64(encrypted, password);
    print('Decrypted: $decrypted');

    // Kontrol et
    expect(decrypted, equals(plainText));
    print('✅ DES encryption/decryption test PASSED!');
  });

  test('DES with different passwords should fail', () {
    const password1 = '12345678';
    const password2 = '87654321';
    const plainText = 'Secret message';

    final encrypted = DesService.encryptToBase64(plainText, password1);

    // Farklı password ile deşifreleme başarısız olmalı
    expect(
      () => DesService.decryptFromBase64(encrypted, password2),
      throwsA(anything),
    );
    print('✅ Different password test PASSED!');
  });
}
