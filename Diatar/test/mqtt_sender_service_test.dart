import 'package:diatar_app/src/services/mqtt_sender_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MqttSenderService.close', () {
    test('clears retained MQTT messages before disconnecting', () async {
      final _TrackingMqttSender sender = _TrackingMqttSender();

      await sender.close();

      expect(sender.clearRetainedMessagesCalled, isTrue);
    });

    test(
      'can keep retained messages while reopening the same topic group',
      () async {
        final _TrackingMqttSender sender = _TrackingMqttSender();

        await sender.close(clearRetained: false);

        expect(sender.clearRetainedMessagesCalled, isFalse);
      },
    );
  });
}

class _TrackingMqttSender extends MqttSenderService {
  _TrackingMqttSender() : super(onStatusChanged: (_) {}, onError: (_, __) {});

  bool clearRetainedMessagesCalled = false;

  @override
  Future<void> clearRetainedMessages() async {
    clearRetainedMessagesCalled = true;
  }
}
