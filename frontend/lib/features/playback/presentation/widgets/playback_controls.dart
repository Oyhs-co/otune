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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: session.isShuffle
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          tooltip: session.isShuffle ? 'Aleatorio activado' : 'Modo aleatorio',
          onPressed: controller.toggleShuffle,
        ),
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, size: isCompact ? 24 : 36),
          tooltip: 'Pista anterior',
          onPressed: controller.skipPrevious,
        ),
        IconButton.filled(
          icon: Icon(
            session.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: isCompact ? 32 : 42,
          ),
          tooltip: session.isPlaying ? 'Pausar' : 'Reproducir',
          onPressed: controller.togglePlayPause,
        ),
        IconButton(
          icon: Icon(Icons.skip_next_rounded, size: isCompact ? 24 : 36),
          tooltip: 'Siguiente pista',
          onPressed: controller.skipNext,
        ),
        IconButton(
          icon: Icon(
            session.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: session.repeatMode != RepeatMode.off
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          tooltip: 'Repetir: ${session.repeatMode.name}',
          onPressed: controller.cycleRepeatMode,
        ),
      ],
    );
  }
}
