import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';

class PlaybackControls extends ConsumerWidget {
  const PlaybackControls({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final theme = Theme.of(context);

    // Sin pista activa no hay operación de reproducción que tenga sentido:
    // los controles se deshabilitan para no provocar estados contradictorios
    // (ROADMAP Fase 2 · Sprint 3 S3-2).
    final hasActiveTrack = session.currentTrack != null;
    final canSkipPrevious = hasActiveTrack && session.hasPrevious;
    final canSkipNext = hasActiveTrack && session.hasNext;
    final disabledColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.2,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: !session.isShuffle
                ? (hasActiveTrack
                      ? theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        )
                      : disabledColor)
                : theme.colorScheme.primary,
          ),
          tooltip: session.isShuffle ? 'Aleatorio activado' : 'Modo aleatorio',
          onPressed: hasActiveTrack ? controller.toggleShuffle : null,
        ),
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, size: isCompact ? 24 : 36),
          tooltip: 'Pista anterior',
          onPressed: canSkipPrevious ? controller.skipPrevious : null,
        ),
        IconButton.filled(
          icon: Icon(
            session.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: isCompact ? 32 : 42,
          ),
          tooltip: session.isPlaying ? 'Pausar' : 'Reproducir',
          onPressed: hasActiveTrack ? controller.togglePlayPause : null,
        ),
        IconButton(
          icon: Icon(Icons.skip_next_rounded, size: isCompact ? 24 : 36),
          tooltip: 'Siguiente pista',
          onPressed: canSkipNext ? controller.skipNext : null,
        ),
        IconButton(
          icon: Icon(
            session.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: session.repeatMode != RepeatMode.off
                ? theme.colorScheme.primary
                : (hasActiveTrack
                      ? theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        )
                      : disabledColor),
          ),
          tooltip: 'Repetir: ${session.repeatMode.name}',
          onPressed: hasActiveTrack ? controller.cycleRepeatMode : null,
        ),
      ],
    );
  }
}
