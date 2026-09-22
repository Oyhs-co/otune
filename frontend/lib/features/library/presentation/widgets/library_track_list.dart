import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/design_system/widgets/artwork_placeholder.dart';
import 'package:otune/features/library/domain/entities/library_view_mode.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/playback_session.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

/// Lista visual de pistas de la biblioteca.
class LibraryTrackList extends ConsumerWidget {
  const new({
    required this.tracks,
    required this.onTrackSelected,
    this.viewMode = LibraryViewMode.list,
    super.key,
  });

  final List<LibraryTrack> tracks;
  final ValueChanged<LibraryTrack> onTrackSelected;
  final LibraryViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playbackControllerProvider);
    switch (viewMode) {
      case LibraryViewMode.grid:
        return _buildGrid(ref, session);
      case LibraryViewMode.detailed:
        return _buildDetailedList(ref, session);
      case LibraryViewMode.list:
        return _buildCompactList(ref, session);
    }
  }

  Widget _buildCompactList(WidgetRef ref, PlaybackSession session) {
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isPlaying =
            session.currentTrack?.id == track.id && session.isPlaying;

        return ListTile(
          leading: track.albumArt != null
              ? ArtworkPlaceholder(
                  size: ArtworkSize.small,
                  child: Image.memory(
                    track.albumArt!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              : const ArtworkPlaceholder(size: ArtworkSize.small),
          title: Text(
            track.title,
            style: TextStyle(
              color: isPlaying ? Theme.of(context).colorScheme.primary : null,
              fontWeight: isPlaying ? FontWeight.bold : null,
            ),
          ),
          subtitle: Text(
            '${track.artist ?? 'Artista desconocido'}'
            ' • ${track.album ?? 'Álbum desconocido'}',
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'play_next') {
                unawaited(
                  ref
                      .read(playbackControllerProvider.notifier)
                      .playNext(TrackRef.fromLibraryTrack(track)),
                );
              } else if (value == 'add_to_queue') {
                ref
                    .read(playbackControllerProvider.notifier)
                    .addToQueue(TrackRef.fromLibraryTrack(track));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'play_next',
                child: Text('Reproducir a continuación'),
              ),
              const PopupMenuItem(
                value: 'add_to_queue',
                child: Text('Añadir a la cola'),
              ),
            ],
          ),
          onTap: () => onTrackSelected(track),
        );
      },
    );
  }

  Widget _buildDetailedList(WidgetRef ref, PlaybackSession session) {
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isPlaying =
            session.currentTrack?.id == track.id && session.isPlaying;

        return ListTile(
          leading: track.albumArt != null
              ? ArtworkPlaceholder(
                  size: ArtworkSize.small,
                  child: Image.memory(
                    track.albumArt!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : const ArtworkPlaceholder(size: ArtworkSize.small),
          title: Text(
            track.title,
            style: TextStyle(
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              color: isPlaying ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(track.artist ?? 'Artista desconocido'),
              Text(
                track.album ?? 'Álbum desconocido',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(track.duration?.toString().split('.').first ?? '0:00'),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'play_next') {
                    unawaited(
                      ref
                          .read(playbackControllerProvider.notifier)
                          .playNext(TrackRef.fromLibraryTrack(track)),
                    );
                  } else if (value == 'add_to_queue') {
                    ref
                        .read(playbackControllerProvider.notifier)
                        .addToQueue(TrackRef.fromLibraryTrack(track));
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'play_next',
                    child: Text('Reproducir a continuación'),
                  ),
                  const PopupMenuItem(
                    value: 'add_to_queue',
                    child: Text('Añadir a la cola'),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => onTrackSelected(track),
        );
      },
    );
  }

  Widget _buildGrid(WidgetRef ref, PlaybackSession session) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isPlaying =
            session.currentTrack?.id == track.id && session.isPlaying;

        return GestureDetector(
          onTap: () => onTrackSelected(track),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ArtworkPlaceholder(
                      size: ArtworkSize.medium,
                      child: track.albumArt != null
                          ? Image.memory(
                              track.albumArt!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (value) {
                          if (value == 'play_next') {
                            unawaited(
                              ref
                                  .read(playbackControllerProvider.notifier)
                                  .playNext(TrackRef.fromLibraryTrack(track)),
                            );
                          } else if (value == 'add_to_queue') {
                            ref
                                .read(playbackControllerProvider.notifier)
                                .addToQueue(TrackRef.fromLibraryTrack(track));
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'play_next',
                            child: Text('Reproducir a continuación'),
                          ),
                          const PopupMenuItem(
                            value: 'add_to_queue',
                            child: Text('Añadir a la cola'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  color: isPlaying
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                track.artist ?? 'Desconocido',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
