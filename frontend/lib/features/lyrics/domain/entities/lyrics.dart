import 'package:meta/meta.dart';

/// Representa una línea sincronizada de letra musical.
@immutable
class LyricLine {
  const new({required this.timestamp, required this.text});

  final Duration timestamp;
  final String text;

  @override
  String toString() => '[${timestamp.inMilliseconds}ms]: $text';
}

/// Entidad de dominio que contiene las letras completas sincronizadas
/// de una pista.
@immutable
class Lyrics {
  const new({required this.trackId, required this.lines});

  final String trackId;
  final List<LyricLine> lines;

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;
}
