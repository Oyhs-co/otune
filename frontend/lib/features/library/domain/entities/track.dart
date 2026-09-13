import 'package:meta/meta.dart';

/// Entidad de dominio que representa una pista musical
/// indexada en la biblioteca local.
@immutable
class LibraryTrack {
  const new({
    required this.id,
    required this.title,
    required this.path,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.duration,
    this.fileFormat,
  });

  final String id;
  final String title;
  final String path;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final Duration? duration;
  final String? fileFormat;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryTrack &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LibraryTrack(id: $id, title: $title, artist: $artist)';
}
