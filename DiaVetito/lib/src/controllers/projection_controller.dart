import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:diatar_common/diatar_common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../services/settings_store.dart';
import '../services/tcp_server_service.dart';
import '../services/webrtc_camera_service.dart';
import '../services/web_mqtt_settings.dart';
import '../utils/browser_window_close.dart' as browser_window_close;

class ProjectionController extends ChangeNotifier {
  static const MethodChannel _systemChannel = MethodChannel(
    'com.polyjoe.diavetito/system',
  );

  ProjectionController()
    : _server = TcpServerService(
        onState: _onStateStatic,
        onText: _onTextStatic,
        onPic: _onPicStatic,
        onBlank: _onBlankStatic,
        onAskSize: _onAskSizeStatic,
        onCamera: _onCameraStatic,
        onError: _onErrorStatic,
        onConnection: _onConnectionStatic,
      ),
      _mqtt = MqttService(
        onError: _onErrorStatic,
        onState: _onStateStatic,
        onText: _onTextStatic,
        onPic: _onPicStatic,
        onBlank: _onBlankStatic,
        onUsers: _onUsersStatic,
        onConnection: _onMqttConnectionStatic,
      ) {
    _instance = this;
    _lifecycleListener = AppLifecycleListener(onResume: _onAppResumed);
  }

  static ProjectionController? _instance;
  AppLifecycleListener? _lifecycleListener;

  static Future<void> _onStateStatic(RecStateRecord record) async =>
      await _instance?._onState(record);
  static Future<void> _onTextStatic(RecTextRecord record) async =>
      _instance?._onText(record);
  static Future<void> _onPicStatic(RecImageRecord record) async =>
      await _instance?._onPic(record);
  static Future<void> _onBlankStatic(RecImageRecord record) async =>
      await _instance?._onBlank(record);
  static Future<void> _onAskSizeStatic() async => await _instance?._onAskSize();
  static Future<void> _onCameraStatic(CameraSignal signal) async  => await
      _instance?._onCameraSignal(signal);
  static void _onErrorStatic(String message) => _instance?._onError(message);
  static void _onConnectionStatic(bool connected) =>
      _instance?._onConnection(connected);
  static void _onUsersStatic(List<MqttUser> users) =>
      _instance?._onUsers(users);
  static void _onMqttConnectionStatic(bool connected) =>
      _instance?._onMqttConnection(connected);

  final SettingsStore _settingsStore = SettingsStore();
  final TcpServerService _server;
  final MqttService _mqtt;
  late final WebrtcCameraService _camera;

  bool cameraAvailable = false;

  AppSettings settings = const AppSettings();
  ProjectionGlobals globals = const ProjectionGlobals().copyWith(
    projecting: true,
  );
  ProjectionFrame? diaFrame;
  ProjectionFrame? blankFrame;
  LogoFrame? _logoFrame = const LogoFrame(0);
  List<MqttUser> mqttUsers = <MqttUser>[];
  List<String> senderSuggestions = <String>[];

  bool initialized = false;
  bool connected = false;
  bool mqttActive = false;
  bool mqttConnected = false;
  bool _hasDataForCurrentConnection = false;
  bool _startupAnimationFinished = false;
  bool _ignoreNextMqttEndProgram = false;
  String statusCode = 'statusStarting';
  Map<String, Object> statusParams = const <String, Object>{};
  Size viewportSize = const Size(1920, 1080);

  Timer? _logoTimer;
  bool _disposed = false;

  Future<void> init() async {
    if (_disposed) {
      return;
    }
    _camera = WebrtcCameraService(
      sendSignal: (CameraSignal signal) => _server.sendCameraSignal(signal),
    );
    cameraAvailable = _camera.available;
    await _camera.init();
    settings = (await _settingsStore.load()).copyWith(mqttChannel: '1');
    _camera.selectedDeviceId = settings.cameraStreamDeviceId;
    if (kIsWeb) {
      final String? mqttUser = mqttUsernameFromWebUri(Uri.base);
      if (mqttUser != null && mqttUser != settings.mqttUser) {
        settings = settings.copyWith(mqttUser: mqttUser);
        await _settingsStore.save(settings);
      }
    }
    globals = _applyReceiverDisplayFilters(globals);
    await _applyTransport();
    await refreshMqttUsers();
    _startLogo();
    initialized = true;
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> applySettings(AppSettings newSettings) async {
    if (_disposed) {
      return;
    }
    final AppSettings previousSettings = settings;
    settings = newSettings.copyWith(mqttChannel: '1');
    await _settingsStore.save(settings);
    globals = _applyReceiverDisplayFilters(globals);
    await _applyTransport();
    _syncNoConnectionLogo();
    if (!settings.cameraStreamEnabled && previousSettings.cameraStreamEnabled) {
      unawaited(_camera.stop());
    } else if (settings.cameraStreamEnabled) {
      if (settings.cameraStreamDeviceId != _camera.selectedDeviceId) {
        _camera.selectedDeviceId = settings.cameraStreamDeviceId;
        if (_camera.active) {
          unawaited(_restartCameraStream(settings.cameraStreamDeviceId));
        }
      }
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _restartCameraStream(String? deviceId) async {
    try {
      await _camera.start(deviceId: deviceId);
      await _camera.sendOffer();
    } catch (_) {
      // Camera unavailable; ignore.
    }
  }

  Future<void> refreshMqttUsers() async {
    if (_disposed) {
      return;
    }
    await _mqtt.fillUserList();
  }

  void updateSenderFilter(String mask) {
    senderSuggestions
      ..clear()
      ..addAll(_mqtt.usersLike(mask).map((MqttUser u) => u.username));
    notifyListeners();
  }

  String? registeredMqttUsername(String username) =>
      _mqtt.getUser(username)?.username;

  Future<void> setKeepStartupLogo(bool keep) async {
    if (_disposed || settings.receiverKeepStartupLogo == keep) {
      return;
    }
    settings = settings.copyWith(receiverKeepStartupLogo: keep);
    _syncNoConnectionLogo();
    await _settingsStore.save(settings);
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> connectInternetFromQrUsername(
    String username, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (_disposed) {
      return false;
    }
    final String user = username.trim();
    if (user.isEmpty) {
      return false;
    }
    await refreshMqttUsers();
    final String? registeredUser = registeredMqttUsername(user);
    if (registeredUser == null) {
      return false;
    }

    settings = settings.copyWith(mqttUser: registeredUser, mqttChannel: '1');
    await _settingsStore.save(settings);
    globals = _applyReceiverDisplayFilters(globals);
    await _applyTransport();
    if (!_disposed) {
      notifyListeners();
    }

    final DateTime deadline = DateTime.now().add(timeout);
    while (!_disposed && DateTime.now().isBefore(deadline)) {
      if (mqttConnected) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return mqttConnected;
  }

  bool get _transportConnected => mqttActive ? mqttConnected : connected;

  bool get _transportConfigured =>
      mqttActive ? settings.mqttUser.trim().isNotEmpty : settings.port > 0;

  bool get _shouldShowNoConnectionLogo =>
      settings.receiverKeepStartupLogo &&
      _transportConfigured &&
      !_transportConnected;

  void _syncNoConnectionLogo() {
    if (!_startupAnimationFinished) {
      return;
    }
    if (_shouldShowNoConnectionLogo) {
      if (_logoTimer == null) {
        _startLogo(restartStartup: false);
      }
      return;
    }
    _logoTimer?.cancel();
    _logoTimer = null;
    _logoFrame = null;
  }

  ProjectionFrame? _connectedProjectedFrame() {
    if (globals.projecting && diaFrame != null) {
      return diaFrame;
    }
    if (!_transportConnected || !_hasDataForCurrentConnection) {
      return null;
    }
    if (globals.isBlankPic && globals.showBlankPic && blankFrame != null) {
      return blankFrame;
    }
    return null;
  }

  ProjectionGlobals _applyReceiverDisplayFilters(ProjectionGlobals source) {
    final ProjectionGlobals colored = settings.receiverUseServerColors
        ? source
        : source.copyWith(
            bkColor: settings.bkColor,
            txtColor: settings.txtColor,
            blankColor: settings.blankColor,
            hiColor: settings.hiColor,
          );

    return colored.copyWith(
      wordToHighlight: settings.receiverShowHighlight
          ? colored.wordToHighlight
          : 0,
      useAkkord: settings.receiverUseAkkord && source.useAkkord,
      useKotta: settings.receiverUseKotta && source.useKotta,
      autoResize: settings.projAutoSize,
    );
  }

  Future<void> requestExit() async {
    if (_disposed) {
      return;
    }
    _setStatus('statusExitRequested');
    await _server.stop();
    await _mqtt.closeReceiver();
    if (kIsWeb) {
      await browser_window_close.tryCloseBrowserWindow();
      return;
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      try {
        final bool? closed = await _systemChannel.invokeMethod<bool>(
          'requestExit',
        );
        if (closed == true) {
          return;
        }
      } on MissingPluginException {
        // Fallback below.
      } on PlatformException {
        // Fallback below.
      }
    }
    await SystemNavigator.pop();
  }

  Future<bool> requestShutdown() async {
    if (_disposed) {
      return false;
    }
    return _requestShutdown();
  }

  void requestReboot() {
    if (_disposed) {
      return;
    }
    _setStatus('statusRebootUnsupported');
  }

  void updateViewport(Size size) {
    if (size == Size.zero) {
      return;
    }
    viewportSize = size;
  }

  Future<void> _onState(RecStateRecord record) async {
    if (_disposed) {
      return;
    }
    _hasDataForCurrentConnection = true;
    final bool ignoreEndProgram = mqttActive && _ignoreNextMqttEndProgram;
    if (ignoreEndProgram) {
      _ignoreNextMqttEndProgram = false;
    }
    globals = _applyReceiverDisplayFilters(globals.fromState(record));
    if (!globals.isBlankPic && !globals.showBlankPic) {
      blankFrame = null;
    }
    final int ep = record.endProgram;
    if (!ignoreEndProgram && settings.remoteShutdownEnabled) {
      if (ep == RecStateEndProgram.stop ||
          ep == RecStateEndProgram.stop + RecStateEndProgram.skipSerialOff) {
        _setStatus('statusStopRequested', notify: false);
        await requestExit();
        return;
      }
      if (ep == RecStateEndProgram.shutdown ||
          ep ==
              RecStateEndProgram.shutdown + RecStateEndProgram.skipSerialOff) {
        await _requestShutdown();
        return;
      }
    }
    if (settings.borderToClip) {
      settings = settings.copyWith(
        clipL: math.max(0, globals.borderL).toDouble(),
        clipT: math.max(0, globals.borderT).toDouble(),
        clipR: math.max(0, globals.borderR).toDouble(),
        clipB: math.max(0, globals.borderB).toDouble(),
      );
      await _settingsStore.save(settings);
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> _requestShutdown() async {
    if (_disposed) {
      return false;
    }
    if (kIsWeb) {
      _setStatus('statusShutdownUnsupported');
      return false;
    }
    final bool supportedPlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    if (!supportedPlatform) {
      _setStatus('statusShutdownUnsupported');
      return false;
    }

    try {
      final bool? started = await _systemChannel.invokeMethod<bool>(
        'requestShutdown',
      );
      if (started == true) {
        _setStatus('statusShutdownRequested');
        return true;
      }
    } on PlatformException {
      _setStatus('statusShutdownDenied');
      return false;
    } on MissingPluginException {
      _setStatus('statusShutdownUnsupported');
      return false;
    }

    _setStatus('statusShutdownDenied');
    return false;
  }

  void _onText(RecTextRecord record) {
    if (_disposed) {
      return;
    }
    _hasDataForCurrentConnection = true;
    diaFrame = TextFrame(record: record);
    notifyListeners();
  }

  Future<void> _onPic(RecImageRecord record) async {
    if (_disposed) {
      return;
    }
    _hasDataForCurrentConnection = true;
    final ui.Image? image = await _decodeImage(record.imageBytes);
    if (image == null) {
      return;
    }
    diaFrame = ImageFrame(image: image, bgMode: 1);
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _onBlank(RecImageRecord record) async {
    if (_disposed) {
      return;
    }
    _hasDataForCurrentConnection = true;
    final ui.Image? image = await _decodeImage(record.imageBytes);
    blankFrame = image == null
        ? null
        : ImageFrame(image: image, bgMode: globals.bgMode);
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _onAskSize() async {
    if (_disposed) {
      return;
    }
    await _server.sendScreenSize(
      width: viewportSize.width.round(),
      height: viewportSize.height.round(),
    );
  }

  Future<void> _onCameraSignal(CameraSignal signal) async {
    if (_disposed) {
      return;
    }
    if (signal.kind == CameraSignalKind.request && !settings.cameraStreamEnabled) {
      debugPrint('CAM offerer request ignored (cameraStreamEnabled=false)');
      return;
    }
    try {
      await _camera.handleSignal(signal);
    } catch (e, st) {
      debugPrint('CAM offerer handleSignal error: $e');
      debugPrint('$st');
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _onError(String message) {
    if (_disposed) {
      return;
    }
    if (message.startsWith('tcpServerOpenPortFailed:')) {
      const String prefix = 'tcpServerOpenPortFailed:';
      final String payload = message.substring(prefix.length);
      final int separator = payload.indexOf(':');
      if (separator > 0) {
        final int? port = int.tryParse(payload.substring(0, separator));
        final String error = payload.substring(separator + 1);
        _setStatus(
          'statusTcpServerOpenPortFailed',
          params: <String, Object>{
            'port': port ?? settings.port,
            'error': error,
          },
        );
        return;
      }
    }

    if (message.startsWith('tcpServerError:')) {
      _setStatus(
        'statusTcpServerError',
        params: <String, Object>{
          'error': message.substring('tcpServerError:'.length),
        },
      );
      return;
    }
    if (message.startsWith('tcpServerClientError:')) {
      _setStatus(
        'statusTcpServerClientError',
        params: <String, Object>{
          'error': message.substring('tcpServerClientError:'.length),
        },
      );
      return;
    }
    if (message.startsWith('tcpServerPacketParseError:')) {
      _setStatus(
        'statusTcpServerPacketParseError',
        params: <String, Object>{
          'error': message.substring('tcpServerPacketParseError:'.length),
        },
      );
      return;
    }
    if (message.startsWith('tcpServerSendError:')) {
      _setStatus(
        'statusTcpServerSendError',
        params: <String, Object>{
          'error': message.substring('tcpServerSendError:'.length),
        },
      );
      return;
    }

    _setStatus(
      'statusReceiverError',
      params: <String, Object>{'message': message},
    );
  }

  void _onConnection(bool isConnected) {
    if (_disposed) {
      return;
    }
    if (connected != isConnected) {
      _hasDataForCurrentConnection = false;
      if (!isConnected) {
        diaFrame = null;
        blankFrame = null;
      }
    }
    connected = isConnected;
    _syncNoConnectionLogo();
    if (mqttActive) {
      _setStatus(
        settings.mqttUser.trim().isEmpty
            ? 'statusMqttOff'
            : 'statusMqttReceiving',
        notify: false,
        params: settings.mqttUser.trim().isEmpty
            ? const <String, Object>{}
            : <String, Object>{'user': settings.mqttUser, 'channel': '1'},
      );
    } else {
      if (isConnected) {
        _setStatus(
          'statusConnected',
          notify: false,
          params: <String, Object>{'port': settings.port},
        );
      } else if (_transportConfigured) {
        _setStatus(
          'statusWaitingForClient',
          notify: false,
          params: <String, Object>{'port': settings.port},
        );
      } else {
        _setStatus('statusTcpOff', notify: false);
      }
    }
    notifyListeners();
  }

  void _onMqttConnection(bool isConnected) {
    if (_disposed) {
      return;
    }
    if (mqttConnected != isConnected) {
      _hasDataForCurrentConnection = false;
      if (!isConnected) {
        diaFrame = null;
        blankFrame = null;
      }
    }
    mqttConnected = isConnected;
    _syncNoConnectionLogo();
    notifyListeners();
  }

  void _onUsers(List<MqttUser> users) {
    if (_disposed) {
      return;
    }
    mqttUsers = users;
    senderSuggestions
      ..clear()
      ..addAll(
        _mqtt.usersLike(settings.mqttUser).map((MqttUser u) => u.username),
      );
    notifyListeners();
  }

  ProjectionFrame? get activeFrame {
    final ProjectionFrame? connectedFrame = _connectedProjectedFrame();
    if (connectedFrame != null) {
      return connectedFrame;
    }
    if (!_startupAnimationFinished) {
      return _logoFrame;
    }
    if (_shouldShowNoConnectionLogo) {
      return _logoFrame ?? const LogoFrame(80);
    }
    if (globals.projecting) {
      return diaFrame;
    }
    if (globals.isBlankPic && globals.showBlankPic && blankFrame != null) {
      return blankFrame;
    }
    return null;
  }

  Future<ui.Image?> _decodeImage(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return null;
    }
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  void _onAppResumed() {
    _applyTransport();
  }

  Future<void> _applyTransport() async {
    final String user = settings.mqttUser.trim();
    if (user.isEmpty && !kIsWeb) {
      mqttActive = false;
      mqttConnected = false;
      connected = false;
      _hasDataForCurrentConnection = false;
      _ignoreNextMqttEndProgram = false;
      await _mqtt.closeReceiver();
      await _server.restart(settings.port);
      if (_server.running) {
        _setStatus(
          'statusTcpListening',
          notify: false,
          params: <String, Object>{'port': settings.port},
        );
      }
    } else if (user.isEmpty && kIsWeb) {
      mqttActive = false;
      mqttConnected = false;
      connected = false;
      _hasDataForCurrentConnection = false;
      _ignoreNextMqttEndProgram = false;
      await _mqtt.closeReceiver();
      await _server.stop();
      _setStatus('statusTcpOff', notify: false);
    } else {
      mqttActive = true;
      connected = false;
      mqttConnected = false;
      _hasDataForCurrentConnection = false;
      _ignoreNextMqttEndProgram = true;
      await _server.stop();
      await _mqtt.openReceiver(username: user, channel: '1');
      _setStatus(
        'statusMqttReceiving',
        notify: false,
        params: <String, Object>{'user': user, 'channel': '1'},
      );
    }
    _syncNoConnectionLogo();
  }

  void _setStatus(
    String code, {
    Map<String, Object> params = const <String, Object>{},
    bool notify = true,
  }) {
    statusCode = code;
    statusParams = params;
    if (notify && !_disposed) {
      notifyListeners();
    }
  }

  void _startLogo({bool restartStartup = true}) {
    _logoTimer?.cancel();
    _logoTimer = null;
    if (restartStartup) {
      _startupAnimationFinished = false;
    }
    _logoFrame = const LogoFrame(0);
    int phase = 0;
    _logoTimer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
      if (phase > 80) {
        _startupAnimationFinished = true;
        if (_shouldShowNoConnectionLogo) {
          phase = 0;
          _logoFrame = const LogoFrame(0);
        } else {
          _logoFrame = null;
          t.cancel();
          _logoTimer = null;
        }
      } else {
        _logoFrame = LogoFrame(phase);
        phase++;
      }
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _instance = null;
    _lifecycleListener?.dispose();
    _logoTimer?.cancel();
    _server.stop(emitConnection: false);
    _camera.dispose();
    _mqtt.dispose();
    super.dispose();
  }
}
