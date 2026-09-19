import 'dart:js_interop';

import 'package:flutter/services.dart';

@JS('eval')
external JSAny? _globalEval(String code);

@JS('Aretino')
external JSObject? get _aretino;

extension type _AretinoApi(JSObject _) implements JSObject {
  external String render(String argsJson);
}

/// The browser's own JavaScript engine hosts the same bundle every other
/// platform runs. The bundle is an IIFE assigning a global, so it is evaluated
/// through `globalThis.eval` — an indirect eval, which runs in global scope.
class AretinoJsEngine {
  AretinoJsEngine();

  static const String assetPath = 'assets/aretino/aretino.js';

  bool _ready = false;
  Future<void>? _loading;

  bool get isReady => _ready;

  Future<void> ensureLoaded() {
    _loading ??= _boot();
    return _loading!;
  }

  Future<void> _boot() async {
    final String bundle = await rootBundle.loadString(assetPath);
    _globalEval(bundle);
    if (_aretino == null) {
      throw StateError('Aretino bundle failed to load: no global');
    }
    _ready = true;
  }

  String render(String argsJson) {
    final JSObject? api = _aretino;
    if (api == null || !_ready) {
      throw StateError('Aretino engine used before ensureLoaded() completed');
    }
    return _AretinoApi(api).render(argsJson);
  }

  void dispose() {
    _ready = false;
    _loading = null;
  }
}
