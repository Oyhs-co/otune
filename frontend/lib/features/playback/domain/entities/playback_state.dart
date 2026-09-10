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
    this.errorMessage,
  });

  final PlaybackStatus status;
  final TrackRef? currentTrack;
  final Duration position;
  final Duration buffered;
  final Duration duration;
  final double volume;
  final String? errorMessage;

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get isCompleted => status == PlaybackStatus.completed;
  bool get hasError => status == PlaybackStatus.error;

  PlaybackState copyWith({
    PlaybackStatus? status,
    TrackRef? currentTrack,
    Duration? position,
    Duration? buffered,
    Duration? duration,
    double? volume,
    String? errorMessage,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'PlaybackState(status: $status, track: ${currentTrack?.title}, '
      'pos: $position, dur: $duration)';
}
