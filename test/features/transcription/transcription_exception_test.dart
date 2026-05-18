// Unit tests for `TranscriptionException` and `TranscriptionErrorKind`.
//
// The full HTTP-status -> error-kind mapping test (U1.6 in the test
// plan) requires a Dio mock; that arrives in a later test pass once we
// add the `mocktail` dev dependency.  These tests cover the parts that
// don't need a network mock.
//
// Test catalogue: `docs/11-test-plan.md` §1.6.
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/features/transcription/transcription_service.dart';

void main() {
  group('TranscriptionException', () {
    test('Defaults to TranscriptionErrorKind.other when kind is omitted', () {
      final e = TranscriptionException('network unreachable');

      expect(e.kind, TranscriptionErrorKind.other);
      expect(e.message, 'network unreachable');
    });

    test('Carries the supplied kind', () {
      final e = TranscriptionException(
        'Free plan limit reached',
        kind: TranscriptionErrorKind.quotaExceeded,
      );

      expect(e.kind, TranscriptionErrorKind.quotaExceeded);
    });

    test('toString includes the message for easy logging', () {
      final e = TranscriptionException('something broke');

      expect(e.toString(), contains('something broke'));
      expect(e.toString(), contains('TranscriptionException'));
    });
  });

  group('TranscriptionErrorKind', () {
    test('All five expected variants are present', () {
      // Defensive: if someone removes a variant, the UI's switch on
      // error kind will silently fall through. Catch it here.
      const expected = <TranscriptionErrorKind>{
        TranscriptionErrorKind.quotaExceeded,
        TranscriptionErrorKind.fileTooLarge,
        TranscriptionErrorKind.disabled,
        TranscriptionErrorKind.unauthorized,
        TranscriptionErrorKind.other,
      };
      expect(TranscriptionErrorKind.values.toSet(), expected);
    });
  });
}
