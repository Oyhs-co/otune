import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:otune/features/library/domain/entities/library_sort_option.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/repositories/library_repository.dart'
    show LibrarySort;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';
part 'tracks_maintenance.dart';

class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get path => text().withLength(min: 1)();

  /// Fecha de incorporación a la biblioteca (migración v4). Se fija en el
  /// primer insert y no se actualiza en re-escaneos.
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get fileFormat => text().nullable()();
  BlobColumn get albumArt => blob().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Instantánea persistente de la sesión de reproducción (cola, índice, modos
/// y posición). Siempre existe exactamente una fila (id fijo).
///
/// `DataClassName` evita colisionar con la entidad de dominio
/// `PlaybackSnapshot` (features/playback/domain/entities).
@DataClassName('PlaybackSnapshotRow')
class PlaybackSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get queueJson => text()();
  IntColumn get currentIndex => integer()();
  BoolColumn get isShuffle => boolean()();

  /// Almacena el índice del enum `RepeatMode` (off=0, all=1, one=2).
  IntColumn get repeatModeIndex => integer()();
  IntColumn get positionMs => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Tracks, PlaybackSnapshots])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  // Keep the named constructor explicit because it is used as a test seam.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2 -> v3: tabla de snapshots de sesión de reproducción.
      if (from < 3) {
        await m.createTable(playbackSnapshots);
      }
      // v3 -> v4: fecha de incorporación para ordenar la biblioteca
      // (SPEC library-sorting). Las filas existentes adoptan el valor por
      // defecto (ahora) sin perder datos.
      if (from < 4) {
        await m.addColumn(tracks, tracks.addedAt);
      }
    },
  );

  Future<List<LibraryTrack>> getAllTracks({LibrarySort? sort}) {
    return (select(tracks)..orderBy(_orderByClause(sort))).map((row) {
      // Las consultas de lista no seleccionan el blob de artwork
      // (FR-AW-001 de artwork-management): se resuelve por pista.
      return LibraryTrack(
        id: row.id,
        title: row.title,
        path: row.path,
        addedAt: row.addedAt,
        artist: row.artist,
        album: row.album,
        albumArtist: row.albumArtist,
        trackNumber: row.trackNumber,
        duration: row.durationMs != null
            ? Duration(milliseconds: row.durationMs!)
            : null,
        fileFormat: row.fileFormat,
      );
    }).get();
  }

  Future<int> upsertTrack(TracksCompanion companion) =>
      into(tracks).insert(companion, mode: InsertMode.insertOrReplace);

  Future<int> deleteTrack(String id) =>
      (delete(tracks)..where((t) => t.id.equals(id))).go();

  Future<LibraryTrack?> getTrackById(String id) async {
    final row = await (select(
      tracks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _rowToLibraryTrack(row);
  }

  LibraryTrack _rowToLibraryTrack(Track row) {
    return LibraryTrack(
      id: row.id,
      title: row.title,
      path: row.path,
      addedAt: row.addedAt,
      artist: row.artist,
      album: row.album,
      albumArtist: row.albumArtist,
      trackNumber: row.trackNumber,
      duration: row.durationMs != null
          ? Duration(milliseconds: row.durationMs!)
          : null,
      fileFormat: row.fileFormat,
      albumArt: row.albumArt,
    );
  }

  /// Cláusula de ordenación SQL para un criterio (DR-001 de library-sorting:
  /// ordena la base de datos, no el dominio en memoria).
  ///
  /// Los criterios de texto ordenan ascendente; `addedAt` ordena de más
  /// reciente a más antigua (FR-SORT-003).
  List<OrderClauseGenerator<$TracksTable>> _orderByClause(LibrarySort? sort) {
    final option = sort?.option ?? LibrarySortOption.title;
    return switch (option) {
      LibrarySortOption.addedAt => [(t) => OrderingTerm.desc(t.addedAt)],
      // Los criterios de texto son insensibles a mayúsculas/minúsculas
      // (DR-002 de library-sorting).
      LibrarySortOption.title => [
        (t) => OrderingTerm.asc(t.title.collate(Collate.noCase)),
      ],
      LibrarySortOption.artist => [
        (t) => OrderingTerm.asc(t.artist.collate(Collate.noCase)),
      ],
      LibrarySortOption.album => [
        (t) => OrderingTerm.asc(t.album.collate(Collate.noCase)),
      ],
    };
  }

  Future<List<LibraryTrack>> searchTracks(String query, {LibrarySort? sort}) {
    final escapedQuery = _escapeLikePattern(query);
    final pattern = '%$escapedQuery%';

    return (select(tracks)
          ..where(
            (t) =>
                t.title.like(pattern, escapeChar: r'\') |
                t.artist.like(pattern, escapeChar: r'\') |
                t.album.like(pattern, escapeChar: r'\'),
          )
          ..orderBy(_orderByClause(sort)))
        .map((row) {
          return LibraryTrack(
            id: row.id,
            title: row.title,
            path: row.path,
            addedAt: row.addedAt,
            artist: row.artist,
            album: row.album,
            albumArtist: row.albumArtist,
            trackNumber: row.trackNumber,
            duration: row.durationMs != null
                ? Duration(milliseconds: row.durationMs!)
                : null,
            fileFormat: row.fileFormat,
          );
        })
        .get();
  }
}

String _escapeLikePattern(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
