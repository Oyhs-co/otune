import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/repositories/library_repository.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_persistence.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/queue.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

import '../../../fakes/fake_audio_engine.dart';
import '../../../fakes/fake_snapshot_repository.dart';

/// Repositorio de biblioteca falso: la restauración no debe tocar la base de
/// datos real en pruebas.
class _FakeLibraryRepository implements LibraryRepository {
  @override
  Future<List<LibraryTrack>> getAllTracks() async => const [];

  @override
  Future<List<LibraryTrack>> searchTracks(String query) async => const [];

  @override
  Future<void> upsertTrack(LibraryTrack track) async {}

  @override
  Future<void> deleteTrack(String id) async {}

  @override
  Future<LibraryTrack?> getTrackById(String id) async => null;
}

void main() {
  group('Restauración y persistencia de sesión', () {
    late FakeAudioEngine fakeEngine;
    late FakeSnapshotRepository fakeSnapshots;
    late ProviderContainer container;

    const track1 = TrackRef(id: 't1', uri: 'file:///t1.mp3', title: 'Track 1');
    const track2 = TrackRef(id: 't2', uri: 'file:///t2.mp3', title: 'Track 2');

    setUp(() {
      fakeEngine = FakeAudioEngine();
      fakeSnapshots = FakeSnapshotRepository();

      container = ProviderContainer(
        overrides: [
          audioEngineProvider.overrideWithValue(fakeEngine),
          playbackSnapshotRepositoryProvider.overrideWithValue(fakeSnapshots),
          libraryRepositoryProvider.overrideWithValue(_FakeLibraryRepository()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('restoreSnapshot restaura cola y posición sin reproducir (AC-003/004/005)', () async {
      final controller = container.read(playbackControllerProvider.notifier);

      final queue = const PlaybackQueue()
          .addTrack(track1)
          .addTrack(track2)
          .moveTo(1);

      await controller.restoreSnapshot(queue, positionMs: 83000);
      await pumpEventQueue();

      final session = container.read(playbackControllerProvider);
      expect(session.queueItems, hasLength(2));
      expect(session.currentIndex, 1);
      expect(session.currentTrack, track2);
      expect(
        fakeEngine.currentState.position,
        const Duration(milliseconds: 83000),
      );
      // No autoplay tras restaurar.
      expect(session.isPlaying, isFalse);
      expect(fakeEngine.currentState.status, isNot(PlaybackStatus.playing));
    });

    test('restoreSession no hace nada si nunca hubo snapshot', () async {
      await container
          .read(playbackPersistenceProvider.notifier)
          .restoreSession();

      expect(container.read(playbackControllerProvider).queueItems, isEmpty);
    });

    test('restoreSession reconstruye la sesión desde el repositorio', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.setQueue([track1, track2]);
      await fakeSnapshots.storeFrom(container.read(playbackControllerProvider));

      // Nuevo contenedor = "reinicio de la app".
      final restarted = ProviderContainer(
        overrides: [
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          playbackSnapshotRepositoryProvider.overrideWithValue(fakeSnapshots),
          libraryRepositoryProvider.overrideWithValue(_FakeLibraryRepository()),
        ],
      );
      addTearDown(restarted.dispose);

      await restarted
          .read(playbackPersistenceProvider.notifier)
          .restoreSession();
      await pumpEventQueue();

      final session = restarted.read(playbackControllerProvider);
      expect(session.queueItems, hasLength(2));
      expect(session.currentTrack, track1);
      expect(session.isPlaying, isFalse);
    });

    test('scheduleSave guarda con debounce el estado más reciente', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.setQueue([track1, track2]);

      container.read(playbackPersistenceProvider.notifier).scheduleSave();
      // No esperar el debounce todavía: aún no debe estar guardado.
      expect(fakeSnapshots.storedCount, 0);

      // Avanzar el tiempo virtual más allá del debounce (2 s).
      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));

      expect(fakeSnapshots.storedCount, 1);
      final snapshot = await fakeSnapshots.load();
      expect(snapshot!.currentIndex, 0);
      expect(snapshot.items, hasLength(2));
    });

    test(
      'flush guarda inmediatamente el snapshot pendiente (AC-008)',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.setQueue([track1, track2]);

        container.read(playbackPersistenceProvider.notifier).scheduleSave();
        await container.read(playbackPersistenceProvider.notifier).flush();

        expect(fakeSnapshots.storedCount, 1);
      },
    );

    test('scheduleSave ignora colas vacías', () async {
      container.read(playbackPersistenceProvider.notifier).scheduleSave();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(fakeSnapshots.storedCount, 0);
    });
  });
}
