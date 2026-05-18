import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/config/env.dart';
import '../../core/logging/logger.dart';

/// Result of a successful call to the backend `/api/transcribe` endpoint.
class TranscriptionResult {
  TranscriptionResult({
    required this.transcript,
    required this.summary,
    required this.actionItems,
    this.warning,
  });

  final String transcript;
  final String summary;
  final List<String> actionItems;

  /// Non-fatal warning from the backend (e.g. transcript succeeded but
  /// summarization failed). When present, [summary] / [actionItems] may be empty.
  final String? warning;

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      transcript: (json['transcript'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      actionItems:
          (json['actionItems'] as List?)?.whereType<String>().toList() ??
              <String>[],
      warning: json['warning'] as String?,
    );
  }
}

/// Thrown when the backend is not configured or the request fails.
class TranscriptionException implements Exception {
  TranscriptionException(this.message, {this.kind = TranscriptionErrorKind.other});
  final String message;
  final TranscriptionErrorKind kind;
  @override
  String toString() => 'TranscriptionException: $message';
}

/// Coarse-grained failure category, so the UI can react differently for
/// recoverable errors (network, server) vs hard limits (quota, kill switch).
enum TranscriptionErrorKind {
  /// User-friendly: free quota exhausted, needs to upgrade.
  quotaExceeded,
  /// User-friendly: file exceeds the per-plan size cap.
  fileTooLarge,
  /// Transient: feature globally disabled by admin (rare).
  disabled,
  /// Auth problem (token missing / expired / invalid).
  unauthorized,
  /// Everything else: network, OpenAI down, decoding error, etc.
  other,
}

/// Uploads an audio file to the RecapCoach backend (`POST /api/transcribe`)
/// and returns transcript + summary + action items.
class TranscriptionService {
  TranscriptionService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                // Whisper on a multi-minute file plus GPT can take a while.
                sendTimeout: const Duration(seconds: 60),
                receiveTimeout: const Duration(seconds: 90),
              ),
            );

  final Dio _dio;

  /// True when [Env.backendUrl] has been configured at build time.
  bool get isConfigured => Env.hasBackend;

  Future<TranscriptionResult> transcribe(File audio) async {
    if (!isConfigured) {
      throw TranscriptionException(
        'Backend not configured. Pass --dart-define=BACKEND_URL=https://... when running the app.',
      );
    }

    // The backend requires a Firebase ID token. If the user isn't signed in,
    // we can't transcribe -- fail fast with a clear message.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw TranscriptionException(
        'You must be signed in to transcribe recordings.',
      );
    }
    final String idToken;
    try {
      final t = await user.getIdToken();
      if (t == null || t.isEmpty) {
        throw TranscriptionException('Could not obtain a Firebase ID token.');
      }
      idToken = t;
    } on FirebaseAuthException catch (e) {
      throw TranscriptionException('Auth error: ${e.message ?? e.code}');
    }

    final url = '${Env.backendUrl.replaceAll(RegExp(r'/+$'), '')}/api/transcribe';
    logger.info('Uploading audio to $url (${audio.lengthSync()} bytes)');

    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audio.path,
        filename: audio.uri.pathSegments.last,
      ),
    });

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        url,
        data: form,
        options: Options(
          // Let Dio set the multipart boundary header itself.
          contentType: 'multipart/form-data',
          responseType: ResponseType.json,
          headers: <String, String>{
            'Authorization': 'Bearer $idToken',
          },
        ),
      );
      final data = res.data;
      if (data == null) {
        throw TranscriptionException('Empty response from backend.');
      }
      return TranscriptionResult.fromJson(data);
    } on DioException catch (e) {
      final body = e.response?.data;
      final status = e.response?.statusCode ?? 0;
      final serverMsg = body is Map && body['error'] is String
          ? body['error'] as String
          : e.message ?? 'unknown error';
      logger.error('Transcription HTTP error (status=$status)', e);

      TranscriptionErrorKind kind;
      switch (status) {
        case 401:
          kind = TranscriptionErrorKind.unauthorized;
          break;
        case 413:
          kind = TranscriptionErrorKind.fileTooLarge;
          break;
        case 429:
          kind = TranscriptionErrorKind.quotaExceeded;
          break;
        case 503:
          kind = TranscriptionErrorKind.disabled;
          break;
        default:
          kind = TranscriptionErrorKind.other;
      }
      throw TranscriptionException(serverMsg, kind: kind);
    }
  }
}
