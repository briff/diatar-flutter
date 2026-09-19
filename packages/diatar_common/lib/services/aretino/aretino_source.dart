/// Recognising an Aretino chant verse inside a DTX body, and reading its words
/// back out as plain text.
///
/// A verse is an Aretino score when its first body line starts with `\?A`. The
/// rest of that line, and every line after it, is Aretino source verbatim, so
/// `DtxParser` carries it without changes (see
/// `plans/aretino-projection-v1.md`, "The format").
///
/// Lyric extraction is the only Aretino parsing Dart ever does: the score
/// itself is rendered by the upstream library. Diatar needs the words for
/// search, verse lists, slide previews, the `text` record's title fields, and
/// as the placeholder a projector shows while the score is still rendering.
library;

class AretinoSource {
  const AretinoSource._();

  /// Marks the first body line of a verse as Aretino source.
  static const String marker = r'\?A';

  /// Hungarian digraphs that double across a syllable boundary (`osz-szad`),
  /// longest first so `dzs` is tried before `dz`. Mirrors `HU_DIGRAPHS` in the
  /// library's `lyrics.js`, which does the same repair when it collapses a
  /// hyphen.
  static const List<String> _huDigraphs = <String>[
    'dzs',
    'cs',
    'dz',
    'gy',
    'ly',
    'ny',
    'sz',
    'ty',
    'zs',
  ];

  /// Whether these verse body lines are an Aretino score.
  static bool isAretino(List<String> lines) => extract(lines) != null;

  /// The Aretino source carried by these verse body lines, or null when the
  /// verse is ordinary text. The marker is stripped; everything else — the rest
  /// of the first line and every line after it — is passed through untouched.
  static String? extract(List<String> lines) {
    int first = 0;
    while (first < lines.length && lines[first].trim().isEmpty) {
      first++;
    }
    if (first >= lines.length) {
      return null;
    }
    final String head = lines[first].trimLeft();
    if (!head.startsWith(marker)) {
      return null;
    }
    final List<String> out = <String>[head.substring(marker.length).trimLeft()];
    out.addAll(lines.sublist(first + 1));
    while (out.isNotEmpty && out.last.trim().isEmpty) {
      out.removeLast();
    }
    return out.join('\n');
  }

  /// The sung words of an Aretino score, as plain text — one line per lyric
  /// line of the source, syllables joined back into words.
  ///
  /// Reads `w:` (syllable) and `W:` (free verse) lines and drops everything
  /// else: header lines, music lines and blank lines carry no words.
  static List<String> lyricLines(String source) {
    final List<String> out = <String>[];
    for (final String raw in source.split('\n')) {
      final String line = raw.trim();
      if (!line.startsWith('w:') && !line.startsWith('W:')) {
        continue;
      }
      final String text = _plainText(line.substring(2).trim());
      if (text.isNotEmpty) {
        out.add(text);
      }
    }
    return out;
  }

  /// The sung words of an Aretino verse body, as plain text lines. Empty when
  /// the verse is not Aretino or carries no lyrics.
  static List<String> lyricLinesOfVerse(List<String> lines) {
    final String? source = extract(lines);
    return source == null ? const <String>[] : lyricLines(source);
  }

  /// Strips Aretino lyric syntax down to the words a reader would sing:
  /// formatting markup, syllable hyphens, extenders and escapes all go, leaving
  /// text fit for search, a verse list, or a fallback text slide.
  static String _plainText(String input) {
    final StringBuffer out = StringBuffer();
    // The word being assembled, held back until a syllable boundary or a word
    // boundary settles whether its tail needs the digraph repair.
    final StringBuffer word = StringBuffer();
    // True while the previous character was a syllable boundary (`-` or `=`),
    // so the next run of letters joins the word rather than starting one.
    bool joining = false;

    void flushWord() {
      out.write(word.toString());
      word.clear();
      joining = false;
    }

    void addSyllable(String syllable) {
      if (syllable.isEmpty) {
        return;
      }
      if (!joining) {
        flushWord();
        word.write(syllable);
        return;
      }
      // `osz` + `szad` is sung `osszad`, not `oszszad`: the digraph doubles
      // rather than repeating. Same rule the renderer applies when it collapses
      // the hyphen between the two syllables.
      final String left = word.toString();
      for (final String digraph in _huDigraphs) {
        if (left.endsWith(digraph) && syllable.startsWith(digraph)) {
          word.clear();
          word.write(left.substring(0, left.length - digraph.length + 1));
          word.write(syllable);
          joining = false;
          return;
        }
      }
      word.write(syllable);
      joining = false;
    }

    final StringBuffer run = StringBuffer();
    void endRun() {
      final String syllable = run.toString();
      run.clear();
      addSyllable(syllable);
    }

    int i = 0;
    while (i < input.length) {
      final String ch = input[i];
      if (ch == r'\') {
        final String next = i + 1 < input.length ? input[i + 1] : '';
        i += 2;
        switch (next) {
          case '':
            break;
          case 'R':
            run.write('℟'); // ℟
          case 'V':
            run.write('℣'); // ℣
          case 'b':
          case 'n':
          case '#':
          case "'":
            // Inline notation glyphs (flat, natural, sharp, stress). They are
            // marks over the staff, not part of the word.
            break;
          default:
            if (input.startsWith('sc{', i - 1) ||
                input.startsWith('small{', i - 1) ||
                input.startsWith('large{', i - 1) ||
                input.startsWith('red{', i - 1)) {
              i = input.indexOf('{', i - 1) + 1;
            } else if (input.startsWith('color:', i - 1)) {
              final int brace = input.indexOf('{', i - 1);
              i = brace < 0 ? input.length : brace + 1;
            } else {
              // `\X` is a literal X — including `\-`, `\_` and `\(`, which is
              // the whole point of the escape.
              run.write(next);
            }
        }
        continue;
      }
      i++;
      switch (ch) {
        case '-':
        case '=':
          // Syllable boundary inside a word: the syllables butt together.
          endRun();
          joining = true;
        case '+':
          if (i < input.length && input[i] == '+') {
            i++;
            run.write('‡'); // ‡
          } else {
            run.write('†'); // †
          }
        case '~':
          // `~` is a non-breaking space; `~~` splits display text from
          // alignment text, and only the display half is sung.
          if (i < input.length && input[i] == '~') {
            i++;
          } else {
            run.write(' ');
          }
        case '_':
          // Extender line: holds the syllable over more neumes, adds no letter.
          break;
        case '{':
        case '}':
        case '<':
        case '>':
        case '[':
        case ']':
          // Bold / italic / underline delimiters.
          break;
        case '|':
          endRun();
          flushWord();
          out.write(' ');
        case ' ':
        case '\t':
          endRun();
          flushWord();
          out.write(' ');
        default:
          run.write(ch);
      }
    }
    endRun();
    flushWord();

    return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
