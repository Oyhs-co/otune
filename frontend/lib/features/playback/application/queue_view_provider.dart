import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/domain/entities/queue_view_mode.dart';

/// Notificador para gestionar el modo de visualización de la cola.
class QueueViewNotifier extends Notifier<QueueViewMode> {
  @override
  QueueViewMode build() => QueueViewMode.list;

  QueueViewMode get mode => state;

  set mode(QueueViewMode mode) {
    state = mode;
  }
}

/// Proveedor del estado de visualización de la cola.
final queueViewModeProvider =
    NotifierProvider<QueueViewNotifier, QueueViewMode>(() {
      return QueueViewNotifier();
    });
