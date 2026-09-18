import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/lyrics/data/repositories/local_lyrics_repository.dart';
import 'package:otune/features/lyrics/domain/entities/lyrics.dart';
import 'package:otune/features/lyrics/domain/services/lrc_parser.dart';

class RecordingLrcParser implements LrcParser {
  String? content;
  Exception? error;

  @override
  Lyrics parse(String trackId, String content) {
    this.content = content;
    if (error != null) throw error!;
    return Lyrics(
      trackId: trackId,
      lines: const [LyricLine(timestamp: Duration.zero, text: 'Parsed')],
    );
  }
}

void main() {
  late Directory directory;
  late RecordingLrcParser parser;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('otune-lyrics-test-');
    parser = RecordingLrcParser();
  });

  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('reads the LRC file next to the audio file', () async {
    final audioPath = '${directory.path}${Platform.pathSeparator}song.mp3';
    final lyricsFile = File(
      '${directory.path}${Platform.pathSeparator}song.lrc',
    )..writeAsStringSync('[00:01.00] Hello');

    final result = await LocalLyricsRepository(parser)
        .getLyricsForTrack('track-1', audioPath);

    expect(result?.trackId, 'track-1');
    expect(parser.content, '[00:01.00] Hello');
    expect(lyricsFile.existsSync(), isTrue);
  });

  test('returns null when no matching LRC exists', () async {
    final result = await LocalLyricsRepository(parser).getLyricsForTrack(
      'track-1',
      '${directory.path}${Platform.pathSeparator}missing.mp3',
    );

    expect(result, isNull);
    expect(parser.content, isNull);
  });

  test('returns null when parsing fails', () async {
    parser.error = const FormatException('invalid lrc');
    File('${directory.path}${Platform.pathSeparator}song.lrc')
        .writeAsStringSync('[00:01.00] Hello');

    final result = await LocalLyricsRepository(parser).getLyricsForTrack(
      'track-1',
      '${directory.path}${Platform.pathSeparator}song.mp3',
    );

    expect(result, isNull);
  });

  test('associateLyrics completes for the MVP naming convention', () async {
    await expectLater(
      LocalLyricsRepository(parser).associateLyrics('track-1', 'song.lrc'),
      completes,
    );
  });
}
