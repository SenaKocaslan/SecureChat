import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../services/stego_service.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  File? _selectedImageFile;
  bool _isLoading = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickImage() async {
    final XFile? file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: 'images', extensions: ['png', 'jpg', 'jpeg']),
      ],
    );
    if (file == null) return;

    setState(() {
      _selectedImageFile = File(file.path);
    });
  }

  Future<File> getCoverImageOrDefault() async {
    if (_selectedImageFile != null) {
      return _selectedImageFile!;
    }

    // Kullanıcı foto seçmezse default image kullan
    final byteData = await rootBundle.load('assets/images/default_profile.png');

    final tempDir = Directory.systemTemp;
    final path = '${tempDir.path}${Platform.pathSeparator}default_profile.png';

    final file = File(path);
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

    return file;
  }

  Future<void> _onRegisterPressed() async {
    if (_isLoading) return;

    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      // 1) Cover image bytes oku
      final File coverFile = await getCoverImageOrDefault();
      final Uint8List coverBytes = await coverFile.readAsBytes();

      // 2) Password'u resme göm → stego PNG bytes üret
      final Uint8List stegoPngBytes = StegoService.embedText(
        coverBytes,
        password,
      );

      // 3) Stego bytes'ı geçici bir dosyaya yaz
      final tempDir = Directory.systemTemp;
      final stegoPath =
          '${tempDir.path}${Platform.pathSeparator}stego_${DateTime.now().millisecondsSinceEpoch}.png';

      final File stegoFile = await File(
        stegoPath,
      ).writeAsBytes(stegoPngBytes, flush: true);

      print(
        'Cover: ${coverBytes.length} bytes | Stego: ${stegoPngBytes.length} bytes',
      );
      print('Stego file path: ${stegoFile.path}');
      print('Register URL: ${ApiService.baseUrl}/register');

      // 4) Artık server'a cover değil, stego image gönderiyoruz
      final success = await ApiService.registerUser(username, stegoFile);

      if (!mounted) return;

      if (success != null && success['user_id'] != null) {
        final userId = success['user_id'] as int;
        print('✅ Register successful: userId=$userId');

        Navigator.pushReplacementNamed(
          context,
          '/chat',
          arguments: {
            'username': username,
            'password': password,
            'userId': userId, // user_id'yi geç
          },
        );
      } else {
        _showSnack('Kayıt başarısız. Kullanıcı adı alınmış olabilir.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Sunucu/bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profil fotoğrafı önizleme (dinamik)
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: ClipOval(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        border: Border.all(color: Colors.white24, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          _selectedImageFile != null
                              ? Image.file(
                                _selectedImageFile!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              )
                              : Image.asset(
                                'assets/images/usericon.png',
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedImageFile == null
                      ? 'Profil fotoğrafı seçmek için tıklayın'
                      : 'Değiştirmek için tıklayın',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Yeni Hesap Oluştur',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kullanıcı adı + 8 karakter parola girin',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 8,
                  color: const Color(0xFF1E1E2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Username
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Kullanıcı adı',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Kullanıcı adı boş olamaz';
                              }
                              if (v.trim().length < 3) {
                                return 'En az 3 karakter olmalı';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Parola (8 karakter)',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            maxLength: 8,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Parola boş olamaz';
                              }
                              if (v.length != 8) {
                                return 'Parola tam 8 karakter olmalı';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // Confirm
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Parola tekrar',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            maxLength: 8,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Parolayı tekrar girin';
                              }
                              if (v != _passwordController.text) {
                                return 'Parolalar uyuşmuyor';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onRegisterPressed,
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Kayıt Ol'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
