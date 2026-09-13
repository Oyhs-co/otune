import 'package:otune/features/library/domain/entities/track.dart';

/// Interfaz para el servicio de escaneo de la biblioteca musical.
abstract interface class LibraryScanner {
  /// Escanea un directorio y sus subdirectorios en busca de archivos de audio.
  /// Emite un stream de pistas encontradas y el progreso del escaneo.
  Stream<ScanEvent> scanDirectory(String path);
}

/// Eventos emitidos durante el proceso de escaneo.
sealed class ScanEvent;

class ScanProgress extends ScanEvent {
  new({
    required this.currentFile,
    required this.filesProcessed,
    required this.totalFilesFound,
  });
  final String currentFile;
  final int filesProcessed;
  final int totalFilesFound;
}

class ScanTrackFound extends ScanEvent {
  new(this.track);
  final LibraryTrack track;
}

class ScanComplete extends ScanEvent {
  new(this.totalTracksIndexed);
  final int totalTracksIndexed;
}

class ScanError extends ScanEvent {
  new({required this.message, required this.path});
  final String message;
  final String path;
}
