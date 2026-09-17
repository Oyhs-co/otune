import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/app/app.dart';
import 'package:otune/features/playback/application/playback_providers.dart';

import 'fakes/fake_audio_engine.dart';

void main() {
  testWidgets('OtuneApp renders home page smoke test', (tester) async {
    final fakeEngine = FakeAudioEngine();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioEngineProvider.overrideWithValue(fakeEngine)],
        child: const OtuneApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Otune'), findsWidgets);
    expect(find.byTooltip('Biblioteca'), findsOneWidget);
  });
}
