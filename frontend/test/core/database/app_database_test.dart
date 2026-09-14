import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('persists Unicode metadata and finds it by text', () async {
    await database.upsertTrack(
      TracksCompanion.insert(
        id: 'unicode-track',
        title: 'Canción 日本語 🎵',
        path: r'C:\Music\Canción 日本語 🎵.mp3',
        artist: const Value('Beyoncé'),
      ),
    );

    final tracks = await database.searchTracks('日本語');

    expect(tracks, hasLength(1));
    expect(tracks.single.title, 'Canción 日本語 🎵');
    expect(tracks.single.artist, 'Beyoncé');
  });

  test('treats LIKE wildcard characters as literal search text', () async {
    await database.upsertTrack(
      TracksCompanion.insert(
        id: 'wildcard-track',
        title: '100%_real',
        path: r'C:\Music\100%_real.mp3',
      ),
    );

    expect(await database.searchTracks('%_'), hasLength(1));
    expect(await database.searchTracks('%x'), isEmpty);
  });
}
