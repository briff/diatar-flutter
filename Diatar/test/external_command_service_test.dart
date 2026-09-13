import 'package:diatar_app/src/services/external_command_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('diatar.eu/external_command');

  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'runs Android external commands through the native intent channel',
    () async {
      MethodCall? receivedCall;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            receivedCall = call;
            return null;
          });

      await const ExternalCommandService().run(
        'intent:#Intent;action=com.example.ACTION;S.name=value;end',
      );

      expect(receivedCall?.method, 'run');
      expect(receivedCall?.arguments, <String, String>{
        'command': 'intent:#Intent;action=com.example.ACTION;S.name=value;end',
      });
    },
  );

  test('supports iOS external URL actions', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(const ExternalCommandService().isSupported, isTrue);
  });
}
