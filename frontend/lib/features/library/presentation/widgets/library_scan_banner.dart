import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';

class LibraryScanBanner extends ConsumerWidget {
  const LibraryScanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(libraryScanProvider);

    if (!scanState.isScanning &&
        scanState.status == 'No se ha realizado ningún escaneo') {
      return const SizedBox.shrink();
    }

    final isError = scanState.status.startsWith('Error:');
    final isComplete = scanState.status.startsWith('Escaneo completado');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? Theme.of(context).colorScheme.errorContainer
            : isComplete
            ? Colors.green.shade100
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
          if (isError)
            TextButton(
              onPressed: scanState.isScanning
                  ? null
                  : ref.read(libraryScanProvider.notifier).retryLastScan,
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
