import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/app/app.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_persistence.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

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
}
