import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';

/// One long-lived QuickJS (or JavaScriptCore, on Apple platforms) runtime with
/// the Aretino bundle evaluated into it. Booting the engine is the expensive
/// part, not rendering, so the runtime is created once and kept
/// (`plans/aretino-projection-v1.md`, Decision 6).
class AretinoJsEngine {
  AretinoJsEngine();

  static const String assetPath = 'assets/aretino/aretino.js';

  JavascriptRuntime? _runtime;
  Future<void>? _loading;

  bool get isReady => _runtime != null;

  Future<void> ensureLoaded() {
    _loading ??= _boot();
    return _loading!;
  }

  Future<void> _boot() async {
    final String bundle = await rootBundle.loadString(assetPath);
    final JavascriptRuntime runtime = getJavascriptRuntime();
    final JsEvalResult result = runtime.evaluate(bundle);
    if (result.isError) {
      runtime.dispose();
      throw StateError('Aretino bundle failed to load: ${result.stringResult}');
    }
    _runtime = runtime;
  }

  /// Calls `Aretino.render(argsJson)` and returns its JSON reply.
  ///
  /// Both directions are strings, so the argument is embedded as a JavaScript
  /// string literal — `jsonEncode` of a Dart string is exactly that.
  String render(String argsJson) {
    final JavascriptRuntime? runtime = _runtime;
    if (runtime == null) {
      throw StateError('Aretino engine used before ensureLoaded() completed');
    }
    final JsEvalResult result = runtime.evaluate(
      'Aretino.render(${jsonEncode(argsJson)})',
    );
    if (result.isError) {
      throw StateError('Aretino render failed: ${result.stringResult}');
    }
    return result.stringResult;
  }

  void dispose() {
    _runtime?.dispose();
    _runtime = null;
    _loading = null;
  }
}
