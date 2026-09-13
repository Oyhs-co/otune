/// Modos de repetición soportados por la cola de reproducción.
enum RepeatMode {
  off,
  all,
  one;

  /// Cicla al siguiente modo de repetición: Off -> All -> One -> Off.
  RepeatMode next() {
    return switch (this) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
  }
}
