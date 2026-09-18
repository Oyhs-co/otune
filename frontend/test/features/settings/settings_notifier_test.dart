import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/settings/application/settings_notifier.dart';
import 'package:otune/features/settings/domain/entities/app_settings.dart';

void main() {
  test('starts with system theme and updates the preference', () {
    final container = ProviderContainer();
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
}
