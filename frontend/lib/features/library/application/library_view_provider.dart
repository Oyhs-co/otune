import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/library/domain/entities/library_view_mode.dart';

/// Notificador para gestionar el modo de visualización de la biblioteca.
class LibraryViewNotifier extends Notifier<LibraryViewMode> {
  @override
  LibraryViewMode build() => LibraryViewMode.list;

  LibraryViewMode get mode => state;

  set mode(LibraryViewMode mode) {
    state = mode;
  }
}

/// Proveedor del estado de visualización de la biblioteca.
final libraryViewModeProvider =
    NotifierProvider<LibraryViewNotifier, LibraryViewMode>(() {
      return LibraryViewNotifier();
    });
