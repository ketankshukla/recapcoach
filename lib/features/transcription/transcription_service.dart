import 'dart:io';

import 'package:dio/dio.dart';

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
  TranscriptionException(this.message);
  final String message;
  @override
  String toString() => 'TranscriptionException: $message';
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
        ),
      );
      final data = res.data;
      if (data == null) {
        throw TranscriptionException('Empty response from backend.');
      }
      return TranscriptionResult.fromJson(data);
    } on DioException catch (e) {
      final body = e.response?.data;
      final serverMsg = body is Map && body['error'] is String
          ? body['error'] as String
          : e.message ?? 'unknown error';
      logger.error('Transcription HTTP error', e);
      throw TranscriptionException(serverMsg);
    }
  }
}
