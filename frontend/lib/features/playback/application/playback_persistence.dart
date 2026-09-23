import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/logging/app_logger.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/data/repositories/drift_playback_snapshot_repository.dart';
import 'package:otune/features/playback/domain/entities/playback_snapshot.dart';
import 'package:otune/features/playback/domain/repositories/playback_snapshot_repository.dart';

/// Proveedor del repositorio de snapshots de reproducción (adapter Drift).
final playbackSnapshotRepositoryProvider = Provider<PlaybackSnapshotRepository>(
  (ref) {
    final db = ref.watch(databaseProvider);
    return DriftPlaybackSnapshotRepository(db);
  },
);

/// Proveedor del delay de debounce para el guardado del snapshot.
///
/// En pruebas de widgets los timers reales dejan estados pendientes al
/// desechar el árbol; los tests lo sobrescriben con `null` para guardar de
/// inmediato (o descartar) sin temporizadores.
final playbackSaveDebounceProvider = Provider<Duration?>(
  (ref) => const Duration(seconds: 2),
);

/// Proveedor de la persistencia de sesión de reproducción.
///
/// Guarda el snapshot con debounce mientras la sesión cambia y expone la
/// restauración inicial de la sesión al arrancar la aplicación.
final playbackPersistenceProvider =
    NotifierProvider<PlaybackPersistenceNotifier, void>(
      PlaybackPersistenceNotifier.new,
    );

/// Coordinador de persistencia de la sesión activa.
class PlaybackPersistenceNotifier extends Notifier<void> {
  Timer? _debounce;
  PlaybackSnapshot? _pending;

  @override
  void build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
  }

  /// Programa el guardado del snapshot con debounce (2 s en producción).
  ///
  /// Si ya había un guardado pendiente, se reemplaza por el último estado:
  /// sólo interesa persistir la instantánea más reciente.
  void scheduleSave() {
    final session = ref.read(playbackControllerProvider);
    if (session.queue.isEmpty) return;

    _pending = buildSnapshotFromQueue(
      session.queue,
      position: session.position,
    );

    final debounce = ref.read(playbackSaveDebounceProvider);
    if (debounce == null) {
      // Entorno de prueba (o guardado síncrono): sin temporizadores.
      unawaited(_flush());
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(debounce, _flush);
  }

  /// Guarda inmediatamente el snapshot pendiente (si existe).
  Future<void> flush() async {
    _debounce?.cancel();
    _debounce = null;
    await _flush();
  }

  Future<void> _flush() async {
    final snapshot = _pending;
    if (snapshot == null) return;
    _pending = null;

    try {
      await ref.read(playbackSnapshotRepositoryProvider).save(snapshot);
    } on Object catch (e) {
      appLogger.e('No se pudo guardar la sesión de reproducción: $e');
    }
  }

  /// Restaura la última sesión persistida en el controller.
  ///
  /// Reglas (SPEC session-persistence):
  /// - nunca inicia reproducción automática;
  /// - índice fuera of range -> índice 0;
  /// - cola vacía -> sesión limpia e idle;
  /// - el arte embebido se recupera desde la biblioteca si la pista existe.
  Future<void> restoreSession() async {
    try {
      final repository = ref.read(playbackSnapshotRepositoryProvider);
      final snapshot = await repository.load();
      if (snapshot == null) return;

      // Recupera carátulas desde la biblioteca local para las pistas
      // restauradas (el snapshot no las persiste).
      final artworkById = await _loadArtworkFor(snapshot);

      final controller = ref.read(playbackControllerProvider.notifier);
      await controller.restoreSnapshot(
        snapshot.toQueue(artworkById: artworkById),
        positionMs: snapshot.positionMs,
      );
    } on Object catch (e) {
      appLogger.e('No se pudo restaurar la sesión de reproducción: $e');
    }
  }

  Future<Map<String, Uint8List?>> _loadArtworkFor(
    PlaybackSnapshot snapshot,
  ) async {
    final library = ref.read(libraryRepositoryProvider);
    final artwork = <String, Uint8List?>{};

    for (final track in snapshot.items) {
      try {
        final stored = await library.getTrackById(track.id);
        artwork[track.id] = stored?.albumArt;
      } on Object catch (e) {
        appLogger.w('No se pudo recuperar la pista ${track.id}: $e');
      }
    }
    return artwork;
  }
}
