import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/logging/app_logger.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';

/// Estado del proceso de escaneo de la biblioteca.
class LibraryScanState {
  const LibraryScanState({
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

/// Estado de la limpieza de huérfanos (SPEC scan-robustness, FR-SCANR-006).
class MissingTracksState {
  const MissingTracksState({this.removed = const <LibraryTrack>[]});

  /// Pistas eliminadas en la última limpieza, conservadas para poder
  /// restaurarlas (acción de deshacer).
  final List<LibraryTrack> removed;

  bool get isEmpty => removed.isEmpty;
}

/// Estado combinado del escaneo para el provider principal.
class LibraryScanControllerState {
  const LibraryScanControllerState({
    this.scan = const LibraryScanState(),
    this.missingTracks = const MissingTracksState(),
  });

  final LibraryScanState scan;
  final MissingTracksState missingTracks;

  LibraryScanControllerState copyWith({
    LibraryScanState? scan,
    MissingTracksState? missingTracks,
  }) {
    return LibraryScanControllerState(
      scan: scan ?? this.scan,
      missingTracks: missingTracks ?? this.missingTracks,
    );
  }
}

/// Mensaje mostrado cuando el estado inicial aún no registró ningún escaneo.
const defaultScanStatus = 'No se ha realizado ningún escaneo';

/// Notificador para gestionar el estado del escaneo de la biblioteca.
///
/// Sprint 4 (SPEC scan-robustness): exclusión mutua de escaneos (FR-SCANR-003),
/// cancelación cooperativa (FR-SCANR-001/002) y limpieza de huérfanos con
/// deshacer (DR-004).
class LibraryScanNotifier extends Notifier<LibraryScanControllerState> {
  ScanCancellationToken? _activeToken;

  @override
  LibraryScanControllerState build() {
    return const LibraryScanControllerState();
  }

  LibraryScanState get _scanState => state.scan;

  set _scanState(LibraryScanState value) {
    state = state.copyWith(scan: value);
  }

  Future<void> scanDirectory(String path) async {
    // Guard de escaneo simultáneo (FR-SCANR-003): una segunda petición
    // mientras hay un escaneo activo se ignora sin alterar el estado.
    if (_scanState.isScanning) {
      appLogger.w('Escaneo ignorado: ya hay un escaneo en curso');
      return;
    }

    final scanner = ref.read(libraryScannerProvider);
    final token = ScanCancellationToken();
    _activeToken = token;

    _scanState = LibraryScanState(
      isScanning: true,
      status: 'Escaneando...',
      lastScanPath: path,
    );

    try {
      await for (final event in scanner.scanDirectory(
        path,
        cancellationToken: token,
      )) {
        switch (event) {
          case ScanProgress():
            _scanState = _scanState.copyWith(
              status: 'Procesando: ${event.currentFile}',
              filesProcessed: event.filesProcessed,
              totalFilesFound: event.totalFilesFound,
            );
          case ScanTrackFound():
            // Los datos se leen del repositorio; el evento confirma el hito.
            break;
          case ScanCancelled():
            _scanState = _scanState.copyWith(
              isScanning: false,
              status:
                  'Escaneo cancelado. ${event.filesProcessed} '
                  'archivos procesados.',
            );
            return;
          case ScanComplete():
            final skippedFiles = _scanState.filesWithErrors > 0
                ? ' y ${_scanState.filesWithErrors} archivos omitidos'
                : '';
            _scanState = _scanState.copyWith(
              isScanning: false,
              status:
                  'Escaneo completado. ${event.totalTracksIndexed} '
                  'pistas indexadas$skippedFiles.',
            );
            await _invalidateArtworkCache();
            // El proveedor de listas reacciona al finalizar el escaneo
            // (FR-AW-004 de artwork-management).
            ref.read(libraryLibraryVersionProvider.notifier).bump();
          case ScanError():
            if (event.kind == ScanErrorKind.file) {
              _scanState = _scanState.copyWith(
                status: 'Archivo omitido: ${event.path}',
                filesWithErrors: _scanState.filesWithErrors + 1,
              );
            } else {
              _scanState = _scanState.copyWith(
                isScanning: false,
                status: 'Error: ${event.message}',
              );
            }
        }
      }
    } finally {
      _activeToken = null;
    }
  }

  /// Solicita la cancelación del escaneo activo (cooperativa: el escáner
  /// la atiende en la siguiente frontera de archivo).
  void cancelScan() {
    if (!_scanState.isScanning) return;
    _activeToken?.cancel();
  }

  Future<void> retryLastScan() async {
    final path = _scanState.lastScanPath;
    if (path != null && !_scanState.isScanning) {
      await scanDirectory(path);
    }
  }

  /// Detecta pistas cuyo archivo ya no existe y las elimina en una
  /// transacción, conservándolas para la acción de deshacer (DR-004).
  Future<int> removeMissingTracks({List<String>? candidateIds}) async {
    final repository = ref.read(libraryRepositoryProvider);
    final missingIds = await repository.findMissingTracks(
      candidateIds: candidateIds,
    );
    if (missingIds.isEmpty) return 0;

    final removed = <LibraryTrack>[];
    for (final id in missingIds) {
      final track = await repository.getTrackById(id);
      if (track != null) {
        removed.add(track);
      }
    }
    if (removed.isEmpty) return 0;

    await repository.deleteTracks(removed.map((t) => t.id).toList());
    state = state.copyWith(missingTracks: MissingTracksState(removed: removed));

    await _invalidateArtworkCache();
    ref.read(libraryLibraryVersionProvider.notifier).bump();
    return removed.length;
  }

  /// Restaura las pistas eliminadas por la última limpieza (deshacer).
  Future<void> undoRemoveMissingTracks() async {
    final removed = state.missingTracks.removed;
    if (removed.isEmpty) return;

    await ref.read(libraryRepositoryProvider).restoreTracks(removed);
    state = state.copyWith(missingTracks: const MissingTracksState());

    await _invalidateArtworkCache();
    ref.read(libraryLibraryVersionProvider.notifier).bump();
  }

  Future<void> _invalidateArtworkCache() async {
    ref.read(artworkCacheProvider).clear();
  }
}

/// Proveedor del estado del escaneo.
final libraryScanProvider =
    NotifierProvider<LibraryScanNotifier, LibraryScanControllerState>(() {
      return LibraryScanNotifier();
    });

/// Contador de versiones de la biblioteca: se incrementa al completar un
/// escaneo o modificar el catálogo (limpieza/deshacer) para que las listas
/// reactivas se refresquen (FR-AW-004).
final libraryLibraryVersionProvider =
    NotifierProvider<_LibraryVersionNotifier, int>(_LibraryVersionNotifier.new);

class _LibraryVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}
