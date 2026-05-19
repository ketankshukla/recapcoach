# Local pre-deploy verification: run `vercel build` exactly the way
# Vercel's build cluster does, but on this machine, before pushing.
#
# Catches:
#   - TypeScript compile errors in api/*.ts (same as `tsc --noEmit`)
#   - vercel.json schema errors (typos in maxDuration, memory, etc.)
#   - Function-export shape errors
#   - Bundle size / runtime config drift
#
# Auth: reads the personal access token from secrets/vercel-cli-token
# (gitignored). To set up, see docs/SETUP.md section "Vercel CLI auth".
#
# Run via:
#   npm run vercel:build
# or directly:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\vercel-build.ps1

$ErrorActionPreference = 'Stop'

$tokenFile = Join-Path $PSScriptRoot '..\secrets\vercel-cli-token'

if (-not (Test-Path $tokenFile)) {
    Write-Host "ERROR: $tokenFile not found." -ForegroundColor Red
    Write-Host "Generate a token at https://vercel.com/account/tokens"
    Write-Host "and save it (just the raw vcp_... value) to:"
    Write-Host "  $tokenFile"
    exit 1
}

$token = (Get-Content $tokenFile -Raw).Trim()

# Tolerate either "VERCEL_TOKEN=vcp_..." or just the raw "vcp_..." value.
if ($token -match '^VERCEL_TOKEN=(.+)$') {
    $token = $matches[1].Trim()
}

if (-not $token.StartsWith('vcp_')) {
    Write-Host "ERROR: token in $tokenFile does not start with 'vcp_'." -ForegroundColor Red
    Write-Host "It should be a Vercel personal access token from"
    Write-Host "https://vercel.com/account/tokens"
    exit 1
}

Write-Host "Running vercel build (token: $($token.Length) chars)..."
Write-Host ""

vercel build --token $token

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "vercel build FAILED (exit $LASTEXITCODE). Do NOT commit." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "vercel build OK -- safe to commit." -ForegroundColor Green
