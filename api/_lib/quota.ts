/**
 * Server-side quota enforcement for /api/transcribe.
 *
 * Data model (Firestore):
 *
 *   /config/global
 *     { transcriptionEnabled: bool,
 *       freeOverride:  PlanLimits | null,
 *       proOverride:   PlanLimits | null }
 *
 *   /users/{uid}
 *     { plan: 'free' | 'pro', ... }   // mirrored from RevenueCat webhook
 *
 *   /users/{uid}/usage/{YYYY-MM}
 *     { transcriptionSeconds: number,
 *       recordingsCount: number,
 *       lastTranscriptionAt: Timestamp }
 *
 * Clients are allowed to READ their own /users/{uid}/usage/* docs but cannot
 * write them -- only this backend (running as the service account) increments
 * the counters.  See firestore.rules.
 */

import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import {
  FREE_LIMITS,
  PRO_LIMITS,
  type Plan,
  type PlanLimits,
  currentMonthKey,
  limitsFor,
} from './limits';

export class QuotaExceededError extends Error {
  constructor(
    message: string,
    public readonly reason:
      | 'kill_switch'
      | 'recording_too_long'
      | 'file_too_large'
      | 'monthly_minutes'
      | 'monthly_recordings',
    public readonly plan: Plan,
    public readonly limits: PlanLimits,
    public readonly used: { seconds: number; count: number },
  ) {
    super(message);
    this.name = 'QuotaExceededError';
  }
}

export class TranscriptionDisabledError extends Error {
  constructor(message = 'Transcription is temporarily disabled.') {
    super(message);
    this.name = 'TranscriptionDisabledError';
  }
}

interface GlobalConfig {
  transcriptionEnabled: boolean;
  freeOverride: Partial<PlanLimits> | null;
  proOverride: Partial<PlanLimits> | null;
}

const DEFAULT_GLOBAL: GlobalConfig = {
  transcriptionEnabled: true,
  freeOverride: null,
  proOverride: null,
};

/** Read /config/global with safe defaults if the doc is missing. */
async function readGlobalConfig(): Promise<GlobalConfig> {
  const snap = await getFirestore().doc('config/global').get();
  if (!snap.exists) return DEFAULT_GLOBAL;
  const data = snap.data() ?? {};
  return {
    transcriptionEnabled: data.transcriptionEnabled !== false, // default true
    freeOverride: (data.freeOverride as Partial<PlanLimits> | undefined) ?? null,
    proOverride: (data.proOverride as Partial<PlanLimits> | undefined) ?? null,
  };
}

/** Look up the user's plan (defaults to 'free' if no /users/{uid} doc). */
async function readUserPlan(uid: string): Promise<Plan> {
  const snap = await getFirestore().doc(`users/${uid}`).get();
  if (!snap.exists) return 'free';
  const plan = snap.data()?.plan;
  return plan === 'pro' ? 'pro' : 'free';
}

/** Read this month's usage counters for the user. */
async function readMonthlyUsage(
  uid: string,
  monthKey: string,
): Promise<{ seconds: number; count: number }> {
  const snap = await getFirestore()
    .doc(`users/${uid}/usage/${monthKey}`)
    .get();
  if (!snap.exists) return { seconds: 0, count: 0 };
  const d = snap.data() ?? {};
  return {
    seconds: Number(d.transcriptionSeconds ?? 0) || 0,
    count: Number(d.recordingsCount ?? 0) || 0,
  };
}

export interface QuotaContext {
  plan: Plan;
  limits: PlanLimits;
  used: { seconds: number; count: number };
  monthKey: string;
}

/**
 * Build the user's quota context (plan + effective limits + current usage).
 * Throws TranscriptionDisabledError if the global kill switch is flipped.
 */
export async function loadQuotaContext(uid: string): Promise<QuotaContext> {
  const [cfg, plan] = await Promise.all([readGlobalConfig(), readUserPlan(uid)]);
  if (!cfg.transcriptionEnabled) {
    throw new TranscriptionDisabledError();
  }
  const base = limitsFor(plan);
  const override = plan === 'pro' ? cfg.proOverride : cfg.freeOverride;
  const limits: PlanLimits = override
    ? {
        maxRecordingSeconds: override.maxRecordingSeconds ?? base.maxRecordingSeconds,
        maxMonthlySeconds: override.maxMonthlySeconds ?? base.maxMonthlySeconds,
        maxMonthlyRecordings: override.maxMonthlyRecordings ?? base.maxMonthlyRecordings,
        maxFileBytes: override.maxFileBytes ?? base.maxFileBytes,
      }
    : base;
  const monthKey = currentMonthKey();
  const used = await readMonthlyUsage(uid, monthKey);
  return { plan, limits, used, monthKey };
}

/** Enforce hard file-size cap BEFORE we even parse the upload body. */
export function assertFileSizeAllowed(
  fileBytes: number,
  ctx: QuotaContext,
): void {
  if (fileBytes > ctx.limits.maxFileBytes) {
    throw new QuotaExceededError(
      `File too large for ${ctx.plan} plan: ${fileBytes} bytes > ${ctx.limits.maxFileBytes} bytes limit.`,
      'file_too_large',
      ctx.plan,
      ctx.limits,
      ctx.used,
    );
  }
}

/**
 * Enforce per-recording + per-month caps once we know how many audio seconds
 * we're about to transcribe. Call AFTER decoding the audio header but
 * BEFORE invoking Whisper.
 */
export function assertWithinMonthlyQuota(
  audioSeconds: number,
  ctx: QuotaContext,
): void {
  if (audioSeconds > ctx.limits.maxRecordingSeconds) {
    throw new QuotaExceededError(
      `Recording is ${Math.ceil(audioSeconds)}s; ${ctx.plan} plan allows max ${ctx.limits.maxRecordingSeconds}s per recording.`,
      'recording_too_long',
      ctx.plan,
      ctx.limits,
      ctx.used,
    );
  }
  if (ctx.used.count >= ctx.limits.maxMonthlyRecordings) {
    throw new QuotaExceededError(
      `Monthly recording cap reached: ${ctx.used.count}/${ctx.limits.maxMonthlyRecordings} for ${ctx.plan} plan.`,
      'monthly_recordings',
      ctx.plan,
      ctx.limits,
      ctx.used,
    );
  }
  if (ctx.used.seconds + audioSeconds > ctx.limits.maxMonthlySeconds) {
    throw new QuotaExceededError(
      `Monthly minute cap would be exceeded: ${ctx.used.seconds}+${Math.ceil(audioSeconds)}s > ${ctx.limits.maxMonthlySeconds}s for ${ctx.plan} plan.`,
      'monthly_minutes',
      ctx.plan,
      ctx.limits,
      ctx.used,
    );
  }
}

/**
 * Atomically increment usage counters after a successful transcription.
 * Best-effort: errors here are logged but don't fail the request (the user
 * already paid the OpenAI cost; failing the response would mean wasted money).
 */
export async function recordUsage(
  uid: string,
  audioSeconds: number,
  ctx: QuotaContext,
): Promise<void> {
  const ref = getFirestore().doc(`users/${uid}/usage/${ctx.monthKey}`);
  try {
    await ref.set(
      {
        transcriptionSeconds: FieldValue.increment(Math.ceil(audioSeconds)),
        recordingsCount: FieldValue.increment(1),
        lastTranscriptionAt: FieldValue.serverTimestamp(),
        plan: ctx.plan,
      },
      { merge: true },
    );
  } catch (err) {
    console.error('[quota] recordUsage failed (non-fatal):', err);
  }
}

export { FREE_LIMITS, PRO_LIMITS };
