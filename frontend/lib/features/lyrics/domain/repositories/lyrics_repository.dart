import 'package:otune/features/lyrics/domain/entities/lyrics.dart';

/// Repositorio para la gestión de letras sincronizadas.
abstract interface class LyricsRepository {
  /// Recupera las letras asociadas a una pista específica.
  Future<Lyrics?> getLyricsForTrack(String trackId, String filePath);

  /// Permite asociar manualmente un archivo de letras a una pista.
  Future<void> associateLyrics(String trackId, String lyricsPath);
}
