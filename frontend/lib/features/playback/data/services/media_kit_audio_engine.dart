import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/domain/services/audio_engine.dart';

/// Implementación concreta de [AudioEngine] basada en la librería media_kit.
class MediaKitAudioEngine implements AudioEngine {
  new({Player? player}) : _player = player ?? Player() {
    _initSubscriptions();
  }

  final Player _player;
  final _stateController = StreamController<PlaybackState>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  PlaybackState _currentState = const PlaybackState();

  void _initSubscriptions() {
    _subscriptions.addAll([
      _player.stream.playing.listen((isPlaying) {
        final status = isPlaying
            ? PlaybackStatus.playing
            : PlaybackStatus.paused;
        _emit(_currentState.copyWith(status: status));
      }),
      _player.stream.position.listen((position) {
        _emit(_currentState.copyWith(position: position));
      }),
      _player.stream.duration.listen((duration) {
        _emit(_currentState.copyWith(duration: duration));
      }),
      _player.stream.buffer.listen((buffered) {
        _emit(_currentState.copyWith(buffered: buffered));
      }),
      _player.stream.completed.listen((isCompleted) {
        if (isCompleted) {
          _emit(_currentState.copyWith(status: PlaybackStatus.completed));
        }
      }),
      _player.stream.error.listen((error) {
        if (error.isNotEmpty) {
          _emit(
            _currentState.copyWith(
              status: PlaybackStatus.error,
              errorMessage: error,
            ),
          );
        }
      }),
    ]);
  }

  void _emit(PlaybackState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  @override
  Future<void> load(TrackRef track) async {
    _emit(
      _currentState.copyWith(
        status: PlaybackStatus.loading,
        currentTrack: track,
        position: Duration.zero,
      ),
    );

    try {
      await _player.open(Media(track.uri), play: false);
      _emit(_currentState.copyWith(status: PlaybackStatus.idle));
    } on Object catch (e) {
      _emit(
        _currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _emit(
      _currentState.copyWith(
        status: PlaybackStatus.idle,
        position: Duration.zero,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _player.dispose();
    await _stateController.close();
  }

  @override
  Stream<PlaybackState> get state => _stateController.stream;

  @override
  PlaybackState get currentState => _currentState;
}
