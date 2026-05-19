/// Pure-logic helper that maps a [DateTime] to a human-friendly greeting.
///
/// Used by the home-screen app bar so signed-in users see "Good morning,
/// Ketan" / "Good afternoon, Ketan" / "Good evening, Ketan" depending on
/// the device clock.
///
/// Kept as a static helper (no `BuildContext`, no Riverpod) so the
/// time-of-day → greeting mapping is trivially unit-testable with no
/// widget infra.
class TimeBasedGreeting {
  TimeBasedGreeting._();

  /// Returns one of `'Good morning'`, `'Good afternoon'`, `'Good evening'`.
  ///
  /// Buckets:
  ///  - `[5:00, 12:00)`  → `Good morning`
  ///  - `[12:00, 17:00)` → `Good afternoon`
  ///  - `[17:00, 24:00)` and `[0:00, 5:00)` → `Good evening`
  ///
  /// The `< 5:00` rollover is deliberate: at 2 a.m. the user is more
  /// plausibly winding down a late evening than waking for the day.
  static String forTime(DateTime t) {
    final h = t.hour;
    if (h < 5) return 'Good evening';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Convenience wrapper around [forTime] using `DateTime.now()`.
  static String now() => forTime(DateTime.now());
}
