/**
 * Plan limits for RecapCoach (Hybrid pricing tier).
 *
 * These are the SAFE defaults baked into the backend. They can be overridden
 * at runtime by writing to `/config/global` in Firestore -- useful for raising
 * limits during a promo, or dropping them to zero as an emergency kill switch.
 *
 * Cost basis (OpenAI Whisper @ $0.006/min):
 *   Free max:   15 min / user / month  -> ~$0.09 / user / month
 *   Pro max:    8 hr  / user / month   -> ~$2.88 / user / month
 *   Pro price:  $7.99 / mo ($6.79 net after Google Play 15% fee)
 *   Pro margin: ~58% per user at maximum usage
 */

export type Plan = 'free' | 'pro';

export interface PlanLimits {
  /** Max seconds of audio per single recording. */
  maxRecordingSeconds: number;
  /** Max total seconds of audio that can be transcribed per calendar month. */
  maxMonthlySeconds: number;
  /** Max number of recordings that can be transcribed per calendar month. */
  maxMonthlyRecordings: number;
  /** Hard upload size cap before we even read the file (anti-abuse). */
  maxFileBytes: number;
}

export const FREE_LIMITS: PlanLimits = {
  maxRecordingSeconds: 180,        // 3 minutes
  maxMonthlySeconds: 900,          // 15 minutes total / month
  maxMonthlyRecordings: 5,
  maxFileBytes: 5 * 1024 * 1024,   // 5 MB
};

export const PRO_LIMITS: PlanLimits = {
  maxRecordingSeconds: 1200,       // 20 minutes
  maxMonthlySeconds: 28800,        // 8 hours total / month
  maxMonthlyRecordings: 100,
  maxFileBytes: 25 * 1024 * 1024,  // 25 MB (OpenAI Whisper's own cap)
};

export function limitsFor(plan: Plan): PlanLimits {
  return plan === 'pro' ? PRO_LIMITS : FREE_LIMITS;
}

/**
 * Returns the current `YYYY-MM` key in UTC. Used as the Firestore document
 * id for monthly usage buckets so all users roll over at the same instant.
 */
export function currentMonthKey(now: Date = new Date()): string {
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}
