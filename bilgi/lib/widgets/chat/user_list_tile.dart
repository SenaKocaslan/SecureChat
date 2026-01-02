import 'package:flutter/material.dart';
import 'user_avatar.dart';

class UserListTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isSelected;
  final int unreadCount;
  final VoidCallback onTap;

  const UserListTile({
    super.key,
    required this.user,
    required this.isSelected,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final uname = user['username']?.toString() ?? '';
    final userId = user['id'] as int?;
    final isOnline = user['is_online'] == true;

    return Material(
      color: isSelected ? const Color(0xFF22202A) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFF1F1D26),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  UserAvatar(
                    username: uname,
                    userId: userId,
                    size: 48,
                    borderRadius: 14,
                  ),
                  if (isOnline)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981), // Green
                          border: Border.all(
                            color: const Color(0xFF16151B),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEDE9FE),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnline ? 'Aktif' : 'Çevrimdışı',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isOnline
                                ? const Color(0xFF10B981).withOpacity(0.8)
                                : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF), // Purple Accent
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
