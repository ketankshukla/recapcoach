import 'package:talker_flutter/talker_flutter.dart';

final Talker logger = TalkerFlutter.init(
  settings: TalkerSettings(
    useConsoleLogs: true,
    maxHistoryItems: 1000,
  ),
);
