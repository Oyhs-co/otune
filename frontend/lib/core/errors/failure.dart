/// Representación base para fallos del sistema y de dominio.
sealed class Failure {
  const new(this.message);

  final String message;

  @override
  String toString() => 'Failure: $message';
}

/// Fallo inesperado o no controlado.
final class UnexpectedFailure extends Failure {
  const new([super.message = 'Ha ocurrido un error inesperado.']);
}

/// Fallo en operaciones de archivos o sistema de almacenamiento.
final class FileFailure extends Failure {
  const new(super.message);
}

/// Fallo en la capa de audio o motor de reproducción.
final class PlaybackFailure extends Failure {
  const new(super.message);
}

/// Fallo al procesar o analizar archivos (ej. metadatos, LRC).
final class ParseFailure extends Failure {
  const new(super.message);
}
