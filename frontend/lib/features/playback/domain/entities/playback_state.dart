import 'package:otune/features/playback/domain/entities/track_ref.dart';

/// Estado del ciclo de vida de reproducción de audio.
enum PlaybackStatus { idle, loading, playing, paused, completed, error }

/// Estado inmutable de la reproducción actual de audio.
class PlaybackState {
  const new({
    this.status = PlaybackStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    String? errorMessage,
  }) : _storedErrorMessage = errorMessage;

  final PlaybackStatus status;
  final TrackRef? currentTrack;
  final Duration position;
  final Duration buffered;
  final Duration duration;
  final double volume;

  /// Mensaje del último error del motor.
  ///
  /// Sólo es significativo mientras el estado es [PlaybackStatus.error]:
  /// fuera de él se reporta `null` para que un error anterior no contamine
  /// estados posteriores (por ejemplo, tras recargar con éxito la pista).
  String? get errorMessage =>
      status == PlaybackStatus.error ? _storedErrorMessage : null;
  final String? _storedErrorMessage;

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isCompleted => status == PlaybackStatus.completed;
  bool get isLoading => status == PlaybackStatus.loading;

  bool get hasError => status == PlaybackStatus.error;

  /// Crea una copia conservando los campos no indicados.
  ///
  /// El mensaje de error se propaga desde el almacenamiento interno
  /// (`_storedErrorMessage`) y no desde el getter condicionado al estado, de
  /// modo que una transición `error → sano → error` no pierde el mensaje.
  /// Como el patrón `x ?? this.x` no distingue «no tocado» de «limpiado», la
  /// bandera [clearError] permite eliminar el mensaje de forma explícita.
  PlaybackState copyWith({
    PlaybackStatus? status,
    TrackRef? currentTrack,
    Duration? position,
    Duration? buffered,
    Duration? duration,
    double? volume,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      errorMessage: clearError ? null : (errorMessage ?? _storedErrorMessage),
    );
  }

  @override
  String toString() =>
      'PlaybackState(status: $status, track: ${currentTrack?.title}, '
      'pos: $position, dur: $duration)';
}
