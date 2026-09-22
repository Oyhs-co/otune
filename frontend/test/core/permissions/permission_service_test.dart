import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otune/core/permissions/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('otune/permissions');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns the native permission result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => true);

    expect(await PermissionService().requestMediaPermissions(), isTrue);
  });

  test('returns false when native plugin is unavailable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw MissingPluginException();
        });

    expect(await PermissionService().requestMediaPermissions(), isFalse);
  });

  test('returns false when native permission call fails', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'denied');
        });

    expect(await PermissionService().requestMediaPermissions(), isFalse);
  });
}
