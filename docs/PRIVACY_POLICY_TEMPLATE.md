# Privacy Policy — {{APP_NAME}}

**Effective date:** {{DATE}}
**Operator:** {{YOUR_NAME or YOUR_COMPANY}}
**Contact:** {{SUPPORT_EMAIL}}

This Privacy Policy explains what data {{APP_NAME}} ("the App", "we") collects, why, how it is used, and your choices.

## 1. Data we collect

### a) Account data
If you create an account, we store your email address and a Firebase Authentication user ID. If you sign in with Google, we receive your email and display name from Google.

### b) Anonymous user data
If you use the App as a guest, we generate a random anonymous ID. No personal information is collected.

### c) Usage analytics
We use **Firebase Analytics** and **Firebase Crashlytics** to understand which features are used and to diagnose crashes. These services may collect:
- Device model, OS version, app version
- Country / region (not precise location)
- Anonymized advertising ID (only if you have not opted out at the OS level)
- Crash logs (stack traces, device state at time of crash)

### d) Purchase data
Subscription purchases are processed by **Google Play Billing** and managed by **RevenueCat**. We do not see your credit card. We receive: product ID purchased, purchase date, renewal status, country.

### e) {{APP_SPECIFIC_DATA — e.g. "voice recordings you create"}}
{{Describe specifically what content the user creates and where it is stored — on-device only, in Firestore, in your backend, sent to an AI provider, etc. Be explicit.}}

## 2. Third parties we share data with

| Provider | Purpose | Data shared |
|---|---|---|
| Google Firebase | Auth, analytics, crash reporting, storage | Account ID, usage events, crash logs |
| Google Play Billing | Subscription processing | Purchase tokens |
| RevenueCat | Subscription management | Anonymized user ID, purchase events |
| {{OpenAI / Anthropic / etc. if applicable}} | {{AI processing}} | {{What content is sent}} |

We do **not** sell your data.

## 3. Data retention

- Account & app data: kept while your account is active.
- Crash logs & analytics: retained per Firebase defaults (up to 14 months).
- After account deletion: data is removed within 30 days.

## 4. Your rights

- **Access / export:** email {{SUPPORT_EMAIL}} and we will provide a copy of your data within 30 days.
- **Delete:** use Settings → Delete account, or email us.
- **Opt out of analytics:** disable in Settings → Privacy (if applicable to your build).

## 5. Children

The App is not directed to children under 13 (or the equivalent minimum age in your jurisdiction). We do not knowingly collect data from children.

## 6. Security

Data in transit is encrypted with TLS. Data at rest in Firebase is encrypted by Google. Subscription tokens are stored only by Google Play and RevenueCat.

## 7. Changes

We will post any changes to this policy at the URL where you found this document and update the "Effective date" above.

## 8. Contact

Email: {{SUPPORT_EMAIL}}
