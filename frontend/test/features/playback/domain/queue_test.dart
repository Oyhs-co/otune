import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';
import 'package:otune/features/playback/domain/entities/queue.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

void main() {
  group('PlaybackQueue (Domain Aggregate)', () {
    const trackA = TrackRef(id: 'a', uri: 'file:///a.mp3', title: 'Track A');
    const trackB = TrackRef(id: 'b', uri: 'file:///b.mp3', title: 'Track B');
    const trackC = TrackRef(id: 'c', uri: 'file:///c.mp3', title: 'Track C');
    const trackD = TrackRef(id: 'd', uri: 'file:///d.mp3', title: 'Track D');

    test('initial queue is empty with index -1', () {
      const queue = PlaybackQueue();
      expect(queue.isEmpty, isTrue);
      expect(queue.currentIndex, equals(-1));
      expect(queue.currentItem, isNull);
    });

    test('addTrack appends to end of queue', () {
      final queue = const PlaybackQueue().addTrack(trackA).addTrack(trackB);

      expect(queue.length, equals(2));
      expect(queue.items[0].track, equals(trackA));
      expect(queue.items[1].track, equals(trackB));
      expect(queue.currentIndex, equals(0));
    });

    test('addPlayNext inserts immediately after currentIndex', () {
      var queue = const PlaybackQueue()
          .addTrack(trackA)
          .addTrack(trackB)
          .addTrack(trackC);

      // Current index es 0 (trackA). Añadimos trackD como play next.
      queue = queue.addPlayNext(trackD);

      expect(queue.length, equals(4));
      expect(queue.items[0].track, equals(trackA));
      expect(queue.items[1].track, equals(trackD)); // Inserción en índice 1
      expect(queue.items[2].track, equals(trackB));
      expect(queue.items[3].track, equals(trackC));
      expect(queue.currentIndex, equals(0));
    });

    test('removeItem removes track and adjusts currentIndex properly', () {
      var queue = const PlaybackQueue()
          .addTrack(trackA)
          .addTrack(trackB)
          .addTrack(trackC);

      final itemBId = queue.items[1].id;
      queue = queue.moveTo(2); // Reproduciendo trackC (índice 2)

      // Eliminamos item B (índice 1, anterior a C)
      queue = queue.removeItem(itemBId);

      expect(queue.length, equals(2));
      expect(queue.items[1].track, equals(trackC));
      expect(queue.currentIndex, equals(1)); // Se decrementó de 2 a 1
    });

    test('clear resets queue to empty state', () {
      final queue = const PlaybackQueue()
          .addTrack(trackA)
          .addTrack(trackB)
          .clear();

      expect(queue.isEmpty, isTrue);
      expect(queue.currentIndex, equals(-1));
    });

    group('Sequential Navigation', () {
      late PlaybackQueue queue;

      setUp(() {
        queue = const PlaybackQueue()
            .addTrack(trackA)
            .addTrack(trackB)
            .addTrack(trackC);
      });

      test('getNextIndex with RepeatMode.off returns next or null at end', () {
        expect(queue.getNextIndex(), equals(1));

        queue = queue.moveTo(1);
        expect(queue.getNextIndex(), equals(2));

        queue = queue.moveTo(2); // Fin de la cola
        expect(queue.getNextIndex(), isNull);
      });

      test('getNextIndex with RepeatMode.all loops back to index 0', () {
        queue = queue.copyWith(repeatMode: RepeatMode.all).moveTo(2);
        expect(queue.getNextIndex(), equals(0));
      });

      test('getNextIndex with RepeatMode.one returns same index', () {
        queue = queue.copyWith(repeatMode: RepeatMode.one).moveTo(1);
        expect(queue.getNextIndex(), equals(1));
      });

      test('getPreviousIndex moves backward or loops with repeat all', () {
        queue = queue.moveTo(2);
        expect(queue.getPreviousIndex(), equals(1));

        queue = queue.moveTo(0);
        expect(
          queue.getPreviousIndex(),
          equals(0),
        ); // Sin repeat all se queda en 0

        queue = queue.copyWith(repeatMode: RepeatMode.all);
        expect(
          queue.getPreviousIndex(),
          equals(2),
        ); // Con repeat all va al último
      });
    });

    group('Shuffle Behavior', () {
      test(
        'toggleShuffle preserves current item as first in shuffle cycle',
        () {
          var queue = const PlaybackQueue()
              .addTrack(trackA)
              .addTrack(trackB)
              .addTrack(trackC)
              .addTrack(trackD)
              .moveTo(2); // trackC es el actual

          queue = queue.toggleShuffle();

          expect(queue.isShuffle, isTrue);
          expect(queue.shuffleIndices.length, equals(4));
          expect(
            queue.shuffleIndices.first,
            equals(2),
          ); // trackC permanece primero
          expect(queue.shuffleIndices.toSet(), equals({0, 1, 2, 3}));
        },
      );

      test('getNextIndex in shuffle follows shuffleIndices', () {
        final queue = const PlaybackQueue()
            .addTrack(trackA)
            .addTrack(trackB)
            .addTrack(trackC)
            .toggleShuffle();

        final firstIdx = queue.shuffleIndices[0];
        final secondIdx = queue.shuffleIndices[1];

        expect(queue.currentIndex, equals(firstIdx));
        expect(queue.getNextIndex(), equals(secondIdx));
      });

      test('disabling shuffle returns to original sequential order', () {
        var queue = const PlaybackQueue()
            .addTrack(trackA)
            .addTrack(trackB)
            .addTrack(trackC)
            .moveTo(1)
            .toggleShuffle(); // Activa shuffle

        queue = queue.toggleShuffle(); // Desactiva shuffle

        expect(queue.isShuffle, isFalse);
        expect(queue.currentIndex, equals(1));
        expect(queue.getNextIndex(), equals(2)); // Secuencia original
      });
    });
  });
}
