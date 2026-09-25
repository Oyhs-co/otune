import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/playback/application/file_picker_service.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

import '../../../fakes/fake_audio_engine.dart';

class FakeLocalAudioPicker implements LocalAudioPicker {
  TrackRef? trackToReturn;

  @override
  Future<TrackRef?> pickAudioFile() async => trackToReturn;
}

void main() {
  group('PlaybackController with Queue, Repeat and Shuffle', () {
    late FakeAudioEngine fakeEngine;
    late FakeLocalAudioPicker fakePicker;
    late ProviderContainer container;

    const track1 = TrackRef(id: 't1', uri: 'file:///t1.mp3', title: 'Track 1');
    const track2 = TrackRef(id: 't2', uri: 'file:///t2.mp3', title: 'Track 2');
    const track3 = TrackRef(id: 't3', uri: 'file:///t3.mp3', title: 'Track 3');

    setUp(() {
      fakeEngine = FakeAudioEngine();
      fakePicker = FakeLocalAudioPicker();

      container = ProviderContainer(
        overrides: [
          audioEngineProvider.overrideWithValue(fakeEngine),
          localAudioPickerProvider.overrideWithValue(fakePicker),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has empty queue and idle engine', () {
      final session = container.read(playbackControllerProvider);
      expect(session.status, equals(PlaybackStatus.idle));
      expect(session.queueItems, isEmpty);
      expect(session.currentTrack, isNull);
    });

    test('TrackRef preserves metadata when created from a library track', () {
      const libraryTrack = LibraryTrack(
        id: 't1',
        title: 'Night Drive',
        path: '/music/night-drive.mp3',
        artist: 'Nova Echo',
        album: 'Afterglow',
        duration: Duration(minutes: 4, seconds: 12),
      );

      final track = TrackRef.fromLibraryTrack(libraryTrack);

      expect(track.id, equals('t1'));
      expect(track.title, equals('Night Drive'));
      expect(track.artist, equals('Nova Echo'));
      expect(track.album, equals('Afterglow'));
      expect(track.duration, equals(const Duration(minutes: 4, seconds: 12)));
      expect(track.uri, equals(Uri.file('/music/night-drive.mp3').toString()));
    });

    test('setQueue loads and plays the first track', () async {
      final controller = container.read(playbackControllerProvider.notifier);

      await controller.setQueue([track1, track2, track3]);

      final session = container.read(playbackControllerProvider);
      expect(session.queueItems.length, equals(3));
      expect(session.currentIndex, equals(0));
      expect(session.currentTrack, equals(track1));
      expect(session.isPlaying, isTrue);
    });

    test('skipNext advances to next track in queue', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.setQueue([track1, track2, track3]);

      await controller.skipNext();

      final session = container.read(playbackControllerProvider);
      expect(session.currentIndex, equals(1));
      expect(session.currentTrack, equals(track2));
      expect(session.isPlaying, isTrue);
    });

    test('skipPrevious restarts track if position > 3 seconds', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.setQueue([track1, track2, track3], startIndex: 1);

      fakeEngine.emitState(
        fakeEngine.currentState.copyWith(position: const Duration(seconds: 10)),
      );
      await pumpEventQueue();

      await controller.skipPrevious();

      // Debe permanecer en track2 con posición reseteada a cero
      final session = container.read(playbackControllerProvider);
      expect(session.currentIndex, equals(1));
      expect(fakeEngine.currentState.position, equals(Duration.zero));
    });

    test(
      'skipPrevious moves to previous track if position <= 3 seconds',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.setQueue([track1, track2, track3], startIndex: 1);

        fakeEngine.emitState(
          fakeEngine.currentState.copyWith(
            position: const Duration(seconds: 1),
          ),
        );

        await controller.skipPrevious();

        final session = container.read(playbackControllerProvider);
        expect(session.currentIndex, equals(0));
        expect(session.currentTrack, equals(track1));
      },
    );

    test('cycleRepeatMode transitions through off -> all -> one -> off', () {
      final controller = container.read(playbackControllerProvider.notifier);

      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.off),
      );

      controller.cycleRepeatMode();
      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.all),
      );

      controller.cycleRepeatMode();
      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.one),
      );

      controller.cycleRepeatMode();
      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.off),
      );
    });

    test('toggleShuffle activates and deactivates shuffle state', () {
      final controller = container.read(playbackControllerProvider.notifier)
        ..addToQueue(track1)
        ..addToQueue(track2)
        ..toggleShuffle();

      expect(container.read(playbackControllerProvider).isShuffle, isTrue);

      controller.toggleShuffle();
      expect(container.read(playbackControllerProvider).isShuffle, isFalse);
    });

    test(
      'track completion automatically advances to next track in queue',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.setQueue([track1, track2]);

        expect(
          container.read(playbackControllerProvider).currentTrack,
          equals(track1),
        );

        // Simulamos que el motor emite completion del track 1
        fakeEngine.emitState(
          fakeEngine.currentState.copyWith(status: PlaybackStatus.completed),
        );

        // Esperamos microtareas para que el listener procese
        await pumpEventQueue();

        final session = container.read(playbackControllerProvider);
        expect(session.currentTrack, equals(track2));
      },
    );

    test(
      'removeFromQueue removes item and stops engine if queue becomes empty',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(track1);

        final itemId = container
            .read(playbackControllerProvider)
            .queueItems
            .first
            .id;
        controller.removeFromQueue(itemId);

        final session = container.read(playbackControllerProvider);
        expect(session.queueItems, isEmpty);
        expect(fakeEngine.currentState.status, equals(PlaybackStatus.idle));
      },
    );

    test(
      'repeat one replays the same track without reloading or moving',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.setQueue([track1, track2]);
        controller
          ..cycleRepeatMode() // off -> all
          ..cycleRepeatMode(); // all -> one

        expect(
          container.read(playbackControllerProvider).repeatMode,
          equals(RepeatMode.one),
        );

        fakeEngine.emitState(
          fakeEngine.currentState.copyWith(status: PlaybackStatus.completed),
        );
        await pumpEventQueue();

        final session = container.read(playbackControllerProvider);
        expect(session.currentTrack, equals(track1));
        expect(session.currentIndex, equals(0));
        // No se recarga el archivo: play() reanuda tras seek a cero.
        expect(fakeEngine.currentState.status, equals(PlaybackStatus.playing));
      },
    );

    test(
      'repeat off at end of queue stops the engine and keeps index',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.setQueue([track1, track2], startIndex: 1);

        fakeEngine.emitState(
          fakeEngine.currentState.copyWith(status: PlaybackStatus.completed),
        );
        await pumpEventQueue();

        final session = container.read(playbackControllerProvider);
        expect(session.currentIndex, equals(1));
        expect(fakeEngine.currentState.status, equals(PlaybackStatus.idle));
      },
    );

    test('repeat all restarts from the first track after completion', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.setQueue([track1, track2], startIndex: 1);
      controller.cycleRepeatMode(); // off -> all

      fakeEngine.emitState(
        fakeEngine.currentState.copyWith(status: PlaybackStatus.completed),
      );
      await pumpEventQueue();

      final session = container.read(playbackControllerProvider);
      expect(session.currentIndex, equals(0));
      expect(session.currentTrack, equals(track1));
      expect(session.isPlaying, isTrue);
    });

    group('playback error policy (S3-3)', () {
      test(
        'failed load skips to next track without blocking the queue',
        () async {
          fakeEngine.loadFailures[track1.id] =
              'Unable to open file: no such file or directory';
          final controller = container.read(
            playbackControllerProvider.notifier,
          );

          await controller.setQueue([track1, track2, track3]);
          await pumpEventQueue();

          final session = container.read(playbackControllerProvider);
          expect(session.currentIndex, equals(1));
          expect(session.currentTrack, equals(track2));
          expect(session.isPlaying, isTrue);
          // La pista fallida permanece en la cola.
          expect(session.queueItems.length, equals(3));
        },
      );

      test('three consecutive failures stop the engine', () async {
        fakeEngine.loadFailures
          ..[track1.id] = 'file not found'
          ..[track2.id] = 'file not found'
          ..[track3.id] = 'file not found';
        final controller = container.read(playbackControllerProvider.notifier);

        // t1 carga bien; al completar, la transición automática falla en
        // t2 (fallo 1), salta a t3 (fallo 2). Sin más pistas: stop.
        await controller.setQueue([track1, track2, track3]);
        fakeEngine.emitState(
          fakeEngine.currentState.copyWith(status: PlaybackStatus.completed),
        );
        await pumpEventQueue();

        expect(fakeEngine.currentState.status, equals(PlaybackStatus.idle));
        expect(
          container.read(playbackControllerProvider).currentTrack,
          equals(track3),
          reason: 'el índice queda en la última pista fallida',
        );
      });

      test(
        'retryCurrentTrack reloads the active track and clears failures',
        () async {
          fakeEngine.loadFailures[track1.id] = 'no such file or directory';
          final controller = container.read(
            playbackControllerProvider.notifier,
          );

          await controller.playTrack(track1);
          await pumpEventQueue();
          // La política detuvo el motor (idle) tras el fallo sin pistas
          // siguientes; el fallo queda registrado para la UI.
          expect(fakeEngine.currentState.status, equals(PlaybackStatus.idle));
          expect(
            container.read(playbackControllerProvider).status,
            isNot(PlaybackStatus.error),
          );

          // El archivo "vuelve a estar disponible".
          fakeEngine.loadFailures.remove(track1.id);
          await controller.retryCurrentTrack();
          await pumpEventQueue();

          // Tras el reintento, el fallo previo se limpia al reproducir.
          expect(
            fakeEngine.currentState.status,
            equals(PlaybackStatus.playing),
          );
          expect(
            fakeEngine.loadCallCounts[track1.id],
            equals(2),
            reason: 'la pista se recargó exactamente una vez más',
          );
        },
      );

      test(
        'failed load of the only track stops the engine with error',
        () async {
          fakeEngine.loadFailures[track1.id] = 'Permission denied';
          final controller = container.read(
            playbackControllerProvider.notifier,
          );

          await controller.playTrack(track1);
          await pumpEventQueue();

          expect(fakeEngine.currentState.status, equals(PlaybackStatus.idle));
          expect(
            container.read(playbackControllerProvider).queueItems.length,
            equals(1),
          );
        },
      );
      test(
        'isolated failure does not disturb subsequent valid tracks',
        () async {
          fakeEngine.loadFailures[track2.id] = 'invalid data';
          final controller = container.read(
            playbackControllerProvider.notifier,
          );

          // t1 carga y suena; al completar, la transición automática intenta
          // t2 (falla), salta a t3 y reproduce con normalidad.
          await controller.setQueue([track1, track2, track3]);
          fakeEngine.emitState(
            fakeEngine.currentState.copyWith(status: PlaybackStatus.completed),
          );
          await pumpEventQueue();

          final session = container.read(playbackControllerProvider);
          expect(session.currentTrack, equals(track3));
          expect(session.isPlaying, isTrue);
        },
      );
    });

    test(
      'restoreQueueItem restores an item without changing playback',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.setQueue([track1, track2]);
        final session = container.read(playbackControllerProvider);
        final removed = session.queueItems[1];

        controller
          ..removeFromQueue(removed.id)
          ..restoreQueueItem(removed, 1);

        final restored = container.read(playbackControllerProvider);
        expect(restored.queueItems[1], equals(removed));
        expect(restored.currentTrack, equals(track1));
        expect(restored.isPlaying, isTrue);
      },
    );
  });
}
