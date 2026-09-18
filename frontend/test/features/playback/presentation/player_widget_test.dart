import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/presentation/widgets/player_widget.dart';

import '../../../fakes/fake_audio_engine.dart';

void _noop() {}

void main() {
  group('PlayerWidget with Queue, Repeat and Shuffle controls', () {
    late FakeAudioEngine fakeEngine;

    const testTrack = TrackRef(
      id: 'test-1',
      uri: 'file:///path/song.mp3',
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      duration: Duration(minutes: 5, seconds: 55),
    );

    setUp(() {
      fakeEngine = FakeAudioEngine();
    });

    Widget createWidgetUnderTest({ProviderContainer? container}) {
      return UncontrolledProviderScope(
        container:
            container ??
            ProviderContainer(
              overrides: [audioEngineProvider.overrideWithValue(fakeEngine)],
            ),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerWidget(onQueuePressed: _noop),
            ),
          ),
        ),
      );
    }

    testWidgets('renders placeholder and controls when idle', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Sin pista seleccionada'), findsOneWidget);
      expect(find.text('Carga una pista para comenzar'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
      expect(find.text('Cola (0)'), findsOneWidget);
    });

    testWidgets('shuffle button toggles shuffle mode in controller', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [audioEngineProvider.overrideWithValue(fakeEngine)],
      );

      await tester.pumpWidget(createWidgetUnderTest(container: container));

      expect(container.read(playbackControllerProvider).isShuffle, isFalse);

      await tester.tap(find.byIcon(Icons.shuffle_rounded));
      await tester.pump();

      expect(container.read(playbackControllerProvider).isShuffle, isTrue);
    });

    testWidgets('repeat button cycles repeat mode in controller', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [audioEngineProvider.overrideWithValue(fakeEngine)],
      );

      await tester.pumpWidget(createWidgetUnderTest(container: container));

      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.off),
      );

      // Tap 1 -> RepeatMode.all (muestra Icons.repeat_rounded)
      await tester.tap(find.byIcon(Icons.repeat_rounded));
      await tester.pump();
      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.all),
      );

      // Tap 2 -> RepeatMode.one (muestra Icons.repeat_one_rounded)
      await tester.tap(find.byIcon(Icons.repeat_rounded));
      await tester.pump();
      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.one),
      );
      expect(find.byIcon(Icons.repeat_one_rounded), findsOneWidget);
    });

    testWidgets('play/pause button toggles playback state', (tester) async {
      final container = ProviderContainer(
        overrides: [audioEngineProvider.overrideWithValue(fakeEngine)],
      );

      await tester.pumpWidget(createWidgetUnderTest(container: container));

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(testTrack);
      await tester.pump();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}
