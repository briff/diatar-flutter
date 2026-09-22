import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:super_clipboard/super_clipboard.dart';

import 'chord_editor_dialog.dart';
import 'chord_renderer.dart';

enum InlineTextStyle { bold, italic, underline, strike, tieUnderline }

const String inlineCommandPlaceholder = '\uFFFC';

enum InlineTextSpecialCharacter {
  conditionalHyphen,
  nonBreakingSpace,
  nonBreakingHyphen,
  preferredLineBreak,
}

const List<InlineTextStyle> _styleOrder = <InlineTextStyle>[
  InlineTextStyle.bold,
  InlineTextStyle.italic,
  InlineTextStyle.underline,
  InlineTextStyle.strike,
  InlineTextStyle.tieUnderline,
];

extension on InlineTextStyle {
  String get enableMarker => switch (this) {
    InlineTextStyle.bold => r'\B',
    InlineTextStyle.italic => r'\I',
    InlineTextStyle.underline => r'\U',
    InlineTextStyle.strike => r'\S',
    InlineTextStyle.tieUnderline => r'\(',
  };

  String get disableMarker => switch (this) {
    InlineTextStyle.bold => r'\b',
    InlineTextStyle.italic => r'\i',
    InlineTextStyle.underline => r'\u',
    InlineTextStyle.strike => r'\s',
    InlineTextStyle.tieUnderline => r'\)',
  };
}

enum _InlineTextElementKind {
  text,
  nonBreakingSpace,
  softHyphen,
  nonBreakingHyphen,
  preferredLineBreak,
  command,
}

extension InlineTextSpecialCharacterDetails on InlineTextSpecialCharacter {
  _InlineTextElementKind get _kind => switch (this) {
    InlineTextSpecialCharacter.conditionalHyphen =>
      _InlineTextElementKind.softHyphen,
    InlineTextSpecialCharacter.nonBreakingSpace =>
      _InlineTextElementKind.nonBreakingSpace,
    InlineTextSpecialCharacter.nonBreakingHyphen =>
      _InlineTextElementKind.nonBreakingHyphen,
    InlineTextSpecialCharacter.preferredLineBreak =>
      _InlineTextElementKind.preferredLineBreak,
  };

  String get visibleCharacter => switch (this) {
    InlineTextSpecialCharacter.conditionalHyphen => '\u00AD',
    InlineTextSpecialCharacter.nonBreakingSpace => '\u00A0',
    InlineTextSpecialCharacter.nonBreakingHyphen => '\u2011',
    InlineTextSpecialCharacter.preferredLineBreak => '\n',
  };

  String get editorSymbol => switch (this) {
    InlineTextSpecialCharacter.conditionalHyphen => '\u00AC',
    InlineTextSpecialCharacter.nonBreakingSpace => '\u2423',
    InlineTextSpecialCharacter.nonBreakingHyphen => '\u2E17',
    InlineTextSpecialCharacter.preferredLineBreak => '\u21B5',
  };
}

class _InlineTextElement {
  const _InlineTextElement({
    required this.kind,
    required this.styles,
    required this.visibleCharacter,
    this.rawCommand,
  });

  final _InlineTextElementKind kind;
  final Set<InlineTextStyle> styles;
  final String visibleCharacter;
  final String? rawCommand;

  bool get isCommand => kind == _InlineTextElementKind.command;

  String? get chordSource {
    final String? command = rawCommand;
    if (command == null || !command.endsWith(';')) {
      return null;
    }
    if (command.startsWith(r'\G')) {
      return command.substring(2, command.length - 1);
    }
    if (command.startsWith(r'\?G')) {
      return command.substring(3, command.length - 1);
    }
    return null;
  }

  String get clipboardText => chordSource ?? rawCommand ?? visibleCharacter;

  String get editorCharacter => switch (kind) {
    _InlineTextElementKind.softHyphen =>
      InlineTextSpecialCharacter.conditionalHyphen.editorSymbol,
    _InlineTextElementKind.nonBreakingSpace =>
      InlineTextSpecialCharacter.nonBreakingSpace.editorSymbol,
    _InlineTextElementKind.nonBreakingHyphen =>
      InlineTextSpecialCharacter.nonBreakingHyphen.editorSymbol,
    _InlineTextElementKind.preferredLineBreak =>
      InlineTextSpecialCharacter.preferredLineBreak.editorSymbol,
    _ => visibleCharacter,
  };

  _InlineTextElement copyWithStyles(Set<InlineTextStyle> newStyles) {
    return _InlineTextElement(
      kind: kind,
      styles: Set<InlineTextStyle>.unmodifiable(newStyles),
      visibleCharacter: visibleCharacter,
      rawCommand: rawCommand,
    );
  }
}

/// Editable logical representation of DIA inline formatting.
///
/// Every element has exactly one UTF-16 code unit in [visibleText]. This
/// matches [TextEditingController] selection offsets while keeping commands
/// that have no editable source representation as indivisible placeholders.
class InlineTextDocument {
  InlineTextDocument._(this._elements);

  factory InlineTextDocument.decode(String diaText) {
    final List<_InlineTextElement> elements = <_InlineTextElement>[];
    final Set<InlineTextStyle> activeStyles = <InlineTextStyle>{};

    void addElement(
      _InlineTextElementKind kind,
      String visibleCharacter, {
      String? rawCommand,
    }) {
      elements.add(
        _InlineTextElement(
          kind: kind,
          styles: Set<InlineTextStyle>.unmodifiable(activeStyles),
          visibleCharacter: visibleCharacter,
          rawCommand: rawCommand,
        ),
      );
    }

    for (int index = 0; index < diaText.length;) {
      if (diaText[index] != '\\' || index + 1 >= diaText.length) {
        addElement(_InlineTextElementKind.text, diaText[index]);
        index++;
        continue;
      }

      final String command = diaText[index + 1];
      final InlineTextStyle? style = switch (command) {
        'B' || 'b' => InlineTextStyle.bold,
        'I' || 'i' => InlineTextStyle.italic,
        'U' || 'u' => InlineTextStyle.underline,
        'S' || 's' => InlineTextStyle.strike,
        '(' || ')' => InlineTextStyle.tieUnderline,
        _ => null,
      };
      if (style != null) {
        if (command == style.enableMarker[1]) {
          activeStyles.add(style);
        } else {
          activeStyles.remove(style);
        }
        index += 2;
        continue;
      }

      switch (command) {
        case '\\':
          addElement(_InlineTextElementKind.text, '\\');
          index += 2;
        case ' ':
          addElement(_InlineTextElementKind.nonBreakingSpace, '\u00A0');
          index += 2;
        case '-':
          addElement(_InlineTextElementKind.softHyphen, '\u00AD');
          index += 2;
        case '_':
          addElement(_InlineTextElementKind.nonBreakingHyphen, '\u2011');
          index += 2;
        case '.':
          addElement(_InlineTextElementKind.preferredLineBreak, '\n');
          index += 2;
        case 'K':
        case 'G':
        case '?':
          final int end = diaText.indexOf(';', index + 2);
          if (end >= index + 2) {
            addElement(
              _InlineTextElementKind.command,
              inlineCommandPlaceholder,
              rawCommand: diaText.substring(index, end + 1),
            );
            index = end + 1;
          } else {
            addElement(_InlineTextElementKind.text, '\\');
            index++;
          }
        default:
          // Preserve unrecognised commands as atomic elements so newer DIA
          // markup cannot be split by an ordinary text edit.
          addElement(
            _InlineTextElementKind.command,
            inlineCommandPlaceholder,
            rawCommand: diaText.substring(index, index + 2),
          );
          index += 2;
      }
    }

    return InlineTextDocument._(elements);
  }

  final List<_InlineTextElement> _elements;

  InlineTextDocument copyRange(int start, int end) {
    final int rangeStart = start.clamp(0, _elements.length);
    final int rangeEnd = end.clamp(rangeStart, _elements.length);
    return InlineTextDocument._(
      List<_InlineTextElement>.from(_elements.sublist(rangeStart, rangeEnd)),
    );
  }

  void replaceRangeWithDocument(
    int start,
    int end,
    InlineTextDocument replacement,
  ) {
    final int rangeStart = start.clamp(0, _elements.length);
    final int rangeEnd = end.clamp(rangeStart, _elements.length);
    _elements.replaceRange(rangeStart, rangeEnd, replacement._elements);
  }

  String get visibleText =>
      _elements.map((element) => element.visibleCharacter).join();

  String get plainText =>
      _elements.map((element) => element.clipboardText).join();

  Set<InlineTextStyle> stylesForInsertionAt(int offset) {
    if (_elements.isEmpty) {
      return <InlineTextStyle>{};
    }
    final int clampedOffset = offset.clamp(0, _elements.length);
    final int elementIndex = clampedOffset == 0 ? 0 : clampedOffset - 1;
    return Set<InlineTextStyle>.from(_elements[elementIndex].styles);
  }

  bool isStyleActiveForRange(InlineTextStyle style, int start, int end) {
    final int rangeStart = start.clamp(0, _elements.length);
    final int rangeEnd = end.clamp(rangeStart, _elements.length);
    return rangeStart < rangeEnd &&
        _elements
            .sublist(rangeStart, rangeEnd)
            .every((element) => element.styles.contains(style));
  }

  void setStyle(
    InlineTextStyle style,
    int start,
    int end, {
    required bool enabled,
  }) {
    final int rangeStart = start.clamp(0, _elements.length);
    final int rangeEnd = end.clamp(rangeStart, _elements.length);
    for (int index = rangeStart; index < rangeEnd; index++) {
      final Set<InlineTextStyle> styles = Set<InlineTextStyle>.from(
        _elements[index].styles,
      );
      if (enabled) {
        styles.add(style);
      } else {
        styles.remove(style);
      }
      _elements[index] = _elements[index].copyWithStyles(styles);
    }
  }

  void replaceVisibleRange(
    int start,
    int end,
    String replacement, {
    required Set<InlineTextStyle> styles,
  }) {
    final int rangeStart = start.clamp(0, _elements.length);
    final int rangeEnd = end.clamp(rangeStart, _elements.length);
    _elements.replaceRange(
      rangeStart,
      rangeEnd,
      replacement.codeUnits.map(
        (int codeUnit) => _InlineTextElement(
          kind: _InlineTextElementKind.text,
          styles: Set<InlineTextStyle>.unmodifiable(styles),
          visibleCharacter: String.fromCharCode(codeUnit),
        ),
      ),
    );
  }

  void replaceVisibleRangeWithSpecialCharacter(
    int start,
    int end,
    InlineTextSpecialCharacter character, {
    required Set<InlineTextStyle> styles,
  }) {
    final int rangeStart = start.clamp(0, _elements.length);
    final int rangeEnd = end.clamp(rangeStart, _elements.length);
    _elements.replaceRange(rangeStart, rangeEnd, <_InlineTextElement>[
      _InlineTextElement(
        kind: character._kind,
        styles: Set<InlineTextStyle>.unmodifiable(styles),
        visibleCharacter: character.visibleCharacter,
      ),
    ]);
  }

  /// Returns DIA markup with deterministic transitions and escaped literals.
  String encode() {
    final StringBuffer result = StringBuffer();
    final Set<InlineTextStyle> activeStyles = <InlineTextStyle>{};
    for (int index = 0; index < _elements.length; index++) {
      final _InlineTextElement element = _elements[index];
      if (element.isCommand) {
        _writeStyleTransition(result, activeStyles, element.styles);
        result.write(element.rawCommand);
        continue;
      }
      _writeStyleTransition(result, activeStyles, element.styles);
      result.write(switch (element.kind) {
        _InlineTextElementKind.text =>
          element.visibleCharacter == '\\' ? r'\\' : element.visibleCharacter,
        _InlineTextElementKind.nonBreakingSpace => r'\ ',
        _InlineTextElementKind.softHyphen => r'\-',
        _InlineTextElementKind.nonBreakingHyphen => r'\_',
        _InlineTextElementKind.preferredLineBreak => r'\.',
        _InlineTextElementKind.command => throw StateError('Unreachable'),
      });
    }
    _writeStyleTransition(result, activeStyles, const <InlineTextStyle>{});
    return result.toString();
  }
}

class InlineChordCommand {
  const InlineChordCommand({
    required this.offset,
    required this.source,
    required this.chord,
  });

  final int offset;
  final String source;
  final DiatarChord? chord;
}

void _writeStyleTransition(
  StringBuffer result,
  Set<InlineTextStyle> activeStyles,
  Set<InlineTextStyle> targetStyles,
) {
  for (final InlineTextStyle style in _styleOrder) {
    if (activeStyles.contains(style) && !targetStyles.contains(style)) {
      result.write(style.disableMarker);
      activeStyles.remove(style);
    }
  }
  for (final InlineTextStyle style in _styleOrder) {
    if (!activeStyles.contains(style) && targetStyles.contains(style)) {
      result.write(style.enableMarker);
      activeStyles.add(style);
    }
  }
}

/// Converts DIA inline documents to and from clipboard representations.
///
/// The private DIA format preserves commands such as chords and notation. HTML
/// and RTF provide interoperable rich text for office applications.
class InlineTextClipboardContent {
  const InlineTextClipboardContent({
    required this.document,
    required this.plainText,
  });

  final InlineTextDocument document;
  final String? plainText;
}

class InlineTextClipboard {
  InlineTextClipboard._();

  static const CustomValueFormat<String> _diaFormat = CustomValueFormat<String>(
    applicationId: 'eu.diatar.inline-text',
  );
  static const SimpleValueFormat<String> _rtfFormat = SimpleValueFormat<String>(
    android: SimplePlatformCodec<String>(formats: <String>['text/rtf']),
    ios: SimplePlatformCodec<String>(formats: <String>['public.rtf']),
    macos: SimplePlatformCodec<String>(formats: <String>['public.rtf']),
    windows: SimplePlatformCodec<String>(formats: <String>['Rich Text Format']),
    fallback: SimplePlatformCodec<String>(formats: <String>['application/rtf']),
  );

  static Future<void> copy(InlineTextDocument document) async {
    final SystemClipboard? clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      await Clipboard.setData(ClipboardData(text: document.plainText));
      return;
    }
    final DataWriterItem item = DataWriterItem()
      ..add(_diaFormat(document.encode()))
      ..add(Formats.htmlText(toHtml(document)))
      ..add(_rtfFormat(toRtf(document)))
      ..add(Formats.plainText(document.plainText));
    await clipboard.write(<DataWriterItem>[item]);
  }

  static Future<InlineTextClipboardContent?> read() async {
    final SystemClipboard? clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text == null
          ? null
          : InlineTextClipboardContent(
              document: InlineTextDocument.decode(data!.text!),
              plainText: data.text,
            );
    }
    final ClipboardReader reader = await clipboard.read();
    final Future<String?> plainText = reader.readValue(Formats.plainText);
    final String? dia = await reader.readValue(_diaFormat);
    if (dia != null) {
      return InlineTextClipboardContent(
        document: InlineTextDocument.decode(dia),
        plainText: await plainText,
      );
    }
    final String? html = await reader.readValue(Formats.htmlText);
    if (html != null) {
      return InlineTextClipboardContent(
        document: fromHtml(html),
        plainText: await plainText,
      );
    }
    final String? rtf = await reader.readValue(_rtfFormat);
    if (rtf != null) {
      return InlineTextClipboardContent(
        document: fromRtf(rtf),
        plainText: await plainText,
      );
    }
    final String? text = await plainText;
    return text == null
        ? null
        : InlineTextClipboardContent(
            document: InlineTextDocument.decode(text),
            plainText: text,
          );
  }

  static String toHtml(InlineTextDocument document) {
    final StringBuffer result = StringBuffer('<span data-diatar-inline="1">');
    for (final _InlineTextElement element in document._elements) {
      final String text = element.isCommand
          ? element.clipboardText
          : element.visibleCharacter;
      final String content = _escapeHtml(text);
      if (element.isCommand) {
        result.write(
          '<span data-diatar-command="${_escapeHtmlAttribute(element.rawCommand!)}">$content</span>',
        );
        continue;
      }
      String wrapped = element.kind == _InlineTextElementKind.preferredLineBreak
          ? '<br data-diatar-preferred-break="1">'
          : content;
      for (final InlineTextStyle style in _styleOrder.reversed) {
        if (element.styles.contains(style)) {
          wrapped = switch (style) {
            InlineTextStyle.bold => '<strong>$wrapped</strong>',
            InlineTextStyle.italic => '<em>$wrapped</em>',
            InlineTextStyle.underline => '<u>$wrapped</u>',
            InlineTextStyle.strike => '<s>$wrapped</s>',
            InlineTextStyle.tieUnderline =>
              '<span data-diatar-tie-underline="1"><u>$wrapped</u></span>',
          };
        }
      }
      result.write(wrapped);
    }
    result.write('</span>');
    return result.toString();
  }

  static String toRtf(InlineTextDocument document) {
    final StringBuffer result = StringBuffer(r'{\rtf1\ansi\deff0 ');
    Set<InlineTextStyle> active = <InlineTextStyle>{};
    for (final _InlineTextElement element in document._elements) {
      _writeRtfStyleTransition(result, active, element.styles);
      if (element.isCommand) {
        _writeRtfText(result, element.clipboardText);
      } else if (element.kind == _InlineTextElementKind.preferredLineBreak) {
        result.write(r'\line ');
      } else {
        _writeRtfText(result, element.visibleCharacter);
      }
    }
    _writeRtfStyleTransition(result, active, const <InlineTextStyle>{});
    return '${result.toString()}}';
  }

  static InlineTextDocument fromHtml(String source) {
    final StringBuffer dia = StringBuffer();
    final Set<InlineTextStyle> activeStyles = <InlineTextStyle>{};
    bool suppressLeadingWhitespace = false;

    void writeText(String text, Set<InlineTextStyle> styles) {
      String normalized = text.replaceAll(RegExp(r'[ \t\r\n\f]+'), ' ');
      if (suppressLeadingWhitespace) {
        normalized = normalized.replaceFirst(RegExp(r'^ +'), '');
      }
      if (normalized.isEmpty) {
        return;
      }
      for (final int codeUnit in normalized.codeUnits) {
        final String character = String.fromCharCode(codeUnit);
        _writeStyleTransition(dia, activeStyles, styles);
        dia.write(switch (character) {
          '\\' => r'\\',
          '\u00A0' => r'\ ',
          '\u00AD' => r'\-',
          '\u2011' => r'\_',
          '\n' => r'\.',
          _ => character,
        });
      }
      suppressLeadingWhitespace = false;
    }

    void writePreferredLineBreak(Set<InlineTextStyle> styles) {
      _writeStyleTransition(dia, activeStyles, styles);
      dia.write(r'\.');
      suppressLeadingWhitespace = true;
    }

    void writeHardLineBreak(Set<InlineTextStyle> styles) {
      _writeStyleTransition(dia, activeStyles, styles);
      dia.write('\n');
      suppressLeadingWhitespace = true;
    }

    void visit(dom.Node node, Set<InlineTextStyle> inherited) {
      if (node is dom.Text) {
        if (node.data.trim().isEmpty && RegExp(r'[\r\n]').hasMatch(node.data)) {
          return;
        }
        writeText(node.data, inherited);
        return;
      }
      if (node is! dom.Element) {
        return;
      }
      final String? command = node.attributes['data-diatar-command'];
      if (command != null) {
        _writeStyleTransition(dia, activeStyles, inherited);
        dia.write(command);
        return;
      }
      final String tag = node.localName?.toLowerCase() ?? '';
      if (tag == 'br') {
        if (node.attributes['data-diatar-preferred-break'] == '1') {
          writePreferredLineBreak(inherited);
        } else {
          writeHardLineBreak(inherited);
        }
        return;
      }
      final Set<InlineTextStyle> styles = Set<InlineTextStyle>.from(inherited);
      if (<String>{'b', 'strong'}.contains(tag)) {
        styles.add(InlineTextStyle.bold);
      }
      if (<String>{'i', 'em'}.contains(tag)) styles.add(InlineTextStyle.italic);
      if (tag == 'u') styles.add(InlineTextStyle.underline);
      if (<String>{'s', 'strike', 'del'}.contains(tag)) {
        styles.add(InlineTextStyle.strike);
      }
      final String css = node.attributes['style']?.toLowerCase() ?? '';
      if (RegExp(r'font-weight\s*:\s*(bold|[6-9]00)').hasMatch(css)) {
        styles.add(InlineTextStyle.bold);
      }
      if (RegExp(r'font-style\s*:\s*italic').hasMatch(css)) {
        styles.add(InlineTextStyle.italic);
      }
      if (RegExp(r'text-decoration[^;]*underline').hasMatch(css)) {
        styles.add(InlineTextStyle.underline);
      }
      if (RegExp(r'text-decoration[^;]*(line-through|strike)').hasMatch(css)) {
        styles.add(InlineTextStyle.strike);
      }
      for (final dom.Node child in node.nodes) {
        visit(child, styles);
      }
      if (<String>{'p', 'div', 'li'}.contains(tag) &&
          dia.isNotEmpty &&
          !dia.toString().endsWith('\n')) {
        writeHardLineBreak(styles);
      }
    }

    final dom.DocumentFragment document = html_parser.parseFragment(source);
    for (final dom.Node node in document.nodes) {
      visit(node, const <InlineTextStyle>{});
    }
    _writeStyleTransition(dia, activeStyles, const <InlineTextStyle>{});
    return InlineTextDocument.decode(dia.toString());
  }

  static InlineTextDocument fromRtf(String source) {
    final StringBuffer dia = StringBuffer();
    final List<Set<InlineTextStyle>> styles = <Set<InlineTextStyle>>[
      <InlineTextStyle>{},
    ];
    final List<bool> skipped = <bool>[false];
    final Set<InlineTextStyle> activeStyles = <InlineTextStyle>{};
    final Set<String> skippedDestinations = <String>{
      'colortbl',
      'fonttbl',
      'stylesheet',
      'info',
      'pict',
      'object',
    };

    void writeText(String text) {
      if (skipped.last) return;
      final Set<InlineTextStyle> current = styles.last;
      _writeStyleTransition(dia, activeStyles, current);
      for (final int codeUnit in text.codeUnits) {
        final String character = String.fromCharCode(codeUnit);
        dia.write(switch (character) {
          '\\' => r'\\',
          '\u00A0' => r'\ ',
          '\u00AD' => r'\-',
          '\u2011' => r'\_',
          '\n' => r'\.',
          _ => character,
        });
      }
    }

    for (int index = 0; index < source.length; index++) {
      final String character = source[index];
      if (character == '{') {
        styles.add(Set<InlineTextStyle>.from(styles.last));
        skipped.add(skipped.last);
        continue;
      }
      if (character == '}') {
        if (styles.length > 1) {
          styles.removeLast();
          skipped.removeLast();
        }
        continue;
      }
      if (character != '\\') {
        writeText(character);
        continue;
      }
      if (++index >= source.length) break;
      final String first = source[index];
      if (<String>{'\\', '{', '}'}.contains(first)) {
        writeText(first);
        continue;
      }
      if (first == '~') {
        writeText('\u00A0');
        continue;
      }
      if (first == '-') {
        writeText('\u00AD');
        continue;
      }
      if (first == '_') {
        writeText('\u2011');
        continue;
      }
      if (first == '*') {
        skipped[skipped.length - 1] = true;
        continue;
      }
      final int wordStart = index;
      while (index < source.length &&
          RegExp(r'[A-Za-z]').hasMatch(source[index])) {
        index++;
      }
      final String word = source.substring(wordStart, index);
      int? parameter;
      final int parameterStart = index;
      if (index < source.length &&
          (source[index] == '-' || source[index] == '+')) {
        index++;
      }
      while (index < source.length && RegExp(r'\d').hasMatch(source[index])) {
        index++;
      }
      if (index > parameterStart) {
        parameter = int.tryParse(source.substring(parameterStart, index));
      }
      if (index < source.length && source[index] == ' ') {
        index++;
      }
      index--;
      if (skippedDestinations.contains(word)) {
        skipped[skipped.length - 1] = true;
        continue;
      }
      if (skipped.last) continue;
      final Set<InlineTextStyle> current = styles.last;
      switch (word) {
        case 'b':
          _setStyle(current, InlineTextStyle.bold, parameter != 0);
        case 'i':
          _setStyle(current, InlineTextStyle.italic, parameter != 0);
        case 'ul':
          _setStyle(current, InlineTextStyle.underline, parameter != 0);
        case 'ulnone':
          current.remove(InlineTextStyle.underline);
        case 'strike':
          _setStyle(current, InlineTextStyle.strike, parameter != 0);
        case 'par':
        case 'line':
          writeText('\n');
        case 'u':
          if (parameter != null) {
            writeText(
              String.fromCharCode(
                parameter < 0 ? parameter + 65536 : parameter,
              ),
            );
            if (index + 1 < source.length) index++;
          }
      }
    }
    _writeStyleTransition(dia, activeStyles, const <InlineTextStyle>{});
    return InlineTextDocument.decode(dia.toString());
  }
}

void _setStyle(
  Set<InlineTextStyle> styles,
  InlineTextStyle style,
  bool enabled,
) {
  if (enabled) {
    styles.add(style);
  } else {
    styles.remove(style);
  }
}

void _writeRtfStyleTransition(
  StringBuffer result,
  Set<InlineTextStyle> active,
  Set<InlineTextStyle> target,
) {
  for (final InlineTextStyle style in _styleOrder) {
    if (style == InlineTextStyle.underline ||
        style == InlineTextStyle.tieUnderline) {
      continue;
    }
    if (active.contains(style) == target.contains(style)) continue;
    result.write(switch (style) {
      InlineTextStyle.bold => target.contains(style) ? r'\b ' : r'\b0 ',
      InlineTextStyle.italic => target.contains(style) ? r'\i ' : r'\i0 ',
      InlineTextStyle.strike =>
        target.contains(style) ? r'\strike ' : r'\strike0 ',
      InlineTextStyle.underline || InlineTextStyle.tieUnderline =>
        throw StateError('Handled after the loop'),
    });
    _setStyle(active, style, target.contains(style));
  }
  final bool activeUnderline =
      active.contains(InlineTextStyle.underline) ||
      active.contains(InlineTextStyle.tieUnderline);
  final bool targetUnderline =
      target.contains(InlineTextStyle.underline) ||
      target.contains(InlineTextStyle.tieUnderline);
  if (activeUnderline != targetUnderline) {
    result.write(targetUnderline ? r'\ul ' : r'\ulnone ');
  }
  _setStyle(
    active,
    InlineTextStyle.underline,
    target.contains(InlineTextStyle.underline),
  );
  _setStyle(
    active,
    InlineTextStyle.tieUnderline,
    target.contains(InlineTextStyle.tieUnderline),
  );
}

void _writeRtfText(StringBuffer result, String text) {
  for (final int codeUnit in text.codeUnits) {
    final String character = String.fromCharCode(codeUnit);
    if (character == '\\' || character == '{' || character == '}') {
      result.write('\\$character');
    } else if (character == '\u00A0') {
      result.write(r'\~');
    } else if (character == '\u00AD') {
      result.write(r'\-');
    } else if (character == '\u2011') {
      result.write(r'\_');
    } else if (codeUnit <= 127) {
      result.write(character);
    } else {
      result.write('\\u${codeUnit > 32767 ? codeUnit - 65536 : codeUnit}?');
    }
  }
}

String _escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _escapeHtmlAttribute(String text) =>
    _escapeHtml(text).replaceAll("'", '&#39;');

/// A [TextEditingController] whose text and selection use logical DIA text.
///
/// Its [text] never contains DIA markup: source commands are represented by
/// one visible placeholder character, making it impossible for a caret to
/// land inside an encoded command.
class InlineTextEditingController extends TextEditingController {
  factory InlineTextEditingController.fromDia(String diaText) {
    return InlineTextEditingController._(InlineTextDocument.decode(diaText));
  }

  InlineTextEditingController._(this._document)
    : _pendingStyles = _document.stylesForInsertionAt(0),
      super(text: _document.visibleText);

  final InlineTextDocument _document;
  Set<InlineTextStyle> _pendingStyles;
  bool _updatingValue = false;
  bool _isRichClipboardPasteInProgress = false;
  Timer? _richClipboardPasteTimer;

  String get encodedText => _document.encode();

  InlineTextDocument get selectedDocument =>
      _document.copyRange(selection.start, selection.end);

  InlineChordCommand? chordAtOffset(int offset) {
    if (offset < 0 || offset >= _document._elements.length) {
      return null;
    }
    final String? source = _document._elements[offset].chordSource;
    return source == null
        ? null
        : InlineChordCommand(
            offset: offset,
            source: source,
            chord: DiatarChord.tryParse(source),
          );
  }

  InlineChordCommand? get selectedChord {
    final TextSelection current = selection;
    if (!current.isValid || current.isCollapsed) {
      return null;
    }
    final int start = current.start;
    return current.end - start == 1 ? chordAtOffset(start) : null;
  }

  void insertChord(String source) {
    if (DiatarChord.tryParse(source) == null) {
      throw ArgumentError.value(source, 'source', 'Invalid Diatár chord');
    }
    final TextSelection current = selection.isValid
        ? selection
        : TextSelection.collapsed(offset: _document._elements.length);
    final int start = current.start;
    final Set<InlineTextStyle> styles = _document.stylesForInsertionAt(start);
    _document._elements.replaceRange(start, current.end, <_InlineTextElement>[
      _InlineTextElement(
        kind: _InlineTextElementKind.command,
        styles: Set<InlineTextStyle>.unmodifiable(styles),
        visibleCharacter: inlineCommandPlaceholder,
        rawCommand: '\\G$source;',
      ),
    ]);
    _setDocumentValue(TextSelection.collapsed(offset: start + 1));
  }

  void replaceChordAt(int offset, String source) {
    if (DiatarChord.tryParse(source) == null) {
      throw ArgumentError.value(source, 'source', 'Invalid Diatár chord');
    }
    final InlineChordCommand? existing = chordAtOffset(offset);
    if (existing == null) {
      return;
    }
    final _InlineTextElement oldElement = _document._elements[offset];
    _document._elements[offset] = _InlineTextElement(
      kind: _InlineTextElementKind.command,
      styles: oldElement.styles,
      visibleCharacter: inlineCommandPlaceholder,
      rawCommand: '\\G$source;',
    );
    _setDocumentValue(TextSelection.collapsed(offset: offset + 1));
  }

  bool isStyleActiveForSelection(InlineTextStyle style) {
    final TextSelection currentSelection = selection;
    if (!currentSelection.isValid) {
      return false;
    }
    if (currentSelection.isCollapsed) {
      return _pendingStyles.contains(style);
    }
    return _document.isStyleActiveForRange(
      style,
      currentSelection.start,
      currentSelection.end,
    );
  }

  void toggleStyle(InlineTextStyle style) {
    final TextSelection currentSelection = selection;
    if (!currentSelection.isValid) {
      return;
    }

    if (currentSelection.isCollapsed) {
      final Set<InlineTextStyle> updated = Set<InlineTextStyle>.from(
        _pendingStyles,
      );
      if (!updated.add(style)) {
        updated.remove(style);
      }
      _pendingStyles = updated;
    } else {
      _document.setStyle(
        style,
        currentSelection.start,
        currentSelection.end,
        enabled: !_document.isStyleActiveForRange(
          style,
          currentSelection.start,
          currentSelection.end,
        ),
      );
    }
    notifyListeners();
  }

  void insertSpecialCharacter(InlineTextSpecialCharacter character) {
    final TextSelection currentSelection = selection;
    if (!currentSelection.isValid) {
      return;
    }

    final int start = currentSelection.start;
    final int end = currentSelection.end;
    _document.replaceVisibleRangeWithSpecialCharacter(
      start,
      end,
      character,
      styles: _pendingStyles,
    );
    _setDocumentValue(TextSelection.collapsed(offset: start + 1));
  }

  void replaceSelectionWithDocument(InlineTextDocument replacement) {
    final TextSelection currentSelection = selection;
    if (!currentSelection.isValid) {
      return;
    }

    final int start = currentSelection.start;
    _document.replaceRangeWithDocument(
      start,
      currentSelection.end,
      replacement,
    );
    _pendingStyles = replacement.stylesForInsertionAt(
      replacement._elements.length,
    );
    _setDocumentValue(
      TextSelection.collapsed(offset: start + replacement._elements.length),
    );
  }

  void beginRichClipboardPaste() {
    _richClipboardPasteTimer?.cancel();
    _isRichClipboardPasteInProgress = true;
    _richClipboardPasteTimer = Timer(const Duration(seconds: 1), () {
      _isRichClipboardPasteInProgress = false;
    });
  }

  void cancelRichClipboardPaste() {
    _richClipboardPasteTimer?.cancel();
    _richClipboardPasteTimer = null;
    _isRichClipboardPasteInProgress = false;
  }

  void _setDocumentValue(TextSelection newSelection) {
    _updatingValue = true;
    try {
      super.value = TextEditingValue(
        text: _document.visibleText,
        selection: newSelection,
      );
    } finally {
      _updatingValue = false;
    }
  }

  @override
  set value(TextEditingValue newValue) {
    if (_updatingValue) {
      super.value = newValue;
      return;
    }
    if (_isRichClipboardPasteInProgress) {
      return;
    }
    final TextEditingValue oldValue = super.value;
    if (oldValue.text != newValue.text) {
      final _TextChange change = _TextChange.between(
        oldValue.text,
        newValue.text,
      );
      final Set<InlineTextStyle> insertionStyles =
          oldValue.selection.isCollapsed &&
              oldValue.selection.extentOffset == change.start
          ? _pendingStyles
          : _document.stylesForInsertionAt(change.start);
      _document.replaceVisibleRange(
        change.start,
        change.oldEnd,
        newValue.text.substring(change.start, change.newEnd),
        styles: insertionStyles,
      );
      _pendingStyles =
          newValue.text.substring(change.start, change.newEnd).isEmpty
          ? _document.stylesForInsertionAt(newValue.selection.extentOffset)
          : insertionStyles;
    } else if (newValue.selection.isValid &&
        oldValue.selection != newValue.selection) {
      _pendingStyles = _document.stylesForInsertionAt(
        newValue.selection.extentOffset,
      );
    }

    _updatingValue = true;
    try {
      super.value = newValue;
    } finally {
      _updatingValue = false;
    }
  }

  @override
  void dispose() {
    _richClipboardPasteTimer?.cancel();
    super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextStyle baseStyle = style ?? const TextStyle();
    final List<InlineSpan> spans = <InlineSpan>[];
    final StringBuffer textBuffer = StringBuffer();
    Set<InlineTextStyle> runStyles = const <InlineTextStyle>{};
    bool hasRunStyles = false;

    void flushText() {
      if (textBuffer.isEmpty) {
        return;
      }
      spans.add(
        TextSpan(
          text: textBuffer.toString(),
          style: baseStyle.copyWith(
            fontWeight: runStyles.contains(InlineTextStyle.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: runStyles.contains(InlineTextStyle.italic)
                ? FontStyle.italic
                : FontStyle.normal,
            decoration: TextDecoration.combine(<TextDecoration>[
              if (runStyles.contains(InlineTextStyle.underline))
                TextDecoration.underline,
              if (runStyles.contains(InlineTextStyle.strike))
                TextDecoration.lineThrough,
              if (runStyles.contains(InlineTextStyle.tieUnderline))
                TextDecoration.underline,
            ]),
          ),
        ),
      );
      textBuffer.clear();
    }

    for (final _InlineTextElement element in _document._elements) {
      if (hasRunStyles && !_sameStyles(runStyles, element.styles)) {
        flushText();
      }
      runStyles = element.styles;
      hasRunStyles = true;
      final String? chordSource = element.chordSource;
      if (chordSource != null) {
        flushText();
        final bool valid = DiatarChord.tryParse(chordSource) != null;
        final ColorScheme colors = Theme.of(context).colorScheme;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: ChordDisplay(
                source: chordSource,
                style: baseStyle.copyWith(
                  color: valid ? baseStyle.color : colors.error,
                ),
                borderColor: valid ? colors.outline : colors.error,
                backgroundColor: valid
                    ? colors.surfaceContainerLowest
                    : colors.errorContainer,
              ),
            ),
          ),
        );
        continue;
      }
      textBuffer.write(element.editorCharacter);
    }
    flushText();
    return TextSpan(style: baseStyle, children: spans);
  }
}

/// Localized labels used by [InlineTextEditor].
class InlineTextEditorLabels {
  const InlineTextEditorLabels({
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strikethrough,
    required this.insertSpecialCharacter,
    required this.conditionalHyphen,
    required this.nonBreakingSpace,
    required this.nonBreakingHyphen,
    required this.preferredLineBreak,
    required this.insertChord,
    required this.editChord,
  });

  final String bold;
  final String italic;
  final String underline;
  final String strikethrough;
  final String insertSpecialCharacter;
  final String conditionalHyphen;
  final String nonBreakingSpace;
  final String nonBreakingHyphen;
  final String preferredLineBreak;
  final String insertChord;
  final String editChord;

  String specialCharacterLabel(InlineTextSpecialCharacter character) {
    return switch (character) {
      InlineTextSpecialCharacter.conditionalHyphen => conditionalHyphen,
      InlineTextSpecialCharacter.nonBreakingSpace => nonBreakingSpace,
      InlineTextSpecialCharacter.nonBreakingHyphen => nonBreakingHyphen,
      InlineTextSpecialCharacter.preferredLineBreak => preferredLineBreak,
    };
  }
}

/// Reusable rich-text input for DIA inline text.
///
/// The [controller] exposes only visible, logical editor positions. Its
/// [InlineTextEditingController.encodedText] property produces DIA markup.
class InlineTextEditor extends StatefulWidget {
  const InlineTextEditor({
    super.key,
    required this.controller,
    required this.labels,
    required this.decoration,
    required this.chordEditorLabels,
    this.focusNode,
    this.minLines,
    this.maxLines,
  });

  final InlineTextEditingController controller;
  final InlineTextEditorLabels labels;
  final InputDecoration decoration;
  final ChordEditorLabels chordEditorLabels;
  final FocusNode? focusNode;
  final int? minLines;
  final int? maxLines;

  @override
  State<InlineTextEditor> createState() => _InlineTextEditorState();
}

class _InlineTextEditorState extends State<InlineTextEditor> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  final GlobalKey _textFieldKey = GlobalKey();
  DateTime? _lastPointerDownAt;
  Offset? _lastPointerDownPosition;
  bool _editingChord = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode(onKeyEvent: _handleKeyEvent);
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.f2 &&
        widget.controller.selectedChord != null) {
      unawaited(_editChord(widget.controller.selectedChord!));
      return KeyEventResult.handled;
    }
    final bool shortcut =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (!shortcut) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyC) {
      unawaited(_copy());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyX) {
      unawaited(_cut());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyV) {
      unawaited(_paste(suppressPlatformTextChanges: true));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handlePointerDown(PointerDownEvent event) {
    final DateTime now = DateTime.now();
    final bool isDoubleClick =
        _lastPointerDownAt != null &&
        now.difference(_lastPointerDownAt!) <=
            const Duration(milliseconds: 500) &&
        _lastPointerDownPosition != null &&
        (event.position - _lastPointerDownPosition!).distance <= 20;
    _lastPointerDownAt = now;
    _lastPointerDownPosition = event.position;
    if (!isDoubleClick) {
      return;
    }
    _lastPointerDownAt = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_editChordAtPosition(event.position));
      }
    });
  }

  RenderEditable? _findRenderEditable() {
    final RenderObject? root = _textFieldKey.currentContext?.findRenderObject();
    if (root == null) {
      return null;
    }
    RenderEditable? result;
    void visit(RenderObject child) {
      if (result != null) {
        return;
      }
      if (child is RenderEditable) {
        result = child;
        return;
      }
      child.visitChildren(visit);
    }

    if (root is RenderEditable) {
      return root;
    }
    root.visitChildren(visit);
    return result;
  }

  Future<void> _editChordAtPosition(Offset globalPosition) async {
    final RenderEditable? editable = _findRenderEditable();
    if (editable == null) {
      return;
    }
    final int offset = editable.getPositionForPoint(globalPosition).offset;
    final InlineChordCommand? chord =
        widget.controller.chordAtOffset(offset) ??
        widget.controller.chordAtOffset(offset - 1);
    if (chord != null) {
      await _editChord(chord);
    }
  }

  Future<void> _insertChord() async {
    if (_editingChord) {
      return;
    }
    _editingChord = true;
    try {
      final String? source = await showChordEditorDialog(
        context: context,
        labels: widget.chordEditorLabels,
      );
      if (source != null && mounted) {
        widget.controller.insertChord(source);
        _focusNode.requestFocus();
      }
    } finally {
      _editingChord = false;
    }
  }

  Future<void> _editChord(InlineChordCommand chord) async {
    if (_editingChord) {
      return;
    }
    _editingChord = true;
    try {
      final String? source = await showChordEditorDialog(
        context: context,
        labels: widget.chordEditorLabels,
        initialSource: chord.source,
      );
      if (source != null && mounted) {
        widget.controller.replaceChordAt(chord.offset, source);
        _focusNode.requestFocus();
      }
    } finally {
      _editingChord = false;
    }
  }

  Future<void> _copy() async {
    if (widget.controller.selection.isCollapsed) {
      return;
    }
    await InlineTextClipboard.copy(widget.controller.selectedDocument);
  }

  Future<void> _cut() async {
    if (widget.controller.selection.isCollapsed) {
      return;
    }
    await _copy();
    widget.controller.replaceSelectionWithDocument(
      InlineTextDocument.decode(''),
    );
  }

  Future<void> _paste({bool suppressPlatformTextChanges = false}) async {
    if (suppressPlatformTextChanges) {
      widget.controller.beginRichClipboardPaste();
    }
    final InlineTextClipboardContent? content =
        await InlineTextClipboard.read();
    if (content == null) {
      if (suppressPlatformTextChanges) {
        widget.controller.cancelRichClipboardPaste();
      }
      return;
    }
    widget.controller.replaceSelectionWithDocument(content.document);
  }

  List<ContextMenuButtonItem> _contextMenuItems(
    EditableTextState editableTextState,
  ) {
    final InlineChordCommand? selectedChord = widget.controller.selectedChord;
    return <ContextMenuButtonItem>[
      if (selectedChord != null)
        ContextMenuButtonItem(
          label: widget.labels.editChord,
          onPressed: () {
            ContextMenuController.removeAny();
            unawaited(_editChord(selectedChord));
          },
        ),
      ...editableTextState.contextMenuButtonItems.map((
        ContextMenuButtonItem item,
      ) {
        return switch (item.type) {
          ContextMenuButtonType.copy => ContextMenuButtonItem(
            type: item.type,
            onPressed: () {
              unawaited(_copy());
              ContextMenuController.removeAny();
            },
          ),
          ContextMenuButtonType.cut => ContextMenuButtonItem(
            type: item.type,
            onPressed: () {
              unawaited(_cut());
              ContextMenuController.removeAny();
            },
          ),
          ContextMenuButtonType.paste => ContextMenuButtonItem(
            type: item.type,
            onPressed: () {
              unawaited(_paste());
              ContextMenuController.removeAny();
            },
          ),
          _ => item,
        };
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _FormattingButton(
                controller: widget.controller,
                style: InlineTextStyle.bold,
                icon: Icons.format_bold,
                tooltip: widget.labels.bold,
              ),
              _FormattingButton(
                controller: widget.controller,
                style: InlineTextStyle.italic,
                icon: Icons.format_italic,
                tooltip: widget.labels.italic,
              ),
              _FormattingButton(
                controller: widget.controller,
                style: InlineTextStyle.underline,
                icon: Icons.format_underlined,
                tooltip: widget.labels.underline,
              ),
              _FormattingButton(
                controller: widget.controller,
                style: InlineTextStyle.strike,
                icon: Icons.strikethrough_s,
                tooltip: widget.labels.strikethrough,
              ),
              PopupMenuButton<InlineTextSpecialCharacter>(
                tooltip: widget.labels.insertSpecialCharacter,
                icon: const Icon(Icons.more_horiz),
                onSelected: (InlineTextSpecialCharacter character) {
                  widget.controller.insertSpecialCharacter(character);
                  _focusNode.requestFocus();
                },
                itemBuilder: (BuildContext context) {
                  return InlineTextSpecialCharacter.values
                      .map(
                        (InlineTextSpecialCharacter character) =>
                            PopupMenuItem<InlineTextSpecialCharacter>(
                              value: character,
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    character.editorSymbol,
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    widget.labels.specialCharacterLabel(
                                      character,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      )
                      .toList();
                },
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceContainerHighest,
                  foregroundColor: colors.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: widget.labels.insertChord,
                onPressed: () {
                  final InlineChordCommand? chord =
                      widget.controller.selectedChord;
                  unawaited(chord == null ? _insertChord() : _editChord(chord));
                },
                icon: const Icon(Icons.queue_music),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceContainerHighest,
                  foregroundColor: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Listener(
          onPointerDown: _handlePointerDown,
          child: TextField(
            key: _textFieldKey,
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: widget.decoration,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            contextMenuBuilder:
                (BuildContext context, EditableTextState state) {
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: state.contextMenuAnchors,
                    buttonItems: _contextMenuItems(state),
                  );
                },
          ),
        ),
      ],
    );
  }
}

class _FormattingButton extends StatelessWidget {
  const _FormattingButton({
    required this.controller,
    required this.style,
    required this.icon,
    required this.tooltip,
  });

  final InlineTextEditingController controller;
  final InlineTextStyle style;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = controller.isStyleActiveForSelection(style);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      isSelected: isSelected,
      onPressed: () => controller.toggleStyle(style),
      icon: Icon(icon),
      selectedIcon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: isSelected
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        foregroundColor: isSelected
            ? colors.onPrimaryContainer
            : colors.onSurfaceVariant,
      ),
    );
  }
}

bool _sameStyles(Set<InlineTextStyle> first, Set<InlineTextStyle> second) {
  return first.length == second.length && first.containsAll(second);
}

class _TextChange {
  const _TextChange({
    required this.start,
    required this.oldEnd,
    required this.newEnd,
  });

  factory _TextChange.between(String oldText, String newText) {
    int prefixLength = 0;
    while (prefixLength < oldText.length &&
        prefixLength < newText.length &&
        oldText[prefixLength] == newText[prefixLength]) {
      prefixLength++;
    }

    int suffixLength = 0;
    while (suffixLength < oldText.length - prefixLength &&
        suffixLength < newText.length - prefixLength &&
        oldText[oldText.length - suffixLength - 1] ==
            newText[newText.length - suffixLength - 1]) {
      suffixLength++;
    }
    return _TextChange(
      start: prefixLength,
      oldEnd: oldText.length - suffixLength,
      newEnd: newText.length - suffixLength,
    );
  }

  final int start;
  final int oldEnd;
  final int newEnd;
}

/// Canonicalizes inline style markers while preserving every DIA command.
String normalizeInlineTextFormattingMarkers(String text) {
  return InlineTextDocument.decode(text).encode();
}
