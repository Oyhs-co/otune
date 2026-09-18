import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otune/core/design_system/widgets/artwork_placeholder.dart';
import 'package:otune/features/playback/application/playback_controller.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _navigateToNowPlaying(context),
          leading: ArtworkPlaceholder(
            size: ArtworkSize.small,
            child: track.albumArt != null
                ? Image.memory(track.albumArt!, fit: BoxFit.cover)
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
                onPressed: () => unawaited(controller.skipPrevious()),
              ),
              IconButton(
                icon: Icon(
                  session.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                onPressed: () => unawaited(controller.togglePlayPause()),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () => unawaited(controller.skipNext()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNowPlaying(BuildContext context) {
    unawaited(context.pushNamed('now-playing'));
  }
}
