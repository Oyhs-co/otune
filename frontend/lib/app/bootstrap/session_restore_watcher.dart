import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/playback_persistence.dart';

/// Observa el ciclo de vida de la aplicación para persistir la sesión en los
/// momentos clave (SPEC session-persistence, FR-SESS-005):
///
/// - `paused` (app pasa a segundo plano o se minimiza): guardado inmediato.
/// - `detached` (cierre): intento final de guardado antes de morir.
class SessionRestoreWatcher with WidgetsBindingObserver {
  SessionRestoreWatcher(this._ref);

  final Ref _ref;
  bool _observing = false;

  /// Empieza a observar el ciclo de vida y restaura la última sesión
  /// persistida. Debe invocarse una sola vez durante el arranque.
  Future<void> start() async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    await _ref.read(playbackPersistenceProvider.notifier).restoreSession();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final persistence = _ref.read(playbackPersistenceProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(persistence.flush());
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Deja de observar y cancela temporizadores pendientes.
  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
  }
}

/// Proveedor del watcher de sesión; se activa en el bootstrap de la app.
final sessionRestoreWatcherProvider = Provider<SessionRestoreWatcher>((ref) {
  final watcher = SessionRestoreWatcher(ref);
  ref.onDispose(watcher.dispose);
  return watcher;
});
