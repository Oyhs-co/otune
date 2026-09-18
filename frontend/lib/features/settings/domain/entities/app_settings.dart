/// Preferencia del tema visual de la aplicación.
enum ThemePreference { system, light, dark }

/// Entidad de configuración y preferencias de usuario.
class AppSettings {
  const new({
    this.themePreference = ThemePreference.system,
    this.badgeDuration = const Duration(seconds: 3),
  });

  final ThemePreference themePreference;
  final Duration badgeDuration;

  AppSettings copyWith({
    ThemePreference? themePreference,
    Duration? badgeDuration,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      badgeDuration: badgeDuration ?? this.badgeDuration,
    );
  }
}
