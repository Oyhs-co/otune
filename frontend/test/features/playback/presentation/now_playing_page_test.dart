import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_persistence.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_state.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/presentation/pages/now_playing_page.dart';
import 'package:otune/features/playback/presentation/widgets/artwork_panel.dart';
import 'package:otune/features/playback/presentation/widgets/playback_controls.dart';
import 'package:otune/features/playback/presentation/widgets/playback_progress.dart';

import '../../../fakes/fake_audio_engine.dart';

void main() {
  Future<ProviderContainer> pumpPage(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [audioEngineProvider.overrideWithValue(FakeAudioEngine())],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NowPlayingPage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('muestra la sección de portada, progreso y controles', (
    tester,
  ) async {
    final container = await pumpPage(tester, width: 390, height: 844);
    addTearDown(container.dispose);

    expect(find.byType(ArtworkPanel), findsOneWidget);
    expect(find.byType(PlaybackProgress), findsOneWidget);
    expect(find.byType(PlaybackControls), findsOneWidget);
  });

  testWidgets('sin overflow en pantalla estrecha y baja', (tester) async {
    final container = await pumpPage(tester, width: 320, height: 560);
    addTearDown(container.dispose);

    expect(tester.takeException(), isNull);
    expect(find.byType(ArtworkPanel), findsOneWidget);
  });

  testWidgets('sin overflow en pantalla amplia', (tester) async {
    final container = await pumpPage(tester, width: 900, height: 1000);
    addTearDown(container.dispose);

    expect(tester.takeException(), isNull);
    expect(find.byType(ArtworkPanel), findsOneWidget);
  });

  group('superficie de error (S3-3)', () {
    testWidgets('muestra mensaje accionable y reintenta al pulsarlo', (
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
        id: 'error-track',
        uri: 'file:///missing.mp3',
        title: 'Missing',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NowPlayingPage()),
        ),
      );

      await container
          .read(playbackControllerProvider.notifier)
          .playTrack(track);
      fakeEngine.loadFailures[track.id] = 'No such file or directory';
      fakeEngine.emitState(
        fakeEngine.currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'No such file or directory',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('El archivo de audio no está disponible.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);

      // La pista "vuelve" y el reintento recarga sin error.
      fakeEngine.loadFailures.remove(track.id);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('no muestra banner cuando no hay error', (tester) async {
      final container = await pumpPage(tester, width: 390, height: 844);
      addTearDown(container.dispose);

      expect(find.text('Reintentar'), findsNothing);
    });
  });
}
