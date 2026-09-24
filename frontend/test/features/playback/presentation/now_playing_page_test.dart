import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
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
}
