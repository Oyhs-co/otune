import 'package:media_metadata/media_metadata.dart';

/// Lectura de metadatos como capacidad inyectable (seam de pruebas).
///
/// `MediaMetadata.read` es un canal de plataforma: no existe en entornos de
/// test unitario, por lo que el escáner lo recibe por constructor y los
/// tests sustituyen esta función por un falso determinista.
typedef MediaMetadataReader = Future<Metadata?> Function(String path);

/// Lector real sobre el plugin `media_metadata`.
Future<Metadata?> defaultMetadataReader(String path) {
  return MediaMetadata.read(path);
}
