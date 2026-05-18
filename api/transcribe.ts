/**
 * POST /api/transcribe
 *
 * Accepts a multipart/form-data upload with a single field `audio` containing
 * an audio file (m4a / aac-lc preferred, but Whisper accepts mp3, wav, webm, etc).
 *
 * Pipeline:
 *   1. Whisper-1: audio  -> transcript text
 *   2. gpt-4o-mini: transcript -> { summary, actionItems[] } JSON
 *
 * Response (200):
 *   {
 *     "transcript":  string,
 *     "summary":     string,
 *     "actionItems": string[]
 *   }
 *
 * Errors:
 *   400 - no audio file / file too large
 *   500 - OpenAI failure
 *
 * Env:
 *   OPENAI_API_KEY - required, set in Vercel project settings (Encrypted).
 */
import type { VercelRequest, VercelResponse } from '@vercel/node';
import OpenAI from 'openai';
import formidable from 'formidable';
import fs from 'fs';

// Disable Vercel's default JSON body parser; we handle multipart ourselves.
export const config = {
  api: {
    bodyParser: false,
  },
};

const MAX_AUDIO_BYTES = 25 * 1024 * 1024; // 25 MB (OpenAI Whisper's hard limit)

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
  res: VercelResponse,
): Promise<void> {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    res
      .status(500)
      .json({ error: 'Server misconfigured: OPENAI_API_KEY is not set' });
    return;
  }

  // ---- 1. Parse multipart upload ----
  let audioPath: string;
  let audioMime: string;
  let audioFilename: string;
  try {
    const form = formidable({
      maxFileSize: MAX_AUDIO_BYTES,
      keepExtensions: true,
    });
    const [, files] = await form.parse(req);
    const audio = Array.isArray(files.audio) ? files.audio[0] : files.audio;
    if (!audio) {
      res.status(400).json({ error: 'Missing "audio" file field' });
      return;
    }
    audioPath = audio.filepath;
    audioMime = audio.mimetype ?? 'audio/m4a';
    audioFilename = audio.originalFilename ?? 'recording.m4a';
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    res.status(400).json({ error: `Could not parse upload: ${message}` });
    return;
  }

  const openai = new OpenAI({ apiKey });

  // ---- 2. Whisper transcription ----
  let transcript: string;
  try {
    const transcription = await openai.audio.transcriptions.create({
      file: fs.createReadStream(audioPath),
      model: 'whisper-1',
      response_format: 'json',
    });
    transcript = transcription.text.trim();
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    res.status(500).json({ error: `Transcription failed: ${message}` });
    return;
  } finally {
    // Best-effort cleanup of the tmp file formidable wrote.
    fs.promises.unlink(audioPath).catch(() => undefined);
  }

  if (transcript.length === 0) {
    res.status(200).json({
      transcript: '',
      summary: '(No speech detected.)',
      actionItems: [],
    });
    return;
  }

  // ---- 3. gpt-4o-mini summarize + extract action items ----
  let parsed: SummaryResponse;
  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      temperature: 0.2,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        {
          role: 'user',
          content: `Transcript of the call (JSON output required):\n\n${transcript}`,
        },
      ],
    });

    const raw = completion.choices[0]?.message?.content ?? '{}';
    const obj = JSON.parse(raw) as Partial<SummaryResponse>;
    parsed = {
      summary: typeof obj.summary === 'string' ? obj.summary.trim() : '',
      actionItems: Array.isArray(obj.actionItems)
        ? obj.actionItems.filter((s): s is string => typeof s === 'string')
        : [],
    };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    // Still return the transcript so the user doesn't lose it.
    res.status(200).json({
      transcript,
      summary: '',
      actionItems: [],
      warning: `Summarization failed but transcript is available: ${message}`,
      audioFilename, // unused, kept to silence lint
    });
    return;
  }

  res.status(200).json({
    transcript,
    summary: parsed.summary,
    actionItems: parsed.actionItems,
  });
}
