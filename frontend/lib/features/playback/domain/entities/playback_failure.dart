import 'package:meta/meta.dart';

/// Categoría de fallo de reproducción reconocida por el dominio.
///
/// El motor emite mensajes de error como strings; el dominio sólo razona
/// con esta taxonomía cerrada (S3-3: fallos del motor tipados, sin acoplar
/// media_kit al dominio).
enum PlaybackFailureKind {
  /// El archivo no existe o la URI no es accesible.
  missingFile,

  /// El archivo existe pero no puede decodificarse (corrupto o no soportado).
  corruptFile,

  /// Falta un permiso para acceder al archivo.
  permissionDenied,

  /// Cualquier otro fallo del motor.
  unknown,
}

/// Fallo de reproducción clasificado, con mensaje presentable al usuario.
@immutable
class PlaybackFailure {
  const PlaybackFailure({required this.kind, required this.message});

  /// Clasifica el mensaje de error del motor en la taxonomía del dominio.
  ///
  /// [uri] permite distinguir rutas inexistentes de archivos corruptos.
  factory PlaybackFailure.categorize({
    required String? engineMessage,
    required String uri,
  }) {
    final message = engineMessage ?? '';

    if (_matchesAny(message, const [
      'permission',
      'denied',
      'access is denied',
      'not allowed',
    ])) {
      return const PlaybackFailure(
        kind: PlaybackFailureKind.permissionDenied,
        message: 'Otune no tiene permiso para abrir este archivo.',
      );
    }

    if (_matchesAny(message, const [
      'no such file',
      'file not found',
      'not found',
      'does not exist',
      'no existe',
    ])) {
      return const PlaybackFailure(
        kind: PlaybackFailureKind.missingFile,
        message: 'El archivo de audio no está disponible.',
      );
    }

    if (_matchesAny(message, const [
      'corrupt',
      'invalid data',
      'malformed',
      'unsupported',
      'failed to open',
      'no demuxer',
      'unable to open',
    ])) {
      return const PlaybackFailure(
        kind: PlaybackFailureKind.corruptFile,
        message: 'El archivo de audio no se puede reproducir.',
      );
    }

    if (uri.startsWith('file:') && !_looksLikeExistingPath(uri)) {
      return const PlaybackFailure(
        kind: PlaybackFailureKind.missingFile,
        message: 'El archivo de audio no está disponible.',
      );
    }

    return const PlaybackFailure(
      kind: PlaybackFailureKind.unknown,
      message: 'No se pudo reproducir este archivo.',
    );
  }

  final PlaybackFailureKind kind;

  /// Mensaje accionable para la superficie de error en la UI.
  final String message;

  static bool _matchesAny(String message, List<String> patterns) {
    final normalized = message.toLowerCase();
    return patterns.any(normalized.contains);
  }

  static bool _looksLikeExistingPath(String uri) {
    // No se accede al filesystem desde el dominio; la heurística sólo
    // descarta URIs vacías o evidentemente inválidas.
    final path = uri.replaceFirst(RegExp('^file://'), '');
    return path.trim().isNotEmpty;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackFailure &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          message == other.message;

  @override
  int get hashCode => Object.hash(kind, message);

  @override
  String toString() => 'PlaybackFailure(kind: $kind, message: $message)';
}
