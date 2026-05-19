import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/analytics.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass/glass_icon_button.dart';
import '../../core/widgets/glass/glass_pill_button.dart';
import '../../core/widgets/glass/gradient_pill_button.dart';
import '../home/widgets/glass_card.dart';
import '../home/widgets/mesh_gradient_background.dart';
import 'purchases_service.dart';

/// Glass-themed paywall.
///
/// Sits over the same animated mesh-gradient background as the home
/// screen so the upgrade flow feels like a continuous part of the
/// premium product, not a Material-3 detour.
///
/// Layered structure (bottom-to-top):
///
///   1. `MeshGradientBackground` (drifting amber + navy + sage blobs)
///   2. `SafeArea` so the close icon clears the status bar
///   3. A scrollable column:
///       - hero amber-on-glass medal disc
///       - headline + subhead
///       - benefits list inside a `GlassCard`
///       - product tiles (one `GlassCard` per package)
///       - error chip if [_error] != null
///       - `GradientPillButton` "Start free trial" CTA
///       - fine-print + Terms / Privacy links
///   4. Floating glass close + restore controls anchored to the top
///      corners (replaces the Material `AppBar`).
///
/// When RevenueCat is in stub mode (no API key set) the package list
/// is empty -- we render an explanatory glass tile instead of bricking
/// the screen on a null-pointer dereference (the original bug fixed
/// in commit 7742178).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  Package? _selected;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallView);
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final svc = ref.read(purchasesServiceProvider);
    final o = await svc.getOfferings();
    if (!mounted) return;
    setState(() {
      _offerings = o;
      final pkgs = o?.current?.availablePackages ?? const <Package>[];
      // Stub mode (REVENUECAT_ANDROID_KEY unset) leaves `_selected`
      // null so the empty-offerings branch renders the stub tile and
      // the CTA stays disabled, instead of hanging on `_selected!`.
      if (pkgs.isNotEmpty) {
        _selected = pkgs.firstWhere(
          (p) => p.packageType == PackageType.annual,
          orElse: () => pkgs.first,
        );
      } else {
        _selected = null;
      }
      _loading = false;
    });
  }

  Future<void> _buy() async {
    if (_selected == null) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    final svc = ref.read(purchasesServiceProvider);
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.paywallPurchaseStart, {
      'product': _selected!.storeProduct.identifier,
    });
    try {
      final info = await svc.purchase(_selected!);
      if (svc.isPro(info)) {
        analytics.track(AnalyticsEvents.paywallPurchaseSuccess);
        if (mounted) context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
      analytics.track(
        AnalyticsEvents.paywallPurchaseFail,
        {'error': e.toString()},
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    final svc = ref.read(purchasesServiceProvider);
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallRestore);
    try {
      final info = await svc.restore();
      if (svc.isPro(info) && mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pkgs = _offerings?.current?.availablePackages ?? const <Package>[];
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;

    // The whole screen is transparent so the mesh background shows
    // through. We omit the AppBar entirely -- close + restore live as
    // floating glass controls in the top corners.
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: MeshGradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ---- Main scrollable content ----
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.amber400,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        72, // leave room for the floating top controls
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroMedal(),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Unlock Pro',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w700,
                              fontSize: 34,
                              height: 1.05,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Everything you need, no limits.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: fgMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _BenefitsCard(fg: fg),
                          const SizedBox(height: AppSpacing.lg),
                          if (pkgs.isEmpty)
                            const _StubProductTile()
                          else
                            ...pkgs.map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _ProductTile(
                                  pkg: p,
                                  selected: _selected == p,
                                  onTap: () =>
                                      setState(() => _selected = p),
                                ),
                              ),
                            ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _ErrorChip(message: _error!),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          GradientPillButton(
                            onPressed: _selected == null ? null : _buy,
                            loading: _purchasing,
                            expanded: true,
                            icon: Icons.workspace_premium_rounded,
                            label: 'Start free trial',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Then billed at the selected price. '
                            'Cancel anytime in Play Store.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: fgMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _LegalLinks(fgMuted: fgMuted),
                        ],
                      ),
                    ),

              // ---- Floating top controls ----
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: GlassIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  onPressed: () => context.pop(),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: GlassPillButton(
                  label: 'Restore',
                  onPressed: _restore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Hero medal disc -- amber-on-glass focal point
// =============================================================================

class _HeroMedal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.amber600, AppColors.amber400],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber600.withValues(alpha: 0.45),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.30),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.workspace_premium_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}

// =============================================================================
// Benefits card
// =============================================================================

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.fg});

  final Color fg;

  static const _benefits = <String>[
    '8 hours of monthly transcription (vs. 15 minutes)',
    '100 recordings per month (vs. 5)',
    '20 minutes per recording (vs. 3)',
    'Cancel anytime',
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _benefits.length; i++) ...[
            _BenefitRow(text: _benefits[i], fg: fg),
            if (i != _benefits.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text, required this.fg});

  final String text;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 26,
          width: 26,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.amber600, AppColors.amber400],
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Product tiles (per RevenueCat package)
// =============================================================================

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.pkg,
    required this.selected,
    required this.onTap,
  });

  final Package pkg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;
    final isAnnual = pkg.packageType == PackageType.annual;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: 18,
      onTap: onTap,
      borderColor: selected
          ? AppColors.amber400
          : (isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.7)),
      tint: selected
          ? AppColors.amber600.withValues(alpha: isDark ? 0.10 : 0.12)
          : null,
      child: Row(
        children: [
          // Custom radio indicator that picks up amber when selected.
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 22,
            width: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.amber400 : fgMuted,
                width: 2,
              ),
              color: selected
                  ? AppColors.amber400
                  : Colors.transparent,
            ),
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isAnnual ? 'Annual' : 'Monthly',
                      style: TextStyle(
                        color: fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isAnnual) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.amber600,
                              AppColors.amber400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BEST VALUE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  pkg.storeProduct.priceString,
                  style: TextStyle(
                    color: fgMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StubProductTile extends StatelessWidget {
  const _StubProductTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: 18,
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, color: fgMuted),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Products will appear here once RevenueCat is configured.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'See docs/SETUP.md → Step 6.',
            textAlign: TextAlign.center,
            style: TextStyle(color: fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Error chip
// =============================================================================

class _ErrorChip extends StatelessWidget {
  const _ErrorChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error600.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error600.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error600,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Legal links
// =============================================================================

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.fgMuted});

  final Color fgMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => launchUrl(Uri.parse(Env.termsUrl)),
          child: Text(
            'Terms',
            style: TextStyle(color: fgMuted, fontWeight: FontWeight.w500),
          ),
        ),
        Text('  ·  ', style: TextStyle(color: fgMuted)),
        TextButton(
          onPressed: () => launchUrl(Uri.parse(Env.privacyPolicyUrl)),
          child: Text(
            'Privacy',
            style: TextStyle(color: fgMuted, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
