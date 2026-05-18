# RecapCoach API

Vercel serverless backend for the RecapCoach Flutter app. Wraps OpenAI Whisper
(speech-to-text) and `gpt-4o-mini` (summarization + action-item extraction)
behind a single endpoint so the app never sees the OpenAI API key.

## Endpoint

### `POST /api/transcribe`

Multipart upload. One field, `audio`, containing an audio file
(`audio/m4a` / `audio/aac` recommended, but Whisper accepts mp3, wav, webm, etc).

**Required header:** `Authorization: Bearer <Firebase ID token>`. The server
verifies the token with the Firebase Admin SDK; anonymous requests are
rejected with `401`.

**Response (200):**

```json
{
  "transcript": "Hi, yeah so I'm just calling to follow up on the proposal...",
  "summary": "Discovery call with Acme about the billing migration. Budget confirmed; Q3 go-live target.",
  "actionItems": [
    "Send written proposal by Friday EOD",
    "Schedule deep-dive with their CTO next Tuesday"
  ]
}
```

**Errors:**

- `400` — no audio file, malformed multipart, file > 25 MB
- `401` — missing or invalid Firebase ID token
- `405` — wrong method (only POST is allowed)
- `500` — server misconfigured (missing env var) or OpenAI request failed

## Required environment variables

Set in **Vercel → Project → Settings → Environment Variables**, all **Encrypted**:

| Name                    | Source                                                                  |
| ----------------------- | ----------------------------------------------------------------------- |
| `OPENAI_API_KEY`        | OpenAI dashboard → API keys                                             |
| `FIREBASE_PROJECT_ID`   | Firebase Console → Project settings → General → Project ID              |
| `FIREBASE_CLIENT_EMAIL` | `client_email` from a downloaded service account JSON                   |
| `FIREBASE_PRIVATE_KEY`  | `private_key` from the same JSON (paste the full BEGIN/END block as-is) |

To generate the service account JSON:

1. Firebase Console → Project settings → **Service accounts** tab
2. Click **Generate new private key** → confirm
3. A JSON file downloads — copy `client_email` and `private_key` into Vercel
4. Never commit this JSON to git

## Deployment

This repo is a hybrid: Flutter app at the root, Vercel functions in `/api`.
`.vercelignore` excludes all Flutter files so the Vercel build only ships the
TypeScript functions.

1. In Vercel: **Add New → Project → Import** the `recapcoach` GitHub repo.
2. Framework Preset: **Other**.
3. Root Directory: keep as repo root (Vercel will pick up `api/*.ts` automatically).
4. Add the env var `OPENAI_API_KEY` for all environments.
5. Deploy. Every push to `main` will auto-redeploy.

After deployment, your endpoint will be:

```
https://<project>.vercel.app/api/transcribe
```

Set this URL on the Flutter side via `--dart-define=BACKEND_URL=https://...`.

## Local development

```sh
npm install
vercel dev
# → http://localhost:3000/api/transcribe
```

Local testing requires a `.env.local` with `OPENAI_API_KEY=sk-...`.
(That file is gitignored.)

## Cost estimate

For a 5-minute call recorded at 64 kbps AAC mono (~2.5 MB):

- Whisper: $0.006/min × 5 = **$0.03**
- gpt-4o-mini summarize (~800 input + 200 output tokens): **<$0.001**
- **Total: ~$0.03 per call**

Set a billing cap in your OpenAI dashboard while testing.

## Security TODO (post-MVP)

- [x] Verify Firebase ID token on every request (shipped)
- [ ] Rate-limit per Firebase UID using Upstash Redis or Vercel KV
- [ ] Add request signing or CSRF token for additional defense-in-depth
