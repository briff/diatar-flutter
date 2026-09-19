/// Hosts the checked-in `@aretino-chant/core` bundle.
///
/// The library is the renderer on every platform; only the JavaScript engine
/// differs (`plans/aretino-projection-v1.md`, Decision 2). These are bindings,
/// not renderers: the whole interface is one JSON-in, JSON-out call, so no
/// JS-to-Dart callback ever fires during a render.
library;

export 'aretino_js_engine_stub.dart'
    if (dart.library.io) 'aretino_js_engine_native.dart'
    if (dart.library.js_interop) 'aretino_js_engine_web.dart';
