import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/settings/application/settings_notifier.dart';
import 'package:otune/features/settings/domain/entities/app_settings.dart';
import 'package:otune/features/settings/domain/repositories/settings_repository.dart';

import '../../fakes/fake_settings_repository.dart';

void main() {
  group('SettingsNotifier con persistencia', () {
    test('arranca con valores por defecto cuando no hay datos guardados', () {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(settingsProvider).settings.themePreference,
        ThemePreference.system,
      );
      expect(
        container.read(settingsProvider).settings.badgeDuration,
        const Duration(seconds: 3),
      );
    });

    test('hidrata el tema y la duración desde el repositorio', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(
              const AppSettings(
                themePreference: ThemePreference.dark,
                badgeDuration: Duration(seconds: 5),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).hydrate();

      expect(
        container.read(settingsProvider).settings.themePreference,
        ThemePreference.dark,
      );
      expect(
        container.read(settingsProvider).settings.badgeDuration,
        const Duration(seconds: 5),
      );
    });

    test(
      'updateTheme persiste y sobrevive al reinicio del contenedor',
      () async {
        final repository = FakeSettingsRepository();
        final container = ProviderContainer(
          overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        container
            .read(settingsProvider.notifier)
            .updateTheme(ThemePreference.dark);
        // El guardado es asíncrono: esperar a que termine.
        await pumpEventQueue();

        // Reinicio: contenedor nuevo leyendo el mismo almacenamiento.
        final restartedContainer = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(
              repository.simulateRestart(),
            ),
          ],
        );
        addTearDown(restartedContainer.dispose);
        await restartedContainer.read(settingsProvider.notifier).hydrate();

        expect(
          restartedContainer.read(settingsProvider).settings.themePreference,
          ThemePreference.dark,
        );
      },
    );

    test('updateBadgeDuration persiste y sobrevive al reinicio', () async {
      final repository = FakeSettingsRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container
          .read(settingsProvider.notifier)
          .updateBadgeDuration(const Duration(seconds: 10));
      await pumpEventQueue();

      final restartedContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            repository.simulateRestart(),
          ),
        ],
      );
      addTearDown(restartedContainer.dispose);
      await restartedContainer.read(settingsProvider.notifier).hydrate();

      expect(
        restartedContainer.read(settingsProvider).settings.badgeDuration,
        const Duration(seconds: 10),
      );
    });

    test(
      'un fallo de almacenamiento no revierte el estado en memoria',
      () async {
        final repository = _FailingSettingsRepository();
        final container = ProviderContainer(
          overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        container
            .read(settingsProvider.notifier)
            .updateTheme(ThemePreference.light);
        await pumpEventQueue();

        expect(
          container.read(settingsProvider).settings.themePreference,
          ThemePreference.light,
        );
      },
    );
  });
}

class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings?> load() async => null;

  @override
  Future<bool> save(AppSettings settings) async {
    throw Exception('storage unavailable');
  }
}
