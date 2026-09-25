import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/domain/entities/library_sort_option.dart';
import 'package:otune/features/library/domain/entities/library_view_mode.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/repositories/library_repository.dart';
import 'package:otune/features/library/presentation/widgets/lazy_artwork.dart';
import 'package:otune/features/library/presentation/widgets/library_empty_state.dart';
import 'package:otune/features/library/presentation/widgets/library_sort_menu.dart';
import 'package:otune/features/library/presentation/widgets/library_track_list.dart';
import 'package:otune/features/playback/application/playback_providers.dart';

import '../../../fakes/fake_audio_engine.dart';

/// Repositorio con artwork determinista para probar la resolución lazy.
class FakeArtworkLibraryRepository implements LibraryRepository {
  @override
  Future<List<LibraryTrack>> getAllTracks({LibrarySort? sort}) async =>
      const [];

  @override
  Future<List<LibraryTrack>> searchTracks(
    String query, {
    LibrarySort? sort,
  }) async => const [];

  @override
  Future<void> upsertTrack(LibraryTrack track) async {}

  @override
  Future<void> deleteTrack(String id) async {}

  @override
  Future<LibraryTrack?> getTrackById(String id) async => null;

  int artworkRequests = 0;

  /// PNG 1×1 válido para que Image.memory lo decodifique.
  static final Uint8List _validPng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // firma
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  @override
  Future<Uint8List?> getTrackArtwork(String id) async {
    artworkRequests++;
    return id == 'with-art' ? _validPng : null;
  }

  @override
  Future<List<String>> findMissingTracks({List<String>? candidateIds}) async =>
      const [];

  @override
  Future<void> deleteTracks(List<String> ids) async {}

  @override
  Future<void> restoreTracks(List<LibraryTrack> tracks) async {}
}

void main() {
  const track = LibraryTrack(
    id: 'track-1',
    title: 'Night Drive',
    path: '/music/night-drive.mp3',
    artist: 'Nova Echo',
    album: 'Afterglow',
    duration: Duration(minutes: 3),
  );

  testWidgets('empty state invokes its action and supports no button', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LibraryEmptyState(
          message: 'No music',
          buttonText: 'Scan',
          onButtonPressed: () => pressed = true,
        ),
      ),
    );

    expect(find.text('No music'), findsOneWidget);
    await tester.tap(find.text('Scan'));
    expect(pressed, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: LibraryEmptyState(
          message: 'Still empty',
          buttonText: '',
          onButtonPressed: () {},
        ),
      ),
    );
    expect(find.text('Still empty'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('track list renders all view modes and invokes selection', (
    tester,
  ) async {
    final engine = FakeAudioEngine();
    var selected = false;

    for (final viewMode in LibraryViewMode.values) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [audioEngineProvider.overrideWithValue(engine)],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                child: LibraryTrackList(
                  tracks: const [track],
                  viewMode: viewMode,
                  onTrackSelected: (_) => selected = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Night Drive'), findsOneWidget);
      await tester.tap(find.text('Night Drive'));
      expect(selected, isTrue);
    }

    await engine.dispose();
  });

  testWidgets('AC-AW-003: LazyArtwork resolves on demand and falls back', (
    widgetTester,
  ) async {
    final repository = FakeArtworkLibraryRepository();

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LazyArtwork(trackId: 'with-art'),
                LazyArtwork(trackId: 'without-art'),
              ],
            ),
          ),
        ),
      ),
    );
    await widgetTester.pumpAndSettle();

    // La pista con arte resuelve su imagen; la sin arte queda en placeholder.
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(LazyArtwork), findsNWidgets(2));
    expect(repository.artworkRequests, 2);
  });

  testWidgets('AC-SORT-004: sort menu exposes all options and marks active', (
    tester,
  ) async {
    LibrarySortOption? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibrarySortMenu(
            sortOption: LibrarySortOption.title,
            onSortChanged: (option) => selected = option,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.sort_by_alpha));
    await tester.pumpAndSettle();

    // Cuatro criterios: Título, Artista, Álbum, Añadido recientemente.
    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Artista'), findsOneWidget);
    expect(find.text('Álbum'), findsOneWidget);
    expect(find.text('Añadido recientemente'), findsOneWidget);

    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();

    expect(selected, LibrarySortOption.artist);
  });
}
