import 'package:flutter/material.dart';

/// Configuración de temas visuales para Otune (Material 3).
abstract final class AppTheme {
  static const _defaultSeedColor = Color(0xFF6750A4);

  /// Construye el tema claro con un color semilla dinámico de la plataforma.
  static ThemeData light([Color? seedColor]) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? _defaultSeedColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );
  }

  /// Construye el tema oscuro con un color semilla dinámico de la plataforma.
  static ThemeData dark([Color? seedColor]) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? _defaultSeedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );
  }
}
