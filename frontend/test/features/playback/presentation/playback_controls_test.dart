import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/playback_persistence.dart';
import 'package:otune/features/playback/application/playback_providers.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:otune/features/playback/presentation/widgets/playback_controls.dart';

import '../../../fakes/fake_audio_engine.dart';

void main() {
  bool isEnabled(WidgetTester tester, IconData icon) {
    final button = tester.widget<IconButton>(
      find
          .ancestor(of: find.byIcon(icon), matching: find.byType(IconButton))
          .first,
    );
    return button.onPressed != null;
  }

  testWidgets('controls are disabled without an active track', (tester) async {
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
        child: const MaterialApp(home: Scaffold(body: PlaybackControls())),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      isEnabled(tester, Icons.shuffle_rounded),
      isFalse,
      reason: 'shuffle sin pista activa debe estar deshabilitado',
    );
    expect(
      isEnabled(tester, Icons.skip_previous_rounded),
      isFalse,
      reason: 'anterior sin pista activa debe estar deshabilitado',
    );
    expect(
      isEnabled(tester, Icons.play_arrow_rounded),
      isFalse,
      reason: 'play sin pista activa debe estar deshabilitado',
    );
    expect(
      isEnabled(tester, Icons.skip_next_rounded),
      isFalse,
      reason: 'siguiente sin pista activa debe estar deshabilitado',
    );
    expect(
      isEnabled(tester, Icons.repeat_rounded),
      isFalse,
      reason: 'repetir sin pista activa debe estar deshabilitado',
    );
  });

  testWidgets('skip controls respect navigation boundaries', (tester) async {
    final fakeEngine = FakeAudioEngine();
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(fakeEngine),
        playbackSaveDebounceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    const track = TrackRef(id: 't1', uri: 'file:///t1.mp3', title: 'Track 1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: PlaybackControls())),
      ),
    );

    await container.read(playbackControllerProvider.notifier).playTrack(track);
    await tester.pump();

    // Una sola pista, repeat off: no hay siguiente ni anterior real.
    expect(
      isEnabled(tester, Icons.skip_previous_rounded),
      isFalse,
      reason: 'anterior en cola de una pista debe estar deshabilitado',
    );
    expect(
      isEnabled(tester, Icons.skip_next_rounded),
      isFalse,
      reason: 'siguiente en cola de una pista debe estar deshabilitado',
    );
    // Reproduciendo: el botón central muestra pausa y está habilitado.
    expect(isEnabled(tester, Icons.pause_rounded), isTrue);

    // Repeat all habilita la navegación circular.
    container
        .read(playbackControllerProvider.notifier)
        .cycleRepeatMode(); // off -> all
    await tester.pump();

    expect(
      container.read(playbackControllerProvider).repeatMode,
      equals(RepeatMode.all),
    );
    expect(isEnabled(tester, Icons.skip_next_rounded), isTrue);
    expect(isEnabled(tester, Icons.skip_previous_rounded), isTrue);
  });
}
