import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

/// Contrato abstracto del motor de reproducción musical de Otune.
///
/// La capa de dominio y aplicación interactúa exclusivamente mediante esta
/// abstracción, garantizando el total desacoplamiento de librerías concretas
/// de plataforma (ej. media_kit, just_audio).
abstract interface class AudioEngine {
  /// Carga una pista de audio y la prepara para reproducción.
  Future<void> load(TrackRef track);

  /// Inicia o reanuda la reproducción.
  Future<void> play();

  /// Pausa la reproducción actual.
  Future<void> pause();

  /// Desplaza la reproducción a una posición temporal específica.
  Future<void> seek(Duration position);

  /// Detiene por completo la reproducción y restablece la posición.
  Future<void> stop();

  /// Ajusta el volumen del motor (0.0 a 1.0).
  Future<void> setVolume(double volume);

  /// Libera los recursos nativos del motor de reproducción.
  Future<void> dispose();

  /// Flujo continuo y reactivo del estado de reproducción.
  Stream<PlaybackState> get state;

  /// Estado actual instantáneo del motor.
  PlaybackState get currentState;
}
