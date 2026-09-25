import 'package:otune/features/library/domain/entities/track.dart';

/// Token cooperativo de cancelación del escaneo (SPEC scan-robustness,
/// DR-001): el escáner lo consulta en cada frontera de archivo.
class ScanCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// Interfaz para el servicio de escaneo de la biblioteca musical.
abstract interface class LibraryScanner {
  /// Escanea un directorio y sus subdirectorios en busca de archivos de audio.
  /// Emite un stream de pistas encontradas y el progreso del escaneo.
  ///
  /// Si [cancellationToken] se cancela durante el recorrido, el escaneo se
  /// detiene en la siguiente frontera de archivo y el último evento emitido
  /// es [ScanCancelled] (nunca [ScanComplete]).
  Stream<ScanEvent> scanDirectory(
    String path, {
    ScanCancellationToken? cancellationToken,
  });
}

/// Eventos emitidos durante el proceso de escaneo.
sealed class ScanEvent;

class ScanProgress extends ScanEvent {
  ScanProgress({
    required this.currentFile,
    required this.filesProcessed,
    required this.totalFilesFound,
  });
  final String currentFile;
  final int filesProcessed;
  final int totalFilesFound;
}

class ScanTrackFound extends ScanEvent {
  ScanTrackFound(this.track);
  final LibraryTrack track;
}

class ScanComplete extends ScanEvent {
  ScanComplete(this.totalTracksIndexed);
  final int totalTracksIndexed;
}

/// Evento terminal de un escaneo cancelado por el usuario (FR-SCANR-001).
///
/// Conserva el progreso parcial para el resumen de estado.
class ScanCancelled extends ScanEvent {
  ScanCancelled(this.filesProcessed);
  final int filesProcessed;
}

enum ScanErrorKind { file, critical }

class ScanError extends ScanEvent {
  ScanError({
    required this.message,
    required this.path,
    this.kind = ScanErrorKind.critical,
  });
  final String message;
  final String path;
  final ScanErrorKind kind;
}
