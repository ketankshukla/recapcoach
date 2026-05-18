/**
 * Lazy-initialized Firebase Admin SDK singleton for verifying ID tokens.
 *
 * Required env vars (set in Vercel project settings):
 *   FIREBASE_PROJECT_ID   - e.g. "recapcoach-dev"
 *   FIREBASE_CLIENT_EMAIL - from the service account JSON
 *   FIREBASE_PRIVATE_KEY  - from the service account JSON; \n line breaks must
 *                           be preserved (Vercel stores the literal "\n" string
 *                           which we convert below).
 *
 * If any of those env vars are missing, requests will be rejected with 500
 * "Server misconfigured" rather than silently allowing anonymous access.
 */
import {
  initializeApp,
  getApps,
  cert,
  type App,
} from 'firebase-admin/app';
import { getAuth, type DecodedIdToken } from 'firebase-admin/auth';
import type { VercelRequest, VercelResponse } from '@vercel/node';

let cachedApp: App | null = null;

function adminApp(): App {
  if (cachedApp) return cachedApp;
  const existing = getApps();
  if (existing.length > 0) {
    cachedApp = existing[0];
    return cachedApp;
  }
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKeyRaw = process.env.FIREBASE_PRIVATE_KEY;
  if (!projectId || !clientEmail || !privateKeyRaw) {
    throw new Error(
      'Firebase Admin not configured: set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in Vercel.',
    );
  }
  // Vercel stores \n as the literal two-character sequence; PEM parser needs
  // real newlines.
  const privateKey = privateKeyRaw.replace(/\\n/g, '\n');
  cachedApp = initializeApp({
    credential: cert({ projectId, clientEmail, privateKey }),
  });
  return cachedApp;
}

/**
 * Extract and verify the Firebase ID token on the incoming request.
 *
 * On success, returns the decoded token (includes `uid`, `email`, etc).
 * On failure, writes a 401/500 response and returns null. Callers should
 * `return` immediately when null is returned.
 */
export async function requireFirebaseUser(
  req: VercelRequest,
  res: VercelResponse,
): Promise<DecodedIdToken | null> {
  const header = req.headers.authorization ?? '';
  const match = /^Bearer\s+(.+)$/i.exec(header);
  if (!match) {
    res.status(401).json({
      error: 'Missing or malformed Authorization header. Expected "Bearer <Firebase ID token>".',
    });
    return null;
  }
  const idToken = match[1].trim();

  let app: App;
  try {
    app = adminApp();
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    res.status(500).json({ error: `Server misconfigured: ${message}` });
    return null;
  }

  try {
    return await getAuth(app).verifyIdToken(idToken);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    res.status(401).json({ error: `Invalid ID token: ${message}` });
    return null;
  }
}
