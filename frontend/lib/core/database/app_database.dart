import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get path => text().withLength(min: 1)();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get fileFormat => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Tracks])
class AppDatabase extends _$AppDatabase {
  new() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<LibraryTrack>> getAllTracks() {
    return select(tracks).map((row) {
      return LibraryTrack(
        id: row.id,
        title: row.title,
        path: row.path,
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

  Future<List<LibraryTrack>> searchTracks(String query) {
    return (select(tracks)..where(
          (t) =>
              t.title.like('%$query%') |
              t.artist.like('%$query%') |
              t.album.like('%$query%'),
        ))
        .map((row) {
          return LibraryTrack(
            id: row.id,
            title: row.title,
            path: row.path,
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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
