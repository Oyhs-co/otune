import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';

class FakeLibraryScanner implements LibraryScanner {
  FakeLibraryScanner(this.events);
  final List<ScanEvent> events;

  @override
  Stream<ScanEvent> scanDirectory(String path) async* {
    yield* Stream.fromIterable(events);
  }
}

void main() {
  test('tracks progress and completion state', () async {
    final container = ProviderContainer(
      overrides: [
        libraryScannerProvider.overrideWithValue(
          FakeLibraryScanner([
            ScanProgress(
              currentFile: 'song.mp3',
              filesProcessed: 1,
              totalFilesFound: 2,
            ),
            ScanComplete(2),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(libraryScanProvider.notifier).scanDirectory('/music');

    final state = container.read(libraryScanProvider);
    expect(state.isScanning, isFalse);
    expect(state.status, 'Escaneo completado. 2 pistas indexadas.');
    expect(state.filesProcessed, 1);
    expect(state.totalFilesFound, 2);
  });

  test('exposes scan errors and stops scanning', () async {
    final container = ProviderContainer(
      overrides: [
        libraryScannerProvider.overrideWithValue(
          FakeLibraryScanner([
            ScanError(message: 'Directory does not exist', path: '/missing'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(libraryScanProvider.notifier)
        .scanDirectory('/missing');

    final state = container.read(libraryScanProvider);
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
}
