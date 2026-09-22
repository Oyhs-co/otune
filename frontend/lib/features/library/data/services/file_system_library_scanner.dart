import 'dart:io';

import 'package:drift/drift.dart';
import 'package:media_metadata/media_metadata.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';
import 'package:path/path.dart' as p;

class FileSystemLibraryScanner implements LibraryScanner {
  new(this._db);
  final AppDatabase _db;

  static const _supportedExtensions = {
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
  Stream<ScanEvent> scanDirectory(String path) async* {
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
        processed++;
        yield ScanProgress(
          currentFile: p.basename(file.path),
          filesProcessed: processed,
          totalFilesFound: total,
        );

        try {
          final metadata = await MediaMetadata.read(file.path);

          final track = LibraryTrack(
            id: file.path, // Path as unique ID for MVP
            title:
                _metadataText(metadata?.title) ??
                p.basenameWithoutExtension(file.path),
            path: file.path,
            artist: _metadataText(metadata?.artist),
            album: _metadataText(metadata?.album),
            albumArtist: _metadataText(metadata?.albumArtist),
            trackNumber: metadata?.trackNumber,
            duration: metadata?.duration,
            fileFormat: p.extension(file.path),
            albumArt: metadata?.imageMetadata?.data,
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
