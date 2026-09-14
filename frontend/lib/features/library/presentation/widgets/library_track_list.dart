import 'package:flutter/material.dart';
import 'package:otune/features/library/domain/entities/library_view_mode.dart';
import 'package:otune/features/library/domain/entities/track.dart';

/// Lista visual de pistas de la biblioteca.
class LibraryTrackList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    switch (viewMode) {
      case LibraryViewMode.grid:
        return _buildGrid();
      case LibraryViewMode.detailed:
        return _buildDetailedList();
      case LibraryViewMode.list:
        return _buildCompactList();
    }
  }

  Widget _buildCompactList() {
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          title: Text(track.title),
          subtitle: Text(
            '${track.artist ?? 'Artista desconocido'}'
            ' • ${track.album ?? 'Álbum desconocido'}',
          ),
          trailing: const Icon(Icons.play_arrow_rounded),
          onTap: () => onTrackSelected(track),
        );
      },
    );
  }

  Widget _buildDetailedList() {
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          leading: track.albumArt != null
              ? Image.memory(
                  track.albumArt!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.music_note),
          title: Text(
            track.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
              const Icon(Icons.play_arrow_rounded),
            ],
          ),
          onTap: () => onTrackSelected(track),
        );
      },
    );
  }

  Widget _buildGrid() {
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
        return GestureDetector(
          onTap: () => onTrackSelected(track),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: track.albumArt != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            track.albumArt!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : const Icon(Icons.music_note, size: 48),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
