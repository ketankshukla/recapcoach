import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/logger.dart';

final remoteConfigProvider = Provider<RemoteConfigService>(
  (ref) => RemoteConfigService(),
);

class RemoteConfigService {
  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await _rc.setDefaults(<String, dynamic>{
      'paywall_headline': 'Unlock Pro',
      'paywall_subhead': 'Everything you need, no limits.',
      'free_tier_limit': 3,
      'show_annual_first': true,
    });
    try {
      await _rc.fetchAndActivate();
    } catch (e) {
      logger.warning('RemoteConfig fetch failed: $e');
    }
  }

  String string(String key) => _rc.getString(key);
  int integer(String key) => _rc.getInt(key);
  bool boolean(String key) => _rc.getBool(key);
}
