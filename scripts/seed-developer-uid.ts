/**
 * One-time script: seeds the developer UID into Firestore
 * `/config/global.developerUids`.
 *
 * Usage:
 *   npx tsx scripts/seed-developer-uid.ts <firebase-uid>
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_SERVICE_ACCOUNT_KEY
 * env var pointing to / containing the service-account JSON.
 */

import { initializeApp, cert, type ServiceAccount } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as fs from "fs";
import * as path from "path";

const uid = process.argv[2];
if (!uid) {
  console.error("Usage: npx tsx scripts/seed-developer-uid.ts <firebase-uid>");
  process.exit(1);
}

// Try multiple sources for the service-account key.
let credential: ReturnType<typeof cert> | undefined;

// 1. GOOGLE_APPLICATION_CREDENTIALS file path.
const gacPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (gacPath && fs.existsSync(gacPath)) {
  credential = cert(
    JSON.parse(fs.readFileSync(gacPath, "utf-8")) as ServiceAccount
  );
}

// 2. FIREBASE_SERVICE_ACCOUNT_KEY env var (inline JSON, used by Vercel).
if (!credential && process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
  credential = cert(
    JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY) as ServiceAccount
  );
}

// 3. Local secrets file (gitignored).
if (!credential) {
  const localPath = path.resolve(__dirname, "../secrets/firebase-admin.json");
  if (fs.existsSync(localPath)) {
    credential = cert(
      JSON.parse(fs.readFileSync(localPath, "utf-8")) as ServiceAccount
    );
  }
}

if (!credential) {
  console.error(
    "No Firebase service-account credentials found.\n" +
      "Set GOOGLE_APPLICATION_CREDENTIALS, FIREBASE_SERVICE_ACCOUNT_KEY,\n" +
      "or place the JSON at secrets/firebase-admin.json."
  );
  process.exit(1);
}

initializeApp({ credential });

const doc = getFirestore().doc("config/global");
await doc.set({ developerUids: FieldValue.arrayUnion([uid]) }, { merge: true });

console.log(`✓ Added ${uid} to /config/global.developerUids`);
process.exit(0);
