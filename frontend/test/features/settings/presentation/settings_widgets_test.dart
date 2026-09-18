import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/settings/domain/entities/app_settings.dart';
import 'package:otune/features/settings/presentation/pages/settings_page.dart';
import 'package:otune/features/settings/presentation/widgets/theme_preference_tile.dart';

void main() {
  testWidgets('theme preference tile displays and changes selection', (
    tester,
  ) async {
    ThemePreference? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThemePreferenceTile(
            preference: ThemePreference.system,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('Sistema'), findsAtLeastNWidgets(1));
    await tester.tap(find.byType(DropdownButton<ThemePreference>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscuro').last);

    expect(selected, ThemePreference.dark);
  });

  testWidgets('settings page shows information dialog', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );

    expect(find.text('Ajustes'), findsOneWidget);
    await tester.tap(find.text('Información'));
    await tester.pumpAndSettle();

    expect(find.text('Otune'), findsOneWidget);
    expect(find.text('By Oyhs-Co'), findsOneWidget);
  });
}
