import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';
import 'package:otune/features/library/domain/entities/library_sort_option.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/repositories/library_repository.dart';
import 'package:otune/features/settings/application/settings_notifier.dart';

/// Duración del debounce de búsqueda (NFR-SEARCH-002 de search-library).
const librarySearchDebounce = Duration(milliseconds: 300);

/// Notificador de la consulta de búsqueda tal como la escribe el usuario.
///
/// El estado crudo alimenta la UI del campo (icono de limpiar); la lista
/// reacciona a la versión con debounce ([libraryDebouncedQueryProvider]).
class LibrarySearchNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    return '';
  }

  String get query => state;

  /// Actualiza la consulta y reprograma el debounce.
  ///
  /// Una consulta vacía (limpiar búsqueda) se aplica de inmediato para que
  /// la biblioteca completa reaparezca sin espera perceptible.
  void updateQuery(String query) {
    state = query;
    _debounce?.cancel();
    if (query.isEmpty) {
      ref.read(libraryDebouncedQueryProvider.notifier).commit('');
      return;
    }
    _debounce = Timer(librarySearchDebounce, () {
      ref.read(libraryDebouncedQueryProvider.notifier).commit(query);
    });
  }
}

/// Proveedor del estado de la consulta de búsqueda (cruda).
final librarySearchQueryProvider =
    NotifierProvider<LibrarySearchNotifier, String>(() {
      return LibrarySearchNotifier();
    });

/// Consulta diferida (debounce 300 ms): la lista sólo consulta la base de
/// datos una vez el usuario deja de escribir (FR-SEARCH-005).
///
/// El estado lo publica [LibrarySearchNotifier.updateQuery] al vencer el
/// temporizador.
final libraryDebouncedQueryProvider =
    NotifierProvider<_DebouncedQueryNotifier, String>(
      _DebouncedQueryNotifier.new,
    );

class _DebouncedQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  /// Publica la consulta diferida (usado por [LibrarySearchNotifier]).
  // ignore: use_setters_to_change_properties, se documenta como commit.
  void commit(String query) => state = query;
}

/// Proveedor que devuelve las pistas filtradas por la consulta con debounce,
/// con el criterio de orden activo (SPEC library-sorting, DR-001) y refresco
/// reactivo al finalizar un escaneo o limpiar el catálogo (FR-AW-004).
final filteredTracksProvider = FutureProvider<List<LibraryTrack>>((ref) {
  final query = ref.watch(libraryDebouncedQueryProvider);
  final sort = ref.watch(librarySortProvider);
  ref.watch(libraryLibraryVersionProvider);
  final repository = ref.watch(libraryRepositoryProvider);

  if (query.isEmpty) {
    return repository.getAllTracks(sort: sort);
  }
  return repository.searchTracks(query, sort: sort);
});

/// Criterio de orden activo de la biblioteca.
final librarySortProvider = Provider<LibrarySort>((ref) {
  return (option: ref.watch(librarySortOptionProvider), descending: false);
});

/// Opción de orden seleccionada, persistida vía el repositorio de
/// preferencias (FR-SORT-005): el estado vive en settings y sobrevive al
/// reinicio.
final librarySortOptionProvider =
    NotifierProvider<LibrarySortNotifier, LibrarySortOption>(
      LibrarySortNotifier.new,
    );

class LibrarySortNotifier extends Notifier<LibrarySortOption> {
  @override
  LibrarySortOption build() {
    return ref.watch(settingsProvider).settings.librarySortOption;
  }

  void setOption(LibrarySortOption option) {
    ref.read(settingsProvider.notifier).updateLibrarySort(option);
  }
}
