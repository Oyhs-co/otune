import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/data/services/media_kit_audio_engine.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/services/audio_engine.dart';

/// Proveedor del motor de reproducción [AudioEngine].
final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = MediaKitAudioEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Proveedor reactivo del stream de estado de reproducción.
final playbackStateStreamProvider = StreamProvider<PlaybackState>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return engine.state;
});
