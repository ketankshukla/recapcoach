import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/logger.dart';

final analyticsProvider = Provider<Analytics>((ref) => Analytics());

class Analytics {
  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  Future<void> track(String name, [Map<String, Object?>? props]) async {
    logger.info('event:$name $props');
    try {
      await _fa.logEvent(
        name: name,
        parameters: props?.map(
          (key, value) => MapEntry(key, value as Object),
        ),
      );
    } catch (e, st) {
      logger.error('Analytics.track failed: $name', e, st);
    }
  }

  Future<void> setUserId(String? id) async {
    await _fa.setUserId(id: id);
    if (id != null) {
      await FirebaseCrashlytics.instance.setUserIdentifier(id);
    }
  }

  Future<void> setUserProperty(String name, String? value) async {
    await _fa.setUserProperty(name: name, value: value);
  }

  Future<void> screen(String name) async {
    await _fa.logScreenView(screenName: name);
  }
}

class AnalyticsEvents {
  AnalyticsEvents._();
  static const String appOpen = 'app_open';
  static const String onboardingStart = 'onboarding_start';
  static const String onboardingComplete = 'onboarding_complete';
  static const String paywallView = 'paywall_view';
  static const String paywallPurchaseStart = 'paywall_purchase_start';
  static const String paywallPurchaseSuccess = 'paywall_purchase_success';
  static const String paywallPurchaseFail = 'paywall_purchase_fail';
  static const String paywallRestore = 'paywall_restore';
  static const String signInStart = 'sign_in_start';
  static const String signInSuccess = 'sign_in_success';
  static const String signInFail = 'sign_in_fail';
  static const String accountDelete = 'account_delete';
  static const String featureGateBlocked = 'feature_gate_blocked';
}
