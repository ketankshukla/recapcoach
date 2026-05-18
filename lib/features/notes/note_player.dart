import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/logging/logger.dart';

/// Audio playback widget for a recorded note.
///
/// Shows a play/pause button, current position, total duration, and a seek
/// slider. The player is created when the widget mounts and disposed when it
/// unmounts, so it never plays in the background.
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
    final scheme = Theme.of(context).colorScheme;

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: scheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            ],
          ),
        ),
      );
    }

    final total = _duration.inMilliseconds == 0 ? 1 : _duration.inMilliseconds;
    final pos = _position.inMilliseconds.clamp(0, total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                size: 44,
                color: scheme.primary,
              ),
              onPressed: _ready ? _toggle : null,
              tooltip: _playing ? 'Pause' : 'Play',
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
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
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _fmt(_duration),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
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
      ),
    );
  }
}
