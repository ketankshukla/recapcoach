import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transcription_service.dart';

final transcriptionServiceProvider = Provider<TranscriptionService>((_) {
  return TranscriptionService();
});
