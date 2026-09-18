import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';

/// Estado del proceso de escaneo de la biblioteca.
class LibraryScanState {
  const new({
    this.isScanning = false,
    this.status = 'No se ha realizado ningún escaneo',
    this.filesProcessed = 0,
    this.totalFilesFound = 0,
    this.filesWithErrors = 0,
    this.lastScanPath,
  });
  final bool isScanning;
  final String status;
  final int filesProcessed;
  final int totalFilesFound;
  final int filesWithErrors;
  final String? lastScanPath;

  LibraryScanState copyWith({
    bool? isScanning,
    String? status,
    int? filesProcessed,
    int? totalFilesFound,
    int? filesWithErrors,
    String? lastScanPath,
  }) {
    return LibraryScanState(
      isScanning: isScanning ?? this.isScanning,
      status: status ?? this.status,
      filesProcessed: filesProcessed ?? this.filesProcessed,
      totalFilesFound: totalFilesFound ?? this.totalFilesFound,
      filesWithErrors: filesWithErrors ?? this.filesWithErrors,
      lastScanPath: lastScanPath ?? this.lastScanPath,
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
      filesWithErrors: 0,
      lastScanPath: path,
    );

    await for (final event in scanner.scanDirectory(path)) {
      if (event is ScanProgress) {
        state = state.copyWith(
          status: 'Procesando: ${event.currentFile}',
          filesProcessed: event.filesProcessed,
          totalFilesFound: event.totalFilesFound,
        );
      } else if (event is ScanComplete) {
        final skippedFiles = state.filesWithErrors > 0
            ? ' y ${state.filesWithErrors} archivos omitidos'
            : '';
        state = state.copyWith(
          isScanning: false,
          status:
              'Escaneo completado. ${event.totalTracksIndexed}'
              ' pistas indexadas$skippedFiles.',
        );
      } else if (event is ScanError) {
        if (event.kind == ScanErrorKind.file) {
          state = state.copyWith(
            status: 'Archivo omitido: ${event.path}',
            filesWithErrors: state.filesWithErrors + 1,
          );
        } else {
          state = state.copyWith(
            isScanning: false,
            status: 'Error: ${event.message}',
          );
        }
      }
    }
  }

  Future<void> retryLastScan() async {
    final path = state.lastScanPath;
    if (path != null && !state.isScanning) {
      await scanDirectory(path);
    }
  }
}

/// Proveedor del estado del escaneo.
final libraryScanProvider =
    NotifierProvider<LibraryScanNotifier, LibraryScanState>(() {
      return LibraryScanNotifier();
    });
