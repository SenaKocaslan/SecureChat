import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final int? userId;
  final double size;
  final double borderRadius;

  const UserAvatar({
    super.key,
    required this.username,
    this.userId,
    this.size = 40,
    this.borderRadius = 12, // Default squircle radius for size 40
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: const Color(0xFF2D2B36),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (userId != null) {
      return Image.network(
        '${ApiService.baseUrl}/users/$userId/photo',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildLetterAvatar(username),
      );
    }
    return _buildLetterAvatar(username);
  }

  Widget _buildLetterAvatar(String username) {
    final color =
        Colors.primaries[username.hashCode.abs() % Colors.primaries.length];
    return Container(
      color: color.withOpacity(0.2),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.45,
          ),
        ),
      ),
    );
  }
}
