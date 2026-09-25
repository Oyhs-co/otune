import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';
import 'package:otune/features/library/presentation/widgets/library_app_bar_actions.dart';

/// Banner de progreso del escaneo (SPEC scan-progress-feedback) con la
/// cancelación y el estado final de cancelación de la SPEC scan-robustness.
class LibraryScanBanner extends ConsumerWidget {
  const LibraryScanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(libraryScanProvider).scan;

    if (!scanState.isScanning && scanState.status == defaultScanStatus) {
      return const SizedBox.shrink();
    }

    final isError = scanState.status.startsWith('Error:');
    final isComplete = scanState.status.startsWith('Escaneo completado');
    final isCancelled = scanState.status.startsWith('Escaneo cancelado');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? Theme.of(context).colorScheme.errorContainer
            : isComplete
            ? Colors.green.shade100
            : isCancelled
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (scanState.isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (isComplete)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.check_circle, color: Colors.green, size: 18),
            )
          else if (isCancelled)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.cancel_outlined, size: 18),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.error_outline, color: Colors.red, size: 18),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scanState.status,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                if (scanState.isScanning)
                  Text(
                    'Archivos procesados: ${scanState.filesProcessed}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
          if (scanState.isScanning)
            ScanCancelButton(
              onPressed: () =>
                  ref.read(libraryScanProvider.notifier).cancelScan(),
            )
          else if (isError)
            TextButton(
              // La rama sólo se alcanza con el escaneo detenido (la rama
              // previa cubre isScanning), por lo que no hace falta guard.
              onPressed: ref.read(libraryScanProvider.notifier).retryLastScan,
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
