import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final int? userId;
  final double size;
  final double fontSize;
  final bool isOnline;
  final bool showStatus;

  const UserAvatar({
    super.key,
    required this.username,
    this.userId,
    this.size = 48.0,
    this.fontSize = 20.0,
    this.isOnline = false,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF2D2B36),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildContent(),
        ),
        if (showStatus && isOnline)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981), // Green
                border: Border.all(color: const Color(0xFF16151B), width: 2.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (userId != null) {
      return Image.network(
        '${ApiService.baseUrl}/users/$userId/photo',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildLetterAvatar(),
      );
    }
    return _buildLetterAvatar();
  }

  Widget _buildLetterAvatar() {
    // Generate color from username hash for variety
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
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
