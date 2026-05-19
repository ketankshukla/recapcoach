import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/analytics.dart';
import '../../core/config/env.dart';
import 'purchases_service.dart';

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
      // When RevenueCat is stubbed (REVENUECAT_ANDROID_KEY not set) or
      // the configured offering has no packages, leave `_selected` as
      // null so the UI falls through to the stub product picker
      // instead of NPE-ing on `_selected!`. The previous orElse
      // dereferenced `_selected!` which was still null at this point,
      // bricking the screen with an infinite spinner because the
      // exception fired before `_loading = false` ran.
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
      analytics.track(AnalyticsEvents.paywallPurchaseFail, {'error': e.toString()});
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
    final scheme = Theme.of(context).colorScheme;
    final pkgs = _offerings?.current?.availablePackages ?? const <Package>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(onPressed: _restore, child: const Text('Restore')),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.workspace_premium, size: 64, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Unlock Pro',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Everything you need, no limits.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    const _Benefit(text: 'Unlimited usage'),
                    const _Benefit(text: 'Priority processing'),
                    const _Benefit(text: 'Advanced exports'),
                    const _Benefit(text: 'Cancel any time'),
                    const SizedBox(height: 24),
                    if (pkgs.isEmpty)
                      _StubProductPicker(onSelected: (_) {})
                    else
                      ...pkgs.map((p) => _ProductTile(
                            pkg: p,
                            selected: _selected == p,
                            onTap: () => setState(() => _selected = p),
                          )),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: scheme.error)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _purchasing || _selected == null ? null : _buy,
                      child: _purchasing
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Start free trial'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Then billed at the selected price. Cancel anytime in Play Store.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => launchUrl(Uri.parse(Env.termsUrl)),
                          child: const Text('Terms'),
                        ),
                        const Text('  ·  '),
                        TextButton(
                          onPressed: () => launchUrl(Uri.parse(Env.privacyPolicyUrl)),
                          child: const Text('Privacy'),
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

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

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
    final scheme = Theme.of(context).colorScheme;
    final isAnnual = pkg.packageType == PackageType.annual;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? scheme.primary.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isAnnual ? 'Annual' : 'Monthly',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isAnnual) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'BEST VALUE',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pkg.storeProduct.priceString,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StubProductPicker extends StatelessWidget {
  const _StubProductPicker({required this.onSelected});
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Products will appear here once RevenueCat is configured.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'See docs/SETUP.md → Step 6.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
