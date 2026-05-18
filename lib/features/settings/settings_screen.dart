import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/analytics.dart';
import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_providers.dart';
import '../paywall/entitlement_provider.dart';
import '../paywall/purchases_service.dart';

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
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and all data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(purchasesServiceProvider).logOut();
      await ref.read(authRepositoryProvider).deleteAccount();
      ref.read(analyticsProvider).track(AnalyticsEvents.accountDelete);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _manageSubscription() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAnon = ref.watch(isAnonymousProvider);
    final isPro = ref.watch(entitlementProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.email ?? (isAnon ? 'Guest user' : 'Signed in')),
            subtitle: isAnon
                ? const Text('Sign in to back up your data')
                : Text('UID: ${user?.uid.substring(0, 8) ?? ''}…'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              isPro ? Icons.workspace_premium : Icons.lock_outline,
              color: isPro
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(isPro ? 'Pro — active' : 'Free plan'),
            subtitle: Text(
              isPro
                  ? 'Manage your subscription in Play Store'
                  : 'Tap to upgrade',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (isPro) {
                _manageSubscription();
              } else {
                context.push(AppRoutes.paywall);
              }
            },
          ),
          if (isPro)
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore purchases'),
              onTap: () async {
                await ref.read(purchasesServiceProvider).restore();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restored')),
                  );
                }
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => launchUrl(Uri.parse(Env.termsUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => launchUrl(Uri.parse(Env.privacyPolicyUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contact support'),
            onTap: () => launchUrl(
              Uri.parse('mailto:${Env.supportEmail}?subject=App%20Support'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await ref.read(purchasesServiceProvider).logOut();
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever,
                color: Theme.of(context).colorScheme.error),
            title: Text(
              'Delete account',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _confirmDelete,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'v$_version',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
