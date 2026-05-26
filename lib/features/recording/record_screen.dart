import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/logging/logger.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass/glass_alert_dialog.dart';
import '../../core/widgets/glass/glass_icon_button.dart';
import '../../core/widgets/glass/gradient_pill_button.dart';
import '../home/widgets/glass_card.dart';
import '../home/widgets/mesh_gradient_background.dart';
import '../notes/note.dart';
import '../notes/note_providers.dart';
import '../notes/note_repository.dart';
import '../transcription/transcription_providers.dart';
import '../transcription/transcription_service.dart';
import '../usage/usage.dart';
import '../usage/usage_provider.dart';
import 'recording_providers.dart';
import 'widgets/amplitude_pulse_mic.dart';
import 'widgets/amplitude_waveform.dart';

/// Glass-themed recording screen.
///
/// Mesh-gradient backdrop matches the home + paywall so the recording
/// "moment of truth" feels like the same product. Layout (top to
/// bottom):
///
///  1. Floating glass cancel `X` in the top-left corner. No `AppBar`.
///  2. Hero amber-on-glass `AmplitudePulseMic` sized 140-200 dp,
///     halos pulsing with live dBFS.
///  3. `GlassCard` holding the elapsed-time timer (mono digits) and
///     a status sub-label ("Recording…" / "Preparing…").
///  4. `AmplitudeWaveform` -- 20 amber-gradient bars driven by the
///     same loudness signal.
///  5. Bottom action row: glass discard pill + amber `GradientPillButton`
///     "Stop & save".
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    // Auto-start when the screen opens. The user can stop or cancel.
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart());
  }

  Future<void> _autoStart() async {
    if (_starting) return;
    _starting = true;

    // ---- Pre-flight quota check (client-side, advisory) ----
    // The server is the source of truth and will reject 429 if the user is
    // over quota, but bouncing them BEFORE they record saves a wasted recording.
    //
    // Dev accounts get isAtCap=false from `UsageSnapshot` so they
    // never see this dialog (debug builds OR uid in
    // `/config/global.developerUids`). The `plan != 'pro'` check is
    // intentional: this dialog's copy is Free-tier specific
    // ("Upgrade to Pro..."), so we don't want to show it to a Pro
    // user who hit their 100/8h ceiling -- they'll get a clearer
    // server 429 with a Pro-aware message.
    final usage = ref.read(monthlyUsageProvider).value;
    if (usage != null && usage.isAtCap && usage.plan != 'pro') {
      await _showQuotaDialog(usage);
      return;
    }

    final ok = await ref.read(recordingControllerProvider.notifier).start();
    if (!mounted) return;
    if (!ok) {
      await _showPermissionDialog();
      if (mounted) context.pop();
    }
  }

  Future<void> _showPermissionDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => const GlassAlertDialog(
        title: 'Microphone access needed',
        message:
            'RecapCoach needs permission to use your microphone to record '
            'calls. Please grant access in Settings and try again.',
        primaryLabel: 'OK',
      ),
    );
  }

  Future<void> _showQuotaDialog(UsageSnapshot usage) async {
    final usedMin = (usage.usedSeconds / 60).toStringAsFixed(0);
    final limitMin = (usage.limitSeconds / 60).toStringAsFixed(0);
    final upgrade = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => GlassAlertDialog(
        title: 'Free plan limit reached',
        message: "You've used $usedMin / $limitMin minutes this month "
            '(${usage.usedRecordings} of ${usage.limitRecordings} recordings).\n\n'
            'Upgrade to Pro to keep recording — 8 hours and 100 recordings '
            'every month.',
        primaryLabel: 'Upgrade',
        secondaryLabel: 'Not now',
        primaryReturn: true,
        secondaryReturn: false,
      ),
    );
    if (!mounted) return;
    if (upgrade == true) {
      context.pushReplacement(AppRoutes.paywall);
    } else {
      context.pop();
    }
  }

  Future<void> _stopAndSave() async {
    // Capture providers BEFORE we pop, because after pop the ConsumerState
    // is unmounted and `ref` is no longer usable.
    final repo = ref.read(noteRepositoryProvider);
    final transcriber = ref.read(transcriptionServiceProvider);

    final result = await ref.read(recordingControllerProvider.notifier).stop();
    if (!mounted) return;

    if (result == null) {
      context.pop();
      return;
    }
    if (result.durationMs < 1500) {
      // Too short to be useful — discard.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording too short. Try again.')),
      );
      context.pop();
      return;
    }

    // Save the note immediately with isProcessing=true so it shows up on the
    // home screen with a spinner. Transcription runs in the background and
    // updates the same note when it finishes.
    final note = Note(
      id: const Uuid().v4(),
      audioFilePath: result.filePath,
      createdAt: DateTime.now(),
      durationMs: result.durationMs,
      isProcessing: transcriber.isConfigured,
    );
    await repo.upsert(note);
    if (!mounted) return;
    context.pop();

    // Fire-and-forget transcription. Errors are logged and persisted on the
    // note's `processingError` field so the detail screen can show them.
    unawaited(_runTranscription(repo, transcriber, note));
  }

  /// Top-level (post-pop) transcription runner. Does NOT touch `ref` or
  /// `BuildContext` — only the captured repo & service, both root-scoped.
  Future<void> _runTranscription(
    NoteRepository repo,
    TranscriptionService transcriber,
    Note initial,
  ) async {
    if (!transcriber.isConfigured) {
      logger.warning(
        'BACKEND_URL not set; skipping transcription for note ${initial.id}.',
      );
      return;
    }
    try {
      final result = await transcriber.transcribe(File(initial.audioFilePath));
      // Re-fetch in case anything else changed the note in the meantime.
      final current = repo.byId(initial.id) ?? initial;
      final updated = current.copyWith(
        transcript: result.transcript,
        summary: result.summary,
        actionItems: result.actionItems,
        isProcessing: false,
        clearError: true,
        processingError: result.warning,
      );
      await repo.upsert(updated);
      logger.info('Transcription complete for note ${initial.id}.');
    } catch (e, st) {
      logger.error('Transcription failed for note ${initial.id}', e, st);
      final current = repo.byId(initial.id) ?? initial;
      final failed = current.copyWith(
        isProcessing: false,
        processingError: e.toString(),
      );
      await repo.upsert(failed);
    }
  }

  Future<void> _cancel() async {
    await ref.read(recordingControllerProvider.notifier).cancel();
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: MeshGradientBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // Main column — declared FIRST so the floating cancel
                // button below sits on top and actually receives taps.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    72,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      AmplitudePulseMic(amplitudeDb: state.amplitudeDb),
                      const SizedBox(height: AppSpacing.xl),

                      // Glass card wrapping the elapsed timer + status copy.
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        radius: 22,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.elapsedLabel,
                              style:
                                  theme.textTheme.displayMedium?.copyWith(
                                color: fg,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _RecordingDot(active: state.isRecording),
                                const SizedBox(width: 6),
                                Text(
                                  state.isRecording
                                      ? 'Recording…'
                                      : 'Preparing…',
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(
                                    color: fgMuted,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      AmplitudeWaveform(amplitudeDb: state.amplitudeDb),
                      const SizedBox(height: AppSpacing.xl),

                      // Bottom action row.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GlassIconButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Discard',
                            tint: AppColors.error600,
                            size: 56,
                            iconSize: 26,
                            radius: 28,
                            onPressed: _cancel,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: GradientPillButton(
                              onPressed: _stopAndSave,
                              icon: Icons.stop_rounded,
                              label: 'Stop & save',
                              expanded: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ),
                ),

                // Floating cancel control — declared LAST so it sits
                // on top of the main column and receives taps.
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: GlassIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Cancel',
                    onPressed: _cancel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small red dot that turns from solid red while recording to muted
/// grey while preparing. Sits next to the "Recording…" / "Preparing…"
/// label inside the timer card.
class _RecordingDot extends StatelessWidget {
  const _RecordingDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppColors.error600
            : AppColors.slate400.withValues(alpha: 0.6),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.error600.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

