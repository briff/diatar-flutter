import 'dart:async';
import 'dart:collection';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import 'aretino_render_service.dart';

/// What a rendering is keyed by. Colours are deliberately absent: `#000` ink is
/// recognised when the SVG is parsed, so the projector's text colour is applied
/// when the score is painted rather than when it is rendered.
@immutable
class AretinoRenderKey {
  AretinoRenderKey({
    required this.source,
    required double width,
    required double height,
    required this.style,
  })  : width = width.roundToDouble(),
        height = height.roundToDouble();

  final String source;
  final double width;
  final double height;
  final AretinoStyle style;

  @override
  bool operator ==(Object other) =>
      other is AretinoRenderKey &&
      other.source == source &&
      other.width == width &&
      other.height == height &&
      other.style == style;

  @override
  int get hashCode => Object.hash(source, width, height, style);
}

/// Prepared scores, painted from and never rendered inside `paint()`.
///
/// `CustomPainter.paint` is synchronous and booting a JavaScript engine is not,
/// so an Aretino slide is *prepared* when it arrives and painted from here
/// afterwards (`plans/aretino-projection-v1.md`, Decision 6). Missing a lookup
/// is normal and not an error: the painter draws the extracted lyrics as plain
/// text meanwhile, and this notifies its listeners when the score is ready.
///
/// `ProjectorPainter` repaints on this notifier, so nothing else has to know
/// the cache exists.
class AretinoRenderCache extends ChangeNotifier {
  AretinoRenderCache({AretinoRenderService? service})
      : _service = service ?? AretinoRenderService.instance;

  static final AretinoRenderCache instance = AretinoRenderCache();

  static const int _limit = 24;

  final AretinoRenderService _service;
  final LinkedHashMap<AretinoRenderKey, AretinoRendering> _entries =
      LinkedHashMap<AretinoRenderKey, AretinoRendering>();
  final Set<AretinoRenderKey> _pending = <AretinoRenderKey>{};
  final Map<AretinoRenderKey, String> _failures = <AretinoRenderKey, String>{};

  /// The prepared score for [key], or null when it is not ready yet.
  AretinoRendering? lookup(AretinoRenderKey key) {
    final AretinoRendering? hit = _entries.remove(key);
    if (hit != null) {
      _entries[key] = hit;
    }
    return hit;
  }

  /// Why [key] could not be rendered, when it failed. A malformed score shows
  /// its lyrics rather than retrying forever.
  String? failureFor(AretinoRenderKey key) => _failures[key];

  /// Asks for [key] to be prepared. Cheap and idempotent: safe to call from
  /// `paint()` on every frame while a score is still rendering.
  void request(AretinoRenderKey key) {
    if (_entries.containsKey(key) ||
        _pending.contains(key) ||
        _failures.containsKey(key)) {
      return;
    }
    _pending.add(key);
    unawaited(_prepare(key));
  }

  /// Rendering is synchronous once the engine is up; the await is the engine
  /// boot, which happens once per app.
  Future<void> _prepare(AretinoRenderKey key) async {
    try {
      await _service.ensureLoaded();
      _store(
        key,
        _service.renderToFit(
          key.source,
          target: Size(key.width, key.height),
          style: key.style,
        ),
      );
    } catch (error) {
      _failures[key] = error.toString();
    } finally {
      _pending.remove(key);
      notifyListeners();
    }
  }

  void _store(AretinoRenderKey key, AretinoRendering rendering) {
    _entries[key] = rendering;
    while (_entries.length > _limit) {
      _entries.remove(_entries.keys.first);
    }
  }

  @visibleForTesting
  void clear() {
    _entries.clear();
    _pending.clear();
    _failures.clear();
  }
}
