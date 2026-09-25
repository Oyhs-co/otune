import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/domain/entities/playback_session.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

void main() {
  const track = TrackRef(id: '1', uri: 'file:///one.mp3', title: 'One');

  test('F-04: copyWith preserves stored error across healthy transitions', () {
    const errored = PlaybackState(
      status: PlaybackStatus.error,
      currentTrack: track,
      errorMessage: 'No such file',
    );

    // Error → sano: el mensaje almacenado se conserva internamente...
    final healthy = errored.copyWith(status: PlaybackStatus.playing);
    expect(healthy.hasError, isFalse);
    expect(healthy.errorMessage, isNull);

    // ...y al volver a error reaparece sin volver a pasarlo.
    final erroredAgain = healthy.copyWith(status: PlaybackStatus.error);
    expect(erroredAgain.hasError, isTrue);
    expect(erroredAgain.errorMessage, 'No such file');
  });

  test('F-04: copyWith clearError removes the stored message', () {
    const errored = PlaybackState(
      status: PlaybackStatus.error,
      currentTrack: track,
      errorMessage: 'No such file',
    );

    final cleared = errored.copyWith(clearError: true);
    expect(cleared.hasError, isTrue);
    expect(cleared.errorMessage, isNull);

    // Tras limpiar, volver a error ya no reusa el mensaje antiguo.
    final healthy = cleared.copyWith(status: PlaybackStatus.playing);
    final erroredAgain = healthy.copyWith(status: PlaybackStatus.error);
    expect(erroredAgain.errorMessage, isNull);
  });

  test('F-04: copyWith can replace the stored error message', () {
    const errored = PlaybackState(
      status: PlaybackStatus.error,
      errorMessage: 'old failure',
    );

    final replaced = errored.copyWith(errorMessage: 'new failure');
    expect(replaced.errorMessage, 'new failure');
  });

  test('playback state exposes status helpers and copies values', () {
    const state = PlaybackState(
      status: PlaybackStatus.error,
      currentTrack: track,
      position: Duration(seconds: 1),
      buffered: Duration(seconds: 2),
      duration: Duration(seconds: 3),
      volume: 0.5,
      errorMessage: 'Failure',
    );

    expect(state.hasError, isTrue);
    expect(state.isPlaying, isFalse);
    expect(state.copyWith(status: PlaybackStatus.playing).isPlaying, isTrue);
    expect(state.toString(), contains('One'));
  });

  test('session uses queue track before playback track and exposes flags', () {
    const playbackTrack = TrackRef(
      id: 'playback',
      uri: 'file:///playback.mp3',
      title: 'Playback',
    );
    const session = PlaybackSession(
      playback: PlaybackState(currentTrack: playbackTrack),
    );

    expect(session.currentTrack, playbackTrack);
    expect(session.queueItems, isEmpty);
    expect(session.hasNext, isFalse);
    expect(session.hasPrevious, isFalse);
    expect(session.copyWith().currentTrack, playbackTrack);
  });
}
