import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';

class LegalViewerScreen extends StatelessWidget {
  const LegalViewerScreen({super.key, required this.doc});

  final String doc;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = doc == 'privacy';
    final url = isPrivacy ? Env.privacyPolicyUrl : Env.termsUrl;
    final title = isPrivacy ? 'Privacy Policy' : 'Terms of Service';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_new, size: 56),
            const SizedBox(height: 16),
            Text(
              'View $title online',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              url,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication),
              child: const Text('Open in browser'),
            ),
          ],
        ),
      ),
    );
  }
}
