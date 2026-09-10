import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/presentation/widgets/player_widget.dart';

import '../../../fakes/fake_audio_engine.dart';

void main() {
  group('PlayerWidget', () {
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

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [audioEngineProvider.overrideWithValue(fakeEngine)],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: PlayerWidget())),
        ),
      );
    }

    testWidgets('renders placeholder when no track is active', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Sin pista seleccionada'), findsOneWidget);
      expect(
        find.text('Carga un archivo de audio para comenzar'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('Abrir archivo de audio'), findsOneWidget);
    });

    testWidgets('renders track info when track is loaded', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await fakeEngine.load(testTrack);
      await tester.pump();

      expect(find.text('Bohemian Rhapsody'), findsOneWidget);
      expect(find.text('Queen'), findsOneWidget);
      expect(find.text('05:55'), findsOneWidget);
    });

    testWidgets('play/pause button toggles playback state and icon', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await fakeEngine.load(testTrack);
      await tester.pump();

      // En pausa / idle: muestra icono play
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Tap play
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();

      // Ahora en reproducción: muestra icono pause
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(fakeEngine.currentState.isPlaying, isTrue);

      // Tap pause
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      // Regresa a icono play
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(fakeEngine.currentState.isPaused, isTrue);
    });
  });
}
