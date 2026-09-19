import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:diatar_common/diatar_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_hotkey.dart';

class DesktopProjectorWindow extends StatefulWidget {
  const DesktopProjectorWindow({super.key, required this.monitor});

  /// A kiválasztott monitor indexe. -1 esetén az utolsó (jobb szélső) kijelző.
  final int monitor;

  @override
  State<DesktopProjectorWindow> createState() => _DesktopProjectorWindowState();
}

class _DesktopProjectorWindowState extends State<DesktopProjectorWindow>
    with WindowListener {
  static const String _channelName = 'diatar/desktop_projector';
  static const String _controlChannelName = 'diatar/desktop_projector_control';

  final WindowMethodChannel _channel = const WindowMethodChannel(
    _channelName,
    mode: ChannelMode.unidirectional,
  );
  final WindowMethodChannel _controlChannel = const WindowMethodChannel(
    _controlChannelName,
    mode: ChannelMode.bidirectional,
  );
  final DesktopProjectorController _controller = DesktopProjectorController();
  final FocusNode _hotkeyFocusNode = FocusNode(
    debugLabel: 'desktop-projector-hotkeys',
  );
  WindowController? _currentWindowController;
  int _mainMonitor = -1;
  bool _windowReady = false;

  @override
  void initState() {
    super.initState();
    // The projector runs in a separate Flutter engine, so its notation
    // images must be loaded independently from the main window.
    // Booting the JavaScript engine is the expensive part of an Aretino
    // slide, not rendering one, so it happens here rather than on the first
    // chant (plans/aretino-projection-v1.md, Decision 6).
    unawaited(AretinoRenderService.instance.ensureLoaded());

    unawaited(
      KottaAssets.ensureLoaded().then((_) {
        if (mounted) {
          setState(() {});
        }
      }),
    );
    unawaited(_bootstrap());
  }

  bool _shuttingDown = false;

  /// Leállítja a vetítőablakot: előbb leiratkozik a natív ablakcsatornákról
  /// (hogy a következő megnyitáskor ne kapjunk CHANNEL_LIMIT_REACHED hibát,
  /// mivel a csatorna regisztrációja a natív oldalon az izolátum leállása
  /// után is megmarad), majd bezárja az ablakot.
  Future<void> _shutdown() async {
    if (_shuttingDown) {
      return;
    }
    _shuttingDown = true;
    await _channel.setMethodCallHandler(null);
    await _controlChannel.setMethodCallHandler(null);
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  Future<void> _bootstrap() async {
    final WindowController windowController =
        await WindowController.fromCurrentEngine();
    _currentWindowController = windowController;
    final Map<String, dynamic> args = _decodeArguments(
      windowController.arguments,
    );
    final int requestedMonitor = (args['monitor'] as int?) ?? widget.monitor;
    _mainMonitor = (args['mainMonitor'] as int?) ?? -1;
    _controller.applyMonitor(requestedMonitor);
    _controller.onClose = _shutdown;
    await windowController.setWindowMethodHandler((MethodCall call) async {
      if (call.method == 'window_close') {
        await _shutdown();
        return null;
      }
      throw MissingPluginException('Unknown window method: ${call.method}');
    });
    try {
      await _channel.setMethodCallHandler(_handleProjectorMethodCall);
    } catch (error) {
      if (_isChannelLimitReached(error)) {
        await _shutdown();
        return;
      }
      rethrow;
    }
    // A vezérlő ablakkal való kommunikációhoz (vetítésbe kattintás ->
    // vezérlő visszahozása) egy bidirekcionális csatornán párba állunk a
    // főablakkal. Ha egy korábbi vetítőablak regisztrációja megmaradt
    // (CHANNEL_LIMIT_REACHED), újrapróbáljuk, hogy a kattintásos visszahozás
    // ne törjön el véglegesen.
    await _registerControlChannelWithRetry();
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    // macOS-en a `setSkipTaskbar(true)` az NSApplication activation policy-ját
    // `.accessory`-ra állítja, ami az EGÉSZ alkalmazást eltünteti a Dock-ból.
    // Mivel a vetítőablak amúgy sem jelenik meg külön a Dock-ban (egy app = egy
    // dock ikon), macOS-en nem használjuk a skipTaskbar-t.
    final bool useSkipTaskbar = !Platform.isMacOS;
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        titleBarStyle: TitleBarStyle.hidden,
        backgroundColor: Colors.black,
        alwaysOnTop: true,
        skipTaskbar: useSkipTaskbar,
        windowButtonVisibility: false,
      ),
      () async {
        await windowManager.setAsFrameless();
        if (useSkipTaskbar) {
          await windowManager.setSkipTaskbar(true);
        }
        await windowManager.setPreventClose(true);
        await _applyWindowPlacement(requestedMonitor);
        _windowReady = true;
      },
    );
  }

  Future<void> _registerControlChannelWithRetry() async {
    for (int attempt = 0; attempt < 10; attempt++) {
      try {
        await _controlChannel.setMethodCallHandler((MethodCall call) async {
          return null;
        });
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  Future<dynamic> _handleProjectorMethodCall(MethodCall call) async {
    if (call.method == 'relocate') {
      final Map<String, dynamic> payload = Map<String, dynamic>.from(
        call.arguments as Map,
      );
      final int? monitor = payload['monitor'] as int?;
      final int? mainMonitor = payload['mainMonitor'] as int?;
      if (mainMonitor != null) {
        _mainMonitor = mainMonitor;
      }
      if (monitor != null) {
        _controller.applyMonitor(monitor);
      }
      await _applyWindowPlacement(_controller.monitor);
      return null;
    }

    if (call.method == 'dialog_mode') {
      // A macOS fájlpárbeszédablakok a `runModal` alapú natív útvonalon
      // mennek (lásd: `macos_file_panels`), így erre az üzenetre nincs
      // szükség. A beérkező üzeneteket figyelmen kívül hagyjuk.
      return null;
    }

    final int previousMonitor = _controller.monitor;
    final dynamic result = await _controller.handleMethodCall(call);
    if (call.method == 'settings' && previousMonitor != _controller.monitor) {
      await _applyWindowPlacement(_controller.monitor);
    }
    return result;
  }

  Future<void> _applyWindowPlacement(int requestedMonitor) async {
    if (!_windowReady && _currentWindowController == null) {
      return;
    }
    try {
      final int targetIndex = await _positionOnSelectedDisplay(
        requestedMonitor,
      );
      final bool sameMonitor = _mainMonitor >= 0 && _mainMonitor == targetIndex;
      // Ha a vetítő ablak a vezérlő ablakkal azonos monitoron van, akkor
      // ne legyen mindig felül, hogy a vezérlő ablak kerülhessen a tetejére.
      await windowManager.setAlwaysOnTop(!sameMonitor);
      // A kijelző teljes fizikai területére helyezzük az ablakot. A
      // visibleSize csak a munkaterületet adja vissza, ezért a tálca vagy
      // panel mellett fekete sávot hagyna.
      await windowManager.setFullScreen(false);
      final ui.Rect displayRect = await _displayRect(targetIndex);
      await windowManager.setBounds(displayRect, animate: false);
      final bool useNativeFullscreen = Platform.isWindows || Platform.isLinux;
      if (useNativeFullscreen) {
        await windowManager.setFullScreen(true);
      }
      await windowManager.show(inactive: true);
      // Biztonsági újraalkalmazás: futás közbeni monitorváltáskor a
      // window_manager néha nem érvényesíti azonnal az alwaysOnTop
      // beállítást.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await windowManager.setAlwaysOnTop(!sameMonitor);
      await _requestControlForeground();
    } catch (_) {
      // Nem kritikus: következő settings/relocate ciklus újrapróbálja.
    }
  }

  Future<void> _requestControlForeground() async {
    try {
      await _controlChannel.invokeMethod('focusControl');
    } catch (_) {
      // nem kritikus
    }
  }

  Map<String, dynamic> _decodeArguments(String raw) {
    if (raw.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final Object decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  bool _isChannelLimitReached(Object error) {
    return error.toString().contains('CHANNEL_LIMIT_REACHED');
  }

  /// A kért monitorra pozícionálja az ablakot.
  /// [monitor] >= 0 esetén az adott indexű kijelző, egyébként az utolsó
  /// (jobb szélső) kijelző. Visszaadja a ténylegesen kiválasztott indexet.
  Future<int> _positionOnSelectedDisplay(int monitor) async {
    final List<Display> displays = await screenRetriever.getAllDisplays();
    if (displays.isEmpty) {
      return 0;
    }
    final List<Display> sorted = List<Display>.from(displays)
      ..sort((Display a, Display b) {
        final double ax = a.visiblePosition?.dx ?? 0;
        final double bx = b.visiblePosition?.dx ?? 0;
        return ax.compareTo(bx);
      });
    final int index = (monitor >= 0 && monitor < sorted.length)
        ? monitor
        : sorted.length - 1;
    final Display selected = sorted[index];
    final ui.Offset position = selected.visiblePosition ?? ui.Offset.zero;
    final ui.Size size = selected.size;
    await windowManager.setBounds(
      ui.Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
    );
    return index;
  }

  /// Visszaadja a megadott indexű kijelző teljes területét leíró téglalant.
  /// [index] >= 0 esetén az adott kijelző, egyébként az utolsó (jobb
  /// szélső) kijelző. A vetítőablak teljes képernyőre helyezéséhez használjuk
  /// a natív fullscreen helyett.
  Future<ui.Rect> _displayRect(int index) async {
    final List<Display> displays = await screenRetriever.getAllDisplays();
    if (displays.isEmpty) {
      return ui.Rect.zero;
    }
    final List<Display> sorted = List<Display>.from(displays)
      ..sort((Display a, Display b) {
        final double ax = a.visiblePosition?.dx ?? 0;
        final double bx = b.visiblePosition?.dx ?? 0;
        return ax.compareTo(bx);
      });
    final int i = (index >= 0 && index < sorted.length)
        ? index
        : sorted.length - 1;
    final Display d = sorted[i];
    final ui.Offset position = d.visiblePosition ?? ui.Offset.zero;
    final ui.Size size = d.size;
    return ui.Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _hotkeyFocusNode.dispose();
    final WindowController? current = _currentWindowController;
    if (current != null) {
      unawaited(current.setWindowMethodHandler(null));
    }
    unawaited(_channel.setMethodCallHandler(null));
    unawaited(_controlChannel.setMethodCallHandler(null));
    _controller.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() => _shutdown();

  /// A vetítésbe való kattintáskor visszahozzuk a vezérlő (fő) ablakot.
  Future<void> _onProjectionTap() async {
    try {
      await _controlChannel.invokeMethod('showControl');
    } catch (_) {
      // nem kritikus
    }
  }

  KeyEventResult _onHotkeyEvent(FocusNode node, KeyEvent event) {
    final String? actionId = desktopHotkeyActionForEvent(
      event,
      _controller.settings.desktopActionHotkeys,
    );
    if (actionId == null) {
      return KeyEventResult.ignored;
    }
    unawaited(_controlChannel.invokeMethod<void>('hotkeyAction', actionId));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Focus(
            autofocus: true,
            focusNode: _hotkeyFocusNode,
            onKeyEvent: _onHotkeyEvent,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: MouseRegion(
                cursor: SystemMouseCursors.none,
                child: GestureDetector(
                  onTap: _onProjectionTap,
                  child: CustomPaint(
                    painter: ProjectorPainter(
                      frame: _controller.activeFrame,
                      globals: _controller.globals,
                      settings: _controller.settings,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DesktopProjectorController extends ChangeNotifier {
  ProjectionGlobals globals = const ProjectionGlobals().copyWith(
    projecting: true,
  );
  AppSettings settings = const AppSettings();
  ProjectionFrame? diaFrame = const LogoFrame(0);
  ProjectionFrame? blankFrame;
  int monitor = -1;
  Timer? _logoTimer;
  bool _disposed = false;

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'settings':
        _applySettings(
          AppSettings.fromMap(Map<String, dynamic>.from(call.arguments as Map)),
        );
        return null;
      case 'state':
        _onState(
          Uint8List.fromList(List<int>.from(call.arguments as List<int>)),
        );
        return null;
      case 'text':
        _onText(
          Uint8List.fromList(List<int>.from(call.arguments as List<int>)),
        );
        return null;
      case 'rendered_text':
        return _onRenderedText(
          Uint8List.fromList(List<int>.from(call.arguments as List<int>)),
        );
      case 'pic':
        await _onPic(
          Uint8List.fromList(List<int>.from(call.arguments as List<int>)),
        );
        return null;
      case 'blank':
        await _onBlank(
          Uint8List.fromList(List<int>.from(call.arguments as List<int>)),
        );
        return null;
      case 'idle':
        return null;
      case 'close':
        await _onClose();
        return null;
      default:
        throw MissingPluginException(
          'Unknown projector method: ${call.method}',
        );
    }
  }

  /// A vezérlő ablak bezárását (a 'close' csatornaüzenetre) a vetítőablak
  /// állapotkezelőjéből indítjuk, hogy a natív csatornák is leiratkozzanak.
  Future<void> Function()? onClose;

  Future<void> _onClose() async {
    if (onClose == null) {
      return;
    }
    await onClose!.call();
  }

  void applyMonitor(int value) {
    monitor = value;
  }

  void _applySettings(AppSettings newSettings) {
    if (_disposed) {
      return;
    }
    settings = newSettings;
    monitor = newSettings.desktopProjectorMonitor;
    notifyListeners();
  }

  void _onState(Uint8List bytes) {
    if (_disposed) {
      return;
    }
    final RecStateRecord record = RecStateRecord.fromBytes(bytes);
    globals = globals.fromState(record);
    notifyListeners();
  }

  void _onText(Uint8List bytes) {
    if (_disposed) {
      return;
    }
    diaFrame = TextFrame(record: RecTextRecord.fromBytes(bytes));
    notifyListeners();
  }

  Future<bool> _onRenderedText(Uint8List bytes) async {
    if (_disposed) {
      return false;
    }
    final RecImageRecord record = RecImageRecord.fromBytes(bytes);
    final ui.Image? image = await _decodeImage(record.imageBytes);
    if (image == null) {
      return false;
    }
    diaFrame = ImageFrame(image: image, bgMode: 2);
    notifyListeners();
    return true;
  }

  Future<void> _onPic(Uint8List bytes) async {
    if (_disposed) {
      return;
    }
    final RecImageRecord record = RecImageRecord.fromBytes(bytes);
    final ui.Image? image = await _decodeImage(record.imageBytes);
    if (image == null) {
      return;
    }
    diaFrame = ImageFrame(image: image, bgMode: 1);
    notifyListeners();
  }

  Future<void> _onBlank(Uint8List bytes) async {
    if (_disposed) {
      return;
    }
    final RecImageRecord record = RecImageRecord.fromBytes(bytes);
    final ui.Image? image = await _decodeImage(record.imageBytes);
    if (image == null) {
      return;
    }
    blankFrame = ImageFrame(image: image, bgMode: globals.bgMode);
    notifyListeners();
  }

  ProjectionFrame? get activeFrame {
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

  @override
  void dispose() {
    _disposed = true;
    _logoTimer?.cancel();
    super.dispose();
  }
}
