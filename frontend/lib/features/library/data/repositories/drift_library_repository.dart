import 'package:drift/drift.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/repositories/library_repository.dart';

/// Adaptador Drift de [LibraryRepository].
class DriftLibraryRepository implements LibraryRepository {
  DriftLibraryRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<LibraryTrack>> getAllTracks({LibrarySort? sort}) async {
    return await _db.getAllTracks(sort: sort);
  }

  @override
  Future<List<LibraryTrack>> searchTracks(
    String query, {
    LibrarySort? sort,
  }) async {
    return await _db.searchTracks(query, sort: sort);
  }

  @override
  Future<void> upsertTrack(LibraryTrack track) async {
    await _db.upsertTrack(
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
    );
  }

  @override
  Future<void> deleteTrack(String id) async {
    await _db.deleteTrack(id);
  }

  @override
  Future<LibraryTrack?> getTrackById(String id) async {
    return await _db.getTrackById(id);
  }

  @override
  Future<Uint8List?> getTrackArtwork(String id) async {
    return await _db.getTrackArtwork(id);
  }

  @override
  Future<List<String>> findMissingTracks({List<String>? candidateIds}) async {
    return await _db.findMissingTracks(candidateIds: candidateIds);
  }

  @override
  Future<void> deleteTracks(List<String> ids) async {
    await _db.deleteTracks(ids);
  }

  @override
  Future<void> restoreTracks(List<LibraryTrack> tracks) async {
    await _db.restoreTracks(tracks);
  }
}
