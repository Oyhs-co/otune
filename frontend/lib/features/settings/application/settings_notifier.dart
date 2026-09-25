import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/logging/app_logger.dart';
import 'package:otune/features/library/domain/entities/library_sort_option.dart';
import 'package:otune/features/settings/data/repositories/shared_preferences_settings_repository.dart';
import 'package:otune/features/settings/domain/entities/app_settings.dart';
import 'package:otune/features/settings/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado de la configuración de la aplicación.
class SettingsState {
  const SettingsState({AppSettings? settings})
    : settings = settings ?? const AppSettings();
  final AppSettings settings;

  SettingsState copyWith({AppSettings? settings}) {
    return SettingsState(settings: settings ?? this.settings);
  }
}

/// Notificador para gestionar las preferencias del usuario.
///
/// Cada cambio se persiste inmediatamente en el [SettingsRepository]. Un fallo
/// de almacenamiento se registra en el log pero no revierte el estado en
/// memoria: la preferencia sigue activa durante la sesión actual.
class SettingsNotifier extends Notifier<SettingsState> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  SettingsState build() {
    return const SettingsState();
  }

  /// Hidrata el estado desde el almacenamiento persistente.
  ///
  /// Se invoca una vez durante el arranque (ver `bootstrapApp`). Un fallo de
  /// lectura deja los valores por defecto y se registra en el log.
  Future<void> hydrate() async {
    try {
      final stored = await _repository.load();
      if (stored != null) {
        state = SettingsState(settings: stored);
      }
    } on Object catch (e) {
      appLogger.e('No se pudieron cargar las preferencias: $e');
    }
  }

  void updateTheme(ThemePreference preference) {
    state = state.copyWith(
      settings: state.settings.copyWith(themePreference: preference),
    );
    unawaited(_persist());
  }

  /// Actualiza la duración de los badges sólo con valores del catálogo
  /// soportado. Las duraciones fuera del catálogo se ignoran para no
  /// representar estados de preferencia inválidos.
  void updateBadgeDuration(Duration duration) {
    final option = BadgeDurationOption.tryFromSeconds(duration.inSeconds);
    if (option == null) return;
    state = state.copyWith(
      settings: state.settings.copyWith(badgeDuration: option.toDuration()),
    );
    unawaited(_persist());
  }

  /// Actualiza el criterio de orden de la biblioteca (SPEC library-sorting,
  /// FR-SORT-005) y lo persiste.
  void updateLibrarySort(LibrarySortOption option) {
    state = state.copyWith(
      settings: state.settings.copyWith(librarySortOption: option),
    );
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      await _repository.save(state.settings);
    } on Object catch (e) {
      appLogger.e('No se pudieron guardar las preferencias: $e');
    }
  }
}

/// Proveedor del repositorio de preferencias (adapter SharedPreferences).
///
/// Se resuelve con la instancia real de [SharedPreferences], que debe estar
/// inicializada antes del arranque de la app (ver `bootstrapApp`). En pruebas
/// se sobrescribe con un falso o con `SharedPreferences.setMockInitialValues`.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SharedPreferencesSettingsRepository(SharedPreferences.getInstance());
});

/// Proveedor del estado de configuración.
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
