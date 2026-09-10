import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

import '../../../fakes/fake_audio_engine.dart';

void main() {
  group('FakeAudioEngine (AudioEngine contract)', () {
    late FakeAudioEngine engine;
    const testTrack = TrackRef(
      id: 'track-1',
      uri: 'file:///music/song.mp3',
      title: 'Test Song',
      artist: 'Test Artist',
      duration: Duration(minutes: 3),
    );

    setUp(() {
      engine = FakeAudioEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('initial state is idle with zero position', () {
      expect(engine.currentState.status, equals(PlaybackStatus.idle));
      expect(engine.currentState.position, equals(Duration.zero));
      expect(engine.currentState.currentTrack, isNull);
    });

    test('load sets track and resets position', () async {
      await engine.load(testTrack);

      expect(engine.currentState.currentTrack, equals(testTrack));
      expect(engine.currentState.duration, equals(const Duration(minutes: 3)));
      expect(engine.currentState.position, equals(Duration.zero));
    });

    test('play changes status to playing', () async {
      await engine.load(testTrack);
      await engine.play();

      expect(engine.currentState.status, equals(PlaybackStatus.playing));
      expect(engine.currentState.isPlaying, isTrue);
    });

    test('pause changes status to paused', () async {
      await engine.load(testTrack);
      await engine.play();
      await engine.pause();

      expect(engine.currentState.status, equals(PlaybackStatus.paused));
      expect(engine.currentState.isPaused, isTrue);
    });

    test('seek updates position', () async {
      await engine.load(testTrack);
      await engine.seek(const Duration(seconds: 45));

      expect(engine.currentState.position, equals(const Duration(seconds: 45)));
    });

    test('stop resets position and sets status to idle', () async {
      await engine.load(testTrack);
      await engine.play();
      await engine.seek(const Duration(seconds: 60));
      await engine.stop();

      expect(engine.currentState.status, equals(PlaybackStatus.idle));
      expect(engine.currentState.position, equals(Duration.zero));
    });

    test('state stream emits state changes', () async {
      unawaited(
        expectLater(
          engine.state.map((s) => s.status),
          emitsInOrder([
            PlaybackStatus.idle,
            PlaybackStatus.playing,
            PlaybackStatus.paused,
          ]),
        ),
      );

      await engine.load(testTrack);
      await engine.play();
      await engine.pause();
    });
  });
}
