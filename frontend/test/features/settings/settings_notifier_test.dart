import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/settings/application/settings_notifier.dart';
import 'package:otune/features/settings/domain/entities/app_settings.dart';

import '../../fakes/fake_settings_repository.dart';

ProviderContainer _offlineContainer() {
  // Repositorio en memoria: evita tocar el almacenamiento real (y el binding
  // de plataforma) en pruebas unitarias.
  return ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    ],
  );
}

void main() {
  test('starts with system theme and updates the preference', () {
    final container = _offlineContainer();
    addTearDown(container.dispose);
    final notifier = container.read(settingsProvider.notifier);

    expect(
      container.read(settingsProvider).settings.themePreference,
      ThemePreference.system,
    );

    notifier.updateTheme(ThemePreference.dark);

    expect(
      container.read(settingsProvider).settings.themePreference,
      ThemePreference.dark,
    );
    expect(
      const AppSettings()
          .copyWith(themePreference: ThemePreference.light)
          .themePreference,
      ThemePreference.light,
    );
  });

  group('updateBadgeDuration', () {
    test('accepts supported durations', () {
      final container = _offlineContainer();
      addTearDown(container.dispose);

      container
          .read(settingsProvider.notifier)
          .updateBadgeDuration(const Duration(seconds: 5));

      expect(
        container.read(settingsProvider).settings.badgeDuration,
        const Duration(seconds: 5),
      );
    });

    test('rejects values outside the supported catalogue', () {
      final container = _offlineContainer();
      addTearDown(container.dispose);
      const defaultDuration = Duration(seconds: 3);

      for (final invalid in const [
        Duration(seconds: 7),
        Duration.zero,
        Duration(seconds: -2),
      ]) {
        container.read(settingsProvider.notifier).updateBadgeDuration(invalid);

        expect(
          container.read(settingsProvider).settings.badgeDuration,
          defaultDuration,
          reason: 'La duración inválida $invalid no debe mutar la preferencia',
        );
      }
    });
  });
}
