import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/analytics.dart';
import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass/glass_alert_dialog.dart';
import '../../core/widgets/glass/glass_icon_button.dart';
import '../auth/auth_providers.dart';
import '../home/widgets/glass_card.dart';
import '../home/widgets/mesh_gradient_background.dart';
import '../paywall/entitlement_provider.dart';
import '../paywall/purchases_service.dart';

/// Glass-themed Settings.
///
/// Replaces the M3 `ListView`-of-`ListTile`s with mesh-backed sections,
/// each section a `GlassCard` containing semantically-grouped rows:
///
///  1. **Account** -- profile / email / UID (or "sign in to back up"
///     for anonymous users).
///  2. **Subscription** -- Pro / Free state, manage subscription /
///     upgrade tap target, optional Restore row when on Pro.
///  3. **Legal & support** -- Terms, Privacy, Contact.
///  4. **Account actions** -- Sign out + destructive Delete account.
///
/// The destructive Delete-account confirmation uses the shared
/// [GlassAlertDialog] with `primaryDestructive: true` so the red
/// outlined button replaces the loud amber CTA.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = '${p.version} (${p.buildNumber})');
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const GlassAlertDialog(
        title: 'Delete account?',
        message:
            'This permanently deletes your account and all data. '
            'This cannot be undone.',
        primaryLabel: 'Delete',
        primaryReturn: true,
        primaryDestructive: true,
        secondaryLabel: 'Cancel',
        secondaryReturn: false,
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(purchasesServiceProvider).logOut();
      await ref.read(authRepositoryProvider).deleteAccount();
      ref.read(analyticsProvider).track(AnalyticsEvents.accountDelete);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _manageSubscription() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _restorePurchases() async {
    await ref.read(purchasesServiceProvider).restore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restored')),
    );
  }

  Future<void> _signOut() async {
    await ref.read(purchasesServiceProvider).logOut();
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAnon = ref.watch(isAnonymousProvider);
    final isPro = ref.watch(entitlementProvider).value ?? false;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MeshGradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Floating back button.
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                ),
              ),

              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  72,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  // Title.
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.lg,
                    ),
                    child: Text(
                      'Settings',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  // ---- Account ----
                  _SectionLabel(text: 'Account', fgMuted: fgMuted),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: _SettingsRow(
                      icon: Icons.person_outline_rounded,
                      title: user?.email ??
                          (isAnon ? 'Guest user' : 'Signed in'),
                      subtitle: isAnon
                          ? 'Sign in to back up your data'
                          : 'UID: ${user?.uid.substring(0, 8) ?? ''}…',
                      fg: fg,
                      fgMuted: fgMuted,
                      showChevron: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Subscription ----
                  _SectionLabel(text: 'Subscription', fgMuted: fgMuted),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: isPro
                              ? Icons.workspace_premium_rounded
                              : Icons.lock_outline_rounded,
                          iconTint: isPro ? AppColors.amber600 : null,
                          title: isPro ? 'Pro — active' : 'Free plan',
                          subtitle: isPro
                              ? 'Manage your subscription in Play Store'
                              : 'Tap to upgrade',
                          fg: fg,
                          fgMuted: fgMuted,
                          onTap: () => isPro
                              ? _manageSubscription()
                              : context.push(AppRoutes.paywall),
                        ),
                        if (isPro)
                          _SettingsRow(
                            icon: Icons.restore_rounded,
                            title: 'Restore purchases',
                            fg: fg,
                            fgMuted: fgMuted,
                            onTap: _restorePurchases,
                            showDivider: false,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Legal & support ----
                  _SectionLabel(
                    text: 'Legal & support',
                    fgMuted: fgMuted,
                  ),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          fg: fg,
                          fgMuted: fgMuted,
                          onTap: () => launchUrl(Uri.parse(Env.termsUrl)),
                        ),
                        _SettingsRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          fg: fg,
                          fgMuted: fgMuted,
                          onTap: () =>
                              launchUrl(Uri.parse(Env.privacyPolicyUrl)),
                        ),
                        _SettingsRow(
                          icon: Icons.mail_outline_rounded,
                          title: 'Contact support',
                          fg: fg,
                          fgMuted: fgMuted,
                          onTap: () => launchUrl(
                            Uri.parse(
                              'mailto:${Env.supportEmail}'
                              '?subject=App%20Support',
                            ),
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Account actions ----
                  _SectionLabel(text: 'Account actions', fgMuted: fgMuted),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.logout_rounded,
                          title: 'Sign out',
                          fg: fg,
                          fgMuted: fgMuted,
                          onTap: _signOut,
                        ),
                        _SettingsRow(
                          icon: Icons.delete_forever_rounded,
                          iconTint: AppColors.error600,
                          title: 'Delete account',
                          titleTint: AppColors.error600,
                          fg: fg,
                          fgMuted: fgMuted,
                          onTap: _confirmDelete,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ---- Version footer ----
                  Center(
                    child: Text(
                      'v$_version',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: fgMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small uppercase label drawn above each `GlassCard` section. Helps
/// the eye see "Account / Subscription / Legal" at a glance without
/// having to read each row.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.fgMuted});

  final String text;
  final Color fgMuted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: fgMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// One row inside a settings `GlassCard`.
///
/// Looks like a `ListTile` but is hand-rolled so the divider, ripple
/// shape, and color tints can match the glass aesthetic.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.fg,
    required this.fgMuted,
    this.subtitle,
    this.iconTint,
    this.titleTint,
    this.onTap,
    this.showChevron = true,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color fg;
  final Color fgMuted;

  /// Override the icon colour. Used for accent rows (amber on Pro,
  /// red on Delete account, etc.).
  final Color? iconTint;

  /// Override the title colour. Mirrors `iconTint` for destructive rows.
  final Color? titleTint;

  /// Tap handler. `null` makes the row non-interactive (e.g. the
  /// account row that's purely informational).
  final VoidCallback? onTap;

  /// Hides the trailing chevron when the row isn't tappable.
  final bool showChevron;

  /// Set to `false` for the LAST row in a card so it doesn't draw a
  /// divider against the card's bottom border.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final iconColor = iconTint ?? fg.withValues(alpha: 0.85);
    final titleColor = titleTint ?? fg;

    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: fgMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null && showChevron)
            Icon(
              Icons.chevron_right_rounded,
              color: fgMuted,
              size: 22,
            ),
        ],
      ),
    );

    final tappable = onTap == null
        ? body
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Colors.white.withValues(alpha: 0.06),
              highlightColor: Colors.white.withValues(alpha: 0.04),
              child: body,
            ),
          );

    if (!showDivider) return tappable;
    return Column(
      children: [
        tappable,
        Divider(
          height: 1,
          thickness: 1,
          color: dividerColor,
          indent: AppSpacing.md + 22 + AppSpacing.sm, // align with title
        ),
      ],
    );
  }
}
