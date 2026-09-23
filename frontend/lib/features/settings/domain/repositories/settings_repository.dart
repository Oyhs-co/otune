import 'package:otune/features/settings/domain/entities/app_settings.dart';

/// Capacidad requerida por el caso de uso de configuración: persistir y
/// recuperar las preferencias del usuario entre sesiones.
abstract interface class SettingsRepository {
  /// Lee las preferencias guardadas; devuelve `null` si no existen.
  Future<AppSettings?> load();

  /// Guarda las preferencias. Devuelve el resultado de la escritura.
  Future<bool> save(AppSettings settings);
}
