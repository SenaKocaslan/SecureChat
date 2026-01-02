import 'package:flutter/material.dart';

class ChatMessage {
  final String from;
  final String to;
  final String text;
  final bool isMe;
  final DateTime time;
  final String status; // sent, delivered, read

  ChatMessage({
    required this.from,
    required this.to,
    required this.text,
    required this.isMe,
    required this.time,
    this.status = 'sent',
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final bg =
        isMe
            ? const Color(0xFF7C4DFF) // Deep Purple (Me)
            : const Color(0xFF2D2B36); // Dark Grey (Other)

    // Daha modern, az yuvarlak "Squircle" vari köşeler
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: borderRadius),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : const Color(0xFFEDE9FE),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.time),
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isMe
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF9CA3AF),
                  ),
                ),
                if (isMe) ...[const SizedBox(width: 4), _buildStatusIcon()],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildStatusIcon() {
    return Icon(
      message.status == 'read'
          ? Icons.done_all_rounded
          : message.status == 'delivered'
          ? Icons.done_all_rounded
          : Icons.check_rounded,
      size: 14,
      color:
          message.status == 'read'
              ? const Color(0xFF00E5FF) // Cyan for read
              : Colors.white.withOpacity(0.7),
    );
  }
}
