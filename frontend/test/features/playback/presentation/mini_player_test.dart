import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_persistence.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/presentation/widgets/mini_player.dart';

import '../../../fakes/fake_audio_engine.dart';

void main() {
  testWidgets('shows track info when a track is active', (tester) async {
    final fakeEngine = FakeAudioEngine();
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(fakeEngine),
        playbackSaveDebounceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    const track = TrackRef(id: 't1', uri: 'file:///t1.mp3', title: 'Song A');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MiniPlayer())),
      ),
    );

    await container.read(playbackControllerProvider.notifier).playTrack(track);
    await tester.pumpAndSettle();

    expect(find.text('Song A'), findsOneWidget);
    expect(find.byType(MiniPlayer), findsOneWidget);
  });

  testWidgets('shows nothing without an active track', (tester) async {
    final fakeEngine = FakeAudioEngine();
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(fakeEngine),
        playbackSaveDebounceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MiniPlayer())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Song A'), findsNothing);
    expect(find.byIcon(Icons.skip_next_rounded), findsNothing);
  });

  testWidgets('shows the classified error message while in error state', (
    tester,
  ) async {
    final fakeEngine = FakeAudioEngine();
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(fakeEngine),
        playbackSaveDebounceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    const track = TrackRef(
      id: 't2',
      uri: 'file:///broken.mp3',
      title: 'Song B',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MiniPlayer())),
      ),
    );

    await container.read(playbackControllerProvider.notifier).playTrack(track);
    await tester.pumpAndSettle();

    fakeEngine.emitState(
      fakeEngine.currentState.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'file not found',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('El archivo de audio no está disponible.'),
      findsOneWidget,
    );
    expect(find.text('Song B'), findsOneWidget);
  });
}
