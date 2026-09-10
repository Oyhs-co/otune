import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/application/file_picker_service.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

import '../../../fakes/fake_audio_engine.dart';

class FakeLocalAudioPicker implements LocalAudioPicker {
  TrackRef? trackToReturn;

  @override
  Future<TrackRef?> pickAudioFile() async => trackToReturn;
}

void main() {
  group('PlaybackController', () {
    late FakeAudioEngine fakeEngine;
    late FakeLocalAudioPicker fakePicker;
    late ProviderContainer container;

    const testTrack = TrackRef(
      id: 'test-1',
      uri: 'file:///path/song.mp3',
      title: 'Awesome Song',
      artist: 'Great Artist',
      duration: Duration(minutes: 4),
    );

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

    test('initial state matches engine currentState', () {
      final state = container.read(playbackControllerProvider);
      expect(state.status, equals(PlaybackStatus.idle));
      expect(state.currentTrack, isNull);
    });

    test('playTrack loads and starts playback in engine', () async {
      final controller = container.read(playbackControllerProvider.notifier);

      await controller.playTrack(testTrack);

      final state = container.read(playbackControllerProvider);
      expect(state.currentTrack, equals(testTrack));
      expect(state.isPlaying, isTrue);
    });

    test('togglePlayPause pauses when playing', () async {
      final controller = container.read(playbackControllerProvider.notifier);

      await controller.playTrack(testTrack);
      expect(container.read(playbackControllerProvider).isPlaying, isTrue);

      await controller.togglePlayPause();
      expect(container.read(playbackControllerProvider).isPaused, isTrue);
    });

    test('togglePlayPause resumes when paused', () async {
      final controller = container.read(playbackControllerProvider.notifier);

      await controller.playTrack(testTrack);
      await controller.togglePlayPause();
      expect(container.read(playbackControllerProvider).isPaused, isTrue);

      await controller.togglePlayPause();
      expect(container.read(playbackControllerProvider).isPlaying, isTrue);
    });

    test('seek updates position in engine', () async {
      final controller = container.read(playbackControllerProvider.notifier);

      await controller.playTrack(testTrack);
      await controller.seek(const Duration(seconds: 90));

      expect(
        container.read(playbackControllerProvider).position,
        equals(const Duration(seconds: 90)),
      );
    });

    test('stop resets engine position and status to idle', () async {
      final controller = container.read(playbackControllerProvider.notifier);

      await controller.playTrack(testTrack);
      await controller.stop();

      final state = container.read(playbackControllerProvider);
      expect(state.status, equals(PlaybackStatus.idle));
      expect(state.position, equals(Duration.zero));
    });

    test('pickAndPlay plays track when picker returns a file', () async {
      fakePicker.trackToReturn = testTrack;
      final controller = container.read(playbackControllerProvider.notifier);

      await controller.pickAndPlay();

      final state = container.read(playbackControllerProvider);
      expect(state.currentTrack, equals(testTrack));
      expect(state.isPlaying, isTrue);
    });
  });
}
