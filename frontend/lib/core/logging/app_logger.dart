import 'package:logger/logger.dart';

/// Instancia centralizada de logging para Otune.
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 5,
    lineLength: 80,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
