import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Turns the SVG `renderAretino` returns into Flutter drawing operations.
///
/// The library emits a deliberately narrow document — `g`, `line`, `ellipse`,
/// `circle`, `path`, `text`, `tspan`, and only `translate`/`scale`/`rotate`
/// transforms — so this walks that subset directly onto a `Canvas` rather than
/// going through a general SVG stack (`plans/aretino-projection-v1.md`,
/// Decision 4). Two things fall out of doing it here:
///
/// * lyrics are drawn by `TextPainter`, with the same font and the same metrics
///   fed back into the layout engine, so words land exactly where the engine
///   was told they would;
/// * `#000` ink is recognised as ink, so a slide can honour the projector's
///   text colour without re-rendering the score.

/// The colour the library draws ink in. Recognised so the painter can swap in
/// the projector's own text colour.
const int _inkArgb = 0xFF000000;

/// A parsed SVG document: drawing operations in paint order, plus the logical
/// size of its `viewBox`.
class AretinoPicture {
  AretinoPicture({
    required this.ops,
    required this.viewBox,
  }) : inkBounds = _inkBoundsOf(ops) ?? viewBox;

  final List<AretinoOp> ops;
  final Rect viewBox;

  /// What the staff system actually draws, which is less than [viewBox]: the
  /// library reserves a nominal two staff spaces above every staff for the
  /// notes that may rise over it, and leaves the lyric descender's worth of
  /// room below. Systems are stacked on this rather than on the viewBox, so the
  /// air between one system's lyrics and the next system's music is the gap
  /// asked for and nothing more.
  final Rect inkBounds;

  Size get size => viewBox.size;

  bool get isEmpty => ops.isEmpty;

  static Rect? _inkBoundsOf(List<AretinoOp> ops) {
    Rect? bounds;
    for (final AretinoOp op in ops) {
      final Rect? local = op.localBounds();
      if (local == null || local.isEmpty) {
        continue;
      }
      final Rect r = _transformRect(op.transform, local);
      bounds = bounds == null ? r : bounds.expandToInclude(r);
    }
    return bounds;
  }

  /// The library emits only translate, scale and rotate, so the four corners
  /// bound the transformed rectangle exactly.
  static Rect _transformRect(Float64List m, Rect r) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    for (final Offset corner in <Offset>[
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
    ]) {
      final double x = m[0] * corner.dx + m[4] * corner.dy + m[12];
      final double y = m[1] * corner.dx + m[5] * corner.dy + m[13];
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Draws into [canvas] at logical coordinates, with `#000` ink replaced by
  /// [inkColor].
  void paint(Canvas canvas, {required Color inkColor}) {
    for (final AretinoOp op in ops) {
      canvas.save();
      canvas.transform(op.transform);
      op.paint(canvas, inkColor);
      canvas.restore();
    }
  }
}

abstract class AretinoOp {
  const AretinoOp(this.transform);

  /// Column-major 4x4, as `Canvas.transform` wants it.
  final Float64List transform;

  void paint(Canvas canvas, Color inkColor);

  /// What this operation inks, before [transform] — null when it inks nothing.
  Rect? localBounds();

  static Color _resolve(AretinoInk color, Color inkColor) =>
      color.isInk ? inkColor : color.value;
}

class AretinoLineOp extends AretinoOp {
  const AretinoLineOp(
    super.transform, {
    required this.from,
    required this.to,
    required this.stroke,
    required this.strokeWidth,
    required this.cap,
  });

  final Offset from;
  final Offset to;
  final AretinoInk stroke;
  final double strokeWidth;
  final StrokeCap cap;

  @override
  void paint(Canvas canvas, Color inkColor) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = AretinoOp._resolve(stroke, inkColor)
        ..strokeWidth = strokeWidth
        ..strokeCap = cap,
    );
  }

  @override
  Rect? localBounds() =>
      Rect.fromPoints(from, to).inflate(strokeWidth / 2);
}

class AretinoOvalOp extends AretinoOp {
  const AretinoOvalOp(
    super.transform, {
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.fill,
  });

  final Offset center;
  final double radiusX;
  final double radiusY;
  final AretinoInk fill;

  @override
  void paint(Canvas canvas, Color inkColor) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      Paint()..color = AretinoOp._resolve(fill, inkColor),
    );
  }

  @override
  Rect? localBounds() => Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      );
}

class AretinoPathOp extends AretinoOp {
  const AretinoPathOp(
    super.transform, {
    required this.path,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final Path path;
  final AretinoInk? fill;
  final AretinoInk? stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Color inkColor) {
    final AretinoInk? f = fill;
    if (f != null) {
      canvas.drawPath(path, Paint()..color = AretinoOp._resolve(f, inkColor));
    }
    final AretinoInk? s = stroke;
    if (s != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AretinoOp._resolve(s, inkColor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  @override
  Rect? localBounds() {
    if (fill == null && stroke == null) {
      return null;
    }
    final Rect bounds = path.getBounds();
    return stroke == null ? bounds : bounds.inflate(strokeWidth / 2);
  }
}

/// A `<text>` element, laid out by `TextPainter` rather than by the SVG stack.
class AretinoTextOp extends AretinoOp {
  AretinoTextOp(
    super.transform, {
    required this.spans,
    required this.anchor,
    required this.anchorX,
    required this.baselineY,
    required this.fill,
  });

  final List<AretinoTextRun> spans;
  final TextAlign anchor;
  final double anchorX;
  final double baselineY;
  final AretinoInk fill;

  @override
  void paint(Canvas canvas, Color inkColor) {
    final TextPainter tp = _layout(inkColor);
    tp.paint(canvas, _origin(tp));
    tp.dispose();
  }

  @override
  Rect? localBounds() {
    final TextPainter tp = _layout(const Color(0xFF000000));
    final Rect bounds = _origin(tp) & tp.size;
    tp.dispose();
    return bounds;
  }

  TextPainter _layout(Color inkColor) {
    final Color base = AretinoOp._resolve(fill, inkColor);
    return TextPainter(
      text: TextSpan(
        children: <InlineSpan>[
          for (final AretinoTextRun run in spans)
            TextSpan(
              text: run.text,
              style: run.style.toTextStyle(
                run.color == null ? base : AretinoOp._resolve(run.color!, inkColor),
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Where the laid-out line box goes, so that its alphabetic baseline lands on
  /// [baselineY] and it sits at [anchorX] the way `text-anchor` asks.
  Offset _origin(TextPainter tp) {
    final double baseline =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final double left =
        anchor == TextAlign.center ? anchorX - tp.width / 2 : anchorX;
    return Offset(left, baselineY - baseline);
  }
}

class AretinoTextRun {
  const AretinoTextRun({
    required this.text,
    required this.style,
    this.color,
  });

  final String text;
  final AretinoTextStyle style;
  final AretinoInk? color;
}

/// The text attributes the library actually emits, in a form both the renderer's
/// measurement callback and the painter can build a `TextStyle` from — so a
/// string is measured exactly as it is later drawn.
class AretinoTextStyle {
  const AretinoTextStyle({
    required this.fontSize,
    required this.fontFamily,
    required this.fontFamilyFallback,
    this.bold = false,
    this.italic = false,
    this.smallCaps = false,
  });

  final double fontSize;
  final String? fontFamily;
  final List<String> fontFamilyFallback;
  final bool bold;
  final bool italic;
  final bool smallCaps;

  TextStyle toTextStyle(Color color) => TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontFeatures: smallCaps
            ? const <FontFeature>[FontFeature.enable('smcp')]
            : null,
        // The engine positions every syllable itself; Flutter must not add
        // leading of its own or the baseline drifts off the one it computed.
        height: null,
      );

  AretinoTextStyle scaled(double factor) => AretinoTextStyle(
        fontSize: fontSize * factor,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        bold: bold,
        italic: italic,
        smallCaps: smallCaps,
      );
}

/// Measures a string the way it will be drawn. This is what is injected into
/// the renderer (Decision 3), and what `AretinoTextOp` later lays out, so
/// layout and painting cannot disagree.
double measureAretinoText(String text, AretinoTextStyle style) {
  if (text.isEmpty) {
    return 0;
  }
  final TextPainter tp = TextPainter(
    text: TextSpan(text: text, style: style.toTextStyle(const Color(0xFF000000))),
    textDirection: TextDirection.ltr,
  )..layout();
  final double width = tp.width;
  tp.dispose();
  return width;
}

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

/// A colour from the SVG, remembering whether it was the library's `#000` ink.
/// Ink is swapped for the projector's text colour when the score is painted, so a
/// colour change never costs a re-render.
class AretinoInk {
  const AretinoInk(this.value, this.isInk);

  final Color value;
  final bool isInk;

  static AretinoInk? parse(String? raw) {
    if (raw == null) {
      return null;
    }
    final String s = raw.trim().toLowerCase();
    if (s.isEmpty || s == 'none' || s == 'transparent') {
      return null;
    }
    final int? argb = _parseCss(s);
    if (argb == null) {
      return const AretinoInk(Color(_inkArgb), true);
    }
    return AretinoInk(Color(argb), argb == _inkArgb);
  }

  static int? _parseCss(String s) {
    if (s.startsWith('#')) {
      final String hex = s.substring(1);
      if (hex.length == 3) {
        final int r = int.parse(hex[0], radix: 16) * 17;
        final int g = int.parse(hex[1], radix: 16) * 17;
        final int b = int.parse(hex[2], radix: 16) * 17;
        return 0xFF000000 | (r << 16) | (g << 8) | b;
      }
      if (hex.length == 6) {
        final int? v = int.tryParse(hex, radix: 16);
        return v == null ? null : 0xFF000000 | v;
      }
      return null;
    }
    return _namedColors[s];
  }

  static const Map<String, int> _namedColors = <String, int>{
    'black': 0xFF000000,
    'white': 0xFFFFFFFF,
    'red': 0xFFFF0000,
    'green': 0xFF008000,
    'blue': 0xFF0000FF,
    'yellow': 0xFFFFFF00,
    'orange': 0xFFFFA500,
    'purple': 0xFF800080,
    'gray': 0xFF808080,
    'grey': 0xFF808080,
  };
}

/// A 2D affine transform, kept in SVG's `a b c d e f` order.
class _Affine {
  const _Affine(this.a, this.b, this.c, this.d, this.e, this.f);

  static const _Affine identity = _Affine(1, 0, 0, 1, 0, 0);

  final double a, b, c, d, e, f;

  _Affine multiply(_Affine o) => _Affine(
        a * o.a + c * o.b,
        b * o.a + d * o.b,
        a * o.c + c * o.d,
        b * o.c + d * o.d,
        a * o.e + c * o.f + e,
        b * o.e + d * o.f + f,
      );

  Float64List toFloat64List() {
    final Float64List m = Float64List(16);
    m[0] = a;
    m[1] = b;
    m[4] = c;
    m[5] = d;
    m[10] = 1;
    m[12] = e;
    m[13] = f;
    m[15] = 1;
    return m;
  }

  /// Parses the `translate(…) scale(…) rotate(…)` forms the library emits.
  static _Affine parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return identity;
    }
    _Affine result = identity;
    for (final RegExpMatch m
        in RegExp(r'(\w+)\s*\(([^)]*)\)').allMatches(raw)) {
      final String name = m.group(1)!;
      final List<double> args = m
          .group(2)!
          .split(RegExp(r'[\s,]+'))
          .where((String s) => s.isNotEmpty)
          .map((String s) => double.tryParse(s) ?? 0)
          .toList();
      switch (name) {
        case 'translate':
          result = result.multiply(
            _Affine(1, 0, 0, 1, args.isNotEmpty ? args[0] : 0,
                args.length > 1 ? args[1] : 0),
          );
        case 'scale':
          final double sx = args.isNotEmpty ? args[0] : 1;
          final double sy = args.length > 1 ? args[1] : sx;
          result = result.multiply(_Affine(sx, 0, 0, sy, 0, 0));
        case 'rotate':
          final double deg = args.isNotEmpty ? args[0] : 0;
          final double rad = deg * math.pi / 180;
          final double cx = args.length > 1 ? args[1] : 0;
          final double cy = args.length > 2 ? args[2] : 0;
          final _Affine rot = _Affine(
            math.cos(rad),
            math.sin(rad),
            -math.sin(rad),
            math.cos(rad),
            0,
            0,
          );
          result = result
              .multiply(_Affine(1, 0, 0, 1, cx, cy))
              .multiply(rot)
              .multiply(_Affine(1, 0, 0, 1, -cx, -cy));
        case 'matrix':
          if (args.length >= 6) {
            result = result.multiply(
              _Affine(args[0], args[1], args[2], args[3], args[4], args[5]),
            );
          }
      }
    }
    return result;
  }
}

class _Tag {
  _Tag(this.name, this.attrs, this.selfClosing, this.closing);

  final String name;
  final Map<String, String> attrs;
  final bool selfClosing;
  final bool closing;
}

/// Parses one SVG document produced by `renderAretino`.
///
/// The input is machine-generated with escaped attributes and text, so a
/// tokenizer over `<…>` is enough — there are no CDATA sections, comments with
/// angle brackets, or attribute values containing `>`.
AretinoPicture parseAretinoSvg(
  String svg, {
  required AretinoTextStyle defaultTextStyle,
}) {
  final List<AretinoOp> ops = <AretinoOp>[];
  final List<_Affine> stack = <_Affine>[_Affine.identity];
  Rect viewBox = Rect.zero;

  final RegExp tagRe = RegExp(r'<(/?)([a-zA-Z][\w:-]*)((?:[^>"]|"[^"]*")*?)(/?)>');
  final RegExp attrRe = RegExp(r'([\w:-]+)\s*=\s*"([^"]*)"');

  _Tag readTag(RegExpMatch m) {
    final Map<String, String> attrs = <String, String>{};
    for (final RegExpMatch a in attrRe.allMatches(m.group(3) ?? '')) {
      attrs[a.group(1)!] = _unescape(a.group(2)!);
    }
    return _Tag(m.group(2)!, attrs, (m.group(4) ?? '').isNotEmpty,
        (m.group(1) ?? '').isNotEmpty);
  }

  double? num_(Map<String, String> a, String key) =>
      a[key] == null ? null : double.tryParse(a[key]!.trim());

  int pos = 0;
  while (pos < svg.length) {
    final Iterator<RegExpMatch> it = tagRe.allMatches(svg, pos).iterator;
    if (!it.moveNext()) {
      break;
    }
    final RegExpMatch m = it.current;
    pos = m.end;
    final _Tag tag = readTag(m);

    if (tag.name == 'style') {
      // Only carries the editor's highlight rules; nothing to draw.
      final int close = svg.indexOf('</style>', pos);
      pos = close < 0 ? svg.length : close + '</style>'.length;
      continue;
    }

    if (tag.closing) {
      if (tag.name == 'g' && stack.length > 1) {
        stack.removeLast();
      }
      continue;
    }

    final _Affine parent = stack.last;
    final _Affine local =
        parent.multiply(_Affine.parse(tag.attrs['transform']));

    switch (tag.name) {
      case 'svg':
        final List<double> vb = (tag.attrs['viewBox'] ?? '')
            .split(RegExp(r'[\s,]+'))
            .where((String s) => s.isNotEmpty)
            .map((String s) => double.tryParse(s) ?? 0)
            .toList();
        if (vb.length == 4) {
          viewBox = Rect.fromLTWH(vb[0], vb[1], vb[2], vb[3]);
        }
      case 'g':
        if (!tag.selfClosing) {
          stack.add(local);
        }
      case 'line':
        final AretinoInk? stroke = AretinoInk.parse(tag.attrs['stroke']);
        if (stroke != null) {
          ops.add(
            AretinoLineOp(
              local.toFloat64List(),
              from: Offset(num_(tag.attrs, 'x1') ?? 0, num_(tag.attrs, 'y1') ?? 0),
              to: Offset(num_(tag.attrs, 'x2') ?? 0, num_(tag.attrs, 'y2') ?? 0),
              stroke: stroke,
              strokeWidth: num_(tag.attrs, 'stroke-width') ?? 1,
              cap: switch (tag.attrs['stroke-linecap']) {
                'round' => StrokeCap.round,
                'square' => StrokeCap.square,
                _ => StrokeCap.butt,
              },
            ),
          );
        }
      case 'ellipse':
      case 'circle':
        final AretinoInk? fill = tag.attrs.containsKey('fill')
            ? AretinoInk.parse(tag.attrs['fill'])
            : const AretinoInk(Color(_inkArgb), true);
        if (fill != null) {
          final double r = num_(tag.attrs, 'r') ?? 0;
          ops.add(
            AretinoOvalOp(
              local.toFloat64List(),
              center: Offset(
                num_(tag.attrs, 'cx') ?? 0,
                num_(tag.attrs, 'cy') ?? 0,
              ),
              radiusX: num_(tag.attrs, 'rx') ?? r,
              radiusY: num_(tag.attrs, 'ry') ?? r,
              fill: fill,
            ),
          );
        }
      case 'path':
        final Path path = parseSvgPath(tag.attrs['d'] ?? '');
        path.fillType = (tag.attrs['fill-rule'] ?? '') == 'evenodd'
            ? PathFillType.evenOdd
            : PathFillType.nonZero;
        final bool hasFillAttr = tag.attrs.containsKey('fill');
        ops.add(
          AretinoPathOp(
            local.toFloat64List(),
            path: path,
            fill: hasFillAttr
                ? AretinoInk.parse(tag.attrs['fill'])
                : const AretinoInk(Color(_inkArgb), true),
            stroke: AretinoInk.parse(tag.attrs['stroke']),
            strokeWidth: num_(tag.attrs, 'stroke-width') ?? 1,
          ),
        );
      case 'text':
        final int close = svg.indexOf('</text>', pos);
        final String body = close < 0 ? '' : svg.substring(pos, close);
        pos = close < 0 ? svg.length : close + '</text>'.length;
        final AretinoTextStyle style = _textStyle(tag.attrs, defaultTextStyle);
        final List<AretinoTextRun> runs = _parseTextRuns(body, style, attrRe);
        if (runs.isNotEmpty) {
          ops.add(
            AretinoTextOp(
              local.toFloat64List(),
              spans: runs,
              anchor: (tag.attrs['text-anchor'] ?? 'start') == 'middle'
                  ? TextAlign.center
                  : TextAlign.left,
              anchorX: num_(tag.attrs, 'x') ?? 0,
              baselineY: num_(tag.attrs, 'y') ?? 0,
              fill: AretinoInk.parse(tag.attrs['fill']) ??
                  const AretinoInk(Color(_inkArgb), true),
            ),
          );
        }
      default:
        // Unknown element: ignore it rather than fail the whole slide.
        break;
    }
  }

  return AretinoPicture(ops: ops, viewBox: viewBox);
}

AretinoTextStyle _textStyle(
  Map<String, String> attrs,
  AretinoTextStyle fallback,
) {
  final double? size = double.tryParse(attrs['font-size'] ?? '');
  // `font-family` is deliberately ignored. The renderer echoes one family —
  // the `textFont` we handed it — into every `<text>` element, and it is a CSS
  // name, not a Flutter one: honouring it would paint with a face the widths
  // were never measured against. [fallback] carries the face the caller both
  // measured and paints with.
  return AretinoTextStyle(
    fontSize: size ?? fallback.fontSize,
    fontFamily: fallback.fontFamily,
    fontFamilyFallback: fallback.fontFamilyFallback,
    bold: (attrs['font-weight'] ?? '') == 'bold' || fallback.bold,
    italic: (attrs['font-style'] ?? '') == 'italic' || fallback.italic,
    smallCaps: (attrs['font-variant'] ?? '') == 'small-caps' || fallback.smallCaps,
  );
}

/// Splits a `<text>` body into styled runs. The body is either plain escaped
/// text or a sequence of `<tspan>` elements carrying weight, style and a
/// relative `font-size`.
List<AretinoTextRun> _parseTextRuns(
  String body,
  AretinoTextStyle base,
  RegExp attrRe,
) {
  final List<AretinoTextRun> runs = <AretinoTextRun>[];
  final RegExp tspanRe = RegExp(r'<tspan([^>]*)>(.*?)</tspan>', dotAll: true);
  int cursor = 0;

  void addPlain(String raw) {
    final String text = _unescape(raw);
    if (text.isNotEmpty) {
      runs.add(AretinoTextRun(text: text, style: base));
    }
  }

  for (final RegExpMatch m in tspanRe.allMatches(body)) {
    addPlain(body.substring(cursor, m.start));
    cursor = m.end;
    final Map<String, String> attrs = <String, String>{};
    for (final RegExpMatch a in attrRe.allMatches(m.group(1) ?? '')) {
      attrs[a.group(1)!] = _unescape(a.group(2)!);
    }
    AretinoTextStyle style = AretinoTextStyle(
      fontSize: base.fontSize,
      fontFamily: base.fontFamily,
      fontFamilyFallback: base.fontFamilyFallback,
      bold: base.bold || (attrs['font-weight'] ?? '') == 'bold',
      italic: base.italic || (attrs['font-style'] ?? '') == 'italic',
      smallCaps: base.smallCaps || (attrs['font-variant'] ?? '') == 'small-caps',
    );
    final RegExpMatch? em =
        RegExp(r'font-size\s*:\s*([\d.]+)em').firstMatch(attrs['style'] ?? '');
    if (em != null) {
      style = style.scaled(double.tryParse(em.group(1)!) ?? 1);
    }
    final String text = _unescape(m.group(2) ?? '');
    if (text.isNotEmpty) {
      runs.add(
        AretinoTextRun(
          text: text,
          style: style,
          color: AretinoInk.parse(attrs['fill']),
        ),
      );
    }
  }
  addPlain(body.substring(cursor));
  return runs;
}

String _unescape(String s) {
  if (!s.contains('&')) {
    return s;
  }
  return s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');
}

/// Parses an SVG path `d` attribute into a `Path`.
///
/// Covers the commands the library's glyph outlines use (`M L H V C S Z`, both
/// cases) plus quadratics and arcs, so a future glyph cannot silently vanish.
Path parseSvgPath(String d) {
  final Path path = Path();
  final RegExp tokenRe = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])|(-?[\d.]+(?:[eE][-+]?\d+)?)');
  final List<String> tokens = <String>[
    for (final RegExpMatch m in tokenRe.allMatches(d)) m.group(0)!,
  ];

  double cx = 0, cy = 0;
  double startX = 0, startY = 0;
  // Reflection point for smooth curve commands.
  double lastCtrlX = 0, lastCtrlY = 0;
  String? lastCmd;
  int i = 0;

  double next() {
    while (i < tokens.length && RegExp(r'^[A-Za-z]$').hasMatch(tokens[i])) {
      i++;
    }
    return i < tokens.length ? (double.tryParse(tokens[i++]) ?? 0) : 0;
  }

  bool moreNumbers() =>
      i < tokens.length && !RegExp(r'^[A-Za-z]$').hasMatch(tokens[i]);

  while (i < tokens.length) {
    String cmd;
    if (RegExp(r'^[A-Za-z]$').hasMatch(tokens[i])) {
      cmd = tokens[i++];
    } else if (lastCmd != null) {
      // An implicit repeat: after `M` the repeats are `L`.
      cmd = lastCmd == 'M' ? 'L' : (lastCmd == 'm' ? 'l' : lastCmd);
    } else {
      break;
    }
    lastCmd = cmd;
    final bool rel = cmd == cmd.toLowerCase();
    final String c = cmd.toUpperCase();

    switch (c) {
      case 'M':
        final double x = next(), y = next();
        cx = rel ? cx + x : x;
        cy = rel ? cy + y : y;
        path.moveTo(cx, cy);
        startX = cx;
        startY = cy;
        lastCtrlX = cx;
        lastCtrlY = cy;
        while (moreNumbers()) {
          final double nx = next(), ny = next();
          cx = rel ? cx + nx : nx;
          cy = rel ? cy + ny : ny;
          path.lineTo(cx, cy);
        }
      case 'L':
        do {
          final double x = next(), y = next();
          cx = rel ? cx + x : x;
          cy = rel ? cy + y : y;
          path.lineTo(cx, cy);
        } while (moreNumbers());
        lastCtrlX = cx;
        lastCtrlY = cy;
      case 'H':
        do {
          final double x = next();
          cx = rel ? cx + x : x;
          path.lineTo(cx, cy);
        } while (moreNumbers());
        lastCtrlX = cx;
        lastCtrlY = cy;
      case 'V':
        do {
          final double y = next();
          cy = rel ? cy + y : y;
          path.lineTo(cx, cy);
        } while (moreNumbers());
        lastCtrlX = cx;
        lastCtrlY = cy;
      case 'C':
        do {
          final double x1 = next(), y1 = next();
          final double x2 = next(), y2 = next();
          final double x = next(), y = next();
          final double c1x = rel ? cx + x1 : x1;
          final double c1y = rel ? cy + y1 : y1;
          final double c2x = rel ? cx + x2 : x2;
          final double c2y = rel ? cy + y2 : y2;
          final double ex = rel ? cx + x : x;
          final double ey = rel ? cy + y : y;
          path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
          lastCtrlX = c2x;
          lastCtrlY = c2y;
          cx = ex;
          cy = ey;
        } while (moreNumbers());
      case 'S':
        do {
          final double x2 = next(), y2 = next();
          final double x = next(), y = next();
          final double c1x = 2 * cx - lastCtrlX;
          final double c1y = 2 * cy - lastCtrlY;
          final double c2x = rel ? cx + x2 : x2;
          final double c2y = rel ? cy + y2 : y2;
          final double ex = rel ? cx + x : x;
          final double ey = rel ? cy + y : y;
          path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
          lastCtrlX = c2x;
          lastCtrlY = c2y;
          cx = ex;
          cy = ey;
        } while (moreNumbers());
      case 'Q':
        do {
          final double x1 = next(), y1 = next();
          final double x = next(), y = next();
          final double c1x = rel ? cx + x1 : x1;
          final double c1y = rel ? cy + y1 : y1;
          final double ex = rel ? cx + x : x;
          final double ey = rel ? cy + y : y;
          path.quadraticBezierTo(c1x, c1y, ex, ey);
          lastCtrlX = c1x;
          lastCtrlY = c1y;
          cx = ex;
          cy = ey;
        } while (moreNumbers());
      case 'T':
        do {
          final double x = next(), y = next();
          final double c1x = 2 * cx - lastCtrlX;
          final double c1y = 2 * cy - lastCtrlY;
          final double ex = rel ? cx + x : x;
          final double ey = rel ? cy + y : y;
          path.quadraticBezierTo(c1x, c1y, ex, ey);
          lastCtrlX = c1x;
          lastCtrlY = c1y;
          cx = ex;
          cy = ey;
        } while (moreNumbers());
      case 'A':
        do {
          final double rx = next(), ry = next();
          final double rot = next();
          final bool largeArc = next() != 0;
          final bool sweep = next() != 0;
          final double x = next(), y = next();
          final double ex = rel ? cx + x : x;
          final double ey = rel ? cy + y : y;
          path.arcToPoint(
            Offset(ex, ey),
            radius: Radius.elliptical(rx, ry),
            rotation: rot,
            largeArc: largeArc,
            clockwise: sweep,
          );
          cx = ex;
          cy = ey;
          lastCtrlX = cx;
          lastCtrlY = cy;
        } while (moreNumbers());
      case 'Z':
        path.close();
        cx = startX;
        cy = startY;
        lastCtrlX = cx;
        lastCtrlY = cy;
    }
  }
  return path;
}

/// Records a picture so it can be replayed cheaply. Kept as a `ui.Picture`
/// rather than a raster: resolution independence is the point.
ui.Picture recordAretinoPicture(
  AretinoPicture picture, {
  required Color inkColor,
}) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  picture.paint(canvas, inkColor: inkColor);
  return recorder.endRecording();
}
