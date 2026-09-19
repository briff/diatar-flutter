import 'dart:async';
import 'package:diatar_common/diatar_common.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_client_factory.dart';
import 'package:typed_data/typed_buffers.dart';

typedef SenderErrorCallback =
    void Function(String code, Map<String, String> params);

class MqttSenderService {
  MqttSenderService({required this.onStatusChanged, required this.onError});

  ValueChanged<bool> onStatusChanged;
  SenderErrorCallback onError;

  static const String _host = 'mqtt.diatar.eu';
  static const String _webHost = 'wss://mqttws.diatar.eu';
  static const int _port = 1883;
  static const int _webPort = 443;

  MqttClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _sub;
  String _topicGroup = '';
  String _topicState = '';
  String _topicBlank = '';
  String _topicDia = '';
  final Set<String> _publishedTopics = <String>{};

  Uint8List? _cachedState;
  Uint8List? _cachedText;
  Uint8List? _cachedBlank;

  bool get running => _client != null;

  Future<void> open({
    required String username,
    required String password,
    required String channel,
  }) async {
    final String user = username.trim();
    final String pass = password;
    final String ch = channel.trim().isEmpty ? '1' : channel.trim();

    // Ha másik felhasználó/csatorna: előbb töröljük a régi topic-csoport
    // retained üzeneteit, amíg a régi kapcsolat még él.
    if (_topicGroup.isNotEmpty && 'Diatar/$user/$ch/' != _topicGroup) {
      await clearRetainedMessages();
    }

    // Azonos topic-csoport újranyitásakor a cache-t újra kell küldeni, ezért
    // a kapcsolatot retained törlés nélkül zárjuk le.
    await close(clearRetained: false);

    if (user.isEmpty) {
      onStatusChanged(false);
      return;
    }

    _topicGroup = 'Diatar/$user/$ch/';
    _topicState = '${_topicGroup}state';
    _topicBlank = '${_topicGroup}blank';
    _topicDia = '${_topicGroup}dia';

    final String clientId = 'sender-${DateTime.now().millisecondsSinceEpoch}';
    final String host = kIsWeb ? _webHost : _host;
    final int port = kIsWeb ? _webPort : _port;
    final MqttClient client = createMqttClient(host, clientId);
    client.port = port;

    client
      ..logging(on: false)
      ..keepAlivePeriod = 15
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = false
      ..onDisconnected = () {
        onStatusChanged(false);
      }
      ..connectionMessage = MqttConnectMessage()
          .authenticateAs(user, pass)
          .withClientIdentifier(clientId)
          .withWillQos(MqttQos.atMostOnce);

    try {
      final MqttClientConnectionStatus? status = await client.connect();
      if (status?.state != MqttConnectionState.connected) {
        onError('senderMqttConnectFailed', const <String, String>{});
        client.disconnect();
        onStatusChanged(false);
        return;
      }

      _client = client;
      _sub = client.updates?.listen((_) {});
      onStatusChanged(true);
      await _replayCache();
    } catch (e) {
      onError('senderMqttError', <String, String>{'error': '$e'});
      try {
        client.disconnect();
      } catch (_) {}
      onStatusChanged(false);
    }
  }

  Future<void> close({bool clearRetained = true}) async {
    if (clearRetained) {
      await clearRetainedMessages();
    }
    await _sub?.cancel();
    _sub = null;
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;
    onStatusChanged(false);
  }

  Future<void> clearRetainedMessages() async {
    final MqttClient? client = _client;
    if (client == null) {
      _publishedTopics.clear();
      _cachedState = null;
      _cachedText = null;
      _cachedBlank = null;
      return;
    }

    final List<String> topics = _publishedTopics.toList(growable: false);
    if (topics.isEmpty) {
      _cachedState = null;
      _cachedText = null;
      _cachedBlank = null;
      return;
    }

    final Set<String> ackedTopics = <String>{};
    final StreamSubscription<MqttPublishMessage>? sub = client.published
        ?.listen((MqttPublishMessage msg) {
          final String? topic = msg.variableHeader?.topicName;
          if (topic != null && _publishedTopics.contains(topic)) {
            ackedTopics.add(topic);
          }
        });

    try {
      // Minden, ezen a kapcsolaton használt topic törlését szinkronban
      // elindítjuk, hogy akár azonnali leállásnál is mindegyik PUBLISH
      // elküldése megkezdődjön.
      final List<Future<void>> sends = <Future<void>>[
        for (final String topic in topics) _publishEmpty(topic),
      ];
      await Future.wait(sends);

      // Megvárjuk a QoS1 PUBACK-okat, hogy a törlő üzenetek beérjenek a
      // brokerre, mielőtt a kapcsolat bezárulna.
      final Stopwatch stopwatch = Stopwatch()..start();
      while (ackedTopics.length < topics.length &&
          stopwatch.elapsedMilliseconds < 1500) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    } finally {
      await sub?.cancel();
    }

    _cachedState = null;
    _cachedText = null;
    _cachedBlank = null;
    _publishedTopics.clear();
  }

  Future<void> sendState(
    ProjectionGlobals globals, {
    required bool showing,
    required int wordToHighlight,
  }) async {
    _cachedState = encodeStateRecord(
      globals,
      projecting: showing,
      wordToHighlight: wordToHighlight,
    );
    await _publish(_topicState, _cachedState);
  }

  Future<void> sendText({
    required String title,
    required List<String> lines,
  }) async {
    final Uint8List body = encodeTextRecord(title: title, lines: lines);
    _cachedText = Uint8List.fromList(<int>['T'.codeUnitAt(0), ...body]);
    await _publish(_topicDia, _cachedText);
  }

  Future<void> sendBlank(Uint8List bytes, {String ext = ''}) async {
    _cachedBlank = encodeImageRecord(bytes: bytes, ext: ext);
    await _publish(_topicBlank, _cachedBlank);
  }

  Future<void> sendPic(Uint8List bytes, {String ext = ''}) async {
    final Uint8List body = encodeImageRecord(bytes: bytes, ext: ext);
    await _publish(
      _topicDia,
      Uint8List.fromList(<int>['P'.codeUnitAt(0), ...body]),
    );
  }

  Future<void> _replayCache() async {
    await _publish(_topicState, _cachedState);
    await _publish(_topicDia, _cachedText);
    await _publish(_topicBlank, _cachedBlank);
  }

  Future<void> _publish(String topic, Uint8List? payload) async {
    final MqttClient? client = _client;
    if (client == null || payload == null || topic.isEmpty) {
      return;
    }
    final Uint8Buffer buffer = Uint8Buffer()..addAll(payload);
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder()
      ..addBuffer(buffer);
    try {
      client.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );
      _publishedTopics.add(topic);
    } catch (e) {
      // Átmeneti publikálási hiba (pl. reconnect közben) nem eldobható: a
      // payload már a cache-ben van, auto-reconnect után újraküldjük. A
      // hivatkozás nem tartható, de a kapcsolat-jelzőt jelezzük és az
      // hibát jelentjük a hívó réteg felé, anélkül hogy a hívást
      // összeomlasztanánk.
      onError('senderMqttError', <String, String>{'error': '$e'});
      onStatusChanged(false);
    }
  }

  Future<void> _publishEmpty(String topic) async {
    final MqttClient? client = _client;
    if (client == null || topic.isEmpty) {
      return;
    }
    try {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      client.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );
    } catch (_) {
      // A kapcsolat nem connected lehet (pl. kilépés közbeni szakadás);
      // az üres törlő üzenetet ilyenkor nem tudjuk kiküldeni, de nem
      // szabad eldobnunk a többi topic törlését sem.
    }
  }
}
