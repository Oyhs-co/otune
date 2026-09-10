import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/file_picker_service.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/domain/services/audio_engine.dart';

/// Controlador principal de la sesión de reproducción musical.
class PlaybackController extends Notifier<PlaybackState> {
  late final AudioEngine _engine;

  @override
  PlaybackState build() {
    _engine = ref.watch(audioEngineProvider);

    final subscription = _engine.state.listen((playbackState) {
      state = playbackState;
    });

    ref.onDispose(subscription.cancel);

    return _engine.currentState;
  }

  /// Carga y reproduce inmediatamente una pista.
  Future<void> playTrack(TrackRef track) async {
    await _engine.load(track);
    await _engine.play();
  }

  /// Alterna entre reproducción y pausa.
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _engine.pause();
    } else if (state.isPaused || state.status == PlaybackStatus.idle) {
      await _engine.play();
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

  /// Abre el selector de archivos local y reproduce la pista seleccionada.
  Future<void> pickAndPlay() async {
    final picker = ref.read(localAudioPickerProvider);
    final track = await picker.pickAudioFile();
    if (track != null) {
      await playTrack(track);
    }
  }
}

/// Proveedor global del controlador de reproducción.
final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);
