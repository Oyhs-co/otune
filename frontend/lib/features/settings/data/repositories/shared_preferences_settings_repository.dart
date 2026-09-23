import 'dart:async';
import 'dart:convert';

import 'package:otune/features/settings/domain/entities/app_settings.dart';
import 'package:otune/features/settings/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave única bajo la que se serializan las preferencias.
const settingsStorageKey = 'otune.settings.v1';

/// Adaptador de persistencia de preferencias sobre `shared_preferences`.
///
/// Serializa [AppSettings] como JSON para mantener el esquema de almacenamiento
/// en un único lugar y tolerar valores corruptos sin romper el arranque.
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._prefsFuture);

  final Future<SharedPreferences> _prefsFuture;

  @override
  Future<AppSettings?> load() async {
    final prefs = await _prefsFuture;
    final data = prefs.getString(settingsStorageKey);
    if (data == null) return null;

    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return null;
      return _fromMap(decoded);
    } on FormatException {
      // JSON corrupto: se descarta y se arranca con valores por defecto.
      return null;
    }
  }

  @override
  Future<bool> save(AppSettings settings) async {
    final map = <String, Object?>{
      'themePreference': settings.themePreference.name,
      'badgeDurationSeconds': settings.badgeDuration.inSeconds,
    };
    final prefs = await _prefsFuture;
    final saved = await prefs.setString(settingsStorageKey, jsonEncode(map));
    return saved;
  }

  /// Reconstruye [AppSettings] ignorando valores desconocidos o inválidos:
  /// el catálogo cerrado del dominio ([BadgeDurationOption.tryFromSeconds]) ya
  /// normaliza duraciones fuera de soporte a `null`.
  AppSettings _fromMap(Map<String, dynamic> map) {
    final themeName = map['themePreference'];
    final seconds = map['badgeDurationSeconds'];

    ThemePreference? theme;
    for (final preference in ThemePreference.values) {
      if (preference.name == themeName) {
        theme = preference;
        break;
      }
    }

    final duration = BadgeDurationOption.tryFromSeconds(
      seconds is int ? seconds : null,
    );

    return AppSettings(
      themePreference: theme ?? ThemePreference.system,
      badgeDuration: duration?.toDuration() ?? const Duration(seconds: 3),
    );
  }
}
