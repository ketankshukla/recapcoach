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

  /// URL of the Vercel-hosted backend that exposes /api/transcribe.
  /// Pass via:  flutter run --dart-define=BACKEND_URL=https://<project>.vercel.app
  /// Leave empty in dev to make transcription gracefully fall back to "no backend configured".
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  static bool get isProd => flavor == Flavor.prod;
  static bool get isDev => flavor == Flavor.dev;
  static bool get hasBackend => backendUrl.isNotEmpty;
}
