import 'package:otune/features/playback/domain/entities/playback_session.dart';
import 'package:otune/features/playback/domain/entities/playback_snapshot.dart';
import 'package:otune/features/playback/domain/repositories/playback_snapshot_repository.dart';

/// Fake en memoria del repositorio de snapshots de reproducción.
class FakeSnapshotRepository implements PlaybackSnapshotRepository {
  PlaybackSnapshot? _stored;

  /// Número de escrituras realizadas (para assertions de debounce/flush).
  int storedCount = 0;

  /// Guarda un snapshot derivado de la [PlaybackSession] actual del
  /// contenedor; útil para simular sesiones previas en pruebas.
  Future<void> storeFrom(PlaybackSession session) async {
    await save(
      buildSnapshotFromQueue(session.queue, position: session.position),
    );
  }

  @override
  Future<void> save(PlaybackSnapshot snapshot) async {
    _stored = snapshot;
    storedCount++;
  }

  @override
  Future<PlaybackSnapshot?> load() async => _stored;
}
