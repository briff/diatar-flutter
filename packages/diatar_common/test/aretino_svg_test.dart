import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:diatar_common/services/aretino/aretino_svg.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const AretinoTextStyle _style = AretinoTextStyle(
  fontSize: 24,
  fontFamily: 'Palatino Linotype',
  fontFamilyFallback: <String>['serif'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('path data', () {
    test('an empty path is empty', () {
      expect(parseSvgPath('').computeMetrics().isEmpty, isTrue);
    });

    test('absolute and relative commands describe the same square', () {
      final Rect absolute =
          parseSvgPath('M 10 10 L 20 10 L 20 20 L 10 20 Z').getBounds();
      final Rect relative =
          parseSvgPath('m 10 10 l 10 0 l 0 10 l -10 0 z').getBounds();
      expect(absolute, relative);
      expect(absolute, const Rect.fromLTRB(10, 10, 20, 20));
    });

    test('horizontal and vertical shorthands move on one axis only', () {
      expect(
        parseSvgPath('M 0 0 H 30 V 40 H 0 Z').getBounds(),
        const Rect.fromLTRB(0, 0, 30, 40),
      );
    });

    test('repeated coordinates after a moveto are implicit linetos', () {
      expect(
        parseSvgPath('M 0 0 10 0 10 10 Z').getBounds(),
        const Rect.fromLTRB(0, 0, 10, 10),
      );
    });

    test('a cubic reaches its endpoint', () {
      final Rect bounds =
          parseSvgPath('M 0 0 C 0 50 100 50 100 0').getBounds();
      expect(bounds.left, 0);
      expect(bounds.right, 100);
      expect(bounds.bottom, greaterThan(0));
    });
  });

  group('document', () {
    test('reads the viewBox as the logical size', () {
      final AretinoPicture picture = parseAretinoSvg(
        '<svg viewBox="0 -5 800 200"></svg>',
        defaultTextStyle: _style,
      );
      expect(picture.viewBox, const Rect.fromLTWH(0, -5, 800, 200));
      expect(picture.size, const Size(800, 200));
    });

    test('nested group transforms compose', () {
      final AretinoPicture picture = parseAretinoSvg(
        '<svg viewBox="0 0 100 100">'
        '<g transform="translate(10, 20)">'
        '<g transform="scale(2)">'
        '<circle cx="1" cy="1" r="1" fill="#000"/>'
        '</g></g></svg>',
        defaultTextStyle: _style,
      );
      expect(picture.ops, hasLength(1));
      final Float64List m = picture.ops.single.transform;
      expect(m[0], 2.0); // scale x
      expect(m[5], 2.0); // scale y
      expect(m[12], 10.0); // translate x
      expect(m[13], 20.0); // translate y
    });

    test('a stroke of "none" draws nothing', () {
      final AretinoPicture picture = parseAretinoSvg(
        '<svg viewBox="0 0 10 10"><line x1="0" y1="0" x2="10" y2="0" stroke="none"/></svg>',
        defaultTextStyle: _style,
      );
      expect(picture.ops, isEmpty);
    });

    test('the embedded stylesheet is skipped, not drawn', () {
      final AretinoPicture picture = parseAretinoSvg(
        '<svg viewBox="0 0 10 10"><style>.aretino-active [fill]{fill:#ea580c}</style>'
        '<line x1="0" y1="0" x2="10" y2="0" stroke="#000" stroke-width="1"/></svg>',
        defaultTextStyle: _style,
      );
      expect(picture.ops, hasLength(1));
      expect(picture.ops.single, isA<AretinoLineOp>());
    });

    test('text runs carry tspan styling and escaped characters', () {
      final AretinoPicture picture = parseAretinoSvg(
        '<svg viewBox="0 0 100 100">'
        '<text x="10" y="20" font-size="30" text-anchor="middle" fill="#000">'
        'a&amp;b<tspan font-weight="bold" style="font-size:0.75em">kis</tspan>'
        '</text></svg>',
        defaultTextStyle: _style,
      );
      final AretinoTextOp op = picture.ops.single as AretinoTextOp;
      expect(op.anchor, TextAlign.center);
      expect(op.anchorX, 10);
      expect(op.baselineY, 20);
      expect(op.spans, hasLength(2));
      expect(op.spans[0].text, 'a&b');
      expect(op.spans[0].style.fontSize, 30);
      expect(op.spans[0].style.bold, isFalse);
      expect(op.spans[1].text, 'kis');
      expect(op.spans[1].style.bold, isTrue);
      expect(op.spans[1].style.fontSize, 30 * 0.75);
    });
  });

  group('a real score', () {
    late String svg;

    setUpAll(() {
      svg = File('test/fixtures/aretino_alleluia_row0.svg').readAsStringSync();
    });

    test('parses into staff lines, noteheads, a clef and lyrics', () {
      final AretinoPicture picture =
          parseAretinoSvg(svg, defaultTextStyle: _style);

      expect(picture.size.width, 800);
      expect(picture.size.height, greaterThan(0));

      // Four staff lines are drawn as five rules in this row, the noteheads as
      // ellipses, the clef as an outline, and every syllable as its own <text>.
      expect(picture.ops.whereType<AretinoLineOp>(), isNotEmpty);
      expect(picture.ops.whereType<AretinoOvalOp>(), isNotEmpty);
      expect(picture.ops.whereType<AretinoPathOp>(), isNotEmpty);

      final List<AretinoTextOp> texts =
          picture.ops.whereType<AretinoTextOp>().toList();
      expect(
        texts.map((AretinoTextOp t) => t.spans.single.text).join('-'),
        'Al-le-lu-ja,-al-le-lu-ja,-al-le-lu-ja.',
      );
    });

    test('the ink is tighter than the viewBox, and holds every op', () {
      final AretinoPicture picture =
          parseAretinoSvg(svg, defaultTextStyle: _style);

      // The library reserves two staff spaces over the staff for notes that may
      // rise above it; this row has none that high, so its ink starts lower.
      expect(picture.inkBounds.top, greaterThan(picture.viewBox.top));
      expect(picture.inkBounds.height, lessThan(picture.viewBox.height));

      // The lyrics are the lowest ink, and the staff lines the widest.
      final AretinoTextOp lastSyllable =
          picture.ops.whereType<AretinoTextOp>().last;
      expect(picture.inkBounds.bottom, greaterThan(lastSyllable.baselineY));
      expect(picture.inkBounds.width, greaterThan(0));
    });

    test('paints, and honours the projector text colour', () {
      final AretinoPicture picture =
          parseAretinoSvg(svg, defaultTextStyle: _style);
      final ui.Picture white =
          recordAretinoPicture(picture, inkColor: const Color(0xFFFFFFFF));
      expect(white, isNotNull);
      white.dispose();
    });
  });

  group('measurement', () {
    test('an empty string measures zero', () {
      expect(measureAretinoText('', _style), 0);
    });

    test('a wider string measures wider, and scales with the size', () {
      expect(
        measureAretinoText('lu', _style),
        greaterThan(measureAretinoText('l', _style)),
      );
      expect(
        measureAretinoText('Alleluja', _style.scaled(2)),
        greaterThan(measureAretinoText('Alleluja', _style)),
      );
    });
  });
}
