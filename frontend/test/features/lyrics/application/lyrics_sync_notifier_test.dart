import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/lyrics/application/lyrics_providers.dart';
import 'package:otune/features/lyrics/application/lyrics_sync_notifier.dart';
import 'package:otune/features/lyrics/domain/entities/lyrics.dart';
import 'package:otune/features/lyrics/domain/repositories/lyrics_repository.dart';

class FakeLyricsRepository implements LyricsRepository {
  Lyrics? result;
  String? trackId;
  String? filePath;

  @override
  Future<Lyrics?> getLyricsForTrack(String trackId, String filePath) async {
    this.trackId = trackId;
    this.filePath = filePath;
    return result;
  }

  @override
  Future<void> associateLyrics(String trackId, String lyricsPath) async {}
}

void main() {
  late FakeLyricsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeLyricsRepository();
    container = ProviderContainer(
      overrides: [lyricsRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('loads lyrics and resets active line', () async {
    repository.result = const Lyrics(
      trackId: 'track-1',
      lines: [LyricLine(timestamp: Duration(seconds: 2), text: 'Line')],
    );
    final notifier = container.read(lyricsSyncProvider.notifier);

    await notifier.loadLyrics('track-1', '/music/track.mp3');

    expect(repository.trackId, 'track-1');
    expect(repository.filePath, '/music/track.mp3');
    expect(container.read(lyricsSyncProvider).lyrics, repository.result);
    expect(container.read(lyricsSyncProvider).currentLineIndex, -1);
  });

  test('updates the active line according to the current position', () async {
    repository.result = const Lyrics(
      trackId: 'track-1',
      lines: [
        LyricLine(timestamp: Duration(seconds: 1), text: 'One'),
        LyricLine(timestamp: Duration(seconds: 3), text: 'Two'),
      ],
    );
    final notifier = container.read(lyricsSyncProvider.notifier);
    await notifier.loadLyrics('track-1', '/music/track.mp3');

    notifier
      ..updatePosition(const Duration(milliseconds: 500))
      ..updatePosition(const Duration(seconds: 1));
    expect(container.read(lyricsSyncProvider).currentLineIndex, 0);
    notifier.updatePosition(const Duration(seconds: 4));
    expect(container.read(lyricsSyncProvider).currentLineIndex, 1);
  });

  test('ignores updates without lyrics and clear resets state', () {
    container.read(lyricsSyncProvider.notifier).clear();
    final state = container.read(lyricsSyncProvider);
    expect(state.currentLineIndex, -1);
    expect(state.lyrics, isNull);
  });
}
