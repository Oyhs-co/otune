import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/app/app.dart';
import 'package:otune/app/router/app_router.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_persistence.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/presentation/pages/now_playing_page.dart';
import 'package:otune/features/playback/presentation/widgets/mini_player.dart';

import 'fakes/fake_audio_engine.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fakeEngine = FakeAudioEngine();
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(fakeEngine),
        // Sin timers de debounce pendientes al desechar el árbol de widgets.
        playbackSaveDebounceProvider.overrideWithValue(null),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const OtuneApp()),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    return container;
  }

  testWidgets('shows bottom navigation on mobile', (tester) async {
    final container = await pumpApp(tester);
    addTearDown(container.dispose);

    expect(find.text('Mi Biblioteca'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);
  });

  testWidgets('shows navigation rail on wide screens', (tester) async {
    final container = await pumpApp(tester, width: 800);
    addTearDown(container.dispose);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);
  });

  testWidgets('switching sections preserves playback', (tester) async {
    final container = await pumpApp(tester);
    addTearDown(container.dispose);
    const track = TrackRef(
      id: 'navigation-track',
      uri: 'file:///navigation-track.mp3',
      title: 'Navigation track',
    );

    await container.read(playbackControllerProvider.notifier).playTrack(track);
    await tester.pump();
    expect(container.read(playbackControllerProvider).isPlaying, isTrue);

    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsWidgets);
    expect(container.read(playbackControllerProvider).isPlaying, isTrue);
  });

  group('contratos de UI (S3-1)', () {
    const track = TrackRef(
      id: 'mini-player-track',
      uri: 'file:///mini-player-track.mp3',
      title: 'Mini player track',
    );

    testWidgets(
      'mini player visible y actualizado al cambiar de sección (móvil)',
      (tester) async {
        final container = await pumpApp(tester);
        addTearDown(container.dispose);

        await container
            .read(playbackControllerProvider.notifier)
            .playTrack(track);
        // Duración fija: el shell mantiene un spinner mientras el
        // FutureProvider de biblioteca no resuelve en el entorno de test.
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Mini player track'), findsOneWidget);

        await tester.tap(find.text('Ajustes').last);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        // El mini player sigue visible y muestra la pista activa.
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Mini player track'), findsOneWidget);
        expect(container.read(playbackControllerProvider).isPlaying, isTrue);
      },
    );

    testWidgets(
      'mini player visible y actualizado al cambiar de sección (escritorio)',
      (tester) async {
        final container = await pumpApp(tester, width: 800);
        addTearDown(container.dispose);

        await container
            .read(playbackControllerProvider.notifier)
            .playTrack(track);
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Mini player track'), findsOneWidget);

        await tester.tap(find.text('Ajustes').last);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Mini player track'), findsOneWidget);
      },
    );

    testWidgets(
      'abrir Now Playing no crea una segunda sesión ni reinicia la cola',
      (tester) async {
        final container = await pumpApp(tester);
        addTearDown(container.dispose);

        final controller = container.read(playbackControllerProvider.notifier);
        await controller.setQueue([
          const TrackRef(
            id: 'queue-1',
            uri: 'file:///queue-1.mp3',
            title: 'Queue 1',
          ),
          const TrackRef(
            id: 'queue-2',
            uri: 'file:///queue-2.mp3',
            title: 'Queue 2',
          ),
        ], startIndex: 1);
        await tester.pump(const Duration(seconds: 1));

        final engineBefore = container.read(audioEngineProvider);
        final sessionBefore = container.read(
          playbackControllerProvider,
        ); // Abrir Now Playing por el mismo camino que el mini player
        // (pushNamed 'now-playing', sin await: el Future completa al cerrar
        // la ruta). El contrato S3-1 es que la APERTURA de la página no
        // duplique sesión ni reinicie la cola.
        unawaited(container.read(appRouterProvider).pushNamed('now-playing'));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        // La navegación realmente ocurrió.
        expect(find.byType(NowPlayingPage), findsOneWidget);

        expect(container.read(audioEngineProvider), same(engineBefore));
        expect(
          container.read(playbackControllerProvider).currentIndex,
          equals(sessionBefore.currentIndex),
        );
        expect(
          container.read(playbackControllerProvider).queueItems.length,
          equals(2),
        );
        expect(container.read(playbackControllerProvider).isPlaying, isTrue);
      },
    );
  });
}
