import 'dart:async';

import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/domain/services/audio_engine.dart';

/// Implementación en memoria (Fake) de [AudioEngine]
/// para pruebas unitarias y de widgets.
class FakeAudioEngine implements AudioEngine {
  new({PlaybackState initialState = const PlaybackState()})
    : _currentState = initialState;

  final _stateController = StreamController<PlaybackState>.broadcast();
  PlaybackState _currentState;

  /// Pistas cuya carga debe fallar (por id), con el mensaje de error
  /// que emitirá el motor (S3-3: política de errores de carga).
  final Map<String, String> loadFailures = {};

  /// Número de veces que se invocó [load], por id de pista.
  final Map<String, int> loadCallCounts = {};

  void emitState(PlaybackState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  @override
  Future<void> load(TrackRef track) async {
    loadCallCounts.update(track.id, (value) => value + 1, ifAbsent: () => 1);

    final failureMessage = loadFailures[track.id];
    if (failureMessage != null) {
      emitState(
        _currentState.copyWith(
          status: PlaybackStatus.error,
          currentTrack: track,
          position: Duration.zero,
          errorMessage: failureMessage,
        ),
      );
      // Mismo contrato que MediaKitAudioEngine: fallo determinista.
      throw PlaybackLoadException(failureMessage);
    }

    emitState(
      _currentState.copyWith(
        status: PlaybackStatus.idle,
        currentTrack: track,
        position: Duration.zero,
        duration: track.duration ?? Duration.zero,
      ),
    );
  }

  @override
  Future<void> play() async {
    emitState(_currentState.copyWith(status: PlaybackStatus.playing));
  }

  @override
  Future<void> pause() async {
    emitState(_currentState.copyWith(status: PlaybackStatus.paused));
  }

  @override
  Future<void> seek(Duration position) async {
    emitState(_currentState.copyWith(position: position));
  }

  @override
  Future<void> stop() async {
    emitState(
      _currentState.copyWith(
        status: PlaybackStatus.idle,
        position: Duration.zero,
      ),
    );
  }

  @override
  Future<void> setVolume(double volume) async {
    // No-op for fake
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
  }

  @override
  Stream<PlaybackState> get state => _stateController.stream;

  @override
  PlaybackState get currentState => _currentState;
}
