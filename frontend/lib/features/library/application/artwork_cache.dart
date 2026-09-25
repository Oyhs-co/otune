import 'dart:typed_data';

/// Caché LRU limitada por número de entradas (SPEC artwork-management,
/// DR-002): evita recargar de la base de datos el artwork de las filas
/// visibles durante el scroll sin crecer sin cota.
class ArtworkCache {
  ArtworkCache({this.maxEntries = 200});

  final int maxEntries;
  final _entries = <String, Uint8List?>{};
  final _lru = <String>[];

  /// Indica si la clave tiene una entrada en caché (aunque sea `null`,
  /// es decir, una pista sin artwork resuelta previamente).
  bool contains(String trackId) => _entries.containsKey(trackId);

  /// Devuelve los bytes en caché o `null` si no están (hito o ausencia).
  /// Actualiza la posición LRU de la clave consultada.
  Uint8List? get(String trackId) {
    final value = _entries[trackId];
    if (value == null) return null;
    _touch(trackId);
    return value;
  }

  /// Reserva un hueco según [maxEntries] (desalojando el menos usado).
  void _evictIfNeeded() {
    while (_entries.length >= maxEntries && _lru.isNotEmpty) {
      final oldest = _lru.removeAt(0);
      _entries.remove(oldest);
    }
  }

  void put(String trackId, Uint8List? bytes) {
    _evictIfNeeded();
    _entries[trackId] = bytes;
    _touch(trackId);
  }

  void invalidate(String trackId) {
    _entries.remove(trackId);
    _lru.remove(trackId);
  }

  void clear() {
    _entries.clear();
    _lru.clear();
  }

  void _touch(String trackId) {
    _lru
      ..remove(trackId)
      ..add(trackId);
  }
}
