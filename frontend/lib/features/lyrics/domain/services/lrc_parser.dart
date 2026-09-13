import 'package:otune/features/lyrics/domain/entities/lyrics.dart';

/// Servicio encargado de parsear archivos en formato LRC.
abstract interface class LrcParser {
  /// Convierte el contenido de un archivo LRC en una entidad Lyrics.
  Lyrics parse(String trackId, String content);
}
