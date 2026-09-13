import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/data/repositories/drift_library_repository.dart';
import 'package:otune/features/library/domain/entities/track.dart';

class MockAppDatabase extends Mock implements AppDatabase;

void main() {
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
  });
}
