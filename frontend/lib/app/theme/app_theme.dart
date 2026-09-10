import 'package:flutter/material.dart';

/// Configuración de temas visuales para Otune (Material 3).
abstract final class AppTheme {
  static const _defaultSeedColor = Color(0xFF6750A4);

  /// Construye el tema claro admitiendo paleta dinámica de la plataforma.
  static ThemeData light([ColorScheme? dynamicColorScheme]) {
    final colorScheme =
        dynamicColorScheme ??
        ColorScheme.fromSeed(seedColor: _defaultSeedColor);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );
  }

  /// Construye el tema oscuro admitiendo paleta dinámica de la plataforma.
  static ThemeData dark([ColorScheme? dynamicColorScheme]) {
    final colorScheme =
        dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: _defaultSeedColor,
          brightness: Brightness.dark,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );
  }
}
