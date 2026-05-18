# Publishing to Google Play

End-to-end checklist for getting `recapcoach` (or any app cloned from it) live on the Play Store. Assumes `docs/SETUP.md` is done.

## 1. Configure release signing

Edit `android/app/build.gradle` — find the `android { ... }` block and ensure it contains:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        release {
            keyAlias keystoreProperties["keyAlias"]
            keyPassword keystoreProperties["keyPassword"]
            storeFile keystoreProperties["storeFile"] ? file(keystoreProperties["storeFile"]) : null
            storePassword keystoreProperties["storePassword"]
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

Also set `minSdkVersion 23`, `targetSdkVersion 35`, and `compileSdkVersion 35` (Google's current target for new apps).

## 2. App identity

- `applicationId` in `android/app/build.gradle` → e.g. `com.ketankshukla.recapcoach`
- `pubspec.yaml` `version: 1.0.0+1` (semver+build)
- App icon: replace `assets/icons/app_icon.png` (1024×1024 PNG) and run:

```powershell
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

## 3. Build a release AAB locally

```powershell
flutter build appbundle --release `
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxxxxxxx `
  --dart-define=SUPPORT_EMAIL=you@example.com
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

## 4. Create the Play Console listing

1. https://play.google.com/console → **Create app**
2. App details: name, default language, app/game type, free/paid.
3. Complete **all** the policy declarations (data safety, ads, target audience, content rating, government apps, news, etc.). Save Draft after each section.
4. **Store listing** → app name (30 chars max), short description (80 chars), full description (4000 chars), graphics:
   - App icon: 512×512 PNG
   - Feature graphic: 1024×500 PNG
   - 2–8 phone screenshots (min 320 px, 16:9 or 9:16)
5. **Privacy Policy URL** → paste your hosted URL (must return 200).

## 5. Wire Play Console to RevenueCat (one-time)

To let RevenueCat read your subscription status server-side:

1. Play Console → **API access** → link your Google Cloud project → create a service account with role **Service Account User** + **Pub/Sub Admin**.
2. Grant the service account access in Play Console (Users & permissions → invite → grant Finance + View app info on the app).
3. Download the service account JSON.
4. Upload it in RevenueCat → Project Settings → Apps → your Android app → **Play Store credentials**.

## 6. Create subscription products in Play Console

Play Console → **Monetize** → **Subscriptions** → create:

- Product ID: `pro_monthly`
  - Base plan: `monthly` — auto-renewing, 1 month
  - Price: e.g. $6.99/mo
  - Optional offer: 3-day free trial for new users
- Product ID: `pro_annual`
  - Base plan: `yearly` — auto-renewing, 1 year
  - Price: e.g. $39.99/yr
  - Optional offer: 3-day free trial

Activate both. **Product IDs MUST match** what you entered in RevenueCat → Products.

## 7. Closed testing (Google's 14-day / 20-tester rule)

New personal developer accounts must run a **closed test with 20+ testers for 14 consecutive days** before being allowed to release to production. Plan for this.

1. Play Console → **Testing** → **Closed testing** → create track → upload AAB.
2. Add an email list of 20+ testers (or create a Google Group).
3. Share the opt-in link from the track's "Testers" tab.
4. Recruit testers from: niche subreddits, Discord communities your target users hang in, friends. Pay $5 Amazon cards if needed — still cheap.

Watch Play Console for review status. First review usually takes 1–7 days.

## 8. Production release

After 14 days of closed testing + 20 testers:

1. Play Console → **Production** → **Create new release** → upload same AAB (or new build).
2. Release notes (max 500 chars).
3. Set rollout: start at 20%, monitor crashes for 24h, then ramp to 100%.

## 9. Post-launch operations

Daily for the first 30 days:

- Check **Crashlytics** dashboard. Ship a bugfix release for any crash affecting >0.5% of users.
- Reply to every Play Store review within 24h. Play ranks responsive devs.
- Watch RevenueCat dashboard: trial start → conversion %. Target ≥10%.

Weekly:

- ASO iteration: re-keyword the short description, swap one screenshot.
- Run an A/B test on one paywall element via RevenueCat experiments.

## 10. CI release (after first manual publish)

Tag a version to trigger the GitHub Actions workflow:

```powershell
git tag v1.0.1
git push origin v1.0.1
```

The workflow builds a signed AAB and uploads it as a GitHub artifact. Download it and upload to Play Console (or extend the workflow with `r0adkll/upload-google-play` to push automatically).

GitHub secrets required for CI:

- `ANDROID_KEYSTORE_BASE64` — `[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\upload-keystore.jks"))`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `GOOGLE_SERVICES_JSON` — full contents of `android/app/google-services.json`
- `REVENUECAT_ANDROID_KEY`

## 11. Reality checks

- **Reviews are stricter for AI apps.** Expect rejections about "AI content policy" — add a clear disclosure in onboarding and in Settings.
- **Subscriptions require an obvious cancel path.** The "Manage subscription" link in `SettingsScreen` covers this.
- **You must offer account deletion.** Already wired in Settings → Delete account.
- **Don't soft-launch in the US first** if you're worried. Some devs soft-launch in IN/PH/BR to get reviews and ASO signal before targeting US.
