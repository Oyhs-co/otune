import 'package:meta/meta.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

/// Elemento identificable dentro de la cola de reproducción.
@immutable
class QueueItem {
  const new({required this.id, required this.track});

  /// Identificador único del elemento en la cola.
  final String id;

  /// Referencia a la pista de audio.
  final TrackRef track;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'QueueItem(id: $id, title: ${track.title})';
}
