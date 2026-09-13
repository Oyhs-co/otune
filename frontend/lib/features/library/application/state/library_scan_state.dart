import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';

/// Estado del proceso de escaneo de la biblioteca.
class LibraryScanState {
  final bool isScanning;
  final String status;
  final int filesProcessed;
  final int totalFilesFound;

  const LibraryScanState({
    this.isScanning = false,
    this.status = 'No se ha realizado ningún escaneo',
    this.filesProcessed = 0,
    this.totalFilesFound = 0,
  });

  LibraryScanState copyWith({
    bool? isScanning,
    String? status,
    int? filesProcessed,
    int? totalFilesFound,
  }) {
    return LibraryScanState(
      isScanning: isScanning ?? this.isScanning,
      status: status ?? this.status,
      filesProcessed: filesProcessed ?? this.filesProcessed,
      totalFilesFound: totalFilesFound ?? this.totalFilesFound,
    );
  }
}

/// Notificador para gestionar el estado del escaneo de la biblioteca.
class LibraryScanNotifier extends Notifier<LibraryScanState> {
  @override
  LibraryScanState build() {
    return const LibraryScanState();
  }

  Future<void> scanDirectory(String path) async {
    final scanner = ref.read(libraryScannerProvider);

    state = state.copyWith(
      isScanning: true,
      status: 'Escaneando...',
      filesProcessed: 0,
      totalFilesFound: 0,
    );

    await for (final event in scanner.scanDirectory(path)) {
      if (event is ScanProgress) {
        state = state.copyWith(
          status: 'Procesando: ${event.currentFile}',
          filesProcessed: event.filesProcessed,
          totalFilesFound: event.totalFilesFound,
        );
      } else if (event is ScanComplete) {
        state = state.copyWith(
          isScanning: false,
          status: 'Escaneo completado. ${event.totalTracksIndexed} pistas indexadas.',
        );
      } else if (event is ScanError) {
        state = state.copyWith(
          isScanning: false,
          status: 'Error: ${event.message}',
        );
      }
    }
  }
}

/// Proveedor del estado del escaneo.
final libraryScanProvider = NotifierProvider<LibraryScanNotifier, LibraryScanState>(() {
  return LibraryScanNotifier();
});
