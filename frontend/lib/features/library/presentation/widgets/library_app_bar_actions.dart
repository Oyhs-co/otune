import 'package:flutter/material.dart';
import 'package:otune/features/library/domain/entities/library_view_mode.dart';

class LibraryAppBarActions extends StatelessWidget {
  const LibraryAppBarActions({
    required this.isScanning,
    required this.onViewModeChanged,
    required this.onScanFolder,
    super.key,
  });

  final bool isScanning;
  final ValueChanged<LibraryViewMode> onViewModeChanged;
  final VoidCallback onScanFolder;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
