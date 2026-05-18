# RecapCoach API

Vercel serverless backend for the RecapCoach Flutter app. Wraps OpenAI Whisper
(speech-to-text) and `gpt-4o-mini` (summarization + action-item extraction)
behind a single endpoint so the app never sees the OpenAI API key.

## Endpoint

### `POST /api/transcribe`

Multipart upload. One field, `audio`, containing an audio file
(`audio/m4a` / `audio/aac` recommended, but Whisper accepts mp3, wav, webm, etc).

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
- `405` — wrong method (only POST is allowed)
- `500` — missing `OPENAI_API_KEY`, OpenAI request failed

## Required environment variables

Set in **Vercel → Project → Settings → Environment Variables**:

| Name             | Where it goes | Example                       |
| ---------------- | ------------- | ----------------------------- |
| `OPENAI_API_KEY` | Encrypted     | `sk-proj-...`                 |

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

The endpoint is currently anonymous — anyone with the URL can spam it and burn
your credits. Before publishing the app:

1. Send the user's Firebase ID token from Flutter:
   `Authorization: Bearer <idToken>`
2. Verify it on the server with `firebase-admin` SDK.
3. Optional: rate-limit per Firebase UID using Upstash Redis or Vercel KV.
