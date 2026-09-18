import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/settings/domain/entities/app_settings.dart';

/// Estado de la configuración de la aplicación.
class SettingsState {
  const new({AppSettings? settings})
    : settings = settings ?? const AppSettings();
  final AppSettings settings;

  SettingsState copyWith({AppSettings? settings}) {
    return SettingsState(settings: settings ?? this.settings);
  }
}

/// Notificador para gestionar las preferencias del usuario.
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState();
  }

  void updateTheme(ThemePreference preference) {
    state = state.copyWith(
      settings: state.settings.copyWith(themePreference: preference),
    );
  }

  void updateBadgeDuration(Duration duration) {
    state = state.copyWith(
      settings: state.settings.copyWith(badgeDuration: duration),
    );
  }
}

/// Proveedor del estado de configuración.
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
