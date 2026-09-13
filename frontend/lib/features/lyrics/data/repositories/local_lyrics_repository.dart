import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:otune/features/lyrics/domain/entities/lyrics.dart';
import 'package:otune/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:otune/features/lyrics/domain/services/lrc_parser.dart';

class LocalLyricsRepository implements LyricsRepository {
  final LrcParser _parser;

  LocalLyricsRepository(this._parser);

  @override
  Future<Lyrics?> getLyricsForTrack(String trackId, String filePath) async {
    try {
      // 1. Try to find .lrc file with same name as audio file in the same directory
      final lrcPath = p.join(
        p.dirname(filePath),
        '${p.basenameWithoutExtension(filePath)}.lrc',
      );

      final lrcFile = File(lrcPath);
      if (await lrcFile.exists()) {
        final content = await lrcFile.readAsString();
        return _parser.parse(trackId, content);
      }
    } catch (e) {
      // Log error but return null as per SPEC (graceful handling)
    }

    return null;
  }

  @override
  Future<void> associateLyrics(String trackId, String lyricsPath) async {
    // For MVP, we rely on the file naming convention.
    // Manual association could be implemented via a database mapping in future phases.
  }
}
