import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/playback_controller.dart';

/// Widget visual para visualización y control de la reproducción en curso.
class PlayerWidget extends ConsumerWidget {
  const new({super.key});

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playbackState = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);

    final track = playbackState.currentTrack;
    final title = track?.title ?? 'Sin pista seleccionada';
    final artist = track?.artist ?? 'Carga un archivo de audio para comenzar';

    final position = playbackState.position;
    final duration = playbackState.duration;

    final maxDurationMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final currentPosMs = position.inMilliseconds
        .clamp(0, maxDurationMs.toInt())
        .toDouble();

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
            child: Icon(
              Icons.music_note_rounded,
              size: 64,
              color: theme.colorScheme.primary,
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
            value: currentPosMs,
            max: maxDurationMs,
            onChanged: (newMs) {
              unawaited(controller.seek(Duration(milliseconds: newMs.toInt())));
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

          // Controles principales
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 32,
                tooltip: 'Pista anterior',
                onPressed: () {
                  unawaited(controller.seek(Duration.zero));
                },
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                icon: Icon(
                  playbackState.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                iconSize: 42,
                tooltip: playbackState.isPlaying ? 'Pausar' : 'Reproducir',
                onPressed: () {
                  unawaited(controller.togglePlayPause());
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.stop_rounded),
                iconSize: 32,
                tooltip: 'Detener',
                onPressed: () {
                  unawaited(controller.stop());
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón para seleccionar pista local
          FilledButton.tonalIcon(
            icon: const Icon(Icons.audio_file_rounded),
            label: const Text('Abrir archivo de audio'),
            onPressed: () {
              unawaited(controller.pickAndPlay());
            },
          ),
        ],
      ),
    );
  }
}
