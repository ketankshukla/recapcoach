enum Flavor { dev, prod }

class Env {
  static const Flavor flavor = Flavor.dev;

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'RecapCoach',
  );

  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: '',
  );

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@example.com',
  );

  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: 'https://ketankshukla.github.io/recapcoach/privacy.html',
  );

  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://ketankshukla.github.io/recapcoach/terms.html',
  );

  static const String entitlementId = String.fromEnvironment(
    'ENTITLEMENT_ID',
    defaultValue: 'pro',
  );

  static bool get isProd => flavor == Flavor.prod;
  static bool get isDev => flavor == Flavor.dev;
}
