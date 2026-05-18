/**
 * Extract audio duration from a file on disk without invoking any native
 * binaries (Vercel serverless = no ffmpeg). Uses the pure-JS music-metadata
 * library, which supports MP4/M4A/AAC/MP3/WAV/WebM/Ogg.
 *
 * The result is what we charge against the user's monthly quota -- it MUST
 * come from parsing the actual audio bytes, never from a client-supplied
 * value, because clients can lie.
 */
import fs from 'fs';
import { parseStream } from 'music-metadata';

export interface AudioMeta {
  /** Duration in seconds, rounded up to the nearest 0.1s. */
  seconds: number;
  /** Container / codec info, mostly for logging. */
  container: string | null;
  codec: string | null;
  /** Bitrate in bps, when known. */
  bitrate: number | null;
}

/**
 * Returns the parsed duration in seconds. Throws if the file cannot be
 * decoded (corrupt upload, unsupported format, zero-length file).
 */
export async function probeAudioFile(
  filePath: string,
  mimeHint?: string,
): Promise<AudioMeta> {
  const stat = await fs.promises.stat(filePath);
  if (stat.size === 0) {
    throw new Error('Audio file is empty (0 bytes).');
  }
  const stream = fs.createReadStream(filePath);
  try {
    const meta = await parseStream(
      stream,
      mimeHint ? { mimeType: mimeHint, size: stat.size } : { size: stat.size },
      { duration: true },
    );
    const seconds = meta.format.duration ?? 0;
    if (!Number.isFinite(seconds) || seconds <= 0) {
      throw new Error(
        `Could not determine audio duration (got ${seconds}). The upload may be corrupted.`,
      );
    }
    return {
      seconds: Math.ceil(seconds * 10) / 10,
      container: meta.format.container ?? null,
      codec: meta.format.codec ?? null,
      bitrate: meta.format.bitrate ?? null,
    };
  } finally {
    // parseStream consumes the stream; make sure it's closed in error paths.
    stream.destroy();
  }
}
