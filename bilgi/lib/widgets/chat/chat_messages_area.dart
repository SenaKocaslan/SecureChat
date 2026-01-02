import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'message_bubble.dart';
import 'user_avatar.dart';

class ChatMessagesArea extends StatefulWidget {
  final Map<String, dynamic>? selectedUser;
  final List<ChatMessage> messages;
  final bool loading;
  final String? error;
  final Function(String text) onSendMessage;

  const ChatMessagesArea({
    super.key,
    required this.selectedUser,
    required this.messages,
    required this.loading,
    required this.error,
    required this.onSendMessage,
  });

  @override
  State<ChatMessagesArea> createState() => _ChatMessagesAreaState();
}

class _ChatMessagesAreaState extends State<ChatMessagesArea> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmoji = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF22202A),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 60,
                color: Color(0xFF7C4DFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sohbet Başlatın',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEDE9FE),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Güvenli ve şifreli mesajlaşma için\nsol taraftan bir kişi seçin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !_showEmoji,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        setState(() => _showEmoji = false);
      },
      child: Container(
        color: const Color(0xFF0F0E13), // Slightly Darker for chat area
        child: Column(
          children: [
            _buildHeader(),
            if (widget.error != null)
              Container(
                width: double.infinity,
                color: Colors.redAccent.withOpacity(0.1),
                padding: const EdgeInsets.all(8),
                child: Text(
                  widget.error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child:
                  widget.loading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7C4DFF),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        itemCount: widget.messages.length,
                        itemBuilder: (context, i) {
                          final message = widget.messages[i];
                          final bool isFirstMessage = i == 0;
                          final bool isNewDay =
                              isFirstMessage ||
                              !_isSameDay(
                                widget.messages[i - 1].time,
                                message.time,
                              );

                          if (isNewDay) {
                            return Column(
                              children: [
                                _buildDateHeader(message.time),
                                MessageBubble(message: message),
                              ],
                            );
                          }
                          return MessageBubble(message: message);
                        },
                      ),
            ),
            _buildInputArea(),
            if (_showEmoji) _buildEmojiPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final uname = widget.selectedUser!['username'] ?? '';
    final uid = widget.selectedUser!['id'] as int?;
    final isOnline = widget.selectedUser!['is_online'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF22202A),
        border: Border(bottom: BorderSide(color: Color(0xFF2D2B36))),
      ),
      child: Row(
        children: [
          UserAvatar(username: uname, userId: uid, size: 40, borderRadius: 12),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                uname,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEDE9FE),
                ),
              ),
              if (isOnline)
                const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'Çevrimiçi',
                      style: TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                    ),
                  ],
                )
              else
                const Text(
                  'Çevrimdışı',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF16151B),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF22202A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2D2B36)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showEmoji = !_showEmoji;
                        if (_showEmoji) {
                          _focusNode.unfocus();
                        } else {
                          _focusNode.requestFocus();
                        }
                      });
                    },
                    icon: Icon(
                      _showEmoji
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Color(0xFFEDE9FE)),
                      onSubmitted: (_) => _handleSend(),
                      decoration: const InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        hintStyle: TextStyle(color: Color(0xFF6B7280)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      cursorColor: const Color(0xFF7C4DFF),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF7C4DFF), // Purple Button
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        textEditingController: _messageController,
        config: Config(
          height: 256,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax:
                28 *
                (foundation.defaultTargetPlatform == TargetPlatform.iOS
                    ? 1.20
                    : 1.0),
            backgroundColor: const Color(0xFF16151B),
            columns: 7,
          ),
          swapCategoryAndBottomBar: false,
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: const CategoryViewConfig(
            backgroundColor: Color(0xFF16151B),
            indicatorColor: Color(0xFF7C4DFF),
            iconColor: Color(0xFF6B7280),
            iconColorSelected: Color(0xFF7C4DFF),
            backspaceColor: Color(0xFF7C4DFF),
            tabBarHeight: 46.0,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(
            enabled: false,
            backgroundColor: Color(0xFF16151B),
            buttonColor: Color(0xFF16151B),
            buttonIconColor: Color(0xFF6B7280),
          ),
          searchViewConfig: const SearchViewConfig(
            backgroundColor: Color(0xFF16151B),
            buttonIconColor: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = 'Bugün';
    } else if (dateOnly == yesterday) {
      label = 'Dün';
    } else {
      label =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF22202A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2D2B36)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
