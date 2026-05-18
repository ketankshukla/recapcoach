import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notes/note_providers.dart';

class RecapCoachApp extends ConsumerWidget {
  const RecapCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the sync bootstrap alive for the lifetime of the app so it can
    // react to sign-in events and trigger a one-shot Firestore -> Hive sync.
    ref.watch(noteSyncBootstrapProvider);

    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'RecapCoach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
