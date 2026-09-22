import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/data/repositories/drift_library_repository.dart';
import 'package:otune/features/library/domain/entities/track.dart';

class MockAppDatabase extends Mock implements AppDatabase;

void main() {
  setUpAll(() {
    registerFallbackValue(
      TracksCompanion.insert(
        id: 'fallback',
        title: 'fallback',
        path: 'fallback',
      ),
    );
  });

  late MockAppDatabase mockDb;
  late DriftLibraryRepository repository;

  setUp(() {
    mockDb = MockAppDatabase();
    repository = DriftLibraryRepository(mockDb);
  });

  group('DriftLibraryRepository', () {
    test('getAllTracks should call database getAllTracks', () async {
      final tracks = [
        const LibraryTrack(id: '1', title: 'Song 1', path: '/path/1'),
      ];

      when(() => mockDb.getAllTracks()).thenAnswer((_) async => tracks);

      final result = await repository.getAllTracks();

      expect(result, equals(tracks));
      verify(() => mockDb.getAllTracks()).called(1);
    });

    test('searchTracks should call database searchTracks', () async {
      const query = 'test';
      final tracks = [
        const LibraryTrack(id: '1', title: 'Test Song', path: '/path/1'),
      ];

      when(() => mockDb.searchTracks(query)).thenAnswer((_) async => tracks);

      final result = await repository.searchTracks(query);

      expect(result, equals(tracks));
      verify(() => mockDb.searchTracks(query)).called(1);
    });

    test(
      'upsertTrack maps all track fields to the database companion',
      () async {
        const track = LibraryTrack(
          id: '1',
          title: 'Song 1',
          path: '/path/1',
          artist: 'Artist',
          album: 'Album',
          albumArtist: 'Album Artist',
          trackNumber: 2,
          duration: Duration(seconds: 90),
          fileFormat: '.mp3',
        );
        when(() => mockDb.upsertTrack(any())).thenAnswer((_) async => 1);

        await repository.upsertTrack(track);

        final captured = verify(() => mockDb.upsertTrack(captureAny()))
            .captured;
        final companion = captured.single as TracksCompanion;
        expect(companion.id.value, '1');
        expect(companion.title.value, 'Song 1');
        expect(companion.artist.value, 'Artist');
        expect(companion.durationMs.value, 90000);
        expect(companion.fileFormat.value, '.mp3');
      },
    );

    test('deleteTrack delegates to the database', () async {
      when(() => mockDb.deleteTrack('1')).thenAnswer((_) async => 1);

      await repository.deleteTrack('1');

      verify(() => mockDb.deleteTrack('1')).called(1);
    });
  });
}
