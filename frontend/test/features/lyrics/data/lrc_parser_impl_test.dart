import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/lyrics/data/services/lrc_parser_impl.dart';

void main() {
  test('parses and sorts timestamped lines', () {
    final lyrics = LrcParserImpl().parse(
      'track-1',
      '[00:12.50] Second line\n[00:01.25] First line\nIgnored metadata',
    );

    expect(lyrics.trackId, 'track-1');
    expect(lyrics.lines, hasLength(2));
    expect(
      lyrics.lines.first.timestamp,
      const Duration(seconds: 1, milliseconds: 250),
    );
    expect(lyrics.lines.first.text, 'First line');
    expect(
      lyrics.lines.last.timestamp,
      const Duration(seconds: 12, milliseconds: 500),
    );
  });

  test('accepts an empty lyric line', () {
    final lyrics = LrcParserImpl().parse('track-1', '[00:00.00]   ');

    expect(lyrics.isEmpty, isFalse);
    expect(lyrics.lines.single.text, isEmpty);
    expect(lyrics.lines.single.toString(), '[0ms]: ');
  });
}
