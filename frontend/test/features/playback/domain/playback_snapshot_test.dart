import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/core/database/app_database.dart' as db;
import 'package:otune/features/playback/data/repositories/drift_playback_snapshot_repository.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';
import 'package:otune/features/playback/domain/entities/playback_snapshot.dart';
import 'package:otune/features/playback/domain/entities/queue.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

void main() {
  group('PlaybackSnapshotMapper (dominio)', () {
    const track1 = TrackRef(id: 't1', uri: 'file:///t1.mp3', title: 'Track 1');
    const track2 = TrackRef(id: 't2', uri: 'file:///t2.mp3', title: 'Track 2');

    test('construye snapshot desde la cola con posición', () {
      final queue = const PlaybackQueue()
          .addTrack(track1)
          .addTrack(track2)
          .moveTo(1);

      final snapshot = buildSnapshotFromQueue(
        queue,
        position: const Duration(seconds: 83),
      );

      expect(snapshot.items, hasLength(2));
      expect(snapshot.currentIndex, 1);
      expect(snapshot.positionMs, 83000);
      expect(snapshot.repeatModeIndex, 0);
      expect(snapshot.isShuffle, isFalse);
    });

    test('restaura índice válido y modos', () {
      const snapshot = PlaybackSnapshot(
        items: [
          SnapshotTrack(id: 't1', uri: 'file:///t1.mp3', title: 'Track 1'),
          SnapshotTrack(id: 't2', uri: 'file:///t2.mp3', title: 'Track 2'),
        ],
        currentIndex: 1,
        isShuffle: true,
        repeatModeIndex: 1,
        positionMs: 42000,
      );

      final queue = snapshot.toQueue();

      expect(queue.currentIndex, 1);
      expect(queue.isShuffle, isTrue);
      expect(queue.repeatMode, RepeatMode.all);
      expect(queue.currentTrack?.id, 't2');
    });

    test('índice fuera de rango restaura con índice 0 (AC-006)', () {
      const snapshot = PlaybackSnapshot(
        items: [
          SnapshotTrack(id: 't1', uri: 'file:///t1.mp3', title: 'Track 1'),
        ],
        currentIndex: 9,
        isShuffle: false,
        repeatModeIndex: 0,
        positionMs: 0,
      );

      final queue = snapshot.toQueue();

      expect(queue.currentIndex, 0);
    });

    test('snapshot vacío restaura cola vacía e inactiva (AC-007)', () {
      const snapshot = PlaybackSnapshot(
        items: [],
        currentIndex: 4,
        isShuffle: false,
        repeatModeIndex: 2,
        positionMs: 1000,
      );

      final queue = snapshot.toQueue();

      expect(queue.isEmpty, isTrue);
      expect(queue.currentIndex, -1);
    });
  });

  group('DriftPlaybackSnapshotRepository', () {
    late db.AppDatabase database;
    late DriftPlaybackSnapshotRepository repository;

    setUp(() {
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
      repository = DriftPlaybackSnapshotRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('load devuelve null cuando nunca se guardó', () async {
      expect(await repository.load(), isNull);
    });

    test('roundtrip: guarda y recupera el snapshot completo', () async {
      const snapshot = PlaybackSnapshot(
        items: [
          SnapshotTrack(
            id: 't1',
            uri: 'file:///t1.mp3',
            title: 'Canción 日本語',
            artist: 'Beyoncé',
            album: 'Afterglow',
            albumArtist: 'Nova Echo',
            durationMs: 252000,
          ),
          SnapshotTrack(id: 't2', uri: 'file:///t2.mp3', title: 'Track 2'),
        ],
        currentIndex: 1,
        isShuffle: true,
        repeatModeIndex: 2,
        positionMs: 83000,
      );

      await repository.save(snapshot);
      final loaded = await repository.load();

      expect(loaded, isNotNull);
      expect(loaded!.items, hasLength(2));
      expect(loaded.items.first.title, 'Canción 日本語');
      expect(loaded.items.first.artist, 'Beyoncé');
      expect(loaded.items.first.durationMs, 252000);
      expect(loaded.currentIndex, 1);
      expect(loaded.isShuffle, isTrue);
      expect(loaded.repeatModeIndex, 2);
      expect(loaded.positionMs, 83000);
    });

    test('save es idempotente: reemplaza el snapshot anterior', () async {
      const first = PlaybackSnapshot(
        items: [
          SnapshotTrack(id: 't1', uri: 'file:///t1.mp3', title: 'Track 1'),
        ],
        currentIndex: 0,
        isShuffle: false,
        repeatModeIndex: 0,
        positionMs: 0,
      );
      const second = PlaybackSnapshot(
        items: [
          SnapshotTrack(id: 't1', uri: 'file:///t1.mp3', title: 'Track 1'),
          SnapshotTrack(id: 't2', uri: 'file:///t2.mp3', title: 'Track 2'),
        ],
        currentIndex: 1,
        isShuffle: false,
        repeatModeIndex: 0,
        positionMs: 5000,
      );

      await repository.save(first);
      await repository.save(second);
      final loaded = await repository.load();

      expect(loaded!.items, hasLength(2));
      expect(loaded.positionMs, 5000);
    });

    test('cola JSON corrupta se descarta en lugar de fallar', () async {
      const snapshot = PlaybackSnapshot(
        items: [
          SnapshotTrack(id: 't1', uri: 'file:///t1.mp3', title: 'Track 1'),
        ],
        currentIndex: 0,
        isShuffle: false,
        repeatModeIndex: 0,
        positionMs: 0,
      );

      await repository.save(snapshot);
      // Corromper el JSON directamente en la fila.
      final corruptCompanion = db.PlaybackSnapshotsCompanion.custom(
        queueJson: const drift.Constant('not-json{'),
      );
      await database.update(database.playbackSnapshots).write(corruptCompanion);

      expect(await repository.load(), isNull);
    });
  });
}
