import 'custom_order_entry.dart';

/// Egy betöltött diasor (saját diasor) állapota.
///
/// Több diasor is tartható meg párhuzamosan: mindegyik saját névvel,
/// bejegyzéslistával és engedélyezési állapottal rendelkezik. A vezérlő
/// egyszerre mindig egyet tart aktívnak (ezt navigálja/vetíti), de a
/// betöltöttek közül bármelyik kiválasztható vagy letiltható.
class CustomOrderSet {
  const CustomOrderSet({
    required this.id,
    required this.name,
    required this.entries,
    this.enabled = true,
    this.baseName,
    this.sourceType,
    this.diaFilePath,
    this.embedImages = false,
    this.cursor = -1,
    this.isModified = false,
    this.lastUsed = 0,
  });

  final String id;
  final String name;
  final List<CustomOrderEntry> entries;
  final bool enabled;
  final String? baseName;
  final String? sourceType;
  final String? diaFilePath;
  final bool embedImages;
  final bool isModified;
  final int lastUsed;

  /// A diasor utoljára ismert kurzorpozíciója (a bejegyzéslistában).
  /// Diasorok közötti váltáskor ezt tároljuk el, hogy visszaváltáskor
  /// ugyanoda kerüljön a kurzor. Érvénytelen (üres lista) esetén -1.
  final int cursor;

  /// A felhasználói felületen megjelenítendő név.
  ///
  /// Előnyben részesíti a fájlnévből származtatott alapnevet, majd magát a
  /// megadott nevet.
  String get displayName {
    final String base = (baseName ?? '').trim();
    if (base.isNotEmpty) {
      return base;
    }
    final String named = name.trim();
    if (named.isNotEmpty) {
      return named;
    }
    return '';
  }

  CustomOrderSet copyWith({
    String? id,
    String? name,
    List<CustomOrderEntry>? entries,
    bool? enabled,
    String? baseName,
    bool clearBaseName = false,
    String? sourceType,
    bool clearSourceType = false,
    String? diaFilePath,
    bool clearDiaFilePath = false,
    bool? embedImages,
    int? cursor,
    bool clearCursor = false,
    bool? isModified,
    int? lastUsed,
  }) {
    return CustomOrderSet(
      id: id ?? this.id,
      name: name ?? this.name,
      entries: entries ?? this.entries,
      enabled: enabled ?? this.enabled,
      baseName: clearBaseName ? null : (baseName ?? this.baseName),
      sourceType: clearSourceType ? null : (sourceType ?? this.sourceType),
      diaFilePath: clearDiaFilePath ? null : (diaFilePath ?? this.diaFilePath),
      embedImages: embedImages ?? this.embedImages,
      cursor: clearCursor ? -1 : (cursor ?? this.cursor),
      isModified: isModified ?? this.isModified,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
