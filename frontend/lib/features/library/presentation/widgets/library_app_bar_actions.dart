import 'package:flutter/material.dart';
import 'package:otune/features/library/domain/entities/library_sort_option.dart';
import 'package:otune/features/library/domain/entities/library_view_mode.dart';
import 'package:otune/features/library/presentation/widgets/library_sort_menu.dart';

/// Acciones de la barra de biblioteca: orden, vista y escaneo/cancelación.
class LibraryAppBarActions extends StatelessWidget {
  const LibraryAppBarActions({
    required this.isScanning,
    required this.onViewModeChanged,
    required this.onScanFolder,
    required this.sortOption,
    required this.onSortChanged,
    required this.onCancelScan,
    super.key,
  });

  final bool isScanning;
  final ValueChanged<LibraryViewMode> onViewModeChanged;
  final VoidCallback onScanFolder;
  final LibrarySortOption sortOption;
  final ValueChanged<LibrarySortOption> onSortChanged;
  final VoidCallback onCancelScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LibrarySortMenu(sortOption: sortOption, onSortChanged: onSortChanged),
        PopupMenuButton<LibraryViewMode>(
          icon: const Icon(Icons.view_module),
          onSelected: onViewModeChanged,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: LibraryViewMode.list,
              child: Text('Lista'),
            ),
            const PopupMenuItem(
              value: LibraryViewMode.grid,
              child: Text('Carátulas'),
            ),
            const PopupMenuItem(
              value: LibraryViewMode.detailed,
              child: Text('Detallado'),
            ),
          ],
        ),
        IconButton(
          icon: isScanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.folder_open),
          onPressed: isScanning ? null : onScanFolder,
          tooltip: 'Escanear carpeta',
        ),
      ],
    );
  }
}

/// Botón de cancelación del escaneo (FR-SCANR-001). Vive fuera de
/// [LibraryAppBarActions] porque se muestra en el banner de progreso.
class ScanCancelButton extends StatelessWidget {
  const ScanCancelButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Cancelar'));
  }
}
