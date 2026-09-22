/// Duraciones soportadas para la caducidad de los badges de estado.
///
/// Definir el catálogo cerrado en el dominio evita representar estados de
/// preferencia inválidos (por ejemplo, 0 o segundos negativos).
enum BadgeDurationOption {
  one(1),
  two(2),
  three(3),
  five(5),
  ten(10);

  BadgeDurationOption(this.seconds);

  final int seconds;

  Duration toDuration() => Duration(seconds: seconds);

  static BadgeDurationOption? tryFromSeconds(int? seconds) {
    for (final option in BadgeDurationOption.values) {
      if (option.seconds == seconds) {
        return option;
      }
    }
    return null;
  }
}

/// Preferencia del tema visual de la aplicación.
enum ThemePreference { system, light, dark }

/// Entidad de configuración y preferencias de usuario.
class AppSettings {
  const AppSettings({
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
