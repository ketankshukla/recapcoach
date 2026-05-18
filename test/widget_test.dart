// Placeholder test. Real widget/integration tests will be added once the
// recording flow and Firebase test harness are wired up.
//
// Pumping the actual app here is non-trivial because main() initializes
// Firebase, Hive, and RevenueCat. We'll add a proper test rig later.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanity', () {
    expect(1 + 1, 2);
  });
}
