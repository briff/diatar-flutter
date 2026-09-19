import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'aretino_js_engine.dart';
import 'aretino_svg.dart';

/// How a score is sized. Everything is in logical pixels; the library's
/// physical units (mm, pt) are converted here so callers never see them.
@immutable
class AretinoStyle {
  const AretinoStyle({
    required this.lyricFontSize,
    this.notationScale = 0.25,
    this.fontFamily,
    this.fontFamilyFallback = const <String>[],
    this.noteSpacing = 1.0,
    this.hideRepeatClef = true,
  });

  /// Height of the lyric face, in logical pixels.
  final double lyricFontSize;

  /// One staff space as a fraction of [lyricFontSize]. The library's own
  /// defaults (1.75 mm staff space against 10 pt lyrics) work out to almost
  /// exactly 0.5; against projected lyrics that staff is twice as tall as it
  /// needs to be, so half of it is the default here.
  final double notationScale;

  /// The lyric face. Null — the default — is the face the rest of the
  /// projection is drawn with: whatever the platform gives a [TextStyle] that
  /// names no family. Measurement and painting both go through [textStyle], so
  /// the two cannot disagree whatever the platform picks.
  final String? fontFamily;
  final List<String> fontFamilyFallback;

  /// Multiplier on the horizontal advance between neumes.
  final double noteSpacing;

  /// Draw the clef on the first staff system only. A projected chant is one
  /// verse broken over a few systems rather than a page of music, so the
  /// repeated clef is noise; a score can still ask for it back with
  /// `%option: hideRepeatClef=false`.
  final bool hideRepeatClef;

  /// Points per pixel at the library's default 96 dpi.
  static const double _dpi = 96.0;

  double get _staffSpaceMm => lyricFontSize * notationScale * 25.4 / _dpi;

  /// The `font-family` string handed to the renderer. It comes back in the
  /// SVG's `<text>` elements, but nothing reads it there: every string is
  /// measured on the Dart side with [textStyle], and [parseAretinoSvg] paints
  /// with that same style. Inside the library it is only a measurement key.
  String get cssFontFamily {
    final List<String> families = <String>[
      if (fontFamily != null) fontFamily!,
      ...fontFamilyFallback,
    ];
    if (families.isEmpty) {
      return 'sans-serif';
    }
    return families
        .map((String f) => f.contains(' ') ? "'$f'" : f)
        .join(', ');
  }

  AretinoTextStyle get textStyle => AretinoTextStyle(
        fontSize: lyricFontSize,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      );

  Map<String, Object?> rendererOptions(double width) => <String, Object?>{
        'width': width,
        'dpi': _dpi,
        'staffSpaceMm': _staffSpaceMm,
        'lyricSize': lyricFontSize * 72.0 / _dpi,
        'textFont': cssFontFamily,
        'noteSpacing': noteSpacing,
        'hideRepeatClef': hideRepeatClef,
      };

  AretinoStyle withLyricFontSize(double size) => AretinoStyle(
        lyricFontSize: size,
        notationScale: notationScale,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        noteSpacing: noteSpacing,
        hideRepeatClef: hideRepeatClef,
      );

  @override
  bool operator ==(Object other) =>
      other is AretinoStyle &&
      other.lyricFontSize == lyricFontSize &&
      other.notationScale == notationScale &&
      other.fontFamily == fontFamily &&
      other.noteSpacing == noteSpacing &&
      other.hideRepeatClef == hideRepeatClef &&
      listEquals(other.fontFamilyFallback, fontFamilyFallback);

  @override
  int get hashCode => Object.hash(
        lyricFontSize,
        notationScale,
        fontFamily,
        noteSpacing,
        hideRepeatClef,
        Object.hashAll(fontFamilyFallback),
      );
}

/// A rendered score: one picture per staff system, in the order they stack.
///
/// A staff system is the reflow unit, the way a wrapped line is for text
/// (`plans/aretino-projection-v1.md`, Decision 5), so the existing fit and
/// scroll behaviour applies to these unchanged.
@immutable
class AretinoRendering {
  const AretinoRendering({
    required this.rows,
    required this.style,
    required this.width,
  });

  final List<AretinoPicture> rows;
  final AretinoStyle style;

  /// The width the score was laid out against.
  final double width;

  double get height =>
      rows.fold(0.0, (double sum, AretinoPicture r) => sum + r.size.height);

  bool get isEmpty => rows.isEmpty;
}

class AretinoRenderException implements Exception {
  AretinoRenderException(this.message);

  final String message;

  @override
  String toString() => 'AretinoRenderException: $message';
}

/// Renders Aretino source through the embedded library.
///
/// Flutter measures every string the layout engine asks about, on every
/// platform (Decision 3): the engine reports the strings it could not find in
/// the injected map, this measures them with `TextPainter`, and the render runs
/// again. Two or three passes settle it, and no JS-to-Dart call happens during
/// a render.
class AretinoRenderService {
  AretinoRenderService({AretinoJsEngine? engine})
      : _engine = engine ?? AretinoJsEngine();

  static final AretinoRenderService instance = AretinoRenderService();

  /// Guard against a pathological source whose line breaks never settle.
  static const int _maxMeasurePasses = 6;

  final AretinoJsEngine _engine;

  /// Widths and ascents carry over between renders: the same syllables recur
  /// across sizes only when the size matches, and the key includes the size, so
  /// this is a pure win.
  final Map<String, double> _widths = <String, double>{};
  final Map<String, double> _ascents = <String, double>{};

  int _renderCount = 0;

  /// How many times the JavaScript renderer has actually run. Instrumentation
  /// for the fit loop, which the plan asks to measure before optimising.
  int get renderCount => _renderCount;

  bool get isReady => _engine.isReady;

  Future<void> ensureLoaded() => _engine.ensureLoaded();

  /// Renders [source] to staff systems laid out against [width].
  AretinoRendering render(
    String source, {
    required double width,
    required AretinoStyle style,
  }) {
    final List<String> rows = _renderRows(source, width: width, style: style);
    return AretinoRendering(
      rows: <AretinoPicture>[
        for (final String row in rows)
          parseAretinoSvg(row, defaultTextStyle: style.textStyle),
      ],
      style: style,
      width: width,
    );
  }

  /// Renders [source] as large as it can while still fitting [target].
  ///
  /// Shrinking the lyric size rather than scaling the finished picture is what
  /// makes this a fit and not a zoom: at a smaller size more syllables fit on a
  /// staff system, so the score re-breaks instead of merely getting smaller.
  AretinoRendering renderToFit(
    String source, {
    required Size target,
    required AretinoStyle style,
    double minLyricFontSize = 8.0,
    double step = 0.85,
    int maxSteps = 10,
  }) {
    AretinoStyle attempt = style;
    AretinoRendering? last;
    for (int i = 0; i < maxSteps; i++) {
      final AretinoRendering rendering =
          render(source, width: target.width, style: attempt);
      last = rendering;
      if (rendering.height <= target.height || rendering.isEmpty) {
        return rendering;
      }
      final double next = attempt.lyricFontSize * step;
      if (next < minLyricFontSize) {
        break;
      }
      attempt = attempt.withLyricFontSize(next);
    }
    return last!;
  }

  /// Options that are ours to decide only until a score says otherwise.
  ///
  /// The library merges `%option:` headers *under* the options it is called
  /// with, so anything we always pass a score can never override. Projection
  /// geometry — width, sizes, the face — has to stay ours, but these are
  /// engraving taste, so a score that states one wins.
  static const List<String> _overridableOptions = <String>['hideRepeatClef'];

  static final RegExp _optionHeader =
      RegExp(r'^\s*%option:\s*([A-Za-z]+)\s*=', multiLine: true);

  List<String> _renderRows(
    String source, {
    required double width,
    required AretinoStyle style,
  }) {
    final Map<String, Object?> options = style.rendererOptions(width);
    for (final RegExpMatch m in _optionHeader.allMatches(source)) {
      final String name = m.group(1)!;
      if (_overridableOptions.contains(name)) {
        options.remove(name);
      }
    }
    for (int pass = 0; pass < _maxMeasurePasses; pass++) {
      final Map<String, Object?> reply = _callRenderer(
        source: source,
        options: options,
      );
      final List<Object?> missingWidths =
          (reply['missingWidths'] as List<Object?>?) ?? const <Object?>[];
      final List<Object?> missingAscents =
          (reply['missingAscents'] as List<Object?>?) ?? const <Object?>[];

      if (missingWidths.isEmpty && missingAscents.isEmpty) {
        final List<Object?> rows =
            (reply['rows'] as List<Object?>?) ?? const <Object?>[];
        return rows.cast<String>();
      }

      for (final Object? entry in missingWidths) {
        final Map<String, Object?> m = entry! as Map<String, Object?>;
        _widths[m['key']! as String] =
            measureAretinoText(m['text']! as String, _styleOf(m, style));
      }
      for (final Object? entry in missingAscents) {
        final Map<String, Object?> m = entry! as Map<String, Object?>;
        _ascents[m['key']! as String] =
            measureAretinoAscent(m['text']! as String, _styleOf(m, style));
      }
    }
    throw AretinoRenderException(
      'text measurement did not settle in $_maxMeasurePasses passes',
    );
  }

  AretinoTextStyle _styleOf(Map<String, Object?> m, AretinoStyle style) =>
      AretinoTextStyle(
        fontSize: (m['fontSize']! as num).toDouble(),
        fontFamily: style.fontFamily,
        fontFamilyFallback: style.fontFamilyFallback,
        bold: m['bold'] == true,
        italic: m['italic'] == true,
      );

  Map<String, Object?> _callRenderer({
    required String source,
    required Map<String, Object?> options,
  }) {
    _renderCount++;
    final String argsJson = jsonEncode(<String, Object?>{
      'source': source,
      'options': options,
      'widths': _widths,
      'ascents': _ascents,
      'split': true,
    });
    final Map<String, Object?> reply =
        jsonDecode(_engine.render(argsJson)) as Map<String, Object?>;
    if (reply['ok'] != true) {
      throw AretinoRenderException(
        (reply['error'] as String?) ?? 'unknown renderer error',
      );
    }
    return reply;
  }
}
