import 'package:flutter/material.dart';

enum ChordPartStyle { root, normal, superscript }

class ChordPart {
  const ChordPart(this.text, this.style);

  final String text;
  final ChordPartStyle style;
}

/// Parses and renders Diatár's compact chord notation.
class DiatarChord {
  const DiatarChord._({
    required this.root,
    required this.accidental,
    required this.isMinor,
    required this.modifier,
    required this.bass,
    required this.bassAccidental,
  });

  static const List<String> _inputModifiers = <String>[
    '',
    '#',
    'o',
    '7',
    '7+',
    'o7',
    'o7-',
    'o7+',
    '#7',
    '#7+',
    '6',
    '79',
    '79-',
    '79+',
    '#79',
    '#79+',
    '7+9',
    '7+9+',
    '#7+9',
    '#7+9+',
    'o79',
    'o79-',
    '9',
    '9-',
    '9+',
    '#9',
    '#9+',
    'o9',
    'o9-',
    '4',
    '2',
    '47',
    '27',
    '49',
    '49-',
    '49+',
  ];

  static const List<String> _outputModifiers = <String>[
    '',
    '+',
    'o',
    '7',
    '7+',
    'o/7',
    'o/7-',
    'o/7+',
    '+/7',
    '+/7+',
    '6',
    '7/9',
    '7/9-',
    '7/9+',
    '+/7/9',
    '+/7/9+',
    '7+/9',
    '7+/9+',
    '+/7+/9',
    '+/7+/9+',
    'o/7/9',
    'o/7/9-',
    '9',
    '9-',
    '9+',
    '+/9',
    '+/9+',
    'o/9',
    'o/9-',
    '4',
    '2',
    '4/7',
    '2/7',
    '4/9',
    '4/9-',
    '4/9+',
  ];

  static const Set<int> _minorModifiers = <int>{
    0,
    3,
    4,
    10,
    11,
    12,
    16,
    22,
    23,
  };

  final String root;
  final String? accidental;
  final bool isMinor;
  final int modifier;
  final String? bass;
  final String? bassAccidental;

  static List<String> get supportedModifiers =>
      List<String>.unmodifiable(_inputModifiers);

  String get rootCode => '$root${accidental ?? ''}';

  String get modifierCode => _inputModifiers[modifier];

  String? get bassCode => bass == null ? null : '$bass${bassAccidental ?? ''}';

  static bool supportsModifier(String modifier, {required bool minor}) {
    final int index = _inputModifiers.indexOf(modifier);
    return index >= 0 && (!minor || _minorModifiers.contains(index));
  }

  String get source {
    final StringBuffer result = StringBuffer()
      ..write(root)
      ..write(accidental ?? '');
    if (isMinor) {
      result.write('m');
    }
    result.write(_inputModifiers[modifier]);
    if (bass != null) {
      result
        ..write('/')
        ..write(bass)
        ..write(bassAccidental ?? '');
    }
    return result.toString();
  }

  String transpose(int semitones) {
    final bool useFlats = accidental == '-';
    final String transposedRoot = _transposeNote(
      root,
      accidental,
      semitones,
      useFlats: useFlats,
    );
    final StringBuffer result = StringBuffer(transposedRoot);
    if (isMinor) {
      result.write('m');
    }
    result.write(_inputModifiers[modifier]);
    if (bass != null) {
      result
        ..write('/')
        ..write(
          _transposeNote(bass!, bassAccidental, semitones, useFlats: useFlats),
        );
    }
    return result.toString();
  }

  static DiatarChord? tryParse(String source) {
    if (source.isEmpty) {
      return null;
    }

    final _ChordNote? rootNote = _parseNote(source, 0, allowMinor: true);
    if (rootNote == null) {
      return null;
    }

    final int slashIndex = source.indexOf('/', rootNote.end);
    if (slashIndex != -1 && source.indexOf('/', slashIndex + 1) != -1) {
      return null;
    }
    final String modifierText = source.substring(
      rootNote.end,
      slashIndex == -1 ? source.length : slashIndex,
    );
    final int modifier = _inputModifiers.indexOf(modifierText);
    if (modifier == -1 ||
        (rootNote.isMinor && !_minorModifiers.contains(modifier))) {
      return null;
    }

    _ChordNote? bassNote;
    if (slashIndex != -1) {
      bassNote = _parseNote(source, slashIndex + 1, allowMinor: false);
      if (bassNote == null || bassNote.end != source.length) {
        return null;
      }
    }

    return DiatarChord._(
      root: rootNote.letter,
      accidental: rootNote.accidental,
      isMinor: rootNote.isMinor,
      modifier: modifier,
      bass: bassNote?.letter,
      bassAccidental: bassNote?.accidental,
    );
  }

  static _ChordNote? _parseNote(
    String source,
    int start, {
    required bool allowMinor,
  }) {
    if (start >= source.length) {
      return null;
    }

    String letter = source[start].toUpperCase();
    if (letter == 'B') {
      letter = 'H';
    }
    if (!'CDEFGAH'.contains(letter)) {
      return null;
    }

    int end = start + 1;
    String? accidental;
    if (end < source.length && '+-'.contains(source[end])) {
      accidental = source[end++];
    }
    bool isMinor = false;
    if (allowMinor && end < source.length && source[end] == 'm') {
      isMinor = true;
      end++;
    }
    return _ChordNote(
      letter: letter,
      accidental: accidental,
      isMinor: isMinor,
      end: end,
    );
  }

  List<ChordPart> get parts {
    final List<ChordPart> result = <ChordPart>[
      ChordPart(_displayLetter(root, accidental, isMinor), ChordPartStyle.root),
    ];
    final String rootSuffix = _accidentalSuffix(root, accidental);
    if (rootSuffix.isNotEmpty) {
      result.add(ChordPart(rootSuffix, ChordPartStyle.normal));
    }
    if (isMinor) {
      result.add(const ChordPart('m', ChordPartStyle.normal));
    }
    if (modifier != 0) {
      result.add(
        ChordPart(_outputModifiers[modifier], ChordPartStyle.superscript),
      );
    }
    if (bass != null) {
      result.add(ChordPart('/', ChordPartStyle.normal));
      result.add(
        ChordPart(
          _displayLetter(bass!, bassAccidental, false),
          ChordPartStyle.normal,
        ),
      );
      final String bassSuffix = _accidentalSuffix(bass!, bassAccidental);
      if (bassSuffix.isNotEmpty) {
        result.add(ChordPart(bassSuffix, ChordPartStyle.normal));
      }
    }
    return result;
  }

  static String _displayLetter(
    String letter,
    String? accidental,
    bool isMinor,
  ) {
    final String display = letter == 'H' && accidental == '-' ? 'B' : letter;
    return isMinor ? display.toLowerCase() : display;
  }

  static String _accidentalSuffix(String letter, String? accidental) {
    if (accidental == '+') {
      return 'is';
    }
    if (accidental == '-') {
      if (letter == 'H') {
        return '';
      }
      return letter == 'E' || letter == 'A' ? 's' : 'es';
    }
    return '';
  }

  static String _transposeNote(
    String letter,
    String? accidental,
    int semitones, {
    required bool useFlats,
  }) {
    const Map<String, int> naturalSemitones = <String, int>{
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'H': 11,
    };
    const List<String> sharps = <String>[
      'C',
      'C+',
      'D',
      'D+',
      'E',
      'F',
      'F+',
      'G',
      'G+',
      'A',
      'A+',
      'H',
    ];
    const List<String> flats = <String>[
      'C',
      'D-',
      'D',
      'E-',
      'E',
      'F',
      'G-',
      'G',
      'A-',
      'A',
      'H-',
      'H',
    ];

    int pitch = naturalSemitones[letter]!;
    if (accidental == '+') {
      pitch++;
    } else if (accidental == '-') {
      pitch--;
    }
    final int transposed = (pitch + semitones) % 12;
    return (useFlats ? flats : sharps)[transposed];
  }
}

class ChordDisplay extends StatelessWidget {
  const ChordDisplay({
    super.key,
    required this.source,
    required this.style,
    this.borderColor,
    this.backgroundColor = Colors.transparent,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    this.borderRadius = 3,
  });

  final String source;
  final TextStyle style;
  final Color? borderColor;
  final Color backgroundColor;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle = DefaultTextStyle.of(
      context,
    ).style.merge(style);
    final ChordLayout layout = ChordRenderer.layout(source, effectiveStyle);
    final Size size = Size(
      layout.width + padding.horizontal,
      layout.height + padding.vertical,
    );
    final Color effectiveBorderColor =
        borderColor ??
        effectiveStyle.color ??
        Theme.of(context).colorScheme.outline;
    return Semantics(
      label: source,
      child: CustomPaint(
        size: size,
        painter: _ChordDisplayPainter(
          layout: layout,
          padding: padding,
          borderColor: effectiveBorderColor,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class _ChordDisplayPainter extends CustomPainter {
  const _ChordDisplayPainter({
    required this.layout,
    required this.padding,
    required this.borderColor,
    required this.backgroundColor,
    required this.borderRadius,
  });

  final ChordLayout layout;
  final EdgeInsets padding;
  final Color borderColor;
  final Color backgroundColor;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    if (backgroundColor.a > 0) {
      canvas.drawRRect(frame, Paint()..color = backgroundColor);
    }
    canvas.drawRRect(
      frame,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    layout.paint(canvas, Offset(padding.left, padding.top));
  }

  @override
  bool shouldRepaint(_ChordDisplayPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.padding != padding ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class _ChordNote {
  const _ChordNote({
    required this.letter,
    required this.accidental,
    required this.isMinor,
    required this.end,
  });

  final String letter;
  final String? accidental;
  final bool isMinor;
  final int end;
}

/// Lays out a chord so every consumer uses the same notation and styling.
class ChordRenderer {
  static ChordLayout layout(String source, TextStyle style) {
    final DiatarChord? chord = DiatarChord.tryParse(source);
    final List<ChordPart> parts =
        chord?.parts ?? <ChordPart>[ChordPart(source, ChordPartStyle.normal)];
    return ChordLayout._(parts, style);
  }
}

class ChordLayout {
  ChordLayout._(List<ChordPart> parts, TextStyle style)
    : _painters = <TextPainter>[
        for (final ChordPart part in parts)
          TextPainter(
            text: TextSpan(
              text: part.text,
              style: switch (part.style) {
                ChordPartStyle.root => style.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                ChordPartStyle.normal => style,
                ChordPartStyle.superscript => style.copyWith(
                  fontSize: (style.fontSize ?? 14) * 0.7,
                ),
              },
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
      ];

  final List<TextPainter> _painters;

  double get width => _painters.fold(
    0,
    (double total, TextPainter painter) => total + painter.width,
  );

  double get height => _painters.fold(
    0,
    (double maximum, TextPainter painter) =>
        maximum > painter.height ? maximum : painter.height,
  );

  void paint(Canvas canvas, Offset offset) {
    double x = offset.dx;
    for (final TextPainter painter in _painters) {
      painter.paint(canvas, Offset(x, offset.dy));
      x += painter.width;
    }
  }
}
