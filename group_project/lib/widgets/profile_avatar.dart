import 'package:flutter/material.dart';

/// Reusable circular profile avatar widget with fallback to initials.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final String? imageUrl;
  final String? displayName;
  final Color? backgroundColor;
  final Color? textColor;

  const ProfileAvatar({
    super.key,
    this.size = 32.0,
    this.imageUrl,
    this.displayName,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBgColor = backgroundColor ?? theme.colorScheme.primary;
    final defaultTextColor = textColor ?? Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 25/255),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: defaultBgColor,
        backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
            ? NetworkImage(imageUrl!)
            : null,
        onBackgroundImageError: (imageUrl != null && imageUrl!.isNotEmpty)
            ? (_, _) {}
            : null,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? Text(
          _getInitials(displayName),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: defaultTextColor,
          ),
        )
            : null,
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}