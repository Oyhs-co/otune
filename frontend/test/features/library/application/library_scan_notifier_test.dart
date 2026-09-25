import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/repositories/library_repository.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';

class FakeLibraryScanner implements LibraryScanner {
  FakeLibraryScanner(this.events);
  final List<ScanEvent> events;

  @override
  Stream<ScanEvent> scanDirectory(
    String path, {
    ScanCancellationToken? cancellationToken,
  }) async* {
    yield* Stream.fromIterable(events);
  }
}

/// Escáner que nunca termina: se usa para probar el guard de escaneos
/// simultáneos. Expone el token recibido para poder cancelarlo.
class NeverEndingFakeScanner implements LibraryScanner {
  final completer = Completer<void>();
  ScanCancellationToken? lastToken;

  @override
  Stream<ScanEvent> scanDirectory(
    String path, {
    ScanCancellationToken? cancellationToken,
  }) async* {
    lastToken = cancellationToken;
    // El estado pasa a isScanning y la petición se queda suspendida hasta
    // que el test cancele o cierre.
    await completer.future;
    yield ScanCancelled(0);
  }
}

class FakeLibraryRepository implements LibraryRepository {
  FakeLibraryRepository({List<LibraryTrack>? initialTracks})
    : tracks = [...?initialTracks];

  final List<LibraryTrack> tracks;

  @override
  Future<List<LibraryTrack>> getAllTracks({LibrarySort? sort}) async => tracks;

  @override
  Future<List<LibraryTrack>> searchTracks(
    String query, {
    LibrarySort? sort,
  }) async => tracks;

  @override
  Future<void> upsertTrack(LibraryTrack track) async => tracks.add(track);

  @override
  Future<void> deleteTrack(String id) async =>
      tracks.removeWhere((track) => track.id == id);

  @override
  Future<LibraryTrack?> getTrackById(String id) async {
    for (final track in tracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  @override
  Future<Uint8List?> getTrackArtwork(String id) async => null;

  @override
  Future<List<String>> findMissingTracks({List<String>? candidateIds}) async {
    final candidates = candidateIds ?? tracks.map((t) => t.id).toList();
    return candidates.where((id) => id.endsWith('.missing')).toList();
  }

  @override
  Future<void> deleteTracks(List<String> ids) async =>
      tracks.removeWhere((track) => ids.contains(track.id));

  @override
  Future<void> restoreTracks(List<LibraryTrack> restored) async =>
      tracks.addAll(restored);
}

ProviderContainer _container({
  required LibraryScanner scanner,
  required FakeLibraryRepository repository,
}) {
  return ProviderContainer(
    overrides: [
      libraryScannerProvider.overrideWithValue(scanner),
      libraryRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

void main() {
  test('tracks progress and completion state', () async {
    final repository = FakeLibraryRepository();
    final container = _container(
      repository: repository,
      scanner: FakeLibraryScanner([
        ScanProgress(
          currentFile: 'song.mp3',
          filesProcessed: 1,
          totalFilesFound: 2,
        ),
        ScanError(
          message: 'Corrupt file',
          path: '/music/broken.mp3',
          kind: ScanErrorKind.file,
        ),
        ScanComplete(2),
      ]),
    );
    addTearDown(container.dispose);

    await container.read(libraryScanProvider.notifier).scanDirectory('/music');

    final state = container.read(libraryScanProvider).scan;
    expect(state.isScanning, isFalse);
    expect(
      state.status,
      'Escaneo completado. 2 pistas indexadas y 1 archivos omitidos.',
    );
    expect(state.filesProcessed, 1);
    expect(state.totalFilesFound, 2);
    expect(state.filesWithErrors, 1);
  });

  test('exposes scan errors and stops scanning', () async {
    final repository = FakeLibraryRepository();
    final container = _container(
      repository: repository,
      scanner: FakeLibraryScanner([
        ScanError(message: 'Directory does not exist', path: '/missing'),
      ]),
    );
    addTearDown(container.dispose);

    await container
        .read(libraryScanProvider.notifier)
        .scanDirectory('/missing');

    final state = container.read(libraryScanProvider).scan;
    expect(state.isScanning, isFalse);
    expect(state.status, 'Error: Directory does not exist');
  });

  test('scan state copyWith preserves values not supplied', () {
    const state = LibraryScanState(
      isScanning: true,
      status: 'Working',
      filesProcessed: 1,
      totalFilesFound: 3,
    );

    expect(state.copyWith(status: 'Done').isScanning, isTrue);
    expect(state.copyWith(status: 'Done').filesProcessed, 1);
  });

  test('file errors do not stop the scan', () async {
    final repository = FakeLibraryRepository();
    final container = _container(
      repository: repository,
      scanner: FakeLibraryScanner([
        ScanProgress(
          currentFile: 'song.mp3',
          filesProcessed: 1,
          totalFilesFound: 2,
        ),
        ScanError(
          message: 'Corrupt file',
          path: '/music/broken.mp3',
          kind: ScanErrorKind.file,
        ),
        ScanComplete(1),
      ]),
    );
    addTearDown(container.dispose);

    await container.read(libraryScanProvider.notifier).scanDirectory('/music');

    final state = container.read(libraryScanProvider).scan;
    expect(state.isScanning, isFalse);
    expect(state.filesWithErrors, 1);
    expect(state.status, contains('archivos omitidos'));
  });

  test('critical errors expose the last path for retry', () async {
    final repository = FakeLibraryRepository();
    final container = _container(
      repository: repository,
      scanner: FakeLibraryScanner([
        ScanError(message: 'Directory does not exist', path: '/missing'),
      ]),
    );
    addTearDown(container.dispose);

    await container
        .read(libraryScanProvider.notifier)
        .scanDirectory('/missing');
    expect(container.read(libraryScanProvider).scan.lastScanPath, '/missing');

    await container.read(libraryScanProvider.notifier).retryLastScan();
    expect(container.read(libraryScanProvider).scan.status, contains('Error:'));
  });

  test('AC-SCANR-002: concurrent scan requests are ignored', () async {
    final repository = FakeLibraryRepository();
    final scanner = NeverEndingFakeScanner();
    final container = _container(repository: repository, scanner: scanner);
    addTearDown(container.dispose);

    final firstScan = container
        .read(libraryScanProvider.notifier)
        .scanDirectory('/music-a');

    // Esperar a que el primer escaneo pase a estado activo.
    await Future<void>.delayed(Duration.zero);
    expect(container.read(libraryScanProvider).scan.isScanning, isTrue);

    // Segunda petición mientras la primera sigue activa: se ignora.
    await container
        .read(libraryScanProvider.notifier)
        .scanDirectory('/music-b');

    expect(
      container.read(libraryScanProvider).scan.lastScanPath,
      '/music-a',
      reason: 'el estado no se reinicia con la segunda petición',
    );

    // Liberar el escáner y cancelar para cerrar limpio.
    container.read(libraryScanProvider.notifier).cancelScan();
    scanner.completer.complete();
    await firstScan;

    expect(container.read(libraryScanProvider).scan.isScanning, isFalse);
  });

  test('AC-SCANR-002: cancel through the notifier stops the scan', () async {
    final repository = FakeLibraryRepository();
    final scanner = NeverEndingFakeScanner();
    final container = _container(repository: repository, scanner: scanner);
    addTearDown(container.dispose);

    final running = container
        .read(libraryScanProvider.notifier)
        .scanDirectory('/music');

    await Future<void>.delayed(Duration.zero);
    container.read(libraryScanProvider.notifier).cancelScan();
    scanner.completer.complete();
    await running;

    final state = container.read(libraryScanProvider).scan;
    expect(state.isScanning, isFalse);
    expect(state.status, startsWith('Escaneo cancelado'));
    expect(scanner.lastToken?.isCancelled ?? false, isTrue);
  });

  test(
    'AC-SCANR-004: missing tracks are removed and can be restored',
    () async {
      final repository = FakeLibraryRepository(
        initialTracks: [
          const LibraryTrack(id: 'a.mp3', title: 'A', path: '/a.mp3'),
          const LibraryTrack(id: 'b.mp3.missing', title: 'B', path: '/b.mp3'),
        ],
      );
      final container = _container(
        repository: repository,
        scanner: FakeLibraryScanner(const []),
      );
      addTearDown(container.dispose);

      final removed = await container
          .read(libraryScanProvider.notifier)
          .removeMissingTracks();

      expect(removed, 1);
      expect(repository.tracks.map((t) => t.id), [
        'a.mp3',
      ], reason: 'sólo la pista ausente se elimina (DR-004)');

      // Deshacer restaura el registro completo.
      await container
          .read(libraryScanProvider.notifier)
          .undoRemoveMissingTracks();
      expect(
        repository.tracks.map((t) => t.id),
        containsAll(['a.mp3', 'b.mp3.missing']),
      );
      expect(container.read(libraryScanProvider).missingTracks.isEmpty, isTrue);
    },
  );
}
