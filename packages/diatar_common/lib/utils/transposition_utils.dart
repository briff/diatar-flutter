import '../ui/chord_renderer.dart';

class TranspositionUtils {
  static const List<String> _chromaticScale = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const List<String> _flatsScale = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  /// Transposes a chord string by the given number of semitones.
  static String transposeChord(String chord, int semitones) {
    if (semitones == 0 || chord.trim().isEmpty) return chord;

    final DiatarChord? diatarChord = DiatarChord.tryParse(chord);
    if (diatarChord != null) {
      return diatarChord.transpose(semitones);
    }

    final rootRegex = RegExp(r'^([A-G][#b]?)(.*)');
    final match = rootRegex.firstMatch(chord);

    if (match == null) return chord;

    final String root = match.group(1)!;
    final String quality = match.group(2) ?? '';

    int currentIdx = _getChromaticIndex(root);
    if (currentIdx == -1) return chord;

    int newIdx = (currentIdx + semitones) % 12;
    if (newIdx < 0) newIdx += 12;

    // Use flats if the original root used a flat, otherwise use sharps.
    final bool useFlats = root.contains('b');
    final String newRoot = useFlats
        ? _flatsScale[newIdx]
        : _chromaticScale[newIdx];

    return '$newRoot$quality';
  }

  static int _getChromaticIndex(String root) {
    int idx = _chromaticScale.indexOf(root);
    if (idx != -1) return idx;
    idx = _flatsScale.indexOf(root);
    if (idx != -1) return idx;
    return -1;
  }

  /// Transposes a kotta string by the given number of semitones, following
  /// proper music-notation rules. The key signature (előjegyzés, encoded as
  /// 'e'/'E' commands) is transposed together with the notes, and individual
  /// accidentals ('m' commands) are adjusted so the resulting pitch matches
  /// the transposed key.
  static String transposeKotta(String kotta, int semitones) {
    if (semitones == 0 || kotta.trim().isEmpty) return kotta;

    final List<String> commands = _parseKottaCommands(kotta);
    final List<String> transposed = [];

    // Diatar note letters mapped to semitone offsets from C (within one octave).
    final Map<String, int> noteToSemi = {
      'g': 0,
      'a': 2,
      'h': 4,
      'c': 5,
      'd': 7,
      'e': 9,
      'f': 10,
    };
    // Semitone offset -> natural Diatar note letter.
    final List<String> semiToNote = [
      'g',
      'g',
      'a',
      'a',
      'h',
      'c',
      'c',
      'd',
      'd',
      'e',
      'f',
      'f',
    ];

    // Track the current key signature (number of sharps/flats) so we can decide
    // whether a transposed note needs an explicit accidental.
    int keyAccidentals = 0; // negative = flats, positive = sharps

    for (final String cmd in commands) {
      final String c1 = cmd[0];
      final String c2 = cmd[1];

      if (c1 == 'e' || c1 == 'E') {
        // Key signature (előjegyzés). Transpose the number of accidentals.
        final int count = int.tryParse(c2) ?? 0;
        final int signed = c1 == 'e' ? -count : count;
        int newSigned = (signed + semitones) % 12;
        if (newSigned < 0) newSigned += 12;
        // Preserve the accidental type of the original key signature.
        final bool useFlats = c1 == 'e';
        keyAccidentals = useFlats ? -newSigned : newSigned;
        final int absNew = newSigned.abs().clamp(0, 7);
        transposed.add('${useFlats ? 'e' : 'E'}$absNew');
        continue;
      }

      if (c1 == 'm') {
        // Individual accidental. It modifies the following note, so we defer it
        // and apply it after transposing the note (handled below).
        transposed.add(cmd);
        continue;
      }

      if ('123'.contains(c1) && noteToSemi.containsKey(c2.toLowerCase())) {
        final String lower = c2.toLowerCase();
        int currentSemi = noteToSemi[lower]!;
        int newSemi = (currentSemi + semitones) % 12;
        if (newSemi < 0) newSemi += 12;

        final String naturalNote = semiToNote[newSemi];
        // Determine if the transposed pitch needs an accidental relative to the
        // (transposed) key signature.
        final int needed = _accidentalForNote(newSemi, keyAccidentals);
        if (needed != 0) {
          final String mod = needed < 0
              ? (needed == -2 ? 'B' : 'b')
              : (needed == 2 ? 'K' : 'k');
          transposed.add('m$mod');
        }
        transposed.add('$c1$naturalNote');
        continue;
      }

      // All other commands (clef, rhythm, rests, meters, bars, slurs, etc.)
      // are passed through unchanged.
      transposed.add(cmd);
    }

    return transposed.join();
  }

  /// Returns the accidental needed for a note at [semi] given the current
  /// key signature [keyAccidentals] (negative = flats, positive = sharps).
  /// 0 = natural, 1 = sharp, -1 = flat, 2 = double sharp, -2 = double flat.
  static int _accidentalForNote(int semi, int keyAccidentals) {
    // Notes that are sharp in a sharp key / flat in a flat key.
    const List<int> sharpNotes = [1, 3, 6, 8, 10]; // C#, D#, F#, G#, A#
    const List<int> flatNotes = [1, 4, 6, 9, 11]; // Db, Eb, Gb, Ab, Bb

    if (keyAccidentals > 0) {
      // Sharp key: notes in the sharp set are natural, others need sharps.
      if (sharpNotes.contains(semi)) return 0;
      // Find nearest representation: a note not in the sharp set is a natural
      // that would be spelled with a sharp in this key.
      return 1;
    } else if (keyAccidentals < 0) {
      // Flat key: notes in the flat set are natural, others need flats.
      if (flatNotes.contains(semi)) return 0;
      return -1;
    }
    // No key signature: prefer sharps for black keys.
    if (semi == 1 || semi == 3 || semi == 6 || semi == 8 || semi == 10) {
      return 1;
    }
    return 0;
  }

  static List<String> _parseKottaCommands(String kotta) {
    final List<String> out = [];
    for (int i = 0; i + 1 < kotta.length; i += 2) {
      out.add(kotta.substring(i, i + 2));
    }
    return out;
  }

  /// Transposes a full line of text, including embedded chords (\G;...) and kotta (\K;...).
  static String transposeLine(String line, int semitones) {
    if (semitones == 0 || line.isEmpty) return line;

    StringBuffer result = StringBuffer();
    int i = 0;
    while (i < line.length) {
      if (i + 1 < line.length && line[i] == '\\' && line[i + 1] == 'G') {
        // Chord: \Gchord;
        int semicolon = line.indexOf(';', i + 2);
        if (semicolon != -1) {
          String chord = line.substring(i + 2, semicolon);
          result.write('\\G');
          result.write(transposeChord(chord, semitones));
          result.write(';');
          i = semicolon + 1;
          continue;
        }
      } else if (i + 1 < line.length && line[i] == '\\' && line[i + 1] == 'K') {
        // Kotta: \Kkotta;
        int semicolon = line.indexOf(';', i + 2);
        if (semicolon != -1) {
          String kotta = line.substring(i + 2, semicolon);
          result.write('\\K');
          result.write(transposeKotta(kotta, semitones));
          result.write(';');
          i = semicolon + 1;
          continue;
        }
      }
      result.write(line[i]);
      i++;
    }
    return result.toString();
  }
}
