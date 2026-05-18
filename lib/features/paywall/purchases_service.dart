import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config/env.dart';
import '../../core/logging/logger.dart';

final purchasesServiceProvider = Provider<PurchasesService>(
  (ref) => PurchasesService(),
);

class PurchasesService {
  bool _configured = false;

  Future<void> configure() async {
    if (_configured) return;
    if (Env.revenueCatApiKey.isEmpty) {
      logger.warning(
        'REVENUECAT_ANDROID_KEY not set; paywall will run in stub mode.',
      );
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cfg = PurchasesConfiguration(Env.revenueCatApiKey)
      ..appUserID = uid;
    await Purchases.configure(cfg);
    _configured = true;
  }

  Future<void> identify(String? userId) async {
    if (!_configured || userId == null) return;
    await Purchases.logIn(userId);
  }

  Future<void> logOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      logger.warning('Purchases.logOut: $e');
    }
  }

  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e, st) {
      logger.error('getOfferings failed', e, st);
      return null;
    }
  }

  Future<CustomerInfo> purchase(Package pkg) async {
    final result = await Purchases.purchasePackage(pkg);
    return result;
  }

  Future<CustomerInfo> restore() => Purchases.restorePurchases();

  Future<CustomerInfo?> customerInfo() async {
    if (!_configured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      logger.warning('customerInfo failed: $e');
      return null;
    }
  }

  bool isPro(CustomerInfo? info) {
    if (info == null) return false;
    final ent = info.entitlements.active[Env.entitlementId];
    return ent != null && ent.isActive;
  }

  Stream<CustomerInfo> customerInfoStream() {
    final controller = Stream<CustomerInfo>.multi((sub) {
      void listener(CustomerInfo info) => sub.add(info);
      Purchases.addCustomerInfoUpdateListener(listener);
      sub.onCancel = () => Purchases.removeCustomerInfoUpdateListener(listener);
    });
    return controller;
  }
}
