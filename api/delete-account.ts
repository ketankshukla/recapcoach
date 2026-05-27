/**
 * POST /api/delete-account
 *
 * Permanently deletes a user's account and all associated data.
 * Before deletion, writes a one-way SHA-256 hash of the user's email
 * to the `usedTrials` collection so that re-registration with the
 * same email cannot exploit the free tier again.
 *
 * The hash is NOT personal data — it's irreversible and cannot be
 * used to recover the email. This is GDPR-compatible: all PII
 * (email, name, recordings, usage) is deleted; only an anonymous
 * fingerprint remains.
 *
 * Pipeline:
 *   1. Verify Firebase ID token (auth gate).
 *   2. Look up the user in Firebase Auth to get their email.
 *   3. Compute SHA-256(email + salt) and write to /usedTrials/{hash}.
 *   4. Delete all Firestore data under /users/{uid}/...
 *   5. Delete the Firebase Auth user.
 *
 * Response (200):
 *   { "ok": true }
 *
 * Errors:
 *   401 - missing/invalid Firebase ID token
 *   500 - server error during deletion
 *
 * Auth:
 *   Caller MUST send `Authorization: Bearer <Firebase ID token>`.
 */
import type { VercelRequest, VercelResponse } from "@vercel/node";
import { createHash } from "crypto";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { requireFirebaseUser } from "./_lib/firebase-admin";

// Salt for the email hash. Not secret — just ensures our hashes
// don't collide with hashes from other systems.
const HASH_SALT = "recapcoach-trial-v1";

function hashEmail(email: string): string {
  return createHash("sha256")
    .update(`${HASH_SALT}:${email.toLowerCase().trim()}`)
    .digest("hex");
}

/**
 * Recursively delete all documents in a collection.
 * Firestore Admin SDK doesn't have a single "deleteCollection" call,
 * so we batch-delete in pages of 100.
 */
async function deleteCollection(
  collectionPath: string,
  batchSize = 100
): Promise<number> {
  const db = getFirestore();
  const collRef = db.collection(collectionPath);
  let deleted = 0;

  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await collRef.limit(batchSize).get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += snap.size;
  }
  return deleted;
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
): Promise<void> {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  // 1. Auth gate
  const decoded = await requireFirebaseUser(req, res);
  if (!decoded) return; // 401 already sent
  const uid = decoded.uid;

  try {
    const auth = getAuth();
    const db = getFirestore();

    // 2. Look up email from Firebase Auth
    let email: string | undefined;
    try {
      const userRecord = await auth.getUser(uid);
      email = userRecord.email;
    } catch (err) {
      console.error("[delete-account] Failed to fetch user record:", err);
      // Proceed even if we can't get the email — the user still
      // wants their data deleted. We just won't be able to write
      // the trial hash.
    }

    // 3. Write anonymous trial hash (if we have an email)
    if (email) {
      const hash = hashEmail(email);
      await db.doc(`usedTrials/${hash}`).set({
        createdAt: FieldValue.serverTimestamp(),
        // No PII stored — just the fact that this hash used a trial.
      });
      console.log(`[delete-account] Wrote trial hash for uid=${uid}`);
    } else {
      console.warn(
        `[delete-account] No email for uid=${uid}; skipping trial hash.`
      );
    }

    // 4. Delete all Firestore data for this user
    const notesDeleted = await deleteCollection(`users/${uid}/notes`);
    const usageDeleted = await deleteCollection(`users/${uid}/usage`);
    // Delete the user profile doc itself
    await db.doc(`users/${uid}`).delete();
    console.log(
      `[delete-account] Deleted Firestore data for uid=${uid}: ` +
        `${notesDeleted} notes, ${usageDeleted} usage docs, 1 profile doc.`
    );

    // 5. Delete the Firebase Auth user
    await auth.deleteUser(uid);
    console.log(`[delete-account] Deleted Firebase Auth user uid=${uid}`);

    res.status(200).json({ ok: true });
  } catch (err) {
    console.error("[delete-account] Error:", err);
    const message = err instanceof Error ? err.message : String(err);
    res.status(500).json({ error: `Account deletion failed: ${message}` });
  }
}
