import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
import 'features/notes/note_cloud_repository.dart';
import 'features/notes/note_providers.dart';
import 'features/notes/note_repository.dart';
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
    final noteCloudRepo = NoteCloudRepository();
    final noteRepo = await NoteRepository.open(
      cloud: noteCloudRepo,
      uidGetter: () => FirebaseAuth.instance.currentUser?.uid,
    );

    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        noteRepositoryProvider.overrideWithValue(noteRepo),
        noteCloudRepositoryProvider.overrideWithValue(noteCloudRepo),
      ],
    );

    await container.read(remoteConfigProvider).initialize();
    await container.read(purchasesServiceProvider).configure();
    await container.read(analyticsProvider).track(AnalyticsEvents.appOpen);

    // Debug builds: log the signed-in UID so the developer can
    // verify it matches `/config/global.developerUids` in Firestore.
    if (kDebugMode) {
      FirebaseAuth.instance.userChanges().listen((user) {
        if (user != null) {
          // ignore: avoid_print
          print('[DEV-UID] ${user.uid}  email=${user.email}');
        }
      });
    }

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
