// Unit tests for `GlobalConfigSnapshot` -- the client mirror of the
// `/config/global` Firestore document.
//
// The same document drives the server-side developer bypass in
// `api/_lib/quota.ts`, so the parsing logic here MUST tolerate the
// same set of weird Firestore payloads (missing fields, wrong types,
// non-list `developerUids`, etc.) without crashing the home screen.
//
// Test catalogue: `docs/11-test-plan.md` §1.x (config).
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/config/global_config.dart';

void main() {
  group('GlobalConfigSnapshot.empty', () {
    test('Has transcription enabled and an empty developer list', () {
      const s = GlobalConfigSnapshot.empty;
      expect(s.transcriptionEnabled, isTrue);
      expect(s.developerUids, isEmpty);
    });
  });

  group('GlobalConfigSnapshot.fromFirestore', () {
    test('Null payload returns the empty default', () {
      final s = GlobalConfigSnapshot.fromFirestore(null);
      expect(s.transcriptionEnabled, isTrue);
      expect(s.developerUids, isEmpty);
    });

    test('Empty map keeps defaults (transcription enabled, no devs)', () {
      final s = GlobalConfigSnapshot.fromFirestore(<String, dynamic>{});
      expect(s.transcriptionEnabled, isTrue);
      expect(s.developerUids, isEmpty);
    });

    test('Parses transcriptionEnabled = false explicitly', () {
      final s = GlobalConfigSnapshot.fromFirestore(<String, dynamic>{
        'transcriptionEnabled': false,
      });
      expect(s.transcriptionEnabled, isFalse);
    });

    test(
        'transcriptionEnabled defaults to true on missing or non-bool field',
        () {
      // Defensive: a misconfigured field must not silently kill
      // transcription for everyone.
      final s1 = GlobalConfigSnapshot.fromFirestore(
        <String, dynamic>{'transcriptionEnabled': 'yes'},
      );
      final s2 = GlobalConfigSnapshot.fromFirestore(
        <String, dynamic>{'transcriptionEnabled': 1},
      );
      expect(s1.transcriptionEnabled, isTrue);
      expect(s2.transcriptionEnabled, isTrue);
    });

    test('Parses developerUids as a list of strings', () {
      final s = GlobalConfigSnapshot.fromFirestore(<String, dynamic>{
        'developerUids': ['uid-a', 'uid-b'],
      });
      expect(s.developerUids, ['uid-a', 'uid-b']);
    });

    test('Drops empty strings and non-string entries from developerUids', () {
      // Real-world: someone hand-edits the array in the Firebase
      // Console and accidentally leaves a blank entry, or types a
      // number. The bypass must NOT match those.
      final s = GlobalConfigSnapshot.fromFirestore(<String, dynamic>{
        'developerUids': ['uid-a', '', 42, null, 'uid-b'],
      });
      expect(s.developerUids, ['uid-a', 'uid-b']);
    });

    test('developerUids that is not iterable falls back to empty', () {
      // If someone writes `developerUids: "uid-a"` (a string instead
      // of a list), we must not split-on-chars or otherwise treat it
      // as a list -- the developer bypass simply doesn't apply.
      final s = GlobalConfigSnapshot.fromFirestore(<String, dynamic>{
        'developerUids': 'uid-a',
      });
      expect(s.developerUids, isEmpty);
    });

    test('[CRITICAL] developerUids absent => empty list (no accidental dev mode)', () {
      // If the field is missing entirely, NOBODY gets bypass. This
      // protects against a bug where a missing field is interpreted as
      // "everyone is a developer".
      final s = GlobalConfigSnapshot.fromFirestore(<String, dynamic>{
        'transcriptionEnabled': true,
      });
      expect(s.developerUids, isEmpty);
    });
  });
}
