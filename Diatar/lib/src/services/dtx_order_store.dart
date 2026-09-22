import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StoredCustomOrderEntry {
  const StoredCustomOrderEntry({
    required this.fileName,
    required this.songIndex,
    required this.verseIndex,
    required this.label,
    this.mergeWithNext = false,
    this.skipped = false,
    this.playSound = false,
    this.advanceAfterSound = false,
    this.customTextTitle,
    this.customTextBody,
    this.customImagePath,
    this.customType,
    this.customData = const <String, dynamic>{},
    this.additionalFields = const <String, dynamic>{},
  });

  final String fileName;
  final int songIndex;
  final int verseIndex;
  final String label;
  final bool mergeWithNext;
  final bool skipped;
  final bool playSound;
  final bool advanceAfterSound;
  final String? customTextTitle;
  final String? customTextBody;
  final String? customImagePath;
  final String? customType;
  final Map<String, dynamic> customData;
  final Map<String, dynamic> additionalFields;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> out = <String, dynamic>{
      'fileName': fileName,
      'songIndex': songIndex,
      'verseIndex': verseIndex,
      'label': label,
      'dbldia': mergeWithNext,
      'skipped': skipped,
      'sound': playSound,
      'soundforward': advanceAfterSound,
      'customTextTitle': customTextTitle,
      'customTextBody': customTextBody,
      'customImagePath': customImagePath,
    };
    if (customType != null && customType!.trim().isNotEmpty) {
      out['customType'] = customType;
    }
    if (customData.isNotEmpty) {
      out['customData'] = customData;
    }
    out.addAll(additionalFields);
    return out;
  }

  static StoredCustomOrderEntry? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final Object? f = raw['fileName'];
    final Object? s = raw['songIndex'];
    final Object? v = raw['verseIndex'];
    final Object? l = raw['label'];
    final Object? dbldia = raw['dbldia'] ?? raw['mergeWithNext'];
    final Object? skipped = raw['skipped'];
    final Object? sound = raw['sound'];
    final Object? soundforward = raw['soundforward'];
    final Object? textTitle = raw['customTextTitle'];
    final Object? textBody = raw['customTextBody'];
    final Object? imagePath = raw['customImagePath'];
    final Object? type = raw['customType'];
    final Object? data = raw['customData'];
    if (f is! String || s is! num || l is! String) {
      return null;
    }

    final Map<String, dynamic> additionalFields = <String, dynamic>{};
    for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
      final Object? key = entry.key;
      if (key is! String) {
        continue;
      }
      if (key == 'fileName' ||
          key == 'songIndex' ||
          key == 'verseIndex' ||
          key == 'label' ||
          key == 'dbldia' ||
          key == 'mergeWithNext' ||
          key == 'skipped' ||
          key == 'sound' ||
          key == 'soundforward' ||
          key == 'customTextTitle' ||
          key == 'customTextBody' ||
          key == 'customImagePath' ||
          key == 'customType' ||
          key == 'customData') {
        continue;
      }
      additionalFields[key] = entry.value;
    }

    return StoredCustomOrderEntry(
      fileName: f,
      songIndex: s.toInt(),
      verseIndex: v is num ? v.toInt() : 0,
      label: l,
      mergeWithNext: dbldia is bool ? dbldia : false,
      skipped: skipped is bool ? skipped : false,
      playSound: sound is bool ? sound : false,
      advanceAfterSound: soundforward is bool ? soundforward : false,
      customTextTitle: textTitle is String ? textTitle : null,
      customTextBody: textBody is String ? textBody : null,
      customImagePath: imagePath is String ? imagePath : null,
      customType: type is String && type.trim().isNotEmpty ? type : null,
      customData: data is Map
          ? Map<String, dynamic>.fromEntries(
              data.entries
                  .where(
                    (MapEntry<dynamic, dynamic> entry) => entry.key is String,
                  )
                  .map(
                    (MapEntry<dynamic, dynamic> entry) =>
                        MapEntry<String, dynamic>(
                          entry.key as String,
                          entry.value,
                        ),
                  ),
            )
          : const <String, dynamic>{},
      additionalFields: additionalFields,
    );
  }
}

/// Egy betöltött diasor (saját diasor) perzisztált állapota.
class StoredCustomOrderSet {
  const StoredCustomOrderSet({
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
  final List<StoredCustomOrderEntry> entries;
  final bool enabled;
  final String? baseName;
  final String? sourceType;
  final String? diaFilePath;
  final bool embedImages;
  final bool isModified;
  final int lastUsed;

  /// A diasor utoljára ismert kurzorpozíciója. Visszamenőleges
  /// kompatibilitás: ha a tárolt JSON nem tartalmazza, -1 a default.
  final int cursor;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> out = <String, dynamic>{
      'id': id,
      'name': name,
      'enabled': enabled,
      'entries': entries.map((StoredCustomOrderEntry e) => e.toJson()).toList(),
      'cursor': cursor,
      'isModified': isModified,
      'lastUsed': lastUsed,
    };
    if (baseName != null && baseName!.trim().isNotEmpty) {
      out['baseName'] = baseName!.trim();
    }
    if (sourceType != null && sourceType!.trim().isNotEmpty) {
      out['sourceType'] = sourceType!.trim();
    }
    if (diaFilePath != null && diaFilePath!.trim().isNotEmpty) {
      out['diaFilePath'] = diaFilePath!.trim();
    }
    if (embedImages) {
      out['embedImages'] = true;
    }
    return out;
  }

  static StoredCustomOrderSet? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final Object? id = raw['id'];
    final Object? name = raw['name'];
    if (id is! String || name is! String) {
      return null;
    }
    final List<StoredCustomOrderEntry> entries = <StoredCustomOrderEntry>[];
    final Object? rawEntries = raw['entries'];
    if (rawEntries is List) {
      for (final Object? e in rawEntries) {
        final StoredCustomOrderEntry? parsed = StoredCustomOrderEntry.fromJson(
          e,
        );
        if (parsed != null) {
          entries.add(parsed);
        }
      }
    }
    final Object? enabled = raw['enabled'];
    final Object? baseName = raw['baseName'];
    final Object? sourceType = raw['sourceType'];
    final Object? diaFilePath = raw['diaFilePath'];
    final Object? embedImages = raw['embedImages'];
    final Object? cursor = raw['cursor'];
    final Object? isModified = raw['isModified'];
    final Object? lastUsed = raw['lastUsed'];
    return StoredCustomOrderSet(
      id: id,
      name: name,
      entries: entries,
      enabled: enabled is bool ? enabled : true,
      baseName: baseName is String ? baseName.trim() : null,
      sourceType: sourceType is String ? sourceType.trim() : null,
      diaFilePath: diaFilePath is String ? diaFilePath.trim() : null,
      embedImages: embedImages is bool ? embedImages : false,
      cursor: cursor is num ? cursor.toInt() : -1,
      isModified: isModified is bool ? isModified : false,
      lastUsed: lastUsed is num ? lastUsed.toInt() : 0,
    );
  }
}

class DtxOrderStore {
  static const String _kDisabledSongbooks = 'DisabledSongbooks';
  static const String _kCurrentCustomOrder = 'CurrentCustomOrder';
  static const String _kCurrentCustomOrderActive = 'CurrentCustomOrderActive';
  static const String _kCurrentCustomOrderBaseName =
      'CurrentCustomOrderBaseName';
  static const String _kCurrentCustomOrderSourceType =
      'CurrentCustomOrderSourceType';
  static const String _kCustomOrderPresets = 'CustomOrderPresets';
  static const String _kCustomOrderSets = 'CustomOrderSets';
  static const String _kCustomOrderSetsActive = 'CustomOrderSetsActive';

  Future<Set<String>> loadDisabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kDisabledSongbooks) ?? const <String>[])
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();
  }

  Future<void> saveDisabled(Set<String> disabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> sorted = disabled.toList()..sort();
    await prefs.setStringList(_kDisabledSongbooks, sorted);
  }

  Future<void> saveCurrentCustomOrder(
    List<StoredCustomOrderEntry> entries, {
    required bool active,
    String? baseName,
    String? sourceType,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String json = jsonEncode(
      entries.map((StoredCustomOrderEntry e) => e.toJson()).toList(),
    );
    await prefs.setString(_kCurrentCustomOrder, json);
    await prefs.setBool(_kCurrentCustomOrderActive, active);
    final String normalized = (baseName ?? '').trim();
    await prefs.setString(_kCurrentCustomOrderBaseName, normalized);
    await prefs.setString(
      _kCurrentCustomOrderSourceType,
      (sourceType ?? '').trim(),
    );
  }

  Future<
    ({
      List<StoredCustomOrderEntry> entries,
      bool active,
      String? baseName,
      String? sourceType,
    })
  >
  loadCurrentCustomOrder() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_kCurrentCustomOrder) ?? '[]';
    final bool active = prefs.getBool(_kCurrentCustomOrderActive) ?? false;
    final String baseNameRaw =
        prefs.getString(_kCurrentCustomOrderBaseName) ?? '';
    final String? baseName = baseNameRaw.trim().isEmpty
        ? null
        : baseNameRaw.trim();
    final String sourceTypeRaw =
        prefs.getString(_kCurrentCustomOrderSourceType) ?? '';
    final String? sourceType = sourceTypeRaw.trim().isEmpty
        ? null
        : sourceTypeRaw.trim();

    final List<StoredCustomOrderEntry> entries = <StoredCustomOrderEntry>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final Object? e in decoded) {
          final StoredCustomOrderEntry? parsed =
              StoredCustomOrderEntry.fromJson(e);
          if (parsed != null) {
            entries.add(parsed);
          }
        }
      }
    } catch (_) {}

    return (
      entries: entries,
      active: active,
      baseName: baseName,
      sourceType: sourceType,
    );
  }

  Future<Map<String, List<StoredCustomOrderEntry>>>
  loadCustomOrderPresets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_kCustomOrderPresets) ?? '{}';
    final Map<String, List<StoredCustomOrderEntry>> out =
        <String, List<StoredCustomOrderEntry>>{};

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((Object? key, Object? value) {
          if (key is! String || value is! List) {
            return;
          }
          final List<StoredCustomOrderEntry> entries =
              <StoredCustomOrderEntry>[];
          for (final Object? e in value) {
            final StoredCustomOrderEntry? parsed =
                StoredCustomOrderEntry.fromJson(e);
            if (parsed != null) {
              entries.add(parsed);
            }
          }
          out[key] = entries;
        });
      }
    } catch (_) {}

    return out;
  }

  Future<void> saveCustomOrderPresets(
    Map<String, List<StoredCustomOrderEntry>> presets,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, List<Map<String, dynamic>>> serializable =
        <String, List<Map<String, dynamic>>>{};
    presets.forEach((String name, List<StoredCustomOrderEntry> entries) {
      serializable[name] = entries
          .map((StoredCustomOrderEntry e) => e.toJson())
          .toList();
    });
    await prefs.setString(_kCustomOrderPresets, jsonEncode(serializable));
  }

  Future<void> saveCustomOrderSets(
    List<StoredCustomOrderSet> sets, {
    required int activeIndex,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String json = jsonEncode(
      sets.map((StoredCustomOrderSet s) => s.toJson()).toList(),
    );
    await prefs.setString(_kCustomOrderSets, json);
    await prefs.setInt(_kCustomOrderSetsActive, activeIndex);
  }

  Future<({List<StoredCustomOrderSet> sets, int activeIndex})>
  loadCustomOrderSets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_kCustomOrderSets) ?? '[]';
    final int activeIndex = prefs.getInt(_kCustomOrderSetsActive) ?? -1;

    final List<StoredCustomOrderSet> sets = <StoredCustomOrderSet>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final Object? e in decoded) {
          final StoredCustomOrderSet? parsed = StoredCustomOrderSet.fromJson(e);
          if (parsed != null) {
            sets.add(parsed);
          }
        }
      }
    } catch (_) {}

    int safeActive = activeIndex;
    if (safeActive < 0 || safeActive >= sets.length) {
      safeActive = sets.isEmpty
          ? -1
          : sets.indexWhere((StoredCustomOrderSet s) => s.enabled);
      if (safeActive < 0 && sets.isNotEmpty) {
        safeActive = 0;
      }
    }
    return (sets: sets, activeIndex: safeActive);
  }
}
