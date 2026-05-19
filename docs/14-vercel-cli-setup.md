# 14 — Vercel CLI: Local Pre-Deploy Verification

**Audience:** anyone setting up a fresh dev machine for RecapCoach.
**Goal:** be able to run `npm run vercel:build` locally to catch the same kinds
of errors the Vercel build cluster would catch, *before* pushing to GitHub.

This is our backend equivalent of `flutter test`. It runs on the machine, not
on Vercel's servers, so we never burn deploys on a typo.

---

## 1. Why we want this

`tsc --noEmit` (`npm run build`) catches TypeScript compile errors. That's
~95% of backend bugs.

But it does not catch:

- `vercel.json` schema errors (typo in `maxDuration`, `memory`, etc.)
- Function-export shape errors (e.g. forgetting `export default`)
- Bundle / runtime config drift (Node version mismatch, missing files in the
  bundle, etc.)
- Env var contract drift between dashboard and code

`vercel build` catches all of the above by running the exact same pipeline
the Vercel cluster runs, but locally and offline-from-deploy. If it succeeds
on your machine, it will (almost always) succeed on Vercel.

---

## 2. One-time setup

### 2a. Install the CLI globally

```powershell
npm install -g vercel
```

Verify:

```powershell
vercel --version
```

You should see `Vercel CLI 50.x` or later.

### 2b. Generate a Personal Access Token

1. Go to <https://vercel.com/account/tokens>
2. Click **Create Token**
3. **Name:** `recapcoach-cli` (or anything memorable)
4. **Scope:** `Full Account` is simplest. To restrict, pick the
   `recapcoach` project.
5. **Expiration:** 1 year (recommended).
6. Click **Create**.
7. **Copy the entire token**, including the `vcp_` prefix. The token is
   shown only once — if you lose it, you have to regenerate.

### 2c. Save the token to `secrets/vercel-cli-token`

The `secrets/` directory is gitignored. Save the raw token (just the
`vcp_...` value, no key=value, no quotes) to:

```
e:\recapcoach\secrets\vercel-cli-token
```

PowerShell one-liner:

```powershell
'vcp_REPLACE_WITH_YOUR_TOKEN' | Set-Content -Path secrets\vercel-cli-token -NoNewline
```

> **Note:** Do **not** put this in `.env.local`. The Vercel CLI treats
> `.env.local` as project runtime env vars and will overwrite it on
> `vercel link` / `vercel pull`. Keep `.env.local` for runtime vars and
> `secrets/vercel-cli-token` for CLI auth.

### 2d. Link the project (one-time per machine)

This creates `.vercel/project.json` (gitignored) so the CLI knows which
Vercel project this folder belongs to.

```powershell
$token = (Get-Content secrets\vercel-cli-token -Raw).Trim()
vercel link --yes --token $token
```

Expected output ends with:

```
✅  Linked to ketan-shuklas-projects-8feda58f/recapcoach (created .vercel and added it to .gitignore)
```

---

## 3. Day-to-day usage

```powershell
npm run vercel:build
```

This invokes `scripts/vercel-build.ps1`, which:

1. Reads the token from `secrets/vercel-cli-token`.
2. Validates it starts with `vcp_`.
3. Runs `vercel build --token <token>`.
4. Exits non-zero on failure with a clear "Do NOT commit" message.
5. Exits zero on success with a "safe to commit" message.

### Expected timings

| State | Time |
|---|---|
| First-ever cold run | 60–120 sec |
| Warm cache run | 10–20 sec |
| Failed build (early exit on TS error) | 5–15 sec |

### When to run

Per the **test-first commit discipline rule** (saved as a Cascade memory):

- **Every commit** that touches Dart code → `flutter test`.
- **Every commit** that touches TypeScript → `npm run build` (`tsc --noEmit`).
- **Every commit** that touches `api/**` or `vercel.json` → also run
  `npm run vercel:build` *before pushing*. Skipping is not allowed.

For commits that don't touch backend code (e.g. UI-only changes,
Dart unit tests, docs), `vercel build` is **not** required. The 60–120 sec
cold delay isn't worth it for non-backend changes.

---

## 4. Troubleshooting

### "Error: The specified token is not valid"

- The token has a typo. Generate a fresh one at
  <https://vercel.com/account/tokens> and re-save to
  `secrets/vercel-cli-token`.
- Or the token was revoked. Same fix.

### "Project not linked"

Re-run step **2d** above (`vercel link --yes --token $token`). The
`.vercel/` folder may have been deleted accidentally.

### "ENOENT: secrets/vercel-cli-token not found"

You haven't done step **2c** on this machine. Re-do it. The script will
print the path it expected.

### `vercel build` fails locally but not on Vercel

Almost never happens, but if it does:
- Make sure your local Node version matches `engines.node` in
  `package.json` (currently `20.x`). Use `nvm` / `volta` to switch.
- Delete `.vercel/output` and try again.
- Run `vercel pull` to refresh env vars from the dashboard.

### `vercel build` succeeds locally but fails on Vercel

This is the rare case `vercel build` was supposed to prevent, so investigate
hard:
- Check that you didn't add a dep that's only in `devDependencies` but
  imported from `api/`.
- Check that `vercel.json` runtime config matches what the Vercel cluster
  actually allows (e.g. `maxDuration` over the plan limit).
- Check the Vercel deploy logs for the exact error.

---

## 5. Security notes

- **`secrets/vercel-cli-token` is gitignored** (the whole `secrets/`
  directory is). Verify with: `git check-ignore -v secrets/vercel-cli-token`.
- **Token scope:** even with `Full Account`, this token can deploy and
  read project settings, but it cannot rotate billing methods or invite
  team members. Still, treat it like a password.
- **Rotation:** if you ever suspect the token leaked (pasted in chat,
  committed by accident, shared with a collaborator who left, etc.),
  rotate immediately at <https://vercel.com/account/tokens>. Cost: ~10 sec.
- **Why not `~/.vercel/auth.json`?** Vercel CLI's `vercel login` flow
  creates a global auth file in your home directory. That works, but it
  authenticates *the whole machine* rather than *the project*, which is
  harder to rotate per-project and harder to onboard a new dev to.
  `secrets/vercel-cli-token` keeps auth scoped to this repo.

---

## 6. Files involved

| File | Purpose | Tracked? |
|---|---|---|
| `scripts/vercel-build.ps1` | Wrapper that reads token + runs `vercel build` | ✅ tracked |
| `secrets/vercel-cli-token` | Raw `vcp_...` token | ❌ gitignored |
| `.vercel/project.json` | Project link metadata, created by `vercel link` | ❌ gitignored |
| `.env.local` | Project runtime env vars (managed by Vercel CLI) | ❌ gitignored |
| `package.json` `vercel:build` script | npm entry point | ✅ tracked |
| `vercel.json` | Function runtime config | ✅ tracked |

---

## 7. Related docs

- [`SETUP.md`](./SETUP.md) — full dev machine setup
- [`PUBLISH.md`](./PUBLISH.md) — release / Play Store flow
- [`09-quotas-and-safety.md`](./09-quotas-and-safety.md) — what the backend
  enforces
- Test-first commit discipline rule (Cascade memory) — when to run this
