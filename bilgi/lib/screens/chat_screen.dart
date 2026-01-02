import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/des_service.dart';
import '../services/websocket_service.dart';
import '../widgets/chat/chat_users_sidebar.dart';
import '../widgets/chat/chat_messages_area.dart';
import '../widgets/chat/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final String username;
  late final String password;
  late final int userId;

  bool _initialized = false;
  final WebSocketService _wsService = WebSocketService();

  List<Map<String, dynamic>> _users = [];
  int? _selectedUserId;
  String? _selectedUserName;
  bool _showOnlineOnly = false;

  final List<ChatMessage> _messages = [];
  final Map<int, int> _unreadCounts = {};

  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    username = (args?['username'] ?? 'unknown').toString();
    password = (args?['password'] ?? '').toString();
    userId = (args?['userId'] ?? 0) as int;

    if (userId == 0) {
      print('ChatScreen: userId is 0, login issue?');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hata: Kullanıcı ID alınamadı. Lütfen tekrar giriş yapın.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      });
    }

    _initialized = true;
    _setupWebSocket();
    _loadUsersAndMessages();
  }

  void _setupWebSocket() {
    _wsService.onMessageReceived = (message) {
      final senderId = message['sender_id'] as int?;
      final receiverId = message['receiver_id'] as int?;
      final encryptedContent = message['encrypted_content'] as String?;
      final createdAt = message['created_at'] as String?;

      if (senderId == null || encryptedContent == null) return;

      print('\n📥 ===== WebSocket MESAJ ALINDI =====');
      print('   Gönderen ID: $senderId');
      print('   Alıcı ID: $receiverId');
      print(
        '   🔐 Şifrelenmiş: ${encryptedContent.length > 50 ? '${encryptedContent.substring(0, 50)}...' : encryptedContent}',
      );
      print('   =====================================\n');

      if (senderId == _selectedUserId || receiverId == _selectedUserId) {
        final isMe = senderId == userId;

        String decryptedText;
        try {
          decryptedText = DesService.decryptFromBase64(
            encryptedContent,
            password,
          );
        } catch (e) {
          decryptedText = '[Şifre çözülemedi]';
        }

        final messageStatus = (message['status'] ?? 'sent').toString();

        final newMessage = ChatMessage(
          from: isMe ? username : _selectedUserName ?? 'unknown',
          to: isMe ? _selectedUserName ?? 'unknown' : username,
          text: decryptedText,
          isMe: isMe,
          time: DateTime.tryParse(createdAt ?? '') ?? DateTime.now(),
          status: isMe ? messageStatus : 'read',
        );

        setState(() {
          _messages.add(newMessage);
        });
      } else if (senderId != userId) {
        setState(() {
          _unreadCounts[senderId] = (_unreadCounts[senderId] ?? 0) + 1;
        });
      }
    };

    _wsService.onStatusUpdate = (userId, username, isOnline) {
      // user status update
      setState(() {
        bool userExists = false;
        for (var user in _users) {
          if (user['id'] == userId) {
            user['is_online'] = isOnline;
            userExists = true;
            break;
          }
        }

        if (!userExists) {
          _users.add({
            'id': userId,
            'username': username,
            'is_online': isOnline,
          });
        }
      });
    };

    _wsService.connect(userId);
  }

  Future<void> _loadUsersAndMessages() async {
    await _loadUsers();
    if (_selectedUserId != null) {
      await _loadMessages();
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.getUsers(currentUserId: userId);
      final filteredUsers =
          users.where((u) => u['username'] != username).toList();

      setState(() {
        _users = filteredUsers;
        // Initial populate of unread counts
        for (var user in _users) {
          final uid = user['id'] as int;
          final count = user['unread_count'] as int? ?? 0;
          if (count > 0) {
            _unreadCounts[uid] = count;
          }
        }
      });
    } catch (e) {
      setState(() => _error = 'Kullanıcılar yüklenemedi: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_selectedUserId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.fetchMessages(
        myId: userId,
        otherId: _selectedUserId!,
      );

      final msgs =
          raw.map((e) {
            final senderId = e['sender_id'] as int?;
            final encryptedText = (e['encrypted_content'] ?? '').toString();
            final tsStr = (e['created_at'] ?? '').toString();
            final ts =
                DateTime.tryParse(tsStr) ??
                DateTime.fromMillisecondsSinceEpoch(0);

            final isMe = senderId == userId;

            String decryptedText;
            try {
              decryptedText = DesService.decryptFromBase64(
                encryptedText,
                password,
              );
            } catch (e) {
              decryptedText = '[Şifre çözülemedi]';
            }

            final status = (e['status'] ?? 'sent').toString();

            return ChatMessage(
              from: isMe ? username : _selectedUserName ?? 'unknown',
              to: isMe ? _selectedUserName ?? 'unknown' : username,
              text: decryptedText,
              isMe: isMe,
              time: ts,
              status: isMe ? status : 'read',
            );
          }).toList();

      msgs.sort((a, b) => a.time.compareTo(b.time));

      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessageToServer(String text) async {
    if (_selectedUserId == null) return;

    try {
      final encryptedMessage = DesService.encryptToBase64(text, password);

      print('\n📤 ===== MESAJ ŞİFRELENDİ =====');
      print('   Orijinal Metin: $text');
      print(
        '   🔐 Şifrelenmiş: ${encryptedMessage.length > 50 ? '${encryptedMessage.substring(0, 50)}...' : encryptedMessage}',
      );
      print('   ==============================\n');

      final ok = await ApiService.sendMessage(
        senderId: userId,
        receiverId: _selectedUserId!,
        encryptedContent: encryptedMessage,
      );

      if (!ok) {
        throw Exception('Mesaj gönderilemedi.');
      }
    } catch (e) {
      print('sendMessage error: $e');
      rethrow;
    }
  }

  void _handleSendMessage(String text) async {
    if (_selectedUserId == null) return;

    final localNow = DateTime.now();
    final localMsg = ChatMessage(
      from: username,
      to: _selectedUserName ?? 'unknown',
      text: text,
      isMe: true,
      time: localNow,
      status: 'sent',
    );

    setState(() {
      _error = null;
      _messages.add(localMsg);
    });

    try {
      await _sendMessageToServer(text);
      await _loadMessages();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopWide = MediaQuery.of(context).size.width >= 900;

    Map<String, dynamic>? selectedUser;
    if (_selectedUserId != null) {
      try {
        selectedUser = _users.firstWhere((u) => u['id'] == _selectedUserId);
      } catch (_) {
        selectedUser = {
          'id': _selectedUserId,
          'username': _selectedUserName,
          'is_online': false,
        };
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF16151B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22202A),
        elevation: 0,
        title: Text(
          'Secure Chat — $username',
          style: const TextStyle(
            color: Color(0xFFEDE9FE),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            icon: Icon(
              Icons.group,
              color:
                  _showOnlineOnly
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF9CA3AF),
            ),
            label: Text(
              'Aktif Kullanıcılar',
              style: TextStyle(
                color:
                    _showOnlineOnly
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF9CA3AF),
              ),
            ),
            onPressed: () {
              setState(() {
                _showOnlineOnly = !_showOnlineOnly;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF9CA3AF)),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await ApiService.logout(userId);
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/welcome');
              }
            },
          ),
        ],
      ),
      body:
          isDesktopWide
              ? Row(
                children: [
                  ChatUsersSidebar(
                    width: 320,
                    users:
                        _showOnlineOnly
                            ? _users
                                .where((u) => u['is_online'] == true)
                                .toList()
                            : _users,
                    selectedUserId: _selectedUserId,
                    unreadCounts: _unreadCounts,
                    onUserSelected: (uid, uname) async {
                      setState(() {
                        _selectedUserId = uid;
                        _selectedUserName = uname;
                        if (_unreadCounts.containsKey(uid)) {
                          _unreadCounts.remove(uid);
                        }
                      });
                      await _loadMessages();
                    },
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFF2D2B36)),
                  Expanded(
                    child: ChatMessagesArea(
                      selectedUser: selectedUser,
                      messages: _messages,
                      loading: _loading,
                      error: _error,
                      onSendMessage: _handleSendMessage,
                    ),
                  ),
                ],
              )
              : Column(
                children: [
                  ChatUsersSidebar(
                    height: 140,
                    users:
                        _showOnlineOnly
                            ? _users
                                .where((u) => u['is_online'] == true)
                                .toList()
                            : _users,
                    selectedUserId: _selectedUserId,
                    unreadCounts: _unreadCounts,
                    onUserSelected: (uid, uname) async {
                      setState(() {
                        _selectedUserId = uid;
                        _selectedUserName = uname;
                        if (_unreadCounts.containsKey(uid)) {
                          _unreadCounts.remove(uid);
                        }
                      });
                      await _loadMessages();
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFF2D2B36)),
                  Expanded(
                    child: ChatMessagesArea(
                      selectedUser: selectedUser,
                      messages: _messages,
                      loading: _loading,
                      error: _error,
                      onSendMessage: _handleSendMessage,
                    ),
                  ),
                ],
              ),
    );
  }
}
