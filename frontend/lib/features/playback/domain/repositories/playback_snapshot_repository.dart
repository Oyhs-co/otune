import 'package:otune/features/playback/domain/entities/playback_snapshot.dart';

/// Capacidad requerida por la aplicación de reproducción: guardar y recuperar
/// la última sesión (cola, índice, modos y posición).
abstract interface class PlaybackSnapshotRepository {
  /// Guarda el snapshot (reemplaza el anterior). Idempotente.
  Future<void> save(PlaybackSnapshot snapshot);

  /// Recupera el último snapshot guardado; `null` si nunca se guardó uno.
  Future<PlaybackSnapshot?> load();
}
