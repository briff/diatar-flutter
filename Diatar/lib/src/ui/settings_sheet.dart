import 'dart:async';
import 'dart:io' show ProcessException;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:diatar_common/diatar_common.dart';
import 'package:diatar_speech/diatar_speech.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/path_helper.dart';
import '../utils/file_system_provider.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../../l10n/generated/app_localizations.dart';
import '../l10n/l10n.dart';
import '../services/mqtt_user_api_service.dart';
import '../services/export_import_service.dart';
import '../services/desktop_projector_bridge.dart';
import '../services/external_command_service.dart';
import '../services/macos_file_panels.dart';
import '../services/blank_image_storage.dart';
import '../services/pic_plc_service.dart';
import '../services/web_diavetito_url.dart';
import '../services/wol_service.dart';
import '../utils/friendly_path.dart';
import 'desktop_hotkey.dart';
import 'onboarding_sheet.dart';

class SongHotkeyOption {
  const SongHotkeyOption({required this.id, required this.label});

  final String id;
  final String label;
}

class CustomOrderSetOption {
  const CustomOrderSetOption({required this.id, required this.name});

  final String id;
  final String name;
}

enum DiatarSettingsInitialSection { internet, localNetwork }

class _DiatarTransferProgress {
  const _DiatarTransferProgress({
    required this.fileName,
    this.entryName,
    this.progress = 0,
  });

  final String fileName;
  final String? entryName;
  final double progress;

  _DiatarTransferProgress copyWith({String? entryName, double? progress}) {
    return _DiatarTransferProgress(
      fileName: fileName,
      entryName: entryName ?? this.entryName,
      progress: progress ?? this.progress,
    );
  }
}

class DiatarSettingsSheet extends StatefulWidget {
  const DiatarSettingsSheet({
    super.key,
    required this.initialSettings,
    required this.initialPicPlcConfiguration,
    required this.onApply,
    required this.onApplyPicPlc,
    required this.onExitRequested,
    required this.onReloadBooksRequested,
    required this.onRemoteStopRequested,
    required this.onRemoteShutdownRequested,
    this.availableSongs = const <SongHotkeyOption>[],
    this.availableSongsLoader,
    this.availableOrderSets = const <CustomOrderSetOption>[],
    this.availableOrderSetsLoader,
    this.initialSection,
    this.closeAfterInitialSectionClose = false,
    this.onDownloadBooksRequested,
    this.onFileTransferProgress,
  });

  final AppSettings initialSettings;
  final PicPlcConfiguration initialPicPlcConfiguration;
  final Future<void> Function(AppSettings) onApply;
  final Future<void> Function(PicPlcConfiguration) onApplyPicPlc;
  final VoidCallback onExitRequested;
  final VoidCallback onReloadBooksRequested;
  final VoidCallback onRemoteStopRequested;
  final VoidCallback onRemoteShutdownRequested;
  final List<SongHotkeyOption> availableSongs;
  final List<SongHotkeyOption> Function()? availableSongsLoader;
  final List<CustomOrderSetOption> availableOrderSets;
  final List<CustomOrderSetOption> Function()? availableOrderSetsLoader;
  final DiatarSettingsInitialSection? initialSection;
  final bool closeAfterInitialSectionClose;
  final VoidCallback? onDownloadBooksRequested;
  final ValueChanged<double?>? onFileTransferProgress;

  @override
  State<DiatarSettingsSheet> createState() => _DiatarSettingsSheetState();
}

class _DiatarSettingsSheetState extends State<DiatarSettingsSheet> {
  static const MethodChannel _androidBackupSaveChannel = MethodChannel(
    'diatar.eu/dia_save',
  );
  static const MethodChannel _androidBackupSaveProgressChannel = MethodChannel(
    'diatar.eu/dia_save_progress',
  );
  static final RegExp _simpleEmailPattern = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  late final TextEditingController _search;
  late final TextEditingController _tcpTargets;
  late final TextEditingController _mqttUser;
  late final TextEditingController _mqttPassword;
  late final TextEditingController _blankPicPath;
  late final TextEditingController _diaExportPath;
  late final TextEditingController _picPlcPort;
  final BlankImageStore _blankImageStore = BlankImageStore();
  final ExternalCommandService _externalCommandService =
      const ExternalCommandService();
  late final TextEditingController _projFontSize;
  late final TextEditingController _projTitleSize;
  late final TextEditingController _projLeftIndent;
  late final TextEditingController _projBorderL;
  late final TextEditingController _projBorderT;
  late final TextEditingController _projBorderR;
  late final TextEditingController _projBorderB;
  late final TextEditingController _externalCommandOnStart;
  late final TextEditingController _externalCommandOnExit;
  late final TextEditingController _externalCommandOnProjectionOn;
  late final TextEditingController _externalCommandOnProjectionOff;
  late int _projSpacingStep;
  late int _projKottaArany;
  late int _projAkkordArany;
  late int _projBgMode;
  late int _projBackTrans;
  late int _projBlankTrans;
  late int _appThemeMode;
  late String _appLanguage;
  late int _maxCustomOrderSets;
  late bool _diaAutoSaveEnabled;
  late bool _homeShowHighlightControls;
  late bool _projHCenter;
  late bool _projVCenter;
  late bool _projUseAkkord;
  late bool _projUseKotta;
  late bool _projInverseKotta;
  late bool _projShowBackgroundImage;
  late bool _useSound;
  late bool _advanceAfterMusic;
  late bool _projUseTitle;
  late bool _projBoldText;
  late int _desktopProjectorMonitor;
  late bool _desktopProjectorEnabled;
  late bool _showCameraView;
  late String? _cameraTarget;
  late bool _wolEnabled;
  late final TextEditingController _wolTargets;
  late final TextEditingController _wolBroadcastAddress;
  late final TextEditingController _wolPort;
  late bool _internetRelayEnabled;
  late bool _localNetworkEnabled;
  late bool _picPlcEnabled;
  late List<PicPlcButtonAction> _picPlcButtonActions;
  late List<PicPlcLedAction> _picPlcLedActions;
  late String? _liveSubtitleDeviceId;
  late String _liveSubtitleLanguage;
  late String _liveSubtitleModel;
  late bool _speechFeatureVisible;
  late Map<String, String> _desktopActionHotkeys;
  late Map<String, String> _desktopSongHotkeys;
  late Map<String, String> _desktopOrderSetHotkeys;
  late List<SongHotkeyOption> _availableSongs;
  late List<CustomOrderSetOption> _availableOrderSets;
  bool _availableSongsResolved = false;
  String _selectedSongHotkeyOptionId = '';
  bool _availableOrderSetsResolved = false;
  String _selectedOrderSetOptionId = '';
  bool _showInternetPassword = false;
  bool _internetActionRunning = false;
  late final TextEditingController _szentirasApiKey;
  void Function(void Function())? _setInternetSectionState;
  late final MqttUserApiService _userApi;
  late Color _bkColor;
  late Color _txtColor;
  late Color _blankColor;
  late Color _hiColor;
  String _appVersion = '-';
  String _buildNumber = '-';
  final ExportImportService _exportImportService = ExportImportService();
  bool _fileTransferRunning = false;

  String get _internetRelayUrl => webDiaVetitoUrl(_mqttUser.text);

  bool get _canShowInternetQr =>
      _internetRelayEnabled && _mqttUser.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _userApi = MqttUserApiService(
      acceptLanguageProvider: _currentAcceptLanguage,
    );
    _loadAppVersion();
    final AppSettings s = widget.initialSettings;
    _search = TextEditingController();
    _tcpTargets = TextEditingController(text: s.tcpTargets.join('\n'));
    _mqttUser = TextEditingController(text: s.mqttUser);
    _mqttPassword = TextEditingController(text: s.mqttPassword);
    _szentirasApiKey = TextEditingController(text: s.szentirasApiKey);
    _blankPicPath = TextEditingController(text: s.blankPicPath);
    _diaExportPath = TextEditingController(text: s.diaExportPath);
    _diaAutoSaveEnabled = s.diaAutoSaveEnabled;
    _picPlcPort = TextEditingController(
      text: widget.initialPicPlcConfiguration.port,
    );
    _picPlcEnabled = widget.initialPicPlcConfiguration.enabled;
    _picPlcButtonActions = List<PicPlcButtonAction>.from(
      widget.initialPicPlcConfiguration.buttonActions,
    );
    _picPlcLedActions = List<PicPlcLedAction>.from(
      widget.initialPicPlcConfiguration.ledActions,
    );
    _projFontSize = TextEditingController(text: s.projFontSize.toString());
    _projTitleSize = TextEditingController(text: s.projTitleSize.toString());
    _projLeftIndent = TextEditingController(text: s.projLeftIndent.toString());
    _projBorderL = TextEditingController(text: s.projBorderL.toString());
    _projBorderT = TextEditingController(text: s.projBorderT.toString());
    _projBorderR = TextEditingController(text: s.projBorderR.toString());
    _projBorderB = TextEditingController(text: s.projBorderB.toString());
    _externalCommandOnStart = TextEditingController(
      text: s.externalCommandOnStart,
    );
    _externalCommandOnExit = TextEditingController(
      text: s.externalCommandOnExit,
    );
    _externalCommandOnProjectionOn = TextEditingController(
      text: s.externalCommandOnProjectionOn,
    );
    _externalCommandOnProjectionOff = TextEditingController(
      text: s.externalCommandOnProjectionOff,
    );
    _projSpacingStep = s.projSpacingStep.clamp(0, 10);
    _projKottaArany = s.projKottaArany.clamp(10, 200);
    _projAkkordArany = s.projAkkordArany.clamp(10, 200);
    _projBgMode = s.projBgMode.clamp(0, 4);
    _projBackTrans = s.projBackTrans.clamp(0, 100);
    _projBlankTrans = s.projBlankTrans.clamp(0, 100);
    _appThemeMode = s.appThemeMode.clamp(0, 1);
    _appLanguage = _isSupportedLanguage(s.appLanguage) ? s.appLanguage : '';
    _maxCustomOrderSets = s.maxCustomOrderSets.clamp(
      AppSettings.minCustomOrderSets,
      AppSettings.maxCustomOrderSetsLimit,
    );
    _homeShowHighlightControls = s.homeShowHighlightControls;
    _projHCenter = s.projHCenter;
    _projVCenter = s.projVCenter;
    _projUseAkkord = s.projUseAkkord;
    _projUseKotta = s.projUseKotta;
    _projInverseKotta = s.projInverseKotta;
    _projShowBackgroundImage = s.projShowBackgroundImage;
    _useSound = s.useSound;
    _advanceAfterMusic = s.advanceAfterMusic;
    _projUseTitle = s.projUseTitle;
    _projBoldText = s.projBoldText;
    _desktopProjectorMonitor = s.desktopProjectorMonitor;
    _desktopProjectorEnabled = s.desktopProjectorEnabled;
    _showCameraView = s.showCameraView;
    _cameraTarget = s.cameraTarget;
    _wolEnabled = s.wolEnabled;
    _wolTargets = TextEditingController(text: s.wolTargets.join('\n'));
    _wolBroadcastAddress = TextEditingController(text: s.wolBroadcastAddress);
    _wolPort = TextEditingController(text: s.wolPort.toString());
    _internetRelayEnabled = s.internetRelayEnabled;
    _localNetworkEnabled = s.tcpClientEnabled;
    _liveSubtitleDeviceId = s.liveSubtitleDeviceId;
    _liveSubtitleLanguage = s.liveSubtitleLanguage;
    _liveSubtitleModel = s.liveSubtitleModel;
    _speechFeatureVisible = s.speechFeatureVisible;
    _desktopActionHotkeys = Map<String, String>.from(s.desktopActionHotkeys);
    _desktopSongHotkeys = Map<String, String>.from(s.desktopSongHotkeys);
    _desktopOrderSetHotkeys = Map<String, String>.from(
      s.desktopOrderSetHotkeys,
    );
    _availableSongs = List<SongHotkeyOption>.from(widget.availableSongs);
    _availableSongsResolved = widget.availableSongs.isNotEmpty;
    if (_availableSongs.isNotEmpty) {
      _selectedSongHotkeyOptionId = _availableSongs.first.id;
    }
    _availableOrderSets = List<CustomOrderSetOption>.from(
      widget.availableOrderSets,
    );
    _availableOrderSetsResolved = widget.availableOrderSets.isNotEmpty;
    if (_selectedOrderSetOptionId.isEmpty && _availableOrderSets.isNotEmpty) {
      _selectedOrderSetOptionId = _availableOrderSets.first.id;
    }
    _bkColor = s.bkColor;
    _txtColor = s.txtColor;
    _blankColor = s.blankColor;
    _hiColor = s.hiColor;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openInitialSectionIfNeeded());
    });
  }

  Future<void> _openInitialSectionIfNeeded() async {
    if (!mounted) {
      return;
    }
    switch (widget.initialSection) {
      case DiatarSettingsInitialSection.internet:
        await _openInternetSettings();
        break;
      case DiatarSettingsInitialSection.localNetwork:
        await _openLocalNetworkSettings();
        break;
      case null:
        return;
    }
    if (!mounted || !widget.closeAfterInitialSectionClose) {
      return;
    }
    await Navigator.of(context).maybePop();
  }

  String? _currentAcceptLanguage() {
    final String languageCode = context.l10n.localeName.trim();
    if (languageCode.isEmpty) {
      return null;
    }
    return languageCode.split(RegExp(r'[_-]')).first;
  }

  Future<void> _loadAppVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() {
      final parts = info.version.split('.');
      _appVersion = parts.length >= 2
          ? '${parts[0]}.${parts[1]}'
          : info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _tcpTargets.dispose();
    _wolTargets.dispose();
    _wolBroadcastAddress.dispose();
    _wolPort.dispose();
    _mqttUser.dispose();
    _mqttPassword.dispose();
    _szentirasApiKey.dispose();
    _blankPicPath.dispose();
    _diaExportPath.dispose();
    _picPlcPort.dispose();
    _projFontSize.dispose();
    _projTitleSize.dispose();
    _projLeftIndent.dispose();
    _projBorderL.dispose();
    _projBorderT.dispose();
    _projBorderR.dispose();
    _projBorderB.dispose();
    _externalCommandOnStart.dispose();
    _externalCommandOnExit.dispose();
    _externalCommandOnProjectionOn.dispose();
    _externalCommandOnProjectionOff.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String query = _search.text.trim().toLowerCase();
    final String internetStatus = _internetRelayEnabled
        ? l10n.internetStatusOn
        : l10n.internetStatusOff;
    final String mqttUser = _mqttUser.text.trim().isEmpty
        ? l10n.valueNotSet
        : _mqttUser.text.trim();
    final String localNetworkStatus = _localNetworkEnabled
        ? l10n.internetStatusOn
        : l10n.internetStatusOff;
    final List<String> tcpTargets = _parseTcpTargets(_tcpTargets.text);
    final String tcpSummary = tcpTargets.isEmpty
        ? l10n.tcpNoTargets
        : l10n.tcpTargetsCount(tcpTargets.length);
    final List<String> wolTargets = _parseWolTargets(_wolTargets.text);
    final String wolSummary = wolTargets.isEmpty
        ? l10n.tcpNoTargets
        : l10n.tcpTargetsCount(wolTargets.length);
    final String languageLabel = _appLanguage.trim().isEmpty
        ? l10n.languageSystem
        : _languageLabel(context, _appLanguage);
    final String themeLabel = _appThemeMode == 0
        ? l10n.themeDark
        : l10n.themeLight;
    final String blankSummary = _blankPicPath.text.trim().isEmpty
        ? l10n.valueNotSet
        : shortFriendlyPathLabel(_blankPicPath.text.trim(), l10n);
    final bool desktopHotkeysAvailable = _supportsHotkeysPlatform();
    final bool picPlcAvailable =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    final bool showInternet = _matches(
      query,
      'internet mqtt kozvetites felhasznalo user',
    );
    final bool showLan =
        !kIsWeb && _matches(query, 'helyi halozat tcp ip port');
    final bool showWol =
        !kIsWeb &&
        _matches(
          query,
          'wake on lan wol ebreszto kapcsolat mac broadcast port',
        );
    final bool showProjection = _matches(
      query,
      'vetites betu meret cim hatter opacity szinek szin',
    );
    final bool showFiles = _matches(
      query,
      'enektar fajlok dtx hatterkep hatter kep blank export import backup biztonsagi mentes zip',
    );
    final bool showGeneral = _matches(
      query,
      'altalanos tema nyelv language gorgetheto akkord kotta hatterkep szokiemeles',
    );
    final bool showSpeech =
        !kIsWeb &&
        _matches(query, 'beszedfelismero speech recognition mikrofon');
    final bool showSystem = _matches(
      query,
      'rendszer kilepes leallas stop shutdown epstop epshutdown',
    );
    final bool showExternalCommands =
        _supportsExternalCommandsPlatform() &&
        _matches(
          query,
          'kulso vezerles parancs shell command inditas kilepes vetites',
        );
    final bool showHotkeys =
        desktopHotkeysAvailable &&
        _matches(
          query,
          'gyorsbillentyu hotkey billentyu shortcut vezerles enek',
        );
    final bool showPicPlc =
        picPlcAvailable &&
        _matches(query, 'picplc vezerlo controller soros serial gomb led');
    final bool showApiKeys = _matches(query, 'api kulcs key szentiras');
    final bool showImpresszum = _matches(
      query,
      'impresszum impress imprint névjegy about verzió version licenc license',
    );
    final bool anyVisible =
        showInternet ||
        showLan ||
        showWol ||
        showProjection ||
        showFiles ||
        showGeneral ||
        showSpeech ||
        showSystem ||
        showExternalCommands ||
        showHotkeys ||
        showPicPlc ||
        showApiKeys ||
        showImpresszum;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                Text(
                  l10n.settingsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.settingsVersionLabel(_appVersion, _buildNumber),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.settingsSearchLabel,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              elevation: 1,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  if (showInternet)
                    _settingsTile(
                      leading: const Icon(Icons.public),
                      title: Text(l10n.settingsInternetTitle),
                      subtitle: Text(
                        l10n.settingsInternetSubtitle(internetStatus, mqttUser),
                      ),
                      onTap: _openInternetSettings,
                      description: l10n.settingsInternetDescription,
                    ),
                  if (showInternet &&
                      (showLan ||
                          showProjection ||
                          showFiles ||
                          showGeneral ||
                          showApiKeys))
                    const Divider(height: 1),
                  if (showApiKeys)
                    _settingsTile(
                      leading: const Icon(Icons.vpn_key),
                      title: Text(l10n.settingsApiKeysTitle),
                      subtitle: Text(
                        l10n.settingsApiKeysSubtitle(
                          _szentirasApiKey.text.trim().isEmpty
                              ? l10n.settingsApiKeysStatusMissing
                              : l10n.settingsApiKeysStatusSet,
                        ),
                      ),
                      onTap: _openApiKeysSettings,
                    ),
                  if (showApiKeys &&
                      (showLan || showProjection || showFiles || showGeneral))
                    const Divider(height: 1),
                  if (showLan)
                    _settingsTile(
                      leading: const Icon(Icons.lan),
                      title: Text(l10n.settingsLocalNetworkTitle),
                      subtitle: Text(
                        l10n.settingsLocalNetworkSubtitle(
                          localNetworkStatus,
                          tcpSummary,
                        ),
                      ),
                      onTap: _openLocalNetworkSettings,
                      description: l10n.settingsLocalNetworkDescription,
                    ),
                  if (showLan && (showProjection || showFiles || showGeneral))
                    const Divider(height: 1),
                  if (showWol)
                    _settingsTile(
                      leading: const Icon(Icons.offline_bolt),
                      title: Text(l10n.settingsWolTitle),
                      subtitle: Text(
                        l10n.settingsWolSubtitle(
                          _wolEnabled
                              ? l10n.internetStatusOn
                              : l10n.internetStatusOff,
                          wolSummary,
                        ),
                      ),
                      onTap: _openWakeOnLanSettings,
                      description: l10n.settingsWolDescription,
                    ),
                  if (showWol && (showProjection || showFiles || showGeneral))
                    const Divider(height: 1),
                  if (showProjection)
                    _settingsTile(
                      leading: const Icon(Icons.slideshow),
                      title: Text(l10n.projectionSettingsTitle),
                      subtitle: Text(
                        l10n.settingsProjectionSummary(
                          _projFontSize.text.trim(),
                          _projTitleSize.text.trim(),
                        ),
                      ),
                      onTap: _openProjectionSettings,
                      description: l10n.projectionSettingsDescription,
                    ),
                  if (showProjection &&
                      (showFiles || showGeneral || showSpeech || showHotkeys))
                    const Divider(height: 1),
                  if (showFiles)
                    _settingsTile(
                      leading: const Icon(Icons.folder),
                      title: Text(l10n.settingsFilesTitle),
                      subtitle: Text(l10n.settingsFilesSummary(blankSummary)),
                      onTap: _openFileSettings,
                      description: l10n.settingsFilesDescription,
                    ),
                  if (showFiles && (showGeneral || showSpeech || showHotkeys))
                    const Divider(height: 1),
                  if (showGeneral)
                    _settingsTile(
                      leading: const Icon(Icons.tune),
                      title: Text(l10n.settingsGeneralTitle),
                      subtitle: Text(
                        l10n.settingsGeneralSummary(themeLabel, languageLabel),
                      ),
                      onTap: _openGeneralSettings,
                      description: l10n.settingsGeneralDescription,
                    ),
                  if (showGeneral &&
                      (showSpeech ||
                          showExternalCommands ||
                          showSystem ||
                          showHotkeys))
                    const Divider(height: 1),
                  if (showSpeech)
                    _settingsTile(
                      leading: const Icon(Icons.mic),
                      title: Text(l10n.speechSettingsTitle),
                      subtitle: Text(l10n.speechSettingsSummary),
                      onTap: _openSpeechSettings,
                    ),
                  if (showSpeech &&
                      (showExternalCommands || showSystem || showHotkeys))
                    const Divider(height: 1),
                  if (showExternalCommands)
                    _settingsTile(
                      leading: const Icon(Icons.terminal),
                      title: Text(l10n.externalCommandsTitle),
                      subtitle: Text(l10n.externalCommandsSummary),
                      onTap: _openExternalCommandSettings,
                      description: _externalCommandsDescription(l10n),
                    ),
                  if (showExternalCommands && (showSystem || showHotkeys))
                    const Divider(height: 1),
                  if (showSystem)
                    _settingsTile(
                      leading: const Icon(Icons.power_settings_new),
                      title: Text(l10n.systemActionsTitle),
                      subtitle: Text(l10n.systemActionsSummary),
                      onTap: _openSystemActions,
                      description: l10n.systemActionsDescription,
                    ),
                  if (showSystem && showHotkeys) const Divider(height: 1),
                  if (showHotkeys)
                    _settingsTile(
                      leading: const Icon(Icons.keyboard_alt_outlined),
                      title: Text(l10n.settingsHotkeysTitle),
                      subtitle: Text(l10n.settingsHotkeysSummary),
                      onTap: _openDesktopHotkeySettings,
                      description: l10n.settingsHotkeysDescription,
                    ),
                  if (showHotkeys && showImpresszum && !showPicPlc)
                    const Divider(height: 1),
                  if (showHotkeys && showPicPlc) const Divider(height: 1),
                  if (showPicPlc)
                    _settingsTile(
                      leading: const Icon(Icons.settings_remote_outlined),
                      title: Text(l10n.picPlcSettingsTitle),
                      subtitle: Text(
                        _picPlcEnabled
                            ? l10n.picPlcSettingsEnabledSummary(
                                _picPlcPort.text.trim().isEmpty
                                    ? l10n.valueNotSet
                                    : _picPlcPort.text.trim(),
                              )
                            : l10n.picPlcSettingsDisabledSummary,
                      ),
                      onTap: _openPicPlcSettings,
                      description: l10n.picPlcSettingsDescription,
                    ),
                  if (showPicPlc && showImpresszum) const Divider(height: 1),
                  if (showImpresszum)
                    _settingsTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(l10n.impresszumTitle),
                      subtitle: Text(l10n.impresszumSummary),
                      onTap: _openImpresszumSheet,
                      description: l10n.impresszumDescription,
                    ),
                  if (!anyVisible)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.settingsNoResults),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const Spacer(),
                FilledButton(onPressed: _save, child: Text(l10n.save)),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.onDownloadBooksRequested != null)
              TextButton.icon(
                icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                label: Text(l10n.downloadBooksTooltip),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDownloadBooksRequested!.call();
                },
              ),
            TextButton.icon(
              icon: const Icon(Icons.auto_stories, size: 18),
              label: Text(l10n.settingsOnboardingButton),
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (BuildContext bc) {
                    return OnboardingSheet(
                      onComplete: () {
                        Navigator.of(bc).pop();
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(String query, String haystack) {
    if (query.isEmpty) {
      return true;
    }
    return haystack.toLowerCase().contains(query);
  }

  Widget _settingsTile({
    required Widget leading,
    required Widget title,
    required Widget subtitle,
    required VoidCallback onTap,
    String? description,
  }) {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (description != null)
            Tooltip(
              message: description,
              child: IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    content: Text(description),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                ),
                padding: EdgeInsets.zero,
                splashRadius: 16,
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _openInternetSettings() {
    final bool originalInternetRelayEnabled = _internetRelayEnabled;
    final String originalMqttUser = _mqttUser.text;
    final String originalMqttPassword = _mqttPassword.text;
    final bool originalShowInternetPassword = _showInternetPassword;

    return _openSectionSheet(
      title: context.l10n.settingsInternetTitle,
      showCancelButton: true,
      onConfirmClose: _applyNetworkSettings,
      onCancel: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _internetRelayEnabled = originalInternetRelayEnabled;
          _mqttUser.text = originalMqttUser;
          _mqttPassword.text = originalMqttPassword;
          _showInternetPassword = originalShowInternetPassword;
        });
      },
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        _setInternetSectionState = setBoth;
        final l10n = context.l10n;
        return <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _internetRelayEnabled,
            onChanged: (bool v) => setBoth(() => _internetRelayEnabled = v),
            title: Text(l10n.internetRelaySwitchTitle),
          ),
          TextField(
            controller: _mqttUser,
            enabled: _internetRelayEnabled,
            onChanged: (_) => setBoth(() {}),
            decoration: InputDecoration(labelText: l10n.userFieldUsername),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _internetRelayUrl,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _canShowInternetQr
                    ? () => _openInternetQrDialog(context)
                    : null,
                icon: const Icon(Icons.qr_code_2),
                label: Text(l10n.internetRelayQrButton),
              ),
            ],
          ),
          TextField(
            controller: _mqttPassword,
            enabled: _internetRelayEnabled,
            obscureText: !_showInternetPassword,
            decoration: InputDecoration(
              labelText: l10n.userFieldPassword,
              suffixIcon: IconButton(
                tooltip: _showInternetPassword
                    ? l10n.passwordHideTooltip
                    : l10n.passwordShowTooltip,
                onPressed: _internetRelayEnabled
                    ? () => setBoth(
                        () => _showInternetPassword = !_showInternetPassword,
                      )
                    : null,
                icon: Icon(
                  _showInternetPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(
            l10n.internetUserActionsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _internetActionRunning ? null : _registerUser,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(l10n.userActionRegister),
              ),
              OutlinedButton.icon(
                onPressed: _internetActionRunning ? null : _resendVerification,
                icon: const Icon(Icons.mark_email_unread_outlined),
                label: Text(l10n.userActionResendVerification),
              ),
              OutlinedButton.icon(
                onPressed: _internetActionRunning ? null : _forgotPassword,
                icon: const Icon(Icons.lock_reset),
                label: Text(l10n.userActionForgotPassword),
              ),
              OutlinedButton.icon(
                onPressed: _internetActionRunning ? null : _deleteUser,
                icon: const Icon(Icons.person_remove_alt_1),
                label: Text(l10n.userActionDeleteUser),
              ),
              OutlinedButton.icon(
                onPressed: _internetActionRunning ? null : _changePassword,
                icon: const Icon(Icons.password),
                label: Text(l10n.userActionChangePassword),
              ),
              OutlinedButton.icon(
                onPressed: _internetActionRunning ? null : _changeEmail,
                icon: const Icon(Icons.alternate_email),
                label: Text(l10n.userActionChangeEmail),
              ),
            ],
          ),
          if (_internetActionRunning) ...<Widget>[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ];
      },
    ).whenComplete(() => _setInternetSectionState = null);
  }

  Future<void> _registerUser() async {
    final l10n = context.l10n;
    final _RegistrationInput? registration = await _askRegistrationInput(
      title: l10n.userActionRegister,
      initialUsername: _mqttUser.text.trim(),
    );
    if (registration == null) {
      return;
    }
    await _runUserApiAction(
      successMessage: l10n.userActionRegisterSuccess,
      action: () => _userApi.createUser(
        username: registration.username,
        password: registration.password,
        email: registration.email,
      ),
    );
  }

  Future<void> _resendVerification() async {
    final l10n = context.l10n;
    final _ResendVerificationInput? input = await _askResendVerificationInput(
      title: l10n.userActionResendVerification,
    );
    if (input == null) {
      return;
    }

    final String username = input.username;
    final String email = input.email;
    if (username.isEmpty || email.isEmpty) {
      await _showInternetResultDialog(l10n.userActionValidationRequiredFields);
      return;
    }
    if (!_simpleEmailPattern.hasMatch(email)) {
      await _showInternetResultDialog(l10n.userActionValidationInvalidEmail);
      return;
    }

    await _runUserApiAction(
      successMessage: l10n.userActionResendVerificationSuccess,
      action: () =>
          _userApi.resendVerification(username: username, email: email),
    );
  }

  Future<void> _deleteUser() async {
    final l10n = context.l10n;
    final _DeleteUserInput? input = await _askDeleteUserInput(
      title: l10n.userActionDeleteUser,
      initialUsername: _mqttUser.text.trim(),
    );
    if (input == null) {
      return;
    }

    final String username = input.username;
    final String password = input.password;
    if (username.isEmpty || password.isEmpty) {
      await _showInternetResultDialog(l10n.userActionValidationRequiredFields);
      return;
    }

    if (!mounted) {
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(l10n.userDeleteConfirmTitle),
              content: Text(l10n.userDeleteConfirmMessage),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.userDeleteConfirmButton),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    await _runUserApiAction(
      successMessage: l10n.userActionDeleteUserSuccess,
      action: () async {
        await _disableInternetRelayBeforeDeletingActiveSender(username);
        await _userApi.deleteUser(username: username, password: password);
      },
    );
  }

  Future<void> _disableInternetRelayBeforeDeletingActiveSender(
    String username,
  ) async {
    final String deletingUser = username.trim();
    final String senderUser = _mqttUser.text.trim();
    final bool shouldDisableRelay =
        _internetRelayEnabled &&
        deletingUser.isNotEmpty &&
        senderUser.isNotEmpty &&
        deletingUser == senderUser;
    if (!shouldDisableRelay) {
      return;
    }

    if (mounted) {
      setState(() {
        _internetRelayEnabled = false;
      });
    }

    final AppSettings relayDisabled = widget.initialSettings.copyWith(
      internetRelayEnabled: false,
      mqttUser: senderUser,
      mqttPassword: '',
      mqttChannel: '1',
    );
    await widget.onApply(relayDisabled);
  }

  Future<void> _forgotPassword() async {
    final l10n = context.l10n;
    final _ResendVerificationInput? input = await _askResendVerificationInput(
      title: l10n.userActionForgotPassword,
    );
    if (input == null) {
      return;
    }

    final String username = input.username;
    final String email = input.email;
    if (username.isEmpty || email.isEmpty) {
      await _showInternetResultDialog(l10n.userActionValidationRequiredFields);
      return;
    }
    if (!_simpleEmailPattern.hasMatch(email)) {
      await _showInternetResultDialog(l10n.userActionValidationInvalidEmail);
      return;
    }

    await _runUserApiAction(
      successMessage: l10n.userActionForgotPasswordSuccess,
      action: () =>
          _userApi.requestPasswordReset(username: username, email: email),
    );
  }

  Future<void> _changePassword() async {
    final l10n = context.l10n;
    final _ChangePasswordInput? input = await _askChangePasswordInput(
      title: l10n.userActionChangePassword,
      initialUsername: _mqttUser.text.trim(),
    );
    if (input == null) {
      return;
    }

    final String username = input.username;
    final String password = input.password;
    final String newPassword = input.newPassword;
    if (username.isEmpty || password.isEmpty || newPassword.isEmpty) {
      await _showInternetResultDialog(
        l10n.userActionValidationRequiredPasswordFields,
      );
      return;
    }

    await _runUserApiAction(
      successMessage: l10n.userActionChangePasswordSuccess,
      action: () => _userApi.changePassword(
        username: username,
        password: password,
        newPassword: newPassword,
      ),
    );
  }

  Future<void> _changeEmail() async {
    final l10n = context.l10n;
    final _ChangeEmailInput? input = await _askChangeEmailInput(
      title: l10n.userActionChangeEmail,
      initialValue: _mqttUser.text.trim(),
    );
    if (input == null) {
      return;
    }

    final String username = input.username;
    final String password = input.password;
    final String newEmail = input.newEmail;
    if (username.isEmpty || password.isEmpty || newEmail.isEmpty) {
      await _showInternetResultDialog(
        l10n.userActionValidationRequiredChangeEmailFields,
      );
      return;
    }

    if (!_simpleEmailPattern.hasMatch(newEmail)) {
      await _showInternetResultDialog(l10n.userActionValidationInvalidEmail);
      return;
    }

    await _runUserApiAction(
      successMessage: l10n.userActionChangeEmailSuccess,
      action: () => _userApi.changeEmail(
        username: username,
        password: password,
        newEmail: newEmail,
      ),
    );
  }

  Future<_RegistrationInput?> _askRegistrationInput({
    required String title,
    required String initialUsername,
  }) {
    return showDialog<_RegistrationInput>(
      context: context,
      builder: (BuildContext context) {
        return _RegistrationInputDialog(
          title: title,
          initialUsername: initialUsername,
        );
      },
    );
  }

  Future<_ChangeEmailInput?> _askChangeEmailInput({
    required String title,
    required String initialValue,
  }) {
    return showDialog<_ChangeEmailInput>(
      context: context,
      builder: (BuildContext context) {
        return _ChangeEmailInputDialog(
          title: title,
          initialUsername: initialValue,
        );
      },
    );
  }

  Future<_ResendVerificationInput?> _askResendVerificationInput({
    required String title,
  }) {
    return showDialog<_ResendVerificationInput>(
      context: context,
      builder: (BuildContext context) {
        return _ResendVerificationInputDialog(title: title);
      },
    );
  }

  Future<_DeleteUserInput?> _askDeleteUserInput({
    required String title,
    required String initialUsername,
  }) {
    return showDialog<_DeleteUserInput>(
      context: context,
      builder: (BuildContext context) {
        return _DeleteUserInputDialog(
          title: title,
          initialUsername: initialUsername,
        );
      },
    );
  }

  Future<_ChangePasswordInput?> _askChangePasswordInput({
    required String title,
    required String initialUsername,
  }) {
    return showDialog<_ChangePasswordInput>(
      context: context,
      builder: (BuildContext context) {
        return _ChangePasswordInputDialog(
          title: title,
          initialUsername: initialUsername,
        );
      },
    );
  }

  Future<void> _showInternetResultDialog(String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.settingsInternetTitle),
          content: Text(message),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openInternetQrDialog(BuildContext sectionContext) {
    final String url = _internetRelayUrl;
    final AppLocalizations l10n = sectionContext.l10n;
    return showModalBottomSheet<void>(
      context: sectionContext,
      isScrollControlled: true,
      useRootNavigator: false,
      enableDrag: true,
      showDragHandle: true,
      backgroundColor: Theme.of(sectionContext).colorScheme.surface,
      builder: (BuildContext context) {
        final Size size = MediaQuery.sizeOf(context);
        final double maxQrWidth = (size.width - 56).clamp(140.0, 520.0);
        final double maxQrHeight = (size.height - 360).clamp(140.0, 520.0);
        final double qrSize = math.min(maxQrWidth, maxQrHeight);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.internetRelayQrTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: url,
                        version: QrVersions.auto,
                        size: qrSize,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.internetRelayQrHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.internetRelayLinkLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    url,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8,
                    overflowSpacing: 8,
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: url));
                          if (!mounted) {
                            return;
                          }
                          await _showInternetResultDialog(
                            l10n.internetRelayLinkCopied,
                          );
                        },
                        icon: const Icon(Icons.copy_all),
                        label: Text(l10n.internetRelayCopyLink),
                      ),
                      TextButton.icon(
                        onPressed: () => _saveInternetQrImage(sectionContext),
                        icon: const Icon(Icons.image_outlined),
                        label: Text(l10n.internetRelaySaveQrImage),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List?> _buildInternetQrPng(
    String url, {
    double size = 1200,
  }) async {
    final QrPainter painter = QrPainter(
      data: url,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
    );
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder)
      ..drawColor(Colors.white, BlendMode.src);
    painter.paint(canvas, Size.square(size));

    final ui.Image image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return data?.buffer.asUint8List();
  }

  String _internetQrFileName() {
    final String user = _mqttUser.text.trim();
    final String safeUser = user
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (safeUser.isEmpty) {
      return 'diavetito-qr.png';
    }
    return 'diavetito-$safeUser-qr.png';
  }

  Future<void> _saveInternetQrImage(BuildContext sectionContext) async {
    final AppLocalizations l10n = sectionContext.l10n;
    final String url = _internetRelayUrl;
    try {
      final Uint8List? png = await _buildInternetQrPng(url);
      if (png == null || png.isEmpty) {
        throw Exception('QR generation failed');
      }
      final String fileName = _internetQrFileName();
      final XFile imageFile = XFile.fromData(
        png,
        mimeType: 'image/png',
        name: fileName,
      );
      String savedPath = fileName;

      if (kIsWeb) {
        await imageFile.saveTo(fileName);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final String? exported = await _saveInternetQrWithAndroidSystemDialog(
            fileName: fileName,
            bytes: png,
          );
          if (exported == null) {
            return;
          }
          savedPath = exported;
        } on MissingPluginException {
          savedPath = await _saveInternetQrToDocumentsDirectory(
            fileName: fileName,
            bytes: png,
          );
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        savedPath = await _saveInternetQrToDocumentsDirectory(
          fileName: fileName,
          bytes: png,
        );
      } else {
        final FileSaveLocation? location = await DesktopProjectorBridge.instance
            .runWithNativeDialog(
              () => showFileSavePanel(
                suggestedName: fileName,
                extensions: const <String>['png'],
              ),
            );
        if (location == null) {
          return;
        }
        await imageFile.saveTo(location.path);
        savedPath = location.path;
      }

      if (!sectionContext.mounted) {
        return;
      }
      await _showInternetResultDialog(
        l10n.savedPath(formatFriendlyPathLabel(savedPath, l10n)),
      );
    } catch (error) {
      if (!sectionContext.mounted) {
        return;
      }
      await _showInternetResultDialog(
        l10n.internetRelayQrSaveFailed(error.toString()),
      );
    }
  }

  Future<String?> _saveInternetQrWithAndroidSystemDialog({
    required String fileName,
    required Uint8List bytes,
  }) {
    return _androidBackupSaveChannel.invokeMethod<String>(
      'saveDiaFile',
      <String, Object?>{'fileName': fileName, 'bytes': bytes},
    );
  }

  Future<String> _saveInternetQrToDocumentsDirectory({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final String documentsPath = await PathHelper.getDocumentsDirectoryPath();
    final String exportPath = '$documentsPath/diatar/$fileName';
    final File exportFile = FileSystemProvider.instance.file(exportPath);
    await exportFile.parent.create(recursive: true);
    await exportFile.writeAsBytes(bytes, flush: true);
    return exportPath;
  }

  Future<void> _runUserApiAction({
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    if (_internetActionRunning) {
      return;
    }
    _setInternetActionRunning(true);
    try {
      await action();
      if (!mounted) {
        return;
      }
      await _showInternetResultDialog(successMessage);
    } catch (e) {
      if (!mounted) {
        return;
      }
      final AppLocalizations l10n = context.l10n;
      await _showInternetResultDialog(
        l10n.userApiError(_mapUserApiErrorMessage(error: e, l10n: l10n)),
      );
    } finally {
      _setInternetActionRunning(false);
    }
  }

  String _mapUserApiErrorMessage({
    required Object error,
    required AppLocalizations l10n,
  }) {
    if (error is MqttUserApiException) {
      if (error.statusCode == 401) {
        return l10n.userApiUnauthorized;
      }
      return error.message.trim().isEmpty
          ? l10n.userApiUnknownError
          : error.message;
    }

    final String message = error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();
    if (message.isEmpty) {
      return l10n.userApiUnknownError;
    }
    return message;
  }

  void _setInternetActionRunning(bool value) {
    final void Function(void Function())? setInternetSectionState =
        _setInternetSectionState;
    if (setInternetSectionState != null) {
      setInternetSectionState(() => _internetActionRunning = value);
      return;
    }
    if (mounted) {
      setState(() => _internetActionRunning = value);
    }
  }

  Future<void> _openLocalNetworkSettings() {
    final bool originalLocalNetworkEnabled = _localNetworkEnabled;
    final String originalTcpTargets = _tcpTargets.text;
    final bool originalShowCameraView = _showCameraView;
    final String? originalCameraTarget = _cameraTarget;

    return _openSectionSheet(
      title: context.l10n.settingsLocalNetworkTitle,
      isDismissible: false,
      enableDrag: false,
      showCancelButton: true,
      onConfirmClose: _applyNetworkSettings,
      onCancel: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _localNetworkEnabled = originalLocalNetworkEnabled;
          _tcpTargets.text = originalTcpTargets;
          _showCameraView = originalShowCameraView;
          _cameraTarget = originalCameraTarget;
        });
      },
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final l10n = context.l10n;
        final List<String> tcpTargets = _parseTcpTargets(_tcpTargets.text);
        return <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _localNetworkEnabled,
            onChanged: (bool v) => setBoth(() => _localNetworkEnabled = v),
            title: Text(l10n.localNetworkRelaySwitchTitle),
          ),
          TextField(
            controller: _tcpTargets,
            enabled: _localNetworkEnabled,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: l10n.tcpTargetsLabel,
              hintText: l10n.tcpTargetsHint,
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tcpTargetsHelp,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_isCameraViewSupported()) ...<Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showCameraView,
              onChanged: (bool v) => setBoth(() => _showCameraView = v),
              title: Text(l10n.cameraViewTitle),
              subtitle: Text(l10n.cameraViewHint),
            ),
            if (_showCameraView) ...<Widget>[
              if (tcpTargets.length > 1)
                DropdownButtonFormField<String>(
                  initialValue:
                      _cameraTarget != null &&
                          tcpTargets.contains(_cameraTarget)
                      ? _cameraTarget
                      : tcpTargets.first,
                  decoration: InputDecoration(
                    labelText: l10n.cameraSourceLabel,
                  ),
                  items: List<DropdownMenuItem<String>>.generate(
                    tcpTargets.length,
                    (int i) => DropdownMenuItem<String>(
                      value: tcpTargets[i],
                      child: Text(tcpTargets[i]),
                    ),
                    growable: false,
                  ),
                  onChanged: (String? v) =>
                      setBoth(() => _cameraTarget = v ?? tcpTargets.first),
                ),
              const SizedBox(height: 8),
              Text(
                l10n.cameraSourceHelp,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ];
      },
    );
  }

  Future<void> _openWakeOnLanSettings() {
    final bool originalWolEnabled = _wolEnabled;
    final String originalWolTargets = _wolTargets.text;
    final String originalWolBroadcastAddress = _wolBroadcastAddress.text;
    final String originalWolPort = _wolPort.text;

    return _openSectionSheet(
      title: context.l10n.settingsWolTitle,
      isDismissible: false,
      enableDrag: false,
      showCancelButton: true,
      onConfirmClose: _applyWakeOnLanSettings,
      onCancel: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _wolEnabled = originalWolEnabled;
          _wolTargets.text = originalWolTargets;
          _wolBroadcastAddress.text = originalWolBroadcastAddress;
          _wolPort.text = originalWolPort;
        });
      },
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final l10n = context.l10n;
        final ThemeData theme = Theme.of(context);
        return <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _wolEnabled,
            onChanged: (bool v) => setBoth(() => _wolEnabled = v),
            title: Text(l10n.wolEnabledTitle),
            subtitle: Text(l10n.wolEnabledHint),
          ),
          if (_wolEnabled) ...<Widget>[
            const SizedBox(height: 8),
            TextField(
              controller: _wolTargets,
              keyboardType: TextInputType.multiline,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.wolTargetsLabel,
                hintText: l10n.wolTargetsHint,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.wolTargetsHelp,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _wolBroadcastAddress,
              decoration: InputDecoration(labelText: l10n.wolBroadcastLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _wolPort,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.wolPortLabel),
            ),
          ],
        ];
      },
    );
  }

  bool _applyWakeOnLanSettings() {
    final List<String> wolTargets = _parseWolTargets(_wolTargets.text);
    final String broadcast = _wolBroadcastAddress.text.trim();
    final int? port = int.tryParse(_wolPort.text.trim());
    if (_wolEnabled) {
      final String? error = _validateWolSettings(wolTargets, broadcast, port);
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return false;
      }
    }
    _wolTargets.text = wolTargets.join('\n');
    final AppSettings updated = widget.initialSettings.copyWith(
      wolEnabled: _wolEnabled,
      wolTargets: wolTargets,
      wolBroadcastAddress: broadcast.isEmpty
          ? widget.initialSettings.wolBroadcastAddress
          : broadcast,
      wolPort: port ?? widget.initialSettings.wolPort,
    );

    unawaited(_applySettingsSafely(updated));
    return true;
  }

  String? _validateWolSettings(
    List<String> targets,
    String broadcast,
    int? port,
  ) {
    final l10n = context.l10n;
    if (targets.isEmpty) {
      return l10n.wolNoTargets;
    }
    for (final String line in targets) {
      if (parseWolTarget(line) == null) {
        return l10n.wolInvalidTarget(line);
      }
    }
    if (!isValidIpv4(broadcast)) {
      return l10n.wolInvalidBroadcast;
    }
    if (port == null || port < 1 || port > 65535) {
      return l10n.wolInvalidPort;
    }
    return null;
  }

  bool _applyNetworkSettings() {
    final String mqttUser = _mqttUser.text.trim();
    final String mqttPassword = _internetRelayEnabled ? _mqttPassword.text : '';
    final List<String> tcpTargets = kIsWeb
        ? const <String>[]
        : _parseTcpTargets(_tcpTargets.text);
    final bool localNetworkEnabled = kIsWeb ? false : _localNetworkEnabled;
    final String? tcpError = localNetworkEnabled
        ? _validateTcpTargets(tcpTargets)
        : null;
    if (tcpError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tcpError)));
      return false;
    }
    _tcpTargets.text = tcpTargets.join('\n');

    final String? cameraTarget =
        _cameraTarget != null && tcpTargets.contains(_cameraTarget)
        ? _cameraTarget
        : (tcpTargets.isEmpty ? null : tcpTargets.first);

    final int firstPort = localNetworkEnabled
        ? (_firstPortFromTargets(tcpTargets) ?? widget.initialSettings.port)
        : widget.initialSettings.port;

    final AppSettings updated = widget.initialSettings.copyWith(
      port: firstPort,
      tcpClientEnabled: localNetworkEnabled,
      tcpTargets: tcpTargets,
      showCameraView: kIsWeb ? false : _showCameraView,
      cameraTarget: kIsWeb ? null : cameraTarget,
      internetRelayEnabled: _internetRelayEnabled,
      mqttUser: mqttUser,
      mqttPassword: mqttPassword,
      mqttChannel: '1',
    );

    unawaited(_applySettingsSafely(updated));
    return true;
  }

  Future<void> _openApiKeysSettings() {
    final String originalSzentirasApiKey = _szentirasApiKey.text;

    return _openSectionSheet(
      title: context.l10n.settingsApiKeysTitle,
      showCancelButton: true,
      onConfirmClose: _applyApiKeysSettings,
      onCancel: () {
        if (!mounted) {
          return;
        }
        if (_picPlcEnabled && _picPlcPort.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.picPlcPortRequired)),
          );
          return;
        }
        setState(() {
          _szentirasApiKey.text = originalSzentirasApiKey;
        });
      },
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final l10n = context.l10n;
        return <Widget>[
          TextField(
            controller: _szentirasApiKey,
            onChanged: (_) => setBoth(() {}),
            decoration: InputDecoration(
              labelText: l10n.settingsSzentirasApiKeyLabel,
              hintText: l10n.settingsSzentirasApiKeyHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.szentirasApiKeyHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];
      },
    );
  }

  bool _applyApiKeysSettings() {
    final AppSettings updated = widget.initialSettings.copyWith(
      szentirasApiKey: _szentirasApiKey.text.trim(),
    );

    unawaited(_applySettingsSafely(updated));
    return true;
  }

  Future<void> _openGeneralSettings() {
    return _openSectionSheet(
      title: context.l10n.settingsGeneralTitle,
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final l10n = context.l10n;
        return <Widget>[
          DropdownButtonFormField<int>(
            initialValue: _appThemeMode,
            decoration: InputDecoration(labelText: l10n.uiTheme),
            items: <DropdownMenuItem<int>>[
              DropdownMenuItem<int>(value: 0, child: Text(l10n.themeDark)),
              DropdownMenuItem<int>(value: 1, child: Text(l10n.themeLight)),
            ],
            onChanged: (int? v) => setBoth(() => _appThemeMode = v ?? 0),
          ),
          DropdownButtonFormField<String>(
            initialValue: _appLanguage,
            decoration: InputDecoration(labelText: l10n.uiLanguage),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: '',
                child: Text(l10n.languageSystem),
              ),
              ...AppLocalizations.supportedLocales.map((Locale locale) {
                final String code = locale.languageCode;
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(_languageLabel(context, code)),
                );
              }),
            ],
            onChanged: (String? v) => setBoth(() => _appLanguage = v ?? ''),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.customOrderSetCount),
            subtitle: Slider(
              value: _maxCustomOrderSets.toDouble(),
              min: AppSettings.minCustomOrderSets.toDouble(),
              max: AppSettings.maxCustomOrderSetsLimit.toDouble(),
              divisions:
                  AppSettings.maxCustomOrderSetsLimit -
                  AppSettings.minCustomOrderSets,
              label: _maxCustomOrderSets.toString(),
              onChanged: (double value) =>
                  setBoth(() => _maxCustomOrderSets = value.round()),
            ),
            trailing: Text(_maxCustomOrderSets.toString()),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _useSound,
            onChanged: (bool v) => setBoth(() => _useSound = v),
            title: Text(l10n.useSound),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _advanceAfterMusic,
            onChanged: _useSound
                ? (bool v) => setBoth(() => _advanceAfterMusic = v)
                : null,
            title: Text(l10n.advanceAfterMusic),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _projUseAkkord,
            onChanged: (bool v) => setBoth(() => _projUseAkkord = v),
            title: Text(l10n.showChords),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _projUseKotta,
            onChanged: (bool v) => setBoth(() => _projUseKotta = v),
            title: Text(l10n.showKotta),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _projInverseKotta,
            onChanged: _projUseKotta
                ? (bool v) => setBoth(() => _projInverseKotta = v)
                : null,
            title: Text(l10n.inverseKottaColors),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _projShowBackgroundImage,
            onChanged: (bool v) => setBoth(() => _projShowBackgroundImage = v),
            title: Text(l10n.showBackgroundImage),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _homeShowHighlightControls,
            onChanged: (bool v) =>
                setBoth(() => _homeShowHighlightControls = v),
            title: Text(l10n.wordHighlight),
          ),
        ];
      },
    );
  }

  Future<void> _openExternalCommandSettings() {
    final String originalOnStart = _externalCommandOnStart.text;
    final String originalOnExit = _externalCommandOnExit.text;
    final String originalOnProjectionOn = _externalCommandOnProjectionOn.text;
    final String originalOnProjectionOff = _externalCommandOnProjectionOff.text;

    return _openSectionSheet(
      title: context.l10n.externalCommandsTitle,
      showCancelButton: true,
      onConfirmClose: _applyExternalCommandSettings,
      onCancel: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _externalCommandOnStart.text = originalOnStart;
          _externalCommandOnExit.text = originalOnExit;
          _externalCommandOnProjectionOn.text = originalOnProjectionOn;
          _externalCommandOnProjectionOff.text = originalOnProjectionOff;
        });
      },
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final l10n = context.l10n;
        return <Widget>[
          Text(_externalCommandsHint(l10n)),
          const SizedBox(height: 8),
          _externalCommandField(
            controller: _externalCommandOnStart,
            label: l10n.externalCommandOnStart,
            setBoth: setBoth,
          ),
          const SizedBox(height: 8),
          _externalCommandField(
            controller: _externalCommandOnExit,
            label: l10n.externalCommandOnExit,
            setBoth: setBoth,
          ),
          const SizedBox(height: 8),
          _externalCommandField(
            controller: _externalCommandOnProjectionOn,
            label: l10n.externalCommandOnProjectionOn,
            setBoth: setBoth,
          ),
          const SizedBox(height: 8),
          _externalCommandField(
            controller: _externalCommandOnProjectionOff,
            label: l10n.externalCommandOnProjectionOff,
            setBoth: setBoth,
          ),
        ];
      },
    );
  }

  Widget _externalCommandField({
    required TextEditingController controller,
    required String label,
    required void Function(void Function()) setBoth,
  }) {
    final bool hasCommand = controller.text.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: (_) => setBoth(() {}),
            decoration: InputDecoration(labelText: label),
          ),
        ),
        IconButton(
          tooltip: context.l10n.externalCommandClear,
          onPressed: hasCommand ? () => setBoth(controller.clear) : null,
          icon: const Icon(Icons.delete_outline),
        ),
        OutlinedButton(
          onPressed: hasCommand
              ? () => unawaited(_testExternalCommand(controller.text))
              : null,
          child: Text(context.l10n.externalCommandTest),
        ),
      ],
    );
  }

  Future<void> _testExternalCommand(String command) async {
    try {
      final ExternalCommandTestResult result = await _externalCommandService
          .test(command);
      if (!mounted) {
        return;
      }
      final l10n = context.l10n;
      final String message;
      if (result.succeeded) {
        message = l10n.externalCommandTestStarted;
      } else {
        final String error = result.errorOutput.trim().isEmpty
            ? l10n.externalCommandTestExitCode(result.exitCode!)
            : result.errorOutput.trim();
        message = l10n.externalCommandTestFailed(error);
      }
      await _showExternalCommandTestDialog(
        title: result.succeeded
            ? l10n.externalCommandTestSucceededTitle
            : l10n.externalCommandTestFailedTitle,
        message: message,
      );
    } on ProcessException catch (error) {
      if (!mounted) {
        return;
      }
      await _showExternalCommandTestDialog(
        title: context.l10n.externalCommandTestFailedTitle,
        message: context.l10n.externalCommandTestFailed('$error'),
      );
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      await _showExternalCommandTestDialog(
        title: context.l10n.externalCommandTestFailedTitle,
        message: context.l10n.externalCommandTestFailed('$error'),
      );
    } on ExternalCommandException catch (error) {
      if (!mounted) {
        return;
      }
      await _showExternalCommandTestDialog(
        title: context.l10n.externalCommandTestFailedTitle,
        message: context.l10n.externalCommandTestFailed('$error'),
      );
    }
  }

  Future<void> _showExternalCommandTestDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.ok),
            ),
          ],
        );
      },
    );
  }

  bool _applyExternalCommandSettings() {
    final AppSettings updated = widget.initialSettings.copyWith(
      externalCommandOnStart: _externalCommandOnStart.text.trim(),
      externalCommandOnExit: _externalCommandOnExit.text.trim(),
      externalCommandOnProjectionOn: _externalCommandOnProjectionOn.text.trim(),
      externalCommandOnProjectionOff: _externalCommandOnProjectionOff.text
          .trim(),
    );
    unawaited(_applySettingsSafely(updated));
    return true;
  }

  Future<void> _openSystemActions() {
    return _openSectionSheet(
      title: context.l10n.systemActionsTitle,
      closeButtonLabel: context.l10n.systemActionsBack,
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final l10n = context.l10n;
        return <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton(
                onPressed: widget.onExitRequested,
                child: Text(l10n.localExit),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (mounted) {
                    Navigator.of(this.context).pop();
                  }
                  widget.onReloadBooksRequested();
                },
                child: Text(l10n.refreshTooltip),
              ),
              OutlinedButton(
                onPressed: widget.onRemoteStopRequested,
                child: Text(l10n.remoteProgramStop),
              ),
              OutlinedButton(
                onPressed: widget.onRemoteShutdownRequested,
                child: Text(l10n.remoteMachineStop),
              ),
            ],
          ),
        ];
      },
    );
  }

  Future<void> _openMicDeviceSelector(
    void Function(void Function()) setBoth,
  ) async {
    final l10n = context.l10n;
    final RecordAudioCapture capture = RecordAudioCapture();
    try {
      final bool hasPerm = await capture.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.liveSubtitlesError)));
        }
        return;
      }
      final List<InputDevice> devices = await capture.listInputDevices();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return SimpleDialog(
            title: Text(l10n.liveSubtitlesMicDevice),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  setBoth(() => _liveSubtitleDeviceId = null);
                  Navigator.of(dialogContext).pop();
                },
                child: Row(
                  children: <Widget>[
                    Icon(
                      _liveSubtitleDeviceId == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.liveSubtitlesMicDeviceDefault)),
                  ],
                ),
              ),
              for (final InputDevice device in devices)
                SimpleDialogOption(
                  onPressed: () {
                    setBoth(() => _liveSubtitleDeviceId = device.id);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Row(
                    children: <Widget>[
                      Icon(
                        _liveSubtitleDeviceId == device.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(device.label)),
                    ],
                  ),
                ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('[Settings] Failed to list mic devices: $e');
    } finally {
      await capture.dispose();
    }
  }

  Future<void> _openSpeechSettings() {
    return _openSectionSheet(
      title: context.l10n.speechSettingsTitle,
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final l10n = context.l10n;
        final SpeechModelInfo currentModel = getSpeechModel(
          SpeechModelType.values.firstWhere(
            (e) => e.name == _liveSubtitleModel,
            orElse: () => SpeechModelType.nemotron35_560ms,
          ),
        );
        return <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.speechFeatureEnabled),
            value: _speechFeatureVisible,
            onChanged: (bool v) {
              setBoth(() => _speechFeatureVisible = v);
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.record_voice_over),
            title: Text(l10n.speechModelTitle),
            subtitle: Text(currentModel.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openModelSelector(setBoth),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mic),
            title: Text(l10n.liveSubtitlesMicDevice),
            subtitle: Text(
              _liveSubtitleDeviceId == null
                  ? l10n.liveSubtitlesMicDeviceDefault
                  : _liveSubtitleDeviceId!,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openMicDeviceSelector(setBoth),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(l10n.speechLanguageTitle),
            subtitle: Text(_speechLanguageName(_liveSubtitleLanguage, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openLanguageSelector(setBoth),
          ),
          const Divider(height: 1),
        ];
      },
    );
  }

  static const _speechLanguageCodes = <String>[
    'auto',
    'es-US',
    'es-ES',
    'it-IT',
    'pt-BR',
    'pt-PT',
    'hi-IN',
    'ko-KR',
    'en-US',
    'en-GB',
    'de-DE',
    'fr-FR',
    'fr-CA',
    'ru-RU',
    'tr-TR',
    'vi-VN',
    'nl-NL',
    'ja-JP',
    'ar-AR',
    'uk-UA',
    'pl-PL',
    'nb-NO',
    'fi-FI',
    'zh-CN',
    'cs-CZ',
    'bg-BG',
    'sk-SK',
    'sv-SE',
    'hr-HR',
    'ro-RO',
    'et-EE',
    'da-DK',
    'hu-HU',
  ];

  String _speechLanguageName(String code, AppLocalizations l10n) {
    switch (code) {
      case 'auto':
        return l10n.speechLangAuto;
      case 'es-US':
        return l10n.speechLangEsUS;
      case 'es-ES':
        return l10n.speechLangEsES;
      case 'it-IT':
        return l10n.speechLangItIT;
      case 'pt-BR':
        return l10n.speechLangPtBR;
      case 'pt-PT':
        return l10n.speechLangPtPT;
      case 'hi-IN':
        return l10n.speechLangHiIN;
      case 'ko-KR':
        return l10n.speechLangKoKR;
      case 'en-US':
        return l10n.speechLangEnUS;
      case 'en-GB':
        return l10n.speechLangEnGB;
      case 'de-DE':
        return l10n.speechLangDeDE;
      case 'fr-FR':
        return l10n.speechLangFrFR;
      case 'fr-CA':
        return l10n.speechLangFrCA;
      case 'ru-RU':
        return l10n.speechLangRuRU;
      case 'tr-TR':
        return l10n.speechLangTrTR;
      case 'vi-VN':
        return l10n.speechLangViVN;
      case 'nl-NL':
        return l10n.speechLangNlNL;
      case 'ja-JP':
        return l10n.speechLangJaJP;
      case 'ar-AR':
        return l10n.speechLangArAR;
      case 'uk-UA':
        return l10n.speechLangUkUA;
      case 'pl-PL':
        return l10n.speechLangPlPL;
      case 'nb-NO':
        return l10n.speechLangNbNO;
      case 'fi-FI':
        return l10n.speechLangFiFI;
      case 'zh-CN':
        return l10n.speechLangZhCN;
      case 'cs-CZ':
        return l10n.speechLangCsCZ;
      case 'bg-BG':
        return l10n.speechLangBgBG;
      case 'sk-SK':
        return l10n.speechLangSkSK;
      case 'sv-SE':
        return l10n.speechLangSvSE;
      case 'hr-HR':
        return l10n.speechLangHrHR;
      case 'ro-RO':
        return l10n.speechLangRoRO;
      case 'et-EE':
        return l10n.speechLangEtEE;
      case 'da-DK':
        return l10n.speechLangDaDK;
      case 'hu-HU':
        return l10n.speechLangHuHU;
      default:
        return code;
    }
  }

  Future<void> _openLanguageSelector(void Function(void Function()) setBoth) {
    final l10n = context.l10n;
    return _openSectionSheet(
      title: l10n.speechLanguageTitle,
      builder:
          (BuildContext context, void Function(void Function()) setModalBoth) {
            return <Widget>[
              RadioGroup<String>(
                groupValue: _liveSubtitleLanguage,
                onChanged: (String? value) {
                  if (value != null) {
                    setBoth(() => _liveSubtitleLanguage = value);
                    setModalBoth(() {});
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.speechLangAuto),
                      value: 'auto',
                    ),
                    for (final code in _speechLanguageCodes)
                      if (code != 'auto')
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_speechLanguageName(code, l10n)),
                          value: code,
                        ),
                  ],
                ),
              ),
            ];
          },
    );
  }

  Future<void> _openModelSelector(void Function(void Function()) setBoth) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return AlertDialog(
              title: Text(l10n.speechModelTitle),
              content: SizedBox(
                width: double.maxFinite,
                child: _ModelSelectorContent(
                  liveSubtitleModel: _liveSubtitleModel,
                  onChanged: (String v) {
                    setBoth(() => _liveSubtitleModel = v);
                    setModalState(() {});
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openImpresszumSheet() {
    final l10n = context.l10n;
    return _openSectionSheet(
      title: l10n.impresszumTitle,
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        return <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.asset(
                'assets/hackathon_logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _impresszumSection(
            l10n.impresszumDevelopers,
            l10n.impresszumDevelopersBody,
          ),
          _impresszumLink(
            label: l10n.impresszumHackathonTitle,
            subtitle: l10n.impresszumHackathonBody,
            url: 'https://szentjozsef.jezsuita.hu/szent-jozsef-hackathon/',
          ),
          const Divider(height: 1),
          _impresszumSection(
            l10n.impresszumDataSources,
            l10n.impresszumSzentiras,
          ),
          _impresszumLink(
            label: l10n.impresszumSzentirasLink,
            subtitle: 'szentiras.eu',
            url: 'https://szentiras.eu',
          ),
          const Divider(height: 1),
          _impresszumSection(l10n.impresszumLicenses, null),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.impresszumNemotron),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.impresszumSherpaOnnx),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.impresszumFlutter),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.impresszumRecord),
          ),
          const Divider(height: 1),
          _impresszumSection(l10n.impresszumLinks, null),
          _impresszumLink(
            label: l10n.impresszumWebsite,
            subtitle: 'diatar.eu',
            url: 'https://www.diatar.eu',
          ),
          _impresszumLink(
            label: l10n.impresszumGitHub,
            subtitle: 'github.com/diatar-eu/diatar-flutter',
            url: 'https://github.com/diatar-eu/diatar-flutter',
          ),
          _impresszumLink(
            label: l10n.impresszumHackathonLink,
            subtitle: 'szentjozsef.jezsuita.hu',
            url: 'https://szentjozsef.jezsuita.hu/szent-jozsef-hackathon/',
          ),
        ];
      },
    );
  }

  Widget _impresszumSection(String title, String? body) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (body != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _impresszumLink({
    required String label,
    required String subtitle,
    required String url,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => launchUrl(Uri.parse(url)),
    );
  }

  Future<void> _openFileSettings() {
    return _openSectionSheet(
      title: context.l10n.settingsFilesTitle,
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final l10n = context.l10n;
        return <Widget>[
          _buildPathPickerRow(
            l10n: l10n,
            label: l10n.blankImagePath,
            rawPath: _blankPicPath.text.trim(),
            onPick: () async {
              await _pickBlankFile();
              setBoth(() {});
            },
            onClear: () {
              _clearBlankImage();
              setBoth(() {});
            },
          ),
          if (_isDesktopPlatform())
            _buildPathPickerRow(
              l10n: l10n,
              label: l10n.diaExportFolderPath,
              rawPath: _diaExportPath.text.trim(),
              onPick: () async {
                await _pickDiaExportFolder();
                setBoth(() {});
              },
            ),
          if (_isDesktopPlatform())
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.diaAutoSave),
              value: _diaAutoSaveEnabled,
              onChanged: (bool value) {
                setBoth(() => _diaAutoSaveEnabled = value);
              },
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            l10n.diatarDataTransferTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.diatarDataTransferDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _fileTransferRunning
                    ? null
                    : () => _exportDiatarData(context, setBoth),
                icon: const Icon(Icons.archive_outlined),
                label: Text(l10n.diatarExportButton),
              ),
              OutlinedButton.icon(
                onPressed: _fileTransferRunning
                    ? null
                    : () => _importDiatarData(context, setBoth),
                icon: const Icon(Icons.unarchive_outlined),
                label: Text(l10n.diatarImportButton),
              ),
            ],
          ),
          if (_fileTransferRunning) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 16),
          if (_isDesktopPlatform())
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_open),
              title: Text(l10n.openDtxFolder),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openDtxFolder,
            ),
        ];
      },
    );
  }

  Future<void> _exportDiatarData(
    BuildContext sectionContext,
    void Function(void Function()) setBoth,
  ) async {
    setBoth(() => _fileTransferRunning = true);
    widget.onFileTransferProgress?.call(0);
    String? tempExportDir;
    final String fileName = _backupFileName(DateTime.now());
    String savedFileName = fileName;
    final DiatarTransferCancellationToken cancellationToken =
        DiatarTransferCancellationToken();
    final ValueNotifier<_DiatarTransferProgress> progress =
        ValueNotifier<_DiatarTransferProgress>(
          _DiatarTransferProgress(fileName: fileName),
        );
    _showDiatarTransferProgressDialog(
      sectionContext,
      progress: progress,
      cancellationToken: cancellationToken,
    );
    // A vezérlőablakot előrehozzuk, hogy a (macOS-on `runModal` alapú)
    // mentési panel megbízhatóan megjelenhessen; a vetítőablak jelenléte
    // nem zavarja, mivel a panel a fájlpárbeszédablak felett jelenik meg.
    await DesktopProjectorBridge.instance.prepareForNativeDialog();
    try {
      if (kIsWeb) {
        final Uint8List zipData = await _exportImportService
            .createExportArchive();
        final XFile exportFile = XFile.fromData(
          zipData,
          mimeType: 'application/zip',
          name: fileName,
        );
        await exportFile.saveTo(fileName);
      } else {
        final String zipPath = await _exportImportService
            .createExportArchiveFile(
              onProgress: (double value) {
                _updateDiatarTransferProgress(progress, value * 0.5);
              },
              onEntry: (String entryName) {
                _updateDiatarTransferProgress(
                  progress,
                  progress.value.progress,
                  entryName,
                );
              },
              cancellationToken: cancellationToken,
            );
        tempExportDir = FileSystemProvider.instance.file(zipPath).parent.path;
        if (defaultTargetPlatform == TargetPlatform.android) {
          try {
            final String? savedPath =
                await _saveDiatarBackupWithAndroidSystemDialog(
                  fileName: fileName,
                  sourcePath: zipPath,
                  onProgress: (double value) {
                    _updateDiatarTransferProgress(
                      progress,
                      0.5 + (value * 0.5),
                    );
                  },
                );
            if (savedPath == null) {
              return;
            }
            savedFileName = savedPath;
          } on MissingPluginException {
            await _saveDiatarBackupToDocumentsDirectory(
              fileName: fileName,
              sourcePath: zipPath,
            );
          }
        } else {
          final FileSaveLocation? location = await showFileSavePanel(
            suggestedName: fileName,
            extensions: const <String>['zip'],
          );
          if (location == null) {
            return;
          }
          await FileSystemProvider.instance.file(zipPath).copy(location.path);
          savedFileName = FileSystemProvider.instance.path.basename(
            location.path,
          );
        }
      }

      if (sectionContext.mounted) {
        await _showFileTransferMessage(
          sectionContext,
          sectionContext.l10n.diatarExportSuccess(savedFileName),
        );
      }
    } catch (error) {
      if (sectionContext.mounted) {
        await _showFileTransferError(sectionContext, error);
      }
    } finally {
      if (tempExportDir != null) {
        try {
          final Directory tempDir = FileSystemProvider.instance.directory(
            tempExportDir,
          );
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } catch (_) {
          // Ignore temp cleanup failures.
        }
      }
      // A fájlművelet (mentési panel, másolás) végeztével visszaállítjuk
      // a vezérlőablak fókuszát és a vetítőablak megjelenését.
      await DesktopProjectorBridge.instance.releaseFromNativeDialog();
      if (sectionContext.mounted) {
        _closeDiatarTransferProgressDialog(sectionContext);
      }
      progress.dispose();
      _finishFileTransfer(sectionContext.mounted, setBoth);
    }
  }

  Future<String?> _saveDiatarBackupWithAndroidSystemDialog({
    required String fileName,
    required String sourcePath,
    required ValueChanged<double> onProgress,
  }) async {
    _androidBackupSaveProgressChannel.setMethodCallHandler((
      MethodCall call,
    ) async {
      if (call.method != 'backupSaveProgress') {
        return;
      }
      final Map<Object?, Object?> values = Map<Object?, Object?>.from(
        call.arguments as Map,
      );
      final int writtenBytes = values['writtenBytes']! as int;
      final int totalBytes = values['totalBytes']! as int;
      if (totalBytes > 0) {
        onProgress(writtenBytes / totalBytes);
      }
    });
    try {
      return await _androidBackupSaveChannel.invokeMethod<String>(
        'saveBackupFile',
        <String, Object?>{'fileName': fileName, 'path': sourcePath},
      );
    } finally {
      _androidBackupSaveProgressChannel.setMethodCallHandler(null);
    }
  }

  Future<void> _saveDiatarBackupToDocumentsDirectory({
    required String fileName,
    required String sourcePath,
  }) async {
    final String documentsPath = await PathHelper.getDocumentsDirectoryPath();
    final String exportPath = '$documentsPath/diatar/$fileName';
    final File exportFile = FileSystemProvider.instance.file(exportPath);
    await exportFile.parent.create(recursive: true);
    await FileSystemProvider.instance.file(sourcePath).copy(exportPath);
  }

  Future<void> _importDiatarData(
    BuildContext sectionContext,
    void Function(void Function()) setBoth,
  ) async {
    String? tempArchivePath;
    setBoth(() => _fileTransferRunning = true);
    widget.onFileTransferProgress?.call(0);
    DiatarTransferCancellationToken? cancellationToken;
    ValueNotifier<_DiatarTransferProgress>? progress;
    try {
      final List<XFile> selectedFiles = await DesktopProjectorBridge.instance
          .runWithNativeDialog(
            () => showFileOpenPanel(extensions: const <String>['zip']),
          );
      final XFile? selectedFile = selectedFiles.isEmpty
          ? null
          : selectedFiles.first;
      if (selectedFile == null) {
        return;
      }
      cancellationToken = DiatarTransferCancellationToken();
      progress = ValueNotifier<_DiatarTransferProgress>(
        _DiatarTransferProgress(fileName: selectedFile.name),
      );
      final ValueNotifier<_DiatarTransferProgress> transferProgress = progress;
      if (!sectionContext.mounted) {
        return;
      }
      _showDiatarTransferProgressDialog(
        sectionContext,
        progress: transferProgress,
        cancellationToken: cancellationToken,
      );

      final String selectedPath = selectedFile.path.trim();
      final bool hasDirectPath =
          !kIsWeb && selectedPath.isNotEmpty && !selectedPath.contains('://');

      Uint8List? zipData;
      final String? importPath;
      if (kIsWeb) {
        importPath = null;
        zipData = await selectedFile.readAsBytes();
      } else if (hasDirectPath) {
        importPath = selectedPath;
      } else {
        final File tempArchive = await _createTempImportArchive(selectedFile);
        tempArchivePath = tempArchive.path;
        importPath = tempArchive.path;
      }

      final DiatarImportResult result = importPath != null
          ? await _exportImportService.importArchiveFile(
              importPath,
              onProgress: (double value) {
                _updateDiatarTransferProgress(transferProgress, value);
              },
              onEntry: (String entryName) {
                _updateDiatarTransferProgress(
                  transferProgress,
                  transferProgress.value.progress,
                  entryName,
                );
              },
              cancellationToken: cancellationToken,
            )
          : await _exportImportService.importArchive(
              zipData!,
              onProgress: (double value) {
                _updateDiatarTransferProgress(transferProgress, value);
              },
              onEntry: (String entryName) {
                _updateDiatarTransferProgress(
                  transferProgress,
                  transferProgress.value.progress,
                  entryName,
                );
              },
              cancellationToken: cancellationToken,
            );

      if (result.importedFileCount > 0) {
        widget.onReloadBooksRequested();
      }
      if (!sectionContext.mounted) {
        return;
      }

      if (result.isSuccess) {
        await _showFileTransferMessage(
          sectionContext,
          sectionContext.l10n.diatarImportSuccess(result.importedFileCount),
        );
      } else {
        await _showFileTransferError(sectionContext, result.errors.join('\n'));
      }
    } catch (error) {
      if (sectionContext.mounted) {
        await _showFileTransferError(sectionContext, error);
      }
    } finally {
      if (tempArchivePath != null) {
        final File tempArchive = FileSystemProvider.instance.file(
          tempArchivePath,
        );
        if (await tempArchive.exists()) {
          await tempArchive.delete();
        }
      }
      if (sectionContext.mounted) {
        _closeDiatarTransferProgressDialog(sectionContext);
      }
      progress?.dispose();
      _finishFileTransfer(sectionContext.mounted, setBoth);
    }
  }

  Future<File> _createTempImportArchive(XFile selectedFile) async {
    final FileSystem fs = FileSystemProvider.instance;
    final Directory tempDir = fs.systemTempDirectory;
    await tempDir.create(recursive: true);
    final String tempPath = fs.path.join(
      tempDir.path,
      'diatar-import-${DateTime.now().microsecondsSinceEpoch}.zip',
    );
    final File tempFile = fs.file(tempPath);
    final sink = tempFile.openWrite();
    await for (final chunk in selectedFile.openRead()) {
      sink.add(chunk);
      await sink.flush();
    }
    await sink.close();
    return tempFile;
  }

  Future<void> _showFileTransferError(
    BuildContext sectionContext,
    Object error,
  ) async {
    if (!sectionContext.mounted) {
      return;
    }
    final AppLocalizations l10n = sectionContext.l10n;
    final String message;
    if (error is DiatarArchiveException) {
      message = switch (error.code) {
        DiatarArchiveErrorCode.sourceDirectoryMissing =>
          l10n.diatarExportSourceMissing,
        DiatarArchiveErrorCode.invalidArchive =>
          l10n.diatarImportInvalidArchive,
        DiatarArchiveErrorCode.cancelled => l10n.diatarTransferCancelled,
      };
    } else {
      message = l10n.diatarTransferError(error.toString());
    }

    await showDialog<void>(
      context: sectionContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.diatarDataTransferTitle),
          content: SingleChildScrollView(child: Text(message)),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }

  void _updateDiatarTransferProgress(
    ValueNotifier<_DiatarTransferProgress> progress,
    double value, [
    String? entryName,
  ]) {
    progress.value = progress.value.copyWith(
      progress: value,
      entryName: entryName,
    );
    widget.onFileTransferProgress?.call(value);
  }

  void _showDiatarTransferProgressDialog(
    BuildContext sectionContext, {
    required ValueNotifier<_DiatarTransferProgress> progress,
    required DiatarTransferCancellationToken cancellationToken,
  }) {
    unawaited(
      showDialog<void>(
        context: sectionContext,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          final AppLocalizations l10n = dialogContext.l10n;
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(l10n.diatarDataTransferTitle),
              content: ValueListenableBuilder<_DiatarTransferProgress>(
                valueListenable: progress,
                builder:
                    (
                      BuildContext context,
                      _DiatarTransferProgress value,
                      Widget? child,
                    ) {
                      final int percent = (value.progress * 100).round();
                      return SizedBox(
                        width: 360,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(l10n.diatarTransferArchive(value.fileName)),
                            const SizedBox(height: 12),
                            Text(
                              l10n.diatarTransferCurrentFile(
                                value.entryName ?? '-',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: value.progress),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(l10n.diatarTransferProgress(percent)),
                            ),
                          ],
                        ),
                      );
                    },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: cancellationToken.isCancelled
                      ? null
                      : cancellationToken.cancel,
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _closeDiatarTransferProgressDialog(BuildContext sectionContext) {
    if (sectionContext.mounted) {
      Navigator.of(sectionContext, rootNavigator: true).pop();
    }
  }

  Future<void> _showFileTransferMessage(
    BuildContext sectionContext,
    String message,
  ) {
    return showDialog<void>(
      context: sectionContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.diatarDataTransferTitle),
        content: Text(message),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.ok),
          ),
        ],
      ),
    );
  }

  void _finishFileTransfer(
    bool sectionMounted,
    void Function(void Function()) setBoth,
  ) {
    widget.onFileTransferProgress?.call(null);
    if (sectionMounted) {
      setBoth(() => _fileTransferRunning = false);
    } else if (mounted) {
      setState(() => _fileTransferRunning = false);
    } else {
      _fileTransferRunning = false;
    }
  }

  String _backupFileName(DateTime timestamp) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return 'diatar-backup-'
        '${timestamp.year}${twoDigits(timestamp.month)}'
        '${twoDigits(timestamp.day)}-'
        '${twoDigits(timestamp.hour)}${twoDigits(timestamp.minute)}.zip';
  }

  Future<void> _openDtxFolder() async {
    if (kIsWeb) {
      // On web, we can't open the file system folder.
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.openDtxFolderTooltip)),
      );
      return;
    }
    final String docsPath = await PathHelper.getDocumentsDirectoryPath();
    final Directory diatarsDir = FileSystemProvider.instance.directory(
      '$docsPath/diatar',
    );
    if (!await diatarsDir.exists()) {
      await diatarsDir.create(recursive: true);
    }
    final Uri uri = Uri.file(diatarsDir.path);
    if (!await launchUrl(uri)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.openDtxFolderTooltip)),
      );
    }
  }

  Widget _buildPathPickerRow({
    required AppLocalizations l10n,
    required String label,
    required String rawPath,
    String? helperText,
    required Future<void> Function() onPick,
    VoidCallback? onClear,
  }) {
    final String trimmed = rawPath.trim();
    final String friendly = trimmed.isEmpty
        ? l10n.valueNotSet
        : formatFriendlyPathLabel(trimmed, l10n);
    return Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            key: ValueKey<String>('path_$label|$trimmed'),
            initialValue: friendly,
            readOnly: true,
            decoration: InputDecoration(
              labelText: label,
              helperText: helperText,
            ),
          ),
        ),
        if (onClear != null && trimmed.isNotEmpty)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.blankImageDelete,
          ),
        IconButton(
          onPressed: () async {
            await onPick();
          },
          icon: const Icon(Icons.folder_open),
          tooltip: l10n.fileChoose,
        ),
      ],
    );
  }

  Future<void> _openDesktopHotkeySettings() {
    return _openSectionSheet(
      title: context.l10n.settingsDesktopHotkeysTitle,
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final AppLocalizations l10n = context.l10n;
        final List<MapEntry<String, String>> actions =
            <MapEntry<String, String>>[
              MapEntry<String, String>(
                'prevSong',
                l10n.settingsHotkeyActionPrevSong,
              ),
              MapEntry<String, String>(
                'prevVerse',
                l10n.settingsHotkeyActionPrevVerse,
              ),
              MapEntry<String, String>(
                'toggleProjection',
                l10n.settingsHotkeyActionToggleProjection,
              ),
              MapEntry<String, String>(
                'nextVerse',
                l10n.settingsHotkeyActionNextVerse,
              ),
              MapEntry<String, String>(
                'nextSong',
                l10n.settingsHotkeyActionNextSong,
              ),
              MapEntry<String, String>(
                'prevOrderSet',
                l10n.settingsHotkeyActionPrevOrderSet,
              ),
              MapEntry<String, String>(
                'nextOrderSet',
                l10n.settingsHotkeyActionNextOrderSet,
              ),
              MapEntry<String, String>(
                'highlightPrev',
                l10n.settingsHotkeyActionHighlightPrev,
              ),
              MapEntry<String, String>(
                'highlightNext',
                l10n.settingsHotkeyActionHighlightNext,
              ),
              MapEntry<String, String>(
                'togglePhoto',
                l10n.settingsHotkeyActionTogglePhoto,
              ),
              MapEntry<String, String>(
                'toggleChords',
                l10n.settingsHotkeyActionToggleChords,
              ),
              MapEntry<String, String>(
                'toggleBackground',
                l10n.settingsHotkeyActionToggleBackground,
              ),
              MapEntry<String, String>(
                'toggleSheetMusic',
                l10n.settingsHotkeyActionToggleSheetMusic,
              ),
              MapEntry<String, String>(
                'homeBooks',
                l10n.settingsHotkeyActionHomeBooks,
              ),
              MapEntry<String, String>(
                'homeDialist',
                l10n.settingsHotkeyActionHomeDialist,
              ),
              MapEntry<String, String>(
                'homePresentation',
                l10n.settingsHotkeyActionHomePresentation,
              ),
            ];

        return <Widget>[
          Text(
            l10n.settingsHotkeysActionsSectionTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...actions.map((MapEntry<String, String> entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.value,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            _desktopActionHotkeys[entry.key] ??
                                '(${l10n.valueNotSet})',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          final String? captured =
                              await _showHotkeyCaptureDialog(context);
                          if (captured != null) {
                            setBoth(() {
                              _desktopActionHotkeys[entry.key] = captured;
                            });
                          }
                        },
                        icon: const Icon(Icons.keyboard),
                        label: Text(l10n.settingsHotkeyCapture),
                      ),
                      const SizedBox(width: 8),
                      if (_desktopActionHotkeys[entry.key] != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: l10n.settingsHotkeyClear,
                          onPressed: () {
                            setBoth(() {
                              _desktopActionHotkeys.remove(entry.key);
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 20),
          Text(
            l10n.settingsHotkeysSongsSectionTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_availableSongsResolved && _availableSongs.isEmpty)
            Text(l10n.settingsHotkeysNoSongs),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.music_note_outlined),
            title: Text(l10n.songLabel),
            subtitle: Text(
              _selectedSongHotkeyOptionId.isEmpty
                  ? l10n.valueNotSet
                  : _songLabelForId(_selectedSongHotkeyOptionId),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: FilledButton.tonalIcon(
              onPressed: () async {
                final SongHotkeyOption? selected = await _pickSongHotkeyOption(
                  context,
                );
                if (selected == null) {
                  return;
                }
                setBoth(() {
                  _selectedSongHotkeyOptionId = selected.id;
                });
              },
              icon: const Icon(Icons.search),
              label: Text(l10n.fileChoose),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: _selectedSongHotkeyOptionId.isEmpty
                  ? null
                  : () async {
                      final String? captured = await _showHotkeyCaptureDialog(
                        context,
                      );
                      if (captured != null) {
                        setBoth(() {
                          _desktopSongHotkeys[captured] =
                              _selectedSongHotkeyOptionId;
                        });
                      }
                    },
              icon: const Icon(Icons.keyboard),
              label: Text(l10n.settingsHotkeyCapture),
            ),
          ),
          if (_desktopSongHotkeys.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            ..._desktopSongHotkeys.entries.map((
              MapEntry<String, String> entry,
            ) {
              final String label = _songLabelForId(entry.value);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key),
                subtitle: Text(label),
                trailing: IconButton(
                  tooltip: l10n.settingsHotkeyDelete,
                  onPressed: () {
                    setBoth(() {
                      _desktopSongHotkeys.remove(entry.key);
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            }),
          ],
          const Divider(height: 20),
          Text(
            l10n.settingsDesktopOrderSetHotkeysTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_availableOrderSetsResolved && _availableOrderSets.isEmpty)
            Text(l10n.settingsHotkeysNoOrderSets),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.list),
            title: Text(l10n.settingsOrderSetLabel),
            subtitle: Text(
              _selectedOrderSetOptionId.isEmpty
                  ? l10n.valueNotSet
                  : _orderSetLabelForId(_selectedOrderSetOptionId),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: FilledButton.tonalIcon(
              onPressed: () async {
                final CustomOrderSetOption? selected =
                    await _pickOrderSetOption(context);
                if (selected == null) {
                  return;
                }
                setBoth(() {
                  _selectedOrderSetOptionId = selected.id;
                });
              },
              icon: const Icon(Icons.search),
              label: Text(l10n.fileChoose),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: _selectedOrderSetOptionId.isEmpty
                  ? null
                  : () async {
                      final String? captured = await _showHotkeyCaptureDialog(
                        context,
                      );
                      if (captured != null) {
                        setBoth(() {
                          _desktopOrderSetHotkeys[captured] =
                              _selectedOrderSetOptionId;
                        });
                      }
                    },
              icon: const Icon(Icons.keyboard),
              label: Text(l10n.settingsHotkeyCapture),
            ),
          ),
          if (_desktopOrderSetHotkeys.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            ..._desktopOrderSetHotkeys.entries.map((
              MapEntry<String, String> entry,
            ) {
              final String label = _orderSetLabelForId(entry.value);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key),
                subtitle: Text(label),
                trailing: IconButton(
                  tooltip: l10n.settingsHotkeyDelete,
                  onPressed: () {
                    setBoth(() {
                      _desktopOrderSetHotkeys.remove(entry.key);
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            }),
          ],
        ];
      },
    );
  }

  void _ensureAvailableSongsLoaded() {
    if (_availableSongsResolved) {
      return;
    }
    _availableSongsResolved = true;
    final List<SongHotkeyOption> loaded =
        widget.availableSongsLoader?.call() ?? const <SongHotkeyOption>[];
    _availableSongs = loaded;
    if (_selectedSongHotkeyOptionId.isEmpty && _availableSongs.isNotEmpty) {
      _selectedSongHotkeyOptionId = _availableSongs.first.id;
    }
  }

  Future<SongHotkeyOption?> _pickSongHotkeyOption(BuildContext context) async {
    _ensureAvailableSongsLoaded();
    if (_availableSongs.isEmpty) {
      return null;
    }

    final AppLocalizations l10n = context.l10n;
    final TextEditingController search = TextEditingController();
    final List<String> lowerLabels = _availableSongs
        .map((SongHotkeyOption option) => option.label.toLowerCase())
        .toList(growable: false);
    List<int> filteredIndexes = List<int>.generate(
      _availableSongs.length,
      (int i) => i,
      growable: true,
    );

    final SongHotkeyOption? selected = await showDialog<SongHotkeyOption>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setStateDialog,
              ) {
                void applyFilter(String query) {
                  final String normalized = query.trim().toLowerCase();
                  if (normalized.isEmpty) {
                    setStateDialog(() {
                      filteredIndexes = List<int>.generate(
                        _availableSongs.length,
                        (int i) => i,
                        growable: true,
                      );
                    });
                    return;
                  }
                  setStateDialog(() {
                    final List<int> matches = <int>[];
                    for (int i = 0; i < lowerLabels.length; i++) {
                      if (lowerLabels[i].contains(normalized)) {
                        matches.add(i);
                      }
                    }
                    filteredIndexes = matches;
                  });
                }

                return AlertDialog(
                  title: Text(l10n.songLabel),
                  content: SizedBox(
                    width: 520,
                    height: 420,
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: search,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: l10n.settingsSearchLabel,
                          ),
                          onChanged: applyFilter,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemExtent: 40,
                            itemCount: filteredIndexes.length,
                            itemBuilder: (BuildContext context, int index) {
                              final SongHotkeyOption option =
                                  _availableSongs[filteredIndexes[index]];
                              return InkWell(
                                onTap: () => Navigator.of(context).pop(option),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      option.label,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ],
                );
              },
        );
      },
    );

    search.dispose();
    return selected;
  }

  bool _isDesktopPlatform() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  bool _isCameraViewSupported() {
    if (kIsWeb) {
      return false;
    }
    return _isDesktopPlatform() ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool _supportsHotkeysPlatform() {
    return kIsWeb || _isDesktopPlatform();
  }

  bool _supportsExternalCommandsPlatform() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String _externalCommandsDescription(AppLocalizations l10n) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return l10n.externalCommandsDescriptionAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return l10n.externalCommandsDescriptionIos;
    }
    return l10n.externalCommandsDescriptionDesktop;
  }

  String _externalCommandsHint(AppLocalizations l10n) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return l10n.externalCommandsHintAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return l10n.externalCommandsHintIos;
    }
    return l10n.externalCommandsHintDesktop;
  }

  String _eventToCombo(KeyEvent event) {
    return desktopHotkeyComboForEvent(event);
  }

  Future<String?> _showHotkeyCaptureDialog(BuildContext context) {
    final l10n = context.l10n;
    String capturedCombo = '';
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
                return Focus(
                  autofocus: true,
                  onKeyEvent: (FocusNode node, KeyEvent event) {
                    if (event is KeyDownEvent) {
                      final String combo = _eventToCombo(event);
                      if (combo.isNotEmpty) {
                        setState(() {
                          capturedCombo = combo;
                        });
                      }
                    }
                    return KeyEventResult.handled;
                  },
                  child: AlertDialog(
                    title: Text(l10n.settingsHotkeyDialogTitle),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.settingsHotkeyPressAnyKey,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        if (capturedCombo.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 16),
                          Text(
                            capturedCombo,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: capturedCombo.isEmpty
                            ? null
                            : () => Navigator.pop(context, capturedCombo),
                        child: Text(l10n.settingsHotkeyConfirm),
                      ),
                    ],
                  ),
                );
              },
        );
      },
    );
  }

  Future<void> _openPicPlcSettings() {
    return _openSectionSheet(
      title: context.l10n.picPlcSettingsTitle,
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final AppLocalizations l10n = context.l10n;
        return <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _picPlcEnabled,
            onChanged: (bool enabled) =>
                setBoth(() => _picPlcEnabled = enabled),
            title: Text(l10n.picPlcEnabledLabel),
          ),
          TextField(
            controller: _picPlcPort,
            enabled: _picPlcEnabled,
            decoration: InputDecoration(
              labelText: l10n.picPlcPortLabel,
              hintText: l10n.picPlcPortHint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.picPlcButtonsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (int index = 0; index < _picPlcButtonActions.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<PicPlcButtonAction>(
                initialValue: _picPlcButtonActions[index],
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.picPlcButtonLabel(index + 1),
                ),
                items: PicPlcButtonAction.values
                    .map(
                      (PicPlcButtonAction action) =>
                          DropdownMenuItem<PicPlcButtonAction>(
                            value: action,
                            child: Text(_picPlcButtonActionLabel(l10n, action)),
                          ),
                    )
                    .toList(),
                onChanged: _picPlcEnabled
                    ? (PicPlcButtonAction? action) {
                        if (action != null) {
                          setBoth(() => _picPlcButtonActions[index] = action);
                        }
                      }
                    : null,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            l10n.picPlcLedsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (int index = 0; index < _picPlcLedActions.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<PicPlcLedAction>(
                initialValue: _picPlcLedActions[index],
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.picPlcLedLabel(index + 1),
                ),
                items: PicPlcLedAction.values
                    .map(
                      (PicPlcLedAction action) =>
                          DropdownMenuItem<PicPlcLedAction>(
                            value: action,
                            child: Text(_picPlcLedActionLabel(l10n, action)),
                          ),
                    )
                    .toList(),
                onChanged: _picPlcEnabled
                    ? (PicPlcLedAction? action) {
                        if (action != null) {
                          setBoth(() => _picPlcLedActions[index] = action);
                        }
                      }
                    : null,
              ),
            ),
        ];
      },
    );
  }

  String _picPlcButtonActionLabel(
    AppLocalizations l10n,
    PicPlcButtonAction action,
  ) {
    return switch (action) {
      PicPlcButtonAction.none => l10n.picPlcActionNone,
      PicPlcButtonAction.toggleProjection => l10n.picPlcActionToggleProjection,
      PicPlcButtonAction.projectionSwitch => l10n.picPlcActionProjectionSwitch,
      PicPlcButtonAction.previousVerse => l10n.picPlcActionPreviousVerse,
      PicPlcButtonAction.nextVerse => l10n.picPlcActionNextVerse,
      PicPlcButtonAction.previousSong => l10n.picPlcActionPreviousSong,
      PicPlcButtonAction.nextSong => l10n.picPlcActionNextSong,
      PicPlcButtonAction.toggleDirection => l10n.picPlcActionToggleDirection,
      PicPlcButtonAction.directionSwitch => l10n.picPlcActionDirectionSwitch,
      PicPlcButtonAction.step => l10n.picPlcActionStep,
    };
  }

  String _picPlcLedActionLabel(AppLocalizations l10n, PicPlcLedAction action) {
    return switch (action) {
      PicPlcLedAction.none => l10n.picPlcActionNone,
      PicPlcLedAction.projectionOn => l10n.picPlcLedProjectionOn,
      PicPlcLedAction.forward => l10n.picPlcLedForward,
      PicPlcLedAction.backward => l10n.picPlcLedBackward,
    };
  }

  Future<void> _openProjectionSettings() {
    return _openSectionSheet(
      title: context.l10n.projectionSettingsTitle,
      builder: (BuildContext context, void Function(void Function()) setBoth) {
        final l10n = context.l10n;
        return <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _projectionNumberField(l10n.fontSize, _projFontSize),
              _projectionNumberField(l10n.titleSize, _projTitleSize),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _projLeftIndent,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.leftMargin),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.projectionMarginsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _projectionNumberField(l10n.projectionMarginLeft, _projBorderL),
              _projectionNumberField(l10n.projectionMarginRight, _projBorderR),
              _projectionNumberField(l10n.projectionMarginTop, _projBorderT),
              _projectionNumberField(l10n.projectionMarginBottom, _projBorderB),
            ],
          ),
          DropdownButtonFormField<int>(
            initialValue: _projSpacingStep,
            decoration: InputDecoration(labelText: l10n.lineSpacing),
            items: List<DropdownMenuItem<int>>.generate(
              11,
              (int i) => DropdownMenuItem<int>(
                value: i,
                child: Text('${100 + i * 10}%'),
              ),
            ),
            onChanged: (int? v) => setBoth(() => _projSpacingStep = v ?? 0),
          ),
          DropdownButtonFormField<int>(
            initialValue: _projKottaArany,
            decoration: InputDecoration(labelText: l10n.kottaScale),
            items: List<DropdownMenuItem<int>>.generate(20, (int i) {
              final int value = (i + 1) * 10;
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value%'),
              );
            }),
            onChanged: (int? v) => setBoth(() => _projKottaArany = v ?? 100),
          ),
          DropdownButtonFormField<int>(
            initialValue: _projAkkordArany,
            decoration: InputDecoration(labelText: l10n.chordScale),
            items: List<DropdownMenuItem<int>>.generate(20, (int i) {
              final int value = (i + 1) * 10;
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value%'),
              );
            }),
            onChanged: (int? v) => setBoth(() => _projAkkordArany = v ?? 100),
          ),
          DropdownButtonFormField<int>(
            initialValue: _projBgMode,
            decoration: InputDecoration(labelText: l10n.backgroundMode),
            items: <DropdownMenuItem<int>>[
              DropdownMenuItem<int>(value: 0, child: Text(l10n.bgModeCenter)),
              DropdownMenuItem<int>(value: 1, child: Text(l10n.bgModeZoom)),
              DropdownMenuItem<int>(value: 2, child: Text(l10n.bgModeFull)),
              DropdownMenuItem<int>(value: 3, child: Text(l10n.bgModeCascade)),
              DropdownMenuItem<int>(value: 4, child: Text(l10n.bgModeMirror)),
            ],
            onChanged: (int? v) => setBoth(() => _projBgMode = v ?? 0),
          ),
          DropdownButtonFormField<int>(
            initialValue: _projBackTrans,
            decoration: InputDecoration(labelText: l10n.backgroundOpacity),
            items: List<DropdownMenuItem<int>>.generate(11, (int i) {
              final int value = i * 10;
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value%'),
              );
            }),
            onChanged: (int? v) => setBoth(() => _projBackTrans = v ?? 0),
          ),
          DropdownButtonFormField<int>(
            initialValue: _projBlankTrans,
            decoration: InputDecoration(labelText: l10n.blankOpacity),
            items: List<DropdownMenuItem<int>>.generate(11, (int i) {
              final int value = i * 10;
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value%'),
              );
            }),
            onChanged: (int? v) => setBoth(() => _projBlankTrans = v ?? 0),
          ),
          if (_isDesktopPlatform()) ...<Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _desktopProjectorEnabled,
              onChanged: (bool v) =>
                  setBoth(() => _desktopProjectorEnabled = v),
              title: Text(l10n.projectorEnabled),
              subtitle: Text(l10n.projectorEnabledHint),
            ),
            _MonitorSelector(
              value: _desktopProjectorMonitor,
              onChanged: (int v) => setBoth(() => _desktopProjectorMonitor = v),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _projUseTitle,
            onChanged: (bool v) => setBoth(() => _projUseTitle = v),
            title: Text(l10n.showTitle),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _projHCenter,
            onChanged: (bool v) => setBoth(() => _projHCenter = v),
            title: Text(l10n.hCenter),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _projVCenter,
            onChanged: (bool v) => setBoth(() => _projVCenter = v),
            title: Text(l10n.vCenter),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _projBoldText,
            onChanged: (bool v) => setBoth(() => _projBoldText = v),
            title: Text(l10n.boldText),
          ),
          const SizedBox(height: 8),
          Text(l10n.colorsTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _colorButton(
                label: l10n.backgroundColor,
                color: _bkColor,
                onPressed: () async {
                  final Color? picked = await _pickColor(
                    context,
                    _bkColor,
                    title: l10n.backgroundColorTitle,
                  );
                  if (picked != null) {
                    setBoth(() => _bkColor = picked);
                  }
                },
              ),
              _colorButton(
                label: l10n.textColor,
                color: _txtColor,
                onPressed: () async {
                  final Color? picked = await _pickColor(
                    context,
                    _txtColor,
                    title: l10n.textColorTitle,
                  );
                  if (picked != null) {
                    setBoth(() => _txtColor = picked);
                  }
                },
              ),
              _colorButton(
                label: l10n.emptySlideColor,
                color: _blankColor,
                onPressed: () async {
                  final Color? picked = await _pickColor(
                    context,
                    _blankColor,
                    title: l10n.emptySlideColorTitle,
                  );
                  if (picked != null) {
                    setBoth(() => _blankColor = picked);
                  }
                },
              ),
              _colorButton(
                label: l10n.highlightColor,
                color: _hiColor,
                onPressed: () async {
                  final Color? picked = await _pickColor(
                    context,
                    _hiColor,
                    title: l10n.highlightColorTitle,
                  );
                  if (picked != null) {
                    setBoth(() => _hiColor = picked);
                  }
                },
              ),
            ],
          ),
        ];
      },
    );
  }

  Future<void> _openSectionSheet({
    required String title,
    String? closeButtonLabel,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showCancelButton = false,
    bool Function()? onConfirmClose,
    VoidCallback? onCancel,
    required List<Widget> Function(
      BuildContext context,
      void Function(void Function()) setBoth,
    )
    builder,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
                void setBoth(void Function() fn) {
                  if (mounted) {
                    setState(fn);
                  }
                  setModalState(() {});
                }

                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...builder(context, setBoth),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              if (showCancelButton)
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(context.l10n.cancel),
                                ),
                              const Spacer(),
                              FilledButton(
                                onPressed: () {
                                  final bool canClose =
                                      onConfirmClose?.call() ?? true;
                                  if (canClose) {
                                    Navigator.of(context).pop(true);
                                  }
                                },
                                child: Text(
                                  closeButtonLabel ?? context.l10n.ok,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
        );
      },
    ).then((bool? accepted) {
      if (accepted == true) {
        return;
      }
      onCancel?.call();
    });
  }

  Future<void> _save() async {
    final String mqttUser = _mqttUser.text.trim();
    final String mqttPassword = _internetRelayEnabled ? _mqttPassword.text : '';
    final List<String> tcpTargets = kIsWeb
        ? const <String>[]
        : _parseTcpTargets(_tcpTargets.text);
    final bool localNetworkEnabled = kIsWeb ? false : _localNetworkEnabled;
    final String? tcpError = localNetworkEnabled
        ? _validateTcpTargets(tcpTargets)
        : null;
    if (tcpError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tcpError)));
      return;
    }
    final int firstPort = localNetworkEnabled
        ? (_firstPortFromTargets(tcpTargets) ?? widget.initialSettings.port)
        : widget.initialSettings.port;

    final Set<String> usedHotkeys = <String>{};
    for (final String hotkey in _desktopActionHotkeys.values) {
      if (usedHotkeys.contains(hotkey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.settingsHotkeyConflict(hotkey))),
        );
        return;
      }
      usedHotkeys.add(hotkey);
    }
    for (final String hotkey in _desktopSongHotkeys.keys) {
      if (usedHotkeys.contains(hotkey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.settingsHotkeyConflict(hotkey))),
        );
        return;
      }
      usedHotkeys.add(hotkey);
    }
    for (final String hotkey in _desktopOrderSetHotkeys.keys) {
      if (usedHotkeys.contains(hotkey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.settingsHotkeyConflict(hotkey))),
        );
        return;
      }
      usedHotkeys.add(hotkey);
    }

    final AppSettings updated = widget.initialSettings.copyWith(
      port: firstPort,
      tcpClientEnabled: localNetworkEnabled,
      tcpTargets: tcpTargets,
      internetRelayEnabled: _internetRelayEnabled,
      mqttUser: mqttUser,
      mqttPassword: mqttPassword,
      mqttChannel: '1',
      dtxPath: '',
      blankPicPath: _blankPicPath.text.trim(),
      diaExportPath: _diaExportPath.text.trim(),
      diaAutoSaveEnabled: _diaAutoSaveEnabled,
      projFontSize: _parseInt(
        _projFontSize.text,
        widget.initialSettings.projFontSize,
        min: 12,
        max: 128,
      ),
      projTitleSize: _parseInt(
        _projTitleSize.text,
        widget.initialSettings.projTitleSize,
        min: 12,
        max: 128,
      ),
      projLeftIndent: _parseInt(
        _projLeftIndent.text,
        widget.initialSettings.projLeftIndent,
        min: 0,
        max: 10,
      ),
      projBorderL: _parseInt(
        _projBorderL.text,
        widget.initialSettings.projBorderL,
        min: 0,
        max: 1000,
      ),
      projBorderT: _parseInt(
        _projBorderT.text,
        widget.initialSettings.projBorderT,
        min: 0,
        max: 1000,
      ),
      projBorderR: _parseInt(
        _projBorderR.text,
        widget.initialSettings.projBorderR,
        min: 0,
        max: 1000,
      ),
      projBorderB: _parseInt(
        _projBorderB.text,
        widget.initialSettings.projBorderB,
        min: 0,
        max: 1000,
      ),
      projSpacingStep: _projSpacingStep.clamp(0, 10),
      projHCenter: _projHCenter,
      projVCenter: _projVCenter,
      projUseAkkord: _projUseAkkord,
      projUseKotta: _projUseKotta,
      projInverseKotta: _projInverseKotta,
      projShowBackgroundImage: _projShowBackgroundImage,
      projUseTitle: _projUseTitle,
      projKottaArany: _projKottaArany.clamp(10, 200),
      projAkkordArany: _projAkkordArany.clamp(10, 200),
      projBgMode: _projBgMode.clamp(0, 4),
      projBackTrans: _projBackTrans.clamp(0, 100),
      projBlankTrans: _projBlankTrans.clamp(0, 100),
      homeShowHighlightControls: _homeShowHighlightControls,
      appThemeMode: _appThemeMode.clamp(0, 1),
      appLanguage: _appLanguage,
      maxCustomOrderSets: _maxCustomOrderSets.clamp(
        AppSettings.minCustomOrderSets,
        AppSettings.maxCustomOrderSetsLimit,
      ),
      desktopProjectorEnabled: _desktopProjectorEnabled,
      desktopProjectorMonitor: _desktopProjectorMonitor,
      desktopActionHotkeys: Map<String, String>.from(_desktopActionHotkeys),
      desktopSongHotkeys: Map<String, String>.from(_desktopSongHotkeys),
      desktopOrderSetHotkeys: Map<String, String>.from(_desktopOrderSetHotkeys),
      projBoldText: _projBoldText,
      useSound: _useSound,
      advanceAfterMusic: _advanceAfterMusic,
      liveSubtitleDeviceId: _liveSubtitleDeviceId,
      liveSubtitleLanguage: _liveSubtitleLanguage,
      liveSubtitleModel: _liveSubtitleModel,
      speechFeatureVisible: _speechFeatureVisible,
      bkColor: _bkColor,
      txtColor: _txtColor,
      blankColor: _blankColor,
      hiColor: _hiColor,
    );

    final bool applied = await _applySettingsSafely(updated);
    if (!applied || !mounted) {
      return;
    }
    final bool picPlcApplied = await _applyPicPlcConfigurationSafely(
      PicPlcConfiguration(
        enabled: _picPlcEnabled,
        port: _picPlcPort.text.trim(),
        buttonActions: List<PicPlcButtonAction>.from(_picPlcButtonActions),
        ledActions: List<PicPlcLedAction>.from(_picPlcLedActions),
      ),
    );
    if (!picPlcApplied || !mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<bool> _applySettingsSafely(AppSettings updated) async {
    try {
      await widget.onApply(updated);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Settings apply failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.statusCommandSendError('$error'))),
      );
      return false;
    }
  }

  Future<bool> _applyPicPlcConfigurationSafely(
    PicPlcConfiguration configuration,
  ) async {
    try {
      await widget.onApplyPicPlc(configuration);
      return true;
    } catch (error, stackTrace) {
      debugPrint('PICPLC settings apply failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.statusCommandSendError('$error'))),
      );
      return false;
    }
  }

  List<String> _parseTcpTargets(String raw) {
    return raw
        .split(RegExp(r'\r?\n'))
        .map((String e) => _normalizeTcpTarget(e.trim()))
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  List<String> _parseWolTargets(String raw) {
    return raw
        .split(RegExp(r'\r?\n'))
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  String _normalizeTcpTarget(String rawTarget) {
    if (rawTarget.isEmpty) {
      return rawTarget;
    }
    return rawTarget.contains(':') ? rawTarget : '$rawTarget:1024';
  }

  String? _validateTcpTargets(List<String> targets) {
    final l10n = context.l10n;
    for (final String target in targets) {
      final int split = target.lastIndexOf(':');
      if (split <= 0 || split >= target.length - 1) {
        return l10n.tcpInvalidTargetFormat(target);
      }
      final String host = target.substring(0, split).trim();
      final int? port = int.tryParse(target.substring(split + 1).trim());
      if (host.isEmpty || port == null || port < 0 || port > 65535) {
        return l10n.tcpInvalidTargetFormat(target);
      }
    }
    return null;
  }

  int? _firstPortFromTargets(List<String> targets) {
    if (targets.isEmpty) {
      return null;
    }
    final String first = targets.first;
    final int split = first.lastIndexOf(':');
    if (split <= 0 || split >= first.length - 1) {
      return null;
    }
    return int.tryParse(first.substring(split + 1).trim());
  }

  Widget _projectionNumberField(
    String label,
    TextEditingController controller,
  ) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  int _parseInt(
    String raw,
    int fallback, {
    required int min,
    required int max,
  }) {
    final int value = int.tryParse(raw.trim()) ?? fallback;
    return value.clamp(min, max);
  }

  bool _isSupportedLanguage(String code) {
    if (code.trim().isEmpty) {
      return true;
    }
    return AppLocalizations.supportedLocales.any(
      (Locale locale) => locale.languageCode == code,
    );
  }

  String _languageLabel(BuildContext context, String code) {
    final l10n = context.l10n;
    switch (code) {
      case 'hu':
        return l10n.languageHungarian;
      case 'en':
        return l10n.languageEnglish;
      default:
        return code;
    }
  }

  Future<void> _pickBlankFile() async {
    final List<XFile> files = await DesktopProjectorBridge.instance
        .runWithNativeDialog(
          () => showFileOpenPanel(
            extensions: const <String>['png', 'jpg', 'jpeg', 'bmp', 'webp'],
          ),
        );
    final XFile? file = files.isEmpty ? null : files.first;
    if (!mounted || file == null) {
      return;
    }
    if (_isDesktopPlatform()) {
      setState(() {
        _blankPicPath.text = file.path;
      });
      return;
    }
    // Weben és mobilon nincs megbízható külső elérési út (blob-URL, illetve
    // ideiglenes cache), ezért a képet a belső fájlrendszerbe importáljuk.
    final Uint8List bytes = await file.readAsBytes();
    final String internalPath = await _blankImageStore.import(
      bytes,
      BlankImageStore.resolveImageExtension(file),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _blankPicPath.text = internalPath;
    });
  }

  void _clearBlankImage() {
    _blankPicPath.text = '';
    if (!_isDesktopPlatform()) {
      unawaited(_blankImageStore.delete());
    }
  }

  Future<void> _pickDiaExportFolder() async {
    final String? folderPath = await DesktopProjectorBridge.instance
        .runWithNativeDialog(showDirectoryPicker);
    if (!mounted || folderPath == null) {
      return;
    }
    setState(() {
      _diaExportPath.text = folderPath;
    });
  }

  Widget _colorButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final Color fg = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    return SizedBox(
      width: 150,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: fg,
          side: BorderSide(color: fg.withValues(alpha: 0.25)),
        ),
        child: Text(label),
      ),
    );
  }

  Future<Color?> _pickColor(
    BuildContext context,
    Color initial, {
    required String title,
  }) {
    final TextEditingController hex = TextEditingController(
      text: _colorToHex(initial),
    );
    Color temp = initial;
    const List<Color> palette = <Color>[
      Color(0xFF000000),
      Color(0xFFFFFFFF),
      Color(0xFFFF0000),
      Color(0xFF00FF00),
      Color(0xFF0000FF),
      Color(0xFFFFFF00),
      Color(0xFF00FFFF),
      Color(0xFFFF00FF),
      Color(0xFF404040),
      Color(0xFF808080),
      Color(0xFF800000),
      Color(0xFF008000),
      Color(0xFF000080),
      Color(0xFF804000),
      Color(0xFF800080),
      Color(0xFF008080),
    ];

    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
                return AlertDialog(
                  title: Text(title),
                  content: SizedBox(
                    width: 360,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          height: 48,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: temp,
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: hex,
                          decoration: InputDecoration(
                            labelText: context.l10n.hexColorHint,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (String value) {
                            final Color? parsed = _parseHexColor(value);
                            if (parsed != null) {
                              setState(() => temp = parsed);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: palette
                              .map(
                                (Color c) => InkWell(
                                  onTap: () {
                                    setState(() {
                                      temp = c;
                                      hex.text = _colorToHex(c);
                                    });
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: c,
                                      border: Border.all(color: Colors.black26),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(temp),
                      child: Text(context.l10n.ok),
                    ),
                  ],
                );
              },
        );
      },
    );
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  Color? _parseHexColor(String input) {
    String value = input
        .trim()
        .replaceAll('#', '')
        .replaceAll('0x', '')
        .replaceAll('0X', '');
    if (value.length == 6) {
      value = 'FF$value';
    }
    if (value.length != 8) {
      return null;
    }
    final int? parsed = int.tryParse(value, radix: 16);
    if (parsed == null) {
      return null;
    }
    return Color(parsed);
  }

  String _songLabelForId(String id) {
    for (final SongHotkeyOption option in _availableSongs) {
      if (option.id == id) {
        return option.label;
      }
    }
    return id;
  }

  String _orderSetLabelForId(String id) {
    _ensureAvailableOrderSetsLoaded();
    for (final CustomOrderSetOption option in _availableOrderSets) {
      if (option.id == id) {
        return option.name;
      }
    }
    for (final CustomOrderSetOption option in widget.availableOrderSets) {
      if (option.id == id) {
        return option.name;
      }
    }
    return id;
  }

  void _ensureAvailableOrderSetsLoaded() {
    if (_availableOrderSetsResolved) {
      return;
    }
    _availableOrderSetsResolved = true;
    final List<CustomOrderSetOption> loaded =
        widget.availableOrderSetsLoader?.call() ??
        const <CustomOrderSetOption>[];
    _availableOrderSets = loaded;
    if (_selectedOrderSetOptionId.isEmpty && _availableOrderSets.isNotEmpty) {
      _selectedOrderSetOptionId = _availableOrderSets.first.id;
    }
  }

  Future<CustomOrderSetOption?> _pickOrderSetOption(
    BuildContext context,
  ) async {
    _ensureAvailableOrderSetsLoaded();
    if (_availableOrderSets.isEmpty) {
      return null;
    }

    final AppLocalizations l10n = context.l10n;
    final TextEditingController search = TextEditingController();
    final List<String> lowerLabels = _availableOrderSets
        .map((CustomOrderSetOption option) => option.name.toLowerCase())
        .toList(growable: false);
    List<int> filteredIndexes = List<int>.generate(
      _availableOrderSets.length,
      (int i) => i,
      growable: true,
    );

    final CustomOrderSetOption?
    selected = await showDialog<CustomOrderSetOption>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(l10n.settingsOrderSetPickerTitle),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: search,
                      onChanged: (String value) {
                        setState(() {
                          final String lowerValue = value.toLowerCase();
                          filteredIndexes =
                              List<int>.generate(
                                    _availableOrderSets.length,
                                    (int i) => i,
                                    growable: true,
                                  )
                                  .where((int i) {
                                    return lowerLabels[i].contains(lowerValue);
                                  })
                                  .toList(growable: false);
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: l10n.settingsSearchLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        itemCount: filteredIndexes.length,
                        itemBuilder: (BuildContext context, int index) {
                          final CustomOrderSetOption option =
                              _availableOrderSets[filteredIndexes[index]];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(option.name),
                            selected: option.id == _selectedOrderSetOptionId,
                            onTap: () {
                              Navigator.of(context).pop(option);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop<CustomOrderSetOption>(),
                  child: Text(l10n.cancel),
                ),
              ],
            );
          },
        );
      },
    );
    return selected;
  }
}

class _RegistrationInput {
  const _RegistrationInput({
    required this.username,
    required this.password,
    required this.email,
  });

  final String username;
  final String password;
  final String email;
}

class _ChangeEmailInput {
  const _ChangeEmailInput({
    required this.username,
    required this.password,
    required this.newEmail,
  });

  final String username;
  final String password;
  final String newEmail;
}

class _ResendVerificationInput {
  const _ResendVerificationInput({required this.username, required this.email});

  final String username;
  final String email;
}

class _DeleteUserInput {
  const _DeleteUserInput({required this.username, required this.password});

  final String username;
  final String password;
}

class _ChangePasswordInput {
  const _ChangePasswordInput({
    required this.username,
    required this.password,
    required this.newPassword,
  });

  final String username;
  final String password;
  final String newPassword;
}

class _RegistrationInputDialog extends StatefulWidget {
  const _RegistrationInputDialog({
    required this.title,
    required this.initialUsername,
  });

  final String title;
  final String initialUsername;

  @override
  State<_RegistrationInputDialog> createState() =>
      _RegistrationInputDialogState();
}

class _RegistrationInputDialogState extends State<_RegistrationInputDialog> {
  late final TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final String email = _emailController.text.trim();
    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      _RegistrationInput(username: username, password: password, email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: l10n.userFieldUsername),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: l10n.userFieldPassword,
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? l10n.passwordHideTooltip
                    : l10n.passwordShowTooltip,
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.userFieldEmail),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.ok)),
      ],
    );
  }
}

/// A vetítőablak megjelenítendő kijelzőjének kiválasztója.
/// -1: automatikus (utolsó/jobb szélső kijelző), egyébként a kijelző indexe.
class _MonitorSelector extends StatefulWidget {
  const _MonitorSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_MonitorSelector> createState() => _MonitorSelectorState();
}

class _MonitorSelectorState extends State<_MonitorSelector> {
  List<Display> _displays = <Display>[];

  @override
  void initState() {
    super.initState();
    _loadDisplays();
  }

  Future<void> _loadDisplays() async {
    try {
      final List<Display> displays = await screenRetriever.getAllDisplays();
      if (!mounted) {
        return;
      }
      setState(() {
        _displays = displays;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _displays = <Display>[];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<DropdownMenuItem<int>> items = <DropdownMenuItem<int>>[
      DropdownMenuItem<int>(value: -1, child: Text(l10n.projectorMonitorAuto)),
    ];
    for (int i = 0; i < _displays.length; i++) {
      final Display d = _displays[i];
      final String size = d.size.width.round() > 0
          ? '${d.size.width.round()}x${d.size.height.round()}'
          : '';
      final String label = size.isNotEmpty
          ? l10n.projectorMonitorIndex(i + 1, size)
          : l10n.projectorMonitorIndexShort(i + 1);
      items.add(DropdownMenuItem<int>(value: i, child: Text(label)));
    }

    return DropdownButtonFormField<int>(
      initialValue: widget.value,
      decoration: InputDecoration(labelText: l10n.projectorMonitor),
      items: items,
      onChanged: (int? v) => widget.onChanged(v ?? -1),
    );
  }
}

class _ChangeEmailInputDialog extends StatefulWidget {
  const _ChangeEmailInputDialog({
    required this.title,
    required this.initialUsername,
  });

  final String title;
  final String initialUsername;

  @override
  State<_ChangeEmailInputDialog> createState() =>
      _ChangeEmailInputDialogState();
}

class _ChangeEmailInputDialogState extends State<_ChangeEmailInputDialog> {
  late final TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  void _submit() {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final String newEmail = _newEmailController.text.trim();
    if (username.isEmpty || password.isEmpty || newEmail.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      _ChangeEmailInput(
        username: username,
        password: password,
        newEmail: newEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: l10n.userFieldCurrentUsername,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: l10n.userFieldCurrentPassword,
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? l10n.passwordHideTooltip
                    : l10n.passwordShowTooltip,
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.userFieldNewEmail),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.ok)),
      ],
    );
  }
}

class _ResendVerificationInputDialog extends StatefulWidget {
  const _ResendVerificationInputDialog({required this.title});

  final String title;

  @override
  State<_ResendVerificationInputDialog> createState() =>
      _ResendVerificationInputDialogState();
}

class _ResendVerificationInputDialogState
    extends State<_ResendVerificationInputDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _ResendVerificationInput(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: l10n.userFieldUsername),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.userFieldEmail),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.ok)),
      ],
    );
  }
}

class _DeleteUserInputDialog extends StatefulWidget {
  const _DeleteUserInputDialog({
    required this.title,
    required this.initialUsername,
  });

  final String title;
  final String initialUsername;

  @override
  State<_DeleteUserInputDialog> createState() => _DeleteUserInputDialogState();
}

class _DeleteUserInputDialogState extends State<_DeleteUserInputDialog> {
  late final TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _DeleteUserInput(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: l10n.userFieldUsername),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: l10n.userFieldPassword,
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? l10n.passwordHideTooltip
                    : l10n.passwordShowTooltip,
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.ok)),
      ],
    );
  }
}

class _ChangePasswordInputDialog extends StatefulWidget {
  const _ChangePasswordInputDialog({
    required this.title,
    required this.initialUsername,
  });

  final String title;
  final String initialUsername;

  @override
  State<_ChangePasswordInputDialog> createState() =>
      _ChangePasswordInputDialogState();
}

class _ChangePasswordInputDialogState
    extends State<_ChangePasswordInputDialog> {
  late final TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showNewPassword = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _ChangePasswordInput(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: l10n.userFieldUsername),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: l10n.userFieldCurrentPassword,
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? l10n.passwordHideTooltip
                    : l10n.passwordShowTooltip,
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            obscureText: !_showNewPassword,
            decoration: InputDecoration(
              labelText: l10n.userFieldNewPassword,
              suffixIcon: IconButton(
                tooltip: _showNewPassword
                    ? l10n.passwordHideTooltip
                    : l10n.passwordShowTooltip,
                onPressed: () =>
                    setState(() => _showNewPassword = !_showNewPassword),
                icon: Icon(
                  _showNewPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.ok)),
      ],
    );
  }
}

class _ModelSelectorContent extends StatefulWidget {
  final String liveSubtitleModel;
  final ValueChanged<String> onChanged;

  const _ModelSelectorContent({
    required this.liveSubtitleModel,
    required this.onChanged,
  });

  @override
  State<_ModelSelectorContent> createState() => _ModelSelectorContentState();
}

class _ModelSelectorContentState extends State<_ModelSelectorContent> {
  Map<String, int> _fileSizes = {};
  bool _loadingSizes = true;

  @override
  void initState() {
    super.initState();
    _loadSizes();
  }

  Future<void> _loadSizes() async {
    final Map<String, int> sizes = await GitHubReleaseSizeCache.getAllSizes();
    if (mounted) {
      setState(() {
        _fileSizes = sizes;
        _loadingSizes = false;
      });
    }
  }

  String _modelSize(SpeechModelInfo info) {
    final String fileName = info.downloadUrl.split('/').last;
    final int? bytes = _fileSizes[fileName];
    if (bytes != null) return GitHubReleaseSizeCache.formatSize(bytes);
    return _loadingSizes ? '...' : '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RadioGroup<String>(
      groupValue: widget.liveSubtitleModel,
      onChanged: (String? value) {
        if (value != null) widget.onChanged(value);
      },
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Text(
            l10n.speechModelStreaming,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          for (final SpeechModelType type in SpeechModelType.values)
            if (getSpeechModel(type).isStreaming)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(getSpeechModel(type).displayName),
                subtitle: Text(
                  '${getSpeechModel(type).latencyMs}ms  •  ${_modelSize(getSpeechModel(type))}',
                ),
                value: type.name,
              ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            l10n.speechModelOffline,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          for (final SpeechModelType type in SpeechModelType.values)
            if (!getSpeechModel(type).isStreaming)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(getSpeechModel(type).displayName),
                subtitle: Text(_modelSize(getSpeechModel(type))),
                value: type.name,
              ),
        ],
      ),
    );
  }
}
