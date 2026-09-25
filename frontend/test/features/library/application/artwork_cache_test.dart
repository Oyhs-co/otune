import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/library/application/artwork_cache.dart';

void main() {
  Uint8List bytes(int seed) => Uint8List.fromList([seed]);

  test('stores and retrieves artwork bytes', () {
    final cache = ArtworkCache()..put('a', bytes(1));

    expect(cache.get('a'), bytes(1));
  });

  test('caches null results for tracks without artwork', () {
    final cache = ArtworkCache()..put('empty', null);

    expect(cache.contains('empty'), isTrue);
    expect(cache.get('empty'), isNull);
  });

  test('evicts least-recently-used entry beyond capacity', () {
    final cache = ArtworkCache(maxEntries: 2)
      ..put('a', bytes(1))
      ..put('b', bytes(2))
      // Tocar 'a' lo renueva: 'b' pasa a ser el menos usado.
      ..get('a')
      ..put('c', bytes(3));

    expect(cache.contains('b'), isFalse, reason: 'LRU desaloja a b');
    expect(cache.contains('a'), isTrue);
    expect(cache.contains('c'), isTrue);
  });

  test('invalidation removes the entry and clear empties the cache', () {
    final cache = ArtworkCache(maxEntries: 4)
      ..put('a', bytes(1))
      ..put('b', bytes(2))
      ..invalidate('a');
    expect(cache.contains('a'), isFalse);

    cache
      ..clear()
      ..put('x', bytes(3));
    expect(cache.contains('b'), isFalse);
    expect(cache.contains('x'), isTrue);
  });
}
