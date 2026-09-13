import 'package:otune/features/lyrics/domain/entities/lyrics.dart';
import 'package:otune/features/lyrics/domain/services/lrc_parser.dart';

class LrcParserImpl implements LrcParser {
  @override
  Lyrics parse(String trackId, String content) {
    final List<LyricLine> lines = [];
    final RegExp timestampRegExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\]');

    for (final line in content.split('\n')) {
      final match = timestampRegExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);

        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: centiseconds * 10,
        );

        final text = line.substring(match.end).trim();
        lines.add(LyricLine(timestamp: timestamp, text: text));
      }
    }

    // Ensure lyrics are sorted by timestamp as per domain rules
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Lyrics(trackId: trackId, lines: lines);
  }
}
