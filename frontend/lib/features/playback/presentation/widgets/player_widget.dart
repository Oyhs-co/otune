import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';

/// Widget visual para visualización y control de la reproducción en curso.
class PlayerWidget extends ConsumerStatefulWidget {
  const new({required this.onQueuePressed, super.key});

  final VoidCallback onQueuePressed;

  @override
  ConsumerState<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends ConsumerState<PlayerWidget> {
  double? _dragPositionMs;
  String? _dragTrackId;

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);

    final track = session.currentTrack;
    final title = track?.title ?? 'Sin pista seleccionada';
    final artist = track?.artist ??
      (track == null
        ? 'Carga un archivo de audio para comenzar'
        : 'Artista desconocido');

    final position = session.position;
    final duration = session.duration;

    final maxDurationMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final currentPosMs = position.inMilliseconds
        .clamp(0, maxDurationMs.toInt())
        .toDouble();
    final sliderPositionMs = _dragTrackId == track?.id
      ? (_dragPositionMs ?? currentPosMs)
      : currentPosMs;

    final isShuffle = session.isShuffle;
    final repeatMode = session.repeatMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            // Arte / Icono de carátula
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: track?.albumArt != null
                    ? Image.memory(
                        track!.albumArt!,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.music_note_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
              ),
            ),

          const SizedBox(height: 24),

          // Título y artista
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artist,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Barra de progreso y tiempos
          Slider(
            value: sliderPositionMs.clamp(0, maxDurationMs),
            max: maxDurationMs,
            onChanged: (newMs) {
              setState(() {
                _dragTrackId = track?.id;
                _dragPositionMs = newMs;
              });
            },
            onChangeEnd: (newMs) {
              unawaited(
                _commitSeek(controller, newMs, trackId: _dragTrackId),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Controles: Shuffle, Previous, Play, Next, Repeat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: isShuffle
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                ),
                tooltip: isShuffle ? 'Aleatorio activado' : 'Modo aleatorio',
                onPressed: controller.toggleShuffle,
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 36,
                tooltip: 'Pista anterior',
                onPressed: () {
                  unawaited(controller.skipPrevious());
                },
              ),
              IconButton.filled(
                icon: Icon(
                  session.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                iconSize: 42,
                tooltip: session.isPlaying ? 'Pausar' : 'Reproducir',
                onPressed: () {
                  unawaited(controller.togglePlayPause());
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 36,
                tooltip: 'Siguiente pista',
                onPressed: () {
                  unawaited(controller.skipNext());
                },
              ),
              IconButton(
                icon: Icon(
                  repeatMode == RepeatMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: repeatMode != RepeatMode.off
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                ),
                tooltip: 'Repetir: ${repeatMode.name}',
                onPressed: controller.cycleRepeatMode,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Acciones secundarias: Cargar archivo y Ver cola
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.queue_music_rounded),
                label: Text('Cola (${session.queueItems.length})'),
                onPressed: widget.onQueuePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _commitSeek(
    PlaybackController controller,
    double positionMs, {
    required String? trackId,
  }) async {
    await controller.seek(Duration(milliseconds: positionMs.toInt()));
    if (!mounted || _dragTrackId != trackId) return;

    setState(() {
      _dragPositionMs = null;
      _dragTrackId = null;
    });
  }
}
