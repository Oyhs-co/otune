import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_metadata/media_metadata.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/data/services/file_system_library_scanner.dart';
import 'package:otune/features/library/data/services/metadata_reader.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';
import 'package:path/path.dart' as p;

/// Metadatos falsos deterministas: el plugin nativo no existe en tests.
Future<Metadata?> fakeMetadataReader(String path) async {
  if (path.endsWith('corrupt.mp3')) {
    throw Exception('not an audio file');
  }
  return Metadata(
    title: 'Fake title',
    artist: 'Fake artist',
    album: 'Fake album',
    trackNumber: 3,
    duration: const Duration(seconds: 42),
    imageMetadata: ImageMetadata(data: Uint8List.fromList(List.filled(16, 1))),
  );
}

/// Metadatos con una imagen mayor que el límite de artwork.
Future<Metadata?> oversizedArtworkReader(String path) async {
  return Metadata(
    title: 'Huge art',
    imageMetadata: ImageMetadata(
      data: Uint8List.fromList(
        List.filled(FileSystemLibraryScanner.maxArtworkBytes + 1, 1),
      ),
    ),
  );
}

void main() {
  late AppDatabase database;
  late Directory directory;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    directory = Directory.systemTemp.createTempSync('otune-scan-test-');
  });

  tearDown(() async {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
    await database.close();
  });

  FileSystemLibraryScanner scannerWith(MediaMetadataReader reader) {
    return FileSystemLibraryScanner(database, metadataReader: reader);
  }

  File writeMediaFile(String name) {
    final file = File('${directory.path}${Platform.pathSeparator}$name')
      ..writeAsBytesSync([0, 1, 2, 3]);
    return file;
  }

  test('reports an error for a missing directory', () async {
    final events = await scannerWith(fakeMetadataReader)
        .scanDirectory('${directory.path}-missing')
        .toList();

    expect(events, hasLength(1));
    expect(events.single, isA<ScanError>());
    expect((events.single as ScanError).message, 'Directory does not exist');
  });

  test('completes an empty directory with zero indexed tracks', () async {
    final events = await scannerWith(fakeMetadataReader)
        .scanDirectory(directory.path)
        .toList();

    expect(events, hasLength(1));
    expect(events.single, isA<ScanComplete>());
    expect((events.single as ScanComplete).totalTracksIndexed, 0);
  });

  test(
    'AC-SCANR-001: cancel emits ScanCancelled and stops processing',
    () async {
      for (var i = 0; i < 5; i++) {
        writeMediaFile('song-$i.mp3');
      }

      final token = ScanCancellationToken();
      final events = <ScanEvent>[];

      await for (final event in scannerWith(
        fakeMetadataReader,
      ).scanDirectory(directory.path, cancellationToken: token)) {
        events.add(event);
        if (event is ScanProgress && event.filesProcessed == 2) {
          // Cancelar tras procesar el segundo archivo: el tercero no debe
          // procesarse (FR-SCANR-001).
          token.cancel();
        }
      }

      expect(events.last, isA<ScanCancelled>());
      expect(
        events.any((event) => event is ScanComplete),
        isFalse,
        reason: 'un escaneo cancelado no emite ScanComplete (DR-001)',
      );

      final cancelled = events.last as ScanCancelled;
      expect(cancelled.filesProcessed, 2);
    },
  );

  test('AC-SCANR-003: indexed paths are normalized', () async {
    final nested = Directory('${directory.path}${Platform.pathSeparator}sub')
      ..createSync();
    File('${nested.path}${Platform.pathSeparator}song.mp3')
        .writeAsBytesSync([0, 1, 2, 3]);

    final events = await scannerWith(fakeMetadataReader)
        .scanDirectory('${directory.path}${Platform.pathSeparator}.')
        .toList();

    final found = events.whereType<ScanTrackFound>().toList();
    expect(found, hasLength(1));
    expect(
      found.single.track.path,
      p.normalize(found.single.track.path),
      reason: 'la ruta persistida debe estar normalizada (FR-SCANR-004)',
    );
    expect(
      found.single.track.path.contains('${Platform.pathSeparator}.'),
      isFalse,
    );
  });

  test('AC-AW-005: artwork exceeding the size limit is discarded', () async {
    writeMediaFile('huge.mp3');

    final events = await scannerWith(oversizedArtworkReader)
        .scanDirectory(directory.path)
        .toList();

    final found = events.whereType<ScanTrackFound>().single;
    expect(
      found.track.albumArt,
      isNull,
      reason: 'la imagen sobre el límite se descarta (FR-AW-006)',
    );
    expect(found.track.title, 'Huge art');
  });

  test('indexes a valid file and persists track metadata', () async {
    final file = writeMediaFile('song.mp3');

    final events = await scannerWith(fakeMetadataReader)
        .scanDirectory(directory.path)
        .toList();

    final found = events.whereType<ScanTrackFound>().toList();
    expect(found, hasLength(1));
    expect(found.single.track.title, 'Fake title');
    expect(found.single.track.artist, 'Fake artist');
    expect(events.last, isA<ScanComplete>());

    final stored = await database.getTrackById(file.path);
    expect(stored, isNotNull);
    expect(stored!.title, 'Fake title');
    expect(
      stored.addedAt,
      isNotNull,
      reason: 'la migración v4 añade added_at con valor por defecto',
    );
  });

  test('upsert on rescan does not duplicate tracks', () async {
    writeMediaFile('song.mp3');

    final scanner = scannerWith(fakeMetadataReader);
    await scanner.scanDirectory(directory.path).toList();
    await scanner.scanDirectory(directory.path).toList();

    final allTracks = await database.getAllTracks();
    expect(allTracks, hasLength(1));
  });

  test('corrupt files are skipped and counted as file errors', () async {
    writeMediaFile('broken.corrupt.mp3');

    final events = await scannerWith(fakeMetadataReader)
        .scanDirectory(directory.path)
        .toList();

    final errors = events.whereType<ScanError>().toList();
    expect(errors, hasLength(1));
    expect(errors.single.kind, ScanErrorKind.file);
    expect(events.last, isA<ScanComplete>());
  });
}
