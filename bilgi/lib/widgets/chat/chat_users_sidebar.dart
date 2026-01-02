import 'package:flutter/material.dart';
import 'user_list_tile.dart';

class ChatUsersSidebar extends StatelessWidget {
  final double? width;
  final double? height;
  final List<Map<String, dynamic>> users;
  final int? selectedUserId;
  final Map<int, int> unreadCounts;
  final Function(int userId, String userName) onUserSelected;

  const ChatUsersSidebar({
    super.key,
    this.width,
    this.height,
    required this.users,
    required this.selectedUserId,
    required this.unreadCounts,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF16151B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mesajlar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEDE9FE),
                    letterSpacing: 0.5,
                  ),
                ),
                const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final userObj = users[i];
                final uname = userObj['username']?.toString() ?? '';
                final uid = userObj['id'] as int?;
                final unreadCount = uid != null ? (unreadCounts[uid] ?? 0) : 0;
                final isSelected = uid == selectedUserId;

                return UserListTile(
                  user: userObj,
                  isSelected: isSelected,
                  unreadCount: unreadCount,
                  onTap: () {
                    if (uid != null) {
                      onUserSelected(uid, uname);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
