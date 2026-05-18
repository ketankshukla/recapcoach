import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'purchases_service.dart';

final entitlementProvider = StreamProvider<bool>((ref) async* {
  final svc = ref.watch(purchasesServiceProvider);

  ref.listen(currentUserProvider, (prev, next) {
    if (next != null) svc.identify(next.uid);
  });

  final initial = await svc.customerInfo();
  yield svc.isPro(initial);

  await for (final info in svc.customerInfoStream()) {
    yield svc.isPro(info);
  }
});
