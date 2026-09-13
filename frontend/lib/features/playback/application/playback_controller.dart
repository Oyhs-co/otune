import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/file_picker_service.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_session.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/queue.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/domain/services/audio_engine.dart';

/// Controlador principal de la sesión de reproducción y cola musical.
class PlaybackController extends Notifier<PlaybackSession> {
  late final AudioEngine _engine;

  @override
  PlaybackSession build() {
    _engine = ref.watch(audioEngineProvider);

    final subscription = _engine.state.listen((playbackState) {
      final wasCompleted = playbackState.isCompleted;
      state = state.copyWith(playback: playbackState);

      if (wasCompleted) {
        unawaited(_handleTrackCompleted());
      }
    });

    ref.onDispose(subscription.cancel);

    return PlaybackSession(playback: _engine.currentState);
  }

  Future<void> _handleTrackCompleted() async {
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
    if (track != null) {
      await _engine.load(track);
      await _engine.play();
    }
  }

  /// Carga y reproduce inmediatamente una pista agregándola a la cola.
  Future<void> playTrack(TrackRef track) async {
    final newQueue = state.queue.isEmpty
        ? state.queue.addTrack(track)
        : state.queue.addPlayNext(track);

    final nextIdx = state.queue.isEmpty ? 0 : state.queue.currentIndex + 1;
    state = state.copyWith(queue: newQueue.moveTo(nextIdx));

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

    await _loadAndPlayCurrent();
  }

  /// Añade una pista al final de la cola.
  void addToQueue(TrackRef track) {
    final wasEmpty = state.queue.isEmpty;
    final newQueue = state.queue.addTrack(track);
    state = state.copyWith(queue: newQueue);

    if (wasEmpty) {
      unawaited(_loadAndPlayCurrent());
    }
  }

  /// Añade una pista para reproducirse a continuación ("Play Next").
  void playNext(TrackRef track) {
    final wasEmpty = state.queue.isEmpty;
    final newQueue = state.queue.addPlayNext(track);
    state = state.copyWith(queue: newQueue);

    if (wasEmpty) {
      unawaited(_loadAndPlayCurrent());
    }
  }

  /// Elimina un elemento de la cola.
  void removeFromQueue(String id) {
    final wasPlaying = state.queue.currentItem?.id == id;
    state = state.copyWith(queue: state.queue.removeItem(id));

    if (wasPlaying) {
      if (state.queue.isNotEmpty) {
        unawaited(_loadAndPlayCurrent());
      } else {
        unawaited(_engine.stop());
      }
    }
  }

  /// Vacía todos los elementos de la cola y detiene el audio.
  Future<void> clearQueue() async {
    state = state.copyWith(queue: state.queue.clear());
    await _engine.stop();
  }

  /// Salta a un elemento específico de la cola por su índice.
  Future<void> playQueueItem(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    state = state.copyWith(queue: state.queue.moveTo(index));
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
  }

  /// Cicla el modo de repetición (Off -> All -> One -> Off).
  void cycleRepeatMode() {
    state = state.copyWith(queue: state.queue.cycleRepeat());
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

  /// Desplaza la reproducción a una posición específica.
  Future<void> seek(Duration position) async {
    await _engine.seek(position);
  }

  /// Detiene la reproducción y reinicia la posición.
  Future<void> stop() async {
    await _engine.stop();
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

/// Proveedor del controlador de sesión y cola de reproducción.
final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackSession>(
      PlaybackController.new,
    );
