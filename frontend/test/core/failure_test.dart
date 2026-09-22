import 'package:flutter_test/flutter_test.dart';
import 'package:otune/core/errors/failure.dart';

void main() {
  test('failure subclasses expose messages and readable descriptions', () {
    const failures = <Failure>[
      UnexpectedFailure(),
      FileFailure('file problem'),
      PlaybackFailure('playback problem'),
      ParseFailure('parse problem'),
    ];

    expect(failures[0].message, 'Ha ocurrido un error inesperado.');
    expect(failures[1].toString(), 'Failure: file problem');
    expect(failures[2].message, 'playback problem');
    expect(failures[3].message, 'parse problem');
  });
}
