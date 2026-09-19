import 'package:flutter/foundation.dart';
import 'package:diatar_common/diatar_common.dart';

import '../utils/escape_sequences.dart';

class SongSearchVerse {
  const SongSearchVerse({
    required this.verseIndex,
    required this.verseName,
    required this.haystack,
    required this.lines,
  });

  final int verseIndex;
  final String verseName;
  final String haystack;
  final List<String> lines;
}

class SongSearchSong {
  const SongSearchSong({
    required this.bookIndex,
    required this.songIndex,
    required this.songNumber,
    required this.bookTitle,
    required this.songTitle,
    required this.metaHaystack,
    required this.verses,
  });

  final int bookIndex;
  final int songIndex;
  final int songNumber;
  final String bookTitle;
  final String songTitle;
  final String metaHaystack;
  final List<SongSearchVerse> verses;
}

class SongSearchResult {
  const SongSearchResult({
    required this.bookIndex,
    required this.songIndex,
    required this.verseIndex,
    required this.bookTitle,
    required this.songTitle,
    required this.verseName,
    required this.snippet,
    required this.isLyricsMatch,
  });

  final int bookIndex;
  final int songIndex;
  final int verseIndex;
  final String bookTitle;
  final String songTitle;
  final String verseName;
  final String snippet;
  final bool isLyricsMatch;
}

/// Top-level function to build the search index in an isolate.
List<SongSearchSong> buildSearchIndex(List<DtxBook> books) {
  final List<SongSearchSong> index = <SongSearchSong>[];

  for (int bIdx = 0; bIdx < books.length; bIdx++) {
    final DtxBook book = books[bIdx];
    final String bookTitleLower = normalizeSearchText(book.displayName);

    for (int sIdx = 0; sIdx < book.songs.length; sIdx++) {
      final DtxSong song = book.songs[sIdx];
      if (song.separator) {
        continue;
      }

      final String songTitleLower = normalizeSearchText(song.title);
      final String metaHaystack = '$bookTitleLower $songTitleLower';

      final List<SongSearchVerse> verses = <SongSearchVerse>[];
      for (int vIdx = 0; vIdx < song.verses.length; vIdx++) {
        final DtxVerse verse = song.verses[vIdx];
        final String verseNameLower = normalizeSearchText(verse.name);
        // A Gregorian chant is indexed and quoted by the words it is sung on,
        // not by its Aretino source: a search for "alleluja" must find the
        // chant, and must not be thrown by the neume letters `g a b a`.
        final List<String> searchableLines = verse.textLines;
        final String linesJoinedLower = normalizeSearchText(
          removeEscapeSequences(searchableLines.join(' ')),
        );
        final String verseHaystack = '$verseNameLower $linesJoinedLower';

        verses.add(SongSearchVerse(
          verseIndex: vIdx,
          verseName: verse.name,
          haystack: verseHaystack,
          lines: searchableLines,
        ));
      }

      index.add(SongSearchSong(
        bookIndex: bIdx,
        songIndex: sIdx,
        songNumber: sIdx + 1,
        bookTitle: book.displayName,
        songTitle: song.title,
        metaHaystack: metaHaystack,
        verses: verses,
      ));
    }
  }
  return index;
}

/// Top-level function to run the search in an isolate.
///
/// [index] is the precomputed list of searchable songs.
/// [query] is the lowercased, trimmed search string.
List<SongSearchResult> _runSongSearch(
  ({List<SongSearchSong> index, String query}) args,
) {
  final List<SongSearchSong> index = args.index;
  final String query = args.query;

  if (query.isEmpty) {
    return const <SongSearchResult>[];
  }

  final List<SongSearchResult> results = <SongSearchResult>[];

  for (final SongSearchSong song in index) {
    bool metaMatch = song.metaHaystack.contains(query);
    bool lyricsMatch = false;

    // If meta doesn't match, check verses for lyrics match
    if (!metaMatch) {
      for (final verse in song.verses) {
        if (verse.haystack.contains(query)) {
          lyricsMatch = true;
          // We found a lyrics match, so we'll add this verse as a result.
          // We'll continue to check other verses of the same song too,
          // but we'll prioritize the first one found for the song-level match if needed.
          // Actually, the requirement is to search everything.
          // If a verse matches, we add it.
        }
      }
    }

    if (metaMatch) {
      // Song-level match (number, title, or book title)
      // We'll use verseIndex 0 as a placeholder for song-level match
      // and show the song title as snippet.
      results.add(SongSearchResult(
        bookIndex: song.bookIndex,
        songIndex: song.songIndex,
        verseIndex: 0,
        bookTitle: song.bookTitle,
        songTitle: song.songTitle,
        verseName: '',
        snippet: song.songTitle,
        isLyricsMatch: false,
      ));
    } else if (lyricsMatch) {
      // Lyrics match - find which verse matched to provide a better result
      for (final verse in song.verses) {
        if (verse.haystack.contains(query)) {
          // Find a snippet: the matching line or the verse name
          String snippet = removeEscapeSequences(verse.lines.join(' '));

          results.add(SongSearchResult(
            bookIndex: song.bookIndex,
            songIndex: song.songIndex,
            verseIndex: verse.verseIndex,
            bookTitle: song.bookTitle,
            songTitle: song.songTitle,
            verseName: verse.verseName,
            snippet: snippet,
            isLyricsMatch: true,
          ));
        }
      }
    }
  }

  // Sort results:
  // 1. Meta matches (isLyricsMatch == false) first
  // 2. Then lyrics matches
  // 3. Within each, by bookIndex, then songIndex, then verseIndex
  results.sort((a, b) {
    if (a.isLyricsMatch != b.isLyricsMatch) {
      return a.isLyricsMatch ? 1 : -1;
    }
    if (a.bookIndex != b.bookIndex) {
      return a.bookIndex.compareTo(b.bookIndex);
    }
    if (a.songIndex != b.songIndex) {
      return a.songIndex.compareTo(b.songIndex);
    }
    return a.verseIndex.compareTo(b.verseIndex);
  });

  // Cap results to 200
  return results.take(200).toList();
}

class SongSearchService {
  /// Runs the search in a separate isolate.
  Future<List<SongSearchResult>> search({
    required List<SongSearchSong> index,
    required String query,
  }) async {
    if (query.trim().isEmpty) {
      return const <SongSearchResult>[];
    }
    return compute(
      _runSongSearch,
      (index: index, query: normalizeSearchText(query)),
    );
  }
}