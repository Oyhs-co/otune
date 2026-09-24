import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/core/design_system/providers/badge_provider.dart';
import 'package:otune/features/settings/application/settings_notifier.dart';
import 'package:otune/features/settings/domain/entities/app_settings.dart';
import 'package:otune/features/settings/presentation/pages/settings_page.dart';
import 'package:otune/features/settings/presentation/widgets/theme_preference_tile.dart';

import '../../../fakes/fake_settings_repository.dart';

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

  // El título de sección ('Ajustes') pertenece al AppShell adaptativo, no a
  // SettingsPage: la página no monta AppBar propio.
  testWidgets('settings page shows information dialog', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );

    expect(find.text('Información'), findsOneWidget);
    await tester.tap(find.text('Información'));
    await tester.pumpAndSettle();

    expect(find.text('Otune'), findsOneWidget);
    expect(find.text('By Oyhs-Co'), findsOneWidget);
  });

  testWidgets('badge duration tile shows the effective preference', (
    tester,
  ) async {
    // Repositorio en memoria: el widget test no debe tocar SharedPreferences.
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    // El texto aparece en el subtitle del tile y en el valor del dropdown.
    expect(find.text('3 segundos'), findsNWidgets(2));

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 segundos').last);
    await tester.pump();

    expect(
      container.read(settingsProvider).settings.badgeDuration,
      const Duration(seconds: 5),
    );
    // El feedback se muestra después de aplicar la preferencia.
    expect(
      container
          .read(badgeProvider)
          .any((badge) => badge.message.contains('5 segundos')),
      isTrue,
    );
    container.read(badgeProvider.notifier).dismissAll();
  });
}
