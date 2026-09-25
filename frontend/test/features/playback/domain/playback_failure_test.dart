import 'package:flutter_test/flutter_test.dart';
import 'package:otune/features/playback/domain/entities/playback_failure.dart';

void main() {
  group('PlaybackFailure.categorize', () {
    test('classifies missing file errors', () {
      final failure = PlaybackFailure.categorize(
        engineMessage: 'Unable to open file: No such file or directory',
        uri: 'file:///music/gone.mp3',
      );

      expect(failure.kind, equals(PlaybackFailureKind.missingFile));
      expect(failure.message, isNotEmpty);
    });

    test('classifies permission denied errors', () {
      final failure = PlaybackFailure.categorize(
        engineMessage: 'Access is denied',
        uri: 'file:///protected/song.mp3',
      );

      expect(failure.kind, equals(PlaybackFailureKind.permissionDenied));
    });

    test('classifies corrupt or unsupported file errors', () {
      final failure = PlaybackFailure.categorize(
        engineMessage: 'No demuxer found for format',
        uri: 'file:///music/broken.mp3',
      );

      expect(failure.kind, equals(PlaybackFailureKind.corruptFile));
    });

    test('classifies empty engine messages as unknown', () {
      final failure = PlaybackFailure.categorize(
        engineMessage: null,
        uri: 'file:///music/song.mp3',
      );

      expect(failure.kind, equals(PlaybackFailureKind.unknown));
    });

    test('matching is case insensitive', () {
      final failure = PlaybackFailure.categorize(
        engineMessage: 'FILE NOT FOUND',
        uri: 'file:///music/gone.mp3',
      );

      expect(failure.kind, equals(PlaybackFailureKind.missingFile));
    });

    test('equality is value based', () {
      final a = PlaybackFailure.categorize(
        engineMessage: 'file not found',
        uri: 'file:///a.mp3',
      );
      final b = PlaybackFailure.categorize(
        engineMessage: 'file not found',
        uri: 'file:///b.mp3',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
