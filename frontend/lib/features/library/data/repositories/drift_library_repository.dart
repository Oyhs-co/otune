import 'package:drift/drift.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/repositories/library_repository.dart';

class DriftLibraryRepository implements LibraryRepository {
  final AppDatabase _db;

  DriftLibraryRepository(this._db);

  @override
  Future<List<LibraryTrack>> getAllTracks() async {
    return await _db.getAllTracks();
  }

  @override
  Future<List<LibraryTrack>> searchTracks(String query) async {
    return await _db.searchTracks(query);
  }

  @override
  Future<void> upsertTrack(LibraryTrack track) async {
    await _db.upsertTrack(
      TracksCompanion.insert(
        id: track.id,
        title: track.title,
        path: track.path,
        artist: Value(track.artist),
        album: Value(track.album),
        albumArtist: Value(track.albumArtist),
        trackNumber: Value(track.trackNumber),
        durationMs: Value(track.duration?.inMilliseconds),
        fileFormat: Value(track.fileFormat),
      ),
    );
  }

  @override
  Future<void> deleteTrack(String id) async {
    await _db.deleteTrack(id);
  }
}
