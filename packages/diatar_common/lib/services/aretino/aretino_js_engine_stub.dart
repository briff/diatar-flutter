/// Keeps targets without `dart:io` or `dart:js_interop` compiling. Nothing
/// ships against this: the native and web variants cover every platform both
/// apps build for.
class AretinoJsEngine {
  AretinoJsEngine();

  static const String assetPath = 'assets/aretino/aretino.js';

  bool get isReady => false;

  Future<void> ensureLoaded() async {
    throw UnsupportedError(
      'No JavaScript engine without dart:io or dart:js_interop',
    );
  }

  String render(String argsJson) {
    throw UnsupportedError(
      'No JavaScript engine without dart:io or dart:js_interop',
    );
  }

  void dispose() {}
}
