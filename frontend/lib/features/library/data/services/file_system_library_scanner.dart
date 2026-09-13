import 'dart:async';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/drift.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';
import 'package:path/path.dart' as p;

class FileSystemLibraryScanner implements LibraryScanner {
  new(this._db);
  final AppDatabase _db;

  static const _supportedExtensions = {'.mp3', '.flac', '.wav', '.m4a'};

  @override
  Stream<ScanEvent> scanDirectory(String path) async* {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      yield ScanError(message: 'Directory does not exist', path: path);
      return;
    }

    try {
      final allFiles = await _findAllAudioFiles(directory);
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
          final metadata = readMetadata(file);

          final track = LibraryTrack(
            id: file.path, // Path as unique ID for MVP
            title: metadata.title ?? p.basenameWithoutExtension(file.path),
            path: file.path,
            artist: metadata.artist,
            album: metadata.album,
            albumArtist: metadata.albumArtist,
            trackNumber: metadata.trackNumber,
            duration: metadata.duration,
            fileFormat: p.extension(file.path),
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
            ),
          );

          yield ScanTrackFound(track);
        } on Object catch (e) {
          yield ScanError(
            message: 'Failed to read metadata: $e',
            path: file.path,
          );
        }
      }

      yield ScanComplete(total);
    } on Object catch (e) {
      yield ScanError(message: 'Critical scan error: $e', path: path);
    }
  }

  Future<List<File>> _findAllAudioFiles(Directory dir) async {
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
