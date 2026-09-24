import 'package:otune/features/library/domain/entities/track.dart';

/// Repositorio para la gestión de la biblioteca musical local.
abstract interface class LibraryRepository {
  /// Recupera todas las pistas indexadas en la biblioteca.
  Future<List<LibraryTrack>> getAllTracks();

  /// Busca pistas basadas en un término de consulta (título, artista o álbum).
  Future<List<LibraryTrack>> searchTracks(String query);

  /// Inserta o actualiza una pista en la biblioteca.
  Future<void> upsertTrack(LibraryTrack track);

  /// Elimina una pista de la biblioteca.
  Future<void> deleteTrack(String id);

  /// Recupera una pista por su identificador; `null` si no existe.
  Future<LibraryTrack?> getTrackById(String id);
}
