# Setup — recapcoach

One-time setup for your Windows 11 dev machine + your first Google Play app. Roughly 1 focused evening (excluding the Play Console ID-verification wait).

## 0. Prerequisites

- Windows 11
- ~10 GB free disk
- A Google account (the one that will own your Play Console + Firebase)

## 1. Install the toolchain

```powershell
# From repo root, in an elevated PowerShell:
.\scripts\install-flutter.ps1
```

Then in a **new** PowerShell window:

```powershell
flutter doctor
flutter doctor --android-licenses    # press y to all
```

You'll also need:

- **Android Studio** (for the Android SDK + emulator). Download: https://developer.android.com/studio
  - On first launch, install: Android SDK Platform 34 + 35, Android SDK Build-Tools, Android Emulator, Android SDK Platform-Tools.
  - Create a Pixel 7 (API 34) emulator.
- **JDK 17** is what Android Gradle Plugin officially supports. You have JDK 23 installed; if Gradle complains, install JDK 17 from https://adoptium.net/ and set `JAVA_HOME` to it.
- **VS Code** + Flutter + Dart extensions (recommended editor).
- **Inter font** (or remove `fontFamily: 'Inter'` from `lib/core/theme/app_theme.dart`).

Verify:

```powershell
flutter doctor   # should be all-green for Android
```

## 2. Generate Android platform code

```powershell
flutter create . --org com.ketankshukla --project-name recapcoach --platforms=android
```

This adds the `android/` folder around our existing `lib/` and `pubspec.yaml`. Existing files are preserved.

## 3. Create the Firebase project

1. Go to https://console.firebase.google.com → **Add project** → name it `recapcoach` (or your app name) → enable Google Analytics.
2. Inside the project: enable **Authentication** → Sign-in method → enable **Email/Password** and **Google**.
3. Enable **Firestore Database** (Native mode, location closest to your users).
4. Enable **Crashlytics**, **Analytics**, **Remote Config**, **Cloud Messaging**.

## 4. Wire Firebase to the app

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

Choose your Firebase project, select **Android only**. The CLI generates:
- `lib/firebase_options.dart` — gitignored, holds API keys
- `android/app/google-services.json` — gitignored

Delete `lib/firebase_options_template.dart` once `lib/firebase_options.dart` exists.

Add SHA-1 fingerprints (required for Google Sign-In to work):

```powershell
# Debug SHA-1 (for local testing):
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Paste the `SHA1:` value into Firebase Console → Project Settings → Your Android app → **Add fingerprint**. Re-run `flutterfire configure` to refresh `google-services.json`.

## 5. Generate the upload keystore (do once, **back this up forever**)

```powershell
keytool -genkey -v -keystore $env:USERPROFILE\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Move the keystore into the project under `android/app/upload-keystore.jks` and create `android/key.properties`:

```
storePassword=<the password you chose>
keyPassword=<the password you chose>
keyAlias=upload
storeFile=upload-keystore.jks
```

**Critical:** if you lose this keystore you can never push updates to your app. Back it up to a password manager + offline drive.

Then edit `android/app/build.gradle` to use it for release builds — see `docs/PUBLISH.md` step 1.

## 6. Set up RevenueCat (paywall + subscriptions)

1. Sign up at https://app.revenuecat.com (free).
2. Create a project (name = your app).
3. Add an **Android app** → bundle ID = `com.ketankshukla.recapcoach`. RevenueCat will ask for a Google Play service-account credential — set this up later before launch (see PUBLISH.md step 5).
4. In RevenueCat → **Products** → add `pro_monthly` and `pro_annual`. These IDs must later match the product IDs you create in Play Console.
5. In RevenueCat → **Offerings** → create `default` offering with both packages.
6. In RevenueCat → **Entitlements** → create entitlement `pro`, attach both products.
7. Copy the **Android Public SDK Key** from RevenueCat → Project Settings → API keys.

Pass it at build time via `--dart-define`:

```powershell
flutter run --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxxxxxxx
```

In CI it's already wired via the `REVENUECAT_ANDROID_KEY` GitHub secret.

## 7. Host your privacy policy & terms

1. Fill in `docs/PRIVACY_POLICY_TEMPLATE.md` and `docs/TERMS_TEMPLATE.md`.
2. Convert each to simple HTML (or Markdown rendered by GitHub Pages).
3. Push them to a public repo (e.g. a `policies/` folder in your GitHub Pages site at `ketankshukla.github.io`).
4. Update `lib/core/config/env.dart` defaults (`privacyPolicyUrl`, `termsUrl`) **or** override per-build with `--dart-define`.

Google Play **will reject** your app if these URLs 404.

## 8. First run

```powershell
flutter pub get
flutter run --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxxxxxxx
```

Expected:
- Onboarding screen appears (skipped after first run).
- Sign-in screen: try "Skip — try it first" for anonymous, or Google sign-in (requires SHA-1 set up).
- Home screen shows Pro upgrade card.
- Tap any Pro feature → routed to Paywall.
- Paywall will show "Products will appear here once RevenueCat is configured" until step 6 is done.

## 9. (Optional) Pay for Google Play Console — do this in parallel

- Go to https://play.google.com/console/signup
- Pay the **$25 USD** one-time fee.
- Complete ID verification (now takes 1–14 days). **Start this today even if you're still coding** — the wait is the gating step for first launch.

When verification clears, continue with `docs/PUBLISH.md`.
