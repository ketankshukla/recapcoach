import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/legal/legal_viewer_screen.dart';
import '../../features/notes/note_detail_screen.dart';
import '../../features/onboarding/onboarding_provider.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/recording/record_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String home = '/';
  static const String paywall = '/paywall';
  static const String settings = '/settings';
  static const String legal = '/legal';
  static const String record = '/record';
  static const String notes = '/notes';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (!onboardingComplete && loc != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      if (onboardingComplete && loc == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      final isAuthed = authState.value != null;
      final goingToSignIn = loc == AppRoutes.signIn;
      if (!isAuthed && !goingToSignIn && loc != AppRoutes.onboarding) {
        return AppRoutes.signIn;
      }
      if (isAuthed && goingToSignIn) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, __) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.legal}/:doc',
        builder: (_, state) => LegalViewerScreen(doc: state.pathParameters['doc']!),
      ),
      GoRoute(
        path: AppRoutes.record,
        builder: (_, __) => const RecordScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.notes}/:id',
        builder: (_, state) =>
            NoteDetailScreen(noteId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
