import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/domain/entities/track.dart';

/// Notificador para gestionar la consulta de búsqueda en la biblioteca.
class LibrarySearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  String get query => state;

  set query(String query) {
    state = query;
  }
}

/// Proveedor del estado de la consulta de búsqueda.
final librarySearchQueryProvider =
    NotifierProvider<LibrarySearchNotifier, String>(() {
      return LibrarySearchNotifier();
    });

/// Proveedor que devuelve las pistas filtradas por la consulta de búsqueda.
final filteredTracksProvider = FutureProvider<List<LibraryTrack>>((ref) {
  final query = ref.watch(librarySearchQueryProvider);
  final repository = ref.watch(libraryRepositoryProvider);

  if (query.isEmpty) {
    return repository.getAllTracks();
  }
  return repository.searchTracks(query);
});
