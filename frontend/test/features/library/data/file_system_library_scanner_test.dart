import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/data/services/file_system_library_scanner.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';

class MockAppDatabase extends Mock implements AppDatabase;

void main() {
  late MockAppDatabase database;
  late Directory directory;

  setUp(() {
    database = MockAppDatabase();
    directory = Directory.systemTemp.createTempSync('otune-scan-test-');
  });

  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('reports an error for a missing directory', () async {
    final events = await FileSystemLibraryScanner(database)
        .scanDirectory('${directory.path}-missing')
        .toList();

    expect(events, hasLength(1));
    expect(events.single, isA<ScanError>());
    expect((events.single as ScanError).message, 'Directory does not exist');
  });

  test('completes an empty directory with zero indexed tracks', () async {
    final events = await FileSystemLibraryScanner(database)
        .scanDirectory(directory.path)
        .toList();

    expect(events, hasLength(1));
    expect(events.single, isA<ScanComplete>());
    expect((events.single as ScanComplete).totalTracksIndexed, 0);
  });
}
