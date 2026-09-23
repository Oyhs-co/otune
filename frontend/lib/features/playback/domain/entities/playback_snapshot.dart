import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';
import 'package:otune/features/playback/domain/entities/queue.dart';
import 'package:otune/features/playback/domain/entities/queue_item.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

/// Instantánea de la sesión de reproducción apta para persistir.
///
/// Describe qué información de la sesión sobrevive al reinicio, sin conocer
/// Drift ni la plataforma. No incluye el arte embebido: al restaurar, la
/// carátula se recupera desde la biblioteca local si la pista existe.
@immutable
class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.items,
    required this.currentIndex,
    required this.isShuffle,
    required this.repeatModeIndex,
    required this.positionMs,
  });

  /// Elementos de la cola en su orden lineal.
  final List<SnapshotTrack> items;

  /// Índice activo al guardar la sesión.
  final int currentIndex;

  /// Modo aleatorio activo al guardar.
  final bool isShuffle;

  /// Índice del enum [RepeatMode] (off=0, all=1, one=2).
  final int repeatModeIndex;

  /// Posición de reproducción de la pista activa, en milisegundos.
  final int positionMs;

  bool get isEmpty => items.isEmpty;
}

/// Referencia reducida a una pista dentro del snapshot.
@immutable
class SnapshotTrack {
  const SnapshotTrack({
    required this.id,
    required this.uri,
    required this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.durationMs,
  });

  final String id;
  final String uri;
  final String title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? durationMs;
}

/// Conversión entre el agregado de cola/sesión y el snapshot persistible.
extension PlaybackSnapshotMapperX on PlaybackSnapshot {
  /// Reconstruye la cola de dominio desde el snapshot, validando el índice.
  ///
  /// Reglas (SPEC session-persistence):
  /// - índice fuera de rango -> índice 0;
  /// - snapshot vacío -> cola vacía e inactiva;
  /// - el arte embebido no se restaura: se recupera desde la biblioteca.
  PlaybackQueue toQueue({Map<String, Uint8List?> artworkById = const {}}) {
    if (isEmpty) {
      return const PlaybackQueue();
    }

    final queueItems = <QueueItem>[
      for (final track in items)
        QueueItem(
          id: track.id,
          track: TrackRef(
            id: track.id,
            uri: track.uri,
            title: track.title,
            artist: track.artist,
            album: track.album,
            albumArtist: track.albumArtist,
            duration: track.durationMs != null
                ? Duration(milliseconds: track.durationMs!)
                : null,
            albumArt: artworkById[track.id],
          ),
        ),
    ];

    final validIndex = (currentIndex >= 0 && currentIndex < queueItems.length)
        ? currentIndex
        : 0;

    // Los índices de shuffle no se persisten (dependen del orden lineal
    // actual); se regeneran al alternar el modo.
    return PlaybackQueue(
      items: List.unmodifiable(queueItems),
      currentIndex: validIndex,
      isShuffle: isShuffle,
      repeatMode: RepeatMode.values[repeatModeIndex.clamp(0, 2)],
    );
  }
}

/// Construye un snapshot desde el agregado de cola actual.
PlaybackSnapshot buildSnapshotFromQueue(
  PlaybackQueue queue, {
  required Duration position,
}) {
  return PlaybackSnapshot(
    items: [
      for (final item in queue.items)
        SnapshotTrack(
          id: item.track.id,
          uri: item.track.uri,
          title: item.track.title,
          artist: item.track.artist,
          album: item.track.album,
          albumArtist: item.track.albumArtist,
          durationMs: item.track.duration?.inMilliseconds,
        ),
    ],
    currentIndex: queue.currentIndex,
    isShuffle: queue.isShuffle,
    repeatModeIndex: queue.repeatMode.index,
    positionMs: position.inMilliseconds,
  );
}
