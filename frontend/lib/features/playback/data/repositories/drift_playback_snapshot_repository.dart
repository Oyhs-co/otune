import 'dart:convert';

import 'package:otune/core/database/app_database.dart' as db;
import 'package:otune/features/playback/domain/entities/playback_snapshot.dart';
import 'package:otune/features/playback/domain/repositories/playback_snapshot_repository.dart';

/// Adaptador Drift de la persistencia de sesión de reproducción.
///
/// Guarda exactamente una fila (`otune.current`) con la cola serializada como
/// JSON y los modos/posición en columnas propias.
class DriftPlaybackSnapshotRepository implements PlaybackSnapshotRepository {
  DriftPlaybackSnapshotRepository(this._db);

  final db.AppDatabase _db;

  static const _snapshotId = 'otune.current';

  @override
  Future<void> save(PlaybackSnapshot snapshot) {
    return _db
        .into(_db.playbackSnapshots)
        .insertOnConflictUpdate(
          db.PlaybackSnapshotsCompanion.insert(
            id: _snapshotId,
            queueJson: jsonEncode(snapshot.toDatabaseJson()),
            currentIndex: snapshot.currentIndex,
            isShuffle: snapshot.isShuffle,
            repeatModeIndex: snapshot.repeatModeIndex,
            positionMs: snapshot.positionMs,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  @override
  Future<PlaybackSnapshot?> load() async {
    final query = _db.select(_db.playbackSnapshots)
      ..where((t) => t.id.equals(_snapshotId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    try {
      return _fromDatabaseJson(row.queueJson, row);
    } on FormatException {
      // Snapshot corrupto: se descarta y arranca una sesión limpia.
      return null;
    }
  }

  PlaybackSnapshot _fromDatabaseJson(
    String queueJson,
    db.PlaybackSnapshotRow row,
  ) {
    final decoded = jsonDecode(queueJson);
    if (decoded is! List) {
      throw const FormatException('queueJson no es una lista');
    }

    final items = <SnapshotTrack>[];
    for (final element in decoded) {
      if (element is! Map<String, dynamic>) {
        throw const FormatException('elemento de cola no es un objeto');
      }
      items.add(_trackFromJson(element));
    }

    return PlaybackSnapshot(
      items: items,
      currentIndex: row.currentIndex,
      isShuffle: row.isShuffle,
      repeatModeIndex: row.repeatModeIndex,
      positionMs: row.positionMs,
    );
  }

  SnapshotTrack _trackFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final uri = json['uri'];
    final title = json['title'];
    if (id is! String || uri is! String || title is! String) {
      throw const FormatException('pista con campos obligatorios ausentes');
    }
    final durationMs = json['durationMs'];
    return SnapshotTrack(
      id: id,
      uri: uri,
      title: title,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      albumArtist: json['albumArtist'] as String?,
      durationMs: durationMs is int ? durationMs : null,
    );
  }
}

extension on PlaybackSnapshot {
  /// Serializa la cola del snapshot a JSON para la columna `queue_json`.
  List<Map<String, Object?>> toDatabaseJson() {
    return [
      for (final track in items)
        <String, Object?>{
          'id': track.id,
          'uri': track.uri,
          'title': track.title,
          if (track.artist != null) 'artist': track.artist,
          if (track.album != null) 'album': track.album,
          if (track.albumArtist != null) 'albumArtist': track.albumArtist,
          if (track.durationMs != null) 'durationMs': track.durationMs,
        },
    ];
  }
}
