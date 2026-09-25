import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/data/repositories/drift_library_repository.dart';
import 'package:otune/features/library/domain/entities/library_sort_option.dart';
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

      when(() => mockDb.getAllTracks(sort: any(named: 'sort')))
          .thenAnswer((_) async => tracks);

      final result = await repository.getAllTracks();

      expect(result, equals(tracks));
      verify(() => mockDb.getAllTracks(sort: any(named: 'sort'))).called(1);
    });

    test('searchTracks should call database searchTracks', () async {
      const query = 'test';
      final tracks = [
        const LibraryTrack(id: '1', title: 'Test Song', path: '/path/1'),
      ];

      when(() => mockDb.searchTracks(query, sort: any(named: 'sort')))
          .thenAnswer((_) async => tracks);

      final result = await repository.searchTracks(query);

      expect(result, equals(tracks));
      verify(() => mockDb.searchTracks(query, sort: any(named: 'sort')))
          .called(1);
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

  group('DriftLibraryRepository sobre base de datos en memoria (Sprint 4)', () {
    late AppDatabase database;
    late DriftLibraryRepository repository;
    late Directory tempDir;
    late String existingPath;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = DriftLibraryRepository(database);
      tempDir = Directory.systemTemp.createTempSync('otune-repo-test-');
      existingPath = '${tempDir.path}${Platform.pathSeparator}present.mp3';
      File(existingPath).writeAsBytesSync([0, 1, 2, 3]);
    });

    tearDown(() async {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      await database.close();
    });

    Future<void> seed() async {
      await repository.upsertTrack(
        const LibraryTrack(
          id: 'zeta',
          title: 'Zeta',
          path: '/zeta.mp3',
          artist: 'Aurora',
          album: 'Waves',
        ),
      );
      await repository.upsertTrack(
        const LibraryTrack(
          id: 'alfa',
          title: 'alfa',
          path: '/alfa.mp3',
          artist: 'beat Collective',
          album: 'Anchor',
        ),
      );
      await repository.upsertTrack(
        const LibraryTrack(id: 'mid', title: 'Midnight', path: '/mid.mp3'),
      );
      // Garantizar addedAt distintos para la ordenación por incorporación.
      final zetaDate = DateTime(2026, 1, 15).millisecondsSinceEpoch;
      final alfaDate = DateTime(2026, 2, 15).millisecondsSinceEpoch;
      final midDate = DateTime(2026, 3, 15).millisecondsSinceEpoch;
      await database.customStatement(
        "UPDATE tracks SET added_at = ? WHERE id = 'zeta'",
        [zetaDate],
      );
      await database.customStatement(
        "UPDATE tracks SET added_at = ? WHERE id = 'alfa'",
        [alfaDate],
      );
      await database.customStatement(
        "UPDATE tracks SET added_at = ? WHERE id = 'mid'",
        [midDate],
      );
    }

    test('AC-SORT-001: orders by each criterion', () async {
      await seed();

      final byTitle = await repository.getAllTracks(
        sort: (option: LibrarySortOption.title, descending: true),
      );
      expect(byTitle.map((t) => t.title).toList(), [
        'alfa',
        'Midnight',
        'Zeta',
      ], reason: 'ordenación ASCII: mayúsculas antes que minúsculas');

      final byArtist = await repository.getAllTracks(
        sort: (option: LibrarySortOption.artist, descending: true),
      );
      // SQLite NOCASE ordena los nulos primero en modo ascendente.
      expect(byArtist.map((t) => t.artist).toList(), [
        null,
        'Aurora',
        'beat Collective',
      ]);

      final byAlbum = await repository.getAllTracks(
        sort: (option: LibrarySortOption.album, descending: true),
      );
      expect(byAlbum.map((t) => t.album).toList(), [null, 'Anchor', 'Waves']);
    });

    test('AC-SORT-001: addedAt orders newest first', () async {
      await seed();

      final byAdded = await repository.getAllTracks(
        sort: (option: LibrarySortOption.addedAt, descending: true),
      );
      expect(byAdded.map((t) => t.id).toList(), [
        'mid',
        'alfa',
        'zeta',
      ], reason: 'FR-SORT-003: más reciente primero');
    });

    test('AC-AW-001: list queries do not load artwork blobs', () async {
      await repository.upsertTrack(
        LibraryTrack(
          id: 'with-art',
          title: 'With art',
          path: '/with-art.mp3',
          albumArt: Uint8List.fromList([9, 9, 9]),
        ),
      );

      final tracks = await repository.getAllTracks();
      final searched = await repository.searchTracks('With');

      expect(tracks.single.albumArt, isNull);
      expect(searched.single.albumArt, isNull);
    });

    test('AC-AW-001: getTrackArtwork resolves the blob by id', () async {
      final art = Uint8List.fromList([9, 9, 9]);
      await repository.upsertTrack(
        LibraryTrack(
          id: 'with-art',
          title: 'With art',
          path: '/with-art.mp3',
          albumArt: art,
        ),
      );
      await repository.upsertTrack(
        const LibraryTrack(id: 'no-art', title: 'No art', path: '/no.mp3'),
      );

      expect(await repository.getTrackArtwork('with-art'), art);
      expect(await repository.getTrackArtwork('no-art'), isNull);
    });

    test(
      'AC-SCANR-004: missing tracks detection and transactional restore',
      () async {
        final art = Uint8List.fromList([1, 2, 3]);
        final present = LibraryTrack(
          id: 'present',
          title: 'Present',
          path: existingPath,
          addedAt: DateTime(2026, 1, 20),
          artist: 'Artist',
          album: 'Album',
          albumArt: art,
        );
        final missing = LibraryTrack(
          id: 'missing',
          title: 'Missing',
          path: '${tempDir.path}${Platform.pathSeparator}gone.mp3',
          addedAt: DateTime(2026, 2, 20),
        );
        await repository.restoreTracks([present, missing]);

        final missingIds = await repository.findMissingTracks();
        expect(missingIds, ['missing']);

        await repository.deleteTracks(missingIds);
        expect((await repository.getAllTracks()).map((t) => t.id), ['present']);

        // Deshacer: restauración transaccional con todos los metadatos.
        await repository.restoreTracks([missing]);
        final restored = await repository.getTrackById('missing');
        expect(restored, isNotNull);
        expect(restored!.title, 'Missing');
      },
    );
  });
}
