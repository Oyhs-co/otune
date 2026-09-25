import 'package:flutter/material.dart';
import 'package:otune/features/library/domain/entities/library_sort_option.dart';

/// Menú de selección del criterio de orden de la biblioteca
/// (SPEC library-sorting, FR-SORT-004). Reutilizado por el AppBar móvil y
/// por la barra de biblioteca en pantallas anchas.
class LibrarySortMenu extends StatelessWidget {
  const LibrarySortMenu({
    required this.sortOption,
    required this.onSortChanged,
    super.key,
  });

  final LibrarySortOption sortOption;
  final ValueChanged<LibrarySortOption> onSortChanged;

  static const Map<LibrarySortOption, String> _labels = {
    LibrarySortOption.title: 'Título',
    LibrarySortOption.artist: 'Artista',
    LibrarySortOption.album: 'Álbum',
    LibrarySortOption.addedAt: 'Añadido recientemente',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LibrarySortOption>(
      tooltip: 'Ordenar biblioteca',
      icon: const Icon(Icons.sort_by_alpha),
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        for (final option in LibrarySortOption.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Expanded(child: Text(_labels[option]!)),
                if (option == sortOption)
                  Icon(
                    Icons.check,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
