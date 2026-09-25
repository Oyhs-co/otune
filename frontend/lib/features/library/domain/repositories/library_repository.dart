import 'dart:typed_data';

import 'package:otune/features/library/domain/entities/library_sort_option.dart';
import 'package:otune/features/library/domain/entities/track.dart';

/// Criterio de ordenación de una consulta de biblioteca.
typedef LibrarySort = ({LibrarySortOption option, bool descending});

/// Repositorio para la gestión de la biblioteca musical local.
abstract interface class LibraryRepository {
  /// Recupera todas las pistas indexadas en la biblioteca.
  ///
  /// Las consultas de lista no cargan blobs de artwork (FR-AW-001): el
  /// artwork se resuelve por pista con [getTrackArtwork].
  Future<List<LibraryTrack>> getAllTracks({LibrarySort? sort});

  /// Busca pistas basadas en un término de consulta (título, artista o álbum).
  ///
  /// Como [getAllTracks], no carga blobs de artwork.
  Future<List<LibraryTrack>> searchTracks(String query, {LibrarySort? sort});

  /// Inserta o actualiza una pista en la biblioteca.
  Future<void> upsertTrack(LibraryTrack track);

  /// Elimina una pista de la biblioteca.
  Future<void> deleteTrack(String id);

  /// Recupera una pista por su identificador; `null` si no existe.
  Future<LibraryTrack?> getTrackById(String id);

  /// Devuelve los bytes del artwork de una pista; `null` si no tiene.
  ///
  /// Operación dedicada de resolución puntual (FR-AW-002); la caché de la
  /// capa de aplicación decide cuándo invocarla (DR-002 de artwork-management).
  Future<Uint8List?> getTrackArtwork(String id);

  /// Devuelve los identificadores de pistas cuyo archivo ya no existe.
  ///
  /// Puede acotarse a una lista de identificadores conocidos (por ejemplo,
  /// los de la cola restaurada); sin argumento revisa toda la biblioteca.
  Future<List<String>> findMissingTracks({List<String>? candidateIds});

  /// Elimina varias pistas en una única transacción (DR-004 de
  /// scan-robustness).
  Future<void> deleteTracks(List<String> ids);

  /// Restaura varias pistas en una única transacción (acción de deshacer de
  /// la limpieza de huérfanos).
  Future<void> restoreTracks(List<LibraryTrack> tracks);
}
