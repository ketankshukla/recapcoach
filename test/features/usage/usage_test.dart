// Unit tests for `UsageSnapshot` -- the client-side mirror of the
// server-side plan limits and monthly counters.
//
// These tests guard the math that the home-screen meter and the
// record-screen pre-flight check rely on. If any one of them fails,
// the user-facing quota UI is wrong and the user could be either:
//   (a) blocked when they shouldn't be, or
//   (b) allowed to proceed when they should be paywalled.
//
// Both outcomes are unacceptable, hence: [CRITICAL] markers on the
// most important assertions.
//
// Cross-reference: `api/_lib/limits.ts` is the server-side source of
// truth.  Tests U1.1.1 and U1.1.2 enforce that the client constants
// stay in lockstep with the server.
//
// Test catalogue: `docs/11-test-plan.md` §1.1.
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/features/usage/usage.dart';

void main() {
  group('UsageSnapshot — plan defaults', () {
    test('[CRITICAL] Free plan constants match server-side api/_lib/limits.ts', () {
      // If this test fails, the server-side FREE_LIMITS was changed
      // without updating the client side -- the home screen meter will
      // show the wrong cap and the pre-flight check will let users
      // through who should be paywalled (or vice versa).
      expect(
        UsageSnapshot.freeLimitSeconds,
        900,
        reason: '15 minutes = 900 seconds',
      );
      expect(UsageSnapshot.freeLimitRecordings, 5);
      expect(
        UsageSnapshot.freeLimitPerRecordingSeconds,
        180,
        reason: '3 minutes per recording = 180 seconds',
      );
    });

    test('[CRITICAL] Pro plan constants match server-side api/_lib/limits.ts', () {
      expect(
        UsageSnapshot.proLimitSeconds,
        28800,
        reason: '8 hours = 28,800 seconds',
      );
      expect(UsageSnapshot.proLimitRecordings, 100);
      expect(
        UsageSnapshot.proLimitPerRecordingSeconds,
        1200,
        reason: '20 minutes per recording = 1200 seconds',
      );
    });
  });

  group('UsageSnapshot.empty', () {
    test('Free empty snapshot has zero usage and free limits applied', () {
      final s = UsageSnapshot.empty(plan: 'free', monthKey: '2026-05');

      expect(s.plan, 'free');
      expect(s.monthKey, '2026-05');
      expect(s.usedSeconds, 0);
      expect(s.usedRecordings, 0);
      expect(s.limitSeconds, UsageSnapshot.freeLimitSeconds);
      expect(s.limitRecordings, UsageSnapshot.freeLimitRecordings);
      expect(
        s.limitPerRecordingSeconds,
        UsageSnapshot.freeLimitPerRecordingSeconds,
      );
    });

    test('Pro empty snapshot applies Pro limits', () {
      final s = UsageSnapshot.empty(plan: 'pro', monthKey: '2026-05');

      expect(s.plan, 'pro');
      expect(s.limitSeconds, UsageSnapshot.proLimitSeconds);
      expect(s.limitRecordings, UsageSnapshot.proLimitRecordings);
      expect(
        s.limitPerRecordingSeconds,
        UsageSnapshot.proLimitPerRecordingSeconds,
      );
    });

    test('Unknown plan string falls back to free limits (defensive)', () {
      // Real-world: if RevenueCat returns a plan we don't recognize,
      // we must not accidentally give the user Pro limits.
      final s = UsageSnapshot.empty(
        plan: 'enterprise-trial',
        monthKey: '2026-05',
      );

      expect(s.limitSeconds, UsageSnapshot.freeLimitSeconds);
      expect(s.limitRecordings, UsageSnapshot.freeLimitRecordings);
    });
  });

  group('UsageSnapshot.fromFirestore', () {
    test('Null data block produces a zero-usage snapshot', () {
      final s = UsageSnapshot.fromFirestore(
        plan: 'free',
        monthKey: '2026-05',
        data: null,
      );

      expect(s.usedSeconds, 0);
      expect(s.usedRecordings, 0);
      expect(s.isAtCap, isFalse);
    });

    test('Empty map produces a zero-usage snapshot', () {
      final s = UsageSnapshot.fromFirestore(
        plan: 'free',
        monthKey: '2026-05',
        data: <String, dynamic>{},
      );

      expect(s.usedSeconds, 0);
      expect(s.usedRecordings, 0);
    });

    test('Parses counters from a real Firestore-shaped doc', () {
      final s = UsageSnapshot.fromFirestore(
        plan: 'pro',
        monthKey: '2026-05',
        data: <String, dynamic>{
          'transcriptionSeconds': 1234,
          'recordingsCount': 7,
          'plan': 'pro',
        },
      );

      expect(s.usedSeconds, 1234);
      expect(s.usedRecordings, 7);
      expect(s.plan, 'pro');
    });

    test('Tolerates int-as-double payloads (Firestore numeric coercion)', () {
      // Firestore sometimes returns numbers as doubles depending on the
      // server-side increment path. The parser must coerce safely.
      final s = UsageSnapshot.fromFirestore(
        plan: 'free',
        monthKey: '2026-05',
        data: <String, dynamic>{
          'transcriptionSeconds': 123.0,
          'recordingsCount': 2.0,
        },
      );

      expect(s.usedSeconds, 123);
      expect(s.usedRecordings, 2);
    });
  });

  group('UsageSnapshot.secondsProgress / recordingsProgress', () {
    test('Zero usage = zero progress', () {
      final s = UsageSnapshot.empty(plan: 'free', monthKey: '2026-05');

      expect(s.secondsProgress, 0.0);
      expect(s.recordingsProgress, 0.0);
    });

    test('Half usage = 0.5 progress', () {
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 450,
        usedRecordings: 2,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.secondsProgress, 0.5);
      expect(s.recordingsProgress, closeTo(0.4, 1e-9));
    });

    test('Full usage = 1.0 progress', () {
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 900,
        usedRecordings: 5,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.secondsProgress, 1.0);
      expect(s.recordingsProgress, 1.0);
    });

    test('Over-cap usage clamps to 1.0 (defensive)', () {
      // Server-side enforcement should make this impossible, but the UI
      // must never render a > 100% bar.
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 9999,
        usedRecordings: 50,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.secondsProgress, 1.0);
      expect(s.recordingsProgress, 1.0);
    });

    test('Zero limit returns 0 progress (division-by-zero guard)', () {
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 100,
        usedRecordings: 1,
        limitSeconds: 0,
        limitRecordings: 0,
        limitPerRecordingSeconds: 0,
      );

      expect(s.secondsProgress, 0.0);
      expect(s.recordingsProgress, 0.0);
    });

    test('worstProgress returns the higher of the two meters', () {
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 90,
        usedRecordings: 4,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.worstProgress, closeTo(0.8, 1e-9));
    });
  });

  group('UsageSnapshot.isAtCap', () {
    test('Not at cap when both meters are below limit', () {
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 600,
        usedRecordings: 3,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.isAtCap, isFalse);
    });

    test('[CRITICAL] At cap when recordings count >= limit (zero minutes)', () {
      // Pathological but real: 5 recordings of 0 seconds each. Backend
      // should reject, but if it slips through, the UI must still flag.
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 0,
        usedRecordings: 5,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.isAtCap, isTrue);
    });

    test('[CRITICAL] At cap when seconds >= limit (low recording count)', () {
      // Single 16-min recording on free tier (above 15-min cap).
      // Server should reject with `recording_too_long` -- this is the
      // belt-and-suspenders client-side flag.
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 960,
        usedRecordings: 1,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.isAtCap, isTrue);
    });

    test('At cap when slightly over (defensive: > limit, not just ==)', () {
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 901,
        usedRecordings: 6,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.isAtCap, isTrue);
    });
  });

  group('UsageSnapshot.remainingSeconds / remainingRecordings', () {
    test('Mid-month usage produces correct remaining', () {
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 300,
        usedRecordings: 2,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.remainingSeconds, 600);
      expect(s.remainingRecordings, 3);
    });

    test('Over-cap usage clamps remaining to zero (never negative)', () {
      const s = UsageSnapshot(
        plan: 'free',
        monthKey: '2026-05',
        usedSeconds: 1000,
        usedRecordings: 10,
        limitSeconds: 900,
        limitRecordings: 5,
        limitPerRecordingSeconds: 180,
      );

      expect(s.remainingSeconds, 0);
      expect(s.remainingRecordings, 0);
    });
  });

  group('UsageSnapshot.remainingMinutesLabel', () {
    UsageSnapshot snap(int usedSec, int limitSec) => UsageSnapshot(
          plan: 'pro',
          monthKey: '2026-05',
          usedSeconds: usedSec,
          usedRecordings: 0,
          limitSeconds: limitSec,
          limitRecordings: 100,
          limitPerRecordingSeconds: 1200,
        );

    test('Sub-minute remaining is shown in seconds', () {
      // 30 seconds remaining
      expect(snap(870, 900).remainingMinutesLabel, '30s');
    });

    test('Mid-range remaining shown as minutes + seconds', () {
      // 7 min 30 sec remaining
      expect(snap(450, 900).remainingMinutesLabel, '7m 30s');
    });

    test('Even minute remaining drops seconds', () {
      // exactly 5 min remaining
      expect(snap(600, 900).remainingMinutesLabel, '5m');
    });

    test('Multi-hour remaining shown as hours + minutes', () {
      // 1 hr 15 min remaining
      expect(snap(0, 4500).remainingMinutesLabel, '1h 15m');
    });

    test('Exact hour drops minutes', () {
      // exactly 8 hours
      expect(snap(0, 28800).remainingMinutesLabel, '8h');
    });

    test('Zero remaining shows 0s', () {
      expect(snap(900, 900).remainingMinutesLabel, '0s');
    });
  });
}
