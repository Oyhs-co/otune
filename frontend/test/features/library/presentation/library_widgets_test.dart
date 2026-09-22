import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/library/domain/entities/library_view_mode.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/presentation/widgets/library_empty_state.dart';
import 'package:otune/features/library/presentation/widgets/library_track_list.dart';
import 'package:otune/features/playback/application/playback_providers.dart';

import '../../../fakes/fake_audio_engine.dart';

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
}
