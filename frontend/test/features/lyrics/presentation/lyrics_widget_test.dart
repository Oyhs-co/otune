import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/lyrics/application/lyrics_sync_notifier.dart';
import 'package:otune/features/lyrics/domain/entities/lyrics.dart';
import 'package:otune/features/lyrics/presentation/widgets/lyrics_widget.dart';
import 'package:otune/features/playback/application/playback_providers.dart';

import '../../../fakes/fake_audio_engine.dart';

void main() {
  testWidgets('shows the empty lyrics state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioEngineProvider.overrideWithValue(FakeAudioEngine())],
        child: const MaterialApp(home: LyricsWidget()),
      ),
    );

    expect(
      find.text('No hay letras disponibles para esta pista'),
      findsOneWidget,
    );
  });

  testWidgets('renders lyrics and seeks when a line is tapped', (tester) async {
    final engine = FakeAudioEngine();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineProvider.overrideWithValue(engine),
          lyricsSyncProvider.overrideWith(LyricsSyncNotifier.new),
        ],
        child: const MaterialApp(home: Scaffold(body: LyricsWidget())),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LyricsWidget)),
    );
    container.read(lyricsSyncProvider.notifier).state = const ActiveLyricsState(
      lyrics: Lyrics(
        trackId: 'track-1',
        lines: [
          LyricLine(timestamp: Duration(seconds: 2), text: 'First line'),
          LyricLine(timestamp: Duration(seconds: 4), text: 'Second line'),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('First line'), findsOneWidget);
    await tester.tap(find.text('Second line'));
    await tester.pump();
    expect(engine.currentState.position, const Duration(seconds: 4));

    await engine.dispose();
  });
}
