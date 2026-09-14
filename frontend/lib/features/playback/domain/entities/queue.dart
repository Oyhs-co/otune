import 'dart:math';

import 'package:meta/meta.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';
import 'package:otune/features/playback/domain/entities/queue_item.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:uuid/uuid.dart';

/// Agregado que encapsula la cola de reproducción, orden, shuffle y repetición.
@immutable
class PlaybackQueue {
  const new({
    this.items = const [],
    this.currentIndex = -1,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.off,
    this.shuffleIndices = const [],
  });

  /// Lista inmutable de elementos en la cola.
  final List<QueueItem> items;

  /// Índice actual en reproducción (-1 si la cola está vacía o inactiva).
  final int currentIndex;

  /// Indica si el modo aleatorio está activo.
  final bool isShuffle;

  /// Modo de repetición actual (off, all, one).
  final RepeatMode repeatMode;

  /// Secuencia de índices barajados para el ciclo de reproducción aleatorio.
  final List<int> shuffleIndices;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  /// Elemento actualmente activo en la cola.
  QueueItem? get currentItem =>
      (currentIndex >= 0 && currentIndex < items.length)
      ? items[currentIndex]
      : null;

  /// Pista actualmente activa en la cola.
  TrackRef? get currentTrack => currentItem?.track;

  /// Determina si existe una pista siguiente reproducible.
  bool get hasNext {
    if (isEmpty) return false;
    if (repeatMode == RepeatMode.one || repeatMode == RepeatMode.all) {
      return true;
    }
    if (isShuffle) {
      final currentPos = shuffleIndices.indexOf(currentIndex);
      return currentPos != -1 && currentPos + 1 < shuffleIndices.length;
    }
    return currentIndex + 1 < items.length;
  }

  /// Determina si existe una pista anterior reproducible.
  bool get hasPrevious {
    if (isEmpty) return false;
    if (repeatMode == RepeatMode.all) return true;
    if (isShuffle) {
      final currentPos = shuffleIndices.indexOf(currentIndex);
      return currentPos > 0;
    }
    return currentIndex > 0;
  }

  /// Calcula el próximo índice de la cola según el modo actual.
  int? getNextIndex() {
    if (isEmpty) return null;
    if (repeatMode == RepeatMode.one) {
      return currentIndex;
    }
    if (isShuffle) {
      final currentPos = shuffleIndices.indexOf(currentIndex);
      if (currentPos != -1 && currentPos + 1 < shuffleIndices.length) {
        return shuffleIndices[currentPos + 1];
      }
      if (repeatMode == RepeatMode.all && shuffleIndices.isNotEmpty) {
        return shuffleIndices.first;
      }
      return null;
    }
    if (currentIndex + 1 < items.length) {
      return currentIndex + 1;
    }
    if (repeatMode == RepeatMode.all) {
      return 0;
    }
    return null;
  }

  /// Calcula el índice anterior de la cola según el modo actual.
  int? getPreviousIndex() {
    if (isEmpty) return null;
    if (isShuffle) {
      final currentPos = shuffleIndices.indexOf(currentIndex);
      if (currentPos > 0) {
        return shuffleIndices[currentPos - 1];
      }
      if (repeatMode == RepeatMode.all && shuffleIndices.isNotEmpty) {
        return shuffleIndices.last;
      }
      return currentIndex >= 0 ? currentIndex : null;
    }
    if (currentIndex > 0) {
      return currentIndex - 1;
    }
    if (repeatMode == RepeatMode.all && items.isNotEmpty) {
      return items.length - 1;
    }
    return currentIndex >= 0 ? currentIndex : null;
  }

  /// Añade una pista al final de la cola.
  PlaybackQueue addTrack(TrackRef track) {
    final newItem = QueueItem(id: const Uuid().v4(), track: track);
    final newItems = List<QueueItem>.unmodifiable([...items, newItem]);
    final newCurrentIndex = currentIndex == -1 ? 0 : currentIndex;
    final newShuffle = isShuffle
        ? _recalculateShuffle(newItems.length, newCurrentIndex)
        : const <int>[];

    return copyWith(
      items: newItems,
      currentIndex: newCurrentIndex,
      shuffleIndices: newShuffle,
    );
  }

  /// Inserta una pista justo después de la pista actual ("Play Next").
  PlaybackQueue addPlayNext(TrackRef track) {
    final newItem = QueueItem(id: const Uuid().v4(), track: track);
    final newItems = List<QueueItem>.from(items);
    final insertPos = currentIndex == -1 ? 0 : currentIndex + 1;
    newItems.insert(insertPos, newItem);
    final newCurrentIndex = currentIndex == -1 ? 0 : currentIndex;
    final newShuffle = isShuffle
        ? _recalculateShuffle(newItems.length, newCurrentIndex)
        : const <int>[];

    return copyWith(
      items: List.unmodifiable(newItems),
      currentIndex: newCurrentIndex,
      shuffleIndices: newShuffle,
    );
  }

  /// Elimina un elemento de la cola por su identificador único.
  PlaybackQueue removeItem(String id) {
    final removeIndex = items.indexWhere((item) => item.id == id);
    if (removeIndex == -1) return this;

    final newItems = List<QueueItem>.from(items)..removeAt(removeIndex);
    if (newItems.isEmpty) {
      return copyWith(
        items: const [],
        currentIndex: -1,
        shuffleIndices: const [],
      );
    }

    var newCurrentIndex = currentIndex;
    if (removeIndex < currentIndex) {
      newCurrentIndex--;
    } else if (removeIndex == currentIndex) {
      if (newCurrentIndex >= newItems.length) {
        newCurrentIndex = newItems.length - 1;
      }
    }
    final newShuffle = isShuffle
        ? _recalculateShuffle(newItems.length, newCurrentIndex)
        : const <int>[];

    return copyWith(
      items: List.unmodifiable(newItems),
      currentIndex: newCurrentIndex,
      shuffleIndices: newShuffle,
    );
  }

  /// Vacía la cola y restablece el índice.
  PlaybackQueue clear() {
    return copyWith(
      items: const [],
      currentIndex: -1,
      shuffleIndices: const [],
    );
  }

  /// Mueve un elemento de la cola de una posición a otra.
  PlaybackQueue moveItem(int from, int to) {
    if (from < 0 || from >= items.length || to < 0 || to >= items.length) {
      return this;
    }
    if (from == to) return this;

    final newItems = List<QueueItem>.from(items);
    final item = newItems.removeAt(from);
    newItems.insert(to, item);

    var newCurrentIndex = currentIndex;
    if (from < currentIndex && to >= currentIndex) {
      newCurrentIndex--;
    } else if (from >= currentIndex && to < currentIndex) {
      newCurrentIndex++;
    } else if (from == currentIndex) {
      newCurrentIndex = to;
    }

    final newShuffle = isShuffle
        ? _recalculateShuffle(newItems.length, newCurrentIndex)
        : const <int>[];

    return copyWith(
      items: List.unmodifiable(newItems),
      currentIndex: newCurrentIndex,
      shuffleIndices: newShuffle,
    );
  }

  /// Alterna el modo aleatorio manteniendo la pista actual en reproducción.
  PlaybackQueue toggleShuffle([Random? random]) {
    final newIsShuffle = !isShuffle;
    var newShuffle = const <int>[];
    if (newIsShuffle && items.isNotEmpty) {
      newShuffle = _generateShuffleList(items.length, currentIndex, random);
    }
    return copyWith(isShuffle: newIsShuffle, shuffleIndices: newShuffle);
  }

  /// Cicla el modo de repetición (Off -> All -> One -> Off).
  PlaybackQueue cycleRepeat() {
    return copyWith(repeatMode: repeatMode.next());
  }

  /// Cambia directamente el índice activo de reproducción.
  PlaybackQueue moveTo(int index) {
    if (index < 0 || index >= items.length) return this;
    return copyWith(currentIndex: index);
  }

  static List<int> _generateShuffleList(
    int length,
    int currentIdx, [
    Random? random,
  ]) {
    final rnd = random ?? Random();
    final remaining = <int>[
      for (var i = 0; i < length; i++)
        if (i != currentIdx) i,
    ]..shuffle(rnd);

    if (currentIdx >= 0 && currentIdx < length) {
      return [currentIdx, ...remaining];
    }
    return remaining;
  }

  List<int> _recalculateShuffle(int newLength, int currentIdx) {
    return _generateShuffleList(newLength, currentIdx);
  }

  PlaybackQueue copyWith({
    List<QueueItem>? items,
    int? currentIndex,
    bool? isShuffle,
    RepeatMode? repeatMode,
    List<int>? shuffleIndices,
  }) {
    return PlaybackQueue(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleIndices: shuffleIndices ?? this.shuffleIndices,
    );
  }
}
