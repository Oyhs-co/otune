import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:otune/app/app.dart';
import 'package:otune/app/bootstrap/session_restore_watcher.dart';
import 'package:otune/features/settings/application/settings_notifier.dart';

/// Contenedor de Riverpod accesible para el arranque antes del primer frame.
final ProviderContainer bootstrapContainer = ProviderContainer();

/// Arranque de la aplicación con restauración de sesión (Sprint 2).
///
/// Secuencia:
/// 1. inicializar bindings y motor multimedia;
/// 2. hidratar preferencias persistentes (tema, badges);
/// 3. observar el ciclo de vida y restaurar la última sesión de reproducción
///    sin iniciar audio automáticamente;
/// 4. ejecutar la app con el contenedor ya preparado.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await bootstrapContainer.read(settingsProvider.notifier).hydrate();

  final watcher = bootstrapContainer.read(sessionRestoreWatcherProvider);
  unawaited(watcher.start());

  runApp(
    UncontrolledProviderScope(
      container: bootstrapContainer,
      child: const OtuneApp(),
    ),
  );
}
