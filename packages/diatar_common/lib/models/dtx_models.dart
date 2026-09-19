import '../services/aretino/aretino_source.dart';

class DtxBook {
  const DtxBook({
    required this.fileName,
    required this.title,
    required this.songs,
    this.nick = '',
    this.group = '',
    this.order = 0,
    this.useSound = true,
  });

  final String fileName;
  final String title;
  final String nick;
  final String group;
  final int order;
  final List<DtxSong> songs;
  final bool useSound;

  String get displayName => nick.trim().isNotEmpty ? nick : title;
}

class DtxSong {
  const DtxSong({
    required this.title,
    required this.verses,
    this.separator = false,
    this.useSound = true,
    this.transposition = 0,
  });

  final String title;
  final bool separator;
  final List<DtxVerse> verses;
  final bool useSound;
  final int transposition;
}

class DtxVerse {
  const DtxVerse({
    required this.name,
    required this.lines,
    this.diaId,
    this.soundFilePath,
    this.soundForSong = false,
    this.fotoFilePath,
    this.forwardMS = 0,
  });

  final String name;
  final List<String> lines;
  final String? diaId;
  final String? soundFilePath;
  final bool soundForSong;
  final String? fotoFilePath;
  final int forwardMS;

  /// Whether this verse is a Gregorian chant written in Aretino notation,
  /// rather than ordinary verse text.
  bool get isAretino => AretinoSource.isAretino(lines);

  /// The Aretino source this verse carries, or null when it is ordinary text.
  String? get aretinoSource => AretinoSource.extract(lines);

  /// The verse as human-readable text: for a chant, the words it is sung on;
  /// for anything else, the lines as they stand.
  ///
  /// Everywhere that shows a verse to a person — a verse list, a slide preview,
  /// a search snippet, the title fields of a `text` record — wants this rather
  /// than [lines], or it shows `\?A(g2) g a b a` where the words should be.
  List<String> get textLines {
    final String? source = aretinoSource;
    return source == null ? lines : AretinoSource.lyricLines(source);
  }
}