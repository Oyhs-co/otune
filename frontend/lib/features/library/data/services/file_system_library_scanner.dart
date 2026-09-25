import 'dart:io';

import 'package:drift/drift.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/data/services/metadata_reader.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';
import 'package:path/path.dart' as p;

/// Adaptador de escaneo sobre el filesystem local.
///
/// Sprint 4 (SPEC scan-robustness): cancelación cooperativa, normalización
/// de rutas (FR-SCANR-004) y descarte de imágenes que exceden el límite de
/// artwork (FR-AW-006 de artwork-management).
class FileSystemLibraryScanner implements LibraryScanner {
  FileSystemLibraryScanner(this._db, {MediaMetadataReader? metadataReader})
    : _metadataReader = metadataReader ?? defaultMetadataReader;

  final AppDatabase _db;

  /// Lector de metadatos inyectable: el plugin nativo no existe en tests
  /// unitarios, así que las pruebas lo sustituyen por un falso.
  final MediaMetadataReader _metadataReader;

  /// Límite de tamaño de imagen embebida que se persiste como artwork.
  /// Imágenes mayores se descartan y la pista se indexa sin carátula.
  static const int maxArtworkBytes = 2 * 1024 * 1024;

  static const Set<String> _supportedExtensions = {
    '.aac',
    '.flac',
    '.m4a',
    '.mkv',
    '.mp3',
    '.mp4',
    '.mov',
    '.ogg',
    '.opus',
    '.wav',
    '.webm',
    '.wma',
  };

  @override
  Stream<ScanEvent> scanDirectory(
    String path, {
    ScanCancellationToken? cancellationToken,
  }) async* {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      yield ScanError(message: 'Directory does not exist', path: path);
      return;
    }

    try {
      final allFiles = await _findAllMediaFiles(directory);
      var processed = 0;
      final total = allFiles.length;

      for (final file in allFiles) {
        // Frontera de cancelación: antes de procesar el siguiente archivo.
        if (cancellationToken?.isCancelled ?? false) {
          yield ScanCancelled(processed);
          return;
        }

        processed++;
        yield ScanProgress(
          currentFile: p.basename(file.path),
          filesProcessed: processed,
          totalFilesFound: total,
        );

        try {
          final metadata = await _metadataReader(file.path);

          final track = LibraryTrack(
            id: file.path, // Path as unique ID for MVP
            title:
                _metadataText(metadata?.title) ??
                p.basenameWithoutExtension(file.path),
            path: p.normalize(file.path),
            artist: _metadataText(metadata?.artist),
            album: _metadataText(metadata?.album),
            albumArtist: _metadataText(metadata?.albumArtist),
            trackNumber: metadata?.trackNumber,
            duration: metadata?.duration,
            fileFormat: p.extension(file.path),
            albumArt: _boundedArtwork(metadata?.imageMetadata?.data),
          );

          // Persist in database
          await _db.upsertTrack(
            TracksCompanion.insert(
              id: track.id,
              title: track.title,
              path: track.path,
              artist: Value(track.artist),
              album: Value(track.album),
              albumArtist: Value(track.albumArtist),
              trackNumber: Value(track.trackNumber),
              durationMs: Value(track.duration?.inMilliseconds),
              fileFormat: Value(track.fileFormat),
              albumArt: Value(track.albumArt),
            ),
          );

          yield ScanTrackFound(track);
        } on Object catch (e) {
          yield ScanError(
            message: 'Failed to read metadata: $e',
            path: file.path,
            kind: ScanErrorKind.file,
          );
        }
      }

      yield ScanComplete(total);
    } on Object catch (e) {
      yield ScanError(message: 'Critical scan error: $e', path: path);
    }
  }

  /// Devuelve los bytes de la imagen si están dentro del límite; `null` en
  /// otro caso (descarte silencioso, la pista se indexa igualmente).
  Uint8List? _boundedArtwork(Uint8List? data) {
    if (data == null || data.length > maxArtworkBytes) {
      return null;
    }
    return data;
  }

  String? _metadataText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<List<File>> _findAllMediaFiles(Directory dir) async {
    final files = <File>[];
    final entities = await dir.list(recursive: true).toList();

    for (final entity in entities) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (_supportedExtensions.contains(ext)) {
          files.add(entity);
        }
      }
    }
    return files;
  }
}
