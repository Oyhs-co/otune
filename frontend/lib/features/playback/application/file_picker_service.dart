import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_metadata/media_metadata.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:uuid/uuid.dart';

/// Contrato para selección de archivos de audio desde almacenamiento local.
abstract interface class LocalAudioPicker {
  /// Abre el explorador de archivos del sistema para seleccionar una pista.
  Future<TrackRef?> pickAudioFile();
}

/// Implementación del selector de archivos de audio usando [FilePicker].
class SystemLocalAudioPicker implements LocalAudioPicker {
  const new();

  static const _supportedAudioExtensions = [
    'mp3',
    'flac',
    'wav',
    'm4a',
    'ogg',
    'aac',
    'opus',
  ];

  @override
  Future<TrackRef?> pickAudioFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _supportedAudioExtensions,
    );

    if (files.isEmpty) {
      return null;
    }

    final file = files.first;
    final path = file.path;
    if (path == null) {
      return null;
    }

    final fileName = file.name;
    final title = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    final metadata = await MediaMetadata.read(path);

    return TrackRef(
      id: const Uuid().v4(),
      uri: Uri.file(path).toString(),
      title: metadata?.title ?? title,
      artist: metadata?.artist,
      album: metadata?.album,
      albumArtist: metadata?.albumArtist,
      duration: metadata?.duration,
      albumArt: metadata?.imageMetadata?.data,
    );
  }
}

/// Proveedor de dependencias para el selector local de archivos de audio.
final localAudioPickerProvider = Provider<LocalAudioPicker>((ref) {
  return const SystemLocalAudioPicker();
});
