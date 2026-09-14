import 'package:flutter/material.dart';
import 'package:otune/features/library/domain/entities/track.dart';

/// Lista visual de pistas de la biblioteca.
class LibraryTrackList extends StatelessWidget {
  const new({
    required this.tracks,
    required this.onTrackSelected,
    super.key,
  });

  final List<LibraryTrack> tracks;
  final ValueChanged<LibraryTrack> onTrackSelected;

  @override
  Widget build(BuildContext context) {
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
}
