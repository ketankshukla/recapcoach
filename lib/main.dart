import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/analytics/analytics.dart';
import 'core/logging/logger.dart';
import 'features/paywall/purchases_service.dart';
import 'firebase_options.dart';
import 'shared/providers/shared_prefs_provider.dart';
import 'shared/services/remote_config_service.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await Hive.initFlutter();
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ]);

    await container.read(remoteConfigProvider).initialize();
    await container.read(purchasesServiceProvider).configure();
    await container.read(analyticsProvider).track(AnalyticsEvents.appOpen);

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const RecapCoachApp(),
      ),
    );
  }, (error, stack) {
    logger.error('Uncaught zone error', error, stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
