import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'time_based_greeting.dart';
import 'user_avatar.dart';

/// Custom AppBar for the home screen.
///
/// Layout (left → right):
///
///   [ avatar ]   Good morning,           [ settings ]
///                Ketan
///
/// Falls back to "Welcome to RecapCoach" on the second line when no user
/// is signed in (e.g. anonymous-only build during dev).
///
/// Implemented as a regular [AppBar] (not a [SliverAppBar]) for now to
/// keep the home-screen layout simple. We can promote to a sliver later
/// if we want a collapsing / parallax effect.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.onSettings,
    this.now,
  });

  final String? displayName;
  final String? email;
  final String? photoUrl;
  final VoidCallback onSettings;

  /// Override the clock for tests. Defaults to [DateTime.now] in
  /// production code.
  final DateTime? now;

  static const double _height = 72;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final greeting = TimeBasedGreeting.forTime(now ?? DateTime.now());
    final firstName = _firstName(displayName);
    final hasName = firstName != null && firstName.isNotEmpty;

    return AppBar(
      toolbarHeight: _height,
      titleSpacing: AppSpacing.sm,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          UserAvatar(
            photoUrl: photoUrl,
            displayName: displayName,
            email: email,
            radius: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasName ? '$greeting,' : 'Welcome to',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasName ? firstName : 'RecapCoach',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: onSettings,
        ),
        const SizedBox(width: AppSpacing.xxs),
      ],
    );
  }

  /// Returns the first whitespace-separated token of [name]. Returns
  /// `null` when [name] is null/blank so callers can swap in a fallback
  /// copy without testing for the empty-string case themselves.
  static String? _firstName(String? name) {
    if (name == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.first;
  }
}
