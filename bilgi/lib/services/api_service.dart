import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const bool kMockApi = false;

  static String _serverIp = '127.0.0.1';
  static String get baseUrl => 'http://$_serverIp:8000';

  static String get serverIp => _serverIp;
  static set serverIp(String ip) => _serverIp = ip;

  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    if (kMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {'user_id': 1, 'username': username};
    }

    try {
      print('Logging in: $username');
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'user_id': data['user_id'], 'username': username};
      }

      print('Login failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Login exception: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> registerUser(
    String username,
    File stegoImage,
  ) async {
    if (kMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {'message': 'Success', 'user_id': 1};
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register'),
      );
      request.fields['username'] = username;
      request.files.add(
        await http.MultipartFile.fromPath('image', stegoImage.path),
      );

      print('Registering user: $username');
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }

      print(
        'Registration failed: ${streamedResponse.statusCode} - $responseBody',
      );
      return null;
    } catch (e) {
      print('Registration exception: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUsers({
    int? currentUserId,
  }) async {
    if (kMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      return [
        {'id': 1, 'username': 'alice', 'is_online': true, 'unread_count': 2},
        {'id': 2, 'username': 'bob', 'is_online': false, 'unread_count': 0},
        {'id': 3, 'username': 'charlie', 'is_online': true, 'unread_count': 5},
      ];
    }

    try {
      var uri = Uri.parse('$baseUrl/users');
      if (currentUserId != null) {
        uri = uri.replace(
          queryParameters: {'current_user_id': currentUserId.toString()},
        );
      }

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print('GetUsers failed: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map<Map<String, dynamic>>((e) {
          return {
            'id': e['id'],
            'username': e['username'] ?? '',
            'is_online': e['is_online'] ?? false,
            'unread_count': e['unread_count'] ?? 0,
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print('GetUsers error: $e');
      return [];
    }
  }

  static Future<bool> sendMessage({
    required int senderId,
    required int receiverId,
    required String encryptedContent,
  }) async {
    if (kMockApi) return true;

    try {
      final payload = {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'encrypted_content': encryptedContent,
      };

      print('\n📤 ===== MESAJ GÖNDERİLİYOR =====');
      print('   Gönderen ID: $senderId');
      print('   Alıcı ID: $receiverId');
      print(
        '   🔐 Şifrelenmiş Mesaj: ${encryptedContent.length > 50 ? '${encryptedContent.substring(0, 50)}...' : encryptedContent}',
      );
      print('   ================================\n');

      final response = await http.post(
        Uri.parse('$baseUrl/messages/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) return true;

      print('SendMessage failed: ${response.body}');
      return false;
    } catch (e) {
      print('SendMessage error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMessages({
    required int myId,
    required int otherId,
  }) async {
    if (kMockApi) {
      return [
        {
          'sender_id': myId,
          'receiver_id': otherId,
          'encrypted_content': 'mock encrypted message',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$myId/$otherId'),
      );

      if (response.statusCode != 200) {
        print('FetchMessages failed: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body);
      if (data is List) {
        print('\n📥 ===== MESAJLAR ALINDI =====');
        for (var msg in data) {
          final encrypted = msg['encrypted_content'] ?? '';
          print(
            '   🔐 Şifrelenmiş: ${encrypted.length > 50 ? '${encrypted.substring(0, 50)}...' : encrypted}',
          );
        }
        print('   ================================\n');
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('FetchMessages error: $e');
      return [];
    }
  }

  static Future<bool> logout(int userId) async {
    if (kMockApi) return true;

    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/logout',
        ).replace(queryParameters: {'user_id': userId.toString()}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }
}
