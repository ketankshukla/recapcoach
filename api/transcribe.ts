/**
 * POST /api/transcribe
 *
 * Accepts a multipart/form-data upload with a single field `audio` containing
 * an audio file (m4a / aac-lc preferred, but Whisper accepts mp3, wav, webm, etc).
 *
 * Pipeline:
 *   0. Verify Firebase ID token (auth gate).
 *   1. Load quota context: kill switch, plan, monthly usage.
 *   2. Parse multipart upload (per-plan file-size cap).
 *   3. Probe audio for real duration (server-side, can't be spoofed).
 *   4. Assert within per-recording + per-month caps.
 *   5. Whisper-1: audio  -> transcript text
 *   6. gpt-4o-mini: transcript -> { summary, actionItems[] } JSON
 *   7. Atomically increment usage counters in Firestore.
 *
 * Response (200):
 *   {
 *     "transcript":  string,
 *     "summary":     string,
 *     "actionItems": string[],
 *     "usage": { plan, monthKey, usedSeconds, usedCount,
 *                limitSeconds, limitCount, limitPerRecordingSeconds }
 *   }
 *
 * Errors:
 *   400 - no audio file / corrupt audio
 *   401 - missing/invalid Firebase ID token
 *   413 - file too large for this plan
 *   429 - quota exceeded ({ reason, plan, limits, used }) -- client should
 *         prompt the user to upgrade and NOT retry
 *   503 - transcription temporarily disabled (global kill switch flipped)
 *   500 - OpenAI failure / server misconfigured
 *
 * Auth:
 *   Caller MUST send `Authorization: Bearer <Firebase ID token>`.
 *
 * Env (set in Vercel project settings, all Encrypted):
 *   OPENAI_API_KEY         - OpenAI secret key
 *   FIREBASE_PROJECT_ID    - e.g. "recapcoach-dev"
 *   FIREBASE_CLIENT_EMAIL  - from the service account JSON
 *   FIREBASE_PRIVATE_KEY   - from the service account JSON (\n preserved)
 */
import type { VercelRequest, VercelResponse } from "@vercel/node";
import OpenAI from "openai";
import formidable from "formidable";
import fs from "fs";
import { requireFirebaseUser } from "./_lib/firebase-admin";
import {
  loadQuotaContext,
  assertFileSizeAllowed,
  assertWithinMonthlyQuota,
  recordUsage,
  QuotaExceededError,
  TranscriptionDisabledError,
  type QuotaContext,
} from "./_lib/quota";
import { probeAudioFile } from "./_lib/audio-meta";

// Disable Vercel's default JSON body parser; we handle multipart ourselves.
export const config = {
  api: {
    bodyParser: false,
  },
};

const SYSTEM_PROMPT = `You are an assistant that summarizes phone-call transcripts for consultants and coaches.

Given a transcript, you MUST respond with a single JSON object with exactly two keys:
- "summary": a 2-3 sentence summary of what the call was about and what was decided.
- "actionItems": an array of clear, concrete action items (strings) the consultant should follow up on. If there are no action items, return an empty array.

Do not include any other keys. Do not wrap the JSON in markdown. Output valid JSON only.

Example:
{
  "summary": "Discovery call with Acme Corp about migrating their billing system off Stripe. Client confirmed budget and target go-live of Q3.",
  "actionItems": [
    "Send written proposal by Friday EOD",
    "Schedule technical deep-dive with their CTO next Tuesday",
    "Share the case study from the FinTech migration"
  ]
}`;

interface SummaryResponse {
  summary: string;
  actionItems: string[];
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
): Promise<void> {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  // ---- 0. Verify the Firebase ID token ----
  const user = await requireFirebaseUser(req, res);
  if (!user) return;

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    res
      .status(500)
      .json({ error: "Server misconfigured: OPENAI_API_KEY is not set" });
    return;
  }

  // ---- 1. Load quota context (also checks kill switch) ----
  let ctx;
  try {
    ctx = await loadQuotaContext(user.uid);
  } catch (err) {
    if (err instanceof TranscriptionDisabledError) {
      res.status(503).json({ error: err.message });
      return;
    }
    const message = err instanceof Error ? err.message : String(err);
    res.status(500).json({ error: `Could not load quota: ${message}` });
    return;
  }
  console.log(
    `[transcribe] uid=${user.uid} plan=${ctx.plan} used=${ctx.used.seconds}s/${ctx.used.count}rec ` +
      `caps=${ctx.limits.maxMonthlySeconds}s/${ctx.limits.maxMonthlyRecordings}rec`
  );

  // Quick early bail-out: if the user has already hit the per-month recording
  // count, we don't need to bother parsing the upload.
  if (ctx.used.count >= ctx.limits.maxMonthlyRecordings) {
    return respondQuotaExceeded(
      res,
      new QuotaExceededError(
        `Monthly recording cap reached: ${ctx.used.count}/${ctx.limits.maxMonthlyRecordings} for ${ctx.plan} plan.`,
        "monthly_recordings",
        ctx.plan,
        ctx.limits,
        ctx.used
      )
    );
  }

  // ---- 2. Parse multipart upload (per-plan max bytes) ----
  let audioPath: string;
  let audioMime: string;
  let audioFilename: string;
  let audioBytes: number;
  try {
    const form = formidable({
      maxFileSize: ctx.limits.maxFileBytes,
      keepExtensions: true,
    });
    const [, files] = await form.parse(req);
    const audio = Array.isArray(files.audio) ? files.audio[0] : files.audio;
    if (!audio) {
      res.status(400).json({ error: 'Missing "audio" file field' });
      return;
    }
    audioPath = audio.filepath;
    audioMime = audio.mimetype ?? "audio/m4a";
    audioFilename = audio.originalFilename ?? "recording.m4a";
    audioBytes = audio.size ?? 0;
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    // formidable throws when maxFileSize is exceeded -- treat as 413.
    if (/maxFileSize/i.test(message)) {
      res.status(413).json({
        error: `Upload exceeds ${ctx.limits.maxFileBytes} byte limit for ${ctx.plan} plan.`,
        reason: "file_too_large",
        plan: ctx.plan,
        limits: ctx.limits,
        used: ctx.used,
      });
      return;
    }
    res.status(400).json({ error: `Could not parse upload: ${message}` });
    return;
  }

  // ---- 2b. Secondary size check (redundant safety net) ----
  try {
    assertFileSizeAllowed(audioBytes, ctx);
  } catch (err) {
    if (err instanceof QuotaExceededError) {
      await fs.promises.unlink(audioPath).catch(() => undefined);
      return respondQuotaExceeded(res, err);
    }
    throw err;
  }

  // ---- 3. Probe audio for real duration ----
  let audioSeconds: number;
  try {
    const meta = await probeAudioFile(audioPath, audioMime);
    audioSeconds = meta.seconds;
    console.log(
      `[transcribe] probed audio: ${audioSeconds}s, ${meta.codec ?? "?"}/${
        meta.container ?? "?"
      }, ${audioBytes} bytes`
    );
  } catch (err: unknown) {
    await fs.promises.unlink(audioPath).catch(() => undefined);
    const message = err instanceof Error ? err.message : String(err);
    res.status(400).json({ error: `Could not decode audio: ${message}` });
    return;
  }

  // ---- 4. Quota check on the actual duration ----
  try {
    assertWithinMonthlyQuota(audioSeconds, ctx);
  } catch (err) {
    if (err instanceof QuotaExceededError) {
      await fs.promises.unlink(audioPath).catch(() => undefined);
      return respondQuotaExceeded(res, err);
    }
    throw err;
  }

  const openai = new OpenAI({ apiKey });

  // ---- 5. Whisper transcription ----
  let transcript: string;
  try {
    const transcription = await openai.audio.transcriptions.create({
      file: fs.createReadStream(audioPath),
      model: "whisper-1",
      response_format: "json",
    });
    transcript = transcription.text.trim();
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    res.status(500).json({ error: `Transcription failed: ${message}` });
    return;
  } finally {
    fs.promises.unlink(audioPath).catch(() => undefined);
  }

  // We just spent money on OpenAI -- count it whether or not summarization works.
  await recordUsage(user.uid, audioSeconds, ctx);
  const usagePayload = buildUsagePayload(ctx, audioSeconds);

  if (transcript.length === 0) {
    res.status(200).json({
      transcript: "",
      summary: "(No speech detected.)",
      actionItems: [],
      usage: usagePayload,
    });
    return;
  }

  // ---- 6. gpt-4o-mini summarize + extract action items ----
  let parsed: SummaryResponse;
  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.2,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        {
          role: "user",
          content: `Transcript of the call (JSON output required):\n\n${transcript}`,
        },
      ],
    });

    const raw = completion.choices[0]?.message?.content ?? "{}";
    const obj = JSON.parse(raw) as Partial<SummaryResponse>;
    parsed = {
      summary: typeof obj.summary === "string" ? obj.summary.trim() : "",
      actionItems: Array.isArray(obj.actionItems)
        ? obj.actionItems.filter((s): s is string => typeof s === "string")
        : [],
    };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    res.status(200).json({
      transcript,
      summary: "",
      actionItems: [],
      warning: `Summarization failed but transcript is available: ${message}`,
      audioFilename, // unused, kept to silence lint
      usage: usagePayload,
    });
    return;
  }

  res.status(200).json({
    transcript,
    summary: parsed.summary,
    actionItems: parsed.actionItems,
    usage: usagePayload,
  });
}

function respondQuotaExceeded(
  res: VercelResponse,
  err: QuotaExceededError
): void {
  res.status(429).json({
    error: err.message,
    reason: err.reason,
    plan: err.plan,
    limits: err.limits,
    used: err.used,
  });
}

function buildUsagePayload(ctx: QuotaContext, justUsedSeconds: number) {
  return {
    plan: ctx.plan,
    monthKey: ctx.monthKey,
    usedSeconds: ctx.used.seconds + Math.ceil(justUsedSeconds),
    usedCount: ctx.used.count + 1,
    limitSeconds: ctx.limits.maxMonthlySeconds,
    limitCount: ctx.limits.maxMonthlyRecordings,
    limitPerRecordingSeconds: ctx.limits.maxRecordingSeconds,
  };
}
