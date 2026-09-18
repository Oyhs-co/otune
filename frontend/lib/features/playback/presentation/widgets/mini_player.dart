import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otune/core/design_system/widgets/artwork_placeholder.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

/// Mini-reproductor persistente que vive en el AppShell.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final track = session.currentTrack;

    if (track == null) return const SizedBox.shrink();

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _navigateToNowPlaying(context),
        leading: ArtworkPlaceholder(
          size: ArtworkSize.small,
            child: track.albumArt != null
                ? Image.memory(
                    track.albumArt!,
                    fit: BoxFit.cover,
                  )
                : null,
        ),
        title: Text(
          track.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          track.artist ?? 'Artista desconocido',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: () => controller.skipPrevious(),
            ),
            IconButton(
              icon: Icon(session.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              onPressed: () => controller.togglePlayPause(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: () => controller.skipNext(),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNowPlaying(BuildContext context) {
    context.pushNamed('now-playing');
  }
}
