part of 'app_database.dart';

/// Operaciones de mantenimiento de pistas de [AppDatabase] (revisión
/// 2026-09-25, F-05): resolución puntual de artwork y ciclo de vida de
/// huérfanos (detección, borrado y restauración transaccional).
///
/// Viven en una extensión para que `AppDatabase` conserve la propiedad de la
/// conexión y del esquema, y este archivo concentre el acceso a datos de
/// limpieza, separado de la ordenación y consultas de lista.
extension TracksMaintenance on AppDatabase {
  /// Resolución puntual del artwork de una pista (FR-AW-002).
  Future<Uint8List?> getTrackArtwork(String id) async {
    final row = await (select(
      tracks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.albumArt;
  }

  /// Identificadores de pistas cuyo archivo ya no existe (FR-SCANR-005).
  ///
  /// Sin [candidateIds] revisa toda la biblioteca; con ellos, acota la
  /// comprobación al subconjunto dado (usado por la restauración de sesión).
  Future<List<String>> findMissingTracks({List<String>? candidateIds}) async {
    if (candidateIds != null && candidateIds.isEmpty) {
      return const [];
    }
    final candidateList = candidateIds;
    final query = candidateList == null
        ? select(tracks)
        : (select(tracks)..where((t) => t.id.isIn(candidateList)));
    final rows = await query.get();
    return [
      for (final row in rows)
        if (!File(row.path).existsSync()) row.id,
    ];
  }

  /// Eliminación de varias pistas en una única transacción (DR-004 de
  /// scan-robustness).
  Future<void> deleteTracks(List<String> ids) {
    if (ids.isEmpty) return Future.value();
    return transaction(() async {
      for (final id in ids) {
        await (delete(tracks)..where((t) => t.id.equals(id))).go();
      }
    });
  }

  /// Restauración de varias pistas en una única transacción (acción
  /// de deshacer de la limpieza de huérfanos).
  Future<void> restoreTracks(List<LibraryTrack> tracksToRestore) {
    if (tracksToRestore.isEmpty) return Future.value();
    return transaction(() async {
      for (final track in tracksToRestore) {
        await into(tracks).insert(
          TracksCompanion.insert(
            id: track.id,
            title: track.title,
            path: track.path,
            addedAt: Value(track.addedAt ?? DateTime.now()),
            artist: Value(track.artist),
            album: Value(track.album),
            albumArtist: Value(track.albumArtist),
            trackNumber: Value(track.trackNumber),
            durationMs: Value(track.duration?.inMilliseconds),
            fileFormat: Value(track.fileFormat),
            albumArt: Value(track.albumArt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}
