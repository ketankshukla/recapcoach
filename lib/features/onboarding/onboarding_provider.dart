import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/shared_prefs_provider.dart';

const _kOnboardingDoneKey = 'onboarding_complete_v1';

final onboardingCompleteProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return prefs.getBool(_kOnboardingDoneKey) ?? false;
});

class OnboardingController {
  OnboardingController(this.ref);
  final Ref ref;

  Future<void> markComplete() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(_kOnboardingDoneKey, true);
    ref.read(onboardingCompleteProvider.notifier).state = true;
  }
}

final onboardingControllerProvider = Provider<OnboardingController>(
  (ref) => OnboardingController(ref),
);
