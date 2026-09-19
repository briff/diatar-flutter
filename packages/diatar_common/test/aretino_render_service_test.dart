import 'dart:convert';
import 'dart:typed_data';

import 'package:diatar_common/services/aretino/aretino_js_engine.dart';
import 'package:diatar_common/services/aretino/aretino_render_service.dart';
import 'package:diatar_common/services/aretino/aretino_svg.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every render with an empty score and remembers what it was asked.
class _FakeEngine implements AretinoJsEngine {
  final List<Map<String, Object?>> calls = <Map<String, Object?>>[];

  @override
  bool get isReady => true;

  @override
  Future<void> ensureLoaded() async {}

  @override
  String render(String argsJson) {
    calls.add(jsonDecode(argsJson) as Map<String, Object?>);
    return jsonEncode(<String, Object?>{'ok': true, 'rows': <String>[]});
  }

  @override
  void dispose() {}

  Map<String, Object?> get lastOptions =>
      calls.last['options']! as Map<String, Object?>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AretinoStyle defaults', () {
    const AretinoStyle style = AretinoStyle(lyricFontSize: 40);

    test('the staff is a quarter of the lyric size, not half', () {
      expect(style.notationScale, 0.25);
      // 40 px lyrics at 96 dpi: 10 px of staff space, in millimetres.
      expect(style.rendererOptions(800)['staffSpaceMm'], closeTo(2.6458, 1e-3));
    });

    test('no face is named, so the projection font is used', () {
      expect(style.fontFamily, isNull);
      expect(style.fontFamilyFallback, isEmpty);
      expect(style.textStyle.fontFamily, isNull);
      expect(style.cssFontFamily, 'sans-serif');
    });

    test('a named face still reaches the renderer quoted', () {
      const AretinoStyle named = AretinoStyle(
        lyricFontSize: 40,
        fontFamily: 'Palatino Linotype',
        fontFamilyFallback: <String>['serif'],
      );
      expect(named.cssFontFamily, "'Palatino Linotype', serif");
    });

    test('the repeated clef is hidden', () {
      expect(style.hideRepeatClef, isTrue);
      expect(style.rendererOptions(800)['hideRepeatClef'], isTrue);
    });
  });

  group('render options', () {
    const AretinoStyle style = AretinoStyle(lyricFontSize: 40);

    test('the default reaches the renderer', () {
      final _FakeEngine engine = _FakeEngine();
      AretinoRenderService(engine: engine)
          .render('c: c4\nw: A-men', width: 800, style: style);
      expect(engine.lastOptions['hideRepeatClef'], isTrue);
    });

    test('a score that states the option keeps its own value', () {
      final _FakeEngine engine = _FakeEngine();
      AretinoRenderService(engine: engine).render(
        '%option: hideRepeatClef=false\nc: c4\nw: A-men',
        width: 800,
        style: style,
      );
      // Passed options win over `%option:` headers inside the library, so ours
      // has to be absent for the score's to take effect.
      expect(engine.lastOptions.containsKey('hideRepeatClef'), isFalse);
    });

    test('geometry stays ours even when the score states it', () {
      final _FakeEngine engine = _FakeEngine();
      AretinoRenderService(engine: engine).render(
        '%option: lyricSize=6\nc: c4\nw: A-men',
        width: 800,
        style: style,
      );
      expect(engine.lastOptions['lyricSize'], 30.0);
    });

    test('widths are measured here, heights are left to the library', () {
      final _FakeEngine engine = _FakeEngine();
      AretinoRenderService(engine: engine)
          .render('c: c4\nw: A-men', width: 800, style: style);
      // The library hangs the lyrics from the ink the syllables carry. Flutter
      // could only offer the top of the line box, which sits well above the
      // letters and would leave a gap under every staff system.
      expect(engine.calls.last.containsKey('widths'), isTrue);
      expect(engine.calls.last.containsKey('ascents'), isFalse);
    });
  });

  group('stacking', () {
    /// A row whose ink is a rule from [top] to [bottom], inside a viewBox with
    /// the slack the library leaves above and below a staff system.
    AretinoPicture row(double top, double bottom) => AretinoPicture(
          ops: <AretinoOp>[
            AretinoLineOp(
              _identity(),
              from: Offset(0, top),
              to: Offset(100, bottom),
              stroke: const AretinoInk(Color(0xFF000000), true),
              strokeWidth: 0,
              cap: StrokeCap.butt,
            ),
          ],
          viewBox: Rect.fromLTWH(0, top - 20, 100, (bottom - top) + 32),
        );

    test('systems are spaced by their ink, not by their viewBox', () {
      const AretinoStyle style = AretinoStyle(lyricFontSize: 40, systemGap: 0.3);
      final AretinoRendering rendering = AretinoRendering(
        rows: <AretinoPicture>[row(100, 200), row(300, 360)],
        style: style,
        width: 800,
      );

      // 12 px of gap — 0.3 of a 40 px lyric — and nothing else between the ink
      // of one system and the ink of the next.
      expect(rendering.rowTops, <double>[0, 112]);
      expect(rendering.height, 112 + 60);
    });

    test('a score with no rows has no height', () {
      final AretinoRendering rendering = AretinoRendering(
        rows: const <AretinoPicture>[],
        style: const AretinoStyle(lyricFontSize: 40),
        width: 800,
      );
      expect(rendering.isEmpty, isTrue);
      expect(rendering.height, 0);
    });
  });
}

Float64List _identity() {
  final Float64List m = Float64List(16);
  m[0] = 1;
  m[5] = 1;
  m[10] = 1;
  m[15] = 1;
  return m;
}
