// Unit tests for `TimeBasedGreeting`. Pure-logic, no widget infra.
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/features/home/widgets/time_based_greeting.dart';

void main() {
  group('TimeBasedGreeting.forTime', () {
    test('Returns "Good morning" at 5:00 (lower morning boundary)', () {
      expect(
        TimeBasedGreeting.forTime(DateTime(2026, 5, 18, 5)),
        'Good morning',
      );
    });

    test('Returns "Good morning" at 11:59', () {
      expect(
        TimeBasedGreeting.forTime(DateTime(2026, 5, 18, 11, 59)),
        'Good morning',
      );
    });

    test('Returns "Good afternoon" at 12:00 (noon boundary)', () {
      expect(
        TimeBasedGreeting.forTime(DateTime(2026, 5, 18, 12)),
        'Good afternoon',
      );
    });

    test('Returns "Good afternoon" at 16:59', () {
      expect(
        TimeBasedGreeting.forTime(DateTime(2026, 5, 18, 16, 59)),
        'Good afternoon',
      );
    });

    test('Returns "Good evening" at 17:00 (evening boundary)', () {
      expect(
        TimeBasedGreeting.forTime(DateTime(2026, 5, 18, 17)),
        'Good evening',
      );
    });

    test('Returns "Good evening" at 23:59', () {
      expect(
        TimeBasedGreeting.forTime(DateTime(2026, 5, 18, 23, 59)),
        'Good evening',
      );
    });

    test('Returns "Good evening" at midnight (late-night override)', () {
      // 0:00-4:59 is treated as "evening" because the user is winding
      // down a late night, not waking up for the day.
      expect(
        TimeBasedGreeting.forTime(DateTime(2026, 5, 18, 0)),
        'Good evening',
      );
    });

    test('Returns "Good evening" at 4:59 (morning boundary minus 1 min)', () {
      expect(
        TimeBasedGreeting.forTime(DateTime(2026, 5, 18, 4, 59)),
        'Good evening',
      );
    });
  });

  group('TimeBasedGreeting.now', () {
    test('Returns one of the three valid greetings', () {
      // We can't pin the clock here, but the result must always be one
      // of the three known strings -- if anyone ever returns null or
      // an off-list value we want to know.
      expect(
        TimeBasedGreeting.now(),
        anyOf(['Good morning', 'Good afternoon', 'Good evening']),
      );
    });
  });
}
