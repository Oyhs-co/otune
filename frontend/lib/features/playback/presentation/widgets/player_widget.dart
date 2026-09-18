import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/presentation/widgets/artwork_panel.dart';
import 'package:otune/features/playback/presentation/widgets/playback_controls.dart';
import 'package:otune/features/playback/presentation/widgets/playback_progress.dart';
import 'package:otune/features/playback/presentation/widgets/track_info.dart';

/// Widget visual para visualización y control de la reproducción en curso.
class PlayerWidget extends ConsumerWidget {
  const PlayerWidget({required this.onQueuePressed, super.key});

  final VoidCallback onQueuePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playbackControllerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ArtworkPanel(isLarge: true),
          const SizedBox(height: 24),
          const TrackInfo(),
          const SizedBox(height: 16),
          const PlaybackProgress(),
          const SizedBox(height: 12),
          const PlaybackControls(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.queue_music_rounded),
                label: Text('Cola (${session.queueItems.length})'),
                onPressed: onQueuePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
