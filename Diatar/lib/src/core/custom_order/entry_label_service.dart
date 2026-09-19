import 'package:diatar_common/diatar_common.dart';

import '../../models/custom_order_entry.dart';
import '../../utils/escape_sequences.dart';
import 'entry_resolver.dart';

class EntryLabelService {
  const EntryLabelService({required this.resolver});

  final EntryResolver resolver;

  DtxBook? bookForEntry(List<DtxBook> books, CustomOrderEntry entry) {
    return resolver.bookForEntry(books, entry);
  }

  DtxSong? songForEntry(List<DtxBook> books, CustomOrderEntry entry) {
    return resolver.songForEntry(books, entry);
  }

  List<DtxVerse> versesForEntry(List<DtxBook> books, CustomOrderEntry entry) {
    return resolver.versesForEntry(books, entry);
  }

  String firstTextLineForEntry(List<DtxBook> books, CustomOrderEntry entry) {
    if (entry.isSeparator || entry.isCustomImage) {
      return '';
    }
    if (entry.isCustomText) {
      return firstMeaningfulLineFromText(entry.customTextBody ?? '');
    }
    final List<DtxVerse> verses = versesForEntry(books, entry);
    if (verses.isEmpty) {
      return '';
    }
    return firstMeaningfulLine(
      verses[resolver.safeVerseIndex(entry)].textLines,
    );
  }

  String buildEntryLabel(
    List<DtxBook> books,
    String fileName,
    int songIndex,
    int verseIndex,
  ) {
    final int bookIndex = books.indexWhere((DtxBook b) => b.fileName == fileName);
    if (bookIndex < 0) {
      return fileName;
    }
    final DtxBook book = books[bookIndex];
    if (book.songs.isEmpty) {
      return book.displayName;
    }
    final int safeSong = songIndex.clamp(0, book.songs.length - 1);
    final DtxSong song = book.songs[safeSong];
    if (song.verses.isEmpty) {
      return '${book.displayName}: ${song.title}';
    }
    final String verseName = song
        .verses[verseIndex.clamp(0, song.verses.length - 1)]
        .name
        .trim();
    final bool hideVersePart = verseName.isEmpty;
    return hideVersePart
        ? '${book.displayName}: ${song.title}'
        : '${book.displayName}: ${song.title} / $verseName';
  }
}
