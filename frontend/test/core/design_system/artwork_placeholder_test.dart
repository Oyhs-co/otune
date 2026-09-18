import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/core/design_system/widgets/artwork_placeholder.dart';

void main() {
  testWidgets('renders the default icon for every artwork size', (
    tester,
  ) async {
    for (final size in ArtworkSize.values) {
      await tester.pumpWidget(
        MaterialApp(home: ArtworkPlaceholder(size: size)),
      );

      expect(find.byIcon(Icons.music_note), findsOneWidget);
    }
  });

  testWidgets('renders custom artwork content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ArtworkPlaceholder(size: ArtworkSize.medium, child: Text('art')),
      ),
    );

    expect(find.text('art'), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsNothing);
  });
}
