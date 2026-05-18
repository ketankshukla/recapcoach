// Unit tests for the `currentUtcMonthKey()` helper -- the function that
// determines which `/users/{uid}/usage/{YYYY-MM}` document a user's
// counters belong to.
//
// This is shared with the backend's `currentMonthKey()` in
// `api/_lib/limits.ts`; the two MUST produce identical keys for the
// same instant in time. Otherwise the client reads the wrong doc and
// the meter on the home screen doesn't update.
//
// Test catalogue: `docs/11-test-plan.md` §1.1 (U1.1.13, U1.1.14).
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/features/usage/usage_provider.dart';

void main() {
  group('currentUtcMonthKey()', () {
    test('Produces YYYY-MM format', () {
      final key = currentUtcMonthKey(DateTime.utc(2026, 5, 18, 12));
      expect(key, '2026-05');
    });

    test('Pads single-digit months with a leading zero', () {
      expect(currentUtcMonthKey(DateTime.utc(2026)), '2026-01');
      expect(
        currentUtcMonthKey(DateTime.utc(2026, 9, 30, 23, 59, 59)),
        '2026-09',
      );
    });

    test('December rolls correctly (no off-by-one on month index)', () {
      expect(
        currentUtcMonthKey(DateTime.utc(2026, 12, 31, 23, 59, 59)),
        '2026-12',
      );
    });

    test('Uses 4-digit year padding', () {
      expect(currentUtcMonthKey(DateTime.utc(999, 5, 1)), '0999-05');
    });

    test('[CRITICAL] A local time on Apr 30 at 11pm Pacific is May UTC', () {
      // Pacific Daylight Time is UTC-7.  11pm PDT on Apr 30 is 6am UTC on
      // May 1.  The user's counters should belong to the May bucket, not
      // the April one -- otherwise their "monthly" quota silently
      // resets one day late.
      //
      // We construct the instant in UTC explicitly to avoid depending on
      // the test runner's local timezone.
      final aprilLateNightPdt = DateTime.utc(2026, 5, 1, 6);

      expect(
        currentUtcMonthKey(aprilLateNightPdt),
        '2026-05',
        reason: 'Month rollover must happen at midnight UTC, '
            'not midnight local.',
      );
    });

    test('[CRITICAL] A local time on May 1 at 1am Tokyo is still April UTC', () {
      // Tokyo is UTC+9.  1am JST on May 1 is 4pm UTC on Apr 30.
      // Counters must still belong to the April bucket.
      final tokyoEarlyMayJst = DateTime.utc(2026, 4, 30, 16);

      expect(
        currentUtcMonthKey(tokyoEarlyMayJst),
        '2026-04',
        reason: 'A user in Tokyo on May 1 1am is still in April UTC; '
            'their April quota has not yet rolled over.',
      );
    });

    test('Uses DateTime.now() when no argument is provided', () {
      // We can't assert the exact value, but it must be a non-empty
      // YYYY-MM string and match the current UTC instant's year+month.
      final key = currentUtcMonthKey();
      final now = DateTime.now().toUtc();
      final y = now.year.toString().padLeft(4, '0');
      final m = now.month.toString().padLeft(2, '0');

      expect(key, '$y-$m');
      expect(key.length, 7);
      expect(key[4], '-');
    });

    test('Idempotent for the same instant', () {
      final t = DateTime.utc(2026, 5, 18, 12);

      expect(currentUtcMonthKey(t), currentUtcMonthKey(t));
    });
  });
}
