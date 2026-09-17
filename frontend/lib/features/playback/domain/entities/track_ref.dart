import 'dart:typed_data';
import 'package:meta/meta.dart';

/// Referencia inmutable a una pista de audio reproducible en el sistema.
@immutable
class TrackRef {
  const new({
    required this.id,
    required this.uri,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.albumArt,
  });

  /// Identificador único de la pista.
  final String id;

  /// Ruta local (file:// o path absoluto) o URI reproducible.
  final String uri;

  /// Título de la pista.
  final String title;

  /// Artista principal o intérprete.
  final String? artist;

  /// Álbum al que pertenece la pista.
  final String? album;

  /// Duración total si ya se conoce.
  final Duration? duration;
  final Uint8List? albumArt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackRef && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TrackRef(id: $id, title: $title, uri: $uri)';
}
