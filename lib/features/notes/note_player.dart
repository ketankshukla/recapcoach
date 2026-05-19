import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/logging/logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../home/widgets/glass_card.dart';

/// Glass-themed audio playback widget for a recorded note.
///
/// Renders inside a `GlassCard` so it sits naturally over the mesh
/// background. Big circular amber-gradient play / pause button on the
/// left, slider + position / duration labels on the right.
///
/// The player is created when the widget mounts and disposed when it
/// unmounts, so audio never plays in the background.
class NotePlayer extends StatefulWidget {
  const NotePlayer({super.key, required this.audioFilePath});

  final String audioFilePath;

  @override
  State<NotePlayer> createState() => _NotePlayerState();
}

class _NotePlayerState extends State<NotePlayer> {
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _ready = false;
  String? _error;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = File(widget.audioFilePath);
      if (!file.existsSync()) {
        setState(() => _error = 'Audio file not found.');
        return;
      }
      final dur = await _player.setFilePath(widget.audioFilePath);
      if (!mounted) return;
      setState(() {
        _duration = dur ?? Duration.zero;
        _ready = true;
      });
      _posSub = _player.positionStream.listen((p) {
        if (!mounted) return;
        setState(() => _position = p);
      });
      _durSub = _player.durationStream.listen((d) {
        if (!mounted || d == null) return;
        setState(() => _duration = d);
      });
      _stateSub = _player.playerStateStream.listen((s) {
        if (!mounted) return;
        setState(() => _playing = s.playing);
        if (s.processingState == ProcessingState.completed) {
          // Snap back to the beginning so the next tap starts fresh.
          _player.pause();
          _player.seek(Duration.zero);
        }
      });
    } catch (e, st) {
      logger.error('NotePlayer failed to load ${widget.audioFilePath}', e, st);
      if (!mounted) return;
      setState(() => _error = 'Could not load audio: $e');
    }
  }

  Future<void> _toggle() async {
    if (!_ready) return;
    if (_playing) {
      await _player.pause();
    } else {
      // If we're at the end, restart.
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;

    if (_error != null) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error600),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error600),
              ),
            ),
          ],
        ),
      );
    }

    final total = _duration.inMilliseconds == 0 ? 1 : _duration.inMilliseconds;
    final pos = _position.inMilliseconds.clamp(0, total);
    final unlitTrack = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.slate300.withValues(alpha: 0.6);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _PlayPauseDisc(playing: _playing, onTap: _ready ? _toggle : null),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: AppColors.amber600,
                    inactiveTrackColor: unlitTrack,
                    thumbColor: AppColors.amber400,
                    overlayColor: AppColors.amber400.withValues(alpha: 0.20),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: pos.toDouble(),
                    max: total.toDouble(),
                    onChanged: _ready
                        ? (v) {
                            _player.seek(
                              Duration(milliseconds: v.toInt()),
                            );
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt(_position),
                        style: TextStyle(
                          color: fgMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _fmt(_duration),
                        style: TextStyle(
                          color: fgMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 52 dp circular amber-gradient play / pause button.
///
/// Sits on the left of the player card. White play / pause icon on
/// an amber gradient with a soft amber bloom shadow, matching the
/// hero amber controls used elsewhere in the glass theme. Disabled
/// state (no `onTap`) drops the saturation.
class _PlayPauseDisc extends StatelessWidget {
  const _PlayPauseDisc({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Opacity(
          opacity: disabled ? 0.55 : 1.0,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.amber600, AppColors.amber400],
              ),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color:
                            AppColors.amber400.withValues(alpha: 0.40),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Icon(
              playing
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
