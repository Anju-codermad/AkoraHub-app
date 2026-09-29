import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Lecteur de note vocale avec forme d'onde cliquable + vitesse de
/// lecture (29/09) — remplace le simple play/pause. La forme d'onde
/// vient des échantillons d'amplitude capturés PENDANT l'enregistrement
/// (voir `chat_composer.dart`, `_amplitudeSamples`) ; impossible à
/// obtenir après coup sans redécoder tout le fichier audio côté client,
/// donc absente pour les notes vocales envoyées avant ce patch (repli
/// sur une forme d'onde plate).
class AudioWaveformPlayer extends StatefulWidget {
  final String url;
  final int? durationMs;
  final String? waveformJson;
  final Color foregroundColor;

  const AudioWaveformPlayer({
    super.key,
    required this.url,
    required this.foregroundColor,
    this.durationMs,
    this.waveformJson,
  });

  @override
  State<AudioWaveformPlayer> createState() => _AudioWaveformPlayerState();
}

class _AudioWaveformPlayerState extends State<AudioWaveformPlayer> {
  final _player = AudioPlayer();
  final _waveformKey = GlobalKey();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  late final List<double> _bars;

  @override
  void initState() {
    super.initState();
    _bars = _parseWaveform(widget.waveformJson);
    _duration = Duration(milliseconds: widget.durationMs ?? 0);
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  List<double> _parseWaveform(String? json) {
    if (json == null || json.isEmpty) {
      return List.filled(28, 20);
    }
    try {
      final decoded = jsonDecode(json) as List;
      final values = decoded.map((e) => (e as num).toDouble()).toList();
      return values.isEmpty ? List.filled(28, 20) : values;
    } catch (_) {
      return List.filled(28, 20);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      await _player.setPlaybackRate(_speed);
      await _player.play(UrlSource(widget.url));
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  Future<void> _cycleSpeed() async {
    final next = _speed == 1.0 ? 1.5 : (_speed == 1.5 ? 2.0 : 1.0);
    setState(() => _speed = next);
    await _player.setPlaybackRate(next);
  }

  Future<void> _seekToFraction(double fraction) async {
    final totalMs = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds
        : (widget.durationMs ?? 0);
    if (totalMs <= 0) return;
    final target = Duration(milliseconds: (totalMs * fraction).round());
    await _player.seek(target);
    if (mounted) setState(() => _position = target);
  }

  void _handleSeekGesture(Offset globalPosition) {
    final box =
        _waveformKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final fraction = (local.dx / box.size.width).clamp(0.0, 1.0).toDouble();
    _seekToFraction(fraction);
  }

  String _speedLabel() {
    if (_speed == _speed.roundToDouble()) return '${_speed.round()}x';
    return '${_speed}x';
  }

  String _format(Duration d) {
    final seconds = d.inSeconds;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds
        : (widget.durationMs ?? 1);
    final progress = totalMs > 0
        ? (_position.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;
    final displayedDuration =
        _isPlaying || _position.inMilliseconds > 0
            ? _position
            : Duration(milliseconds: widget.durationMs ?? 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: widget.foregroundColor,
            size: 32,
          ),
          onPressed: _toggle,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: GestureDetector(
            onTapDown: (details) => _handleSeekGesture(details.globalPosition),
            onHorizontalDragUpdate: (details) =>
                _handleSeekGesture(details.globalPosition),
            child: SizedBox(
              key: _waveformKey,
              height: 28,
              width: _bars.length * 4.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (int i = 0; i < _bars.length; i++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: _bars[i].clamp(6, 100) / 100 * 22 + 4,
                        decoration: BoxDecoration(
                          color: (i / _bars.length) <= progress
                              ? widget.foregroundColor
                              : widget.foregroundColor
                                  .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _cycleSpeed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(
                  color: widget.foregroundColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _speedLabel(),
              style: TextStyle(color: widget.foregroundColor, fontSize: 10),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _format(displayedDuration),
          style: TextStyle(color: widget.foregroundColor, fontSize: 11),
        ),
      ],
    );
  }
}
