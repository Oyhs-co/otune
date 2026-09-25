import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/lyrics/application/lyrics_sync_notifier.dart';
import 'package:otune/features/playback/application/file_picker_service.dart';
import 'package:otune/features/playback/application/playback_persistence.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_failure.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';
import 'package:otune/features/playback/domain/entities/playback_session.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/queue.dart';
import 'package:otune/features/playback/domain/entities/queue_item.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/domain/services/audio_engine.dart';

/// Controlador principal de la sesión de reproducción y cola musical.
class PlaybackController extends Notifier<PlaybackSession> {
  late final AudioEngine _engine;
  bool _isMuted = false;

  /// Límite de fallos de carga consecutivos antes de detener la cola
  /// (política de la SPEC playback_error_policy).
  static const int maxConsecutiveFailures = 3;

  int _consecutiveFailures = 0;

  @override
  PlaybackSession build() {
    _engine = ref.watch(audioEngineProvider);
    _consecutiveFailures = 0;

    final subscription = _engine.state.listen((playbackState) {
      final wasCompleted = playbackState.isCompleted;
      state = state.copyWith(playback: playbackState);

      // Una reproducción sana reinicia el contador de fallos consecutivos
      // y limpia el último fallo registrado para la superficie de error.
      if (playbackState.isPlaying) {
        _consecutiveFailures = 0;
        ref.read(playbackFailureProvider.notifier).clear();
      }

      // Sincronizar la posición actual con el sistema de letras
      ref
          .read(lyricsSyncProvider.notifier)
          .updatePosition(playbackState.position);

      // La posición/status del motor también alimenta el snapshot persistido
      if (playbackState.isPlaying || playbackState.isPaused || wasCompleted) {
        _scheduleSessionSave();
      }

      if (wasCompleted) {
        unawaited(_handleTrackCompleted());
      }
    });

    ref.onDispose(subscription.cancel);

    return PlaybackSession(playback: _engine.currentState);
  }

  /// Programa la persistencia diferida de la sesión actual (cola, modos,
  /// pista y posición). Lo invocan las mutaciones de cola y el listener del
  /// motor; el guardado real lo coordina `PlaybackPersistenceNotifier`.
  void _scheduleSessionSave() {
    ref.read(playbackPersistenceProvider.notifier).scheduleSave();
  }

  Future<void> _handleTrackCompleted() async {
    // Repeat one reintenta la misma pista sin mover el índice (S3-2):
    // mover con getNextIndex() devolvería el mismo índice y recargaría,
    // produciendo un hueco audible y un reset de posición innecesario.
    if (state.queue.repeatMode == RepeatMode.one) {
      await _engine.seek(Duration.zero);
      await _engine.play();
      return;
    }

    final nextIdx = state.queue.getNextIndex();
    if (nextIdx != null) {
      state = state.copyWith(queue: state.queue.moveTo(nextIdx));
      await _loadAndPlayCurrent();
    } else {
      await _engine.stop();
    }
  }

  Future<void> _loadAndPlayCurrent() async {
    final track = state.currentTrack;
    if (track == null) return;

    try {
      await _engine.load(track);
    } on PlaybackLoadException catch (e) {
      // Fallo determinista de carga: la política de errores decide el
      // salto automático o la detención (S3-3, SPEC playback_error_policy).
      await _handleLoadFailure(track, e.message);
      return;
    }

    await _engine.play();

    // Cargar las letras asociadas a la pista que comienza a sonar
    await ref.read(lyricsSyncProvider.notifier).loadLyrics(track.id, track.uri);
  }

  /// Traduce el fallo del motor a un tipo de dominio y aplica la política
  /// de salto automático (SPEC playback_error_policy).
  Future<void> _handleLoadFailure(TrackRef track, String message) async {
    final failure = PlaybackFailure.categorize(
      engineMessage: message,
      uri: track.uri,
    );

    ref
        .read(playbackFailureProvider.notifier)
        .recordFailure(failure, trackId: track.id);

    // Límite de fallos consecutivos sin reproducción sana intermedia:
    // detiene el motor y deja el fallo visible en la UI.
    if (_consecutiveFailures >= maxConsecutiveFailures) {
      await _engine.stop();
      return;
    }

    final nextIdx = state.queue.getNextIndex();
    if (nextIdx == null || nextIdx == state.currentIndex) {
      await _engine.stop();
      return;
    }

    state = state.copyWith(queue: state.queue.moveTo(nextIdx));
    await _loadAndPlayCurrent();
  }

  /// Carga y reproduce inmediatamente una pista agregándola a la cola.
  Future<void> playTrack(TrackRef track) async {
    final newQueue = state.queue.isEmpty
        ? state.queue.addTrack(track)
        : state.queue.addPlayNext(track);

    final nextIdx = state.queue.isEmpty ? 0 : state.queue.currentIndex + 1;
    state = state.copyWith(queue: newQueue.moveTo(nextIdx));
    _scheduleSessionSave();

    await _loadAndPlayCurrent();
  }

  /// Reemplaza la cola por una lista de pistas y reproduce desde [startIndex].
  Future<void> setQueue(List<TrackRef> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;

    var queue = const PlaybackQueue();
    for (final track in tracks) {
      queue = queue.addTrack(track);
    }
    queue = queue.moveTo(startIndex);
    state = state.copyWith(queue: queue);
    _scheduleSessionSave();

    await _loadAndPlayCurrent();
  }

  /// Añade una pista al final de la cola.
  void addToQueue(TrackRef track) {
    final wasEmpty = state.queue.isEmpty;
    final newQueue = state.queue.addTrack(track);
    state = state.copyWith(queue: newQueue);
    _scheduleSessionSave();

    if (wasEmpty) {
      unawaited(_loadAndPlayCurrent());
    }
  }

  /// Añade una pista para reproducirse a continuación ("Play Next").
  Future<void> playNext(TrackRef track) async {
    final wasEmpty = state.queue.isEmpty;
    final newQueue = state.queue.addPlayNext(track);
    state = state.copyWith(queue: newQueue);
    _scheduleSessionSave();

    if (wasEmpty) {
      await _loadAndPlayCurrent();
    }
  }

  /// Elimina un elemento de la cola.
  void removeFromQueue(String id) {
    final wasPlaying = state.queue.currentItem?.id == id;
    state = state.copyWith(queue: state.queue.removeItem(id));
    _scheduleSessionSave();

    if (wasPlaying) {
      if (state.queue.isNotEmpty) {
        unawaited(_loadAndPlayCurrent());
      } else {
        unawaited(_engine.stop());
      }
    }
  }

  /// Restaura un elemento eliminado por una acción reversible de la UI.
  void restoreQueueItem(QueueItem item, int index) {
    state = state.copyWith(queue: state.queue.insertItem(item, index));
    _scheduleSessionSave();
  }

  /// Restaura una instantánea de cola para deshacer un vaciado.
  Future<void> restoreQueue(PlaybackQueue queue) async {
    state = state.copyWith(queue: queue);
    _scheduleSessionSave();
    if (queue.currentItem != null) {
      await _loadAndPlayCurrent();
    }
  }

  /// Vacía todos los elementos de la cola y detiene el audio.
  Future<void> clearQueue() async {
    state = state.copyWith(queue: state.queue.clear());
    _scheduleSessionSave();
    await _engine.stop();
    // Limpiar letras al vaciar la cola
    ref.read(lyricsSyncProvider.notifier).clear();
  }

  /// Salta a un elemento específico de la cola por su índice.
  Future<void> playQueueItem(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    state = state.copyWith(queue: state.queue.moveTo(index));
    _scheduleSessionSave();
    await _loadAndPlayCurrent();
  }

  /// Salta a la siguiente pista de la cola.
  Future<void> skipNext() async {
    final nextIdx = state.queue.getNextIndex();
    if (nextIdx != null) {
      state = state.copyWith(queue: state.queue.moveTo(nextIdx));
      await _loadAndPlayCurrent();
    } else {
      await _engine.stop();
    }
  }

  /// Retrocede a la pista anterior (o al inicio si han pasado > 3 segundos).
  Future<void> skipPrevious() async {
    if (state.position > const Duration(seconds: 3)) {
      await _engine.seek(Duration.zero);
      return;
    }

    final prevIdx = state.queue.getPreviousIndex();
    if (prevIdx != null && prevIdx != state.currentIndex) {
      state = state.copyWith(queue: state.queue.moveTo(prevIdx));
      await _loadAndPlayCurrent();
    } else {
      await _engine.seek(Duration.zero);
    }
  }

  /// Alterna el modo aleatorio (Shuffle).
  void toggleShuffle() {
    state = state.copyWith(queue: state.queue.toggleShuffle());
    _scheduleSessionSave();
  }

  /// Cicla el modo de repetición (Off -> All -> One -> Off).
  void cycleRepeatMode() {
    state = state.copyWith(queue: state.queue.cycleRepeat());
    _scheduleSessionSave();
  }

  /// Alterna entre reproducción y pausa.
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _engine.pause();
    } else if (state.isPaused || state.status == PlaybackStatus.idle) {
      if (state.currentTrack != null) {
        await _engine.play();
      }
    }
  }

  /// Reintenta la carga y reproducción de la pista activa tras un fallo
  /// (acción de la superficie de error en UI, S3-3).
  Future<void> retryCurrentTrack() async {
    _consecutiveFailures = 0;
    ref.read(playbackFailureProvider.notifier).clear();
    await _loadAndPlayCurrent();
  }

  /// Último fallo de reproducción registrado por la política de errores.
  PlaybackFailure? get lastFailure => ref.read(playbackFailureProvider).failure;

  /// Desplaza la reproducción a una posición específica.
  Future<void> seek(Duration position) async {
    await _engine.seek(position);
  }

  /// Silencia el audio durante el scrubbing.
  Future<void> setMuted({required bool muted}) async {
    _isMuted = muted;
    await _engine.setVolume(_isMuted ? 0.0 : 1.0);
  }

  /// Detiene la reproducción y reinicia la posición.
  Future<void> stop() async {
    await _engine.stop();
  }

  /// Mueve un elemento de la cola de una posición a otra.
  void moveQueueItem(int from, int to) {
    state = state.copyWith(queue: state.queue.moveItem(from, to));
    _scheduleSessionSave();
  }

  /// Restaura una sesión persistida sin iniciar la reproducción.
  ///
  /// Coloca la cola, los modos y la pista activa; el motor queda en pausa en
  /// la posición guardada. Se usa durante el arranque de la aplicación
  /// (SPEC session-persistence: nunca autoplay tras restaurar).
  Future<void> restoreSnapshot(
    PlaybackQueue queue, {
    required int positionMs,
  }) async {
    if (queue.isEmpty) return;

    state = state.copyWith(queue: queue);
    final track = queue.currentTrack;
    if (track == null) return;

    await _engine.load(track);
    if (positionMs > 0) {
      await _engine.seek(Duration(milliseconds: positionMs));
    }
    // Sin play(): la sesión restaurada espera una acción explícita del usuario.
  }

  /// Abre el explorador del sistema para cargar y reproducir una pista local.
  Future<void> pickAndPlay() async {
    final picker = ref.read(localAudioPickerProvider);
    final track = await picker.pickAudioFile();
    if (track != null) {
      await playTrack(track);
    }
  }
}

/// Estado de la última política de error de reproducción aplicada.
class PlaybackFailureState {
  const PlaybackFailureState({this.failure, this.failedTrackId});

  final PlaybackFailure? failure;
  final String? failedTrackId;

  PlaybackFailureState copyWith({
    PlaybackFailure? failure,
    String? failedTrackId,
  }) {
    return PlaybackFailureState(
      failure: failure ?? this.failure,
      failedTrackId: failedTrackId ?? this.failedTrackId,
    );
  }
}

/// Notificador que registra el último fallo para la superficie de error UI.
class PlaybackFailureNotifier extends Notifier<PlaybackFailureState> {
  @override
  PlaybackFailureState build() => const PlaybackFailureState();

  void recordFailure(PlaybackFailure failure, {required String trackId}) {
    state = PlaybackFailureState(failure: failure, failedTrackId: trackId);
  }

  void clear() {
    state = const PlaybackFailureState();
  }
}

/// Proveedor del último fallo de reproducción (S3-3).
final playbackFailureProvider =
    NotifierProvider<PlaybackFailureNotifier, PlaybackFailureState>(
      PlaybackFailureNotifier.new,
    );

/// Proveedor del controlador de sesión y cola de reproducción.
final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackSession>(
      PlaybackController.new,
    );
