import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/presentation/widgets/queue_sheet.dart';

import '../../../fakes/fake_audio_engine.dart';

void main() {
  group('QueueSheet Widget', () {
    late FakeAudioEngine fakeEngine;

    const trackA = TrackRef(id: 'a', uri: 'file:///a.mp3', title: 'Song Alpha');
    const trackB = TrackRef(id: 'b', uri: 'file:///b.mp3', title: 'Song Beta');

    setUp(() {
      fakeEngine = FakeAudioEngine();
    });

    testWidgets('renders empty state when queue is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [audioEngineProvider.overrideWithValue(fakeEngine)],
          child: const MaterialApp(home: Scaffold(body: QueueSheet())),
        ),
      );

      expect(find.text('Cola de reproducción (0)'), findsOneWidget);
      expect(find.text('La cola está vacía'), findsOneWidget);
    });

    testWidgets('renders tracks and allows removing an item', (tester) async {
      final container = ProviderContainer(
        overrides: [audioEngineProvider.overrideWithValue(fakeEngine)],
      );

      // Pre-cargamos dos canciones en la cola
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.setQueue([trackA, trackB]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: QueueSheet())),
        ),
      );

      expect(find.text('Cola de reproducción (2)'), findsOneWidget);
      expect(find.text('Song Alpha'), findsOneWidget);
      expect(find.text('Song Beta'), findsOneWidget);

      // Eliminamos Song Beta
      final closeButtons = find.byIcon(Icons.close_rounded);
      await tester.tap(closeButtons.last);
      await tester.pump();

      expect(find.text('Cola de reproducción (1)'), findsOneWidget);
      expect(find.text('Song Beta'), findsNothing);
    });
  });
}
