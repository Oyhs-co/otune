import 'package:otune/features/library/domain/entities/track.dart';

/// Interfaz para el servicio de escaneo de la biblioteca musical.
abstract interface class LibraryScanner {
  /// Escanea un directorio y sus subdirectorios en busca de archivos de audio.
  /// Emite un stream de pistas encontradas y el progreso del escaneo.
  Stream<ScanEvent> scanDirectory(String path);
}

/// Eventos emitidos durante el proceso de escaneo.
sealed class ScanEvent {}

class ScanProgress extends ScanEvent {
  final String currentFile;
  final int filesProcessed;
  final int totalFilesFound;

  ScanProgress({
    required this.currentFile,
    required this.filesProcessed,
    required this.totalFilesFound,
  });
}

class ScanTrackFound extends ScanEvent {
  final LibraryTrack track;

  ScanTrackFound(this.track);
}

class ScanComplete extends ScanEvent {
  final int totalTracksIndexed;

  ScanComplete(this.totalTracksIndexed);
}

class ScanError extends ScanEvent {
  final String message;
  final String path;

  ScanError({required this.message, required this.path});
}
