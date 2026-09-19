import 'package:diatar_common/services/aretino/aretino_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detection', () {
    test('a verse whose first line carries the marker is Aretino', () {
      expect(
        AretinoSource.isAretino(<String>[
          r'\?A(g2) g a b a ||',
          'w: Al-le-lu-ja.',
        ]),
        isTrue,
      );
    });

    test('an ordinary verse is not', () {
      expect(
        AretinoSource.isAretino(<String>['Uram, irgalmazz', 'Krisztus, kegyelmezz']),
        isFalse,
      );
    });

    test('the marker only counts on the first non-empty line', () {
      expect(
        AretinoSource.isAretino(<String>['Uram, irgalmazz', r'\?A(g2) g a ||']),
        isFalse,
      );
      expect(
        AretinoSource.isAretino(<String>['', r'\?A(g2) g a ||']),
        isTrue,
      );
    });

    test('a kotta verse is not mistaken for one', () {
      expect(
        AretinoSource.isAretino(<String>[r'\Kc4;Uram, irgalmazz']),
        isFalse,
      );
    });
  });

  group('extraction', () {
    test('strips the marker and keeps every following line verbatim', () {
      expect(
        AretinoSource.extract(<String>[
          r'\?A(g2) g a b a ||',
          'w: Al-le-lu-ja.',
        ]),
        '(g2) g a b a ||\nw: Al-le-lu-ja.',
      );
    });

    test('drops trailing blank lines but not interior ones', () {
      expect(
        AretinoSource.extract(<String>[r'\?A(g2) g ||', '', 'w: A.', '', '']),
        '(g2) g ||\n\nw: A.',
      );
    });

    test('returns null for a verse that is not Aretino', () {
      expect(AretinoSource.extract(<String>['Uram']), isNull);
      expect(AretinoSource.extract(<String>[]), isNull);
    });
  });

  group('lyrics', () {
    List<String> lyricsOf(String source) => AretinoSource.lyricLines(source);

    test('joins syllables back into words', () {
      expect(
        lyricsOf('(g2) g a b ||\nw: Al-le-lu-ja, al-le-lu-ja.'),
        <String>['Alleluja, alleluja.'],
      );
    });

    test('ignores music and header lines', () {
      expect(
        lyricsOf('%title: Teszt\n%%\n(g2) g a b ||\nw: Di-cső-ség\n\n(g2) c d ||'),
        <String>['Dicsőség'],
      );
    });

    test('reads free verse lines too', () {
      expect(
        lyricsOf('(g2) g ||\nw: Al-le-lu-ja.\nW: Dicsőség az Atyának.'),
        <String>['Alleluja.', 'Dicsőség az Atyának.'],
      );
    });

    test('repairs a Hungarian doubled digraph at a syllable boundary', () {
      // The renderer does the same when it collapses the hyphen: osz + szad is
      // sung osszad, not oszszad.
      expect(lyricsOf('w: osz-szad'), <String>['osszad']);
      expect(lyricsOf('w: asz-szony'), <String>['asszony']);
      expect(lyricsOf('w: any-nyi'), <String>['annyi']);
      // No boundary digraph: the syllables simply butt together.
      expect(lyricsOf('w: ke-gyes'), <String>['kegyes']);
    });

    test('keeps a mandatory hyphen boundary joined as one word', () {
      expect(lyricsOf('w: ki-rály=nő'), <String>['királynő']);
    });

    test('drops extenders and keeps the syllable', () {
      expect(lyricsOf('w: ro___.'), <String>['ro.']);
      expect(lyricsOf('w: lá_-bát.'), <String>['lábát.']);
    });

    test('unwraps inline formatting', () {
      expect(
        lyricsOf('w: {vas-tag} <dőlt> [alá] \\sc{kis} \\red{pi-ros}'),
        <String>['vastag dőlt alá kis piros'],
      );
    });

    test('renders the responsory and versicle signs and daggers', () {
      expect(lyricsOf(r'w: \R jel \V jel + ++'), <String>['℟ jel ℣ jel † ‡']);
    });

    test('drops inline notation glyphs, which are not sung', () {
      expect(lyricsOf(r"w: si-\b-ma"), <String>['sima']);
    });

    test('honours escapes for the syntax characters', () {
      expect(lyricsOf(r'w: only\-be-got-ten'), <String>['only-begotten']);
      expect(lyricsOf(r'w: a\_b'), <String>['a_b']);
      expect(lyricsOf(r'w: \{es-caped\}'), <String>['{escaped}']);
    });

    test('treats a tilde as a non-breaking space', () {
      expect(lyricsOf('w: egy~szó'), <String>['egy szó']);
    });

    test('keeps the flex asterisk', () {
      expect(lyricsOf('w: al-le-lu-ja, * al-le-lu-ja.'),
          <String>['alleluja, * alleluja.']);
    });

    test('reads a whole verse body', () {
      expect(
        AretinoSource.lyricLinesOfVerse(<String>[
          r'\?A(g2) g a b a , ab a g e_d_ | g ab ag g. ||',
          'w: Al-le-lu-ja, al-le-lu-ja, al-le-lu-ja.',
        ]),
        <String>['Alleluja, alleluja, alleluja.'],
      );
    });

    test('is empty for a verse that is not Aretino', () {
      expect(
        AretinoSource.lyricLinesOfVerse(<String>['Uram, irgalmazz']),
        isEmpty,
      );
    });
  });
}
