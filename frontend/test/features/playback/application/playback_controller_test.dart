import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
