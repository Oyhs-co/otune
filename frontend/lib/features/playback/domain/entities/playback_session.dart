import 'package:meta/meta.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/queue.dart';
import 'package:otune/features/playback/domain/entities/queue_item.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

/// Sesión unificada de reproducción y gestión de cola.
@immutable
class PlaybackSession {
  const new({
    this.playback = const PlaybackState(),
    this.queue = const PlaybackQueue(),
  });

  /// Estado del motor de audio (posición, duración, status).
  final PlaybackState playback;

  /// Estado de la lista/cola de reproducción (items, índice, repeat, shuffle).
  final PlaybackQueue queue;

  PlaybackStatus get status => playback.status;
  bool get isPlaying => playback.isPlaying;
  bool get isPaused => playback.isPaused;
  Duration get position => playback.position;
  Duration get duration => playback.duration;
  double get volume => playback.volume;
  String? get errorMessage => playback.errorMessage;

  TrackRef? get currentTrack => queue.currentTrack ?? playback.currentTrack;
  List<QueueItem> get queueItems => queue.items;
  int get currentIndex => queue.currentIndex;
  bool get isShuffle => queue.isShuffle;
  RepeatMode get repeatMode => queue.repeatMode;
  bool get hasNext => queue.hasNext;
  bool get hasPrevious => queue.hasPrevious;

  PlaybackSession copyWith({PlaybackState? playback, PlaybackQueue? queue}) {
    return PlaybackSession(
      playback: playback ?? this.playback,
      queue: queue ?? this.queue,
    );
  }
}
