import 'dart:async';
import 'dart:io';

import 'package:diatar_common/diatar_common.dart';
import 'package:flutter/foundation.dart';

typedef SenderErrorCallback =
    void Function(String code, Map<String, String> params);
typedef SenderCameraCallback =
    void Function(CameraSignal signal, String sourceKey);

class TcpSenderService {
  TcpSenderService({
    required this.onStatusChanged,
    required this.onError,
    required this.onCamera,
  });

  static const int _rawSocketWriteChunkSize = 16 * 1024;

  ValueChanged<bool> onStatusChanged;
  SenderErrorCallback onError;
  SenderCameraCallback onCamera;

  final Map<String, RawSocket> _clients = <String, RawSocket>{};
  final Map<String, StreamSubscription<RawSocketEvent>> _subs =
      <String, StreamSubscription<RawSocketEvent>>{};
  final Map<RawSocket, _RawSocketWriter> _writers =
      <RawSocket, _RawSocketWriter>{};
  final Map<String, DateTime> _lastConnectError = <String, DateTime>{};
  final Set<String> _targetKeys = <String>{};
  final Map<RawSocket, ProjectionPacketParser> _parsers =
      <RawSocket, ProjectionPacketParser>{};
  bool _running = false;
  int _session = 0;
  String? _cameraTargetKey;
  final Map<String, List<CameraSignal>> _cameraPending =
      <String, List<CameraSignal>>{};
  Timer? _idleTimer;
  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _sendQueue = Future<void>.value();
  Uint8List? _cachedState;
  Uint8List? _cachedText;
  Uint8List? _cachedBlank;
  Uint8List? _cachedPic;
  Uint8List? _cachedScrSize;
  bool _lastStatus = false;

  bool get running => _running;
  bool get hasClients => _clients.isNotEmpty;
  bool get allTargetsConnected =>
      _targetKeys.isNotEmpty && _clients.length == _targetKeys.length;

  void setCameraTargetKey(String? key) {
    _cameraTargetKey = key;
  }

  Future<void> _enqueue(Future<void> Function() task) async {
    final Future<void> previous = _sendQueue;
    final Completer<void> current = Completer<void>();
    _sendQueue = current.future;
    await previous;
    try {
      await task();
    } finally {
      current.complete();
    }
  }

  Future<void> start(List<String> targets) async {
    await stop();
    final List<_TcpTarget> parsedTargets = _parseTargets(targets);
    if (parsedTargets.isEmpty) {
      _emitStatus();
      return;
    }

    _running = true;
    _session++;
    final int session = _session;
    _targetKeys
      ..clear()
      ..addAll(parsedTargets.map((target) => target.key));
    _startIdleKeepAlive();
    _emitStatus();

    for (final _TcpTarget target in parsedTargets) {
      unawaited(_runTargetLoop(target, session));
    }
  }

  Future<void> restart(List<String> targets) async {
    await start(targets);
  }

  Future<void> stop() async {
    _running = false;
    _session++;
    _targetKeys.clear();
    _lastConnectError.clear();
    _sendQueue = Future<void>.value();

    for (final StreamSubscription<RawSocketEvent> sub in _subs.values) {
      try {
        await sub.cancel();
      } catch (_) {}
    }
    _subs.clear();

    for (final RawSocket socket in _clients.values) {
      try {
        _writers.remove(socket)?.close();
        socket.close();
      } catch (_) {}
    }
    _clients.clear();
    _writers.clear();
    _parsers.clear();
    _cameraPending.clear();

    _idleTimer?.cancel();
    _idleTimer = null;
    _emitStatus(force: true);
  }

  Future<void> _runTargetLoop(_TcpTarget target, int session) async {
    while (_running &&
        session == _session &&
        _targetKeys.contains(target.key)) {
      RawSocket? socket;
      StreamSubscription<RawSocketEvent>? sub;
      try {
        socket = await _connectTarget(target.host, target.port);
        final RawSocket connectedSocket = socket;
        connectedSocket.writeEventsEnabled = false;
        final _RawSocketWriter writer = _RawSocketWriter(connectedSocket);
        _writers[connectedSocket] = writer;

        _clients[target.key] = connectedSocket;
        final ProjectionPacketParser parser = ProjectionPacketParser();
        _parsers[connectedSocket] = parser;
        _emitStatus();

        final Completer<void> done = Completer<void>();
        sub = connectedSocket.listen(
          (RawSocketEvent event) {
            switch (event) {
              case RawSocketEvent.read:
                while (true) {
                  final List<int>? chunk = connectedSocket.read();
                  if (chunk == null) {
                    break;
                  }
                  _handleIncoming(target.key, parser, chunk);
                }
                break;
              case RawSocketEvent.write:
                writer.onWriteReady();
                break;
              case RawSocketEvent.readClosed:
              case RawSocketEvent.closed:
                debugPrint('CAM tcp closed ${target.key}');
                writer.close();
                if (!done.isCompleted) {
                  done.complete();
                }
                break;
            }
          },
          onError: (Object e) {
            debugPrint('CAM tcp error ${target.key}: $e');
            writer.close();
            _reportConnectOrClientError(target, e);
            if (!done.isCompleted) {
              done.complete();
            }
          },
          onDone: () {
            writer.close();
            if (!done.isCompleted) {
              done.complete();
            }
          },
          cancelOnError: true,
        );
        _subs[target.key] = sub;
        await _enqueue(() => _replayCache(connectedSocket, target.key));
        await done.future;
      } catch (e) {
        _reportConnectOrClientError(target, e);
      } finally {
        if (sub != null) {
          try {
            await sub.cancel();
          } catch (_) {}
        }
        _subs.remove(target.key);

        final RawSocket? old = _clients.remove(target.key);
        try {
          _writers.remove(old)?.close();
          _parsers.remove(old);
          old?.close();
        } catch (_) {}
        _emitStatus();
      }

      if (_running && session == _session && _targetKeys.contains(target.key)) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  Future<RawSocket> _connectTarget(String host, int port) {
    return RawSocket.connect(host, port, timeout: const Duration(seconds: 3));
  }

  void _reportConnectOrClientError(_TcpTarget target, Object error) {
    final DateTime now = DateTime.now();
    final DateTime? last = _lastConnectError[target.key];
    if (last != null && now.difference(last) < const Duration(seconds: 15)) {
      return;
    }
    _lastConnectError[target.key] = now;
    onError('senderTcpError', <String, String>{
      'error': '${target.host}:${target.port} - $error',
    });
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
    await _enqueue(() => _sendPacket(RecTypes.state, _cachedState!));
  }

  Future<void> sendText({
    required String title,
    required List<String> lines,
    required int wordToHighlight,
  }) async {
    // A text slide replaces a previously projected full-screen image.
    _cachedPic = null;
    _cachedText = encodeTextRecord(title: title, lines: lines);
    await _enqueue(() => _sendPacket(RecTypes.text, _cachedText!));
  }

  Future<void> sendBlank(Uint8List bytes, {String ext = ''}) async {
    _cachedBlank = encodeImageRecord(bytes: bytes, ext: ext);
    await _enqueue(() => _sendPacket(RecTypes.blank, _cachedBlank!));
  }

  Future<void> sendPic(Uint8List bytes, {String ext = ''}) async {
    // An image slide replaces a previously projected text slide.
    _cachedText = null;
    _cachedPic = encodeImageRecord(bytes: bytes, ext: ext);
    await _enqueue(() => _sendPacket(RecTypes.pic, _cachedPic!));
  }

  Future<void> sendIdle() async {
    await _enqueue(() => _sendPacket(RecTypes.idle, Uint8List(0)));
  }

  Future<void> sendScreenSize({required int width, required int height}) async {
    _cachedScrSize = encodeScreenSizeRecord(
      width: width,
      height: height,
      korusMode: false,
    );
    await _enqueue(() => _sendPacket(RecTypes.scrSize, _cachedScrSize!));
  }

  Future<void> sendCameraSignal(
    CameraSignal signal, {
    String? sourceKey,
  }) async {
    debugPrint('CAM tx ${signal.kind.name}');
    await _enqueue(() async {
      final Uint8List body = encodeCameraSignal(signal);
      final String? key = sourceKey ?? _cameraTargetKey;
      RawSocket? socket = key == null ? null : _clients[key];
      if (socket == null && _clients.length == 1) {
        socket = _clients.values.first;
      }
      if (socket == null) {
        _queueCameraReply(key, signal);
        debugPrint(
          'CAM txSend camera target=$key not connected - queued',
        );
        return;
      }
      try {
        await _writeAll(
          socket,
          encodeProjectionPacket(RecTypes.camera, body),
        );
        _lastSentAt = DateTime.now();
      } catch (e) {
        onError('senderTcpSendError', <String, String>{'error': '$e'});
        _queueCameraReply(key, signal);
      }
    });
  }

  void _queueCameraReply(String? key, CameraSignal signal) {
    if (key == null) {
      return;
    }
    final List<CameraSignal> pending = _cameraPending.putIfAbsent(
      key,
      () => <CameraSignal>[],
    );
    pending.add(signal);
    if (pending.length > 64) {
      pending.removeAt(0);
    }
  }

  void _handleIncoming(String sourceKey, ProjectionPacketParser parser, List<int> chunk) {
    final List<ProjectionPacket> packets = parser.addChunk(chunk);
    for (final ProjectionPacket packet in packets) {
      if (packet.type == RecTypes.camera) {
        try {
          onCamera(decodeCameraSignal(packet.body), sourceKey);
        } catch (_) {
          // Ignore malformed camera signaling.
        }
      }
    }
  }

  Future<void> _replayCache(RawSocket socket, String key) async {
    debugPrint('CAM replay connected=${_clients.length}');
    await _sendToSocket(socket, RecTypes.scrSize, _cachedScrSize);
    await _sendToSocket(socket, RecTypes.state, _cachedState);
    await _sendToSocket(socket, RecTypes.text, _cachedText);
    await _sendToSocket(socket, RecTypes.blank, _cachedBlank);
    await _sendToSocket(socket, RecTypes.pic, _cachedPic);
    final List<CameraSignal>? pending = _cameraPending.remove(key);
    if (pending == null || pending.isEmpty) {
      return;
    }
    debugPrint('CAM replay flush camera=${pending.length}');
    for (final CameraSignal signal in pending) {
      await _sendToSocket(socket, RecTypes.camera, encodeCameraSignal(signal));
      _lastSentAt = DateTime.now();
    }
  }

  Future<void> _sendPacket(int type, Uint8List body) async {
    if (_clients.isEmpty) {
      debugPrint('CAM txSend type=$type no clients - dropped');
      return;
    }
    final Uint8List packet = encodeProjectionPacket(type, body);
    debugPrint('CAM txSend type=$type body=${body.length} clients=${_clients.length}');
    final List<String> dead = <String>[];
    for (final MapEntry<String, RawSocket> entry in _clients.entries.toList()) {
      final String key = entry.key;
      final RawSocket socket = entry.value;
      try {
        await _writeAll(socket, packet);
        _lastSentAt = DateTime.now();
      } catch (e) {
        onError('senderTcpSendError', <String, String>{'error': '$key - $e'});
        dead.add(key);
      }
    }
    for (final String key in dead) {
      final RawSocket? deadSocket = _clients.remove(key);
      try {
        _writers.remove(deadSocket)?.close();
        deadSocket?.close();
      } catch (_) {}
    }
    _emitStatus();
  }

  Future<void> _sendToSocket(
    RawSocket socket,
    int type,
    Uint8List? body,
  ) async {
    if (body == null) {
      return;
    }
    try {
      final Uint8List packet = encodeProjectionPacket(type, body);
      await _writeAll(socket, packet);
      _lastSentAt = DateTime.now();
    } catch (e) {
      onError('senderTcpSendError', <String, String>{'error': '$type - $e'});
    }
  }

  Future<void> _writeAll(RawSocket socket, Uint8List packet) async {
    final _RawSocketWriter? writer = _writers[socket];
    if (writer == null) {
      throw StateError('The TCP connection is no longer available.');
    }

    int offset = 0;
    while (offset < packet.length) {
      final int remaining = packet.length - offset;
      final int chunkLength = remaining > _rawSocketWriteChunkSize
          ? _rawSocketWriteChunkSize
          : remaining;
      final Uint8List chunk = Uint8List.fromList(
        packet.sublist(offset, offset + chunkLength),
      );
      final int written = socket.write(chunk);
      offset += written;
      if (written < chunkLength) {
        await writer.waitForWriteReady();
      }
    }
  }

  void _startIdleKeepAlive() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!running || _clients.isEmpty) {
        return;
      }
      final Duration sinceLastSend = DateTime.now().difference(_lastSentAt);
      if (sinceLastSend >= const Duration(seconds: 5)) {
        unawaited(sendIdle());
      }
    });
  }

  void _emitStatus({bool force = false}) {
    final bool connected = _clients.isNotEmpty;
    if (force || connected != _lastStatus) {
      _lastStatus = connected;
      onStatusChanged(connected);
    }
  }

  List<_TcpTarget> _parseTargets(List<String> rawTargets) {
    final List<_TcpTarget> out = <_TcpTarget>[];
    final Set<String> seen = <String>{};
    for (final String raw in rawTargets) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final int split = trimmed.lastIndexOf(':');
      if (split <= 0 || split >= trimmed.length - 1) {
        continue;
      }
      final String host = trimmed.substring(0, split).trim();
      final int? port = int.tryParse(trimmed.substring(split + 1).trim());
      if (host.isEmpty || port == null || port < 0 || port > 65535) {
        continue;
      }
      final _TcpTarget target = _TcpTarget(host: host, port: port);
      if (seen.add(target.key)) {
        out.add(target);
      }
    }
    return out;
  }
}

class _TcpTarget {
  const _TcpTarget({required this.host, required this.port});

  final String host;
  final int port;

  String get key => '$host:$port';
}

class _RawSocketWriter {
  _RawSocketWriter(this._socket);

  final RawSocket _socket;
  Completer<void>? _writeReady;
  bool _closed = false;

  Future<void> waitForWriteReady() {
    if (_closed) {
      return Future<void>.error(StateError('The TCP connection is closed.'));
    }
    final Completer<void>? pending = _writeReady;
    if (pending != null) {
      return pending.future;
    }

    final Completer<void> next = Completer<void>();
    _writeReady = next;
    _socket.writeEventsEnabled = true;
    return next.future;
  }

  void onWriteReady() {
    final Completer<void>? pending = _writeReady;
    _writeReady = null;
    pending?.complete();
  }

  void close() {
    _closed = true;
    final Completer<void>? pending = _writeReady;
    _writeReady = null;
    pending?.completeError(StateError('The TCP connection is closed.'));
  }
}
