import 'package:otune/features/settings/domain/entities/app_settings.dart';
import 'package:otune/features/settings/domain/repositories/settings_repository.dart';

/// Fake en memoria del repositorio de preferencias.
///
/// Simula un almacenamiento reiniciable: `simulateRestart` devuelve un nuevo
/// fake que contiene los datos persistidos por el anterior, tal como haría el
/// almacenamiento real entre lanzamientos de la aplicación.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([AppSettings? initial]) : _stored = initial;

  AppSettings? _stored;

  @override
  Future<AppSettings?> load() async => _stored;

  @override
  Future<bool> save(AppSettings settings) {
    _stored = settings;
    return Future.value(true);
  }

  /// Crea un repositorio nuevo que arranca con lo último persistido aquí,
  /// replicando el reinicio de la aplicación.
  FakeSettingsRepository simulateRestart() => FakeSettingsRepository(_stored);
}
