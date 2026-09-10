/// Preferencia del tema visual de la aplicación.
enum ThemePreference { system, light, dark }

/// Entidad de configuración y preferencias de usuario.
class AppSettings {
  const new({this.themePreference = ThemePreference.system});

  final ThemePreference themePreference;

  AppSettings copyWith({ThemePreference? themePreference}) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
    );
  }
}
