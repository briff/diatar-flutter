import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:diatar_common/diatar_common.dart';
import 'package:diatar_speech/diatar_speech.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../l10n/generated/app_localizations.dart';
import '../controllers/diatar_main_controller.dart';
import '../l10n/l10n.dart';
import '../models/custom_order_set.dart';
import '../services/dtx_download_service.dart';
import '../services/dtz_download_service.dart';
import '../services/dtz_user_import_service.dart';
import '../services/streaming_zip_service.dart';
import '../services/android_zip_import_picker.dart';
import '../services/desktop_projector_bridge.dart';
import '../services/macos_file_panels.dart';
import '../utils/custom_entry_labels.dart';
import '../utils/file_system_provider.dart';
import '../utils/friendly_path.dart';
import 'settings_sheet.dart';
import 'custom_order_editor_sheet.dart';
import 'merge_indicator.dart';
import 'song_search_sheet.dart';

String _customOrderSetDisplayName(CustomOrderSet set, AppLocalizations l10n) {
  final String name = set.displayName;
  return name.isEmpty ? l10n.customOrderUnnamedFileName : name;
}

class _BookDropdownEntry {
  const _BookDropdownEntry.header(this.group) : bookIndex = null, title = null;

  const _BookDropdownEntry.book({required this.bookIndex, required this.title})
    : group = null;

  final String? group;
  final int? bookIndex;
  final String? title;

  bool get isHeader => group != null;
}

class _DownloadDialogResult {
  const _DownloadDialogResult({
    required this.dtxDownloadSelected,
    required this.dtxExcludedSelected,
    required this.dtzDownloadSelected,
    required this.dtzExcludedSelected,
    required this.musicDownloadSelected,
    required this.musicExcludedSelected,
  });

  final Set<String> dtxDownloadSelected;
  final Set<String> dtxExcludedSelected;
  final Set<String> dtzDownloadSelected;
  final Set<String> dtzExcludedSelected;
  final Set<String> musicDownloadSelected;
  final Set<String> musicExcludedSelected;
}

class _MediaTabSelections {
  final Set<String> downloadSelected = <String>{};
  final Set<String> excludedFiles = <String>{};
  List<DtzManageItem> allItems = const <DtzManageItem>[];
  bool initialized = false;
}

class _DtxManagerListEntry {
  const _DtxManagerListEntry.header(this.group) : item = null;

  const _DtxManagerListEntry.item(this.item) : group = null;

  final String? group;
  final DtxManageItem? item;

  bool get isHeader => group != null;
}

class _DiaVerseEntry {
  const _DiaVerseEntry({
    required this.customOrderIndex,
    required this.label,
    required this.skipped,
  });

  final int customOrderIndex;
  final String label;
  final bool skipped;
}

class _DiaSongGroup {
  const _DiaSongGroup({required this.label, required this.verses});

  final String label;
  final List<_DiaVerseEntry> verses;
}

({String prefix, String suffix})? _splitSlashLabel(String label) {
  final int slashIndex = label.indexOf('/');
  if (slashIndex <= 0 || slashIndex >= label.length - 1) {
    return null;
  }
  final String prefix = label.substring(0, slashIndex).trim();
  final String suffix = label.substring(slashIndex + 1).trim();
  if (prefix.isEmpty || suffix.isEmpty) {
    return null;
  }
  return (prefix: prefix, suffix: suffix);
}

const int _diaVirtualBookValue = -1000000;
const int _customOrderSetHeaderValue = -3000000;
const int _customOrderSetValueBase = -2000000;

enum _ProjectionDisplayToggle {
  songOrder,
  musicPlayback,
  advanceAfterMusic,
  kotta,
  chords,
  backgroundImage,
  hideControlWindow,
}

enum _HomeControlMode { books, dialist }

enum _HomeScreenMode { books, dialist, presentation }

String _cleanSeparatorLabel(CustomOrderEntry entry) {
  final String explicit = (entry.customTextTitle ?? '').trim();
  if (explicit.isNotEmpty) {
    return '-- $explicit --';
  }
  final String compact = entry.label
      .trim()
      .replaceAll(RegExp(r'^-+\s*'), '')
      .replaceAll(RegExp(r'\s*-+$'), '')
      .trim();
  return compact.isEmpty ? '--' : '-- $compact --';
}

String _normalizeSlashSpacing(String text) {
  return text.replaceAll(RegExp(r'\s*/\s*'), '/');
}

Widget _buildTitleWithFirstLine({
  required String title,
  required String firstLine,
  required TextStyle? titleStyle,
}) {
  final List<InlineSpan> spans = <InlineSpan>[
    TextSpan(text: title, style: titleStyle),
  ];
  if (firstLine.trim().isNotEmpty) {
    spans.add(
      TextSpan(
        text: ' ($firstLine)',
        style: titleStyle?.copyWith(
          fontSize: ((titleStyle.fontSize ?? 13) * 0.85),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
  return Text.rich(
    TextSpan(children: spans),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );
}

String _songVerseToken(DtxVerse verse) {
  final String raw = verse.name.trim();
  if (raw.isEmpty) {
    return '';
  }
  final RegExpMatch? match = RegExp(r'^(\d+)').firstMatch(raw);
  if (match != null) {
    return match.group(1)!;
  }
  return raw;
}

String _entryShortLabel(
  AppLocalizations l10n,
  DiatarMainController controller,
  CustomOrderEntry entry,
) {
  if (entry.isSeparator) {
    return _cleanSeparatorLabel(entry);
  }
  if (entry.isCustomImage) {
    return localizedCustomEntryLabel(l10n, entry);
  }
  if (entry.isCustomText) {
    return localizedCustomEntryLabel(l10n, entry);
  }
  final DtxSong? song = controller.songForEntry(entry);
  final List<DtxVerse> verses = controller.versesForEntry(entry);
  if (song == null || verses.isEmpty) {
    return entry.label;
  }
  final int safeVerse = entry.verseIndex.clamp(0, verses.length - 1);
  final String token = _songVerseToken(verses[safeVerse]);
  if (token.isNotEmpty) {
    return token;
  }
  final String fallback = verses[safeVerse].name.trim();
  return fallback.isEmpty ? '${safeVerse + 1}' : fallback;
}

List<_DiaSongGroup> _buildDiaSongGroups(
  AppLocalizations l10n,
  DiatarMainController controller,
) {
  final List<CustomOrderEntry> custom = controller.customOrder;
  final List<_DiaSongGroup> groups = <_DiaSongGroup>[];
  int i = 0;

  while (i < custom.length) {
    final CustomOrderEntry first = custom[i];
    if (controller.isCustomOrderEntryMergeLeaderAt(i)) {
      final String mergedLabel = controller.customOrderProjectionTitleAt(i);
      groups.add(
        _DiaSongGroup(
          label: mergedLabel,
          verses: <_DiaVerseEntry>[
            _DiaVerseEntry(
              customOrderIndex: i,
              label: mergedLabel,
              skipped: first.skipped,
            ),
          ],
        ),
      );
      i += 2;
      continue;
    }
    if (controller.isCustomOrderEntryMergeFollowerAt(i)) {
      i++;
      continue;
    }
    if (!first.isSongEntry) {
      final String firstLabel = _entryShortLabel(l10n, controller, first);
      final ({String prefix, String suffix})? firstSplit = _splitSlashLabel(
        firstLabel,
      );
      if (firstSplit == null) {
        groups.add(
          _DiaSongGroup(
            label: firstLabel,
            verses: <_DiaVerseEntry>[
              _DiaVerseEntry(
                customOrderIndex: i,
                label: firstLabel,
                skipped: first.skipped,
              ),
            ],
          ),
        );
        i++;
        continue;
      }

      final List<_DiaVerseEntry> verses = <_DiaVerseEntry>[];
      int j = i;
      while (j < custom.length) {
        final CustomOrderEntry candidate = custom[j];
        if (candidate.isSongEntry) {
          break;
        }
        final String candidateLabel = _entryShortLabel(
          l10n,
          controller,
          candidate,
        );
        final ({String prefix, String suffix})? candidateSplit =
            _splitSlashLabel(candidateLabel);
        if (candidateSplit == null ||
            candidateSplit.prefix != firstSplit.prefix) {
          break;
        }
        verses.add(
          _DiaVerseEntry(
            customOrderIndex: j,
            label: candidateSplit.suffix,
            skipped: candidate.skipped,
          ),
        );
        j++;
      }

      final String compactSuffix = verses
          .map((_DiaVerseEntry verse) => verse.label)
          .where((String label) => label.trim().isNotEmpty)
          .join(', ');
      final String groupLabel = compactSuffix.isEmpty
          ? firstLabel
          : '${firstSplit.prefix}/$compactSuffix';
      groups.add(_DiaSongGroup(label: groupLabel, verses: verses));
      i = j;
      continue;
    }

    final List<_DiaVerseEntry> verses = <_DiaVerseEntry>[];
    final DtxSong? song = controller.songForEntry(first);
    final DtxBook? book = controller.bookForEntry(first);
    int j = i;
    int lastVerse = first.verseIndex;

    while (j < custom.length) {
      final CustomOrderEntry candidate = custom[j];
      if (!candidate.isSongEntry ||
          candidate.fileName != first.fileName ||
          candidate.songIndex != first.songIndex) {
        break;
      }
      if (j != i && candidate.verseIndex != lastVerse + 1) {
        break;
      }
      verses.add(
        _DiaVerseEntry(
          customOrderIndex: j,
          label: _entryShortLabel(l10n, controller, candidate),
          skipped: candidate.skipped,
        ),
      );
      lastVerse = candidate.verseIndex;
      j++;
    }

    final String bookName = book?.displayName ?? first.fileName;
    final String songTitle = song?.title ?? first.label;
    final List<String> tokens = verses
        .map((_DiaVerseEntry v) => v.label.trim())
        .where((String v) => v.isNotEmpty)
        .toList();
    final String suffix = tokens.isEmpty
        ? songTitle
        : '$songTitle/${tokens.join(', ')}';
    groups.add(_DiaSongGroup(label: '$bookName: $suffix', verses: verses));
    i = j;
  }

  return groups;
}

int _selectedDiaSongGroupIndex(
  List<_DiaSongGroup> groups,
  int selectedCustomOrderCursor,
) {
  final int idx = groups.indexWhere(
    (_DiaSongGroup g) => g.verses.any(
      (_DiaVerseEntry v) => v.customOrderIndex == selectedCustomOrderCursor,
    ),
  );
  return idx >= 0 ? idx : 0;
}

enum _TransportIndicatorState { off, connecting, connected, error }

typedef TransportIndicatorState = _TransportIndicatorState;

bool _isTransportErrorStatus(String code) {
  return _isMqttErrorStatus(code) || _isTcpErrorStatus(code);
}

String _statusParam(Map<String, String> params, String key) {
  return params[key] ?? '';
}

String _transportErrorMessage(
  BuildContext context,
  DiatarMainController controller,
) {
  final l10n = context.l10n;
  final String code = controller.statusCode;
  final Map<String, String> params = controller.statusParams;
  switch (code) {
    case 'statusSenderMqttConnectFailed':
      return l10n.statusSenderMqttConnectFailed;
    case 'statusSenderMqttError':
      return l10n.statusSenderMqttError(_statusParam(params, 'error'));
    case 'statusSenderTcpError':
      return l10n.statusSenderTcpError(_statusParam(params, 'error'));
    case 'statusSenderOpenPortFailed':
      return l10n.statusSenderOpenPortFailed(
        int.tryParse(_statusParam(params, 'port')) ?? 0,
        _statusParam(params, 'error'),
      );
    case 'statusSenderError':
      return l10n.statusSenderError(_statusParam(params, 'message'));
    default:
      return l10n.statusSenderError(code);
  }
}

String _transportStateLabel(
  BuildContext context,
  _TransportIndicatorState state,
) {
  final l10n = context.l10n;
  switch (state) {
    case _TransportIndicatorState.off:
      return l10n.internetStatusOff;
    case _TransportIndicatorState.connecting:
      return l10n.internetStatusConnecting;
    case _TransportIndicatorState.connected:
      return l10n.internetStatusOn;
    case _TransportIndicatorState.error:
      return l10n.internetStatusError;
  }
}

String _statusTooltip(
  BuildContext context, {
  required String title,
  required _TransportIndicatorState state,
}) {
  return context.l10n.connectionStatusTooltip(
    title,
    _transportStateLabel(context, state),
  );
}

bool _isMqttErrorStatus(String code) {
  return code == 'statusSenderMqttConnectFailed' ||
      code == 'statusSenderMqttError' ||
      code == 'statusSenderError';
}

bool _isTcpErrorStatus(String code) {
  return code == 'statusSenderTcpError' ||
      code == 'statusSenderOpenPortFailed' ||
      code == 'statusSenderError';
}

TransportIndicatorState resolveMqttIndicatorState({
  required bool mqttActive,
  required bool mqttConnected,
  required bool mqttHasError,
}) {
  if (!mqttActive) {
    return TransportIndicatorState.off;
  }
  if (mqttConnected) {
    return TransportIndicatorState.connected;
  }
  if (mqttHasError) {
    return TransportIndicatorState.error;
  }
  return TransportIndicatorState.connecting;
}

TransportIndicatorState resolveTcpIndicatorState({
  required bool tcpActive,
  required bool tcpConnected,
  required bool tcpHasError,
}) {
  if (!tcpActive) {
    return TransportIndicatorState.off;
  }
  if (tcpConnected) {
    return TransportIndicatorState.connected;
  }
  if (tcpHasError) {
    return TransportIndicatorState.error;
  }
  return TransportIndicatorState.connecting;
}

_TransportIndicatorState _mqttIndicatorState(DiatarMainController controller) {
  return resolveMqttIndicatorState(
    mqttActive: controller.mqttActive,
    mqttConnected: controller.mqttConnected,
    mqttHasError: controller.mqttHasError,
  );
}

_TransportIndicatorState _localNetworkIndicatorState(
  DiatarMainController controller,
) {
  return resolveTcpIndicatorState(
    tcpActive: controller.tcpActive,
    tcpConnected: controller.tcpConnected,
    tcpHasError: controller.tcpHasError,
  );
}

Color _statusColorFor(_TransportIndicatorState state, ThemeData theme) {
  switch (state) {
    case _TransportIndicatorState.off:
      return theme.disabledColor;
    case _TransportIndicatorState.connecting:
      return Colors.amber;
    case _TransportIndicatorState.connected:
      return Colors.green;
    case _TransportIndicatorState.error:
      return Colors.red;
  }
}

Widget _statusIcon({
  required IconData icon,
  required _TransportIndicatorState state,
  required ThemeData theme,
}) {
  final Color color = _statusColorFor(state, theme);
  final BorderSide border = switch (state) {
    _TransportIndicatorState.off => BorderSide.none,
    _TransportIndicatorState.connecting => BorderSide(
      color: Colors.amber.withValues(alpha: 0.85),
      width: 1.0,
    ),
    _TransportIndicatorState.connected => BorderSide(
      color: Colors.green.withValues(alpha: 0.85),
      width: 1.0,
    ),
    _TransportIndicatorState.error => BorderSide(
      color: Colors.red.withValues(alpha: 0.9),
      width: 1.4,
    ),
  };
  return Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.fromBorderSide(border),
    ),
    child: Icon(icon, size: 16, color: color),
  );
}

List<_BookDropdownEntry> _buildBookDropdownEntries(
  List<DtxBook> books,
  String ungroupedLabel,
) {
  final List<_BookDropdownEntry> entries = <_BookDropdownEntry>[];
  String? lastGroup;
  for (int index = 0; index < books.length; index++) {
    final DtxBook book = books[index];
    final String rawGroup = book.group.trim();
    final String displayGroup = rawGroup.isEmpty ? ungroupedLabel : rawGroup;
    if (displayGroup != lastGroup) {
      entries.add(_BookDropdownEntry.header(displayGroup));
      lastGroup = displayGroup;
    }
    entries.add(_BookDropdownEntry.book(bookIndex: index, title: book.title));
  }
  return entries;
}

class DiatarHomePage extends StatefulWidget {
  const DiatarHomePage({super.key, required this.controller});

  final DiatarMainController controller;

  @override
  State<DiatarHomePage> createState() => _DiatarHomePageState();
}

class _DiatarHomePageState extends State<DiatarHomePage> {
  static const double _portraitDialistHeight = 148;
  static const double _landscapeSplitterWidth = 18;

  _HomeControlMode _homeControlMode = _HomeControlMode.books;
  int _homeLayoutMode = 0;
  double? _landscapeControlsRatio;
  bool _isLandscapeSplitterDragging = false;
  double? _landscapeDragControlsWidth;
  bool _presentationControlsVisible = false;
  bool _homeTopBarHidden = false;
  bool _startupDownloadDialogScheduled = false;
  Size? _cameraDragSize;
  Size _cameraDragInitialSize = Size.zero;
  Offset? _cameraDragStartPointer;

  static const double _defaultCameraViewWidth = 200;
  static const double _defaultCameraViewHeight = 120;
  static const double _minCameraViewWidth = 160;
  static const double _minCameraViewHeight = 90;
  static const double _maxCameraViewWidth = 1280;
  static const double _maxCameraViewHeight = 720;

  DiatarMainController get controller => widget.controller;

  int _homeViewModeValue(_HomeControlMode mode) {
    return mode == _HomeControlMode.dialist ? 1 : 0;
  }

  _HomeControlMode _homeControlModeFromValue(int value) {
    return value == 1 ? _HomeControlMode.dialist : _HomeControlMode.books;
  }

  void _syncHomeModeFromSettings() {
    final _HomeControlMode stored = _homeControlModeFromValue(
      controller.settings.homeViewMode,
    );
    final int storedLayout = controller.settings.homeLayoutMode;
    final bool storedTopBarHidden = controller.settings.homeTopBarHidden;
    final double? storedControlsRatio =
        controller.settings.landscapeControlsRatio;
    if (stored == _homeControlMode &&
        storedLayout == _homeLayoutMode &&
        storedTopBarHidden == _homeTopBarHidden &&
        storedControlsRatio == _landscapeControlsRatio) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _homeControlMode = stored;
        _homeLayoutMode = storedLayout;
        _homeTopBarHidden = storedTopBarHidden;
        _landscapeControlsRatio = storedControlsRatio;
        if (storedLayout == 1) {
          _presentationControlsVisible =
              controller.settings.presentationControlsVisible;
        }
      });
      if (stored == _HomeControlMode.dialist) {
        controller.selectDiaVirtualBook();
      }
    });
  }

  _HomeScreenMode get _currentScreenMode {
    if (_homeLayoutMode == 1) {
      return _HomeScreenMode.presentation;
    }
    return _homeControlMode == _HomeControlMode.dialist
        ? _HomeScreenMode.dialist
        : _HomeScreenMode.books;
  }

  void _setHomeScreenMode(_HomeScreenMode mode) {
    switch (mode) {
      case _HomeScreenMode.books:
        _setHomeControlMode(_HomeControlMode.books);
        _setHomeLayoutMode(0);
      case _HomeScreenMode.dialist:
        _setHomeControlMode(_HomeControlMode.dialist);
        _setHomeLayoutMode(0);
      case _HomeScreenMode.presentation:
        _setHomeLayoutMode(1);
    }
  }

  void _setHomeLayoutMode(int mode) {
    if (_homeLayoutMode == mode) {
      return;
    }
    setState(() {
      _homeLayoutMode = mode;
      if (mode == 1) {
        _presentationControlsVisible =
            controller.settings.presentationControlsVisible;
      } else {
        _presentationControlsVisible = false;
      }
    });
    unawaited(controller.setHomeLayoutMode(mode));
  }

  void _togglePresentationControls() {
    if (_homeLayoutMode != 1) {
      return;
    }
    final bool newValue = !_presentationControlsVisible;
    setState(() {
      _presentationControlsVisible = newValue;
    });
    unawaited(controller.setPresentationControlsVisible(newValue));
  }

  void _toggleHomeTopBar() {
    if (_homeLayoutMode == 1) {
      return;
    }
    final bool newValue = !_homeTopBarHidden;
    setState(() {
      _homeTopBarHidden = newValue;
    });
    unawaited(controller.setHomeTopBarHidden(newValue));
  }

  void _handlePresentationPreviewTap() {
    if (_homeLayoutMode == 1 && _presentationControlsVisible) {
      setState(() {
        _presentationControlsVisible = false;
      });
      return;
    }
    controller.toggleShowing();
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    AppLocalizations l10n,
    IconData modeIcon,
  ) {
    return <Widget>[
      PopupMenuButton<_HomeScreenMode>(
        tooltip: l10n.homeControlModeTooltip,
        initialValue: _currentScreenMode,
        onSelected: _setHomeScreenMode,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<_HomeScreenMode>>[
              CheckedPopupMenuItem<_HomeScreenMode>(
                value: _HomeScreenMode.books,
                checked: _currentScreenMode == _HomeScreenMode.books,
                child: Text(l10n.homeControlModeBooks),
              ),
              CheckedPopupMenuItem<_HomeScreenMode>(
                value: _HomeScreenMode.dialist,
                checked: _currentScreenMode == _HomeScreenMode.dialist,
                child: Text(l10n.homeControlModeDialist),
              ),
              CheckedPopupMenuItem<_HomeScreenMode>(
                value: _HomeScreenMode.presentation,
                checked: _currentScreenMode == _HomeScreenMode.presentation,
                child: Text(l10n.homeControlModePresentation),
              ),
            ],
        icon: Icon(modeIcon),
      ),
      IconButton(
        tooltip: l10n.searchLabel,
        onPressed: () => _openSearchSheet(context),
        icon: const Icon(Icons.search),
      ),
      if (!kIsWeb && controller.settings.wolEnabled)
        IconButton(
          tooltip: l10n.wolTooltip,
          onPressed: () => _sendWakeOnLan(context),
          icon: const Icon(Icons.offline_bolt),
        ),
      if (!kIsWeb && controller.settings.speechFeatureVisible)
        IconButton(
          tooltip: controller.liveSubtitlesActive
              ? l10n.liveSubtitlesOff
              : l10n.liveSubtitlesOn,
          onPressed: () => _toggleLiveSubtitles(context),
          icon: Icon(
            controller.liveSubtitlesActive
                ? Icons.closed_caption
                : Icons.closed_caption_disabled,
            color: controller.liveSubtitlesActive
                ? const Color(0xFF388E3C)
                : null,
          ),
        ),
      IconButton(
        tooltip: l10n.settingsTooltip,
        onPressed: () => _openSettings(context),
        icon: const Icon(Icons.settings),
      ),
      IconButton(
        tooltip: l10n.customOrderTooltip,
        onPressed: () => _openCustomOrderEditor(context),
        icon: const Icon(Icons.queue_music),
      ),
    ];
  }

  void _setHomeControlMode(_HomeControlMode mode) {
    if (_homeControlMode == mode) {
      return;
    }
    setState(() {
      _homeControlMode = mode;
    });
    if (mode == _HomeControlMode.dialist) {
      controller.selectDiaVirtualBook();
    } else {
      controller.selectBookControlMode();
    }
    final int modeValue = _homeViewModeValue(mode);
    unawaited(controller.setHomeViewMode(modeValue));
  }

  void _updateLandscapeControlsRatio(
    BoxConstraints constraints,
    double controlsWidth,
  ) {
    final double width = constraints.maxWidth;
    if (width <= 0) {
      return;
    }
    _landscapeControlsRatio = (controlsWidth / width).clamp(0.0, 1.0);
  }

  void _startLandscapeSplitterDrag(double controlsWidth) {
    setState(() {
      _isLandscapeSplitterDragging = true;
      _landscapeDragControlsWidth = controlsWidth;
    });
  }

  void _updateLandscapeSplitterDrag({
    required double fallbackControlsWidth,
    required double minControlsWidth,
    required double maxControlsWidth,
    required double delta,
  }) {
    final double current = _landscapeDragControlsWidth ?? fallbackControlsWidth;
    final double next = (current + delta).clamp(
      minControlsWidth,
      maxControlsWidth,
    );
    if (_landscapeDragControlsWidth == next) {
      return;
    }
    setState(() {
      _landscapeDragControlsWidth = next;
    });
  }

  void _commitLandscapeSplitterDrag(
    BoxConstraints constraints, {
    required double minControlsWidth,
    required double maxControlsWidth,
  }) {
    final double? draggedWidth = _landscapeDragControlsWidth;
    setState(() {
      _isLandscapeSplitterDragging = false;
      _landscapeDragControlsWidth = null;
      if (draggedWidth != null) {
        final double clampedWidth = draggedWidth.clamp(
          minControlsWidth,
          maxControlsWidth,
        );
        _landscapeControlsRatio =
            clampedWidth / math.max(constraints.maxWidth, 1.0);
      }
    });
    if (_landscapeControlsRatio != null) {
      unawaited(controller.setLandscapeControlsRatio(_landscapeControlsRatio));
    }
  }

  void _cancelLandscapeSplitterDrag() {
    setState(() {
      _isLandscapeSplitterDragging = false;
      _landscapeDragControlsWidth = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncHomeModeFromSettings();
    final l10n = context.l10n;
    final IconData modeIcon = _currentScreenMode == _HomeScreenMode.presentation
        ? Icons.fit_screen
        : (_homeControlMode == _HomeControlMode.books
              ? Icons.library_books_outlined
              : Icons.view_list_outlined);
    final bool isPresentationMode = _homeLayoutMode == 1;
    final bool topRowHidden = isPresentationMode || _homeTopBarHidden;
    return Scaffold(
      appBar: topRowHidden
          ? null
          : AppBar(
              title: Text(l10n.appTitle),
              actions: _buildAppBarActions(context, l10n, modeIcon),
            ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          if (controller.shouldAutoOpenDownloadDialog &&
              !_startupDownloadDialogScheduled) {
            _startupDownloadDialogScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startupDownloadDialogScheduled = false;
              if (!context.mounted ||
                  !controller.shouldAutoOpenDownloadDialog) {
                return;
              }
              controller.markStartupDownloadDialogHandled();
              unawaited(_openDownloadDialog(context));
            });
          }

          final MediaQueryData mq = MediaQuery.of(context);
          final int screenW = (mq.size.width * mq.devicePixelRatio).round();
          final int screenH = (mq.size.height * mq.devicePixelRatio).round();
          unawaited(
            controller.updateScreenSize(width: screenW, height: screenH),
          );

          final Widget? cameraOverlay = _buildCameraOverlay(context);
          if (cameraOverlay == null) {
            return _buildSimpleView(context);
          }
          return Stack(
            children: <Widget>[
              Positioned.fill(child: _buildSimpleView(context)),
              Positioned(right: 12, bottom: 12, child: cameraOverlay),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildCameraOverlay(BuildContext context) {
    if (!controller.settings.showCameraView || !controller.cameraAvailable) {
      return null;
    }
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final Widget child;
    if (controller.cameraViewActive) {
      child = RTCVideoView(
        controller.cameraRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    } else {
      child = Padding(
        padding: const EdgeInsets.all(8),
        child: Text(l10n.cameraViewHint, textAlign: TextAlign.center),
      );
    }
    final Size boxSize =
        _cameraDragSize ??
        Size(
          controller.settings.cameraViewWidth,
          controller.settings.cameraViewHeight,
        );
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: 6,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: controller.cameraViewActive
            ? controller.stopCameraView
            : controller.requestCameraView,
        child: SizedBox(
          width: boxSize.width,
          height: boxSize.height,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              child,
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    controller.cameraViewActive
                        ? Icons.videocam_off
                        : Icons.videocam,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: _buildCameraViewResizeGrip(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraViewResizeGrip(ThemeData theme) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (DragStartDetails details) {
        _cameraDragInitialSize = Size(
          controller.settings.cameraViewWidth,
          controller.settings.cameraViewHeight,
        );
        _cameraDragStartPointer = details.globalPosition;
      },
      onPanUpdate: (DragUpdateDetails details) {
        final Offset pointer = details.globalPosition;
        final Offset start = _cameraDragStartPointer ?? pointer;
        final double nextW =
            (_cameraDragInitialSize.width + start.dx - pointer.dx).clamp(
              _minCameraViewWidth,
              _maxCameraViewWidth,
            );
        final double nextH =
            (_cameraDragInitialSize.height + start.dy - pointer.dy).clamp(
              _minCameraViewHeight,
              _maxCameraViewHeight,
            );
        final Size nextSize = Size(nextW, nextH);
        if (_cameraDragSize == nextSize) {
          return;
        }
        setState(() {
          _cameraDragSize = nextSize;
        });
      },
      onPanEnd: (_) {
        final Size? dragged = _cameraDragSize;
        setState(() {
          _cameraDragSize = null;
        });
        if (dragged != null) {
          unawaited(
            controller.setCameraViewSize(dragged.width, dragged.height),
          );
        }
      },
      onPanCancel: () {
        setState(() {
          _cameraDragSize = null;
        });
      },
      onLongPress: () {
        unawaited(
          controller.setCameraViewSize(
            _defaultCameraViewWidth,
            _defaultCameraViewHeight,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.open_in_full,
            size: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarRevealHint(
    BuildContext context, {
    required bool visible,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color revealHintColor = theme.colorScheme.surface.withValues(
      alpha: 0.42,
    );
    return IgnorePointer(
      ignoring: false,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        opacity: visible ? 0.6 : 1.0,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, right: 10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: revealHintColor,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.28,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.tune,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleView(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool isLandscape = mq.orientation == Orientation.landscape;

    if (_homeLayoutMode == 1) {
      final ThemeData theme = Theme.of(context);
      final AppLocalizations l10n = context.l10n;
      final Widget revealControlsHint = _buildTopBarRevealHint(
        context,
        visible: _presentationControlsVisible,
        onTap: _togglePresentationControls,
      );

      return Column(
        children: <Widget>[
          if (_presentationControlsVisible)
            SafeArea(
              bottom: false,
              child: Container(
                color: theme.colorScheme.surface,
                height: kToolbarHeight,
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 16),
                    Text(l10n.appTitle, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    ..._buildAppBarActions(
                      context,
                      l10n,
                      _currentScreenMode == _HomeScreenMode.presentation
                          ? Icons.fit_screen
                          : (_homeControlMode == _HomeControlMode.books
                                ? Icons.library_books_outlined
                                : Icons.view_list_outlined),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: _buildSimplePreviewPane(context)),
                Positioned.fill(child: revealControlsHint),
              ],
            ),
          ),
          if (_presentationControlsVisible) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildActionButtons(context),
            ),
          ],
        ],
      );
    }

    if (isLandscape) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const double minPreviewWidth = 320.0;
          const double minControlsWidth = 300.0;
          const double preferredControlsWidth = 460.0;
          // 10 circle buttons (including display options) + 9 gaps + side paddings.
          const double controlsRowMinWidthForButtons = 596.0;

          final double maxControlsWidth = math.max(
            minControlsWidth,
            constraints.maxWidth - minPreviewWidth - _landscapeSplitterWidth,
          );

          final double defaultRatio =
              preferredControlsWidth / math.max(constraints.maxWidth, 1.0);
          final double effectiveRatio =
              (_landscapeControlsRatio ?? defaultRatio).clamp(0.0, 1.0);

          double controlsWidth = constraints.maxWidth * effectiveRatio;

          if (_landscapeControlsRatio == null &&
              maxControlsWidth >= controlsRowMinWidthForButtons &&
              controlsWidth < controlsRowMinWidthForButtons) {
            controlsWidth = controlsRowMinWidthForButtons;
          }

          controlsWidth = controlsWidth.clamp(
            minControlsWidth,
            maxControlsWidth,
          );

          if (!_isLandscapeSplitterDragging &&
              _landscapeDragControlsWidth == null) {
            _updateLandscapeControlsRatio(constraints, controlsWidth);
          }

          final double visibleControlsWidth =
              (_landscapeDragControlsWidth ?? controlsWidth).clamp(
                minControlsWidth,
                maxControlsWidth,
              );

          return Row(
            children: <Widget>[
              SizedBox(
                width: visibleControlsWidth,
                child: _buildSimpleControls(context, isLandscape: true),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (_) =>
                    _startLandscapeSplitterDrag(controlsWidth),
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  _updateLandscapeSplitterDrag(
                    fallbackControlsWidth: controlsWidth,
                    minControlsWidth: minControlsWidth,
                    maxControlsWidth: maxControlsWidth,
                    delta: details.delta.dx,
                  );
                },
                onHorizontalDragEnd: (_) => _commitLandscapeSplitterDrag(
                  constraints,
                  minControlsWidth: minControlsWidth,
                  maxControlsWidth: maxControlsWidth,
                ),
                onHorizontalDragCancel: _cancelLandscapeSplitterDrag,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: SizedBox(
                    width: _landscapeSplitterWidth,
                    child: Center(
                      child: Container(
                        width: 2,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: _isLandscapeSplitterDragging
                          ? _buildPreviewResizePlaceholder(context)
                          : _buildSimplePreviewPane(context),
                    ),
                    Positioned.fill(
                      child: _buildTopBarRevealHint(
                        context,
                        visible: !_homeTopBarHidden,
                        onTap: _toggleHomeTopBar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return Column(
      children: <Widget>[
        _buildSimpleControls(context, isLandscape: false),
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: _buildSimplePreviewPane(context)),
              Positioned.fill(
                child: _buildTopBarRevealHint(
                  context,
                  visible: !_homeTopBarHidden,
                  onTap: _toggleHomeTopBar,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleControls(
    BuildContext context, {
    required bool isLandscape,
  }) {
    if (isLandscape) {
      return Column(
        children: <Widget>[
          if (controller.loading || controller.fileTransferInProgress)
            LinearProgressIndicator(
              value: controller.fileTransferInProgress
                  ? controller.fileTransferProgress
                  : null,
              minHeight: 2,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  _TransportErrorSnackListener(controller: controller),
                  if (_homeControlMode == _HomeControlMode.dialist) ...<Widget>[
                    const SizedBox(height: 4),
                    Expanded(
                      child: _DialistPanel(
                        controller: controller,
                        onInternetSettingsTap: () => _openSettings(
                          context,
                          initialSection: DiatarSettingsInitialSection.internet,
                          sectionOnly: true,
                        ),
                        onLocalNetworkSettingsTap: () => _openSettings(
                          context,
                          initialSection:
                              DiatarSettingsInitialSection.localNetwork,
                          sectionOnly: true,
                        ),
                        projectionDisplayButton: _buildProjectionDisplayButton(
                          context,
                        ),
                      ),
                    ),
                  ] else ...<Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildKotetekSelectors(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        if (controller.loading || controller.fileTransferInProgress)
          LinearProgressIndicator(
            value: controller.fileTransferInProgress
                ? controller.fileTransferProgress
                : null,
            minHeight: 2,
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              _TransportErrorSnackListener(controller: controller),
              if (_homeControlMode == _HomeControlMode.dialist) ...<Widget>[
                const SizedBox(height: 4),
                SizedBox(
                  height: _portraitDialistHeight,
                  child: _DialistPanel(
                    controller: controller,
                    onInternetSettingsTap: () => _openSettings(
                      context,
                      initialSection: DiatarSettingsInitialSection.internet,
                      sectionOnly: true,
                    ),
                    onLocalNetworkSettingsTap: () => _openSettings(
                      context,
                      initialSection: DiatarSettingsInitialSection.localNetwork,
                      sectionOnly: true,
                    ),
                    projectionDisplayButton: _buildProjectionDisplayButton(
                      context,
                    ),
                  ),
                ),
              ] else ...<Widget>[_buildKotetekSelectors(context)],
              const SizedBox(height: 10),
              _buildActionButtons(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKotetekSelectors(BuildContext context) {
    return Column(
      children: <Widget>[
        _BookDropdown(
          controller: controller,
          onInternetSettingsTap: () => _openSettings(
            context,
            initialSection: DiatarSettingsInitialSection.internet,
            sectionOnly: true,
          ),
        ),
        const SizedBox(height: 4),
        _SongDropdown(
          controller: controller,
          onLocalNetworkSettingsTap: () => _openSettings(
            context,
            initialSection: DiatarSettingsInitialSection.localNetwork,
            sectionOnly: true,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(child: _VerseDropdown(controller: controller)),
            const SizedBox(width: 8),
            _buildProjectionDisplayButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectionDisplayButton(BuildContext context) {
    return Builder(
      builder: (BuildContext menuContext) {
        final bool nothingShown =
            !controller.settings.projUseKotta &&
            !controller.settings.projUseAkkord;
        final ThemeData theme = Theme.of(menuContext);
        final Color displayButtonColor = nothingShown
            ? const Color(0xFFF9A825)
            : theme.colorScheme.onSurfaceVariant;
        return Tooltip(
          message:
              '${menuContext.l10n.useSound} / ${menuContext.l10n.advanceAfterMusic} / ${menuContext.l10n.showKotta} / ${menuContext.l10n.showChords} / ${menuContext.l10n.showBackgroundImage}',
          child: InkResponse(
            radius: 20,
            onTap: () => unawaited(_showProjectionDisplayMenu(menuContext)),
            child: SizedBox(
              width: 22,
              height: 22,
              child: Center(
                child: Text(
                  '\u266B',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: displayButtonColor,
                    decoration: nothingShown
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationThickness: 2.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _actionIconButton(
                context,
                icon: Icons.keyboard_double_arrow_left,
                tooltip: l10n.songPrev,
                onPressed: controller.prevSong,
              ),
              const SizedBox(width: 8),
              _actionIconButton(
                context,
                icon: Icons.chevron_left,
                tooltip: l10n.previous,
                onPressed: controller.prevVerse,
              ),
              const SizedBox(width: 8),
              _actionIconButton(
                context,
                icon: controller.showing ? Icons.cast_connected : Icons.cast,
                tooltip: controller.showing
                    ? l10n.projectionOff
                    : l10n.projectionOn,
                onPressed: controller.toggleShowing,
                backgroundColor: controller.showing
                    ? const Color(0xFFD32F2F).withValues(alpha: 0.15)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
                foregroundColor: controller.showing
                    ? const Color(0xFFD32F2F)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              if (controller.hasAnyLoadedVersePhoto) ...<Widget>[
                const SizedBox(width: 8),
                _actionIconButton(
                  context,
                  icon: controller.showPhotoInControl
                      ? Icons.photo
                      : Icons.slideshow,
                  tooltip: l10n.controlPhotoView,
                  onPressed: () => controller.toggleControlPhotoView(),
                  backgroundColor: controller.showPhotoInControl
                      ? const Color(0xFF1976D2).withValues(alpha: 0.15)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
                  foregroundColor: controller.showPhotoInControl
                      ? const Color(0xFF1976D2)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
              const SizedBox(width: 8),
              _actionIconButton(
                context,
                icon: controller.settings.projectionLocked
                    ? Icons.lock
                    : Icons.lock_open,
                tooltip: controller.settings.projectionLocked
                    ? l10n.projectionUnlock
                    : l10n.projectionLock,
                onPressed: () => unawaited(controller.toggleProjectionLock()),
                backgroundColor: controller.settings.projectionLocked
                    ? const Color(0xFFF9A825).withValues(alpha: 0.15)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
                foregroundColor: controller.settings.projectionLocked
                    ? const Color(0xFFF9A825)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              _actionIconButton(
                context,
                icon: Icons.chevron_right,
                tooltip: l10n.next,
                onPressed: controller.nextVerse,
              ),
              const SizedBox(width: 8),
              _actionIconButton(
                context,
                icon: Icons.keyboard_double_arrow_right,
                tooltip: l10n.songNext,
                onPressed: controller.nextSong,
              ),
              if (controller.settings.homeShowHighlightControls) ...<Widget>[
                const SizedBox(width: 8),
                _actionIconButton(
                  context,
                  child: const Text(
                    '\u2796',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  tooltip: l10n.highlightPrev,
                  onPressed: controller.highlightPrev,
                ),
                const SizedBox(width: 8),
                _actionIconButton(
                  context,
                  child: const Text(
                    '\u2795',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  tooltip: l10n.highlightNext,
                  onPressed: controller.highlightNext,
                ),
              ],
            ],
          ),
        ),
        if (controller.downloadInProgress) ...<Widget>[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: controller.downloadCurrentFraction),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.downloadProgress(
                controller.downloadCurrentFile,
                controller.downloadTotalFiles,
                controller.downloadCurrentName,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showProjectionDisplayMenu(BuildContext buttonContext) async {
    final String songOrderTitle = buttonContext.l10n.songOrder;
    final RenderObject? buttonObject = buttonContext.findRenderObject();
    if (buttonObject is! RenderBox) {
      return;
    }
    final OverlayState overlay = Overlay.of(buttonContext);
    final RenderObject? overlayObject = overlay.context.findRenderObject();
    if (overlayObject is! RenderBox) {
      return;
    }

    final Offset topLeft = buttonObject.localToGlobal(
      Offset.zero,
      ancestor: overlayObject,
    );
    final Offset bottomRight = buttonObject.localToGlobal(
      buttonObject.size.bottomRight(Offset.zero),
      ancestor: overlayObject,
    );

    final _ProjectionDisplayToggle? selected =
        await showMenu<_ProjectionDisplayToggle>(
          context: buttonContext,
          position: RelativeRect.fromRect(
            Rect.fromPoints(topLeft, bottomRight),
            Offset.zero & overlayObject.size,
          ),
          items: <PopupMenuEntry<_ProjectionDisplayToggle>>[
            PopupMenuItem<_ProjectionDisplayToggle>(
              value: _ProjectionDisplayToggle.songOrder,
              enabled: controller.customOrder.isNotEmpty,
              child: Text(buttonContext.l10n.songOrderSlide),
            ),
            const PopupMenuDivider(),
            CheckedPopupMenuItem<_ProjectionDisplayToggle>(
              value: _ProjectionDisplayToggle.musicPlayback,
              checked: controller.settings.useSound,
              child: Text(buttonContext.l10n.useSound),
            ),
            CheckedPopupMenuItem<_ProjectionDisplayToggle>(
              value: _ProjectionDisplayToggle.advanceAfterMusic,
              checked: controller.settings.advanceAfterMusic,
              enabled: controller.settings.useSound,
              child: Text(buttonContext.l10n.advanceAfterMusic),
            ),
            const PopupMenuDivider(),
            CheckedPopupMenuItem<_ProjectionDisplayToggle>(
              value: _ProjectionDisplayToggle.kotta,
              checked: controller.settings.projUseKotta,
              child: Text(buttonContext.l10n.showKotta),
            ),
            CheckedPopupMenuItem<_ProjectionDisplayToggle>(
              value: _ProjectionDisplayToggle.chords,
              checked: controller.settings.projUseAkkord,
              child: Text(buttonContext.l10n.showChords),
            ),
            CheckedPopupMenuItem<_ProjectionDisplayToggle>(
              value: _ProjectionDisplayToggle.backgroundImage,
              checked: controller.settings.projShowBackgroundImage,
              child: Text(buttonContext.l10n.showBackgroundImage),
            ),
            if (controller.desktopProjectorEnabled) ...<
              PopupMenuEntry<_ProjectionDisplayToggle>
            >[
              const PopupMenuDivider(),
              PopupMenuItem<_ProjectionDisplayToggle>(
                value: _ProjectionDisplayToggle.hideControlWindow,
                child: Text(buttonContext.l10n.hideControlWindow),
              ),
            ],
          ],
        );

    if (selected == null) {
      return;
    }

    switch (selected) {
      case _ProjectionDisplayToggle.songOrder:
        await controller.showSongOrder(songOrderTitle);
      case _ProjectionDisplayToggle.musicPlayback:
        await controller.toggleMusicPlayback();
      case _ProjectionDisplayToggle.advanceAfterMusic:
        await controller.toggleAdvanceAfterMusic();
      case _ProjectionDisplayToggle.kotta:
        await controller.applySettings(
          controller.settings.copyWith(
            projUseKotta: !controller.settings.projUseKotta,
          ),
        );
      case _ProjectionDisplayToggle.chords:
        await controller.applySettings(
          controller.settings.copyWith(
            projUseAkkord: !controller.settings.projUseAkkord,
          ),
        );
      case _ProjectionDisplayToggle.backgroundImage:
        await controller.toggleBackgroundImageVisible();
      case _ProjectionDisplayToggle.hideControlWindow:
        await controller.hideControlWindow();
    }
  }

  Widget _buildSimplePreviewPane(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final Color previewBorderColor = controller.globals.projecting
        ? Colors.red.shade700
        : theme.dividerColor.withValues(alpha: 0.65);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: controller.globals.bkColor,
        border: Border.all(color: previewBorderColor, width: 3.0),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget preview = _buildActivePreview(
            context,
            panelTitle: l10n.previewTitle,
            onPreviewTap: _homeLayoutMode == 1
                ? _handlePresentationPreviewTap
                : controller.toggleShowing,
            onPreviewLongPress: _homeLayoutMode == 1
                ? _togglePresentationControls
                : null,
          );
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: preview,
          );
        },
      ),
    );
  }

  Widget _buildPreviewResizePlaceholder(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color previewBorderColor = controller.globals.projecting
        ? Colors.red.shade700
        : theme.dividerColor.withValues(alpha: 0.65);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: controller.globals.bkColor,
        border: Border.all(color: previewBorderColor, width: 3.0),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Opacity(
          opacity: 0.82,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.open_with,
                size: 42,
                color: controller.globals.txtColor,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.previewResizeInProgress,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: controller.globals.txtColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePreview(
    BuildContext context, {
    required String panelTitle,
    required VoidCallback onPreviewTap,
    VoidCallback? onPreviewLongPress,
  }) {
    final AppLocalizations l10n = context.l10n;

    if (controller.showPhotoInControl) {
      final CustomOrderEntry? projectedCustom =
          controller.projectedCustomOrderEntry;
      final bool isCustomEntry =
          projectedCustom != null &&
          (projectedCustom.isCustomText || projectedCustom.isCustomImage);
      if (!isCustomEntry) {
        final String? photoPath = controller.currentPhotoPath;
        if (photoPath != null && photoPath.isNotEmpty) {
          return _PhotoPreviewWithFallback(
            photoPath: photoPath,
            notFoundLabel: photoPath,
            fallback: _buildNormalPreviewWithGestures(
              context,
              onPreviewTap: onPreviewTap,
              onPreviewLongPress: onPreviewLongPress,
            ),
            controller: controller,
            l10n: l10n,
            onPreviewTap: onPreviewTap,
            onPreviewLongPress: onPreviewLongPress,
          );
        }
      }
    }

    return _buildNormalPreviewWithGestures(
      context,
      onPreviewTap: onPreviewTap,
      onPreviewLongPress: onPreviewLongPress,
    );
  }

  Widget _buildNormalPreviewWithGestures(
    BuildContext context, {
    required VoidCallback onPreviewTap,
    VoidCallback? onPreviewLongPress,
  }) {
    final AppLocalizations l10n = context.l10n;
    if (controller.songOrderVisible && !controller.liveSubtitlesActive) {
      return _CustomTextPreview(
        controller: controller,
        title: controller.songOrderTitle ?? l10n.songOrder,
        lines: controller.songOrderLines,
        onPreviewTap: onPreviewTap,
        onPreviewLongPress: onPreviewLongPress,
      );
    }
    final CustomOrderEntry? projectedCustom =
        controller.projectedCustomOrderEntry;

    if (projectedCustom != null &&
        projectedCustom.isCustomText &&
        !controller.liveSubtitlesActive) {
      final int cursor = controller.selectedCustomOrderCursor;
      final bool isMergeLeader = controller.isCustomOrderEntryMergeLeaderAt(
        cursor,
      );
      final String title = isMergeLeader
          ? controller.customOrderProjectionTitleAt(cursor)
          : controller.currentCustomOrderProjectionTitle ??
                localizedCustomEntryLabel(l10n, projectedCustom);
      final List<String> lines = controller.customOrderProjectionLinesAt(
        cursor,
      );
      return _CustomTextPreview(
        controller: controller,
        title: title,
        lines: lines,
        onPreviewTap: onPreviewTap,
        onPreviewLongPress: onPreviewLongPress,
      );
    }
    if (projectedCustom != null &&
        projectedCustom.isCustomImage &&
        !controller.liveSubtitlesActive) {
      return _CustomImagePreview(
        controller: controller,
        title: localizedCustomEntryLabel(l10n, projectedCustom),
        imagePath: projectedCustom.customImagePath ?? '',
        onPreviewTap: onPreviewTap,
        onPreviewLongPress: onPreviewLongPress,
      );
    }

    final DtxSong? song = controller.currentSong;
    final DtxVerse? verse = controller.currentVerse;
    if (song == null || verse == null) {
      if (controller.liveSubtitlesActive) {
        return _VersePreview(
          controller: controller,
          title: null,
          panelTitle: context.l10n.previewTitle,
          onPreviewTap: onPreviewTap,
          onPreviewLongPress: onPreviewLongPress,
        );
      }
      return Text(
        l10n.noLoadedSlide,
        style: TextStyle(color: controller.globals.txtColor),
      );
    }
    return _VersePreview(
      controller: controller,
      title: controller.currentCustomOrderProjectionTitle,
      panelTitle: context.l10n.previewTitle,
      onPreviewTap: onPreviewTap,
      onPreviewLongPress: onPreviewLongPress,
    );
  }

  Future<void> _openSettings(
    BuildContext context, {
    DiatarSettingsInitialSection? initialSection,
    bool sectionOnly = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DiatarSettingsSheet(
          initialSettings: controller.settings,
          initialPicPlcConfiguration: controller.picPlcConfiguration,
          initialSection: initialSection,
          closeAfterInitialSectionClose: sectionOnly && initialSection != null,
          availableSongsLoader: () {
            final List<SongHotkeyOption> songOptions = <SongHotkeyOption>[];
            for (final DtxBook book in controller.books) {
              for (int songIdx = 0; songIdx < book.songs.length; songIdx++) {
                final DtxSong song = book.songs[songIdx];
                if (song.separator) {
                  continue;
                }
                songOptions.add(
                  SongHotkeyOption(
                    id: '${book.fileName}::$songIdx',
                    label: '${book.displayName} / ${song.title}',
                  ),
                );
              }
            }
            return songOptions;
          },
          availableOrderSetsLoader: () {
            return controller.customOrderSets.map((CustomOrderSet set) {
              return CustomOrderSetOption(id: set.id, name: set.name);
            }).toList();
          },
          onApply: controller.applySettings,
          onApplyPicPlc: controller.configurePicPlc,
          onExitRequested: controller.requestExit,
          onReloadBooksRequested: () => unawaited(controller.reloadBooks()),
          onRemoteStopRequested: () => unawaited(controller.sendStop()),
          onRemoteShutdownRequested: () =>
              unawaited(controller.sendStop(wantShutdown: true)),
          onDownloadBooksRequested: () => _openDownloadDialog(context),
          onFileTransferProgress: controller.setFileTransferProgress,
        );
      },
    );
  }

  Future<void> _openCustomOrderEditor(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return CustomOrderEditorSheet(controller: controller);
      },
    ).whenComplete(controller.syncProjectionToCurrentDia);
  }

  Future<void> _openDownloadDialog(BuildContext context) async {
    final _DownloadDialogResult? selected =
        await showDialog<_DownloadDialogResult>(
          context: context,
          builder: (BuildContext context) =>
              _DownloadSongbooksDialog(controller: controller),
        );
    if (selected == null) {
      return;
    }
    await controller.applyDtxManagerSelection(
      downloadSelected: selected.dtxDownloadSelected,
      excludedSelected: selected.dtxExcludedSelected,
    );
    await controller.applyDtzManagerSelection(
      downloadSelected: selected.dtzDownloadSelected,
      excludedSelected: selected.dtzExcludedSelected,
    );
    await controller.applyMusicManagerSelection(
      downloadSelected: selected.musicDownloadSelected,
      excludedSelected: selected.musicExcludedSelected,
    );
  }

  void _openSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => SongSearchSheet(
        controller: controller,
        onSelected: (result) {
          _setHomeControlMode(_HomeControlMode.books);
          controller.goToSong(
            result.bookIndex,
            result.songIndex,
            result.verseIndex,
          );
        },
      ),
    );
  }

  Future<void> _sendWakeOnLan(BuildContext context) async {
    final (int sent, String? error) = await controller.sendWakeOnLan();
    if (!context.mounted) {
      return;
    }
    final l10n = context.l10n;
    final String message = error == null
        ? l10n.wolMessageSent(sent)
        : l10n.wolMessageError(error);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleLiveSubtitles(BuildContext context) async {
    if (controller.liveSubtitlesActive) {
      await controller.toggleLiveSubtitles();
      return;
    }
    final ModelManager modelManager = ModelManager();
    final SpeechModelType modelType = SpeechModelType.values.firstWhere(
      (e) => e.name == controller.settings.liveSubtitleModel,
      orElse: () => SpeechModelType.nemotron35_560ms,
    );
    final SpeechModelInfo modelInfo = getSpeechModel(modelType);
    final bool modelReady = await modelManager.isModelReady(modelType);
    if (!modelReady && context.mounted) {
      final l10n = context.l10n;
      final String sizeStr = await _fetchModelSize(modelInfo);
      if (!context.mounted) return;
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l10n.liveSubtitlesDownloadTitle),
          content: Text(
            '${l10n.liveSubtitlesDownloadMessage}\n\n${modelInfo.displayName}${sizeStr.isNotEmpty ? ' ($sizeStr)' : ''}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Mégse'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Letöltés'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      if (!context.mounted) return;
      await _downloadModelWithProgress(context, modelManager, modelType);
    }
    if (!modelInfo.isStreaming &&
        modelReady &&
        !await modelManager.isVadModelReady() &&
        context.mounted) {
      final l10n = context.l10n;
      final bool? vadConfirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l10n.vadDownloadTitle),
          content: Text(l10n.vadDownloadMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Mégse'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Letöltés'),
            ),
          ],
        ),
      );
      if (vadConfirmed != true || !context.mounted) return;
      if (!context.mounted) return;
      await _downloadVadModelWithProgress(context, modelManager);
    }
    await controller.toggleLiveSubtitles();
    if (!context.mounted) return;
    final String? error = controller.liveSubtitleError;
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.liveSubtitlesError}: $error'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<String> _fetchModelSize(SpeechModelInfo modelInfo) async {
    try {
      final String fileName = modelInfo.downloadUrl.split('/').last;
      final int bytes = await GitHubReleaseSizeCache.getFileSize(fileName);
      return GitHubReleaseSizeCache.formatSize(bytes);
    } catch (e) {
      return '';
    }
  }

  Future<void> _downloadModelWithProgress(
    BuildContext context,
    ModelManager modelManager,
    SpeechModelType modelType,
  ) async {
    final l10n = context.l10n;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => _ModelDownloadDialog(
        modelManager: modelManager,
        modelType: modelType,
        l10n: l10n,
      ),
    );
  }

  Future<void> _downloadVadModelWithProgress(
    BuildContext context,
    ModelManager modelManager,
  ) async {
    final l10n = context.l10n;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) =>
          _VadDownloadDialog(modelManager: modelManager, l10n: l10n),
    );
  }
}

class _TransportErrorSnackListener extends StatefulWidget {
  const _TransportErrorSnackListener({required this.controller});

  final DiatarMainController controller;

  @override
  State<_TransportErrorSnackListener> createState() =>
      _TransportErrorSnackListenerState();
}

class _TransportErrorSnackListenerState
    extends State<_TransportErrorSnackListener> {
  String _lastErrorSignature = '';

  @override
  Widget build(BuildContext context) {
    final DiatarMainController controller = widget.controller;
    final String code = controller.statusCode;
    final bool isError = _isTransportErrorStatus(code);
    final String signature =
        '$code|${controller.statusParams.entries.map((MapEntry<String, String> e) => '${e.key}=${e.value}').join(';')}';

    if (!isError) {
      _lastErrorSignature = '';
      return const SizedBox.shrink();
    }

    if (signature != _lastErrorSignature) {
      _lastErrorSignature = signature;
      final String message = _transportErrorMessage(context, controller);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) {
          return;
        }
        messenger.showSnackBar(SnackBar(content: Text(message)));
      });
    }

    return const SizedBox.shrink();
  }
}

class _DownloadSongbooksDialog extends StatefulWidget {
  const _DownloadSongbooksDialog({required this.controller});

  final DiatarMainController controller;

  @override
  State<_DownloadSongbooksDialog> createState() =>
      _DownloadSongbooksDialogState();
}

class _DownloadSongbooksDialogState extends State<_DownloadSongbooksDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<DtxManageItem>> _dtxItemsFuture;
  late Future<List<DtzManageItem>> _dtzItemsFuture;
  late Future<List<DtzManageItem>> _musicItemsFuture;

  final Set<String> _downloadSelected = <String>{};
  final Set<String> _excludedFiles = <String>{};
  final Set<String> _collapsedDtxGroups = <String>{};
  bool _dtxCollapsedGroupsInitialized = false;
  bool _dtxSelectionInitialized = false;

  final _MediaTabSelections _dtzSelections = _MediaTabSelections();
  final _MediaTabSelections _musicSelections = _MediaTabSelections();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _dtxItemsFuture = widget.controller.loadDtxManagerItems();
    _dtzItemsFuture = widget.controller.loadDtzManagerItems();
    _musicItemsFuture = widget.controller.loadMusicManagerItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _dtxSelectionInitialized = false;
      _downloadSelected.clear();
      _excludedFiles.clear();
      _collapsedDtxGroups.clear();
      _dtxCollapsedGroupsInitialized = false;
      _dtxItemsFuture = widget.controller.loadDtxManagerItems();

      _dtzSelections.initialized = false;
      _dtzSelections.downloadSelected.clear();
      _dtzSelections.excludedFiles.clear();
      _dtzSelections.allItems = const <DtzManageItem>[];
      _dtzItemsFuture = widget.controller.loadDtzManagerItems();
      _musicSelections.initialized = false;
      _musicSelections.downloadSelected.clear();
      _musicSelections.excludedFiles.clear();
      _musicSelections.allItems = const <DtzManageItem>[];
      _musicItemsFuture = widget.controller.loadMusicManagerItems();
    });
  }

  String _displayGroup(DtxManageItem managed, BuildContext context) {
    final l10n = context.l10n;
    if (managed.item.isUserProvided) {
      return l10n.downloadUserImportedGroup;
    }
    final String rawGroup = managed.item.group.trim();
    return rawGroup.isEmpty ? l10n.ungroupedBookGroupLabel : rawGroup;
  }

  bool? _groupDownloadValue(List<DtxManageItem> items) {
    final List<DtxManageItem> eligible = items
        .where(
          (DtxManageItem item) =>
              item.item.isOfficial && item.item.updateAvailable,
        )
        .toList();
    if (eligible.isEmpty) {
      return false;
    }
    final int selectedCount = eligible
        .where(
          (DtxManageItem item) =>
              _downloadSelected.contains(item.item.fileName),
        )
        .length;
    if (selectedCount == 0) {
      return false;
    }
    if (selectedCount == eligible.length) {
      return true;
    }
    return null;
  }

  bool? _dtxUpdateValue(List<DtxManageItem> items) {
    final List<DtxManageItem> eligible = items
        .where(
          (DtxManageItem item) =>
              item.item.isOfficial && item.item.updateAvailable,
        )
        .toList();
    if (eligible.isEmpty) {
      return false;
    }
    final int selected = eligible
        .where(
          (DtxManageItem item) =>
              _downloadSelected.contains(item.item.fileName),
        )
        .length;
    if (selected == 0) {
      return false;
    }
    if (selected == eligible.length) {
      return true;
    }
    return null;
  }

  bool? _dtxExcludedValue(List<DtxManageItem> items) {
    if (items.isEmpty) {
      return false;
    }
    final int selected = items
        .where(
          (DtxManageItem item) => _excludedFiles.contains(item.item.fileName),
        )
        .length;
    if (selected == 0) {
      return false;
    }
    if (selected == items.length) {
      return true;
    }
    return null;
  }

  String _displayImportedFileName(String fileName) {
    return fileName.replaceFirst(
      RegExp(r'\.bin(?=\.dtx$)', caseSensitive: false),
      '',
    );
  }

  String _subtitleFor(DtxDownloadItem item, BuildContext context) {
    final l10n = context.l10n;
    if (item.isUserProvided) {
      return _displayImportedFileName(item.fileName);
    }
    if (item.updateAvailable) {
      return l10n.downloadManagerUpdateAvailable;
    }
    return l10n.downloadManagerUpToDate;
  }

  bool? _mediaUpdateValue(_MediaTabSelections selections) {
    final List<DtzManageItem> eligible = selections.allItems
        .where(
          (DtzManageItem item) =>
              item.item.isOfficial && item.item.updateAvailable,
        )
        .toList();
    if (eligible.isEmpty) {
      return false;
    }
    final int selected = eligible
        .where(
          (DtzManageItem item) =>
              selections.downloadSelected.contains(item.item.fileName),
        )
        .length;
    if (selected == 0) {
      return false;
    }
    if (selected == eligible.length) {
      return true;
    }
    return null;
  }

  bool? _mediaExcludedValue(_MediaTabSelections selections) {
    if (selections.allItems.isEmpty) {
      return false;
    }
    final int selected = selections.allItems
        .where(
          (DtzManageItem item) =>
              selections.excludedFiles.contains(item.item.fileName),
        )
        .length;
    if (selected == 0) {
      return false;
    }
    if (selected == selections.allItems.length) {
      return true;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Expanded(child: Text(l10n.downloadTitle)),
          IconButton(
            tooltip: l10n.refreshTooltip,
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          children: <Widget>[
            TabBar(
              controller: _tabController,
              tabs: <Widget>[
                Tab(text: l10n.downloadTabDtx),
                Tab(text: l10n.downloadTabDtz),
                Tab(text: l10n.downloadTabMusic),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildDtxTab(l10n),
                  _buildDtzTab(l10n),
                  _buildDtzTab(l10n, music: true),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        OutlinedButton(
          onPressed: _tabController.index == 0
              ? () => _importDtxFiles(context)
              : _tabController.index == 1
              ? () => _importDtzFiles(context)
              : () => _showMusicImportNotImplemented(context),
          child: Text(
            _tabController.index == 0
                ? l10n.importDtxFilesButton
                : _tabController.index == 1
                ? l10n.importDtzFilesButton
                : l10n.importMusicFilesButton,
          ),
        ),
        FilledButton(
          onPressed: widget.controller.downloadInProgress
              ? null
              : () => Navigator.of(context).pop(
                  _DownloadDialogResult(
                    dtxDownloadSelected: Set<String>.from(_downloadSelected),
                    dtxExcludedSelected: Set<String>.from(_excludedFiles),
                    dtzDownloadSelected: Set<String>.from(
                      _dtzSelections.downloadSelected,
                    ),
                    dtzExcludedSelected: Set<String>.from(
                      _dtzSelections.excludedFiles,
                    ),
                    musicDownloadSelected: Set<String>.from(
                      _musicSelections.downloadSelected,
                    ),
                    musicExcludedSelected: Set<String>.from(
                      _musicSelections.excludedFiles,
                    ),
                  ),
                ),
          child: Text(l10n.apply),
        ),
      ],
    );
  }

  Widget _buildDtxTab(AppLocalizations l10n) {
    return FutureBuilder<List<DtxManageItem>>(
      future: _dtxItemsFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<DtxManageItem>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _centeredProgress(l10n);
            }
            if (snapshot.hasError) {
              return Text(l10n.statusDownloadError('${snapshot.error}'));
            }

            final List<DtxManageItem> items =
                snapshot.data ?? const <DtxManageItem>[];
            if (!_dtxSelectionInitialized) {
              _downloadSelected
                ..clear()
                ..addAll(
                  items
                      .where(
                        (DtxManageItem managed) =>
                            managed.item.isOfficial &&
                            managed.item.updateAvailable &&
                            !managed.excluded,
                      )
                      .map((DtxManageItem managed) => managed.item.fileName),
                );
              _excludedFiles
                ..clear()
                ..addAll(
                  items
                      .where((DtxManageItem managed) => managed.excluded)
                      .map((DtxManageItem managed) => managed.item.fileName),
                );
              _dtxSelectionInitialized = true;
            }

            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.statusDownloadSummaryNone),
              );
            }

            final Map<String, List<DtxManageItem>> grouped =
                <String, List<DtxManageItem>>{};
            for (final DtxManageItem managed in items) {
              final String group = _displayGroup(managed, context);
              grouped.putIfAbsent(group, () => <DtxManageItem>[]).add(managed);
            }

            _collapsedDtxGroups.removeWhere(
              (String group) => !grouped.containsKey(group),
            );
            if (!_dtxCollapsedGroupsInitialized) {
              _collapsedDtxGroups
                ..clear()
                ..addAll(grouped.keys);
              _dtxCollapsedGroupsInitialized = true;
            }

            final List<_DtxManagerListEntry> entries = <_DtxManagerListEntry>[];
            for (final MapEntry<String, List<DtxManageItem>> entry
                in grouped.entries) {
              entries.add(_DtxManagerListEntry.header(entry.key));
              if (!_collapsedDtxGroups.contains(entry.key)) {
                for (final DtxManageItem managed in entry.value) {
                  entries.add(_DtxManagerListEntry.item(managed));
                }
              }
            }

            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compactMode = constraints.maxWidth < 560;
                final double actionColumnWidth = compactMode ? 56 : 92;
                final bool canToggleUpdates = items.any(
                  (DtxManageItem item) =>
                      item.item.isOfficial && item.item.updateAvailable,
                );

                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Row(
                        children: <Widget>[
                          const Expanded(child: SizedBox.shrink()),
                          SizedBox(
                            width: actionColumnWidth,
                            child: compactMode
                                ? Tooltip(
                                    message: l10n.downloadManagerUpdateColumn,
                                    child: const Icon(Icons.refresh, size: 18),
                                  )
                                : Text(
                                    l10n.downloadManagerUpdateColumn,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                          ),
                          SizedBox(
                            width: actionColumnWidth,
                            child: compactMode
                                ? Tooltip(
                                    message: l10n.downloadManagerExcludedColumn,
                                    child: const Icon(
                                      Icons.not_interested,
                                      size: 18,
                                    ),
                                  )
                                : Text(
                                    l10n.downloadManagerExcludedColumn,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: entries.length + 1,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: <Widget>[
                                  const Expanded(child: SizedBox.shrink()),
                                  SizedBox(
                                    width: actionColumnWidth,
                                    child: Center(
                                      child: Checkbox(
                                        tristate: true,
                                        value: _dtxUpdateValue(items),
                                        onChanged: canToggleUpdates
                                            ? (bool? checked) {
                                                setState(() {
                                                  final bool clearColumn =
                                                      _dtxUpdateValue(items) !=
                                                      false;
                                                  for (final DtxManageItem item
                                                      in items) {
                                                    if (!item.item.isOfficial ||
                                                        !item
                                                            .item
                                                            .updateAvailable) {
                                                      continue;
                                                    }
                                                    if (!clearColumn) {
                                                      _downloadSelected.add(
                                                        item.item.fileName,
                                                      );
                                                      _excludedFiles.remove(
                                                        item.item.fileName,
                                                      );
                                                    } else {
                                                      _downloadSelected.remove(
                                                        item.item.fileName,
                                                      );
                                                    }
                                                  }
                                                });
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: actionColumnWidth,
                                    child: Center(
                                      child: Checkbox(
                                        tristate: true,
                                        value: _dtxExcludedValue(items),
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            final bool clearColumn =
                                                _dtxExcludedValue(items) !=
                                                false;
                                            for (final DtxManageItem item
                                                in items) {
                                              if (!clearColumn) {
                                                _excludedFiles.add(
                                                  item.item.fileName,
                                                );
                                                _downloadSelected.remove(
                                                  item.item.fileName,
                                                );
                                              } else {
                                                _excludedFiles.remove(
                                                  item.item.fileName,
                                                );
                                                if (item.item.isOfficial &&
                                                    item.item.updateAvailable) {
                                                  _downloadSelected.add(
                                                    item.item.fileName,
                                                  );
                                                }
                                              }
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final _DtxManagerListEntry entry = entries[index - 1];
                          if (entry.isHeader) {
                            final String groupName = entry.group!;
                            final bool isCollapsed = _collapsedDtxGroups
                                .contains(groupName);
                            final List<DtxManageItem> groupItems =
                                grouped[groupName] ?? const <DtxManageItem>[];
                            final bool hasDownloadEligible = groupItems.any(
                              (DtxManageItem item) =>
                                  item.item.isOfficial &&
                                  item.item.updateAvailable,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 2),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        setState(() {
                                          if (isCollapsed) {
                                            _collapsedDtxGroups.remove(
                                              groupName,
                                            );
                                          } else {
                                            _collapsedDtxGroups.add(groupName);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            Icon(
                                              isCollapsed
                                                  ? Icons.chevron_right
                                                  : Icons.expand_more,
                                              size: 20,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '[$groupName]',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: actionColumnWidth,
                                    child: Center(
                                      child: Checkbox(
                                        tristate: true,
                                        value: _groupDownloadValue(groupItems),
                                        onChanged: hasDownloadEligible
                                            ? (bool? checked) {
                                                setState(() {
                                                  final bool clearColumn =
                                                      _groupDownloadValue(
                                                        groupItems,
                                                      ) !=
                                                      false;
                                                  for (final DtxManageItem item
                                                      in groupItems) {
                                                    if (!item.item.isOfficial ||
                                                        !item
                                                            .item
                                                            .updateAvailable) {
                                                      continue;
                                                    }
                                                    if (!clearColumn) {
                                                      _downloadSelected.add(
                                                        item.item.fileName,
                                                      );
                                                      _excludedFiles.remove(
                                                        item.item.fileName,
                                                      );
                                                    } else {
                                                      _downloadSelected.remove(
                                                        item.item.fileName,
                                                      );
                                                    }
                                                  }
                                                });
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: actionColumnWidth,
                                    child: Center(
                                      child: Checkbox(
                                        tristate: true,
                                        value: _dtxExcludedValue(groupItems),
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            final bool clearColumn =
                                                _dtxExcludedValue(groupItems) !=
                                                false;
                                            for (final DtxManageItem item
                                                in groupItems) {
                                              if (!clearColumn) {
                                                _excludedFiles.add(
                                                  item.item.fileName,
                                                );
                                                _downloadSelected.remove(
                                                  item.item.fileName,
                                                );
                                              } else {
                                                _excludedFiles.remove(
                                                  item.item.fileName,
                                                );
                                                if (item.item.isOfficial &&
                                                    item.item.updateAvailable) {
                                                  _downloadSelected.add(
                                                    item.item.fileName,
                                                  );
                                                }
                                              }
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final DtxManageItem managed = entry.item!;
                          final DtxDownloadItem item = managed.item;
                          final bool canUpdate =
                              item.isOfficial && item.updateAvailable;
                          return Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item.longName),
                                    subtitle: Text(_subtitleFor(item, context)),
                                  ),
                                ),
                                SizedBox(
                                  width: actionColumnWidth,
                                  child: Center(
                                    child: canUpdate
                                        ? Checkbox(
                                            value: _downloadSelected.contains(
                                              item.fileName,
                                            ),
                                            onChanged: (bool? checked) {
                                              setState(() {
                                                if (checked ?? false) {
                                                  _downloadSelected.add(
                                                    item.fileName,
                                                  );
                                                  _excludedFiles.remove(
                                                    item.fileName,
                                                  );
                                                } else {
                                                  _downloadSelected.remove(
                                                    item.fileName,
                                                  );
                                                }
                                              });
                                            },
                                          )
                                        : Tooltip(
                                            message: l10n
                                                .downloadManagerUpdateColumn,
                                            child: const Icon(
                                              Icons.remove,
                                              size: 18,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(
                                  width: actionColumnWidth,
                                  child: Center(
                                    child: Checkbox(
                                      value: _excludedFiles.contains(
                                        item.fileName,
                                      ),
                                      onChanged: (bool? checked) {
                                        setState(() {
                                          if (checked ?? false) {
                                            _excludedFiles.add(item.fileName);
                                            _downloadSelected.remove(
                                              item.fileName,
                                            );
                                          } else {
                                            _excludedFiles.remove(
                                              item.fileName,
                                            );
                                            if (canUpdate) {
                                              _downloadSelected.add(
                                                item.fileName,
                                              );
                                            }
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
    );
  }

  Widget _buildDtzTab(AppLocalizations l10n, {bool music = false}) {
    final _MediaTabSelections selections = music
        ? _musicSelections
        : _dtzSelections;
    return FutureBuilder<List<DtzManageItem>>(
      future: music ? _musicItemsFuture : _dtzItemsFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<DtzManageItem>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _centeredProgress(l10n);
            }
            if (snapshot.hasError) {
              return Text(l10n.statusDownloadError('${snapshot.error}'));
            }

            final List<DtzManageItem> items =
                snapshot.data ?? const <DtzManageItem>[];
            selections.allItems = items;
            if (!selections.initialized) {
              selections.downloadSelected.clear();
              selections.excludedFiles
                ..clear()
                ..addAll(
                  items
                      .where((DtzManageItem item) => !music || item.excluded)
                      .map((DtzManageItem item) => item.item.fileName),
                );
              selections.initialized = true;
            }

            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.downloadDtzNoItems),
              );
            }

            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compactMode = constraints.maxWidth < 560;
                final double actionColumnWidth = compactMode ? 56 : 92;
                final bool canToggleUpdates = items.any(
                  (DtzManageItem item) =>
                      item.item.isOfficial && item.item.updateAvailable,
                );

                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Row(
                        children: <Widget>[
                          const Expanded(child: SizedBox.shrink()),
                          SizedBox(
                            width: actionColumnWidth,
                            child: compactMode
                                ? Tooltip(
                                    message: l10n.downloadManagerUpdateColumn,
                                    child: const Icon(Icons.refresh, size: 18),
                                  )
                                : Text(
                                    l10n.downloadManagerUpdateColumn,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                          ),
                          SizedBox(
                            width: actionColumnWidth,
                            child: compactMode
                                ? Tooltip(
                                    message: l10n.downloadManagerExcludedColumn,
                                    child: const Icon(
                                      Icons.not_interested,
                                      size: 18,
                                    ),
                                  )
                                : Text(
                                    l10n.downloadManagerExcludedColumn,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length + 1,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: <Widget>[
                                  const Expanded(child: SizedBox.shrink()),
                                  SizedBox(
                                    width: actionColumnWidth,
                                    child: Center(
                                      child: Checkbox(
                                        tristate: true,
                                        value: _mediaUpdateValue(selections),
                                        onChanged: canToggleUpdates
                                            ? (bool? checked) {
                                                setState(() {
                                                  final bool clearColumn =
                                                      _mediaUpdateValue(
                                                        selections,
                                                      ) !=
                                                      false;
                                                  for (final DtzManageItem item
                                                      in selections.allItems) {
                                                    if (!item.item.isOfficial ||
                                                        !item
                                                            .item
                                                            .updateAvailable) {
                                                      continue;
                                                    }
                                                    if (!clearColumn) {
                                                      selections
                                                          .downloadSelected
                                                          .add(
                                                            item.item.fileName,
                                                          );
                                                      selections.excludedFiles
                                                          .remove(
                                                            item.item.fileName,
                                                          );
                                                    } else {
                                                      selections
                                                          .downloadSelected
                                                          .remove(
                                                            item.item.fileName,
                                                          );
                                                    }
                                                  }
                                                });
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: actionColumnWidth,
                                    child: Center(
                                      child: Checkbox(
                                        tristate: true,
                                        value: _mediaExcludedValue(selections),
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            final bool clearColumn =
                                                _mediaExcludedValue(
                                                  selections,
                                                ) !=
                                                false;
                                            for (final DtzManageItem item
                                                in selections.allItems) {
                                              if (!clearColumn) {
                                                selections.excludedFiles.add(
                                                  item.item.fileName,
                                                );
                                                selections.downloadSelected
                                                    .remove(item.item.fileName);
                                              } else {
                                                selections.excludedFiles.remove(
                                                  item.item.fileName,
                                                );
                                                if (item.item.isOfficial &&
                                                    item.item.updateAvailable) {
                                                  selections.downloadSelected
                                                      .add(item.item.fileName);
                                                }
                                              }
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final DtzManageItem managed = items[index - 1];
                          final DtzDownloadItem item = managed.item;
                          final bool canUpdate =
                              item.isOfficial && item.updateAvailable;
                          final String displayTitle = item.title.trim().isEmpty
                              ? item.longName
                              : item.title;
                          final String debugFiles = <String>[
                            item.fileName,
                            ...item.zipNames,
                          ].join(', ');

                          return Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(displayTitle),
                                    subtitle: kDebugMode
                                        ? Text(debugFiles)
                                        : null,
                                  ),
                                ),
                                SizedBox(
                                  width: actionColumnWidth,
                                  child: Center(
                                    child: canUpdate
                                        ? Checkbox(
                                            value: selections.downloadSelected
                                                .contains(item.fileName),
                                            onChanged: (bool? checked) {
                                              setState(() {
                                                if (checked ?? false) {
                                                  selections.downloadSelected
                                                      .add(item.fileName);
                                                  selections.excludedFiles
                                                      .remove(item.fileName);
                                                } else {
                                                  selections.downloadSelected
                                                      .remove(item.fileName);
                                                }
                                              });
                                            },
                                          )
                                        : Tooltip(
                                            message: l10n
                                                .downloadManagerUpdateColumn,
                                            child: const Icon(
                                              Icons.remove,
                                              size: 18,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(
                                  width: actionColumnWidth,
                                  child: Center(
                                    child: Checkbox(
                                      value: selections.excludedFiles.contains(
                                        item.fileName,
                                      ),
                                      onChanged: (bool? checked) {
                                        setState(() {
                                          if (checked ?? false) {
                                            selections.excludedFiles.add(
                                              item.fileName,
                                            );
                                            selections.downloadSelected.remove(
                                              item.fileName,
                                            );
                                          } else {
                                            selections.excludedFiles.remove(
                                              item.fileName,
                                            );
                                            if (canUpdate) {
                                              selections.downloadSelected.add(
                                                item.fileName,
                                              );
                                            }
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
    );
  }

  Widget _centeredProgress(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(l10n.statusDownloadListLoading),
      ],
    );
  }

  Future<void> _importDtzFiles(BuildContext context) async {
    final bool? didImport = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ImportDtzDialog(controller: widget.controller),
    );
    if ((didImport ?? false) && context.mounted) {
      _reload();
    }
  }

  void _showMusicImportNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.importMusicNotImplemented)),
    );
  }

  Future<void> _importDtxFiles(BuildContext context) async {
    final List<XFile> files = await DesktopProjectorBridge.instance
        .runWithNativeDialog(
          () => showFileOpenPanel(extensions: const <String>['dtx']),
        );
    if (files.isEmpty || !context.mounted) {
      return;
    }
    try {
      final DtxImportResult result = await widget.controller.importDtxFiles(
        files,
      );
      if (!context.mounted) return;
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      if (result.importedCount > 0 && !result.hasFailures) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.importDtxFilesSuccess(result.importedCount),
            ),
          ),
        );
        _reload();
        return;
      }

      if (result.importedCount > 0 && result.hasFailures) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.importDtxFilesPartial(
                result.importedCount,
                result.failedCount,
                result.shortFailureSummary(),
              ),
            ),
          ),
        );
        _reload();
        return;
      }

      final String reason = result.shortFailureSummary();
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.importDtxFilesErrorDetailed(reason)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final String details = e.toString().trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            details.isEmpty
                ? context.l10n.importDtxFilesError
                : context.l10n.importDtxFilesErrorDetailed(details),
          ),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// DTZ user-import preview dialog
// ---------------------------------------------------------------------------

class _ImportDtzDialog extends StatefulWidget {
  const _ImportDtzDialog({required this.controller});

  final DiatarMainController controller;

  @override
  State<_ImportDtzDialog> createState() => _ImportDtzDialogState();
}

class _ImportDtzDialogState extends State<_ImportDtzDialog> {
  XFile? _dtzFile;
  final List<XFile> _zipFiles = <XFile>[];
  DtzUserImportAnalysis? _analysis;
  Set<String> _selectedPkgs = <String>{};
  bool _analysing = false;
  bool _importing = false;
  bool _cancelRequested = false;
  StreamingZipProgress? _progress;

  bool get _canValidate => _dtzFile != null && !_analysing && !_importing;
  bool get _canImport =>
      _analysis != null && _selectedPkgs.isNotEmpty && !_importing;

  void _resetAnalysis() {
    _analysis = null;
    _selectedPkgs = <String>{};
  }

  Future<void> _pickDtz() async {
    if (_importing) return;
    final List<XFile> files = await DesktopProjectorBridge.instance
        .runWithNativeDialog(
          () => showFileOpenPanel(extensions: const <String>['dtz']),
        );
    if (!mounted || files.isEmpty) return;
    setState(() {
      _dtzFile = files.first;
      _resetAnalysis();
    });
  }

  Future<void> _addZips() async {
    if (_importing) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final XFile? file = await pickAndroidZipImportFile();
        if (!mounted || file == null) return;
        setState(() {
          _zipFiles.add(file);
          _resetAnalysis();
        });
      } catch (error) {
        if (!mounted) return;
        await _showIssues(
          title: context.l10n.importDtzFailureDialogTitle,
          issues: <String>[context.l10n.importDtzError(error.toString())],
        );
      }
      return;
    }
    final List<XFile> files = await DesktopProjectorBridge.instance
        .runWithNativeDialog(
          () => showFileOpenPanel(extensions: const <String>['zip']),
        );
    if (!mounted || files.isEmpty) return;
    setState(() {
      _zipFiles.addAll(files);
      _resetAnalysis();
    });
  }

  void _removeZip(int index) {
    final XFile file = _zipFiles[index];
    setState(() {
      _zipFiles.removeAt(index);
      _resetAnalysis();
    });
    unawaited(deleteAndroidZipImportFile(file.path));
  }

  Future<void> _validate() async {
    if (_dtzFile == null || _analysing) return;
    setState(() {
      _analysing = true;
      _analysis = null;
    });
    try {
      final DtzUserImportAnalysis analysis = await widget.controller
          .analyzeDtzUserImport(<XFile>[_dtzFile!, ..._zipFiles]);
      if (!mounted) return;
      setState(() {
        _analysing = false;
        _analysis = analysis;
        _selectedPkgs = analysis.packages
            .where(
              (DtzImportPackageAnalysis p) =>
                  p.status == DtzImportStatus.ok ||
                  p.status == DtzImportStatus.warning,
            )
            .map((DtzImportPackageAnalysis p) => p.dtzFileName)
            .toSet();
      });
      if (analysis.zipFailures.isNotEmpty) {
        await _showIssues(
          title: context.l10n.importDtzFailureDialogTitle,
          issues: analysis.zipFailures
              .map(
                (DtzZipFailure failure) => context.l10n.importDtzFailureDetails(
                  failure.zipName,
                  _zipFailureMessage(failure.error),
                ),
              )
              .toList(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _analysing = false);
      await _showIssues(
        title: context.l10n.importDtzFailureDialogTitle,
        issues: <String>[context.l10n.importDtzError(e.toString())],
      );
    }
  }

  Future<void> _import() async {
    final DtzUserImportAnalysis? analysis = _analysis;
    if (analysis == null || _dtzFile == null || _importing) return;
    final List<DtzImportPackageAnalysis> toImport = analysis.packages
        .where(
          (DtzImportPackageAnalysis p) => _selectedPkgs.contains(p.dtzFileName),
        )
        .toList();
    if (toImport.isEmpty) return;

    if (toImport.any(
      (DtzImportPackageAnalysis p) => p.status == DtzImportStatus.error,
    )) {
      final bool proceed = await _confirmImportWithErrors(toImport);
      if (!mounted || !proceed) return;
    }

    setState(() {
      _importing = true;
      _cancelRequested = false;
      _progress = null;
    });
    try {
      final DtzUserImportCommitResult result = await widget.controller
          .commitDtzUserImport(
            toImport: toImport,
            files: <XFile>[_dtzFile!, ..._zipFiles],
            isCancelled: () => _cancelRequested,
            onProgress: (StreamingZipProgress progress) {
              if (mounted) setState(() => _progress = progress);
            },
          );
      if (!mounted) return;
      final String msg = result.extractedFileCount > 0
          ? context.l10n.importDtzSuccess(
              result.importedDtzCount,
              result.extractedFileCount,
            )
          : context.l10n.importDtzSuccessNoMedia(result.importedDtzCount);
      if (result.failures.isNotEmpty) {
        setState(() => _importing = false);
        await _showIssues(
          title: context.l10n.importDtzPartialImportTitle,
          issues: <String>[
            msg,
            ...result.zipFailures.map(
              (DtzZipFailure failure) => context.l10n.importDtzFailureDetails(
                failure.zipName,
                _zipFailureMessage(failure.error),
              ),
            ),
            ...result.failures.where(
              (String failure) => !result.zipFailures.any(
                (DtzZipFailure zipFailure) =>
                    failure.startsWith('${zipFailure.zipName}:'),
              ),
            ),
          ],
        );
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      await _showIssues(
        title: context.l10n.importDtzFailureDialogTitle,
        issues: <String>[context.l10n.importDtzError(e.toString())],
      );
    }
  }

  String _zipFailureMessage(StreamingZipException error) {
    switch (error.code) {
      case StreamingZipErrorCode.sourceUnreadable:
        return context.l10n.importDtzFailureSourceUnreadable;
      case StreamingZipErrorCode.invalidArchive:
        return context.l10n.importDtzFailureInvalidArchive;
      case StreamingZipErrorCode.tooManyEntries:
        return context.l10n.importDtzFailureTooManyEntries;
      case StreamingZipErrorCode.entryTooLarge:
        return context.l10n.importDtzFailureEntryTooLarge;
      case StreamingZipErrorCode.totalTooLarge:
        return context.l10n.importDtzFailureTotalTooLarge;
      case StreamingZipErrorCode.cancelled:
        return context.l10n.importDtzFailureCancelled;
      case StreamingZipErrorCode.entryUnreadable:
        return context.l10n.importDtzFailureEntryUnreadable;
      case StreamingZipErrorCode.writeFailed:
        return context.l10n.importDtzFailureWriteFailed;
    }
  }

  Future<void> _showIssues({
    required String title,
    required List<String> issues,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: Text(issues.join('\n\n'))),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final XFile file in _zipFiles) {
      unawaited(deleteAndroidZipImportFile(file.path));
    }
    super.dispose();
  }

  Future<bool> _confirmImportWithErrors(
    List<DtzImportPackageAnalysis> toImport,
  ) async {
    final int errorCount = toImport
        .where(
          (DtzImportPackageAnalysis p) => p.status == DtzImportStatus.error,
        )
        .length;
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dlgContext) => AlertDialog(
        title: Text(dlgContext.l10n.importDtzConfirmErrorsTitle),
        content: Text(dlgContext.l10n.importDtzConfirmErrorsBody(errorCount)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(false),
            child: Text(dlgContext.l10n.close),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dlgContext).pop(true),
            child: Text(dlgContext.l10n.importDtzImportButton),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  /// Whether a package can be force-imported despite its error status.
  /// A pure parse failure cannot be force-imported; missing media files and
  /// missing dia-IDs are tolerated (the app is fault-tolerant at runtime).
  bool _canForceImport(DtzImportPackageAnalysis pkg) {
    if (pkg.status != DtzImportStatus.error) return true;
    return pkg.missingFiles.isNotEmpty || pkg.missingDiaIds.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final DtzUserImportAnalysis? analysis = _analysis;

    return AlertDialog(
      title: Text(l10n.importDtzPreviewTitle),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- DTZ section ---
              Text(l10n.importDtzDtzSection, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _dtzFile == null
                          ? l10n.importDtzNoDtzSelected
                          : _dtzFile!.name,
                      style: _dtzFile == null
                          ? TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            )
                          : null,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _importing ? null : _pickDtz,
                    child: Text(l10n.importDtzSelectDtz),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- ZIP section ---
              Text(l10n.importDtzZipSection, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _importing ? null : _addZips,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.importDtzAddZip),
              ),
              if (_zipFiles.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                for (int i = 0; i < _zipFiles.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.folder_zip_outlined, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _zipFiles[i].name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          onPressed: _importing ? null : () => _removeZip(i),
                        ),
                      ],
                    ),
                  ),
              ],

              // --- Analysis result ---
              if (_analysing) ...<Widget>[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              if (_importing) ...<Widget>[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  _progress == null
                      ? l10n.importDtzImportButton
                      : l10n.importDtzProgress(
                          _progress!.entryName,
                          _progress!.completedEntries + 1,
                          _progress!.totalEntries,
                        ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (analysis != null && !_analysing) ...<Widget>[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 4),
                for (final DtzImportPackageAnalysis pkg in analysis.packages)
                  _PackageRow(
                    pkg: pkg,
                    selected: _selectedPkgs.contains(pkg.dtzFileName),
                    onChanged: !_canForceImport(pkg) || _importing
                        ? null
                        : (bool? v) {
                            setState(() {
                              if (v ?? false) {
                                _selectedPkgs.add(pkg.dtzFileName);
                              } else {
                                _selectedPkgs.remove(pkg.dtzFileName);
                              }
                            });
                          },
                    l10n: l10n,
                  ),
                if (analysis.orphanZipNames.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.importDtzPreviewOrphanZips(
                        analysis.orphanZipNames.length,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _importing ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.close),
        ),
        OutlinedButton(
          onPressed: _canValidate ? _validate : null,
          child: Text(l10n.importDtzValidateButton),
        ),
        FilledButton(
          onPressed: _canImport ? _import : null,
          child: Text(l10n.importDtzImportButton),
        ),
        if (_importing)
          TextButton(
            onPressed: () => setState(() => _cancelRequested = true),
            child: Text(l10n.cancel),
          ),
      ],
    );
  }
}

class _PackageRow extends StatefulWidget {
  const _PackageRow({
    required this.pkg,
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  final DtzImportPackageAnalysis pkg;
  final bool selected;
  final ValueChanged<bool?>? onChanged;
  final AppLocalizations l10n;

  @override
  State<_PackageRow> createState() => _PackageRowState();
}

class _PackageRowState extends State<_PackageRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final DtzImportPackageAnalysis pkg = widget.pkg;
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    switch (pkg.status) {
      case DtzImportStatus.ok:
        statusColor = Colors.green.shade700;
        statusIcon = Icons.check_circle_outline;
        statusText = pkg.referencedFiles.isEmpty
            ? widget.l10n.importDtzStatusNoRefs
            : widget.l10n.importDtzStatusOk(pkg.matchedFiles.length);
      case DtzImportStatus.warning:
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.warning_amber_outlined;
        if (pkg.missingFiles.isNotEmpty) {
          statusText = widget.l10n.importDtzStatusWarning(
            pkg.missingFiles.length,
            pkg.referencedFiles.length,
          );
        } else {
          statusText = widget.l10n.importDtzStatusMissingDiaIdsCount(
            pkg.missingDiaIds.length,
          );
        }
      case DtzImportStatus.error:
        statusColor = Theme.of(context).colorScheme.error;
        statusIcon = Icons.cancel_outlined;
        if (pkg.missingFiles.isNotEmpty) {
          statusText = widget.l10n.importDtzStatusError(
            pkg.missingFiles.length,
            pkg.referencedFiles.length,
          );
        } else if (pkg.missingDiaIds.isNotEmpty) {
          statusText = widget.l10n.importDtzStatusMissingDiaIdsCount(
            pkg.missingDiaIds.length,
          );
        } else {
          statusText = widget.l10n.importDtzStatusParseError;
        }
    }

    final bool hasDetails =
        pkg.missingFiles.isNotEmpty || pkg.missingDiaIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Checkbox(value: widget.selected, onChanged: widget.onChanged),
              const SizedBox(width: 4),
              Icon(statusIcon, size: 18, color: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pkg.dtzFileName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ],
                ),
              ),
              if (hasDetails)
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip: widget.l10n.importDtzDetails,
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
            ],
          ),
          if (_expanded && hasDetails)
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (pkg.missingFiles.isNotEmpty) ...<Widget>[
                      Text(
                        widget.l10n.importDtzMissingFilesTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      for (final String f in pkg.missingFiles.toList()..sort())
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 1),
                          child: Text(f, style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                    if (pkg.missingDiaIds.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        widget.l10n.importDtzMissingDiaIdsTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      for (final String id
                          in pkg.missingDiaIds.toList()..sort())
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 1),
                          child: Text(id, style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookDropdown extends StatelessWidget {
  const _BookDropdown({
    required this.controller,
    required this.onInternetSettingsTap,
  });

  final DiatarMainController controller;
  final VoidCallback onInternetSettingsTap;

  @override
  Widget build(BuildContext context) {
    if (controller.books.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    final bool hasDia =
        controller.hasImportedCustomOrderDia &&
        controller.customOrderSets.isEmpty &&
        controller.customOrderSets
            .where((CustomOrderSet s) => s.enabled)
            .isEmpty;
    final String fallbackDiaName = controller.customOrderLooksLikeBatyu
        ? context.l10n.batyuTooltip
        : controller.customOrderLooksLikeZsolozsma
        ? context.l10n.zsolozsmaTooltip
        : context.l10n.customOrderUnnamedFileName;
    final String diaName =
        controller.suggestedCustomOrderBaseName ?? fallbackDiaName;
    final String virtualBookLabel = context.l10n.diaBookLabel(diaName);
    final List<_BookDropdownEntry> entries = _buildBookDropdownEntries(
      controller.books,
      context.l10n.ungroupedBookGroupLabel,
    );
    final List<CustomOrderSet> enabledSets = controller.customOrderSets
        .where((CustomOrderSet s) => s.enabled)
        .toList();
    final String? activeId = controller.activeCustomOrderSetId;
    final bool hasSets = enabledSets.isNotEmpty;
    final int activeEnabledSetIndex = activeId == null
        ? -1
        : enabledSets.indexWhere((CustomOrderSet s) => s.id == activeId);
    final int initial = controller.diaVirtualBookSelected
        ? (activeEnabledSetIndex >= 0
              ? _customOrderSetValueBase - activeEnabledSetIndex
              : _diaVirtualBookValue)
        : controller.bookIndex;

    return Row(
      children: <Widget>[
        Expanded(
          child: DropdownButtonFormField<int>(
            key: ValueKey<int>(initial),
            initialValue: initial,
            decoration: InputDecoration(
              labelText: context.l10n.bookLabel,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            isExpanded: true,
            items: <DropdownMenuItem<int>>[
              if (hasSets) ...<DropdownMenuItem<int>>[
                DropdownMenuItem<int>(
                  value: _customOrderSetHeaderValue,
                  enabled: false,
                  child: Text(
                    '[${context.l10n.customOrderSetsSection}]',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ...enabledSets.asMap().entries.map((
                  MapEntry<int, CustomOrderSet> e,
                ) {
                  final CustomOrderSet set = e.value;
                  final bool isActive = set.id == activeId;
                  return DropdownMenuItem<int>(
                    value: _customOrderSetValueBase - e.key,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _customOrderSetDisplayName(set, context.l10n),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isActive)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                context.l10n.customOrderSetActive,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              if (hasDia)
                DropdownMenuItem<int>(
                  value: _diaVirtualBookValue,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      virtualBookLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ...entries.asMap().entries.map((
                MapEntry<int, _BookDropdownEntry> e,
              ) {
                final _BookDropdownEntry entry = e.value;
                if (entry.isHeader) {
                  return DropdownMenuItem<int>(
                    value: -(e.key + 1),
                    enabled: false,
                    child: Text(
                      '[${entry.group!}]',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return DropdownMenuItem<int>(
                  value: entry.bookIndex,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        entry.title!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                );
              }),
            ],
            selectedItemBuilder: (BuildContext context) {
              return <Widget>[
                if (hasSets) ...<Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      context.l10n.customOrderSetsSection,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  ...enabledSets.map((CustomOrderSet set) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _customOrderSetDisplayName(set, context.l10n),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }),
                ],
                if (hasDia)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      virtualBookLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ...entries.map((_BookDropdownEntry entry) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      entry.title ?? '[${entry.group!}]',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }),
              ];
            },
            onChanged: (int? value) async {
              if (value == null) {
                return;
              }
              if (value <= _customOrderSetValueBase) {
                final int idx = _customOrderSetValueBase - value;
                if (idx >= 0 && idx < enabledSets.length) {
                  await controller.setActiveCustomOrderSetById(
                    enabledSets[idx].id,
                  );
                }
                return;
              }
              if (value == _diaVirtualBookValue) {
                controller.selectDiaVirtualBook();
                return;
              }
              if (value >= 0) {
                controller.setBookIndex(value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: _statusTooltip(
            context,
            title: context.l10n.settingsInternetTitle,
            state: _mqttIndicatorState(controller),
          ),
          child: InkResponse(
            radius: 20,
            onTap: onInternetSettingsTap,
            child: _statusIcon(
              icon: Icons.public,
              state: _mqttIndicatorState(controller),
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }
}

class _SongDropdown extends StatelessWidget {
  const _SongDropdown({
    required this.controller,
    required this.onLocalNetworkSettingsTap,
  });

  final DiatarMainController controller;
  final VoidCallback onLocalNetworkSettingsTap;

  @override
  Widget build(BuildContext context) {
    if (controller.diaVirtualBookSelected) {
      final List<_DiaSongGroup> groups = _buildDiaSongGroups(
        context.l10n,
        controller,
      );
      if (groups.isEmpty) {
        return const SizedBox.shrink();
      }
      final int selectedCursor = controller.selectedCustomOrderCursor;
      final int selectedGroup = _selectedDiaSongGroupIndex(
        groups,
        selectedCursor,
      );
      final ThemeData theme = Theme.of(context);
      return Row(
        children: <Widget>[
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: selectedGroup.clamp(0, groups.length - 1),
              decoration: InputDecoration(
                labelText: context.l10n.songLabel,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              isExpanded: true,
              items: groups.asMap().entries.map((
                MapEntry<int, _DiaSongGroup> e,
              ) {
                return DropdownMenuItem<int>(
                  value: e.key,
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: <Widget>[
                        if (e.value.verses.every(
                          (_DiaVerseEntry verse) => verse.skipped,
                        ))
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.cancel_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            e.value.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style:
                                e.value.verses.every(
                                  (_DiaVerseEntry verse) => verse.skipped,
                                )
                                ? const TextStyle(color: Colors.grey)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (int? value) {
                if (value == null || value < 0 || value >= groups.length) {
                  return;
                }
                final List<_DiaVerseEntry> verses = groups[value].verses;
                if (verses.isEmpty) {
                  return;
                }
                controller.selectCustomOrderEntryAt(
                  verses.first.customOrderIndex,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          if (!kIsWeb)
            Tooltip(
              message: _statusTooltip(
                context,
                title: context.l10n.settingsLocalNetworkTitle,
                state: _localNetworkIndicatorState(controller),
              ),
              child: InkResponse(
                radius: 20,
                onTap: onLocalNetworkSettingsTap,
                child: _statusIcon(
                  icon: Icons.lan,
                  state: _localNetworkIndicatorState(controller),
                  theme: theme,
                ),
              ),
            )
          else
            const SizedBox(width: 22),
        ],
      );
    }

    final DtxBook? b = controller.currentBook;
    final List<DtxSong> songs = b?.songs ?? const <DtxSong>[];
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    final TextEditingController textController = TextEditingController(
      text: controller.currentSong?.title ?? '',
    );
    return Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            readOnly: true,
            controller: textController,
            decoration: InputDecoration(
              labelText: context.l10n.songLabel,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: const Icon(Icons.search, size: 20),
            ),
            onTap: () {
              _showQuickSongSearch(context, controller, songs, textController);
            },
          ),
        ),
        const SizedBox(width: 8),
        if (!kIsWeb)
          Tooltip(
            message: _statusTooltip(
              context,
              title: context.l10n.settingsLocalNetworkTitle,
              state: _localNetworkIndicatorState(controller),
            ),
            child: InkResponse(
              radius: 20,
              onTap: onLocalNetworkSettingsTap,
              child: _statusIcon(
                icon: Icons.lan,
                state: _localNetworkIndicatorState(controller),
                theme: theme,
              ),
            ),
          )
        else
          const SizedBox(width: 22),
      ],
    );
  }
}

void _showQuickSongSearch(
  BuildContext context,
  DiatarMainController controller,
  List<DtxSong> songs,
  TextEditingController textController,
) {
  final TextEditingController searchController = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          final String query = normalizeSearchText(searchController.text);
          final List<MapEntry<int, DtxSong>> filtered = songs
              .asMap()
              .entries
              .where((MapEntry<int, DtxSong> e) {
                if (query.isEmpty) return true;
                return normalizeSearchText(e.value.title).contains(query);
              })
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: context.l10n.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (BuildContext context, int index) {
                      final MapEntry<int, DtxSong> e = filtered[index];
                      final String title = e.value.separator
                          ? '-- ${e.value.title} --'
                          : e.value.title;
                      return ListTile(
                        title: Text(title),
                        selected: e.key == controller.songIndex,
                        onTap: () {
                          controller.setSongIndex(e.key);
                          textController.text = e.value.title;
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _VerseDropdown extends StatelessWidget {
  const _VerseDropdown({required this.controller});

  final DiatarMainController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.diaVirtualBookSelected) {
      final List<_DiaSongGroup> groups = _buildDiaSongGroups(
        context.l10n,
        controller,
      );
      if (groups.isEmpty) {
        return const SizedBox.shrink();
      }
      final int selectedCursor = controller.selectedCustomOrderCursor;
      final int selectedGroup = _selectedDiaSongGroupIndex(
        groups,
        selectedCursor,
      );
      final List<_DiaVerseEntry> verses = groups[selectedGroup].verses;
      if (verses.isEmpty) {
        return const SizedBox.shrink();
      }
      final int selectedVerse = verses.indexWhere(
        (_DiaVerseEntry v) => v.customOrderIndex == selectedCursor,
      );
      final int initialValue = (selectedVerse >= 0 ? selectedVerse : 0).clamp(
        0,
        verses.length - 1,
      );
      return DropdownButtonFormField<int>(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: context.l10n.verseLabel,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        isExpanded: true,
        items: verses.asMap().entries.map((MapEntry<int, _DiaVerseEntry> e) {
          return DropdownMenuItem<int>(
            value: e.key,
            child: SizedBox(
              width: double.infinity,
              child: Row(
                children: <Widget>[
                  if (e.value.skipped)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      e.value.label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: e.value.skipped
                          ? const TextStyle(color: Colors.grey)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: (int? value) {
          if (value == null || value < 0 || value >= verses.length) {
            return;
          }
          controller.selectCustomOrderEntryAt(verses[value].customOrderIndex);
        },
      );
    }

    final DtxSong? s = controller.currentSong;
    final List<DtxVerse> verses = s?.verses ?? const <DtxVerse>[];
    if (verses.isEmpty) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<int>(
      initialValue: controller.verseIndex.clamp(0, verses.length - 1),
      decoration: InputDecoration(
        labelText: context.l10n.verseLabel,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: verses.asMap().entries.map((MapEntry<int, DtxVerse> e) {
        return DropdownMenuItem<int>(
          value: e.key,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              e.value.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      }).toList(),
      onChanged: (int? value) {
        if (value != null) {
          controller.setVerseIndex(value);
        }
      },
    );
  }
}

class _CustomOrderSetSelector extends StatelessWidget {
  const _CustomOrderSetSelector({required this.controller});

  final DiatarMainController controller;

  @override
  Widget build(BuildContext context) {
    final List<CustomOrderSet> enabledSets = controller.customOrderSets
        .where((CustomOrderSet s) => s.enabled)
        .toList();
    if (enabledSets.length <= 1) {
      return const SizedBox.shrink();
    }
    final String? activeId = controller.activeCustomOrderSetId;
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(activeId),
      initialValue: activeId,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: context.l10n.customOrderSetSelectorLabel,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: enabledSets.map((CustomOrderSet set) {
        return DropdownMenuItem<String>(
          value: set.id,
          child: Text(
            _customOrderSetDisplayName(set, context.l10n),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        if (value != null) {
          unawaited(controller.setActiveCustomOrderSetById(value));
        }
      },
    );
  }
}

String _dialistEntryLabel(
  AppLocalizations l10n,
  DiatarMainController controller,
  CustomOrderEntry entry,
) {
  if (entry.isSeparator) {
    return _cleanSeparatorLabel(entry);
  }
  if (entry.isCustomText || entry.isCustomImage) {
    return localizedCustomEntryLabel(l10n, entry);
  }
  final String explicit = entry.label.trim();
  if (explicit.isNotEmpty) {
    return entry.isSongEntry ? _normalizeSlashSpacing(explicit) : explicit;
  }
  final String fallback = _entryShortLabel(l10n, controller, entry);
  return entry.isSongEntry ? _normalizeSlashSpacing(fallback) : fallback;
}

class _DialistPanel extends StatefulWidget {
  const _DialistPanel({
    required this.controller,
    required this.onInternetSettingsTap,
    required this.onLocalNetworkSettingsTap,
    required this.projectionDisplayButton,
  });

  final DiatarMainController controller;
  final VoidCallback onInternetSettingsTap;
  final VoidCallback onLocalNetworkSettingsTap;
  final Widget projectionDisplayButton;

  @override
  State<_DialistPanel> createState() => _DialistPanelState();
}

class _DialistPanelState extends State<_DialistPanel> {
  static const double _itemExtent = 38;

  final ScrollController _scrollController = ScrollController();
  int _lastScrollTargetIndex = -1;
  int _lastScrollTargetCount = -1;

  DiatarMainController get controller => widget.controller;

  TextStyle? _dialistTitleStyle(
    ThemeData theme, {
    required bool selected,
    required bool isSeparator,
    required bool skipped,
  }) {
    return theme.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      fontStyle: isSeparator ? FontStyle.italic : FontStyle.normal,
      color: skipped || isSeparator ? theme.colorScheme.onSurfaceVariant : null,
    );
  }

  Widget _buildDialistTitle(
    BuildContext context, {
    required ThemeData theme,
    required List<CustomOrderEntry> entries,
    required int index,
    required int selectedCursor,
  }) {
    final CustomOrderEntry entry = entries[index];
    final bool selected = index == selectedCursor;
    final bool isSeparator = entry.isSeparator;
    final TextStyle? style = _dialistTitleStyle(
      theme,
      selected: selected,
      isSeparator: isSeparator,
      skipped: entry.skipped,
    );
    final String label = _dialistEntryLabel(context.l10n, controller, entry);
    final String firstLine = controller.firstTextLineForEntry(entry);

    if (isSeparator || index <= 0) {
      return _buildTitleWithFirstLine(
        title: label,
        firstLine: firstLine,
        titleStyle: style,
      );
    }

    final ({String prefix, String suffix})? split = _splitSlashLabel(label);
    if (split == null) {
      return _buildTitleWithFirstLine(
        title: label,
        firstLine: firstLine,
        titleStyle: style,
      );
    }

    final CustomOrderEntry previousEntry = entries[index - 1];
    if (previousEntry.isSeparator) {
      return _buildTitleWithFirstLine(
        title: label,
        firstLine: firstLine,
        titleStyle: style,
      );
    }

    final String previousLabel = _dialistEntryLabel(
      context.l10n,
      controller,
      previousEntry,
    );
    final ({String prefix, String suffix})? previousSplit = _splitSlashLabel(
      previousLabel,
    );
    if (previousSplit == null || previousSplit.prefix != split.prefix) {
      return _buildTitleWithFirstLine(
        title: label,
        firstLine: firstLine,
        titleStyle: style,
      );
    }

    final bool previousSelected = (index - 1) == selectedCursor;
    final TextStyle? previousStyle = _dialistTitleStyle(
      theme,
      selected: previousSelected,
      isSeparator: previousEntry.isSeparator,
      skipped: previousEntry.skipped,
    );

    final List<InlineSpan> spans = <InlineSpan>[
      TextSpan(
        text: split.prefix,
        style: previousStyle?.copyWith(color: Colors.transparent),
      ),
      TextSpan(text: '/${split.suffix}', style: style),
    ];
    if (firstLine.trim().isNotEmpty) {
      spans.add(
        TextSpan(
          text: ' ($firstLine)',
          style: style?.copyWith(
            fontSize: ((style.fontSize ?? 13) * 0.85),
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureSelectedVisible(int index, int itemCount) {
    if (index < 0 || index >= itemCount) {
      return;
    }
    if (_lastScrollTargetIndex == index &&
        _lastScrollTargetCount == itemCount) {
      return;
    }
    _lastScrollTargetIndex = index;
    _lastScrollTargetCount = itemCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final ScrollPosition pos = _scrollController.position;
      if (!pos.hasViewportDimension) {
        return;
      }

      final double itemTop = index * _itemExtent;
      final double itemBottom = itemTop + _itemExtent;
      final double viewportTop = pos.pixels;
      final double viewportBottom = viewportTop + pos.viewportDimension;
      double? targetOffset;

      if (itemTop < viewportTop) {
        targetOffset = itemTop;
      } else if (itemBottom > viewportBottom) {
        targetOffset = itemBottom - pos.viewportDimension;
      }

      if (targetOffset == null) {
        return;
      }

      final double clamped = targetOffset.clamp(0.0, pos.maxScrollExtent);
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String fallbackDiaName = controller.customOrderLooksLikeBatyu
        ? context.l10n.batyuTooltip
        : controller.customOrderLooksLikeZsolozsma
        ? context.l10n.zsolozsmaTooltip
        : context.l10n.customOrderUnnamedFileName;
    final String dialistName =
        controller.suggestedCustomOrderBaseName ?? fallbackDiaName;
    final List<CustomOrderEntry> entries = controller.customOrder;
    final int selectedCursor = controller.selectedCustomOrderCursor;

    _ensureSelectedVisible(selectedCursor, entries.length);

    final List<CustomOrderSet> enabledSets = controller.customOrderSets
        .where((CustomOrderSet s) => s.enabled)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CustomOrderSetSelector(controller: controller),
              if (enabledSets.length > 1) const SizedBox(height: 6),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.l10n.dialistNamedLabel(dialistName),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  child: entries.isEmpty
                      ? const SizedBox.shrink()
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ListView.builder(
                            controller: _scrollController,
                            primary: false,
                            clipBehavior: Clip.hardEdge,
                            itemCount: entries.length,
                            itemExtent: _itemExtent,
                            itemBuilder: (BuildContext context, int index) {
                              final CustomOrderEntry entry = entries[index];
                              final bool isSeparator = entry.isSeparator;
                              final int normalizedIndex = controller
                                  .normalizeCustomOrderIndex(index);
                              final bool selected =
                                  normalizedIndex == selectedCursor;
                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? theme.colorScheme.primaryContainer
                                            .withValues(alpha: 0.55)
                                      : null,
                                ),
                                child: ListTile(
                                  dense: true,
                                  visualDensity: const VisualDensity(
                                    horizontal: 0,
                                    vertical: -2,
                                  ),
                                  minTileHeight: 38,
                                  leading: SizedBox(
                                    width: 42,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        MergeIndicator(
                                          visual:
                                              controller
                                                  .isCustomOrderEntryMergeFollowerAt(
                                                    index,
                                                  )
                                              ? MergeIndicatorVisual.lowerBrace
                                              : controller
                                                    .isCustomOrderEntryMergeLeaderAt(
                                                      index,
                                                    )
                                              ? MergeIndicatorVisual.upperBrace
                                              : MergeIndicatorVisual.hidden,
                                        ),
                                        if (entry.skipped)
                                          Icon(
                                            Icons.cancel_outlined,
                                            size: 16,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      ],
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  title: _buildDialistTitle(
                                    context,
                                    theme: theme,
                                    entries: entries,
                                    index: index,
                                    selectedCursor: selectedCursor,
                                  ),
                                  onTap: isSeparator
                                      ? null
                                      : () {
                                          controller.selectCustomOrderEntryAt(
                                            normalizedIndex,
                                          );
                                          _ensureSelectedVisible(
                                            normalizedIndex,
                                            entries.length,
                                          );
                                        },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Tooltip(
              message: _statusTooltip(
                context,
                title: context.l10n.settingsInternetTitle,
                state: _mqttIndicatorState(controller),
              ),
              child: InkResponse(
                radius: 20,
                onTap: widget.onInternetSettingsTap,
                child: _statusIcon(
                  icon: Icons.public,
                  state: _mqttIndicatorState(controller),
                  theme: theme,
                ),
              ),
            ),
            const SizedBox(height: 13),
            if (!kIsWeb)
              Tooltip(
                message: _statusTooltip(
                  context,
                  title: context.l10n.settingsLocalNetworkTitle,
                  state: _localNetworkIndicatorState(controller),
                ),
                child: InkResponse(
                  radius: 20,
                  onTap: widget.onLocalNetworkSettingsTap,
                  child: _statusIcon(
                    icon: Icons.lan,
                    state: _localNetworkIndicatorState(controller),
                    theme: theme,
                  ),
                ),
              ),
            const SizedBox(height: 13),
            widget.projectionDisplayButton,
          ],
        ),
      ],
    );
  }
}

class _VersePreview extends StatelessWidget {
  const _VersePreview({
    required this.controller,
    required this.title,
    required this.panelTitle,
    required this.onPreviewTap,
    this.onPreviewLongPress,
  });

  final DiatarMainController controller;
  final String? title;
  final String panelTitle;
  final VoidCallback onPreviewTap;
  final VoidCallback? onPreviewLongPress;

  @override
  Widget build(BuildContext context) {
    final bool showTitle = controller.settings.projUseTitle;
    final RecTextRecord previewRecord = RecTextRecord(
      scholaLine: '',
      title: '',
      lines: controller.projectionDisplayLines,
    );
    final ProjectionFrame frame = TextFrame(record: previewRecord);
    final ProjectionGlobals globals = controller.globals.copyWith(
      projecting: true,
      wordToHighlight: controller.highPos,
      useKotta: controller.diaVirtualBookSelected
          ? false
          : controller.globals.useKotta,
    );
    final ProjectorPainter painter = ProjectorPainter(
      frame: frame,
      globals: globals,
      settings: controller.settings,
      logoTitle: context.l10n.appTitle,
      onHighlightRenderState: (HighlightRenderState state) {
        controller.updateHighlightRenderState(
          maxWordIndex: state.maxWordIndex,
          isFullyHighlighted: state.isFullyHighlighted,
        );
      },
    );
    final String verseTitle = title ?? _buildVerseTitle(controller);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 800;
        final bool needsScrollableMeasure = !constraints.maxHeight.isFinite;
        final double viewportHeightForMeasure = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.vertical -
                      220)
                  .clamp(240, double.infinity);

        final TextPainter titlePainter = TextPainter(
          text: TextSpan(
            text: verseTitle,
            style: TextStyle(
              color: controller.globals.txtColor.withValues(alpha: 0.75),
            ),
          ),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width);
        final double titleHeight = showTitle ? titlePainter.height + 10 : 0;
        final double fallbackCanvasHeight = math.max(
          120,
          viewportHeightForMeasure - titleHeight,
        );
        final double requiredCanvasHeight = needsScrollableMeasure
            ? painter.measureRequiredHeight(Size(width, fallbackCanvasHeight))
            : fallbackCanvasHeight;
        final double scrollCanvasHeight = math.max(
          fallbackCanvasHeight,
          requiredCanvasHeight,
        );

        return _SwipePagingPreview(
          controller: controller,
          onTap: onPreviewTap,
          onLongPress: onPreviewLongPress,
          enableZoom: false,
          child: constraints.maxHeight.isFinite
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (showTitle) ...<Widget>[
                      Text(
                        verseTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: controller.globals.txtColor.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Expanded(
                      child: SizedBox(
                        width: width,
                        child: ClipRect(child: CustomPaint(painter: painter)),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (showTitle) ...<Widget>[
                      Text(
                        verseTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: controller.globals.txtColor.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: width,
                      height: scrollCanvasHeight,
                      child: ClipRect(
                        child: CustomPaint(
                          size: Size(width, scrollCanvasHeight),
                          painter: painter,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _buildVerseTitle(DiatarMainController controller) {
    final DtxBook? book = controller.currentBook;
    final DtxSong? song = controller.currentSong;
    final DtxVerse? verse = controller.currentVerse;
    if (book == null) return verse?.name ?? '';

    final String bookShortName = book.nick.trim().isNotEmpty
        ? book.nick
        : book.title;
    final String songTitle = (song?.title ?? '').trim().isNotEmpty
        ? song!.title.trim()
        : (controller.songIndex + 1).toString();
    final String verseName = verse?.name.trim() ?? '';
    final bool hideVersePart = verseName.isEmpty;
    final String versePart = hideVersePart ? '' : '/$verseName';

    return '$bookShortName: $songTitle$versePart';
  }
}

class _CustomTextPreview extends StatelessWidget {
  const _CustomTextPreview({
    required this.controller,
    required this.title,
    required this.lines,
    required this.onPreviewTap,
    this.onPreviewLongPress,
  });

  final DiatarMainController controller;
  final String title;
  final List<String> lines;
  final VoidCallback onPreviewTap;
  final VoidCallback? onPreviewLongPress;

  @override
  Widget build(BuildContext context) {
    final bool showTitle = controller.settings.projUseTitle;
    final RecTextRecord previewRecord = RecTextRecord(
      scholaLine: '',
      title: '',
      lines: lines.isEmpty ? const <String>[''] : lines,
    );
    final ProjectionFrame frame = TextFrame(record: previewRecord);
    final ProjectionGlobals globals = controller.globals.copyWith(
      projecting: true,
      wordToHighlight: controller.highPos,
    );
    final ProjectorPainter painter = ProjectorPainter(
      frame: frame,
      globals: globals,
      settings: controller.settings,
      logoTitle: context.l10n.appTitle,
      onHighlightRenderState: (HighlightRenderState state) {
        controller.updateHighlightRenderState(
          maxWordIndex: state.maxWordIndex,
          isFullyHighlighted: state.isFullyHighlighted,
        );
      },
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 800;
        final bool needsScrollableMeasure = !constraints.maxHeight.isFinite;
        final String fullTitle = title;
        final TextStyle titleStyle = TextStyle(
          color: controller.globals.txtColor.withValues(alpha: 0.75),
        );
        final TextPainter titlePainter = TextPainter(
          text: TextSpan(text: fullTitle, style: titleStyle),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width);
        final double titleHeight = showTitle ? titlePainter.height + 10 : 0;
        final double viewportHeightForMeasure = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.vertical -
                      220)
                  .clamp(240, double.infinity);
        final double fallbackCanvasHeight = math.max(
          120,
          viewportHeightForMeasure - titleHeight,
        );
        final double requiredCanvasHeight = needsScrollableMeasure
            ? painter.measureRequiredHeight(Size(width, fallbackCanvasHeight))
            : fallbackCanvasHeight;
        final double scrollCanvasHeight = math.max(
          fallbackCanvasHeight,
          requiredCanvasHeight,
        );

        return _SwipePagingPreview(
          controller: controller,
          onTap: onPreviewTap,
          onLongPress: onPreviewLongPress,
          enableZoom: false,
          child: constraints.maxHeight.isFinite
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (showTitle) ...<Widget>[
                      Text(
                        fullTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 10),
                    ],
                    Expanded(
                      child: SizedBox(
                        width: width,
                        child: ClipRect(child: CustomPaint(painter: painter)),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (showTitle) ...<Widget>[
                      Text(
                        fullTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: width,
                      height: scrollCanvasHeight,
                      child: ClipRect(
                        child: CustomPaint(
                          size: Size(width, scrollCanvasHeight),
                          painter: painter,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// Platform-fuggetlen kepfajl-megjelenito. A dart:io helyett a
/// FileSystemProvider altal biztositott (weben MemoryFileSystem) fajlrendszert
/// hasznalja, igy weben sem dob "Unsupported operation _Namespace" hibat.
class _FileImageWidget extends StatefulWidget {
  const _FileImageWidget({required this.path, required this.notFoundLabel});

  final String path;
  final String notFoundLabel;

  @override
  State<_FileImageWidget> createState() => _FileImageWidgetState();
}

class _FileImageWidgetState extends State<_FileImageWidget> {
  late Future<Uint8List?> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _loadBytes();
  }

  @override
  void didUpdateWidget(_FileImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bytesFuture = _loadBytes();
    }
  }

  Future<Uint8List?> _loadBytes() async {
    final String path = widget.path.trim();
    if (path.isEmpty) {
      return null;
    }
    try {
      final file = FileSystemProvider.instance.file(path);
      if (!await file.exists()) {
        return null;
      }
      final List<int> data = await file.readAsBytes();
      if (data.isEmpty) {
        return null;
      }
      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytesFuture,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final Uint8List? bytes = snapshot.data;
        if (bytes == null) {
          return Align(
            alignment: Alignment.topLeft,
            child: Text(context.l10n.statusImageNotFound(widget.notFoundLabel)),
          );
        }
        return Image.memory(bytes, fit: BoxFit.contain);
      },
    );
  }
}

class _PhotoPreviewWithFallback extends StatefulWidget {
  const _PhotoPreviewWithFallback({
    required this.photoPath,
    required this.notFoundLabel,
    required this.fallback,
    required this.controller,
    required this.l10n,
    required this.onPreviewTap,
    this.onPreviewLongPress,
  });

  final String photoPath;
  final String notFoundLabel;
  final Widget fallback;
  final DiatarMainController controller;
  final AppLocalizations l10n;
  final VoidCallback onPreviewTap;
  final VoidCallback? onPreviewLongPress;

  @override
  State<_PhotoPreviewWithFallback> createState() =>
      _PhotoPreviewWithFallbackState();
}

class _PhotoPreviewWithFallbackState extends State<_PhotoPreviewWithFallback> {
  late Future<Uint8List?> _bytesFuture;
  bool _snackbarShown = false;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _loadBytes();
  }

  @override
  void didUpdateWidget(_PhotoPreviewWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath) {
      _bytesFuture = _loadBytes();
      _snackbarShown = false;
    }
  }

  Future<Uint8List?> _loadBytes() async {
    final String path = widget.photoPath.trim();
    if (path.isEmpty) {
      return null;
    }
    try {
      final file = FileSystemProvider.instance.file(path);
      if (!await file.exists()) {
        return null;
      }
      final List<int> data = await file.readAsBytes();
      if (data.isEmpty) {
        return null;
      }
      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytesFuture,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final Uint8List? bytes = snapshot.data;
        if (bytes != null) {
          _snackbarShown = false;
          final Widget image = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, fit: BoxFit.contain),
          );
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool bounded = constraints.maxHeight.isFinite;
              return _SwipePagingPreview(
                controller: widget.controller,
                onTap: widget.onPreviewTap,
                onLongPress: widget.onPreviewLongPress,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.l10n.controlPhotoViewPhoto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.controller.globals.txtColor.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (bounded)
                      Expanded(child: SizedBox.expand(child: image))
                    else
                      SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxWidth * 0.7,
                        child: image,
                      ),
                  ],
                ),
              );
            },
          );
        }
        if (!_snackbarShown) {
          _snackbarShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text(
                  widget.l10n.statusImageNotFound(widget.notFoundLabel),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }
        return widget.fallback;
      },
    );
  }
}

class _CustomImagePreview extends StatelessWidget {
  const _CustomImagePreview({
    required this.controller,
    required this.title,
    required this.imagePath,
    required this.onPreviewTap,
    this.onPreviewLongPress,
  });

  final DiatarMainController controller;
  final String title;
  final String imagePath;
  final VoidCallback onPreviewTap;
  final VoidCallback? onPreviewLongPress;

  @override
  Widget build(BuildContext context) {
    final bool showTitle = controller.settings.projUseTitle;
    final String normalized = imagePath.trim();
    final String friendlyPath = normalized.isEmpty
        ? ''
        : formatFriendlyPathLabel(normalized, context.l10n);

    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _FileImageWidget(path: normalized, notFoundLabel: friendlyPath),
    );

    final TextStyle titleStyle = TextStyle(
      color: controller.globals.txtColor.withValues(alpha: 0.75),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool bounded = constraints.maxHeight.isFinite;
        return _SwipePagingPreview(
          controller: controller,
          onTap: onPreviewTap,
          onLongPress: onPreviewLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showTitle) ...<Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                const SizedBox(height: 10),
              ],
              if (bounded)
                Expanded(child: SizedBox.expand(child: image))
              else
                SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth * 0.7,
                  child: image,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SwipePagingPreview extends StatefulWidget {
  const _SwipePagingPreview({
    required this.controller,
    required this.child,
    this.enableZoom = true,
    this.onTap,
    this.onLongPress,
  });

  final DiatarMainController controller;
  final Widget child;
  final bool enableZoom;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<_SwipePagingPreview> createState() => _SwipePagingPreviewState();
}

class _SwipePagingPreviewState extends State<_SwipePagingPreview>
    with SingleTickerProviderStateMixin {
  static const Duration _settleDuration = Duration(milliseconds: 180);
  static const double _zoomEpsilon = 0.01;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimatingPageTurn = false;
  bool _isZoomed = false;
  int _activePointerCount = 0;
  int? _dragPointer;
  Offset? _dragStartPosition;
  late final AnimationController _pageTurnController;
  late final TransformationController _zoomController;
  Animation<Offset>? _pageTurnAnimation;

  @override
  void initState() {
    super.initState();
    _zoomController = TransformationController()
      ..addListener(_handleZoomTransformChanged);
    _pageTurnController =
        AnimationController(vsync: this, duration: _settleDuration)
          ..addListener(() {
            final Animation<Offset>? animation = _pageTurnAnimation;
            if (animation == null) {
              return;
            }
            setState(() {
              _dragOffset = animation.value;
            });
          });
  }

  @override
  void dispose() {
    _zoomController
      ..removeListener(_handleZoomTransformChanged)
      ..dispose();
    _pageTurnController.dispose();
    super.dispose();
  }

  void _handleZoomTransformChanged() {
    final double scale = _zoomController.value.getMaxScaleOnAxis();
    final bool nextZoomed = scale > (1.0 + _zoomEpsilon);
    if (nextZoomed == _isZoomed) {
      return;
    }
    setState(() {
      _isZoomed = nextZoomed;
      if (_isZoomed) {
        _isDragging = false;
        _dragOffset = Offset.zero;
      }
    });
  }

  void _resetZoom() {
    if (_zoomController.value == Matrix4.identity()) {
      return;
    }
    _zoomController.value = Matrix4.identity();
  }

  bool _isDesktopPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
  }

  void _resetDrag() {
    if (!mounted) return;
    if (_dragOffset == Offset.zero && !_isDragging) {
      return;
    }
    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  void _clearPointerTracking() {
    _dragPointer = null;
    _dragStartPosition = null;
    _isDragging = false;
  }

  void _startDrag() {
    if (!mounted) return;
    if (_isAnimatingPageTurn) {
      return;
    }
    _pageTurnController.stop();
    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = true;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerCount += 1;
    if (_isZoomed || _isAnimatingPageTurn || _activePointerCount != 1) {
      _clearPointerTracking();
      return;
    }
    _dragPointer = event.pointer;
    _dragStartPosition = event.position;
    _startDrag();
  }

  void _handlePointerMove(
    PointerMoveEvent event, {
    required double maxDrag,
    required double maxVerticalDrag,
  }) {
    if (_isZoomed || _isAnimatingPageTurn || _activePointerCount != 1) {
      return;
    }
    if (_dragPointer != event.pointer) {
      return;
    }
    final Offset? start = _dragStartPosition;
    if (start == null) {
      return;
    }

    final Offset totalDelta = event.position - start;
    final bool horizontalDominant = totalDelta.dx.abs() >= totalDelta.dy.abs();
    if (horizontalDominant) {
      _updateDrag(Offset(totalDelta.dx.clamp(-maxDrag, maxDrag).toDouble(), 0));
      return;
    }
    _updateDrag(
      Offset(
        0,
        totalDelta.dy.clamp(-maxVerticalDrag, maxVerticalDrag).toDouble(),
      ),
    );
  }

  void _handlePointerUpOrCancel(
    PointerEvent event, {
    required double distanceThreshold,
    required double verticalDistanceThreshold,
    required double turnTargetX,
    required double turnTargetY,
  }) {
    _activePointerCount = math.max(0, _activePointerCount - 1);

    if (_dragPointer != event.pointer) {
      if (_activePointerCount == 0) {
        _clearPointerTracking();
        _resetDrag();
      }
      return;
    }

    final Offset currentOffset = _dragOffset;
    _clearPointerTracking();

    if (_isZoomed || _isAnimatingPageTurn) {
      _resetDrag();
      return;
    }

    final bool horizontalDominant =
        currentOffset.dx.abs() >= currentOffset.dy.abs();
    if (horizontalDominant) {
      if (currentOffset.dx > distanceThreshold) {
        unawaited(
          _animatePageTurn(Offset(turnTargetX, 0), widget.controller.prevVerse),
        );
      } else if (currentOffset.dx < -distanceThreshold) {
        unawaited(
          _animatePageTurn(
            Offset(-turnTargetX, 0),
            widget.controller.nextVerse,
          ),
        );
      } else {
        _resetDrag();
      }
      return;
    }

    if (currentOffset.dy > verticalDistanceThreshold) {
      unawaited(
        _animatePageTurn(Offset(0, turnTargetY), widget.controller.prevSong),
      );
    } else if (currentOffset.dy < -verticalDistanceThreshold) {
      unawaited(
        _animatePageTurn(Offset(0, -turnTargetY), widget.controller.nextSong),
      );
    } else {
      _resetDrag();
    }
  }

  void _updateDrag(Offset nextOffset) {
    if (!mounted) return;
    if (_isAnimatingPageTurn) {
      return;
    }
    setState(() {
      _dragOffset = nextOffset;
    });
  }

  Future<void> _animateOffset(Offset begin, Offset end) async {
    _pageTurnAnimation = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _pageTurnController, curve: Curves.easeOutCubic),
    );
    _pageTurnController
      ..value = 0
      ..duration = _settleDuration;
    await _pageTurnController.forward().orCancel;
  }

  Future<void> _animatePageTurn(
    Offset targetOffset,
    VoidCallback pageAction,
  ) async {
    if (_isAnimatingPageTurn) {
      return;
    }

    setState(() {
      _isDragging = false;
      _isAnimatingPageTurn = true;
    });

    try {
      await _animateOffset(_dragOffset, targetOffset);
      if (!mounted) {
        return;
      }

      pageAction();

      if (!mounted) {
        return;
      }

      setState(() {
        _dragOffset = Offset(-targetOffset.dx, -targetOffset.dy);
      });

      await _animateOffset(_dragOffset, Offset.zero);
    } on TickerCanceled {
      return;
    } finally {
      if (mounted) {
        setState(() {
          _dragOffset = Offset.zero;
          _isAnimatingPageTurn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TargetPlatform platform = Theme.of(context).platform;
        final bool desktopLike = _isDesktopPlatform(platform);
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final double maxDrag = width * (desktopLike ? 0.30 : 0.40);
        final double distanceThreshold = width * (desktopLike ? 0.20 : 0.14);
        final double turnTargetX = width * 0.92;

        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;
        final double maxVerticalDrag = height * (desktopLike ? 0.30 : 0.38);
        final double verticalDistanceThreshold =
            height * (desktopLike ? 0.17 : 0.13);
        final double turnTargetY = height * 0.90;

        return IgnorePointer(
          ignoring: _isAnimatingPageTurn,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _handlePointerDown,
            onPointerMove: (PointerMoveEvent event) {
              _handlePointerMove(
                event,
                maxDrag: maxDrag,
                maxVerticalDrag: maxVerticalDrag,
              );
            },
            onPointerUp: (PointerUpEvent event) {
              _handlePointerUpOrCancel(
                event,
                distanceThreshold: distanceThreshold,
                verticalDistanceThreshold: verticalDistanceThreshold,
                turnTargetX: turnTargetX,
                turnTargetY: turnTargetY,
              );
            },
            onPointerCancel: (PointerCancelEvent event) {
              _handlePointerUpOrCancel(
                event,
                distanceThreshold: distanceThreshold,
                verticalDistanceThreshold: verticalDistanceThreshold,
                turnTargetX: turnTargetX,
                turnTargetY: turnTargetY,
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isZoomed
                  ? null
                  : (widget.onTap ?? widget.controller.toggleShowing),
              onDoubleTap: (widget.enableZoom && _isZoomed) ? _resetZoom : null,
              onLongPress: _isZoomed ? null : widget.onLongPress,
              child: ClipRect(
                child: Transform.translate(
                  offset: _dragOffset,
                  child: InteractiveViewer(
                    transformationController: _zoomController,
                    minScale: 1.0,
                    maxScale: 4.0,
                    panEnabled: _isZoomed,
                    scaleEnabled: widget.enableZoom,
                    boundaryMargin: const EdgeInsets.all(120),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _actionIconButton(
  BuildContext context, {
  IconData? icon,
  Widget? child,
  required String tooltip,
  required VoidCallback onPressed,
  Color? backgroundColor,
  Color? foregroundColor,
  bool selected = false,
}) {
  assert(icon != null || child != null, 'Either icon or child must be set.');
  final ColorScheme colors = Theme.of(context).colorScheme;
  return Tooltip(
    message: tooltip,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(7),
        minimumSize: const Size(44, 44),
        side: BorderSide(
          color:
              foregroundColor ?? (selected ? colors.onPrimary : colors.outline),
          width: 2.0,
        ),
        backgroundColor:
            backgroundColor ??
            (selected ? colors.primary.withValues(alpha: 0.14) : null),
        foregroundColor:
            foregroundColor ?? (selected ? colors.onPrimary : null),
      ),
      child: child ?? Icon(icon!, size: 22),
    ),
  );
}

class _ModelDownloadDialog extends StatefulWidget {
  final ModelManager modelManager;
  final SpeechModelType modelType;
  final AppLocalizations l10n;

  const _ModelDownloadDialog({
    required this.modelManager,
    required this.modelType,
    required this.l10n,
  });

  @override
  State<_ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<_ModelDownloadDialog> {
  double _progress = 0;
  bool _downloading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await widget.modelManager.downloadModel(
        widget.modelType,
        onProgress: (double p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) {
        setState(() => _downloading = false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.liveSubtitlesDownloading),
      content: _error != null
          ? Text('${widget.l10n.liveSubtitlesError}: $_error')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                ),
                const SizedBox(height: 12),
                Text('${(_progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
      actions: <Widget>[
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
      ],
    );
  }
}

class _VadDownloadDialog extends StatefulWidget {
  final ModelManager modelManager;
  final AppLocalizations l10n;

  const _VadDownloadDialog({required this.modelManager, required this.l10n});

  @override
  State<_VadDownloadDialog> createState() => _VadDownloadDialogState();
}

class _VadDownloadDialogState extends State<_VadDownloadDialog> {
  double _progress = 0;
  bool _downloading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await widget.modelManager.downloadVadModel(
        onProgress: (double p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) {
        setState(() => _downloading = false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.vadDownloading),
      content: _error != null
          ? Text('${widget.l10n.liveSubtitlesError}: $_error')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                ),
                const SizedBox(height: 12),
                Text('${(_progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
      actions: <Widget>[
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
      ],
    );
  }
}
