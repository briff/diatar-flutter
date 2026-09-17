// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Diatar';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get playlistsTooltip => 'Playlists';

  @override
  String get playlistsTitle => 'Playlists';

  @override
  String get customOrderTooltip => 'Editor';

  @override
  String get zsolozsmaTooltip => 'Liturgy of the Hours';

  @override
  String get zsolozsmaTitle => 'Select Liturgy of the Hours';

  @override
  String get zsolozsmaDateLabel => 'Date';

  @override
  String get zsolozsmaPickDate => 'Pick date';

  @override
  String get zsolozsmaSyncButton => 'Sync yearly ZIPs';

  @override
  String get zsolozsmaNoItems => 'No dayparts are available for this date.';

  @override
  String get zsolozsmaDiagnosticsLabel => 'Diagnostics';

  @override
  String get zsolozsmaSelectionHint =>
      'Selection currently loads and picks an item only. Slide splitting comes in the next step.';

  @override
  String get batyuTooltip => 'Daily readings (in Hungarian)';

  @override
  String get batyuTitle => 'Import Daily readings (in Hungarian)';

  @override
  String get batyuDateLabel => 'Date';

  @override
  String get batyuWordsPerSlide => 'Words per slide';

  @override
  String get batyuNoItems => 'No readings are available for this date.';

  @override
  String batyuBookLabel(Object name) {
    return 'Daily reading ($name)';
  }

  @override
  String get addSlideTooltip => 'Add slide';

  @override
  String get addTextSlide => 'Text slide';

  @override
  String get addImageSlide => 'Image slide';

  @override
  String get addImageSlideTooltip => 'Add image';

  @override
  String get downloadBooksTooltip => 'Download songbooks';

  @override
  String get downloadDtz => 'Download DTZ';

  @override
  String get downloadDtzTitle => 'Download DTX scores (DTZ)';

  @override
  String get downloadDtzHint =>
      'Select the DTZ files to download and the related images (zip).';

  @override
  String get downloadDtzWithImages => 'Images (zip) too';

  @override
  String downloadDtzCount(int count) {
    return '$count selected';
  }

  @override
  String get downloadDtzNoItems => 'No downloadable DTZ files.';

  @override
  String get downloadTabDtx => 'Volumes';

  @override
  String get downloadTabDtz => 'Scores';

  @override
  String get downloadTabMusic => 'Music';

  @override
  String get downloadTitle => 'Download';

  @override
  String get downloadManagerNameColumn => 'Volumes';

  @override
  String get downloadManagerUpdateColumn => 'Update';

  @override
  String get downloadManagerExcludedColumn => 'Excluded';

  @override
  String get downloadManagerUserImportedTag => 'User imported';

  @override
  String get downloadManagerUpdateAvailable => 'Update available';

  @override
  String get downloadManagerUpToDate => 'Up to date';

  @override
  String get downloadUserImportedGroup => 'User';

  @override
  String get downloadMessage => 'The download dialog can be restored later.';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get ok => 'OK';

  @override
  String get songPrev => 'Song -';

  @override
  String get songNext => 'Song +';

  @override
  String get projectionOn => 'Projection ON';

  @override
  String get projectionOff => 'Projection OFF';

  @override
  String get hideControlWindow => 'Hide control window';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get highlightPrev => 'Word highlight ←';

  @override
  String get highlightNext => 'Word highlight →';

  @override
  String positionLabel(int current, int total) {
    return 'Position: $current/$total';
  }

  @override
  String statusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String get statusStarting => 'Starting...';

  @override
  String statusSenderError(Object message) {
    return '$message';
  }

  @override
  String statusSenderTcpError(Object error) {
    return 'TCP error: $error';
  }

  @override
  String statusSenderOpenPortFailed(int port, Object error) {
    return 'Failed to open port ($port): $error';
  }

  @override
  String get statusSenderMqttConnectFailed => 'MQTT sender connection failed.';

  @override
  String statusSenderMqttError(Object error) {
    return 'MQTT sender error: $error';
  }

  @override
  String statusMqttSending(Object user, Object channel) {
    return 'MQTT send: $user/$channel';
  }

  @override
  String statusTcpSending(int port) {
    return 'TCP send: $port';
  }

  @override
  String statusNoDtxFiles(Object path) {
    return 'No .dtx files: $path';
  }

  @override
  String get statusAllSongbooksDisabled =>
      'All songbooks are disabled in order settings.';

  @override
  String statusSongbooksLoaded(int count) {
    return '$count songbooks loaded';
  }

  @override
  String statusLoadError(Object error) {
    return 'Load error: $error';
  }

  @override
  String statusCustomOrderSelected(Object label) {
    return 'Custom order: $label';
  }

  @override
  String statusOrderSaved(Object path) {
    return 'Order saved: $path';
  }

  @override
  String statusDiaFileMissing(Object path) {
    return 'No such .DIA file: $path';
  }

  @override
  String statusOrderLoaded(int count, Object path) {
    return 'Order loaded ($count items): $path';
  }

  @override
  String get statusDownloadListLoading => 'Loading songbook update list...';

  @override
  String statusDownloadProgress(
    int current,
    int total,
    Object name,
    int percent,
  ) {
    return 'Download: $current/$total $name $percent%';
  }

  @override
  String get statusDownloadSummaryNone => 'No new songbook updates.';

  @override
  String statusDownloadSummary(int downloaded, int skipped) {
    return '$downloaded files downloaded, $skipped unchanged.';
  }

  @override
  String statusDownloadError(Object error) {
    return 'Download error: $error';
  }

  @override
  String statusZsolozsmaSyncOk(int downloaded, int failed) {
    return 'Zsolozsma ZIP sync: $downloaded downloaded, $failed failed.';
  }

  @override
  String statusZsolozsmaSyncError(Object error) {
    return 'Zsolozsma ZIP sync error: $error';
  }

  @override
  String statusZsolozsmaDayLoaded(int count, Object date) {
    return 'Zsolozsma list loaded ($count) - $date';
  }

  @override
  String statusZsolozsmaDayEmpty(Object date) {
    return 'No zsolozsma list for this date: $date';
  }

  @override
  String statusZsolozsmaDayError(Object error) {
    return 'Zsolozsma list error: $error';
  }

  @override
  String statusZsolozsmaPartSelected(Object date, Object title) {
    return 'Zsolozsma selected ($date): $title';
  }

  @override
  String statusZsolozsmaPartLoaded(int count, Object date, Object title) {
    return 'Zsolozsma loaded ($count slides) - $date: $title';
  }

  @override
  String statusZsolozsmaPartLoadError(Object title) {
    return 'Failed to load selected zsolozsma part: $title';
  }

  @override
  String statusBookSelected(Object name) {
    return 'Book: $name';
  }

  @override
  String statusSongPicked(Object name) {
    return 'Song: $name';
  }

  @override
  String statusVersePicked(Object name) {
    return 'Verse: $name';
  }

  @override
  String statusSongSelected(Object title) {
    return 'Song: $title';
  }

  @override
  String statusSongVerseSelected(Object title) {
    return 'Song/verse: $title';
  }

  @override
  String get statusProjectionOn => 'Projection: ON';

  @override
  String get statusProjectionOff => 'Projection: OFF';

  @override
  String get statusImagePathEmpty => 'Image file path is empty.';

  @override
  String get statusCustomTextEmpty => 'Provide a title or at least one line.';

  @override
  String statusCustomTextSent(Object title) {
    return 'Text slide sent: $title';
  }

  @override
  String statusCustomTextError(Object error) {
    return 'Text slide send error: $error';
  }

  @override
  String statusImageNotFound(Object path) {
    return 'Image file not found: $path';
  }

  @override
  String statusImageSent(Object name) {
    return 'Image sent: $name';
  }

  @override
  String statusImageSendError(Object error) {
    return 'Image send error: $error';
  }

  @override
  String get statusBlankPathEmpty => 'Background image file path is empty.';

  @override
  String statusBlankNotFound(Object path) {
    return 'Background image file not found: $path';
  }

  @override
  String statusBlankSet(Object name) {
    return 'Background image set: $name';
  }

  @override
  String statusBlankSendError(Object error) {
    return 'Background image send error: $error';
  }

  @override
  String get statusBlankCleared => 'Background image cleared.';

  @override
  String statusBlankClearError(Object error) {
    return 'Background image clear error: $error';
  }

  @override
  String get statusShutdownCommandSent => 'Shutdown command sent.';

  @override
  String get statusStopCommandSent => 'Stop command sent.';

  @override
  String statusCommandSendError(Object error) {
    return 'Command send error: $error';
  }

  @override
  String sendStatusLabel(
    Object protocol,
    Object senderState,
    Object clientState,
  ) {
    return 'Sender ($protocol): $senderState, client: $clientState';
  }

  @override
  String get protocolMqtt => 'MQTT';

  @override
  String get protocolTcp => 'TCP';

  @override
  String get senderStateActive => 'active';

  @override
  String get senderStateOff => 'off';

  @override
  String get clientStateConnected => 'connected';

  @override
  String get clientStateWaiting => 'waiting';

  @override
  String tcpPortLabel(int port) {
    return 'TCP port: $port';
  }

  @override
  String downloadProgress(int current, int total, Object name) {
    return 'Download: $current/$total $name';
  }

  @override
  String get noLoadedSlide => 'No slide loaded.';

  @override
  String get homeControlModeTooltip => 'Screen mode';

  @override
  String get homeControlModeBooks => 'Books';

  @override
  String get homeControlModeDialist => 'Slide list';

  @override
  String get homeControlModePresentation => 'Presentation';

  @override
  String dialistNamedLabel(Object name) {
    return 'Slide list: $name';
  }

  @override
  String get bookLabel => 'Book';

  @override
  String get ungroupedBookGroupLabel => '(unclassified)';

  @override
  String diaBookLabel(Object name) {
    return 'DIA: $name';
  }

  @override
  String zsolozsmaBookLabel(Object name) {
    return 'Liturgy: $name';
  }

  @override
  String get songLabel => 'Song';

  @override
  String get verseLabel => 'Verse';

  @override
  String versePanelTitle(Object title, Object verse) {
    return '$title: $verse';
  }

  @override
  String get searchLabel => 'Slide search';

  @override
  String get searchHint => 'Book, song title or lyric';

  @override
  String get searchHintOrderEdit => 'Song number';

  @override
  String get noResults => 'No results.';

  @override
  String customOrderStatus(Object state) {
    return 'Custom order: $state';
  }

  @override
  String get stateActive => 'Active';

  @override
  String get stateInactive => 'Inactive';

  @override
  String get nextShort => 'Next';

  @override
  String get previewTitle => 'Slide preview';

  @override
  String get previewResizeInProgress => 'Resizing preview...';

  @override
  String customTextEntryLabel(Object name) {
    return 'Slide: $name';
  }

  @override
  String customImageEntryLabel(Object name) {
    return 'Image: $name';
  }

  @override
  String get projectedImage => 'Projected image:';

  @override
  String get settingsTitle => 'Diatar settings';

  @override
  String get settingsTitleReceiver => 'Settings';

  @override
  String settingsVersionLabel(Object version, Object buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get modeIp => 'IP';

  @override
  String get modeInternet => 'Internet';

  @override
  String get senderLabel => 'Sender';

  @override
  String get senderHelper => 'MQTT sender name';

  @override
  String get senderRefreshTooltip => 'Refresh sender list';

  @override
  String get channelLabel => 'Channel';

  @override
  String get clipLeft => 'Left';

  @override
  String get clipTop => 'Top';

  @override
  String get clipRight => 'Right';

  @override
  String get clipBottom => 'Bottom';

  @override
  String get borderToClip => 'Margins from controller (Border2Clip)';

  @override
  String get mirror => 'Mirror';

  @override
  String get autoBootIndicator => 'Auto start (indicator)';

  @override
  String get rotationLabel => 'Rotation';

  @override
  String get tcpPortRange => 'TCP port (0..65535)';

  @override
  String get mqttUserHint => 'MQTT user (empty = TCP mode)';

  @override
  String get mqttPassword => 'MQTT password';

  @override
  String get mqttChannel => 'MQTT channel';

  @override
  String get internetRelayQrButton => 'QR code';

  @override
  String get internetRelayQrTitle => 'DiaVetito QR code';

  @override
  String get internetRelayQrHint =>
      'Scan this QR code to quickly open the web DiaVetito receiver.';

  @override
  String get internetRelayLinkLabel => 'Open link';

  @override
  String get internetRelayCopyLink => 'Copy link';

  @override
  String get internetRelayLinkCopied => 'Link copied to clipboard';

  @override
  String get internetRelaySaveQrImage => 'Save QR as PNG';

  @override
  String internetRelayQrSaved(Object fileName) {
    return 'QR image saved: $fileName';
  }

  @override
  String internetRelayQrSaveFailed(Object error) {
    return 'Failed to save QR image: $error';
  }

  @override
  String get uiTheme => 'User interface theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get blankImagePath => 'Background image path';

  @override
  String get diaExportFolderPath => 'DIA export folder';

  @override
  String get fileChoose => 'Choose file';

  @override
  String get blankImageDelete => 'Delete background image';

  @override
  String get openDtxFolder => 'Open Diatár files';

  @override
  String get openDtxFolderTooltip =>
      'Open the folder containing the Diatár files';

  @override
  String get copyPathTooltip => 'Copy original path';

  @override
  String get pathCopied => 'Original path copied';

  @override
  String get pathLabelInternalStorage => 'Internal storage';

  @override
  String get pathSegmentDocuments => 'Documents';

  @override
  String get pathSegmentDownloads => 'Downloads';

  @override
  String get pathSegmentCamera => 'Camera';

  @override
  String get pathSegmentPictures => 'Pictures';

  @override
  String get pathSegmentMusic => 'Music';

  @override
  String get pathSegmentMovies => 'Movies';

  @override
  String get uiLanguage => 'User interface language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageHungarian => 'Hungarian';

  @override
  String get languageEnglish => 'English';

  @override
  String get projectionSettingsTitle => 'Projection settings';

  @override
  String get fontSize => 'Font size';

  @override
  String get titleSize => 'Title size';

  @override
  String get leftMargin => 'Indentation';

  @override
  String get borderLeft => 'Border L';

  @override
  String get borderTop => 'Border T';

  @override
  String get borderRight => 'Border R';

  @override
  String get borderBottom => 'Border B';

  @override
  String get lineSpacing => 'Line spacing';

  @override
  String get kottaScale => 'Music notation scale';

  @override
  String get chordScale => 'Chord scale';

  @override
  String get backgroundMode => 'Background image mode';

  @override
  String get bgModeCenter => 'Center';

  @override
  String get bgModeZoom => 'Zoom';

  @override
  String get bgModeFull => 'Full';

  @override
  String get bgModeCascade => 'Cascade';

  @override
  String get bgModeMirror => 'Mirror';

  @override
  String get backgroundOpacity => 'Background opacity';

  @override
  String get blankOpacity => 'Background image opacity';

  @override
  String get autoSize => 'Auto sizing';

  @override
  String get showTitle => 'Show title';

  @override
  String get projectionLock => 'Lock projection';

  @override
  String get projectionUnlock => 'Unlock projection';

  @override
  String get hCenter => 'Horizontal center align';

  @override
  String get vCenter => 'Vertical center align';

  @override
  String get showChords => 'Show chords';

  @override
  String get showKotta => 'Show notation';

  @override
  String get showBackgroundImage => 'Show background image';

  @override
  String get wordHighlight => 'Word highlight';

  @override
  String get boldText => 'Bold text';

  @override
  String get italicText => 'Italic text';

  @override
  String get underlineText => 'Underline text';

  @override
  String get strikethroughText => 'Strikethrough text';

  @override
  String get insertSpecialCharacter => 'Insert special character';

  @override
  String get conditionalHyphen => 'Conditional hyphen';

  @override
  String get nonBreakingSpace => 'Non-breaking space';

  @override
  String get nonBreakingHyphen => 'Non-breaking hyphen';

  @override
  String get preferredLineBreak => 'Preferred line break';

  @override
  String get colorsTitle => 'Colors';

  @override
  String get backgroundColor => 'Background';

  @override
  String get textColor => 'Text';

  @override
  String get emptySlideColor => 'Empty slide';

  @override
  String get highlightColor => 'Highlight';

  @override
  String get backgroundColorTitle => 'Background color';

  @override
  String get textColorTitle => 'Text color';

  @override
  String get emptySlideColorTitle => 'Empty slide color';

  @override
  String get highlightColorTitle => 'Highlight color';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteFilesTooltip => 'Delete file';

  @override
  String confirmDeleteDtxFiles(Object name) {
    return 'Delete the songbook file “$name” from this device? This action cannot be undone.';
  }

  @override
  String confirmDeleteDtzFiles(Object name) {
    return 'Delete the projector file “$name” from this device? This action cannot be undone.';
  }

  @override
  String get save => 'Save';

  @override
  String get invalidPortRange => 'Port must be between 0 and 65535.';

  @override
  String get hexColorHint => 'Hex color (#AARRGGBB or #RRGGBB)';

  @override
  String get close => 'Close';

  @override
  String get imagesFileTypeLabel => 'images';

  @override
  String get diatarPlaylistFileTypeLabel => 'Diatar playlist';

  @override
  String get customOrderSuggestedFileName => 'order.dia';

  @override
  String get customOrderEditTitle => 'Editor';

  @override
  String customOrderEditTitleWithName(Object name) {
    return '$name - Editor';
  }

  @override
  String customOrderModifiedName(Object name) {
    return '✦ $name';
  }

  @override
  String get customOrderGroupReorder => 'Group reordering';

  @override
  String get customOrderPlaySoundTooltip => 'Play the slide\'s music';

  @override
  String get customOrderAdvanceAfterSoundTooltip =>
      'Advance when the music ends';

  @override
  String get customOrderSkipSlideTooltip => 'Skip this slide during projection';

  @override
  String get addSong => 'Add song';

  @override
  String get searchSongHint => 'Book, song title or lyric';

  @override
  String get customOrderInsertBookLabel => 'Book';

  @override
  String get customOrderInsertSongLabel => 'Song';

  @override
  String get customOrderInsertVersesAction => 'Insert verses';

  @override
  String get customOrderInsertSeparatorAction => 'Insert separator';

  @override
  String get customOrderClearAllTooltip => 'Clear all';

  @override
  String get customOrderClearAllConfirmTitle => 'Confirmation';

  @override
  String get customOrderClearAllConfirmMessage =>
      'Are you sure you want to delete the entire custom slide order?';

  @override
  String get customOrderClearAllConfirmButton => 'Clear all';

  @override
  String get customOrderSeparatorNameLabel => 'Separator name';

  @override
  String get customOrderSeparatorDefaultName => 'separator';

  @override
  String get customOrderEditSeparatorTitle => 'Edit separator';

  @override
  String get customOrderEditTextSlideTitle => 'Edit text slide';

  @override
  String get customOrderInsertVersesTitle => 'Verses to insert';

  @override
  String get customOrderInsertVersesSubtitle =>
      'Select which verses should be added to the order.';

  @override
  String get textSlideDialogTitle => 'Add text slide';

  @override
  String get textSlideTitleLabel => 'Title';

  @override
  String get textSlideBodyLabel => 'Text (one line per row)';

  @override
  String get textSlideDefaultTitle => 'Slide';

  @override
  String get loadDia => 'Load';

  @override
  String get saveDia => 'Save';

  @override
  String get customOrderSaveDiaErrorTitle => 'Save failed';

  @override
  String get customOrderSaveDiaPermissionDenied =>
      'Android could not write to the selected destination while saving the DIA file. Please try again and choose a different folder or file name in the system save dialog.';

  @override
  String customOrderSaveDiaGenericError(Object error) {
    return 'Could not save DIA file. Details: $error';
  }

  @override
  String get customOrderOverwriteSavedDiaTitle => 'Overwrite?';

  @override
  String customOrderOverwriteSavedDiaBody(Object fileName) {
    return 'A saved DIA file already exists: $fileName. What would you like to do?';
  }

  @override
  String get customOrderOverwriteSavedDiaOverwrite => 'Overwrite';

  @override
  String get customOrderOverwriteSavedDiaNewLocation => 'Choose new location';

  @override
  String get customOrderDiaFileNameLabel => 'File name';

  @override
  String get customOrderUnnamedFileName => 'Unnamed';

  @override
  String get customOrderDiaOverwriteTitle => 'Overwrite file';

  @override
  String customOrderDiaOverwriteMessage(Object name) {
    return 'The file \"$name\" already exists. Do you want to overwrite it?';
  }

  @override
  String savedPath(Object path) {
    return 'Saved: $path';
  }

  @override
  String loadedCount(int count) {
    return 'Loaded: $count items';
  }

  @override
  String get customOrderEmpty =>
      'The order is empty.\nSearch songs to edit it.';

  @override
  String get versePicker => 'Verse';

  @override
  String get selectedVersesTitle => 'Selected verses';

  @override
  String get selectedVersesSubtitle => 'You can select multiple.';

  @override
  String get customOrderSelectAllVerses => 'Select all';

  @override
  String get customOrderClearVerseSelection => 'Clear';

  @override
  String get customOrderSetsSection => 'Custom orders';

  @override
  String get customOrderSetSelectorLabel => 'Active custom order';

  @override
  String get customOrderSetActive => 'Active';

  @override
  String get customOrderSetEmpty => 'Empty custom order';

  @override
  String customOrderSetEntryCount(int count) {
    return '$count items';
  }

  @override
  String get customOrderSetRename => 'Rename';

  @override
  String get customOrderSetRemove => 'Remove';

  @override
  String get customOrderSetRenameTitle => 'Rename custom order';

  @override
  String get customOrderSetRemoveConfirm => 'Remove this custom order?';

  @override
  String customOrderSetRemoveHotkeyWarning(Object hotkey) {
    return 'This order set has a hotkey assigned ($hotkey). Remove the hotkey in Settings first.';
  }

  @override
  String get customOrderSetToggleEnabledTooltip =>
      'Enable or disable the custom order (a disabled one is hidden from the views)';

  @override
  String get customOrderSetCreate => 'New custom order';

  @override
  String get customOrderSetCreateTitle => 'Create new custom order';

  @override
  String get customOrderSetCreateNameLabel => 'Custom order name';

  @override
  String get customOrderLoadModeTitle => 'Load custom order';

  @override
  String get customOrderLoadModeOverwrite => 'Overwrite the current one';

  @override
  String get customOrderLoadModeAdd => 'Load alongside (parallel)';

  @override
  String get customOrderLoadModeMessage =>
      'How should the selected custom order be loaded?';

  @override
  String get volumeListTitle => 'Volume list';

  @override
  String get apply => 'Apply';

  @override
  String get internetUserActionsTitle => 'User actions (API)';

  @override
  String get internetStatusOn => 'On';

  @override
  String get internetStatusOff => 'Off';

  @override
  String get internetStatusConnecting => 'Connecting';

  @override
  String get internetStatusError => 'Error';

  @override
  String connectionStatusTooltip(Object name, Object status) {
    return '$name: $status';
  }

  @override
  String get valueNotSet => '-';

  @override
  String get tcpNoTargets => 'No targets';

  @override
  String tcpTargetsCount(int count) {
    return '$count targets';
  }

  @override
  String get settingsSearchLabel => 'Search in settings';

  @override
  String get settingsInternetTitle => 'Internet';

  @override
  String settingsInternetSubtitle(Object status, Object user) {
    return 'Internet relay: $status, user: $user';
  }

  @override
  String get settingsLocalNetworkTitle => 'Local network (TCP/IP)';

  @override
  String settingsLocalNetworkSubtitle(Object status, Object summary) {
    return 'TCP client: $status, targets: $summary';
  }

  @override
  String get settingsWolTitle => 'Wake on LAN';

  @override
  String settingsWolSubtitle(Object status, Object summary) {
    return 'Wake on LAN: $status, targets: $summary';
  }

  @override
  String get settingsWolDescription =>
      'Wake up target machines on your local network by sending a magic packet over UDP.';

  @override
  String get wolEnabledTitle => 'Enable Wake on LAN';

  @override
  String get wolEnabledHint =>
      'When enabled, a toolbar button lets you wake all target machines.';

  @override
  String get wolTargetsLabel => 'Target machines (MAC@IP[:port])';

  @override
  String get wolTargetsHint => 'AA:BB:CC:DD:EE:FF, one per line';

  @override
  String get wolTargetsHelp =>
      'A plain MAC address wakes the machine via the broadcast address below. Add @IP or @IP:port after the MAC to wake a single machine directly.';

  @override
  String get wolBroadcastLabel => 'Broadcast address';

  @override
  String get wolPortLabel => 'UDP port';

  @override
  String get wolNoTargets => 'Add at least one target machine.';

  @override
  String wolInvalidTarget(Object target) {
    return 'Invalid target: $target';
  }

  @override
  String get wolInvalidBroadcast =>
      'Invalid broadcast address. Use an IPv4 address such as 255.255.255.255.';

  @override
  String get wolInvalidPort => 'Invalid port. Use a value between 1 and 65535.';

  @override
  String get wolTooltip => 'Wake on LAN';

  @override
  String wolMessageSent(int count) {
    return 'Wake on LAN sent to $count machine(s).';
  }

  @override
  String wolMessageError(Object error) {
    return 'Wake on LAN failed: $error';
  }

  @override
  String settingsColorSummary(Object background, Object text) {
    return 'Background: $background, Text: $text';
  }

  @override
  String settingsProjectionSummary(Object font, Object title) {
    return 'Font: ${font}px, Title: ${title}px';
  }

  @override
  String get settingsFilesTitle => 'Songbooks and files';

  @override
  String settingsFilesSummary(Object blank) {
    return 'Background image: $blank';
  }

  @override
  String get importDtxFilesButton => 'Import from file';

  @override
  String get importDtzFilesButton => 'Import scores';

  @override
  String get importMusicFilesButton => 'Import music';

  @override
  String get importMusicNotImplemented =>
      'Music import is not implemented yet.';

  @override
  String get importDtzPreviewTitle => 'Import scores';

  @override
  String get importDtzDtzSection => 'DTZ file';

  @override
  String get importDtzZipSection => 'ZIP files (images, sounds)';

  @override
  String get importDtzNoDtzSelected => 'No DTZ file selected';

  @override
  String get importDtzSelectDtz => 'Select DTZ';

  @override
  String get importDtzAddZip => 'Add ZIP files';

  @override
  String get importDtzValidateButton => 'Validate';

  @override
  String get importDtzPreviewNoDtz =>
      'No .dtz file selected. Please select at least one DTZ file!';

  @override
  String importDtzPreviewOrphanZips(int count) {
    return '$count ZIP file(s) cannot be paired with a DTZ.';
  }

  @override
  String importDtzStatusOk(int matched) {
    return 'Importable – $matched media file(s) OK';
  }

  @override
  String get importDtzStatusNoRefs => 'Importable – no media files referenced';

  @override
  String importDtzStatusWarning(int missing, int total) {
    return 'Importable (with warning) – $missing/$total media file(s) missing';
  }

  @override
  String importDtzStatusError(int missing, int total) {
    return 'Not importable – $missing/$total media file(s) missing';
  }

  @override
  String get importDtzStatusParseError => 'Not importable – invalid DTZ file';

  @override
  String importDtzStatusMissingDiaIdsCount(int count) {
    return 'Unknown dia-ID(s) in DTZ: $count';
  }

  @override
  String get importDtzDetails => 'Details';

  @override
  String get importDtzMissingFilesTitle => 'Missing media files';

  @override
  String get importDtzMissingDiaIdsTitle => 'Unknown dia-IDs';

  @override
  String get importDtzConfirmErrorsTitle => 'Import faulty package';

  @override
  String importDtzConfirmErrorsBody(int count) {
    return '$count selected package(s) have errors (missing media files or unknown dia-IDs). Missing files will not be extracted. Import anyway?';
  }

  @override
  String get importDtzImportButton => 'Import';

  @override
  String importDtzSuccess(int dtz, int files) {
    return '$dtz DTZ file(s) imported, $files media file(s) extracted';
  }

  @override
  String importDtzSuccessNoMedia(int dtz) {
    return '$dtz DTZ file(s) imported';
  }

  @override
  String importDtzError(Object reason) {
    return 'Error importing score(s): $reason';
  }

  @override
  String get importDtzFailureDialogTitle => 'Score import problem';

  @override
  String get importDtzPartialImportTitle =>
      'Score import completed with problems';

  @override
  String get importDtzFailureSourceUnreadable =>
      'The selected ZIP file could not be read.';

  @override
  String get importDtzFailureInvalidArchive =>
      'The selected file is not a valid ZIP archive.';

  @override
  String get importDtzFailureTooManyEntries =>
      'The ZIP contains too many files.';

  @override
  String get importDtzFailureEntryTooLarge =>
      'The ZIP contains a file that is too large to import safely.';

  @override
  String get importDtzFailureTotalTooLarge =>
      'The ZIP would extract too much data to import safely.';

  @override
  String get importDtzFailureCancelled => 'The import was cancelled.';

  @override
  String get importDtzFailureEntryUnreadable =>
      'A file in the ZIP could not be extracted.';

  @override
  String get importDtzFailureWriteFailed =>
      'The extracted file could not be written. Check available storage.';

  @override
  String importDtzFailureDetails(Object zip, Object reason) {
    return '$zip: $reason';
  }

  @override
  String importDtzProgress(Object entry, int current, int total) {
    return 'Extracting $entry ($current/$total)';
  }

  @override
  String importDtxFilesSuccess(int count) {
    return '$count .dtx file(s) imported';
  }

  @override
  String get importDtxFilesError => 'Error importing .dtx file(s)';

  @override
  String importDtxFilesErrorDetailed(Object reason) {
    return 'Error importing .dtx file(s): $reason';
  }

  @override
  String importDtxFilesPartial(int count, int failed, Object reason) {
    return '$count .dtx file(s) imported, $failed failed: $reason';
  }

  @override
  String get settingsGeneralTitle => 'General';

  @override
  String settingsGeneralSummary(Object theme, Object language) {
    return 'Theme: $theme, Language: $language';
  }

  @override
  String get systemActionsTitle => 'System actions';

  @override
  String get systemActionsSummary =>
      'Exit, refresh, remote program stop, remote machine stop';

  @override
  String get systemActionsBack => 'Back';

  @override
  String get externalCommandsTitle => 'External commands';

  @override
  String get externalCommandsSummary =>
      'Run external actions for application and projection events';

  @override
  String get externalCommandsDescriptionDesktop =>
      'Configure shell commands that run on Windows and Linux when the application or projection state changes.';

  @override
  String get externalCommandsDescriptionAndroid =>
      'Configure URIs, deep links, Android intents or broadcasts that run when the application or projection state changes.';

  @override
  String get externalCommandsDescriptionIos =>
      'Configure URLs or deep links that open when the application or projection state changes.';

  @override
  String get externalCommandsHintDesktop =>
      'Leave a field empty to skip that event. Commands run through the operating system shell.';

  @override
  String get externalCommandsHintAndroid =>
      'Leave a field empty to skip that event. Enter a URI or deep link, an Android Intent URI, or prefix an Intent URI with \"broadcast:\" to send it as a broadcast. Intent URI extras are supported, for example: intent:#Intent;action=com.example.ACTION;S.name=value;i.count=1;end';

  @override
  String get externalCommandsHintIos =>
      'Leave a field empty to skip that event. Enter a URL or deep link handled by an installed app, for example: mycontroller://projection?state=on. Parameters can be passed in the URL query.';

  @override
  String get externalCommandOnStart => 'When the application starts';

  @override
  String get externalCommandOnExit => 'When the application exits';

  @override
  String get externalCommandOnProjectionOn => 'When projection turns on';

  @override
  String get externalCommandOnProjectionOff => 'When projection turns off';

  @override
  String get externalCommandClear => 'Clear command';

  @override
  String get externalCommandTest => 'Test';

  @override
  String get externalCommandTestStarted => 'Command started.';

  @override
  String get externalCommandTestSucceededTitle => 'Test successful';

  @override
  String get externalCommandTestFailedTitle => 'Test failed';

  @override
  String externalCommandTestFailed(Object error) {
    return 'Could not start command: $error';
  }

  @override
  String externalCommandTestExitCode(int code) {
    return 'The command exited with code $code.';
  }

  @override
  String get localExit => 'Exit';

  @override
  String get remoteProgramStop => 'Remote program stop';

  @override
  String get remoteMachineStop => 'Remote machine stop';

  @override
  String get settingsHotkeysTitle => 'Hotkeys';

  @override
  String get settingsHotkeysSummary =>
      'Controller actions and song assignment to keys';

  @override
  String get settingsDesktopHotkeysTitle => 'Hotkeys (desktop)';

  @override
  String get settingsHotkeysActionsSectionTitle => 'Controller actions';

  @override
  String get settingsHotkeysSongsSectionTitle => 'Song to hotkey';

  @override
  String get settingsHotkeysNoSongs =>
      'No songs loaded, so assignment is not available.';

  @override
  String get settingsHotkeyActionHint => 'e.g. Ctrl+Right or F8';

  @override
  String get settingsHotkeyFieldLabel => 'Hotkey';

  @override
  String get settingsHotkeySongHint => 'e.g. Ctrl+1 or F2';

  @override
  String get settingsHotkeyAssign => 'Assign';

  @override
  String get settingsHotkeyDelete => 'Delete';

  @override
  String get settingsHotkeyActionPrevSong => 'Previous song';

  @override
  String get settingsHotkeyActionPrevVerse => 'Previous verse';

  @override
  String get settingsHotkeyActionToggleProjection => 'Toggle projection';

  @override
  String get settingsHotkeyActionNextVerse => 'Next verse';

  @override
  String get settingsHotkeyActionNextSong => 'Next song';

  @override
  String get settingsHotkeyActionPrevOrderSet => 'Previous custom order';

  @override
  String get settingsHotkeyActionNextOrderSet => 'Next custom order';

  @override
  String get settingsHotkeyActionHighlightPrev => 'Highlight previous word';

  @override
  String get settingsHotkeyActionHighlightNext => 'Highlight next word';

  @override
  String get settingsHotkeyActionTogglePhoto => 'Toggle photo';

  @override
  String get settingsHotkeyActionToggleChords => 'Toggle chords';

  @override
  String get settingsHotkeyActionToggleBackground => 'Toggle background';

  @override
  String get settingsHotkeyActionToggleSheetMusic => 'Toggle sheet music';

  @override
  String get settingsHotkeyActionHomeBooks => 'Show books';

  @override
  String get settingsHotkeyActionHomeDialist => 'Show slide list';

  @override
  String get settingsHotkeyActionHomePresentation => 'Show presentation';

  @override
  String get settingsDesktopOrderSetHotkeysTitle => 'Order set hotkeys';

  @override
  String get settingsOrderSetLabel => 'Order set';

  @override
  String get settingsHotkeysNoOrderSets =>
      'No order sets loaded, so assignment is not available.';

  @override
  String get settingsHotkeysOrderSetExistingTitle => 'Existing bindings';

  @override
  String get settingsOrderSetPickerTitle => 'Select order set';

  @override
  String settingsHotkeyConflict(Object hotkey) {
    return 'Conflicting hotkey: $hotkey';
  }

  @override
  String get settingsNoResults => 'No results for the search.';

  @override
  String get internetRelaySwitchTitle => 'Internet relay';

  @override
  String get localNetworkRelaySwitchTitle => 'Local network (TCP/IP)';

  @override
  String get passwordHideTooltip => 'Hide';

  @override
  String get passwordShowTooltip => 'Show';

  @override
  String get tcpTargetsLabel => 'Targets (IP:port per line)';

  @override
  String get tcpTargetsHint => '192.168.1.50:1024\n192.168.1.51:1024';

  @override
  String get tcpTargetsHelp =>
      'The sender connects as a client to the addresses above.';

  @override
  String get projectionMarginsTitle => 'Margins';

  @override
  String get projectionMarginLeft => 'Left margin';

  @override
  String get projectionMarginRight => 'Right margin';

  @override
  String get projectionMarginTop => 'Top margin';

  @override
  String get projectionMarginBottom => 'Bottom margin';

  @override
  String get projectorMonitor => 'Projector display';

  @override
  String get projectorEnabled => 'Use projector window';

  @override
  String get projectorEnabledHint =>
      'Projects in a separate window on desktop. When off, the app acts only as a controller without a projector window.';

  @override
  String get cameraViewTitle => 'Cantor\'s Eye – Show camera view';

  @override
  String get cameraViewHint =>
      'Shows the camera feed from the projector device over the local network.';

  @override
  String get cameraSourceLabel => 'Camera source';

  @override
  String get cameraSourceHelp =>
      'Select which client\'s camera the view waits for. When only one target is listed, it is used automatically.';

  @override
  String get projectorMonitorAuto => 'Automatic (last display)';

  @override
  String projectorMonitorIndex(int index, Object size) {
    return 'Display $index ($size)';
  }

  @override
  String projectorMonitorIndexShort(int index) {
    return 'Display $index';
  }

  @override
  String tcpInvalidTargetFormat(Object target) {
    return 'Invalid target format: $target';
  }

  @override
  String get userActionRegister => 'Register';

  @override
  String get userActionResendVerification => 'Resend e-mail';

  @override
  String get userActionForgotPassword => 'Forgot password';

  @override
  String get userActionDeleteUser => 'Delete user';

  @override
  String get userActionChangePassword => 'Change password';

  @override
  String get userActionChangeEmail => 'Change e-mail';

  @override
  String get userActionChangeUsername => 'Change username';

  @override
  String get userFieldUsername => 'Username';

  @override
  String get userFieldPassword => 'Password';

  @override
  String get userFieldEmail => 'E-mail';

  @override
  String get userFieldCurrentPassword => 'Current password';

  @override
  String get userFieldNewPassword => 'New password';

  @override
  String get userFieldNewEmail => 'New e-mail';

  @override
  String get userFieldCurrentUsername => 'Current username';

  @override
  String get userFieldNewUsername => 'New username';

  @override
  String get userActionRegisterSuccess =>
      'Registration successful. Please check your e-mail inbox to complete verification.';

  @override
  String get userActionResendVerificationSuccess =>
      'Verification e-mail resent. Please check your e-mails.';

  @override
  String get userActionForgotPasswordSuccess =>
      'If the account exists, a password reset e-mail has been sent.';

  @override
  String get userActionValidationRequiredFields =>
      'Username and e-mail are required.';

  @override
  String get userActionValidationRequiredPasswordFields =>
      'Username, current password and new password are required.';

  @override
  String get userActionValidationRequiredChangeEmailFields =>
      'Username, current password and new e-mail are required.';

  @override
  String get userActionValidationRequiredChangeUsernameFields =>
      'Current username, password and new username are required.';

  @override
  String get userActionValidationInvalidEmail => 'Invalid e-mail address.';

  @override
  String get userActionDeleteUserSuccess => 'User deleted.';

  @override
  String get userActionChangePasswordSuccess =>
      'Password changed successfully.';

  @override
  String get userActionChangeEmailSuccess =>
      'E-mail change request sent. Please check your e-mail inbox to complete verification.';

  @override
  String get userActionChangeUsernameSuccess => 'Username changed.';

  @override
  String get userDeleteConfirmTitle => 'Confirmation';

  @override
  String get userDeleteConfirmMessage =>
      'Are you sure you want to delete this user? This action cannot be undone.';

  @override
  String get userDeleteConfirmButton => 'Delete';

  @override
  String userApiError(Object error) {
    return 'API error: $error';
  }

  @override
  String get userApiUnauthorized =>
      'Authentication failed. Check the username and password.';

  @override
  String get userApiUnknownError => 'Unexpected API error.';

  @override
  String get settingsHotkeyPressAnyKey => 'Press any key combination...';

  @override
  String get settingsHotkeyDialogTitle => 'Capture Hotkey';

  @override
  String get settingsHotkeyConfirm => 'Confirm';

  @override
  String get settingsHotkeyClearCapture => 'Clear';

  @override
  String get settingsHotkeyClear => 'Clear';

  @override
  String get settingsHotkeyCapture => 'Capture';

  @override
  String get settingsSearchKeywordsSystem =>
      'system exit stop shutdown epstop epshutdown';

  @override
  String get controlPhotoView => 'Toggle photo / projection';

  @override
  String get controlPhotoViewPhoto => 'Photo view';

  @override
  String get controlPhotoViewPreview => 'Projection preview';

  @override
  String get useSound => 'Play music';

  @override
  String get advanceAfterMusic => 'Advance after music';

  @override
  String get liveSubtitlesOn => 'Enable live subtitles';

  @override
  String get liveSubtitlesOff => 'Disable live subtitles';

  @override
  String get liveSubtitlesDownloadTitle => 'Download speech model';

  @override
  String get liveSubtitlesDownloadMessage =>
      'A speech recognition model is required. Download now?';

  @override
  String get liveSubtitlesDownloading => 'Downloading speech model...';

  @override
  String get liveSubtitlesError => 'Speech recognition error';

  @override
  String get vadDownloadTitle => 'Download speech activity model';

  @override
  String get vadDownloadMessage =>
      'A speech activity detection (VAD) model is required for offline speech recognition. Download now?';

  @override
  String get vadDownloading => 'Downloading speech activity model...';

  @override
  String get liveSubtitlesMicDevice => 'Microphone';

  @override
  String get liveSubtitlesMicDeviceDefault => 'System default';

  @override
  String get speechSettingsTitle => 'Speech recognition';

  @override
  String get speechFeatureEnabled => 'Enable speech recognition';

  @override
  String get speechSettingsSummary => 'Microphone';

  @override
  String get speechModelTitle => 'Speech model';

  @override
  String get speechModelStreaming => 'Streaming (low latency)';

  @override
  String get speechModelOffline => 'Offline (higher accuracy)';

  @override
  String get transposeDown => 'Transpose down';

  @override
  String get transposeUp => 'Transpose up';

  @override
  String get transposeReset => 'Reset transpose';

  @override
  String get diatarDataTransferTitle => 'Backup';

  @override
  String get diatarDataTransferDescription =>
      'Export the complete internal diatar folder to a ZIP file or restore it from a ZIP file.';

  @override
  String get diatarExportButton => 'Export';

  @override
  String get diatarImportButton => 'Import';

  @override
  String get diatarZipFileTypeLabel => 'Diatar backup';

  @override
  String diatarExportSuccess(Object fileName) {
    return 'Export completed: $fileName';
  }

  @override
  String diatarImportSuccess(int imported) {
    return '$imported files restored.';
  }

  @override
  String get diatarImportConflictTitle => 'Existing files';

  @override
  String diatarImportConflictMessage(int count) {
    return '$count files to import already exist. Should they be overwritten or skipped throughout this import?';
  }

  @override
  String get diatarImportOverwriteAll => 'Overwrite';

  @override
  String get diatarImportSkipAll => 'Skip';

  @override
  String get diatarExportSourceMissing =>
      'The internal diatar folder was not found.';

  @override
  String get diatarImportInvalidArchive =>
      'The selected file is not a valid Diatar backup.';

  @override
  String diatarTransferArchive(Object fileName) {
    return 'ZIP file: $fileName';
  }

  @override
  String diatarTransferCurrentFile(Object fileName) {
    return 'Processing: $fileName';
  }

  @override
  String diatarTransferProgress(int percent) {
    return '$percent%';
  }

  @override
  String get diatarTransferCancelled => 'The operation was cancelled.';

  @override
  String diatarTransferError(Object error) {
    return 'The operation failed: $error';
  }

  @override
  String get szentirasTooltip => 'Bible';

  @override
  String get szentirasTitle => 'Insert Bible verse';

  @override
  String get szentirasReferenceLabel => 'Reference';

  @override
  String get szentirasReferenceHint => 'e.g. 1Cor13,10-13';

  @override
  String get szentirasTranslationLabel => 'Translation';

  @override
  String get szentirasTranslationDefault => 'Default';

  @override
  String get szentirasFetchButton => 'Fetch';

  @override
  String get szentirasImportButton => 'Import';

  @override
  String szentirasInsertAll(int count) {
    return 'Insert all ($count verses)';
  }

  @override
  String get szentirasLoading => 'Loading…';

  @override
  String szentirasError(Object error) {
    return 'Error: $error';
  }

  @override
  String get szentirasNoVerses => 'No verses found.';

  @override
  String get szentirasChunkSizeLabel => 'Slide word limit';

  @override
  String get szentirasChunkSizeHint => 'max. words per slide';

  @override
  String get settingsSzentirasApiKeyLabel => 'szentiras.eu API key';

  @override
  String get settingsSzentirasApiKeyHint => 'Key from szentiras.eu';

  @override
  String get szentirasApiKeyPrompt =>
      'Enter your szentiras.eu API key to use the Bible feature.';

  @override
  String get statusSzentirasApiKeyMissing => 'szentiras.eu API key is not set.';

  @override
  String get settingsApiKeysTitle => 'API Keys';

  @override
  String settingsApiKeysSubtitle(Object status) {
    return 'Szentiras: $status';
  }

  @override
  String get settingsApiKeysStatusSet => 'Set';

  @override
  String get settingsApiKeysStatusMissing => 'Not set';

  @override
  String get szentirasApiKeyHelp =>
      'Get your key:\nszentiras.eu → Login → Profile → API keys';

  @override
  String get szentirasApiKeySave => 'Save';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Diatar!';

  @override
  String get onboardingWelcomeBody =>
      'A church slide projector app.\n\nChoose a songbook, build a custom order, then send it to the projector.';

  @override
  String get onboardingPage2Title => 'Main Screen';

  @override
  String get onboardingPage2Body =>
      'Choose from three modes:\n\n• Books: browse songbooks, select song and verse\n• Slide list: build a custom slide order\n• Presentation: full-screen preview for projecting';

  @override
  String get onboardingPage3Title => 'Building a Slide List';

  @override
  String get onboardingPage3Body =>
      '1. Find songs in the Books mode\n2. Open the Slide List editor\n3. Add verses, text slides, separators\n4. Save as .dia file for later use';

  @override
  String get onboardingPage4Title => 'Special Features';

  @override
  String get onboardingPage4Body =>
      '• Liturgy of the Hours (Zsolozsma): daily liturgy slides\n• Daily Readings (Batyu): import daily readings\n• Bible Verses (Szentiras): insert scripture\n• Search: full-text search across songbooks\n• Hotkeys: keyboard shortcuts for desktop';

  @override
  String get onboardingGotIt => 'Got it, let\'s go!';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingDone => 'Done';

  @override
  String get settingsInternetDescription =>
      'Internet relay via MQTT. Create a user, then share the QR code with the remote DiaVetito receiver.';

  @override
  String get settingsLocalNetworkDescription =>
      'TCP/IP connection over your local network. Enter the projector\'s IP address and port.';

  @override
  String get colorsDescription =>
      'Customize projection colors: background, text, empty slide, and highlight.';

  @override
  String get projectionSettingsDescription =>
      'Font size, margins, background image, alignment, and other projection parameters.';

  @override
  String get settingsFilesDescription =>
      'Import songbooks, DTZ scores, create and restore backups.';

  @override
  String get settingsGeneralDescription =>
      'Switch app theme (dark/light) and user interface language.';

  @override
  String get systemActionsDescription =>
      'Exit the app, reload songbooks, or stop/shutdown the remote projector.';

  @override
  String get settingsHotkeysDescription =>
      'Keyboard shortcuts for quick control on desktop.';

  @override
  String get settingsOnboardingButton => 'Getting started';

  @override
  String get impresszumTitle => 'Imprint';

  @override
  String get impresszumSummary => 'Developers, licenses, and sources';

  @override
  String get impresszumDescription =>
      'About the developers of Diatár and the software used.';

  @override
  String get impresszumDevelopers => 'Developers';

  @override
  String get impresszumDevelopersBody =>
      'Diatár is built by the Szent József Hackathon community.';

  @override
  String get impresszumHackathonTitle => 'Szent József Hackathon';

  @override
  String get impresszumHackathonBody =>
      'Diatár was created during the IV. Szent József Hackathon (2026, Szeged).';

  @override
  String get impresszumDataSources => 'Data sources';

  @override
  String get impresszumSzentiras => 'szentiras.eu — source of Bible texts';

  @override
  String get impresszumLicenses => 'Software and licenses';

  @override
  String get impresszumNemotron =>
      'NVIDIA Nemotron 3.5 ASR — OpenMDW-1.1 license';

  @override
  String get impresszumSherpaOnnx =>
      'Sherpa-ONNX (k2-fsa) — Apache-2.0 license';

  @override
  String get impresszumFlutter => 'Flutter — BSD-3 license';

  @override
  String get impresszumRecord => 'Record (llfbandit) — MIT license';

  @override
  String get impresszumLinks => 'Links';

  @override
  String get impresszumWebsite => 'diatar.eu';

  @override
  String get impresszumGitHub => 'GitHub';

  @override
  String get impresszumHackathonLink => 'Szent József Hackathon';

  @override
  String get impresszumSzentirasLink => 'szentiras.eu';

  @override
  String get speechLanguageTitle => 'Speech recognition language';

  @override
  String get speechLangAuto => 'Automatic (all languages)';

  @override
  String get speechLangEsUS => 'Spanish (es-US)';

  @override
  String get speechLangEsES => 'Spanish (es-ES)';

  @override
  String get speechLangItIT => 'Italian (it-IT)';

  @override
  String get speechLangPtBR => 'Portuguese (pt-BR)';

  @override
  String get speechLangPtPT => 'Portuguese (pt-PT)';

  @override
  String get speechLangHiIN => 'Hindi (hi-IN)';

  @override
  String get speechLangKoKR => 'Korean (ko-KR)';

  @override
  String get speechLangEnUS => 'English (en-US)';

  @override
  String get speechLangEnGB => 'English (en-GB)';

  @override
  String get speechLangDeDE => 'German (de-DE)';

  @override
  String get speechLangFrFR => 'French (fr-FR)';

  @override
  String get speechLangFrCA => 'French (fr-CA)';

  @override
  String get speechLangRuRU => 'Russian (ru-RU)';

  @override
  String get speechLangTrTR => 'Turkish (tr-TR)';

  @override
  String get speechLangViVN => 'Vietnamese (vi-VN)';

  @override
  String get speechLangNlNL => 'Dutch (nl-NL)';

  @override
  String get speechLangJaJP => 'Japanese (ja-JP)';

  @override
  String get speechLangArAR => 'Arabic (ar-AR)';

  @override
  String get speechLangUkUA => 'Ukrainian (uk-UA)';

  @override
  String get speechLangPlPL => 'Polish (pl-PL)';

  @override
  String get speechLangNbNO => 'Norwegian Bokmål (nb-NO)';

  @override
  String get speechLangFiFI => 'Finnish (fi-FI)';

  @override
  String get speechLangZhCN => 'Mandarin (zh-CN)';

  @override
  String get speechLangCsCZ => 'Czech (cs-CZ)';

  @override
  String get speechLangBgBG => 'Bulgarian (bg-BG)';

  @override
  String get speechLangSkSK => 'Slovak (sk-SK)';

  @override
  String get speechLangSvSE => 'Swedish (sv-SE)';

  @override
  String get speechLangHrHR => 'Croatian (hr-HR)';

  @override
  String get speechLangRoRO => 'Romanian (ro-RO)';

  @override
  String get speechLangEtEE => 'Estonian (et-EE)';

  @override
  String get speechLangDaDK => 'Danish (da-DK)';

  @override
  String get speechLangHuHU => 'Hungarian (hu-HU)';

  @override
  String get picPlcSettingsTitle => 'PICPLC controller';

  @override
  String picPlcSettingsEnabledSummary(Object port) {
    return 'Enabled, port: $port';
  }

  @override
  String get picPlcSettingsDisabledSummary => 'Disabled';

  @override
  String get picPlcSettingsDescription =>
      'Configure the PICPLC serial controller, button assignments, and LEDs.';

  @override
  String get picPlcEnabledLabel => 'Enable PICPLC controller';

  @override
  String get picPlcPortLabel => 'Serial port';

  @override
  String get picPlcPortHint => 'e.g. COM3 or /dev/ttyUSB0';

  @override
  String get picPlcPortRequired =>
      'Enter the serial port before enabling the PICPLC controller.';

  @override
  String get picPlcButtonsTitle => 'Button assignments';

  @override
  String picPlcButtonLabel(int number) {
    return 'Button $number';
  }

  @override
  String get picPlcLedsTitle => 'LED assignments';

  @override
  String picPlcLedLabel(int number) {
    return 'LED $number';
  }

  @override
  String get picPlcActionNone => 'No function';

  @override
  String get picPlcActionToggleProjection => 'Toggle projection (button)';

  @override
  String get picPlcActionProjectionSwitch => 'Projection on/off switch';

  @override
  String get picPlcActionPreviousVerse => 'Previous slide';

  @override
  String get picPlcActionNextVerse => 'Next slide';

  @override
  String get picPlcActionPreviousSong => 'Previous song';

  @override
  String get picPlcActionNextSong => 'Next song';

  @override
  String get picPlcActionToggleDirection => 'Toggle direction (button)';

  @override
  String get picPlcActionDirectionSwitch => 'Forward/backward switch';

  @override
  String get picPlcActionStep => 'Step slide';

  @override
  String get picPlcLedProjectionOn => 'Projection on';

  @override
  String get picPlcLedForward => 'Forward direction';

  @override
  String get picPlcLedBackward => 'Backward direction';

  @override
  String get songOrder => 'Song order';

  @override
  String get customOrderEmbedImagesTitle => 'Embed images?';

  @override
  String get customOrderEmbedImagesMessage =>
      'This slide list contains images. Embed them in the DIA file so it can be used without the original image files?';

  @override
  String get customOrderEmbedImagesNo => 'Do not embed';

  @override
  String get customOrderEmbedImagesYes => 'Embed';

  @override
  String customOrderEmbedImageMissing(Object path) {
    return 'The image to embed was not found: $path';
  }
}
