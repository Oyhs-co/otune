import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/application/library_search_provider.dart';
import 'package:otune/features/library/application/library_view_provider.dart';
import 'package:otune/features/library/domain/entities/library_view_mode.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/repositories/library_repository.dart';

class FakeLibraryRepository implements LibraryRepository {
  final tracks = [const LibraryTrack(id: '1', title: 'One', path: '/one.mp3')];
  String? searchedQuery;

  @override
  Future<List<LibraryTrack>> getAllTracks() async => tracks;

  @override
  Future<List<LibraryTrack>> searchTracks(String query) async {
    searchedQuery = query;
    return tracks;
  }

  @override
  Future<void> upsertTrack(LibraryTrack track) async {}

  @override
  Future<void> deleteTrack(String id) async {}
}

void main() {
  late FakeLibraryRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeLibraryRepository();
    container = ProviderContainer(
      overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test(
    'library search defaults to all tracks and searches non-empty query',
    () async {
      expect(
        await container.read(filteredTracksProvider.future),
        repository.tracks,
      );

      container.read(librarySearchQueryProvider.notifier).query = 'one';
      expect(
        await container.read(filteredTracksProvider.future),
        repository.tracks,
      );
      expect(repository.searchedQuery, 'one');
    },
  );

  test('library view notifier changes between modes', () {
    final notifier = container.read(libraryViewModeProvider.notifier);

    expect(notifier.mode, LibraryViewMode.list);
    notifier.mode = LibraryViewMode.grid;
    expect(container.read(libraryViewModeProvider), LibraryViewMode.grid);
  });
}
