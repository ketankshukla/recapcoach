import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../features/paywall/entitlement_provider.dart';
import '../analytics/analytics.dart';

class FeatureGate extends ConsumerWidget {
  const FeatureGate({
    super.key,
    required this.featureName,
    required this.child,
    this.fallback,
  });

  final String featureName;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);
    return entitlement.when(
      data: (isPro) {
        if (isPro) return child;
        return fallback ?? _LockedTile(featureName: featureName);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => fallback ?? _LockedTile(featureName: featureName),
    );
  }
}

class _LockedTile extends ConsumerWidget {
  const _LockedTile({required this.featureName});

  final String featureName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ref.read(analyticsProvider).track(
          AnalyticsEvents.featureGateBlocked,
          {'feature': featureName},
        );
        context.push(AppRoutes.paywall);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(featureName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to unlock with Pro',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
