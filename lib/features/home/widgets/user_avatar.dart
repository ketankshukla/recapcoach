import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Circular avatar that prefers the signed-in user's Google profile photo
/// (`photoURL`) and falls back to navy-on-amber initials when no photo
/// is available or the network image fails to load.
///
/// We keep this widget self-contained so the home app bar, settings
/// screen, and (later) detail headers can share the exact same render.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    required this.email,
    this.radius = 18,
  });

  final String? photoUrl;
  final String? displayName;
  final String? email;
  final double radius;

  /// Initials derived from `displayName` (preferred) or `email`. Always
  /// returns at most 2 characters, uppercased, ASCII-safe.
  String get _initials {
    final name = (displayName ?? '').trim();
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return (parts.first[0] + parts.last[0]).toUpperCase();
      }
      return parts.first.characters.first.toUpperCase();
    }
    final mail = (email ?? '').trim();
    if (mail.isNotEmpty) {
      return mail.characters.first.toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy800,
      child: Text(
        _initials,
        style: TextStyle(
          color: AppColors.amber400,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.85,
        ),
      ),
    );

    if (!hasPhoto) return fallback;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy800,
      foregroundImage: NetworkImage(photoUrl!),
      // If the network image errors out the fallback stays visible
      // because `child` is rendered behind `foregroundImage`.
      child: Text(
        _initials,
        style: TextStyle(
          color: AppColors.amber400,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}
