import 'dart:math' as math;
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/projection_frame.dart';
import '../models/projection_globals.dart';
import '../models/records.dart';
import '../services/aretino/aretino_render_cache.dart';
import '../services/aretino/aretino_render_service.dart';
import '../services/aretino/aretino_source.dart';
import '../services/aretino/aretino_svg.dart';

import 'chord_renderer.dart';
import 'kotta_assets.dart';

class HighlightRenderState {
  const HighlightRenderState({
    required this.maxWordIndex,
    required this.isFullyHighlighted,
  });

  final int maxWordIndex;
  final bool isFullyHighlighted;
}

class ProjectorPainter extends CustomPainter {
  static const int _layoutCacheLimit = 32;
  static const int _preparedLayoutCacheLimit = 16;
  static const int _wordMeasureCacheLimit = 2048;
  static const double _autoResizeBigStep = 0.05;
  static const double _autoResizeSmallStep = 0.005;
  static const double _minAutoFontSize = 8.0;
  static final LinkedHashMap<String, List<_TextRowLayout>> _textRowsCache =
      LinkedHashMap<String, List<_TextRowLayout>>();
  static final LinkedHashMap<String, List<_KottaRowLayout>> _kottaRowsCache =
      LinkedHashMap<String, List<_KottaRowLayout>>();
  static final LinkedHashMap<String, double> _textHeightCache =
      LinkedHashMap<String, double>();
  static final LinkedHashMap<String, _PreparedTextLayout> _preparedLayoutCache =
      LinkedHashMap<String, _PreparedTextLayout>();
  static final LinkedHashMap<String, List<_RenderLine>> _parsedLinesCache =
      LinkedHashMap<String, List<_RenderLine>>();
  static final LinkedHashMap<String, double> _wordWidthCache =
      LinkedHashMap<String, double>();

  ProjectorPainter({
    required this.frame,
    required this.globals,
    required this.settings,
    this.logoTitle = '',
    this.logoSubtitle = '',
    this.onHighlightRenderState,
    // An Aretino score is rendered off the paint path and arrives later, so
    // every projector surface repaints when one becomes ready. The notifier
    // only ever fires after a score render, so this costs nothing on a slide
    // that has no notation.
  }) : super(repaint: AretinoRenderCache.instance);

  final ProjectionFrame? frame;
  final ProjectionGlobals globals;
  final AppSettings settings;
  final String logoTitle;
  final String logoSubtitle;
  final ValueChanged<HighlightRenderState>? onHighlightRenderState;

  void _emitHighlightRenderState({
    required int maxWordIndex,
    required bool isFullyHighlighted,
  }) {
    onHighlightRenderState?.call(
      HighlightRenderState(
        maxWordIndex: maxWordIndex,
        isFullyHighlighted: isFullyHighlighted,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect full = Offset.zero & size;
    canvas.drawRect(full, Paint()..color = Colors.black);

    final double l = settings.clipL;
    final double t = settings.clipT;
    final double r = settings.clipR;
    final double b = settings.clipB;

    final Rect drawRect = Rect.fromLTWH(
      l,
      t,
      math.max(0, size.width - l - r),
      math.max(0, size.height - t - b),
    );

    canvas.save();
    canvas.clipRect(drawRect);
    canvas.translate(drawRect.left, drawRect.top);

    if (settings.mirror) {
      canvas.translate(drawRect.width, 0);
      canvas.scale(-1, 1);
    }

    final int rot = settings.rotateQuarterTurns % 4;
    if (rot != 0) {
      canvas.translate(drawRect.width / 2, drawRect.height / 2);
      canvas.rotate(rot * math.pi / 2);
      canvas.translate(-drawRect.width / 2, -drawRect.height / 2);
    }

    _drawContent(canvas, Size(drawRect.width, drawRect.height));
    canvas.restore();
  }

  // Computes exact required canvas height using the same wrapping/chord/kotta rules as paint.
  double measureRequiredHeight(Size size) {
    final ProjectionFrame? localFrame = frame;
    if (localFrame is! TextFrame) {
      return size.height;
    }
    final double contentHeight = _measureTextRequiredHeight(size, localFrame);
    return globals.vCenter ? contentHeight : contentHeight + 8;
  }

  List<String> debugKottaRowPrefixesForLine(
    String source, {
    double fontSize = 24,
    double maxWidth = 120,
  }) {
    final List<_RenderLine> lines = _parseOneLine(source);
    if (lines.isEmpty) {
      return const <String>[];
    }
    final List<_KottaRowLayout> rows = _buildKottaRows(
      lines.first,
      fontSize,
      maxWidth,
      inheritedState: _KottaDrawState(),
    );
    return rows.map((row) => row.prefix.kotta).toList();
  }

  int debugKottaStaffLineCountForLine(String source) {
    final List<_RenderLine> lines = _parseOneLine(source);
    if (lines.isEmpty) {
      return 5;
    }
    return _staffLineCountForLine(lines.first);
  }

  List<List<String>> debugKottaRowPrefixesForLines(
    List<String> sources, {
    double fontSize = 24,
    double maxWidth = 120,
  }) {
    final _KottaDrawState carryState = _KottaDrawState();
    final List<List<String>> result = <List<String>>[];
    for (final String source in sources) {
      final List<_RenderLine> lines = _parseOneLine(source);
      if (lines.isEmpty) {
        result.add(const <String>[]);
        continue;
      }
      final List<_KottaRowLayout> rows = _buildKottaRows(
        lines.first,
        fontSize,
        maxWidth,
        inheritedState: carryState,
      );
      result.add(rows.map((row) => row.prefix.kotta).toList());
      _advanceKottaStateForLine(
        lines.first,
        _kottaLineGap(fontSize),
        carryState,
      );
    }
    return result;
  }

  List<List<bool>> debugTieUnderlineFlagsForLine(
    String source, {
    double fontSize = 24,
    double maxWidth = 120,
  }) {
    final List<_RenderLine> lines = _parseOneLine(source);
    if (lines.isEmpty) {
      return const <List<bool>>[];
    }

    final List<_TextRowLayout> rows = _buildTextRows(
      lines.first,
      fontSize,
      maxWidth,
    );
    return rows
        .map(
          (row) => row.wordIndices
              .map((int wordIndex) => lines.first.words[wordIndex].tieUnderline)
              .toList(),
        )
        .toList();
  }

  List<List<bool>> debugTieUnderlineRowContinuationsForLine(
    String source, {
    double fontSize = 24,
    double maxWidth = 120,
  }) {
    final List<_RenderLine> lines = _parseOneLine(source);
    if (lines.isEmpty) {
      return const <List<bool>>[];
    }

    final _RenderLine line = lines.first;
    final List<_TextRowLayout> rows = _buildTextRows(line, fontSize, maxWidth);
    return rows.map((row) {
      if (row.wordIndices.isEmpty) {
        return const <bool>[false, false];
      }
      final int firstWord = row.wordIndices.first;
      final int lastWord = row.wordIndices.last;
      final bool fromPrevious =
          firstWord > 0 &&
          line.words[firstWord].tieUnderline &&
          line.words[firstWord - 1].tieUnderline;
      final bool toNext =
          lastWord + 1 < line.words.length &&
          line.words[lastWord].tieUnderline &&
          line.words[lastWord + 1].tieUnderline;
      return <bool>[fromPrevious, toNext];
    }).toList();
  }

  @visibleForTesting
  Offset debugSlurApexForPoints(
    List<Offset> points, {
    required bool down,
    double lineGap = 4.0,
  }) {
    return _resolveSlurApex(points, down: down, lineGap: lineGap);
  }

  @visibleForTesting
  double debugSlurYOffsetForDirection({
    required bool down,
    double lineGap = 4.0,
  }) {
    return _slurYOffset(down: down, lineGap: lineGap);
  }

  @visibleForTesting
  List<String> debugFullPipelineRowsForRecord({
    required Size size,
    required RecTextRecord record,
  }) {
    final TextFrame frame = TextFrame(record: record);
    final _AutoSizeResult auto = _resolveAutoSize(size, frame);
    final _PreparedTextLayout prepared = _prepareTextLayout(
      size,
      frame,
      auto.fontSize,
      preferPreferredBreaks: auto.preferPreferredBreaks,
    );
    final List<String> out = <String>[];
    for (int li = 0; li < prepared.lines.length; li++) {
      final _RenderLine line = prepared.lines[li];
      final bool hasKotta = prepared.hasKottaByLine[li];
      if (hasKotta) {
        for (final _KottaRowLayout r in prepared.kottaRowsByLine[li]) {
          out.add(
            'K<${r.width.toStringAsFixed(1)}> '
            '${r.words.map((w) => line.words[w.wordIndex].text + (line.words[w.wordIndex].spaceAfter ? ' ' : '')).join()}',
          );
        }
      } else {
        for (final _TextRowLayout r in prepared.textRowsByLine[li]) {
          out.add(
            'T<${r.width.toStringAsFixed(1)}/W${size.width.toStringAsFixed(1)}/F${auto.fontSize.toStringAsFixed(1)}> '
            '${r.wordIndices.map((int wi) => line.words[wi].text + (line.words[wi].spaceAfter ? ' ' : '')).join()}${r.endHyphen ? '-' : ''}',
          );
        }
      }
    }
    return out;
  }

  List<String> debugTextWrappedRowsForLine(
    String source, {
    double fontSize = 24,
    double maxWidth = 120,
  }) {
    final List<_RenderLine> lines = _parseOneLine(source);
    if (lines.isEmpty) {
      return const <String>[];
    }

    final List<_TextRowLayout> rows = _buildTextRows(
      lines.first,
      fontSize,
      maxWidth,
    );
    return rows
        .map(
          (row) =>
              row.wordIndices
                  .map((int wi) {
                    final _WordToken w = lines.first.words[wi];
                    return w.text + (w.spaceAfter ? ' ' : '');
                  })
                  .join()
                  .trimRight() +
              (row.endHyphen ? '-' : ''),
        )
        .toList();
  }

  List<double> debugKottaRowStartXsForLine(
    String source, {
    double fontSize = 24,
    double maxWidth = 120,
    double sizeWidth = 400,
    double horizontalPad = 16,
  }) {
    final List<_RenderLine> lines = _parseOneLine(source);
    if (lines.isEmpty) {
      return const <double>[];
    }
    final List<_KottaRowLayout> rows = _buildKottaRows(
      lines.first,
      fontSize,
      maxWidth,
      inheritedState: _KottaDrawState(),
    );
    if (rows.isEmpty) {
      return const <double>[];
    }
    final double blockStartX = _kottaRowsStartX(rows, sizeWidth, horizontalPad);
    return <double>[
      for (int i = 0; i < rows.length; i++)
        blockStartX + _kottaContinuationIndent(i, horizontalPad),
    ];
  }

  List<double> debugKottaVisibleStartXsForLine(
    String source, {
    double fontSize = 24,
    double maxWidth = 120,
    double sizeWidth = 400,
    double horizontalPad = 16,
  }) {
    final List<_RenderLine> lines = _parseOneLine(source);
    if (lines.isEmpty) {
      return const <double>[];
    }
    final List<_KottaRowLayout> rows = _buildKottaRows(
      lines.first,
      fontSize,
      maxWidth,
      inheritedState: _KottaDrawState(),
    );
    if (rows.isEmpty) {
      return const <double>[];
    }
    final List<_KottaRowPrefix> rowPrefixes = _resolveKottaRowPrefixes(
      rows,
      lines.first,
      _kottaLineGap(fontSize),
    );
    final double blockStartX = _kottaRowsStartX(rows, sizeWidth, horizontalPad);
    return <double>[
      for (int i = 0; i < rows.length; i++)
        rowPrefixes[i].kotta.isNotEmpty || rows[i].inlinePrefix.kotta.isNotEmpty
            ? blockStartX + _kottaContinuationIndent(i, horizontalPad)
            : blockStartX + _kottaContinuationIndent(i, horizontalPad),
    ];
  }

  List<double> debugKottaTextStartXsForLine(
    String source, {
    double fontSize = 24,
    double maxWidth = 120,
    double sizeWidth = 400,
    double horizontalPad = 16,
  }) {
    final List<_RenderLine> lines = _parseOneLine(source);
    if (lines.isEmpty) {
      return const <double>[];
    }
    final List<_KottaRowLayout> rows = _buildKottaRows(
      lines.first,
      fontSize,
      maxWidth,
      inheritedState: _KottaDrawState(),
    );
    if (rows.isEmpty) {
      return const <double>[];
    }
    final List<_KottaRowPrefix> rowPrefixes = _resolveKottaRowPrefixes(
      rows,
      lines.first,
      _kottaLineGap(fontSize),
    );
    final double blockStartX = _kottaRowsStartX(rows, sizeWidth, horizontalPad);
    return <double>[
      for (int i = 0; i < rows.length; i++)
        blockStartX +
            _kottaContinuationIndent(i, horizontalPad) +
            rowPrefixes[i].width +
            rows[i].inlinePrefix.width,
    ];
  }

  @visibleForTesting
  int debugKottaLetterConnectorCountForLine(
    String source, {
    double fontSize = 24,
    double maxWidth = 320,
  }) {
    final List<_RenderLine> lines = _parseOneLine(source);
    if (lines.isEmpty) {
      return 0;
    }

    final _RenderLine line = lines.first;
    final List<_KottaRowLayout> rows = _buildKottaRows(
      line,
      fontSize,
      maxWidth,
      inheritedState: _KottaDrawState(),
    );
    final TextPainter measure = TextPainter(textDirection: TextDirection.ltr);
    int count = 0;

    for (final _KottaRowLayout row in rows) {
      for (int i = 1; i < row.words.length; i++) {
        final _KottaWordLayout previousSlot = row.words[i - 1];
        final _KottaWordLayout currentSlot = row.words[i];
        final _WordToken previous = line.words[previousSlot.wordIndex];
        final _WordToken current = line.words[currentSlot.wordIndex];
        final double previousTextWidth = _measureWordDisplayWidth(
          previous,
          fontSize,
          measure,
        );
        if (_shouldPaintKottaLetterConnector(
          previous: previous,
          current: current,
          gap: previousSlot.slotWidth - previousTextWidth,
        )) {
          count++;
        }
      }
    }

    return count;
  }

  void _drawContent(Canvas canvas, Size size) {
    final ProjectionFrame? localFrame = frame;
    if (localFrame is LogoFrame) {
      _emitHighlightRenderState(maxWordIndex: 0, isFullyHighlighted: false);
      _drawLogo(canvas, size, localFrame.phase);
      return;
    }

    if (localFrame is TextFrame) {
      _drawText(canvas, size, localFrame);
      return;
    }

    if (localFrame is ImageFrame) {
      _emitHighlightRenderState(maxWordIndex: 0, isFullyHighlighted: false);
      _drawImage(canvas, size, localFrame, localFrame.bgMode);
      return;
    }

    _emitHighlightRenderState(maxWordIndex: 0, isFullyHighlighted: false);

    final Color blank = _colorWithTransparency(
      globals.blankColor,
      globals.blankTrans,
    );
    canvas.drawRect(Offset.zero & size, Paint()..color = blank);
  }

  void _drawLogo(Canvas canvas, Size size, int phase) {
    final Color bk = debugLogoBackgroundColorForPhase(phase);
    canvas.drawRect(Offset.zero & size, Paint()..color = bk);

    if (globals.hideTitle) {
      return;
    }

    const double titleFontSizeBase = 6.4;
    const double verFontSizeBase = 2.4;
    const double minFontSize = 8.0;

    final double titleFontSize = math
        .max(minFontSize, globals.titleSize * titleFontSizeBase)
        .toDouble();
    final double verFontSize = math
        .max(minFontSize, globals.titleSize * verFontSizeBase)
        .toDouble();

    final TextPainter titlePainter = TextPainter(
      text: TextSpan(
        text: logoTitle,
        style: TextStyle(
          color: const Color(0xFF434ECE),
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          shadows: const <Shadow>[
            Shadow(
              color: Color(0xFF404040),
              blurRadius: 10,
              offset: Offset(5, 5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.9);

    final TextPainter verPainter = TextPainter(
      text: TextSpan(
        text: logoSubtitle,
        style: TextStyle(color: Colors.white70, fontSize: verFontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.9);

    final Offset titlePos = Offset(
      (size.width - titlePainter.width) / 2,
      size.height * 0.42,
    );
    final Offset verPos = Offset(
      (size.width - verPainter.width) / 2,
      titlePos.dy + titlePainter.height + 12,
    );
    titlePainter.paint(canvas, titlePos);
    verPainter.paint(canvas, verPos);
  }

  Color debugLogoBackgroundColorForPhase(int phase) {
    const int maxRed = 0x4B;
    const int maxGreen = 0xEF;
    const int maxBlue = 0x96;

    int intensity;
    if (phase < 16 || phase >= 64) {
      intensity = 0;
    } else if (phase < 32) {
      intensity = phase - 16;
    } else if (phase < 48) {
      intensity = 16;
    } else {
      intensity = 64 - phase;
    }

    return Color.fromARGB(
      255,
      maxRed * intensity ~/ 16,
      maxGreen * intensity ~/ 16,
      maxBlue * intensity ~/ 16,
    );
  }

  /// Draws a Gregorian chant slide. The background is already painted.
  ///
  /// Nothing is rendered here: a prepared score is looked up in
  /// [AretinoRenderCache] and replayed, and a miss draws the words as plain
  /// text while the render runs (Decision 6). A projector never shows an empty
  /// screen waiting for JavaScript.
  void _drawAretino(Canvas canvas, Size size, TextFrame frame, String source) {
    _emitHighlightRenderState(maxWordIndex: 0, isFullyHighlighted: false);

    final double titleHeight = _drawAretinoTitle(canvas, size, frame);
    final Size target = Size(
      math.max(40, size.width),
      math.max(40, size.height - titleHeight),
    );

    final AretinoRenderKey key = AretinoRenderKey(
      source: source,
      width: target.width,
      height: target.height,
      style: AretinoStyle(lyricFontSize: globals.fontSize.toDouble()),
    );
    final AretinoRenderCache cache = AretinoRenderCache.instance;
    final AretinoRendering? rendering = cache.lookup(key);
    if (rendering == null) {
      cache.request(key);
      _drawAretinoLyrics(canvas, size, source, titleHeight);
      return;
    }

    final double contentHeight = rendering.height;
    double y =
        titleHeight +
        (globals.vCenter
            ? math.max(0, (target.height - contentHeight) / 2)
            : 0);
    for (int i = 0; i < rendering.rows.length; i++) {
      final AretinoPicture row = rendering.rows[i];
      final double x = globals.hCenter
          ? (size.width - row.size.width) / 2
          : globals.leftIndent.toDouble();
      canvas.save();
      // Horizontally each row keeps the width it was laid out against, so the
      // systems stay aligned with one another. Vertically they are stacked on
      // their ink, since the room the library reserves above a staff for notes
      // that may rise over it would otherwise show up as a gap under the
      // previous system's lyrics.
      canvas.translate(
        x - row.viewBox.left,
        y + rendering.rowTops[i] - row.inkBounds.top,
      );
      row.paint(canvas, inkColor: globals.txtColor);
      canvas.restore();
    }
  }

  /// Draws the slide title above a score, and returns the height it took.
  double _drawAretinoTitle(Canvas canvas, Size size, TextFrame frame) {
    if (globals.hideTitle || frame.record.title.trim().isEmpty) {
      return 0;
    }
    final double fontSize = (globals.titleSize.toDouble() * 2.5).clamp(
      8.0,
      72.0,
    );
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: frame.record.title,
        style: TextStyle(color: globals.txtColor, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
      textAlign: globals.hCenter ? TextAlign.center : TextAlign.left,
    )..layout(maxWidth: math.max(40, size.width));
    tp.paint(
      canvas,
      Offset(globals.hCenter ? (size.width - tp.width) / 2 : 0, 0),
    );
    final double height = tp.height;
    tp.dispose();
    return height;
  }

  /// The words of a chant, as plain text — what a slide shows while its score
  /// is still rendering, and what it falls back to if the render fails.
  void _drawAretinoLyrics(Canvas canvas, Size size, String source, double top) {
    final List<String> lines = AretinoSource.lyricLines(source);
    if (lines.isEmpty) {
      return;
    }
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: lines.join('\n'),
        style: TextStyle(
          color: globals.txtColor,
          fontSize: globals.fontSize.toDouble(),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: globals.hCenter ? TextAlign.center : TextAlign.left,
    )..layout(maxWidth: math.max(40, size.width));
    final double available = math.max(0, size.height - top);
    tp.paint(
      canvas,
      Offset(
        globals.hCenter ? (size.width - tp.width) / 2 : 0,
        top + (globals.vCenter ? math.max(0, (available - tp.height) / 2) : 0),
      ),
    );
    tp.dispose();
  }

  void _drawText(Canvas canvas, Size size, TextFrame frame) {
    final Color bg = _colorWithTransparency(globals.bkColor, globals.backTrans);
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    // A verse whose first line carries the `\?A` marker is a Gregorian chant in
    // Aretino notation. It travels as ordinary verse text inside the same
    // `text` record as everything else, and is rendered here, at this canvas's
    // own size — which is what makes it reflow to whatever screen it lands on
    // (plans/aretino-projection-v1.md, Decision 1).
    final String? aretino = AretinoSource.extract(frame.record.lines);
    if (aretino != null) {
      _drawAretino(canvas, size, frame, aretino);
      return;
    }

    const double horizontalPad = 0;
    final double maxWidth = math.max(40, size.width);

    final _AutoSizeResult autoSize = _resolveAutoSize(size, frame);
    final double fontSize = autoSize.fontSize;
    final bool preferPreferredBreaks = autoSize.preferPreferredBreaks;

    final _PreparedTextLayout prepared = _prepareTextLayout(
      size,
      frame,
      fontSize,
      preferPreferredBreaks: preferPreferredBreaks,
    );
    final bool hasTitleLine = prepared.hasTitleLine;
    final List<_RenderLine> allLines = prepared.lines;
    final double titleFontSize = prepared.titleFontSize;
    final double lineSpacing = globals.spacing100 / 100.0;

    final List<TextPainter> painters = <TextPainter>[];
    final List<List<bool>> highlightByLine = <List<bool>>[];
    int globalWordIndex = 0; // Track word index for highlighting (skips title)
    bool prevWordHadSpace = true;

    for (int lineIndex = 0; lineIndex < allLines.length; lineIndex++) {
      final _RenderLine line = allLines[lineIndex];
      final bool isTitleLine = hasTitleLine && lineIndex == 0;
      final double lineFontSize = isTitleLine ? titleFontSize : fontSize;
      final List<bool> lineHighlights = <bool>[];

      // Reset at each line boundary so the first word of the new line always
      // gets a new word index, regardless of whether the previous line's last
      // word had a trailing space.
      if (!isTitleLine) {
        prevWordHadSpace = true;
      }

      final List<InlineSpan> spans = <InlineSpan>[];
      for (int i = 0; i < line.words.length; i++) {
        final _WordToken word = line.words[i];

        // Update word index only on real word boundaries (spaceAfter), not syllable breaks.
        if (!isTitleLine && word.countAsWord) {
          final bool startsNewWord = prevWordHadSpace;
          if (startsNewWord) {
            globalWordIndex++;
          }
          prevWordHadSpace = word.spaceAfter;
        }

        // Highlight if index is <= wordToHighlight (and not title)
        final bool highlighted =
            !isTitleLine &&
            globals.wordToHighlight > 0 &&
            globalWordIndex <= globals.wordToHighlight;
        lineHighlights.add(highlighted);
        final Color baseColor = word.color ?? globals.txtColor;

        spans.add(
          TextSpan(
            text: word.text + (word.spaceAfter ? ' ' : ''),
            style: TextStyle(
              color: highlighted ? globals.hiColor : baseColor,
              fontSize: _effectiveWordFontSize(word, lineFontSize),
              fontWeight: (globals.boldText || word.bold)
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontStyle: word.italic ? FontStyle.italic : FontStyle.normal,
              decoration: TextDecoration.combine(<TextDecoration>[
                if (word.underline) TextDecoration.underline,
                if (word.strike) TextDecoration.lineThrough,
              ]),
            ),
          ),
        );
      }

      final TextPainter tp = TextPainter(
        text: TextSpan(children: spans),
        textDirection: TextDirection.ltr,
        textAlign: globals.hCenter ? TextAlign.center : TextAlign.left,
      )..layout(maxWidth: maxWidth);
      painters.add(tp);
      highlightByLine.add(lineHighlights);
    }

    _emitHighlightRenderState(
      maxWordIndex: globalWordIndex,
      isFullyHighlighted:
          globalWordIndex > 0 && globals.wordToHighlight >= globalWordIndex,
    );

    double totalHeight = 0;
    for (int i = 0; i < painters.length; i++) {
      final TextPainter tp = painters[i];
      final bool titleToKottaTransition =
          hasTitleLine && i == 1 && prepared.hasKottaByLine[i];
      if (titleToKottaTransition) {
        totalHeight += _titleToKottaTransitionGap(
          nextLineFontSize: fontSize,
          titleHeight: painters[i - 1].height,
          lineSpacing: lineSpacing,
        );
      }
      if (prepared.hasKottaByLine[i]) {
        final int rows = math.max(1, prepared.kottaRowsByLine[i].length);
        final bool isTitleLine = hasTitleLine && i == 0;
        final double lineFontSize = isTitleLine ? titleFontSize : fontSize;
        final double rowBlockHeight = _kottaRowBlockHeight(lineFontSize);
        totalHeight += rows * rowBlockHeight;
      } else {
        final bool isTitleLine = hasTitleLine && i == 0;
        if (isTitleLine) {
          totalHeight += prepared.chordBandByLine[i] + tp.height * lineSpacing;
        } else {
          final double lineFontSize = fontSize;
          final double textRowHeight = prepared.lineHeightsByLine[i];
          final List<_TextRowLayout> rows = prepared.textRowsByLine[i];
          if (rows.isEmpty) {
            totalHeight +=
                prepared.chordBandByLine[i] + textRowHeight * lineSpacing;
          } else {
            for (final _TextRowLayout row in rows) {
              totalHeight +=
                  _rowChordBandHeight(allLines[i], row, lineFontSize) +
                  textRowHeight * lineSpacing;
            }
          }
        }
      }
    }
    totalHeight += prepared.bottomTextDescent;
    double y = globals.vCenter ? (size.height - totalHeight) / 2 : 8;

    for (int painterIndex = 0; painterIndex < painters.length; painterIndex++) {
      final TextPainter tp = painters[painterIndex];
      final _RenderLine rline = allLines[painterIndex];
      final bool isTitleLine = hasTitleLine && painterIndex == 0;
      final bool hasKotta = prepared.hasKottaByLine[painterIndex];
      final double lineFontSize = isTitleLine ? titleFontSize : fontSize;
      final List<_KottaRowLayout> lineKottaRows =
          prepared.kottaRowsByLine[painterIndex];
      final double chordBand = prepared.chordBandByLine[painterIndex];
      final double lineStep = tp.height * lineSpacing;
      final List<_TextRowLayout> lineTextRows =
          prepared.textRowsByLine[painterIndex];

      final bool titleToKottaTransition =
          hasTitleLine && painterIndex == 1 && hasKotta;
      if (titleToKottaTransition) {
        y += _titleToKottaTransitionGap(
          nextLineFontSize: lineFontSize,
          titleHeight: painters[painterIndex - 1].height,
          lineSpacing: lineSpacing,
        );
      }

      if (!isTitleLine) {
        final double lineGap = _kottaLineGap(lineFontSize);
        final double staffHeight = _kottaStaffHeight(lineGap);
        final double ledgerReserve = _kottaLedgerReserve(lineGap);
        final double staffToTextGap = _kottaStaffToTextGap(lineGap);
        final double rowStep = _kottaRowBlockHeight(lineFontSize);
        final double continuationIndent = globals.hCenter
            ? 0
            : _textContinuationIndent(
                lineFontSize,
                TextPainter(textDirection: TextDirection.ltr),
              );
        final double firstTextY =
            y + ledgerReserve + staffHeight + staffToTextGap;
        _paintKotta(
          canvas,
          rline,
          firstTextY,
          rowStep,
          lineFontSize,
          maxWidth,
          size.width,
          continuationIndent,
          lineKottaRows,
        );

        if (hasKotta && lineKottaRows.isNotEmpty) {
          final List<_KottaRowPrefix> rowPrefixes = _resolveKottaRowPrefixes(
            lineKottaRows,
            rline,
            _kottaLineGap(lineFontSize),
          );
          final double kottaBlockX = _kottaRowsStartX(
            lineKottaRows,
            size.width,
            continuationIndent,
          );
          for (int rowIndex = 0; rowIndex < lineKottaRows.length; rowIndex++) {
            final _KottaRowLayout row = lineKottaRows[rowIndex];
            final _KottaRowPrefix rowPrefix = rowPrefixes[rowIndex];
            final double rowY = firstTextY + rowIndex * rowStep;
            final double rowX =
                kottaBlockX +
                _kottaContinuationIndent(rowIndex, continuationIndent);
            _paintKottaAlignedTextRow(
              canvas,
              rline,
              highlightByLine[painterIndex],
              row,
              rowX,
              rowY,
              lineFontSize,
              leadingInset: rowPrefix.width + row.inlinePrefix.width,
            );
          }
          final double chordY =
              firstTextY + (lineKottaRows.length - 1) * rowStep;
          final _KottaRowPrefix lastRowPrefix =
              rowPrefixes[lineKottaRows.length - 1];
          final _KottaRowLayout lastRow =
              lineKottaRows[lineKottaRows.length - 1];
          final double lastRowX =
              kottaBlockX +
              _kottaContinuationIndent(
                lineKottaRows.length - 1,
                continuationIndent,
              );
          _paintChords(
            canvas,
            rline,
            lastRowX + lastRowPrefix.width + lastRow.inlinePrefix.width,
            chordY,
            lineFontSize,
          );
          y += lineKottaRows.length * rowStep;
          continue;
        }
      }

      final double x = globals.hCenter
          ? (size.width - tp.width) / 2
          : horizontalPad;
      if (isTitleLine || lineTextRows.isEmpty) {
        final double textY = y + chordBand;
        tp.paint(canvas, Offset(x, textY));
        _paintChords(canvas, rline, x, textY, lineFontSize);
        y += chordBand + lineStep;
        continue;
      }

      final double rowHeight = prepared.lineHeightsByLine[painterIndex];
      for (final _TextRowLayout row in lineTextRows) {
        final List<_WordToken> rowWords = <_WordToken>[
          for (final int wi in row.wordIndices) rline.words[wi],
        ];
        final List<bool> rowHighlights = <bool>[
          for (final int wi in row.wordIndices)
            highlightByLine[painterIndex][wi],
        ];
        final _RenderLine rowLine = _RenderLine(words: rowWords);
        final double rowChordBand = _rowChordBandHeight(
          rline,
          row,
          lineFontSize,
        );
        final double rowX = globals.hCenter
            ? (size.width - row.width) / 2
            : horizontalPad + row.indentWidth;
        final double textY = y + rowChordBand;
        _paintTextRow(
          canvas,
          rowLine,
          rowHighlights,
          row.wordIndices,
          row.endHyphen,
          rowX,
          textY,
          lineFontSize,
        );
        _paintChords(canvas, rowLine, rowX, textY, lineFontSize);
        y += rowChordBand + rowHeight * lineSpacing;
      }
    }
  }

  double _measureTextRequiredHeight(Size size, TextFrame frame) {
    final _AutoSizeResult autoSize = _resolveAutoSize(size, frame);

    return _measureTextRequiredHeightForFontSize(
      size,
      frame,
      autoSize.fontSize,
      preferPreferredBreaks: autoSize.preferPreferredBreaks,
    );
  }

  _AutoSizeResult _resolveAutoSize(Size size, TextFrame frame) {
    final double baseFontSize = globals.fontSize.toDouble();
    if (!globals.autoResize || baseFontSize <= _minAutoFontSize) {
      return _AutoSizeResult(
        fontSize: baseFontSize,
        preferPreferredBreaks: true,
      );
    }

    final double fitHeight = size.height * 0.95;
    final int renderedLineCount = math.max(
      1,
      frame.record.lines.length +
          ((!globals.hideTitle && frame.record.title.isNotEmpty) ? 1 : 0),
    );
    final double theoreticalMaxFontSize = fitHeight / renderedLineCount;
    final double startFontSize = math
        .min(baseFontSize, theoreticalMaxFontSize)
        .clamp(_minAutoFontSize, baseFontSize);

    final double minScale = (_minAutoFontSize / startFontSize).clamp(0.01, 1.0);
    double sizeMul = 1.0;
    double step = _autoResizeBigStep;
    bool preferPreferredBreaks = true;

    int guard = 0;
    while (sizeMul >= minScale && guard++ < 300) {
      final double fontSize = (startFontSize * sizeMul).clamp(
        _minAutoFontSize,
        startFontSize,
      );

      final bool preferredFits =
          _measureTextRequiredHeightForFontSize(
            size,
            frame,
            fontSize,
            preferPreferredBreaks: true,
          ) <=
          fitHeight;
      final bool fallbackFits =
          preferredFits ||
          _measureTextRequiredHeightForFontSize(
                size,
                frame,
                fontSize,
                preferPreferredBreaks: false,
              ) <=
              fitHeight;

      if (preferredFits || fallbackFits) {
        preferPreferredBreaks = preferredFits;
        if (step == _autoResizeSmallStep) {
          return _AutoSizeResult(
            fontSize: fontSize,
            preferPreferredBreaks: preferPreferredBreaks,
          );
        }
        sizeMul += step;
        step = _autoResizeSmallStep;
      }

      sizeMul -= step;
    }

    final double fallbackFontSize = _minAutoFontSize.clamp(
      _minAutoFontSize,
      startFontSize,
    );
    final bool preferredFitsAtMin =
        _measureTextRequiredHeightForFontSize(
          size,
          frame,
          fallbackFontSize,
          preferPreferredBreaks: true,
        ) <=
        fitHeight;
    return _AutoSizeResult(
      fontSize: fallbackFontSize,
      preferPreferredBreaks: preferredFitsAtMin,
    );
  }

  _PreparedTextLayout _prepareTextLayout(
    Size size,
    TextFrame frame,
    double fontSize, {
    required bool preferPreferredBreaks,
  }) {
    final String cacheKey = _preparedTextLayoutCacheKey(
      size,
      frame,
      fontSize,
      preferPreferredBreaks,
    );
    final _PreparedTextLayout? cached = _preparedLayoutCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final double maxWidth = math.max(40, size.width);
    final bool hasTitleLine =
        !globals.hideTitle && frame.record.title.isNotEmpty;
    final List<String> sourceLines = <String>[
      if (hasTitleLine) frame.record.title,
      ...frame.record.lines,
    ];
    final List<_RenderLine> allLines = _parseRenderLines(sourceLines);

    final double requestedTitleFontSize = (globals.titleSize.toDouble() * 2.5)
        .clamp(8.0, 72.0);
    final double titleFontSize = math
        .min(requestedTitleFontSize, fontSize)
        .clamp(8.0, 72.0);

    final List<List<_TextRowLayout>> textRowsByLine = <List<_TextRowLayout>>[];
    final List<bool> hasKottaByLine = <bool>[];
    final List<double> chordBandByLine = <double>[];
    final List<List<_KottaRowLayout>> kottaRowsByLine =
        <List<_KottaRowLayout>>[];
    final List<double> lineHeightsByLine = <double>[];
    final _KottaDrawState carryKottaState = _KottaDrawState();

    for (int lineIndex = 0; lineIndex < allLines.length; lineIndex++) {
      final _RenderLine baseLine = allLines[lineIndex];
      final bool isTitleLine = hasTitleLine && lineIndex == 0;
      final double lineFontSize = isTitleLine ? titleFontSize : fontSize;
      final bool hasKotta =
          !isTitleLine &&
          globals.useKotta &&
          settings.receiverUseKotta &&
          baseLine.words.any((w) => (w.kotta ?? '').isNotEmpty);
      final _RenderLine line;
      if (!isTitleLine && !hasKotta) {
        final _RenderLine paddedLine = _applyChordPadding(
          baseLine,
          lineFontSize,
        );
        final double continuationIndent = globals.hCenter
            ? 0
            : _textContinuationIndent(
                lineFontSize,
                TextPainter(textDirection: TextDirection.ltr),
              );
        line = _splitOverlongWords(
          paddedLine,
          lineFontSize,
          maxWidth,
          continuationIndent: continuationIndent,
        );
      } else {
        line = baseLine;
      }
      allLines[lineIndex] = line;

      final double chordBand = (!isTitleLine && !hasKotta)
          ? _lineChordBandHeight(line, lineFontSize)
          : 0;
      final List<_KottaRowLayout> lineKottaRows = hasKotta
          ? _buildKottaRows(
              line,
              lineFontSize,
              maxWidth,
              inheritedState: carryKottaState,
            )
          : const <_KottaRowLayout>[];
      final List<_TextRowLayout> lineTextRows = (!isTitleLine && !hasKotta)
          ? _buildTextRows(
              line,
              lineFontSize,
              maxWidth,
              preferPreferredBreaks: preferPreferredBreaks,
            )
          : const <_TextRowLayout>[];

      textRowsByLine.add(lineTextRows);
      hasKottaByLine.add(hasKotta);
      chordBandByLine.add(chordBand);
      kottaRowsByLine.add(lineKottaRows);
      if (hasKotta) {
        _advanceKottaStateForLine(
          line,
          _kottaLineGap(lineFontSize),
          carryKottaState,
        );
      }
      lineHeightsByLine.add(_measureTextRowHeight(line, lineFontSize));
    }

    final int lastLineIndex = allLines.length - 1;
    final double bottomTextDescent =
        lastLineIndex >= 0 &&
            !hasKottaByLine[lastLineIndex] &&
            !(hasTitleLine && lastLineIndex == 0)
        ? _measureTextRowDescent(allLines[lastLineIndex], fontSize)
        : 0;

    final _PreparedTextLayout prepared = _PreparedTextLayout(
      hasTitleLine: hasTitleLine,
      titleFontSize: titleFontSize,
      lines: List<_RenderLine>.unmodifiable(allLines),
      textRowsByLine: List<List<_TextRowLayout>>.unmodifiable(
        textRowsByLine.map((rows) => List<_TextRowLayout>.unmodifiable(rows)),
      ),
      hasKottaByLine: List<bool>.unmodifiable(hasKottaByLine),
      chordBandByLine: List<double>.unmodifiable(chordBandByLine),
      kottaRowsByLine: List<List<_KottaRowLayout>>.unmodifiable(
        kottaRowsByLine.map((rows) => List<_KottaRowLayout>.unmodifiable(rows)),
      ),
      lineHeightsByLine: List<double>.unmodifiable(lineHeightsByLine),
      bottomTextDescent: bottomTextDescent,
    );

    _preparedLayoutCache[cacheKey] = prepared;
    while (_preparedLayoutCache.length > _preparedLayoutCacheLimit) {
      _preparedLayoutCache.remove(_preparedLayoutCache.keys.first);
    }
    return prepared;
  }

  double _measureTextRequiredHeightForFontSize(
    Size size,
    TextFrame frame,
    double fontSize, {
    bool preferPreferredBreaks = true,
  }) {
    final String cacheKey = _measureTextHeightCacheKey(
      size,
      frame,
      fontSize,
      preferPreferredBreaks,
    );
    final double? cached = _textHeightCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final _PreparedTextLayout prepared = _prepareTextLayout(
      size,
      frame,
      fontSize,
      preferPreferredBreaks: preferPreferredBreaks,
    );

    final bool hasTitleLine = prepared.hasTitleLine;
    final List<_RenderLine> allLines = prepared.lines;
    final double titleFontSize = prepared.titleFontSize;
    final double lineSpacing = globals.spacing100 / 100.0;

    double totalHeight = 0;
    for (int i = 0; i < allLines.length; i++) {
      final bool titleToKottaTransition =
          hasTitleLine && i == 1 && prepared.hasKottaByLine[i];
      if (titleToKottaTransition) {
        totalHeight += _titleToKottaTransitionGap(
          nextLineFontSize: fontSize,
          titleHeight: prepared.lineHeightsByLine[i - 1],
          lineSpacing: lineSpacing,
        );
      }

      if (prepared.hasKottaByLine[i]) {
        final int rows = math.max(1, prepared.kottaRowsByLine[i].length);
        final bool isTitleLine = hasTitleLine && i == 0;
        final double lineFontSize = isTitleLine ? titleFontSize : fontSize;
        final double rowBlockHeight = _kottaRowBlockHeight(lineFontSize);
        totalHeight += rows * rowBlockHeight;
      } else {
        final bool isTitleLine = hasTitleLine && i == 0;
        if (isTitleLine) {
          totalHeight +=
              prepared.chordBandByLine[i] +
              prepared.lineHeightsByLine[i] * lineSpacing;
        } else {
          final double lineFontSize = fontSize;
          final List<_TextRowLayout> rows = prepared.textRowsByLine[i];
          final double lineTextHeight = prepared.lineHeightsByLine[i];
          if (rows.isEmpty) {
            totalHeight +=
                prepared.chordBandByLine[i] + lineTextHeight * lineSpacing;
          } else {
            for (final _TextRowLayout row in rows) {
              totalHeight +=
                  _rowChordBandHeight(allLines[i], row, lineFontSize) +
                  lineTextHeight * lineSpacing;
            }
          }
        }
      }
    }

    totalHeight += prepared.bottomTextDescent;
    _textHeightCache[cacheKey] = totalHeight;
    while (_textHeightCache.length > _layoutCacheLimit) {
      _textHeightCache.remove(_textHeightCache.keys.first);
    }
    return totalHeight;
  }

  double _lineChordBandHeight(_RenderLine line, double fontSize) {
    if (!globals.useAkkord ||
        !settings.receiverUseAkkord ||
        !line.words.any((w) => (w.chord ?? '').isNotEmpty)) {
      return 0;
    }
    return _chordBandHeightForFont(fontSize);
  }

  double _chordBandHeightForFont(double fontSize) {
    final ChordLayout chordMeasure = ChordRenderer.layout(
      'C7',
      TextStyle(
        color: globals.txtColor,
        fontSize: fontSize * (globals.akkordArany / 100.0),
      ),
    );
    return chordMeasure.height + 2;
  }

  double _rowChordBandHeight(
    _RenderLine line,
    _TextRowLayout row,
    double fontSize,
  ) {
    if (!globals.useAkkord || !settings.receiverUseAkkord) {
      return 0;
    }
    for (final int wi in row.wordIndices) {
      if (wi >= 0 &&
          wi < line.words.length &&
          (line.words[wi].chord ?? '').isNotEmpty) {
        return _chordBandHeightForFont(fontSize);
      }
    }
    return 0;
  }

  double _measureTextRowHeight(_RenderLine line, double fontSize) {
    return _buildTextRowMeasure(line, fontSize).height;
  }

  double _measureTextRowDescent(_RenderLine line, double fontSize) {
    final TextPainter tp = _buildTextRowMeasure(line, fontSize);
    final List<ui.LineMetrics> metrics = tp.computeLineMetrics();
    return metrics.isEmpty ? 0 : metrics.last.descent;
  }

  TextPainter _buildTextRowMeasure(_RenderLine line, double fontSize) {
    final List<InlineSpan> spans = <InlineSpan>[];
    for (final _WordToken word in line.words) {
      final Color baseColor = word.color ?? globals.txtColor;
      spans.add(
        TextSpan(
          text: word.text + (word.spaceAfter ? ' ' : ''),
          style: TextStyle(
            color: baseColor,
            fontSize: _effectiveWordFontSize(word, fontSize),
            fontWeight: (globals.boldText || word.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: word.italic ? FontStyle.italic : FontStyle.normal,
            decoration: TextDecoration.combine(<TextDecoration>[
              if (word.underline) TextDecoration.underline,
              if (word.strike) TextDecoration.lineThrough,
            ]),
          ),
        ),
      );
    }
    final TextPainter tp = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
      textAlign: globals.hCenter ? TextAlign.center : TextAlign.left,
    )..layout();
    return tp;
  }

  void _paintTextRow(
    Canvas canvas,
    _RenderLine rowLine,
    List<bool> rowHighlights,
    List<int> rowWordIndices,
    bool drawEndHyphen,
    double x,
    double y,
    double fontSize,
  ) {
    final _TextRowPaintLayout layout = _buildTextRowPaintLayout(
      rowLine,
      rowHighlights,
      fontSize,
    );
    layout.painter.paint(canvas, Offset(x, y));
    _paintTieUnderlines(
      canvas,
      layout,
      rowLine.words,
      rowWordIndices,
      x,
      y,
      fontSize,
    );
    if (drawEndHyphen && rowLine.words.isNotEmpty) {
      final _WordToken lastWord = rowLine.words.last;
      final bool highlighted = rowHighlights.isNotEmpty
          ? rowHighlights.last
          : false;
      final Color baseColor = lastWord.color ?? globals.txtColor;
      final TextPainter hyphen = TextPainter(
        text: TextSpan(
          text: '-',
          style: TextStyle(
            color: highlighted ? globals.hiColor : baseColor,
            fontSize: _effectiveWordFontSize(lastWord, fontSize),
            fontWeight: (globals.boldText || lastWord.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: lastWord.italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hyphen.paint(canvas, Offset(x + layout.painter.width, y));
    }
  }

  _TextRowPaintLayout _buildTextRowPaintLayout(
    _RenderLine rowLine,
    List<bool> rowHighlights,
    double fontSize,
  ) {
    final List<InlineSpan> spans = <InlineSpan>[];
    final List<_TextWordLayout> wordLayouts = <_TextWordLayout>[];
    int offset = 0;

    for (int i = 0; i < rowLine.words.length; i++) {
      final _WordToken word = rowLine.words[i];
      final bool highlighted = i < rowHighlights.length
          ? rowHighlights[i]
          : false;
      final String display = word.text + (word.spaceAfter ? ' ' : '');
      final Color baseColor = word.color ?? globals.txtColor;
      spans.add(
        TextSpan(
          text: display,
          style: TextStyle(
            color: highlighted ? globals.hiColor : baseColor,
            fontSize: _effectiveWordFontSize(word, fontSize),
            fontWeight: (globals.boldText || word.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: word.italic ? FontStyle.italic : FontStyle.normal,
            decoration: TextDecoration.combine(<TextDecoration>[
              if (word.underline) TextDecoration.underline,
              if (word.strike) TextDecoration.lineThrough,
            ]),
          ),
        ),
      );
      wordLayouts.add(
        _TextWordLayout(
          start: offset,
          end: offset + display.length,
          tieUnderline: word.tieUnderline,
          color: baseColor,
        ),
      );
      offset += display.length;
    }

    final TextPainter painter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
      textAlign: globals.hCenter ? TextAlign.center : TextAlign.left,
    )..layout();
    return _TextRowPaintLayout(painter: painter, wordLayouts: wordLayouts);
  }

  void _paintTieUnderlines(
    Canvas canvas,
    _TextRowPaintLayout layout,
    List<_WordToken> rowWords,
    List<int> rowWordIndices,
    double x,
    double y,
    double fontSize,
  ) {
    final List<ui.LineMetrics> metrics = layout.painter.computeLineMetrics();
    if (metrics.isEmpty) {
      return;
    }

    final ui.LineMetrics metric = metrics.first;
    final double underlineY =
        y + metric.baseline + math.max(1.0, fontSize * 0.08);
    final double thickness = math.max(1.0, fontSize * 0.045);
    final double capLength = math.max(thickness * 2.5, fontSize * 0.22);
    final double capLift = math.max(thickness * 1.8, fontSize * 0.11);

    int index = 0;
    while (index < layout.wordLayouts.length) {
      final _TextWordLayout startLayout = layout.wordLayouts[index];
      if (!startLayout.tieUnderline) {
        index++;
        continue;
      }

      int runEnd = index;
      while (runEnd + 1 < layout.wordLayouts.length &&
          layout.wordLayouts[runEnd + 1].tieUnderline) {
        runEnd++;
      }

      final _TextWordLayout endLayout = layout.wordLayouts[runEnd];
      final List<ui.TextBox> startBoxes = layout.painter.getBoxesForSelection(
        TextSelection(
          baseOffset: startLayout.start,
          extentOffset: startLayout.end,
        ),
      );
      final List<ui.TextBox> endBoxes = layout.painter.getBoxesForSelection(
        TextSelection(baseOffset: endLayout.start, extentOffset: endLayout.end),
      );
      if (startBoxes.isEmpty || endBoxes.isEmpty) {
        index = runEnd + 1;
        continue;
      }

      final int startWordIndex = rowWordIndices[index];
      final int endWordIndex = rowWordIndices[runEnd];
      final bool continuedFromPrevious =
          index == 0 &&
          startWordIndex > 0 &&
          rowWords[startWordIndex - 1].tieUnderline;
      final bool continuesToNext =
          runEnd + 1 == layout.wordLayouts.length &&
          endWordIndex + 1 < rowWords.length &&
          rowWords[endWordIndex + 1].tieUnderline;

      final double startX = x + startBoxes.first.left;
      final double endX = x + endBoxes.last.right;
      final double bodyStart = continuedFromPrevious
          ? startX
          : math.min(startX + capLength, endX);
      final double bodyEnd = continuesToNext
          ? endX
          : math.max(bodyStart, endX - capLength);

      final Paint bodyPaint = Paint()
        ..color = startLayout.color
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawLine(
        Offset(bodyStart, underlineY),
        Offset(bodyEnd, underlineY),
        bodyPaint,
      );

      if (!continuedFromPrevious) {
        _paintTieCap(
          canvas,
          bodyStart,
          startX,
          underlineY,
          capLift,
          thickness,
          startLayout.color,
          left: true,
        );
      }
      if (!continuesToNext) {
        _paintTieCap(
          canvas,
          bodyEnd,
          endX,
          underlineY,
          capLift,
          thickness,
          startLayout.color,
          left: false,
        );
      }

      index = runEnd + 1;
    }
  }

  void _paintKottaTieUnderlines(
    Canvas canvas, {
    required List<_WordToken> sourceWords,
    required List<_KottaTextSlotLayout> slots,
    required double y,
    required double fontSize,
  }) {
    if (slots.isEmpty) {
      return;
    }

    final TextPainter measure = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: globals.boldText ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final ui.LineMetrics metric = measure.computeLineMetrics().first;
    final double underlineY =
        y + metric.baseline + math.max(1.0, fontSize * 0.08);
    final double thickness = math.max(1.0, fontSize * 0.045);
    final double capLength = math.max(thickness * 2.5, fontSize * 0.22);
    final double capLift = math.max(thickness * 1.8, fontSize * 0.11);

    int index = 0;
    while (index < slots.length) {
      final _KottaTextSlotLayout startSlot = slots[index];
      if (!startSlot.tieUnderline) {
        index++;
        continue;
      }

      int runEnd = index;
      while (runEnd + 1 < slots.length && slots[runEnd + 1].tieUnderline) {
        runEnd++;
      }

      final _KottaTextSlotLayout endSlot = slots[runEnd];
      final bool continuedFromPrevious =
          index == 0 &&
          startSlot.wordIndex > 0 &&
          sourceWords[startSlot.wordIndex - 1].tieUnderline;
      final bool continuesToNext =
          runEnd + 1 == slots.length &&
          endSlot.wordIndex + 1 < sourceWords.length &&
          sourceWords[endSlot.wordIndex + 1].tieUnderline;

      final double startX = startSlot.left;
      final double endX = endSlot.right;
      final double bodyStart = continuedFromPrevious
          ? startX
          : math.min(startX + capLength, endX);
      final double bodyEnd = continuesToNext
          ? endX
          : math.max(bodyStart, endX - capLength);

      final Paint bodyPaint = Paint()
        ..color = startSlot.color
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawLine(
        Offset(bodyStart, underlineY),
        Offset(bodyEnd, underlineY),
        bodyPaint,
      );

      if (!continuedFromPrevious) {
        _paintTieCap(
          canvas,
          bodyStart,
          startX,
          underlineY,
          capLift,
          thickness,
          startSlot.color,
          left: true,
        );
      }
      if (!continuesToNext) {
        _paintTieCap(
          canvas,
          bodyEnd,
          endX,
          underlineY,
          capLift,
          thickness,
          startSlot.color,
          left: false,
        );
      }

      index = runEnd + 1;
    }
  }

  void _paintTieCap(
    Canvas canvas,
    double bodyEdgeX,
    double tipX,
    double baselineY,
    double capLift,
    double thickness,
    Color color, {
    required bool left,
  }) {
    final double direction = left ? -1.0 : 1.0;
    final double controlX1 = bodyEdgeX + direction * thickness * 0.8;
    final double controlX2 =
        bodyEdgeX + direction * math.max(thickness * 1.6, capLift * 0.45);
    final Path path = Path()
      ..moveTo(bodyEdgeX, baselineY)
      ..cubicTo(
        controlX1,
        baselineY - thickness * 0.15,
        controlX2,
        baselineY - capLift,
        tipX,
        baselineY - capLift * 0.95,
      )
      ..cubicTo(
        controlX2,
        baselineY - capLift * 0.15,
        controlX1,
        baselineY + thickness * 0.2,
        bodyEdgeX,
        baselineY,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  _RenderLine _applyChordPadding(_RenderLine line, double fontSize) {
    if (!globals.useAkkord ||
        !settings.receiverUseAkkord ||
        line.words.isEmpty) {
      return line;
    }

    final TextPainter measure = TextPainter(textDirection: TextDirection.ltr);
    bool changed = false;
    final List<_WordToken> padded = <_WordToken>[];

    for (final _WordToken word in line.words) {
      final String chordText = (word.chord ?? '').trim();
      if (chordText.isEmpty) {
        padded.add(word);
        continue;
      }

      measure.text = TextSpan(
        text: word.text + (word.spaceAfter ? ' ' : ''),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: (globals.boldText || word.bold)
              ? FontWeight.bold
              : FontWeight.normal,
          fontStyle: word.italic ? FontStyle.italic : FontStyle.normal,
        ),
      );
      measure.layout();
      double textWidth = measure.width;

      final ChordLayout chord = ChordRenderer.layout(
        chordText,
        TextStyle(
          color: globals.txtColor,
          fontSize: fontSize * (globals.akkordArany / 100.0),
        ),
      );
      final double chordWidth = chord.width;

      if (textWidth + 1 >= chordWidth) {
        padded.add(word);
        continue;
      }

      String paddedText = word.text;
      int guard = 0;
      while (textWidth + 1 < chordWidth && guard < 24) {
        paddedText = '${paddedText}_';
        measure.text = TextSpan(
          text: paddedText + (word.spaceAfter ? ' ' : ''),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: (globals.boldText || word.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: word.italic ? FontStyle.italic : FontStyle.normal,
          ),
        );
        measure.layout();
        textWidth = measure.width;
        guard++;
      }

      if (paddedText != word.text) {
        changed = true;
        padded.add(
          _WordToken(
            text: paddedText,
            bold: word.bold,
            italic: word.italic,
            underline: word.underline,
            tieUnderline: word.tieUnderline,
            strike: word.strike,
            color: word.color,
            chord: word.chord,
            kotta: word.kotta,
            spaceAfter: word.spaceAfter,
            breakAfter: word.breakAfter,
            preferredBreakAfter: word.preferredBreakAfter,
            softHyphenAfter: word.softHyphenAfter,
            fontScale: word.fontScale,
          ),
        );
      } else {
        padded.add(word);
      }
    }

    if (!changed) {
      return line;
    }
    return _RenderLine(words: padded);
  }

  _RenderLine _splitOverlongWords(
    _RenderLine line,
    double fontSize,
    double maxWidth, {
    required double continuationIndent,
  }) {
    if (line.words.isEmpty) {
      return line;
    }

    final TextPainter measure = TextPainter(textDirection: TextDirection.ltr);
    final double splitLimit = math.max(8.0, maxWidth - continuationIndent);
    const double minWordScale = 0.82;
    const double minWordScaleFallback = 0.62;
    bool changed = false;
    final List<_WordToken> words = <_WordToken>[];

    for (final _WordToken word in line.words) {
      final double width = _measureWordDisplayWidth(word, fontSize, measure);
      if (width <= splitLimit || word.text.characters.length <= 1) {
        words.add(word);
        continue;
      }

      final _WordToken? shrunk = _shrinkWordToFitWidth(
        word,
        fontSize,
        splitLimit,
        minWordScale,
        measure,
        currentWidth: width,
      );
      if (shrunk != null) {
        changed = true;
        words.add(shrunk);
        continue;
      }

      // Prefer per-word downsizing over forced word-splitting.
      final _WordToken? fallbackShrunk = _shrinkWordToFitWidth(
        word,
        fontSize,
        splitLimit,
        minWordScaleFallback,
        measure,
        currentWidth: width,
      );
      if (fallbackShrunk != null) {
        changed = true;
        words.add(fallbackShrunk);
        continue;
      }

      final List<_WordToken> chunks = _splitWordToFitWidth(
        word,
        fontSize,
        splitLimit,
        measure,
      );
      if (chunks.length <= 1) {
        words.add(word);
        continue;
      }

      changed = true;
      words.addAll(chunks);
    }

    return changed ? _RenderLine(words: words) : line;
  }

  _WordToken? _shrinkWordToFitWidth(
    _WordToken word,
    double fontSize,
    double maxWidth,
    double minWordScale,
    TextPainter measure, {
    required double currentWidth,
  }) {
    if ((word.chord ?? '').trim().isNotEmpty ||
        (word.kotta ?? '').trim().isNotEmpty) {
      return null;
    }
    if (word.fontScale <= minWordScale) {
      return null;
    }

    final double targetScale = (word.fontScale * (maxWidth / currentWidth))
        .clamp(minWordScale, 1.0);
    if ((word.fontScale - targetScale).abs() < 0.001) {
      return null;
    }

    final _WordToken scaled = _WordToken(
      text: word.text,
      bold: word.bold,
      italic: word.italic,
      underline: word.underline,
      tieUnderline: word.tieUnderline,
      strike: word.strike,
      color: word.color,
      chord: word.chord,
      kotta: word.kotta,
      spaceAfter: word.spaceAfter,
      breakAfter: word.breakAfter,
      preferredBreakAfter: word.preferredBreakAfter,
      softHyphenAfter: word.softHyphenAfter,
      fontScale: targetScale,
    );

    final double scaledWidth = _measureWordDisplayWidth(
      scaled,
      fontSize,
      measure,
    );
    return scaledWidth <= maxWidth + 0.5 ? scaled : null;
  }

  // Shrinks the lyric text of a kotta-bearing word so that its slot width
  // (the larger of the text and the melody glyph width) fits the row limit.
  // Unlike _shrinkWordToFitWidth, words carrying kotta are allowed, because the
  // melody itself cannot be split across rows safely.
  _WordToken? _shrinkKottaWordToFit(
    _WordToken word,
    double fontSize,
    double kottaWidth,
    double currentWidth,
    double maxWidth,
    TextPainter measure,
  ) {
    final double textScale = (word.fontScale * (maxWidth / currentWidth)).clamp(
      0.55,
      1.0,
    );
    _WordToken candidate = _copyWithFontScale(word, textScale);
    double scaledTextWidth = _measureWordDisplayWidth(
      candidate,
      fontSize,
      measure,
    );

    // The melody glyphs do not scale with fontScale, so if the melody alone is
    // wider than the limit we cannot make it fit by shrinking.
    if (textScale * currentWidth <= maxWidth + 0.5 ||
        scaledTextWidth <= maxWidth + 0.5) {
      return candidate;
    }

    // Binary-search a scale that fits the text-driven slot width.
    double lo = 0.55;
    double hi = word.fontScale;
    _WordToken? best;
    while (hi - lo > 0.005) {
      final double mid = (lo + hi) / 2;
      candidate = _copyWithFontScale(word, mid);
      scaledTextWidth = _measureWordDisplayWidth(candidate, fontSize, measure);
      if (scaledTextWidth <= maxWidth + 0.5) {
        best = candidate;
        hi = mid;
      } else {
        lo = mid;
      }
    }
    if (best != null) {
      return best;
    }
    if (textScale < word.fontScale - 0.001) {
      return _copyWithFontScale(word, textScale);
    }
    return null;
  }

  _WordToken _copyWithFontScale(_WordToken word, double fontScale) {
    return _WordToken(
      text: word.text,
      bold: word.bold,
      italic: word.italic,
      underline: word.underline,
      tieUnderline: word.tieUnderline,
      strike: word.strike,
      color: word.color,
      chord: word.chord,
      kotta: word.kotta,
      spaceAfter: word.spaceAfter,
      breakAfter: word.breakAfter,
      preferredBreakAfter: word.preferredBreakAfter,
      softHyphenAfter: word.softHyphenAfter,
      fontScale: fontScale,
    );
  }

  List<_WordToken> _splitWordToFitWidth(
    _WordToken word,
    double fontSize,
    double maxChunkWidth,
    TextPainter measure,
  ) {
    final List<String> graphemes = word.text.characters.toList();
    if (graphemes.length <= 1) {
      return <_WordToken>[word];
    }

    final List<_WordToken> parts = <_WordToken>[];
    int start = 0;
    while (start < graphemes.length) {
      int low = 1;
      int high = graphemes.length - start;
      int bestLen = 0;

      while (low <= high) {
        final int mid = (low + high) ~/ 2;
        final bool isLastCandidate = start + mid >= graphemes.length;
        final String chunk = graphemes.sublist(start, start + mid).join();

        measure.text = TextSpan(
          text: chunk + (isLastCandidate && word.spaceAfter ? ' ' : ''),
          style: TextStyle(
            fontSize: _effectiveWordFontSize(word, fontSize),
            fontWeight: (globals.boldText || word.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: word.italic ? FontStyle.italic : FontStyle.normal,
          ),
        );
        measure.layout();

        if (measure.width <= maxChunkWidth) {
          bestLen = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      if (bestLen <= 0) {
        bestLen = 1;
      }

      double chunkScale = word.fontScale;
      if (bestLen == 1) {
        // A single grapheme already exceeds the chunk limit. Reduce the font
        // scale just enough that this lone grapheme no longer overflows.
        measure.text = TextSpan(
          text: graphemes[start].toString(),
          style: TextStyle(
            fontSize: _effectiveWordFontSize(word, fontSize),
            fontWeight: (globals.boldText || word.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: word.italic ? FontStyle.italic : FontStyle.normal,
          ),
        );
        measure.layout();
        final double singleWidth = measure.width;
        if (singleWidth > maxChunkWidth + 0.5) {
          chunkScale = (chunkScale * (maxChunkWidth / singleWidth)).clamp(
            0.5,
            1.0,
          );
        }
      }

      final bool isLast = start + bestLen >= graphemes.length;
      parts.add(
        _WordToken(
          text: graphemes.sublist(start, start + bestLen).join(),
          bold: word.bold,
          italic: word.italic,
          underline: word.underline,
          tieUnderline: word.tieUnderline,
          strike: word.strike,
          color: word.color,
          chord: start == 0 ? word.chord : null,
          kotta: start == 0 ? word.kotta : null,
          spaceAfter: isLast ? word.spaceAfter : false,
          // Non-final chunks must be breakable; otherwise splitting has no effect.
          breakAfter: isLast ? word.breakAfter : true,
          preferredBreakAfter: isLast ? word.preferredBreakAfter : false,
          softHyphenAfter: isLast ? word.softHyphenAfter : false,
          fontScale: chunkScale,
        ),
      );

      start += bestLen;
    }

    return parts;
  }

  void _paintChords(
    Canvas canvas,
    _RenderLine line,
    double x,
    double y,
    double fontSize,
  ) {
    if (line.words.isEmpty ||
        !globals.useAkkord ||
        !settings.receiverUseAkkord) {
      return;
    }
    final TextPainter measure = TextPainter(textDirection: TextDirection.ltr);
    double cx = x;
    for (int i = 0; i < line.words.length; i++) {
      final _WordToken w = line.words[i];
      final String display = w.text + (w.spaceAfter ? ' ' : '');
      measure.text = TextSpan(
        text: display,
        style: TextStyle(
          fontSize: _effectiveWordFontSize(w, fontSize),
          fontWeight: (globals.boldText || w.bold)
              ? FontWeight.bold
              : FontWeight.normal,
          fontStyle: w.italic ? FontStyle.italic : FontStyle.normal,
        ),
      );
      measure.layout();
      if ((w.chord ?? '').isNotEmpty) {
        final ChordLayout chord = ChordRenderer.layout(
          w.chord!,
          TextStyle(
            color: globals.txtColor,
            fontSize: fontSize * (globals.akkordArany / 100),
          ),
        );
        chord.paint(canvas, Offset(cx, y - chord.height - 2));
      }
      cx += measure.width;
    }
  }

  void _paintKotta(
    Canvas canvas,
    _RenderLine line,
    double firstTextY,
    double rowStep,
    double fontSize,
    double maxWidth,
    double sizeWidth,
    double continuationIndent,
    List<_KottaRowLayout>? precomputedRows,
  ) {
    if (line.words.isEmpty || !globals.useKotta) {
      return;
    }
    final double lineGap = _kottaLineGap(fontSize);
    final double staffHeight = _kottaStaffHeight(lineGap);
    final double staffToTextGap = _kottaStaffToTextGap(lineGap);
    final List<_KottaRowLayout> rows =
        precomputedRows ?? _buildKottaRows(line, fontSize, maxWidth);
    if (rows.isEmpty) {
      return;
    }

    final Paint staffPaint = Paint()
      ..color = _kottaInkColor
      ..strokeWidth = 1;

    final _KottaDrawState lineState = _KottaDrawState();
    lineState.deferFinalDoubleBarAtEnd = _lineEndsWithDoubleBar(line);
    final List<_KottaRowPrefix> rowPrefixes = _resolveKottaRowPrefixes(
      rows,
      line,
      lineGap,
    );
    final double blockStartX = _kottaRowsStartX(
      rows,
      sizeWidth,
      continuationIndent,
    );
    final double baseTop = firstTextY - staffHeight - staffToTextGap;
    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final _KottaRowLayout row = rows[rowIndex];
      final _KottaRowPrefix rowPrefix = rowPrefixes[rowIndex];
      final double rowX =
          blockStartX + _kottaContinuationIndent(rowIndex, continuationIndent);
      final double rowTop = baseTop + rowIndex * rowStep;
      if (globals.inverzKotta) {
        canvas.drawRect(
          Rect.fromLTRB(
            rowX,
            rowTop - _kottaLedgerReserve(lineGap),
            rowX + row.width,
            rowTop + staffHeight + _kottaLedgerReserve(lineGap),
          ),
          Paint()..color = globals.txtColor,
        );
      }
      final int staffLineCount = _staffLineCountForLine(line);
      for (int i = 0; i < staffLineCount; i++) {
        final double ly = rowTop + i * lineGap;
        canvas.drawLine(
          Offset(rowX, ly),
          Offset(rowX + row.width, ly),
          staffPaint,
        );
      }

      double cx = rowX;
      for (int slotIndex = 0; slotIndex < row.words.length; slotIndex++) {
        final _KottaWordLayout slot = row.words[slotIndex];
        final _WordToken w = line.words[slot.wordIndex];
        String kotta = (w.kotta ?? '').trim();
        final bool isFirstSlot = slotIndex == 0;
        if (isFirstSlot && rowPrefix.kotta.isNotEmpty) {
          _drawSimpleKotta(
            canvas,
            rowPrefix.kotta,
            cx,
            rowTop + staffHeight + staffToTextGap,
            rowPrefix.width,
            fontSize,
            state: lineState,
            lineGapOverride: lineGap,
            drawStaff: false,
          );
          cx += rowPrefix.width;
        }
        if (isFirstSlot && row.inlinePrefix.kotta.isNotEmpty) {
          _drawSimpleKotta(
            canvas,
            row.inlinePrefix.kotta,
            cx,
            rowTop + staffHeight + staffToTextGap,
            row.inlinePrefix.width,
            fontSize,
            state: lineState,
            lineGapOverride: lineGap,
            drawStaff: false,
          );
          cx += row.inlinePrefix.width;
          if (kotta.startsWith(row.inlinePrefix.kotta)) {
            kotta = kotta.substring(row.inlinePrefix.kotta.length);
          }
        }
        if (kotta.isNotEmpty) {
          _drawSimpleKotta(
            canvas,
            kotta,
            cx,
            rowTop + staffHeight + staffToTextGap,
            slot.slotWidth,
            fontSize,
            state: lineState,
            lineGapOverride: lineGap,
            drawStaff: false,
          );
        }
        cx += slot.slotWidth;
      }

      if (rowIndex < rows.length - 1) {
        _endBeam(canvas, lineState, lineGap);
        _endTuplet(canvas, lineState, lineGap);
        _endSlur(canvas, lineState, lineGap);
      }
    }

    if (lineState.deferFinalDoubleBarAtEnd) {
      final _KottaRowLayout last = rows.last;
      final double lastX =
          blockStartX +
          _kottaContinuationIndent(rows.length - 1, continuationIndent);
      final double lastTop = baseTop + (rows.length - 1) * rowStep;
      _drawForcedClosingBarline(canvas, lastX + last.width, lastTop, lineGap);
    }

    _endBeam(canvas, lineState, lineGap);
    _endTuplet(canvas, lineState, lineGap);
    _endSlur(canvas, lineState, lineGap);
  }

  double _kottaLineGap(double fontSize) {
    return (fontSize * 0.22 * (globals.kottaArany / 100.0)).clamp(2.0, 10.0);
  }

  double _kottaStaffHeight(double lineGap) {
    return lineGap * 4;
  }

  int _staffLineCountForLine(_RenderLine line) {
    for (final _WordToken word in line.words) {
      final List<String> commands = _parseKottaCommands(
        (word.kotta ?? '').trim(),
      );
      if (commands.isEmpty) {
        continue;
      }
      final String first = commands.first;
      if (first[0] == '-') {
        return int.tryParse(first[1])?.clamp(1, 5).toInt() ?? 5;
      }
      return 5;
    }
    return 5;
  }

  double _kottaLedgerReserve(double lineGap) {
    return lineGap * 2;
  }

  Color get _kottaInkColor =>
      globals.inverzKotta ? globals.bkColor : globals.txtColor;

  double _kottaStaffToTextGap(double lineGap) {
    // Keep enough clearance for lower ledger lines so they do not collide with lyrics.
    return math.max(4.0, lineGap * 2.2);
  }

  double _kottaRowBlockHeight(double fontSize) {
    final double lineGap = _kottaLineGap(fontSize);
    return _kottaLedgerReserve(lineGap) +
        _kottaStaffHeight(lineGap) +
        _kottaStaffToTextGap(lineGap) +
        _kottaRowTextHeight(fontSize) +
        _kottaLedgerReserve(lineGap);
  }

  double _titleToKottaGap(double fontSize) {
    return math.max(10.0, _kottaLineGap(fontSize) * 1.5);
  }

  double _titleToKottaTransitionGap({
    required double nextLineFontSize,
    required double titleHeight,
    required double lineSpacing,
  }) {
    final double compressedTitleOverlap = math.max(
      0.0,
      titleHeight - titleHeight * lineSpacing,
    );
    return _titleToKottaGap(nextLineFontSize) + compressedTitleOverlap;
  }

  double _kottaRowTextHeight(double fontSize) {
    final TextPainter measure = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: globals.boldText ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return measure.height;
  }

  double _kottaRowStartX(
    double rowWidth,
    double sizeWidth,
    double horizontalPad,
  ) {
    if (!globals.hCenter) {
      return 0;
    }
    return (sizeWidth - rowWidth) / 2.0;
  }

  double _kottaRowsStartX(
    List<_KottaRowLayout> rows,
    double sizeWidth,
    double horizontalPad,
  ) {
    if (rows.isEmpty) {
      return _kottaRowStartX(0, sizeWidth, horizontalPad);
    }
    final double blockWidth = rows.fold<double>(
      0,
      (double maxWidth, _KottaRowLayout row) => math.max(maxWidth, row.width),
    );
    return _kottaRowStartX(blockWidth, sizeWidth, horizontalPad);
  }

  double _kottaContinuationIndent(int rowIndex, double horizontalPad) {
    if (rowIndex <= 0) {
      return 0;
    }
    return horizontalPad;
  }

  void _paintKottaAlignedTextRow(
    Canvas canvas,
    _RenderLine line,
    List<bool> highlights,
    _KottaRowLayout row,
    double rowX,
    double y,
    double fontSize, {
    double leadingInset = 0,
  }) {
    double cx = rowX;
    final List<_KottaTextSlotLayout> slotLayouts = <_KottaTextSlotLayout>[];
    for (int slotIndex = 0; slotIndex < row.words.length; slotIndex++) {
      final _KottaWordLayout slot = row.words[slotIndex];
      final _WordToken w = line.words[slot.wordIndex];
      final bool highlighted = slot.wordIndex < highlights.length
          ? highlights[slot.wordIndex]
          : false;
      final Color baseColor = w.color ?? globals.txtColor;
      final String display = w.text + (w.spaceAfter ? ' ' : '');
      final double inset = slotIndex == 0 ? leadingInset : 0;
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: display,
          style: TextStyle(
            color: highlighted ? globals.hiColor : baseColor,
            fontSize: _effectiveWordFontSize(w, fontSize),
            fontWeight: (globals.boldText || w.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: w.italic ? FontStyle.italic : FontStyle.normal,
            decoration: TextDecoration.combine(<TextDecoration>[
              if (w.underline) TextDecoration.underline,
              if (w.strike) TextDecoration.lineThrough,
            ]),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final double slotLeft = cx + inset;
      tp.paint(canvas, Offset(slotLeft, y));
      slotLayouts.add(
        _KottaTextSlotLayout(
          wordIndex: slot.wordIndex,
          left: slotLeft,
          right: slotLeft + tp.width,
          baseline: y + tp.computeLineMetrics().first.baseline,
          tieUnderline: w.tieUnderline,
          color: baseColor,
          connectorColor: highlighted ? globals.hiColor : baseColor,
        ),
      );
      cx += slot.slotWidth + inset;
    }

    _paintKottaLetterConnectors(canvas, line.words, slotLayouts, fontSize);
    _paintKottaTieUnderlines(
      canvas,
      sourceWords: line.words,
      slots: slotLayouts,
      y: y,
      fontSize: fontSize,
    );

    if (row.endHyphen && row.words.isNotEmpty) {
      final _WordToken lastWord = line.words[row.words.last.wordIndex];
      final bool highlighted = row.words.last.wordIndex < highlights.length
          ? highlights[row.words.last.wordIndex]
          : false;
      final Color baseColor = lastWord.color ?? globals.txtColor;
      final double hyphenX = slotLayouts.isEmpty
          ? rowX
          : slotLayouts.last.right;
      final TextPainter hyphen = TextPainter(
        text: TextSpan(
          text: '-',
          style: TextStyle(
            color: highlighted ? globals.hiColor : baseColor,
            fontSize: _effectiveWordFontSize(lastWord, fontSize),
            fontWeight: (globals.boldText || lastWord.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: lastWord.italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hyphen.paint(canvas, Offset(hyphenX, y));
    }
  }

  bool _shouldPaintKottaLetterConnector({
    required _WordToken previous,
    required _WordToken current,
    required double gap,
  }) {
    return !previous.spaceAfter &&
        previous.text.isNotEmpty &&
        current.text.isNotEmpty &&
        gap > 0.5;
  }

  void _paintKottaLetterConnectors(
    Canvas canvas,
    List<_WordToken> sourceWords,
    List<_KottaTextSlotLayout> slots,
    double fontSize,
  ) {
    if (slots.length < 2) {
      return;
    }

    final Paint paint = Paint()
      ..strokeWidth = math.max(0.75, fontSize * 0.025)
      ..strokeCap = StrokeCap.butt;
    for (int i = 1; i < slots.length; i++) {
      final _KottaTextSlotLayout previousSlot = slots[i - 1];
      final _KottaTextSlotLayout currentSlot = slots[i];
      final _WordToken previous = sourceWords[previousSlot.wordIndex];
      final _WordToken current = sourceWords[currentSlot.wordIndex];
      final double gap = currentSlot.left - previousSlot.right;
      if (!_shouldPaintKottaLetterConnector(
        previous: previous,
        current: current,
        gap: gap,
      )) {
        continue;
      }

      paint.color = previousSlot.connectorColor;
      canvas.drawLine(
        Offset(previousSlot.right, previousSlot.baseline),
        Offset(currentSlot.left, previousSlot.baseline),
        paint,
      );
    }
  }

  List<_KottaRowLayout> _buildKottaRows(
    _RenderLine line,
    double fontSize,
    double maxWidth, {
    _KottaDrawState? inheritedState,
  }) {
    final String cacheKey = _kottaRowsCacheKey(
      line,
      fontSize,
      maxWidth,
      inheritedState,
    );
    final List<_KottaRowLayout>? cached = _kottaRowsCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final TextPainter measure = TextPainter(textDirection: TextDirection.ltr);
    final double lineGap = _kottaLineGap(fontSize);
    final double wrapWidth = math.max(8.0, maxWidth);
    final double continuationIndent = globals.hCenter
        ? 0
        : _textContinuationIndent(fontSize, measure);
    final _KottaDrawState state = inheritedState?.copy() ?? _KottaDrawState();
    state.deferFinalDoubleBarAtEnd = _lineEndsWithDoubleBar(line);
    double firstRowInlinePrefixWidth = 0;
    if (line.words.isNotEmpty) {
      final String firstKotta = (line.words.first.kotta ?? '').trim();
      final String leadingKotta = _leadingInlineKottaPrefix(firstKotta);
      if (leadingKotta.isNotEmpty) {
        firstRowInlinePrefixWidth = _kottaRawWidth(
          leadingKotta,
          lineGap,
          _KottaDrawState(),
        );
      }
    }

    final List<_KottaRowLayout> rows = <_KottaRowLayout>[];
    final List<_KottaWordLayout> currentWords = <_KottaWordLayout>[];
    final List<_KottaWordLayout> pendingWord = <_KottaWordLayout>[];
    _KottaRowPrefix currentPrefix = _lineRequestsCarryPrefix(line)
        ? _kottaRowPrefixForState(state, lineGap)
        : const _KottaRowPrefix.empty();
    _KottaDrawState? pendingWordStartState;
    double currentWidth = currentPrefix.width;
    double pendingWordWidth = 0;

    for (int i = 0; i < line.words.length; i++) {
      pendingWordStartState ??= state.copy();
      final _WordToken w = line.words[i];
      final double textWidth = _measureWordDisplayWidth(w, fontSize, measure);
      final String kotta = (w.kotta ?? '').trim();
      final double kottaWidth = kotta.isEmpty
          ? 0
          : _kottaRawWidth(kotta, lineGap, state);
      final double slotWidth = math.max(textWidth, kottaWidth);

      pendingWord.add(_KottaWordLayout(wordIndex: i, slotWidth: slotWidth));
      pendingWordWidth += slotWidth;

      final bool endsWord =
          w.breakAfter || w.softHyphenAfter || i == line.words.length - 1;
      if (!endsWord) {
        continue;
      }

      final double currentRowLimit = rows.isEmpty
          ? math.max(8.0, wrapWidth - firstRowInlinePrefixWidth)
          : math.max(8.0, wrapWidth - continuationIndent);
      if (currentWords.isNotEmpty &&
          (currentWidth + pendingWordWidth) > currentRowLimit) {
        final int lastWordIndex = currentWords.last.wordIndex;
        final bool endHyphen = line.words[lastWordIndex].softHyphenAfter;
        final double hyphenWidth = endHyphen
            ? _measureHyphenDisplayWidth(
                line.words[lastWordIndex],
                fontSize,
                measure,
              )
            : 0;
        rows.add(
          _KottaRowLayout(
            words: List<_KottaWordLayout>.from(currentWords),
            width: currentWidth + hyphenWidth,
            prefix: currentPrefix,
            endHyphen: endHyphen,
          ),
        );
        currentPrefix = _kottaRowPrefixForState(pendingWordStartState, lineGap);
        currentWords.clear();
        currentWidth = currentPrefix.width;
      }

      // A single kotta word can never be split across rows (its melody is
      // bound to it). If it overflows the row by itself, shrink its lyric font
      // scale so the whole slot fits, per user preference.
      if (currentWords.isEmpty &&
          pendingWord.length == 1 &&
          pendingWordWidth > currentRowLimit) {
        final _KottaWordLayout slot = pendingWord.first;
        final int wi = slot.wordIndex;
        final _WordToken w = line.words[wi];
        final String kotta = (w.kotta ?? '').trim();
        final _WordToken? shrunk = _shrinkKottaWordToFit(
          w,
          fontSize,
          kotta.isEmpty ? 0 : _kottaRawWidth(kotta, lineGap, state),
          slot.slotWidth,
          currentRowLimit,
          measure,
        );
        if (shrunk != null) {
          line.words[wi] = shrunk;
          final double newTextWidth = _measureWordDisplayWidth(
            shrunk,
            fontSize,
            measure,
          );
          final double newKottaWidth = kotta.isEmpty
              ? 0
              : _kottaRawWidth(kotta, lineGap, state);
          final double newSlotWidth = math.max(newTextWidth, newKottaWidth);
          pendingWord[0] = _KottaWordLayout(
            wordIndex: wi,
            slotWidth: newSlotWidth,
          );
          pendingWordWidth = newSlotWidth;
        }
      }

      currentWords.addAll(pendingWord);
      currentWidth += pendingWordWidth;
      pendingWord.clear();
      pendingWordWidth = 0;
      pendingWordStartState = null;
    }

    if (currentWords.isNotEmpty) {
      rows.add(
        _KottaRowLayout(
          words: List<_KottaWordLayout>.from(currentWords),
          width: currentWidth,
          prefix: currentPrefix,
        ),
      );
    }

    final List<_KottaRowLayout> resolved = _applyKottaRowPrefixes(
      rows,
      line,
      lineGap,
      fontSize,
    );
    _kottaRowsCache[cacheKey] = resolved;
    while (_kottaRowsCache.length > _layoutCacheLimit) {
      _kottaRowsCache.remove(_kottaRowsCache.keys.first);
    }
    return resolved;
  }

  List<_KottaRowLayout> _applyKottaRowPrefixes(
    List<_KottaRowLayout> rows,
    _RenderLine line,
    double lineGap,
    double fontSize,
  ) {
    if (rows.isEmpty) {
      return rows;
    }

    final List<_KottaRowPrefix> prefixes = _resolveKottaRowPrefixes(
      rows,
      line,
      lineGap,
    );
    final List<_KottaRowLayout> resolvedRows = <_KottaRowLayout>[];
    final TextPainter measure = TextPainter(textDirection: TextDirection.ltr);

    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final _KottaRowLayout row = rows[rowIndex];
      final _KottaRowPrefix prefix = prefixes[rowIndex];
      List<_KottaWordLayout> effectiveWords = row.words;
      _KottaRowPrefix inlinePrefix = const _KottaRowPrefix.empty();

      if (rowIndex == 0 && prefix.kotta.isEmpty && row.words.isNotEmpty) {
        final _KottaWordLayout firstSlot = row.words.first;
        final _WordToken firstWord = line.words[firstSlot.wordIndex];
        final String firstKotta = (firstWord.kotta ?? '').trim();
        final String leadingKotta = _leadingInlineKottaPrefix(firstKotta);
        if (leadingKotta.isNotEmpty) {
          final double fullKottaWidth = _kottaRawWidth(
            firstKotta,
            lineGap,
            _KottaDrawState(),
          );
          final double leadingWidth = _kottaRawWidth(
            leadingKotta,
            lineGap,
            _KottaDrawState(),
          );
          final double remainingKottaWidth = math.max(
            0,
            fullKottaWidth - leadingWidth,
          );
          final double textWidth = _measureWordDisplayWidth(
            firstWord,
            fontSize,
            measure,
          );
          final List<_KottaWordLayout> adjustedWords =
              List<_KottaWordLayout>.from(row.words);
          adjustedWords[0] = _KottaWordLayout(
            wordIndex: firstSlot.wordIndex,
            slotWidth: math.max(textWidth, remainingKottaWidth),
          );
          effectiveWords = adjustedWords;
          inlinePrefix = _KottaRowPrefix(
            kotta: leadingKotta,
            width: leadingWidth,
          );
        }
      }

      final double contentWidth = effectiveWords.fold<double>(
        0,
        (double sum, _KottaWordLayout slot) => sum + slot.slotWidth,
      );
      resolvedRows.add(
        _KottaRowLayout(
          words: effectiveWords,
          width: prefix.width + inlinePrefix.width + contentWidth,
          prefix: prefix,
          inlinePrefix: inlinePrefix,
          endHyphen: row.endHyphen,
        ),
      );
    }

    return resolvedRows;
  }

  String _leadingInlineKottaPrefix(String kotta) {
    final List<String> commands = _parseKottaCommands(kotta);
    if (commands.isEmpty) {
      return '';
    }

    final StringBuffer prefix = StringBuffer();
    bool sawVisiblePrefix = false;
    for (final String command in commands) {
      final String kind = command[0];
      if (_isLeadingKottaSetupCommand(kind)) {
        prefix.write(command);
        continue;
      }
      if (_isLeadingKottaVisiblePrefixCommand(kind)) {
        sawVisiblePrefix = true;
        prefix.write(command);
        continue;
      }
      break;
    }
    return sawVisiblePrefix ? prefix.toString() : '';
  }

  bool _isLeadingKottaSetupCommand(String kind) {
    return kind == '-' ||
        kind == 'r' ||
        kind == 'R' ||
        kind == 'm' ||
        kind == '[' ||
        kind == ']' ||
        kind == '(' ||
        kind == ')';
  }

  bool _isLeadingKottaVisiblePrefixCommand(String kind) {
    return kind == 'k' ||
        kind == 'e' ||
        kind == 'E' ||
        kind == 'u' ||
        kind == 'U';
  }

  List<_KottaRowPrefix> _resolveKottaRowPrefixes(
    List<_KottaRowLayout> rows,
    _RenderLine line,
    double lineGap,
  ) {
    final List<_KottaRowPrefix> prefixes = <_KottaRowPrefix>[];
    final _KottaDrawState state = _KottaDrawState();
    state.deferFinalDoubleBarAtEnd = _lineEndsWithDoubleBar(line);
    if (rows.isNotEmpty && rows.first.prefix.kotta.isNotEmpty) {
      _kottaRawWidth(rows.first.prefix.kotta, lineGap, state);
    }

    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      prefixes.add(
        rowIndex == 0
            ? rows.first.prefix
            : _kottaRowPrefixForState(state, lineGap),
      );

      for (final _KottaWordLayout slot in rows[rowIndex].words) {
        final String kotta = (line.words[slot.wordIndex].kotta ?? '').trim();
        if (kotta.isNotEmpty) {
          _kottaRawWidth(kotta, lineGap, state);
        }
      }
    }

    return prefixes;
  }

  bool _lineRequestsCarryPrefix(_RenderLine line) {
    for (final _WordToken word in line.words) {
      final String kotta = (word.kotta ?? '').trim();
      if (kotta.isEmpty) {
        continue;
      }
      final List<String> cmds = _parseKottaCommands(kotta);
      if (cmds.isEmpty) {
        continue;
      }
      return cmds.first[0] == '-';
    }
    return false;
  }

  void _advanceKottaStateForLine(
    _RenderLine line,
    double lineGap,
    _KottaDrawState state,
  ) {
    for (final _WordToken word in line.words) {
      final String kotta = (word.kotta ?? '').trim();
      if (kotta.isNotEmpty) {
        _kottaRawWidth(kotta, lineGap, state);
      }
    }
  }

  List<_TextRowLayout> _buildTextRows(
    _RenderLine line,
    double fontSize,
    double maxWidth, {
    bool preferPreferredBreaks = true,
  }) {
    final String cacheKey = _textRowsCacheKey(
      line,
      fontSize,
      maxWidth,
      preferPreferredBreaks,
    );
    final List<_TextRowLayout>? cached = _textRowsCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    if (line.words.isEmpty) {
      return const <_TextRowLayout>[];
    }

    final TextPainter measure = TextPainter(textDirection: TextDirection.ltr);
    final double wrapWidth = math.max(8.0, maxWidth);
    final double continuationIndent = globals.hCenter
        ? 0
        : _textContinuationIndent(fontSize, measure);
    final List<_TextRowLayout> rows = <_TextRowLayout>[];
    final List<int> currentWordIndices = <int>[];
    final List<int> pendingWordIndices = <int>[];
    final List<double> slotWidths = List<double>.generate(
      line.words.length,
      (int index) =>
          _measureWordDisplayWidth(line.words[index], fontSize, measure),
      growable: false,
    );
    double currentWidth = 0;
    double pendingWordWidth = 0;

    for (int i = 0; i < line.words.length; i++) {
      final _WordToken w = line.words[i];
      final double slotWidth = slotWidths[i];
      pendingWordIndices.add(i);
      pendingWordWidth += slotWidth;

      final bool endsWord =
          w.breakAfter || w.softHyphenAfter || i == line.words.length - 1;
      if (!endsWord) {
        continue;
      }

      final double currentRowLimit = rows.isEmpty
          ? wrapWidth
          : math.max(8.0, wrapWidth - continuationIndent);

      if (currentWordIndices.isNotEmpty &&
          (currentWidth + pendingWordWidth) > currentRowLimit) {
        final List<int> combinedWordIndices = <int>[]
          ..addAll(currentWordIndices)
          ..addAll(pendingWordIndices);

        int breakWordIndex = combinedWordIndices.last;
        int? preferredBreakIndex;
        if (preferPreferredBreaks) {
          for (int j = combinedWordIndices.length - 1; j >= 0; j--) {
            final int candidateIndex = combinedWordIndices[j];
            if (!line.words[candidateIndex].preferredBreakAfter) {
              continue;
            }

            double headWidth = 0;
            for (int k = 0; k <= j; k++) {
              headWidth += slotWidths[combinedWordIndices[k]];
            }
            double tailWidth = 0;
            for (int k = j + 1; k < combinedWordIndices.length; k++) {
              tailWidth += slotWidths[combinedWordIndices[k]];
            }

            if (headWidth <= currentRowLimit && tailWidth <= currentRowLimit) {
              preferredBreakIndex = candidateIndex;
              break;
            }
          }
        }
        if (preferredBreakIndex != null) {
          breakWordIndex = preferredBreakIndex;
        } else {
          for (int j = combinedWordIndices.length - 1; j >= 0; j--) {
            final int candidateIndex = combinedWordIndices[j];
            final _WordToken candidate = line.words[candidateIndex];
            final bool isRegularBreak =
                candidate.breakAfter || candidate.softHyphenAfter;
            if (!isRegularBreak && j != combinedWordIndices.length - 1) {
              continue;
            }

            double headWidth = 0;
            for (int k = 0; k <= j; k++) {
              headWidth += slotWidths[combinedWordIndices[k]];
            }
            double tailWidth = 0;
            for (int k = j + 1; k < combinedWordIndices.length; k++) {
              tailWidth += slotWidths[combinedWordIndices[k]];
            }

            if (headWidth <= currentRowLimit && tailWidth <= currentRowLimit) {
              breakWordIndex = candidateIndex;
              break;
            }
          }
        }

        // No preferred or regular break can place the final pending word on
        // the current row without overflowing. Instead of packing every word
        // onto one overflowing row, push the final word onto the next line so
        // the current row stays within its limit.
        if (breakWordIndex == combinedWordIndices.last &&
            combinedWordIndices.length >= 2) {
          breakWordIndex = combinedWordIndices[combinedWordIndices.length - 2];
        }

        final int breakPos = combinedWordIndices.indexOf(breakWordIndex);
        final List<int> rowWordIndices = List<int>.from(
          combinedWordIndices.take(breakPos + 1),
        );
        final List<int> carryWordIndices = List<int>.from(
          combinedWordIndices.skip(breakPos + 1),
        );

        double rowBaseWidth = 0;
        for (final int idx in rowWordIndices) {
          rowBaseWidth += slotWidths[idx];
        }
        double carryWordsWidth = 0;
        for (final int idx in carryWordIndices) {
          carryWordsWidth += slotWidths[idx];
        }

        final int lastWordIndex = breakWordIndex;
        final bool endHyphen = line.words[lastWordIndex].softHyphenAfter;
        final double hyphenWidth = endHyphen
            ? _measureHyphenDisplayWidth(
                line.words[lastWordIndex],
                fontSize,
                measure,
              )
            : 0;
        rows.add(
          _TextRowLayout(
            wordIndices: rowWordIndices,
            width: rowBaseWidth + hyphenWidth,
            indentWidth: rows.isEmpty ? 0 : continuationIndent,
            endHyphen: endHyphen,
          ),
        );
        currentWordIndices
          ..clear()
          ..addAll(carryWordIndices);
        currentWidth = carryWordsWidth;
        pendingWordIndices.clear();
        pendingWordWidth = 0;
        continue;
      }

      currentWordIndices.addAll(pendingWordIndices);
      currentWidth += pendingWordWidth;
      pendingWordIndices.clear();
      pendingWordWidth = 0;
    }

    if (currentWordIndices.isNotEmpty) {
      rows.add(
        _TextRowLayout(
          wordIndices: List<int>.from(currentWordIndices),
          width: currentWidth,
          indentWidth: rows.isEmpty ? 0 : continuationIndent,
        ),
      );
    }

    _textRowsCache[cacheKey] = rows;
    while (_textRowsCache.length > _layoutCacheLimit) {
      _textRowsCache.remove(_textRowsCache.keys.first);
    }
    return rows;
  }

  double _textContinuationIndent(double fontSize, TextPainter measure) {
    if (globals.leftIndent <= 0) {
      return 0;
    }

    measure.text = TextSpan(
      text: ' ' * globals.leftIndent,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: globals.boldText ? FontWeight.bold : FontWeight.normal,
      ),
    );
    measure.layout();
    return measure.width;
  }

  double _measureWordDisplayWidth(
    _WordToken word,
    double fontSize,
    TextPainter measure,
  ) {
    final String display = word.text + (word.spaceAfter ? ' ' : '');
    final String cacheKey = [
      'w',
      display,
      _effectiveWordFontSize(word, fontSize).toStringAsFixed(3),
      globals.boldText || word.bold,
      word.italic,
    ].join('|');
    final double? cached = _wordWidthCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    measure.text = TextSpan(
      text: display,
      style: TextStyle(
        fontSize: _effectiveWordFontSize(word, fontSize),
        fontWeight: (globals.boldText || word.bold)
            ? FontWeight.bold
            : FontWeight.normal,
        fontStyle: word.italic ? FontStyle.italic : FontStyle.normal,
      ),
    );
    measure.layout();
    final double width = measure.width;
    _wordWidthCache[cacheKey] = width;
    while (_wordWidthCache.length > _wordMeasureCacheLimit) {
      _wordWidthCache.remove(_wordWidthCache.keys.first);
    }
    return width;
  }

  double _measureHyphenDisplayWidth(
    _WordToken word,
    double fontSize,
    TextPainter measure,
  ) {
    final String cacheKey = [
      'h',
      _effectiveWordFontSize(word, fontSize).toStringAsFixed(3),
      globals.boldText || word.bold,
      word.italic,
    ].join('|');
    final double? cached = _wordWidthCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    measure.text = TextSpan(
      text: '-',
      style: TextStyle(
        fontSize: _effectiveWordFontSize(word, fontSize),
        fontWeight: (globals.boldText || word.bold)
            ? FontWeight.bold
            : FontWeight.normal,
        fontStyle: word.italic ? FontStyle.italic : FontStyle.normal,
      ),
    );
    measure.layout();
    final double width = measure.width;
    _wordWidthCache[cacheKey] = width;
    while (_wordWidthCache.length > _wordMeasureCacheLimit) {
      _wordWidthCache.remove(_wordWidthCache.keys.first);
    }
    return width;
  }

  double _effectiveWordFontSize(_WordToken word, double baseFontSize) {
    return baseFontSize * word.fontScale.clamp(0.1, 1.0);
  }

  String _textRowsCacheKey(
    _RenderLine line,
    double fontSize,
    double maxWidth,
    bool preferPreferredBreaks,
  ) {
    return [
      'text',
      fontSize.toStringAsFixed(2),
      maxWidth.toStringAsFixed(2),
      preferPreferredBreaks,
      globals.hCenter,
      globals.leftIndent,
      globals.boldText,
      for (final _WordToken word in line.words)
        [
          word.text,
          word.bold,
          word.italic,
          word.spaceAfter,
          word.breakAfter,
          word.preferredBreakAfter,
          word.softHyphenAfter,
          word.fontScale.toStringAsFixed(3),
        ].join(':'),
    ].join('|');
  }

  String _kottaRowsCacheKey(
    _RenderLine line,
    double fontSize,
    double maxWidth,
    _KottaDrawState? inheritedState,
  ) {
    return [
      'kotta',
      fontSize.toStringAsFixed(2),
      maxWidth.toStringAsFixed(2),
      globals.hCenter,
      globals.leftIndent,
      globals.boldText,
      inheritedState == null ? '' : _kottaStateKey(inheritedState),
      for (final _WordToken word in line.words)
        [
          word.text,
          word.bold,
          word.italic,
          word.spaceAfter,
          word.breakAfter,
          word.preferredBreakAfter,
          word.softHyphenAfter,
          word.fontScale.toStringAsFixed(3),
          word.kotta ?? '',
        ].join(':'),
    ].join('|');
  }

  String _measureTextHeightCacheKey(
    Size size,
    TextFrame frame,
    double fontSize,
    bool preferPreferredBreaks,
  ) {
    return [
      'height',
      size.width.toStringAsFixed(2),
      size.height.toStringAsFixed(2),
      fontSize.toStringAsFixed(2),
      preferPreferredBreaks,
      globals.fontSize,
      globals.titleSize,
      globals.leftIndent,
      globals.spacing100,
      globals.hCenter,
      globals.useAkkord,
      globals.useKotta,
      globals.hideTitle,
      settings.receiverUseAkkord,
      settings.receiverUseKotta,
      frame.record.title,
      ...frame.record.lines,
    ].join('|');
  }

  String _preparedTextLayoutCacheKey(
    Size size,
    TextFrame frame,
    double fontSize,
    bool preferPreferredBreaks,
  ) {
    return [
      'prepared',
      size.width.toStringAsFixed(2),
      fontSize.toStringAsFixed(2),
      preferPreferredBreaks,
      globals.titleSize,
      globals.leftIndent,
      globals.hCenter,
      globals.boldText,
      globals.useAkkord,
      globals.useKotta,
      globals.hideTitle,
      globals.kottaArany,
      globals.akkordArany,
      settings.receiverUseAkkord,
      settings.receiverUseKotta,
      frame.record.title,
      ...frame.record.lines,
    ].join('|');
  }

  String _kottaStateKey(_KottaDrawState state) {
    return [
      state.kulcs,
      state.elojegy,
      state.modosito,
      state.ritmus,
      state.pontozott,
      state.tomor,
      state.gerenda,
      state.szaaratlan,
      state.agogika,
      state.staffLineCount,
      state.slurType,
      state.slurNext,
      state.deferFinalDoubleBarAtEnd,
      state.triLe,
      state.triTipus,
      state.triPos.length,
      state.beamStems.length,
    ].join('|');
  }

  double _kottaRawWidth(String kotta, double lineGap, _KottaDrawState state) {
    double width = 0;
    for (final String cmd in _parseKottaCommands(kotta)) {
      width += _kottaWidthOf(cmd, lineGap, state);
    }
    return width;
  }

  bool _lineEndsWithDoubleBar(_RenderLine line) {
    for (int i = line.words.length - 1; i >= 0; i--) {
      final String kotta = (line.words[i].kotta ?? '').trim();
      if (kotta.isEmpty) {
        continue;
      }
      final List<String> cmds = _parseKottaCommands(kotta);
      if (cmds.isEmpty) {
        continue;
      }
      final String last = cmds.last;
      return last.length == 2 && last[0] == '|' && last[1] == '|';
    }
    return false;
  }

  void _drawForcedClosingBarline(
    Canvas canvas,
    double endX,
    double top,
    double lineGap,
  ) {
    final Paint thin = Paint()
      ..color = _kottaInkColor
      ..strokeWidth = 1.2;
    final Paint thick = Paint()
      ..color = _kottaInkColor
      ..strokeWidth = 2.2;

    final double y1 = top;
    final double y2 = top + lineGap * 4;
    final double xThin = endX + lineGap * 0.35;
    final double xThick = endX + lineGap * 0.65;

    canvas.drawLine(Offset(xThin, y1), Offset(xThin, y2), thin);
    canvas.drawLine(Offset(xThick, y1), Offset(xThick, y2), thick);
  }

  void _drawSimpleKotta(
    Canvas canvas,
    String kotta,
    double x,
    double textTopY,
    double wordWidth,
    double fontSize, {
    _KottaDrawState? state,
    double? lineGapOverride,
    bool drawStaff = true,
  }) {
    final List<String> cmds = _parseKottaCommands(kotta);
    if (cmds.isEmpty) {
      return;
    }

    final double lineGap = lineGapOverride ?? _kottaLineGap(fontSize);
    final double staffHeight = _kottaStaffHeight(lineGap);
    final double top = textTopY - staffHeight - _kottaStaffToTextGap(lineGap);
    final _KottaDrawState measureState = (state ?? _KottaDrawState()).copy();

    double rawWidth = 0.0;
    for (final String c in cmds) {
      rawWidth += _kottaWidthOf(c, lineGap, measureState);
    }
    if (rawWidth <= 0) {
      return;
    }
    const double scale = 1.0;
    final double startX = x;
    final _KottaDrawState drawState = state ?? _KottaDrawState();

    if (drawStaff) {
      final Paint staffPaint = Paint()
        ..color = _kottaInkColor
        ..strokeWidth = 1;
      final int staffLineCount = _staffLineCountForCommands(cmds);
      for (int i = 0; i < staffLineCount; i++) {
        final double y = top + i * lineGap;
        canvas.drawLine(Offset(x, y), Offset(x + wordWidth, y), staffPaint);
      }
    }

    double cx = startX;
    for (final String c in cmds) {
      final _KottaDrawState widthState = drawState.copy();
      final double cw = _kottaWidthOf(c, lineGap, widthState) * scale;
      _drawKottaCommand(canvas, c, drawState, cx, top, lineGap, scale);
      cx += cw;
    }
    if (state == null) {
      _endBeam(canvas, drawState, lineGap);
      _endTuplet(canvas, drawState, lineGap);
      _endSlur(canvas, drawState, lineGap);
    }
  }

  List<String> _parseKottaCommands(String kotta) {
    final List<String> out = <String>[];
    for (int i = 0; i + 1 < kotta.length; i += 2) {
      out.add(kotta.substring(i, i + 2));
    }
    return out;
  }

  int _staffLineCountForCommands(List<String> commands) {
    if (commands.isEmpty || commands.first[0] != '-') {
      return 5;
    }
    return int.tryParse(commands.first[1])?.clamp(1, 5).toInt() ?? 5;
  }

  double _kottaWidthOf(String cmd, double lineGap, _KottaDrawState state) {
    final String c1 = cmd[0];
    final String c2 = cmd[1];
    final double minWidth = _kottaMinWidth(lineGap);
    final double staffSpan = lineGap * 4.0;

    if (c1 == 'r' || c1 == 'R') {
      if (c2 == 't') {
        state.tomor = c1 == 'R';
      } else {
        state.ritmus = c2;
        state.pontozott = c1 == 'R';
      }
      return 0;
    }
    if (c1 == '-') {
      state.staffLineCount = int.tryParse(c2)?.clamp(1, 5).toInt() ?? 5;
      return 0;
    }
    if (c1 == 'm') {
      state.modosito = c2;
      return 0;
    }
    if (c1 == 'a') {
      state.agogika = c2;
      return 0;
    }
    if (c1 == 'k') {
      state.kulcs = c2;
      switch (c2) {
        case 'G':
          return minWidth +
              _kcGkulcsW * staffSpan / (_kcGkulcsV1 - _kcGkulcsV5);
        case 'F':
          return minWidth +
              _kcFkulcsW * staffSpan / (_kcFkulcsV1 - _kcFkulcsV5);
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
          return minWidth +
              _kcCkulcsW * staffSpan / (_kcCkulcsV1 - _kcCkulcsV5);
        default:
          if ('abcdefghi'.contains(c2)) {
            return minWidth +
                _kcDkulcsW * (lineGap) / (_kcDkulcsV1 - _kcDkulcsV2);
          }
          return 0;
      }
    }
    if (c1 == 'e') {
      state.elojegy = -((int.tryParse(c2) ?? 0).clamp(0, 7));
      return (1 + (int.tryParse(c2) ?? 0)) *
          _kcBeW *
          lineGap /
          (_kcBeV2a - _kcBeV2f) /
          1.5;
    }
    if (c1 == 'E') {
      state.elojegy = (int.tryParse(c2) ?? 0).clamp(0, 7);
      return (1 + (int.tryParse(c2) ?? 0)) *
          _kcKeresztW *
          lineGap /
          (_kcKeresztV2a - _kcKeresztV2f) /
          1.5;
    }
    if (c1 == 'u' || c1 == 'U') {
      return minWidth + _kcU22W * staffSpan / _kcU22H;
    }
    if (c1 == 's' || c1 == 'S') {
      state.modosito = ' ';
      switch (c2) {
        case '1':
          return (c1 == 'S' ? 1.5 * minWidth : minWidth) +
              _kcSzunet1W * lineGap / _kcSzunet1V;
        case '2':
          return (c1 == 'S' ? 1.5 * minWidth : minWidth) +
              _kcSzunet2W * lineGap / _kcSzunet2V;
        case '4':
          return (c1 == 'S' ? 1.5 * minWidth : minWidth) +
              _kcSzunet4W * (2 * lineGap) / (_kcSzunet4V2 - _kcSzunet4V4);
        case '8':
          return (c1 == 'S' ? 1.5 * minWidth : minWidth) +
              _kcSzunet8W * (2 * lineGap) / (_kcSzunet8V2 - _kcSzunet8V4);
        case '6':
          return (c1 == 'S' ? 1.5 * minWidth : minWidth) +
              _kcSzunet16W * (2 * lineGap) / (_kcSzunet16V2 - _kcSzunet16V4);
        default:
          return 0;
      }
    }
    if (c1 == '1' || c1 == '2' || c1 == '3') {
      double w = state.tomor ? 0.0 : minWidth;
      if (state.modosito != ' ') {
        switch (state.modosito) {
          case '0':
            w += 1.25 * _kcFeloldoW * lineGap / (_kcFeloldoV2a - _kcFeloldoV2f);
            break;
          case 'k':
            w += 1.25 * _kcKeresztW * lineGap / (_kcKeresztV2a - _kcKeresztV2f);
            break;
          case 'K':
            w +=
                1.25 *
                _kcKettosKeresztW *
                lineGap /
                (_kcKettosKeresztV2a - _kcKettosKeresztV2f);
            break;
          case 'b':
            w += 1.25 * _kcBeW * lineGap / (_kcBeV2a - _kcBeV2f);
            break;
          case 'B':
            w += 1.25 * _kcBeBeW * lineGap / (_kcBeBeV2a - _kcBeBeV2f);
            break;
        }
      }
      switch (state.ritmus) {
        case 'l':
          w += _kcHang0W * lineGap / (_kcHang0V2a - _kcHang0V2f);
          break;
        case 'b':
          w +=
              _kcHangBrevis1W *
              lineGap /
              (_kcHangBrevis1V2a - _kcHangBrevis1V2f);
          break;
        case 's':
          w +=
              _kcHangBrevis2W *
              lineGap /
              (_kcHangBrevis2V2a - _kcHangBrevis2V2f);
          break;
        case '1':
          w += _kcHang1W * lineGap / (_kcHang1V2a - _kcHang1V2f);
          break;
        case '2':
          w += _kcHang2W * lineGap / (_kcHang2V2a - _kcHang2V2f);
          break;
        default:
          w += _kcHang4W * lineGap / (_kcHang4V2a - _kcHang4V2f);
          break;
      }
      if (state.pontozott) {
        w +=
            (state.tomor ? 0.0 : minWidth / 8.0) +
            _kcPontW * lineGap / _kcPontV;
      }
      return w;
    }
    if (c1 == '|') {
      if (c2 == ':' || c2 == '<' || c2 == '>') {
        return minWidth * (c2 == ':' ? 3.0 : 2.0);
      }
      return minWidth;
    }
    return minWidth * 0.5;
  }

  double _kottaMinWidth(double lineGap) {
    return _kcHang4W * lineGap / (_kcHang4V2a - _kcHang4V2f);
  }

  _KottaRowPrefix _kottaRowPrefixForState(
    _KottaDrawState state,
    double lineGap,
  ) {
    final StringBuffer sb = StringBuffer();
    if (state.kulcs != ' ') {
      sb.write('k');
      sb.write(state.kulcs);
    }
    if (state.elojegy < 0) {
      sb.write('e');
      sb.write((-state.elojegy).clamp(0, 7));
    } else if (state.elojegy > 0) {
      sb.write('E');
      sb.write(state.elojegy.clamp(0, 7));
    }
    final String prefixKotta = sb.toString();
    if (prefixKotta.isEmpty) {
      return const _KottaRowPrefix.empty();
    }
    final double prefixWidth = _kottaRawWidth(
      prefixKotta,
      lineGap,
      _KottaDrawState(),
    );
    return _KottaRowPrefix(kotta: prefixKotta, width: prefixWidth);
  }

  void _drawKottaCommand(
    Canvas canvas,
    String cmd,
    _KottaDrawState state,
    double x,
    double top,
    double lineGap,
    double scale,
  ) {
    final String c1 = cmd[0];
    final String c2 = cmd[1];
    if (c1 == '[') {
      if (c2 == '0') {
        state.szaaratlan = true;
      } else if (c2 == '1') {
        state.szaaratlan = false;
      } else if (c2 == '3' || c2 == '5') {
        state.triTipus = c2;
        state.triPos.clear();
      } else {
        state.gerenda = true;
      }
      return;
    }
    if (c1 == ']') {
      _endBeam(canvas, state, lineGap);
      state.gerenda = false;
      if (c2 == '3' || c2 == '5') {
        _endTuplet(canvas, state, lineGap);
      }
      return;
    }
    if (c1 == '(') {
      state.slurNext = c2;
      return;
    }
    if (c1 == ')') {
      _endSlur(canvas, state, lineGap, forcedType: c2);
      return;
    }
    if (c1 == '-') {
      state.staffLineCount = int.tryParse(c2)?.clamp(1, 5).toInt() ?? 5;
      return;
    }

    if (c1 == 'k') {
      state.kulcs = c2;
      final String? clefName = switch (c2) {
        'G' => 'gkulcs',
        'F' => 'fkulcs',
        '1' || '2' || '3' || '4' || '5' => 'ckulcs',
        'a' || 'b' || 'c' || 'd' || 'e' || 'f' || 'g' || 'h' || 'i' => 'dkulcs',
        _ => null,
      };
      if (clefName != null) {
        double w = _kcGkulcsW;
        double h = _kcGkulcsH;
        double v1 = _kcGkulcsV1;
        double v5 = _kcGkulcsV5;
        double y0 = _linePos(top, lineGap, 3);
        if (c2 == 'F') {
          w = _kcFkulcsW;
          h = _kcFkulcsH;
          v1 = _kcFkulcsV1;
          v5 = _kcFkulcsV5;
        } else if ('12345'.contains(c2)) {
          w = _kcCkulcsW;
          h = _kcCkulcsH;
          v1 = _kcCkulcsV1;
          v5 = _kcCkulcsV5;
          y0 = _linePos(top, lineGap, 6 - (int.parse(c2) - 1));
        } else if ('abcdefghi'.contains(c2)) {
          w = _kcDkulcsW;
          h = _kcDkulcsH;
          v1 = _kcDkulcsV1;
          v5 = _kcDkulcsV2;
          y0 =
              _linePos(top, lineGap, 7) -
              lineGap * 0.5 * (1 + ('abcdefghi'.indexOf(c2)));
        }
        final double rat = (lineGap * 4.0) / (v1 - v5);
        final double y1 = y0 - v5 * rat;
        final double x2 = x + w * rat;
        final double y2 = y1 + h * rat;
        _drawKottaAsset(canvas, clefName, Rect.fromLTRB(x, y1, x2, y2));
      }
      return;
    }
    if (c1 == 'e' || c1 == 'E') {
      _endBeam(canvas, state, lineGap);
      final bool flat = c1 == 'e';
      final int n = int.tryParse(c2) ?? 0;
      final int count = n.clamp(0, 7);
      final String sym = flat ? 'be' : 'kereszt';
      final String kulcs = state.kulcs;
      final String pattern = flat
          ? switch (kulcs) {
              'G' => '3-4=2=4-2-3=1=',
              'F' => '2-3=1=3-1-2=0=',
              '1' => '4-2-3=1=3-1-2=',
              '2' => '5-3-4=2=4-2-3=',
              '4' => '3=5-3-4=2=4-2-',
              '5' => '4=2=4-2-3=1=3-',
              _ => '2=4-2-3=1=3-1-',
            }
          : switch (kulcs) {
              'G' => '5-3=5=4-2=4=3-',
              'F' => '4-2=4=3-5-3=5=',
              '1' => '2=1-3-1=3=2-4-',
              '2' => '3=2-4-2=4=3-5-',
              '4' => '5=4-2=4=3-5-3=',
              '5' => '3-5-3=5=4-2=4=',
              _ => '4=3-5-3=5=4-2=',
            };
      final double rat = flat
          ? lineGap / (_kcBeV2a - _kcBeV2f)
          : lineGap / (_kcKeresztV2a - _kcKeresztV2f);
      final double w = flat ? _kcBeW : _kcKeresztW;
      final double h = flat ? _kcBeH : _kcKeresztH;
      final double v1 = flat ? _kcBeV1 : _kcKeresztV1;
      final double v2a = flat ? _kcBeV2a : _kcKeresztV2a;

      double x1 = x;
      int p = 0;
      for (int i = 0; i < count && p + 1 < pattern.length; i++) {
        final int? d = int.tryParse(pattern[p]);
        final String t2 = pattern[p + 1];
        p += 2;
        if (d == null) {
          continue;
        }
        final int lineIx = 7 - (d - 1);
        double y1 = _linePos(top, lineGap, lineIx);
        y1 -= (t2 == '-') ? v1 * rat : v2a * rat;
        final double x2 = x1 + w * rat;
        final double y2 = y1 + h * rat;
        _drawKottaAsset(canvas, sym, Rect.fromLTRB(x1, y1, x2, y2));
        x1 += w * rat / 1.5;
      }
      return;
    }
    if (c1 == 'u' || c1 == 'U') {
      _endBeam(canvas, state, lineGap);
      final String? meter = switch ('$c1$c2') {
        'u2' => 'u24',
        'u3' => 'u34',
        'u4' => 'u44',
        'u5' => 'u54',
        'u6' => 'u64',
        'U2' => 'u22',
        'U3' => 'u32',
        'U6' => 'u68',
        'U8' => 'u38',
        _ => null,
      };
      if (meter != null) {
        _drawKottaAsset(
          canvas,
          meter,
          Rect.fromLTWH(x + lineGap * 0.3, top, lineGap * 1.1, lineGap * 4.2),
        );
      }
      return;
    }
    if (c1 == 'm') {
      state.modosito = c2;
      return;
    }
    if (c1 == 'a') {
      state.agogika = c2;
      return;
    }
    if (c1 == 'r' || c1 == 'R') {
      if (c2 == 't') {
        state.tomor = c1 == 'R';
      } else {
        state.ritmus = c2;
        state.pontozott = c1 == 'R';
      }
      return;
    }
    if (c1 == '1' || c1 == '2' || c1 == '3') {
      final _KottaNotePos? pos = _notePos(c1, c2);
      if (pos == null) {
        return;
      }
      final int l1 = pos.l1;
      final int l2 = pos.l2;
      final double minWidth = _kottaMinWidth(lineGap);
      final double mw = state.tomor ? 0.0 : minWidth;
      double x1 = x + mw * 0.5;
      final double? previousCompactHeadRight = state.lastCompactHeadRight;
      if (state.tomor &&
          state.modosito == ' ' &&
          previousCompactHeadRight != null &&
          !state.pontozott) {
        x1 = previousCompactHeadRight;
      }
      if (state.modosito != ' ') {
        final String? modName = switch (state.modosito) {
          '0' => 'feloldo',
          'k' => 'kereszt',
          'K' => 'kettoskereszt',
          'b' => 'be',
          'B' => 'bebe',
          _ => null,
        };
        double mw0 = _kcFeloldoW,
            mh0 = _kcFeloldoH,
            mvv = _kcFeloldoV1,
            mva = _kcFeloldoV2a,
            mvf = _kcFeloldoV2f;
        if (state.modosito == 'k') {
          mw0 = _kcKeresztW;
          mh0 = _kcKeresztH;
          mvv = _kcKeresztV1;
          mva = _kcKeresztV2a;
          mvf = _kcKeresztV2f;
        } else if (state.modosito == 'K') {
          mw0 = _kcKettosKeresztW;
          mh0 = _kcKettosKeresztH;
          mvv = _kcKettosKeresztV1;
          mva = _kcKettosKeresztV2a;
          mvf = _kcKettosKeresztV2f;
        } else if (state.modosito == 'b') {
          mw0 = _kcBeW;
          mh0 = _kcBeH;
          mvv = _kcBeV1;
          mva = _kcBeV2a;
          mvf = _kcBeV2f;
        } else if (state.modosito == 'B') {
          mw0 = _kcBeBeW;
          mh0 = _kcBeBeH;
          mvv = _kcBeBeV1;
          mva = _kcBeBeV2a;
          mvf = _kcBeBeV2f;
        }
        final double rat = lineGap / (mva - mvf);
        final double y1m =
            _linePos(top, lineGap, l1) - ((l1 == l2) ? mvv : mva) * rat;
        final double x2m = x1 + mw0 * rat;
        final double y2m = y1m + mh0 * rat;
        if (modName != null) {
          _drawKottaAsset(canvas, modName, Rect.fromLTRB(x1, y1m, x2m, y2m));
        }
        x1 = x2m + mw0 * rat * 0.25;
      }

      String noteName = switch (state.ritmus) {
        'l' => 'hang0',
        'b' => 'hangbrevis1',
        's' => 'hangbrevis2',
        '1' => 'hang1',
        '2' => 'hang2fej',
        _ => 'hang4fej',
      };
      double nw = _kcHang4W,
          nh = _kcHang4H,
          nvv = _kcHang4V1,
          nva = _kcHang4V2a,
          nvf = _kcHang4V2f;
      if (state.ritmus == 'l') {
        nw = _kcHang0W;
        nh = _kcHang0H;
        nvv = _kcHang0V1;
        nva = _kcHang0V2a;
        nvf = _kcHang0V2f;
      } else if (state.ritmus == 'b') {
        nw = _kcHangBrevis1W;
        nh = _kcHangBrevis1H;
        nvv = _kcHangBrevis1V1;
        nva = _kcHangBrevis1V2a;
        nvf = _kcHangBrevis1V2f;
      } else if (state.ritmus == 's') {
        nw = _kcHangBrevis2W;
        nh = _kcHangBrevis2H;
        nvv = _kcHangBrevis2V1;
        nva = _kcHangBrevis2V2a;
        nvf = _kcHangBrevis2V2f;
      } else if (state.ritmus == '1') {
        nw = _kcHang1W;
        nh = _kcHang1H;
        nvv = _kcHang1V1;
        nva = _kcHang1V2a;
        nvf = _kcHang1V2f;
      } else if (state.ritmus == '2') {
        nw = _kcHang2W;
        nh = _kcHang2H;
        nvv = _kcHang2V1;
        nva = _kcHang2V2a;
        nvf = _kcHang2V2f;
      }
      final double nrat = lineGap / (nva - nvf);
      final double ny1 =
          _linePos(top, lineGap, l1) - ((l1 == l2) ? nvv : nva) * nrat;
      final double nx2 = x1 + nw * nrat;
      final double ny2 = ny1 + nh * nrat;
      final double nx = (x1 + nx2) / 2.0;
      final double cy = (ny1 + ny2) / 2.0;
      final double noteW = (nx2 - x1);

      final bool drewHead = _drawKottaAsset(
        canvas,
        noteName,
        Rect.fromLTRB(x1, ny1, nx2, ny2),
      );
      if (!drewHead) {
        final Paint notePaint = Paint()..color = _kottaInkColor;
        canvas.drawOval(Rect.fromLTRB(x1, ny1, nx2, ny2), notePaint);
      }
      _drawCompactHeadConnector(
        canvas,
        state,
        headLeft: x1,
        headRight: nx2,
        headCenterY: cy,
      );

      // Ledger lines for notes outside the 5-line staff.
      final Paint ledgerPaint = Paint()
        ..color = _kottaInkColor
        ..strokeWidth = 1.0;
      final double lx1 = nx - noteW * 0.75;
      final double lx2 = nx + noteW * 0.75;
      if (pos.centerIndex >= 8.0) {
        for (double idx = 8.0; idx <= pos.centerIndex; idx += 1.0) {
          final double ly = top + (idx - 3.0) * lineGap;
          canvas.drawLine(Offset(lx1, ly), Offset(lx2, ly), ledgerPaint);
        }
      }
      if (pos.centerIndex <= 2.0) {
        for (double idx = 2.0; idx >= pos.centerIndex; idx -= 1.0) {
          final double ly = top + (idx - 3.0) * lineGap;
          canvas.drawLine(Offset(lx1, ly), Offset(lx2, ly), ledgerPaint);
        }
      }

      final bool stemDown = c2.toUpperCase() == c2;
      if (!state.szaaratlan &&
          (state.ritmus == '2' ||
              state.ritmus == '4' ||
              state.ritmus == '8' ||
              state.ritmus == '6')) {
        final double stemX = stemDown ? x1 : nx2;
        final double stemY2 = stemDown
            ? cy + lineGap * 3.2
            : cy - lineGap * 3.2;
        if (state.gerenda &&
            (state.ritmus == '8' || state.ritmus == '6') &&
            !state.szaaratlan) {
          state.beamStems.add(
            _BeamStem(
              x: stemX,
              yHead: cy,
              yTip: stemY2,
              down: stemDown,
              rhythm: state.ritmus,
            ),
          );
        } else {
          final Paint stemPaint = Paint()
            ..color = _kottaInkColor
            ..strokeWidth = 1.2;
          canvas.drawLine(Offset(stemX, cy), Offset(stemX, stemY2), stemPaint);
          if (state.ritmus == '8' || state.ritmus == '6') {
            final String flgName = stemDown
                ? (state.ritmus == '6' ? 'zaszlo16le' : 'zaszlo8le')
                : (state.ritmus == '6' ? 'zaszlo16fel' : 'zaszlo8fel');
            final Rect fr = _flagRect(
              stemX,
              stemY2,
              lineGap,
              stemDown,
              state.ritmus,
            );
            _drawKottaAsset(canvas, flgName, fr);
          }
        }
      }

      _drawAgogika(
        canvas,
        state,
        noteCenter: Offset(nx, cy),
        stemDown: stemDown,
        lineGap: lineGap,
      );
      _trackSlurPoint(state, Offset(nx, cy));
      _trackTupletPoint(state, Offset(nx, cy), stemDown, lineGap, noteW);

      if (state.pontozott) {
        final double dotSize = lineGap * 0.32;
        _drawKottaAsset(
          canvas,
          'pont',
          Rect.fromLTWH(nx2 + mw / 8.0, cy - dotSize, dotSize, dotSize),
        );
      }

      state.modosito = ' ';
      state.agogika = ' ';
      return;
    }
    if (c1 == '|') {
      _endBeam(canvas, state, lineGap);
      if (c2 == '|' && state.deferFinalDoubleBarAtEnd) {
        return;
      }
      final Paint barPaint = Paint()
        ..color = _kottaInkColor
        ..strokeWidth = 1.2;
      if (c2 == '1' || c2 == '|') {
        if (c2 == '|') {
          canvas.drawLine(
            Offset(x + lineGap * 0.8, top),
            Offset(x + lineGap * 0.8, top + lineGap * 4),
            barPaint,
          );
          canvas.drawLine(
            Offset(x + lineGap * 1.2, top),
            Offset(x + lineGap * 1.2, top + lineGap * 4),
            barPaint,
          );
        } else {
          canvas.drawLine(
            Offset(x + lineGap, top),
            Offset(x + lineGap, top + lineGap * 4),
            barPaint,
          );
        }
      } else if (c2 == '.') {
        canvas.drawLine(
          Offset(x + lineGap * 0.8, top),
          Offset(x + lineGap * 0.8, top + lineGap * 4),
          barPaint,
        );
        canvas.drawLine(
          Offset(x + lineGap * 1.2, top),
          Offset(x + lineGap * 1.2, top + lineGap * 4),
          barPaint..strokeWidth = 2.0,
        );
      } else if (c2 == "'") {
        final double x0 = x + lineGap;
        final double y1 = top - lineGap * 0.5;
        final double y2 = y1 + lineGap;
        canvas.drawLine(Offset(x0, y1), Offset(x0, y2), barPaint);
      } else if (c2 == '!') {
        final double x0 = x + lineGap;
        canvas.drawLine(
          Offset(x0, top - lineGap * 0.5),
          Offset(x0, top + lineGap * 2.5),
          barPaint,
        );
      } else if (c2 == '>' || c2 == ':' || c2 == '<') {
        _drawRepeatBarline(canvas, c2, x, top, lineGap, barPaint);
      } else {
        canvas.drawLine(
          Offset(x + lineGap, top),
          Offset(x + lineGap, top + lineGap * 4),
          barPaint,
        );
      }
      return;
    }
    if (c1 == 's' || c1 == 'S') {
      _endBeam(canvas, state, lineGap);
      final String? restName = switch (c2) {
        '1' => 'szunet1',
        '2' => 'szunet2',
        '4' => 'szunet4',
        '8' => 'szunet8',
        '6' => 'szunet16',
        _ => null,
      };
      if (restName != null) {
        _drawKottaAsset(
          canvas,
          restName,
          Rect.fromLTWH(
            x + lineGap * 0.3,
            top + lineGap * 0.6,
            lineGap * 1.4,
            lineGap * 2.6,
          ),
        );
        if (c1 == 'S') {
          _drawKottaAsset(
            canvas,
            'pont',
            Rect.fromLTWH(
              x + lineGap * 1.9,
              top + lineGap * 2.1,
              lineGap * 0.35,
              lineGap * 0.35,
            ),
          );
        }
      }
    }
  }

  void _drawCompactHeadConnector(
    Canvas canvas,
    _KottaDrawState state, {
    required double headLeft,
    required double headRight,
    required double headCenterY,
  }) {
    if (state.lastCompactHeadRight != null &&
        state.lastCompactHeadCenterY != null &&
        (state.lastCompactHeadRight! - headLeft).abs() < 0.01) {
      canvas.drawLine(
        Offset(headLeft, state.lastCompactHeadCenterY!),
        Offset(headLeft, headCenterY),
        Paint()
          ..color = _kottaInkColor
          ..strokeWidth = 1,
      );
    }
    state.lastCompactHeadRight = state.tomor && !state.pontozott
        ? headRight
        : null;
    state.lastCompactHeadCenterY = state.lastCompactHeadRight == null
        ? null
        : headCenterY;
  }

  void _drawRepeatBarline(
    Canvas canvas,
    String kind,
    double x,
    double top,
    double lineGap,
    Paint thinPaint,
  ) {
    final double y1 = top;
    final double y2 = top + lineGap * 4;
    final double centerY = (y1 + y2) / 2;
    final double unit = lineGap * 0.45;
    final Paint thickPaint = Paint()
      ..color = _kottaInkColor
      ..strokeWidth = math.max(2.0, thinPaint.strokeWidth * 2);

    void line(double lineX, Paint paint) {
      canvas.drawLine(Offset(lineX, y1), Offset(lineX, y2), paint);
    }

    void dots(double dotX) {
      final Paint dotPaint = Paint()..color = _kottaInkColor;
      final double radius = math.max(1.0, lineGap * 0.13);
      canvas.drawCircle(
        Offset(dotX, centerY - lineGap * 0.5),
        radius,
        dotPaint,
      );
      canvas.drawCircle(
        Offset(dotX, centerY + lineGap * 0.5),
        radius,
        dotPaint,
      );
    }

    final double centerX = x + lineGap;
    switch (kind) {
      case '>':
        line(centerX, thinPaint);
        line(centerX - unit * 2, thickPaint);
        dots(centerX + unit * 2);
        break;
      case ':':
        line(centerX, thickPaint);
        line(centerX - unit, thinPaint);
        line(centerX + unit, thinPaint);
        dots(centerX - unit * 2.5);
        dots(centerX + unit * 2.5);
        break;
      case '<':
        line(centerX, thinPaint);
        line(centerX + unit, thickPaint);
        dots(centerX - unit * 2);
        break;
    }
  }

  void _drawAgogika(
    Canvas canvas,
    _KottaDrawState state, {
    required Offset noteCenter,
    required bool stemDown,
    required double lineGap,
  }) {
    final String? assetName = switch (state.agogika) {
      '-' => 'tenuto',
      '.' => 'pont',
      '>' => 'marcato1',
      '^' => 'marcato2',
      'K' => stemDown ? 'koronale' : 'koronafel',
      'm' => 'mordent1',
      'M' => 'mordent2',
      't' => 'trilla1',
      'T' => 'trilla2',
      _ => null,
    };
    if (assetName == null) {
      return;
    }

    final ui.Image? image = KottaAssets.image(assetName);
    final _AgogikaMetrics metrics = _agogikaMetrics(assetName, image);
    final double height = metrics.height * lineGap / metrics.lineGap;
    final double width = metrics.width * lineGap / metrics.lineGap;
    double y = noteCenter.dy + (stemDown ? -lineGap : lineGap);
    if (state.agogika == '-' || state.agogika == '.') {
      y += height;
    }
    _drawKottaAsset(
      canvas,
      assetName,
      Rect.fromCenter(
        center: Offset(noteCenter.dx, y),
        width: width,
        height: height,
      ),
    );
  }

  _AgogikaMetrics _agogikaMetrics(String assetName, ui.Image? image) {
    final _AgogikaMetrics fallback = switch (assetName) {
      'tenuto' => const _AgogikaMetrics(66, 13, 53),
      'pont' => const _AgogikaMetrics(25, 25, 80),
      'marcato1' => const _AgogikaMetrics(128, 130, 135),
      'marcato2' => const _AgogikaMetrics(128, 130, 111),
      'koronafel' => const _AgogikaMetrics(169, 95, 99),
      'koronale' => const _AgogikaMetrics(169, 95, 109),
      'mordent1' => const _AgogikaMetrics(91, 103, 103),
      'mordent2' => const _AgogikaMetrics(91, 112, 112),
      'trilla1' => const _AgogikaMetrics(100, 83, 83),
      'trilla2' => const _AgogikaMetrics(100, 107, 107),
      _ => const _AgogikaMetrics(1, 1, 1),
    };
    if (image == null) {
      return fallback;
    }
    return _AgogikaMetrics(
      image.width.toDouble(),
      image.height.toDouble(),
      fallback.lineGap,
    );
  }

  void _trackSlurPoint(_KottaDrawState state, Offset noteCenter) {
    if (state.slurType != ' ') {
      state.slurEnd = noteCenter;
      state.slurPoints.add(noteCenter);
      return;
    }
    state.slurStart = noteCenter;
    state.slurEnd = noteCenter;
    state.slurPoints
      ..clear()
      ..add(noteCenter);
    if (state.slurNext != ' ') {
      state.slurType = state.slurNext;
      state.slurNext = ' ';
    }
  }

  void _endSlur(
    Canvas canvas,
    _KottaDrawState state,
    double lineGap, {
    String? forcedType,
  }) {
    final String t = forcedType ?? state.slurType;
    if (state.slurStart == null || state.slurEnd == null || t == ' ') {
      state.slurType = ' ';
      state.slurNext = ' ';
      state.slurPoints.clear();
      return;
    }
    final Offset s = state.slurStart!;
    final Offset e = state.slurEnd!;
    final bool down = t.toLowerCase() == 'a';
    final double slurYOffset = _slurYOffset(down: down, lineGap: lineGap);
    final Offset apex = _resolveSlurApex(
      state.slurPoints.isEmpty ? <Offset>[s, e] : state.slurPoints,
      down: down,
      lineGap: lineGap,
    );
    final double edgeOffset = math.max(1.0, lineGap * 0.25);
    final double innerY =
        apex.dy + slurYOffset + (down ? -edgeOffset : edgeOffset);
    final Offset c1 = Offset((s.dx * 3 + e.dx) / 4, apex.dy + slurYOffset);
    final Offset c2 = Offset((s.dx + e.dx * 3) / 4, apex.dy + slurYOffset);
    final Offset start = Offset(s.dx, s.dy + slurYOffset);
    final Offset end = Offset(e.dx, e.dy + slurYOffset);
    final Path p = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy)
      ..cubicTo(c2.dx, innerY, c1.dx, innerY, start.dx, start.dy)
      ..close();
    canvas.drawPath(p, Paint()..color = _kottaInkColor);
    state.slurType = ' ';
    state.slurNext = ' ';
    state.slurStart = null;
    state.slurEnd = null;
    state.slurPoints.clear();
  }

  Offset _resolveSlurApex(
    List<Offset> points, {
    required bool down,
    required double lineGap,
  }) {
    if (points.isEmpty) {
      return Offset.zero;
    }

    double extremeY = points.first.dy;
    for (final Offset point in points) {
      if (down) {
        extremeY = math.max(extremeY, point.dy);
      } else {
        extremeY = math.min(extremeY, point.dy);
      }
    }

    final double clearance = math.max(lineGap * 0.9, lineGap * 0.55);
    final double apexY = down ? extremeY + clearance : extremeY - clearance;
    final double apexX = (points.first.dx + points.last.dx) / 2.0;
    return Offset(apexX, apexY);
  }

  double _slurYOffset({required bool down, required double lineGap}) {
    return down ? lineGap : -lineGap;
  }

  void _trackTupletPoint(
    _KottaDrawState state,
    Offset noteCenter,
    bool stemDown,
    double lineGap,
    double headWidth,
  ) {
    if (state.triTipus != '3' && state.triTipus != '5') {
      return;
    }
    state.triLe = stemDown;
    final double y = stemDown
        ? noteCenter.dy + lineGap * 3.2
        : noteCenter.dy - lineGap * 3.2;
    state.triPos.add(
      _TupletPoint(x: noteCenter.dx, y: y, headWidth: headWidth),
    );
  }

  void _endTuplet(Canvas canvas, _KottaDrawState state, double lineGap) {
    final bool tri = state.triTipus == '3';
    final bool pent = state.triTipus == '5';
    if (!tri && !pent) {
      return;
    }
    if (state.triPos.length < 2) {
      state.triTipus = ' ';
      state.triPos.clear();
      return;
    }
    final _TupletPoint lp = state.triPos.first;
    final _TupletPoint rp = state.triPos.last;
    final double dx = rp.x - lp.x;
    double startY = lp.y;
    double endY = rp.y;

    if (dx.abs() > 0.0001) {
      for (int i = 1; i < state.triPos.length - 1; i++) {
        final _TupletPoint point = state.triPos[i];
        final double yOnLine =
            startY + ((endY - startY) * (point.x - lp.x)) / dx;
        final double yDiff = point.y - yOnLine;
        if (state.triLe ? yDiff > 0 : yDiff < 0) {
          startY += yDiff;
          endY += yDiff;
        }
      }
    }

    final double lineOffset = state.triLe ? lineGap * 0.5 : -lineGap * 0.5;
    startY += lineOffset;
    endY += lineOffset;

    final double startX = state.triLe ? lp.x - lp.headWidth : lp.x;
    final double endX = state.triLe ? rp.x : rp.x + rp.headWidth;
    final double startLineY = dx.abs() > 0.0001
        ? startY + ((endY - startY) * (startX - lp.x)) / dx
        : startY;
    final double endLineY = dx.abs() > 0.0001
        ? startY + ((endY - startY) * (endX - lp.x)) / dx
        : endY;

    final Paint p = Paint()
      ..color = _kottaInkColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(startX, startLineY), Offset(endX, endLineY), p);

    final double capLen = lineGap;
    final double capDir = state.triLe ? -1.0 : 1.0;
    canvas.drawLine(
      Offset(startX, startLineY),
      Offset(startX, startLineY + capDir * capLen),
      p,
    );
    canvas.drawLine(
      Offset(endX, endLineY),
      Offset(endX, endLineY + capDir * capLen),
      p,
    );

    final String img = tri ? 'triola' : 'pentola';
    final double numeralHeight = lineGap * 1.15;
    final Offset m = Offset(
      (startX + endX) / 2,
      ((startLineY + endLineY) / 2) +
          (state.triLe
              ? lineGap * 0.5 + numeralHeight / 2
              : -lineGap * 0.5 - numeralHeight / 2),
    );
    _drawKottaAsset(
      canvas,
      img,
      Rect.fromCenter(center: m, width: lineGap * 0.9, height: numeralHeight),
    );
    state.triTipus = ' ';
    state.triPos.clear();
  }

  void _endBeam(Canvas canvas, _KottaDrawState state, double lineGap) {
    if (state.beamStems.length < 2) {
      if (state.beamStems.length == 1) {
        final _BeamStem s = state.beamStems.first;
        canvas.drawLine(
          Offset(s.x, s.yHead),
          Offset(s.x, s.yTip),
          Paint()
            ..color = _kottaInkColor
            ..strokeWidth = 1.2,
        );
        _drawStandaloneFlag(canvas, s, lineGap);
      }
      state.beamStems.clear();
      return;
    }
    final List<_BeamStem> stems = state.beamStems;
    final _BeamStem first = stems.first;
    final _BeamStem last = stems.last;
    final bool down = first.down;
    final double beamThickness = lineGap * 0.45;
    final Paint beamPaint = Paint()
      ..color = _kottaInkColor
      ..strokeWidth = beamThickness;
    canvas.drawLine(
      Offset(first.x, first.yTip),
      Offset(last.x, last.yTip),
      beamPaint,
    );

    final double dx = last.x - first.x;
    for (final _BeamStem s in stems) {
      double yBeam = first.yTip;
      if (dx.abs() > 0.0001) {
        yBeam = first.yTip + (last.yTip - first.yTip) * ((s.x - first.x) / dx);
      }
      final double yEnd = down
          ? yBeam - beamThickness / 2
          : yBeam + beamThickness / 2;
      canvas.drawLine(
        Offset(s.x, s.yHead),
        Offset(s.x, yEnd),
        Paint()
          ..color = _kottaInkColor
          ..strokeWidth = 1.2,
      );
    }

    final bool has16 = stems.any((s) => s.rhythm == '6');
    if (has16) {
      final double off = down ? lineGap * 0.55 : -lineGap * 0.55;
      canvas.drawLine(
        Offset(first.x, first.yTip + off),
        Offset(last.x, last.yTip + off),
        beamPaint,
      );
    }
    state.beamStems.clear();
  }

  void _drawStandaloneFlag(Canvas canvas, _BeamStem stem, double lineGap) {
    final String flgName = stem.down
        ? (stem.rhythm == '6' ? 'zaszlo16le' : 'zaszlo8le')
        : (stem.rhythm == '6' ? 'zaszlo16fel' : 'zaszlo8fel');
    final Rect fr = _flagRect(
      stem.x,
      stem.yTip,
      lineGap,
      stem.down,
      stem.rhythm,
    );
    _drawKottaAsset(canvas, flgName, fr);
  }

  Rect _flagRect(
    double stemX,
    double stemYTip,
    double lineGap,
    bool down,
    String rhythm,
  ) {
    final double rat = lineGap / (_kcHang4V2a - _kcHang4V2f);
    final double stemWidth = _kcZaszloSzel * rat;
    final bool is16 = rhythm == '6';
    if (down) {
      final double w = _kcZaszlo8leW * rat;
      final double h = (is16 ? _kcZaszlo16leH : _kcZaszlo8leH) * rat;
      // Android parity: lower stem uses stem tip as flag bottom anchor.
      return Rect.fromLTWH(stemX, stemYTip - h, w, h);
    }
    final double w = _kcZaszlo8felW * rat;
    final double h = (is16 ? _kcZaszlo16felH : _kcZaszlo8felH) * rat;
    // Android parity: upper stem starts one stem-width left, with flag top at stem tip.
    return Rect.fromLTWH(stemX - stemWidth, stemYTip, w, h);
  }

  bool _drawKottaAsset(Canvas canvas, String assetName, Rect dst) {
    final ui.Image? img = KottaAssets.image(assetName);
    if (img == null) {
      return false;
    }
    final Rect src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final Paint p = Paint()
      ..colorFilter = ColorFilter.mode(_kottaInkColor, BlendMode.srcIn);
    canvas.drawImageRect(img, src, dst, p);
    return true;
  }

  _KottaNotePos? _notePos(String oktav, String note) {
    int l1;
    int l2;
    switch (note.toLowerCase()) {
      case 'g':
        l1 = 10;
        l2 = 9;
        break;
      case 'a':
        l1 = 9;
        l2 = 9;
        break;
      case 'h':
        l1 = 9;
        l2 = 8;
        break;
      case 'c':
        l1 = 8;
        l2 = 8;
        break;
      case 'd':
        l1 = 8;
        l2 = 7;
        break;
      case 'e':
        l1 = 7;
        l2 = 7;
        break;
      case 'f':
        l1 = 7;
        l2 = 6;
        break;
      default:
        return null;
    }
    if (oktav == '2') {
      if (l1 == l2) {
        l1 -= 3;
        l2 -= 4;
      } else {
        l1 -= 4;
        l2 -= 3;
      }
    } else if (oktav == '3') {
      l1 -= 7;
      l2 -= 7;
      if (l1 <= 0) {
        return null;
      }
    }
    return _KottaNotePos(
      l1: l1,
      l2: l2,
      centerIndex: (l1 + l2) / 2.0,
      betweenLines: l1 != l2,
    );
  }

  double _linePos(double top, double lineGap, int lineIndex) {
    return top + (lineIndex - 3) * lineGap;
  }

  List<_RenderLine> _parseRenderLines(List<String> lines) {
    final String cacheKey = lines.join('\u0001');
    final List<_RenderLine>? cached = _parsedLinesCache[cacheKey];
    if (cached != null) {
      return List<_RenderLine>.from(cached);
    }
    final List<_RenderLine> out = <_RenderLine>[];
    for (final String line in lines) {
      out.addAll(_parseOneLine(line));
    }
    _parsedLinesCache[cacheKey] = List<_RenderLine>.unmodifiable(out);
    while (_parsedLinesCache.length > _layoutCacheLimit) {
      _parsedLinesCache.remove(_parsedLinesCache.keys.first);
    }
    return List<_RenderLine>.from(out);
  }

  List<_RenderLine> _parseOneLine(String src) {
    final List<_RenderLine> result = <_RenderLine>[];
    final List<_WordToken> words = <_WordToken>[];
    final _WordStyle style = _WordStyle();
    final StringBuffer sb = StringBuffer();
    String? pendingChord;
    String? pendingKotta;

    void attachPendingToPrevWord() {
      if (words.isEmpty) {
        return;
      }
      if ((pendingChord == null || pendingChord!.isEmpty) &&
          (pendingKotta == null || pendingKotta!.isEmpty)) {
        return;
      }
      final _WordToken last = words.removeLast();
      final String? mergedChord = (() {
        final String a = (last.chord ?? '');
        final String b = (pendingChord ?? '');
        if (a.isEmpty) {
          return b.isEmpty ? null : b;
        }
        if (b.isEmpty) {
          return a;
        }
        return '$a$b';
      })();
      final String? mergedKotta = (() {
        final String a = (last.kotta ?? '');
        final String b = (pendingKotta ?? '');
        if (a.isEmpty) {
          return b.isEmpty ? null : b;
        }
        if (b.isEmpty) {
          return a;
        }
        return '$a$b';
      })();
      words.add(
        _WordToken(
          text: last.text,
          bold: last.bold,
          italic: last.italic,
          underline: last.underline,
          tieUnderline: last.tieUnderline,
          strike: last.strike,
          color: last.color,
          chord: mergedChord,
          kotta: mergedKotta,
          spaceAfter: last.spaceAfter,
          breakAfter: last.breakAfter,
          preferredBreakAfter: last.preferredBreakAfter,
          softHyphenAfter: last.softHyphenAfter,
          fontScale: last.fontScale,
        ),
      );
      pendingChord = null;
      pendingKotta = null;
    }

    void markPrevSpaceAfter() {
      if (words.isEmpty) {
        return;
      }
      final _WordToken last = words.removeLast();
      words.add(
        _WordToken(
          text: last.text,
          bold: last.bold,
          italic: last.italic,
          underline: last.underline,
          tieUnderline: last.tieUnderline,
          strike: last.strike,
          color: last.color,
          chord: last.chord,
          kotta: last.kotta,
          spaceAfter: true,
          breakAfter: true,
          preferredBreakAfter: last.preferredBreakAfter,
          softHyphenAfter: last.softHyphenAfter,
          fontScale: last.fontScale,
        ),
      );
    }

    void markPrevSoftHyphenAfter() {
      if (words.isEmpty) {
        return;
      }
      final _WordToken last = words.removeLast();
      words.add(
        _WordToken(
          text: last.text,
          bold: last.bold,
          italic: last.italic,
          underline: last.underline,
          tieUnderline: last.tieUnderline,
          strike: last.strike,
          color: last.color,
          chord: last.chord,
          kotta: last.kotta,
          spaceAfter: last.spaceAfter,
          breakAfter: true,
          preferredBreakAfter: last.preferredBreakAfter,
          softHyphenAfter: true,
          fontScale: last.fontScale,
        ),
      );
    }

    void flushWord({
      bool addSpaceAfter = false,
      bool addBreakAfter = false,
      bool addPreferredBreakAfter = false,
      bool addSoftHyphenAfter = false,
    }) {
      final String txt = sb.toString();
      sb.clear();
      if (txt.trim().isEmpty) {
        return;
      }
      words.add(
        _WordToken(
          text: txt,
          bold: style.bold,
          italic: style.italic,
          underline: style.underline,
          tieUnderline: style.tieUnderline,
          strike: style.strike,
          color: style.color,
          chord: pendingChord,
          kotta: pendingKotta,
          spaceAfter: addSpaceAfter,
          breakAfter: addBreakAfter,
          preferredBreakAfter: addPreferredBreakAfter,
          softHyphenAfter: addSoftHyphenAfter,
          fontScale: 1,
        ),
      );
      pendingChord = null;
      pendingKotta = null;
    }

    int i = 0;
    while (i < src.length) {
      final String ch = src[i];
      if (ch == '\\' && i + 1 < src.length) {
        final String cmd = src[i + 1];
        i += 2;
        switch (cmd) {
          case 'B':
            flushWord();
            style.bold = true;
            continue;
          case 'b':
            flushWord();
            style.bold = false;
            continue;
          case 'I':
            flushWord();
            style.italic = true;
            continue;
          case 'i':
            flushWord();
            style.italic = false;
            continue;
          case 'U':
            flushWord();
            style.underline = true;
            continue;
          case 'u':
            flushWord();
            style.underline = false;
            continue;
          case '(':
            flushWord();
            style.tieUnderline = true;
            continue;
          case ')':
            flushWord();
            style.tieUnderline = false;
            continue;
          case 'S':
            flushWord();
            style.strike = true;
            continue;
          case 's':
            flushWord();
            style.strike = false;
            continue;
          case '.':
            flushWord(
              addSpaceAfter: true,
              addBreakAfter: true,
              addPreferredBreakAfter: true,
            );
            continue;
          case '_':
            sb.write('-');
            continue;
          case '-':
            if (sb.isNotEmpty) {
              flushWord(addSoftHyphenAfter: true);
            } else {
              attachPendingToPrevWord();
              markPrevSoftHyphenAfter();
            }
            continue;
          case ' ': // non-breaking space marker
            sb.write('\u00A0');
            continue;
          case 'G':
            flushWord();
            attachPendingToPrevWord();
            final int end = src.indexOf(';', i);
            if (end > i) {
              pendingChord = src.substring(i, end);
              i = end + 1;
            }
            continue;
          case 'K':
            flushWord();
            attachPendingToPrevWord();
            final int endK = src.indexOf(';', i);
            if (endK > i) {
              pendingKotta = src.substring(i, endK);
              i = endK + 1;
            }
            continue;
          case 'C':
            flushWord();
            attachPendingToPrevWord();
            final int endC = src.indexOf(';', i);
            if (endC > i) {
              style.color = _parseColor(src.substring(i, endC));
              i = endC + 1;
            }
            continue;
          case '?':
            flushWord();
            attachPendingToPrevWord();
            if (i < src.length) {
              final String sub = src[i];
              i++;
              final int end = src.indexOf(';', i);
              if (end > i) {
                final String payload = src.substring(i, end);
                if (sub == 'G') {
                  pendingChord = payload;
                } else if (sub == 'K') {
                  pendingKotta = payload;
                } else if (sub == 'C') {
                  style.color = _parseColor(payload);
                }
                i = end + 1;
              }
            }
            continue;
          default:
            sb.write(cmd);
            continue;
        }
      }

      if (ch == ' ') {
        if (sb.isNotEmpty) {
          flushWord(addSpaceAfter: true, addBreakAfter: true);
        } else {
          attachPendingToPrevWord();
          // Space can arrive right after an escaped control block (\K, \G, etc.).
          // In that case there is no buffered text, so mark the previous token.
          markPrevSpaceAfter();
        }
      } else if (ch == '-') {
        sb.write('-');
        flushWord(addBreakAfter: true);
      } else {
        sb.write(ch);
      }
      i++;
    }

    flushWord();
    attachPendingToPrevWord();
    result.add(_RenderLine(words: List<_WordToken>.from(words)));
    return result;
  }

  Color? _parseColor(String hex) {
    final String h = hex.trim();
    if (h.isEmpty) {
      return null;
    }
    final int? v = int.tryParse(h, radix: 16);
    if (v == null) {
      return null;
    }
    return Color(0xFF000000 | v);
  }

  void _drawImage(Canvas canvas, Size size, ImageFrame frame, int mode) {
    final bool blankView =
        !globals.projecting || globals.showBlankPic || globals.isBlankPic;
    final Color fill = blankView
        ? _colorWithTransparency(globals.blankColor, globals.blankTrans)
        : _colorWithTransparency(globals.bkColor, globals.backTrans);
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);

    final ui.Image image = frame.image;
    final Rect src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    switch (mode) {
      case 0:
        final Offset pos = Offset(
          (size.width - src.width) / 2,
          (size.height - src.height) / 2,
        );
        canvas.drawImage(image, pos, Paint());
        return;
      case 2:
        final Rect dst = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawImageRect(image, src, dst, Paint());
        return;
      case 3:
        for (double y = 0; y < size.height; y += src.height) {
          for (double x = 0; x < size.width; x += src.width) {
            canvas.drawImage(image, Offset(x, y), Paint());
          }
        }
        return;
      case 4:
        // Mirror-mode is approximated using repeated mirrored tiles.
        final Paint p = Paint();
        for (double y = 0, row = 0; y < size.height; y += src.height, row++) {
          for (double x = 0, col = 0; x < size.width; x += src.width, col++) {
            canvas.save();
            canvas.translate(x, y);
            final bool flipX = col.toInt().isOdd;
            final bool flipY = row.toInt().isOdd;
            if (flipX || flipY) {
              canvas.translate(flipX ? src.width : 0, flipY ? src.height : 0);
              canvas.scale(flipX ? -1 : 1, flipY ? -1 : 1);
            }
            canvas.drawImage(image, Offset.zero, p);
            canvas.restore();
          }
        }
        return;
      case 1:
      default:
        final double scale = math.min(
          size.width / src.width,
          size.height / src.height,
        );
        final Size target = Size(src.width * scale, src.height * scale);
        final Rect dst = Rect.fromLTWH(
          (size.width - target.width) / 2,
          (size.height - target.height) / 2,
          target.width,
          target.height,
        );
        canvas.drawImageRect(image, src, dst, Paint());
        return;
    }
  }

  @override
  bool shouldRepaint(ProjectorPainter oldDelegate) {
    return !_sameFrame(oldDelegate.frame, frame) ||
        !_sameGlobals(oldDelegate.globals, globals) ||
        !_sameSettings(oldDelegate.settings, settings) ||
        oldDelegate.logoTitle != logoTitle ||
        oldDelegate.logoSubtitle != logoSubtitle;
  }

  bool _sameFrame(ProjectionFrame? a, ProjectionFrame? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null || a.runtimeType != b.runtimeType) {
      return false;
    }
    if (a is LogoFrame && b is LogoFrame) {
      return a.phase == b.phase;
    }
    if (a is ImageFrame && b is ImageFrame) {
      return identical(a.image, b.image) && a.bgMode == b.bgMode;
    }
    if (a is TextFrame && b is TextFrame) {
      return _sameTextRecord(a.record, b.record);
    }
    return false;
  }

  bool _sameTextRecord(dynamic a, dynamic b) {
    return a.scholaLine == b.scholaLine &&
        a.title == b.title &&
        listEquals(a.lines, b.lines);
  }

  bool _sameSettings(AppSettings a, AppSettings b) {
    return a.clipL == b.clipL &&
        a.clipT == b.clipT &&
        a.clipR == b.clipR &&
        a.clipB == b.clipB &&
        a.mirror == b.mirror &&
        a.rotateQuarterTurns == b.rotateQuarterTurns &&
        a.receiverUseAkkord == b.receiverUseAkkord &&
        a.receiverUseKotta == b.receiverUseKotta;
  }

  bool _sameGlobals(ProjectionGlobals a, ProjectionGlobals b) {
    return a.bkColor == b.bkColor &&
        a.txtColor == b.txtColor &&
        a.blankColor == b.blankColor &&
        a.hiColor == b.hiColor &&
        a.fontSize == b.fontSize &&
        a.titleSize == b.titleSize &&
        a.leftIndent == b.leftIndent &&
        a.spacing100 == b.spacing100 &&
        a.hKey == b.hKey &&
        a.wordToHighlight == b.wordToHighlight &&
        a.borderL == b.borderL &&
        a.borderT == b.borderT &&
        a.borderR == b.borderR &&
        a.borderB == b.borderB &&
        a.fontName == b.fontName &&
        a.isBlankPic == b.isBlankPic &&
        a.autoResize == b.autoResize &&
        a.projecting == b.projecting &&
        a.showBlankPic == b.showBlankPic &&
        a.hCenter == b.hCenter &&
        a.vCenter == b.vCenter &&
        a.scholaMode == b.scholaMode &&
        a.useAkkord == b.useAkkord &&
        a.useKotta == b.useKotta &&
        a.useTransitions == b.useTransitions &&
        a.endProgram == b.endProgram &&
        a.hideTitle == b.hideTitle &&
        a.inverzKotta == b.inverzKotta &&
        a.bgMode == b.bgMode &&
        a.kottaArany == b.kottaArany &&
        a.akkordArany == b.akkordArany &&
        a.backTrans == b.backTrans &&
        a.blankTrans == b.blankTrans &&
        a.borderToClip == b.borderToClip &&
        a.boldText == b.boldText;
  }

  Color _colorWithTransparency(Color color, int transparencyPercent) {
    final int clamped = transparencyPercent.clamp(0, 100);
    final int alpha = ((100 - clamped) * 255 / 100).round().clamp(0, 255);
    return color.withAlpha(alpha);
  }
}

class _RenderLine {
  const _RenderLine({required this.words});
  final List<_WordToken> words;
}

class _WordToken {
  const _WordToken({
    required this.text,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.tieUnderline,
    required this.strike,
    required this.color,
    this.chord,
    this.kotta,
    this.spaceAfter = false,
    this.breakAfter = false,
    this.preferredBreakAfter = false,
    this.softHyphenAfter = false,
    this.fontScale = 1,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool tieUnderline;
  final bool strike;
  final Color? color;
  final String? chord;
  final String? kotta;
  final bool spaceAfter;
  final bool breakAfter;
  final bool preferredBreakAfter;
  final bool softHyphenAfter;
  final double fontScale;

  bool get countAsWord => text.trim().isNotEmpty;
}

class _WordStyle {
  bool bold = false;
  bool italic = false;
  bool underline = false;
  bool tieUnderline = false;
  bool strike = false;
  Color? color;
}

class _AgogikaMetrics {
  const _AgogikaMetrics(this.width, this.height, this.lineGap);

  final double width;
  final double height;
  final double lineGap;
}

class _KottaDrawState {
  String kulcs = ' ';
  int elojegy = 0;
  String modosito = ' ';
  String ritmus = '4';
  bool pontozott = false;
  bool tomor = false;
  bool gerenda = false;
  bool szaaratlan = false;
  double? lastCompactHeadRight;
  double? lastCompactHeadCenterY;
  String agogika = ' ';
  int staffLineCount = 5;
  String slurType = ' ';
  String slurNext = ' ';
  Offset? slurStart;
  Offset? slurEnd;
  final List<Offset> slurPoints = <Offset>[];
  bool triLe = false;
  String triTipus = ' ';
  bool deferFinalDoubleBarAtEnd = false;
  final List<_TupletPoint> triPos = <_TupletPoint>[];
  final List<_BeamStem> beamStems = <_BeamStem>[];

  _KottaDrawState copy() {
    final _KottaDrawState c = _KottaDrawState();
    c.kulcs = kulcs;
    c.elojegy = elojegy;
    c.modosito = modosito;
    c.ritmus = ritmus;
    c.pontozott = pontozott;
    c.tomor = tomor;
    c.gerenda = gerenda;
    c.szaaratlan = szaaratlan;
    c.lastCompactHeadRight = lastCompactHeadRight;
    c.lastCompactHeadCenterY = lastCompactHeadCenterY;
    c.agogika = agogika;
    c.staffLineCount = staffLineCount;
    c.slurType = slurType;
    c.slurNext = slurNext;
    c.slurStart = slurStart;
    c.slurEnd = slurEnd;
    c.slurPoints.addAll(slurPoints);
    c.triLe = triLe;
    c.triTipus = triTipus;
    c.deferFinalDoubleBarAtEnd = deferFinalDoubleBarAtEnd;
    c.triPos.addAll(triPos);
    c.beamStems.addAll(beamStems);
    return c;
  }

  void resetTransient() {
    modosito = ' ';
    ritmus = '4';
    pontozott = false;
    tomor = false;
  }
}

class _TupletPoint {
  const _TupletPoint({
    required this.x,
    required this.y,
    required this.headWidth,
  });

  final double x;
  final double y;
  final double headWidth;
}

class _BeamStem {
  _BeamStem({
    required this.x,
    required this.yHead,
    required this.yTip,
    required this.down,
    required this.rhythm,
  });
  final double x;
  final double yHead;
  final double yTip;
  final bool down;
  final String rhythm;
}

class _KottaNotePos {
  const _KottaNotePos({
    required this.l1,
    required this.l2,
    required this.centerIndex,
    required this.betweenLines,
  });
  final int l1;
  final int l2;
  final double centerIndex;
  final bool betweenLines;
}

class _KottaWordLayout {
  const _KottaWordLayout({required this.wordIndex, required this.slotWidth});
  final int wordIndex;
  final double slotWidth;
}

class _KottaRowPrefix {
  const _KottaRowPrefix({required this.kotta, required this.width});

  const _KottaRowPrefix.empty() : kotta = '', width = 0;

  final String kotta;
  final double width;
}

class _KottaRowLayout {
  const _KottaRowLayout({
    required this.words,
    required this.width,
    this.prefix = const _KottaRowPrefix.empty(),
    this.inlinePrefix = const _KottaRowPrefix.empty(),
    this.endHyphen = false,
  });
  final List<_KottaWordLayout> words;
  final double width;
  final _KottaRowPrefix prefix;
  final _KottaRowPrefix inlinePrefix;
  final bool endHyphen;
}

class _TextRowLayout {
  const _TextRowLayout({
    required this.wordIndices,
    required this.width,
    this.indentWidth = 0,
    this.endHyphen = false,
  });
  final List<int> wordIndices;
  final double width;
  final double indentWidth;
  final bool endHyphen;
}

class _TextRowPaintLayout {
  const _TextRowPaintLayout({required this.painter, required this.wordLayouts});

  final TextPainter painter;
  final List<_TextWordLayout> wordLayouts;
}

class _TextWordLayout {
  const _TextWordLayout({
    required this.start,
    required this.end,
    required this.tieUnderline,
    required this.color,
  });

  final int start;
  final int end;
  final bool tieUnderline;
  final Color color;
}

class _KottaTextSlotLayout {
  const _KottaTextSlotLayout({
    required this.wordIndex,
    required this.left,
    required this.right,
    required this.baseline,
    required this.tieUnderline,
    required this.color,
    required this.connectorColor,
  });

  final int wordIndex;
  final double left;
  final double right;
  final double baseline;
  final bool tieUnderline;
  final Color color;
  final Color connectorColor;
}

class _PreparedTextLayout {
  const _PreparedTextLayout({
    required this.hasTitleLine,
    required this.titleFontSize,
    required this.lines,
    required this.textRowsByLine,
    required this.hasKottaByLine,
    required this.chordBandByLine,
    required this.kottaRowsByLine,
    required this.lineHeightsByLine,
    required this.bottomTextDescent,
  });

  final bool hasTitleLine;
  final double titleFontSize;
  final List<_RenderLine> lines;
  final List<List<_TextRowLayout>> textRowsByLine;
  final List<bool> hasKottaByLine;
  final List<double> chordBandByLine;
  final List<List<_KottaRowLayout>> kottaRowsByLine;
  final List<double> lineHeightsByLine;
  final double bottomTextDescent;
}

class _AutoSizeResult {
  const _AutoSizeResult({
    required this.fontSize,
    required this.preferPreferredBreaks,
  });

  final double fontSize;
  final bool preferPreferredBreaks;
}

const double _kcGkulcsW = 102.0;
const double _kcFkulcsW = 102.0;
const double _kcCkulcsW = 122.0;
const double _kcDkulcsW = 19.0;
const double _kcGkulcsH = 265.0;
const double _kcFkulcsH = 144.0;
const double _kcCkulcsH = 197.0;
const double _kcDkulcsH = 59.0;
const double _kcGkulcsV1 = 212.0;
const double _kcGkulcsV5 = 67.0;
const double _kcFkulcsV1 = 143.0;
const double _kcFkulcsV5 = 0.0;
const double _kcCkulcsV1 = 196.0;
const double _kcCkulcsV5 = 0.0;
const double _kcDkulcsV1 = 50.0;
const double _kcDkulcsV2 = 10.0;

const double _kcBeW = 43.0;
const double _kcBeBeW = 75.0;
const double _kcFeloldoW = 34.0;
const double _kcKeresztW = 50.0;
const double _kcKettosKeresztW = 58.0;
const double _kcBeH = 114.0;
const double _kcBeBeH = 114.0;
const double _kcFeloldoH = 106.0;
const double _kcKeresztH = 113.0;
const double _kcKettosKeresztH = 58.0;
const double _kcBeV1 = 83.0;
const double _kcBeV2a = 100.0;
const double _kcBeV2f = 67.0;
const double _kcBeBeV1 = 83.0;
const double _kcBeBeV2a = 100.0;
const double _kcBeBeV2f = 67.0;
const double _kcFeloldoV1 = 53.0;
const double _kcFeloldoV2a = 70.0;
const double _kcFeloldoV2f = 35.0;
const double _kcKeresztV1 = 55.0;
const double _kcKeresztV2a = 78.0;
const double _kcKeresztV2f = 35.0;
const double _kcKettosKeresztV1 = 29.0;
const double _kcKettosKeresztV2a = 49.0;
const double _kcKettosKeresztV2f = 7.0;

const double _kcHang0W = 106.0;
const double _kcHang1W = 92.0;
const double _kcHang2W = 67.0;
const double _kcHang4W = 67.0;
const double _kcHangBrevis1W = 119.0;
const double _kcHangBrevis2W = 154.0;
const double _kcHang0H = 79.0;
const double _kcHang1H = 58.0;
const double _kcHang2H = 54.0;
const double _kcHang4H = 54.0;
const double _kcHangBrevis1H = 56.0;
const double _kcHangBrevis2H = 56.0;
const double _kcHang0V1 = 40.0;
const double _kcHang0V2a = 73.0;
const double _kcHang0V2f = 6.0;
const double _kcHang1V1 = 29.0;
const double _kcHang1V2a = 57.0;
const double _kcHang1V2f = 0.0;
const double _kcHang2V1 = 26.0;
const double _kcHang2V2a = 53.0;
const double _kcHang2V2f = 0.0;
const double _kcHang4V1 = 26.0;
const double _kcHang4V2a = 53.0;
const double _kcHang4V2f = 0.0;
const double _kcHangBrevis1V1 = 28.0;
const double _kcHangBrevis1V2a = 55.0;
const double _kcHangBrevis1V2f = 0.0;
const double _kcHangBrevis2V1 = 28.0;
const double _kcHangBrevis2V2a = 55.0;
const double _kcHangBrevis2V2f = 0.0;

const double _kcPontW = 25.0;
const double _kcPontV = 80.0;
const double _kcU22W = 39.0;
const double _kcU22H = 170.0;

const double _kcSzunet1W = 110.0;
const double _kcSzunet2W = 125.0;
const double _kcSzunet4W = 81.0;
const double _kcSzunet8W = 58.0;
const double _kcSzunet16W = 77.0;
const double _kcSzunet1V = 60.0;
const double _kcSzunet2V = 60.0;
const double _kcSzunet4V2 = 175.0;
const double _kcSzunet4V4 = 54.0;
const double _kcSzunet8V2 = 122.0;
const double _kcSzunet8V4 = 0.0;
const double _kcSzunet16V2 = 141.0;
const double _kcSzunet16V4 = 0.0;

const double _kcZaszloSzel = 5.0;
const double _kcZaszlo8felW = 53.0;
const double _kcZaszlo8leW = 58.0;
const double _kcZaszlo16felH = 182.0;
const double _kcZaszlo16leH = 160.0;
const double _kcZaszlo8felH = 165.0;
const double _kcZaszlo8leH = 162.0;
