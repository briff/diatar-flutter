import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diatar_common/diatar_common.dart';
import 'pic_plc_service.dart';

class SettingsStore {
  static const String _kPort = 'Port';
  static const String _kTcpClientEnabled = 'TcpClientEnabled';
  static const String _kTcpTargets = 'TcpTargets';
  static const String _kShowCameraView = 'ShowCameraView';
  static const String _kCameraTarget = 'CameraTarget';
  static const String _kCameraViewWidth = 'CameraViewWidth';
  static const String _kCameraViewHeight = 'CameraViewHeight';
  static const String _kWolEnabled = 'WolEnabled';
  static const String _kWolTargets = 'WolTargets';
  static const String _kWolBroadcastAddress = 'WolBroadcastAddress';
  static const String _kWolPort = 'WolPort';
  static const String _kUser = 'Username';
  static const String _kPassword = 'Password';
  static const String _kInternetRelayEnabled = 'InternetRelayEnabled';
  static const String _kChannel = 'Channel';
  static const String _kBlankPicPath = 'BlankPicPath';
  static const String _kDiaExportPath = 'DiaExportPath';
  static const String _kDiaExportUri = 'DiaExportUri';
  static const String _kDiaExportFileName = 'DiaExportFileName';
  static const String _kDiaAutoSaveEnabled = 'DiaAutoSaveEnabled';
  static const String _kBkColor = 'BkColor';
  static const String _kTxColor = 'TxColor';
  static const String _kBlankColor = 'BlankColor';
  static const String _kHiColor = 'HiColor';
  static const String _kProjFontSize = 'ProjFontSize';
  static const String _kProjTitleSize = 'ProjTitleSize';
  static const String _kProjLeftIndent = 'ProjLeftIndent';
  static const String _kProjBorderL = 'ProjBorderL';
  static const String _kProjBorderT = 'ProjBorderT';
  static const String _kProjBorderR = 'ProjBorderR';
  static const String _kProjBorderB = 'ProjBorderB';
  static const String _kProjSpacingStep = 'ProjSpacingStep';
  static const String _kProjHCenter = 'ProjHCenter';
  static const String _kProjVCenter = 'ProjVCenter';
  static const String _kProjUseAkkord = 'ProjUseAkkord';
  static const String _kProjUseKotta = 'ProjUseKotta';
  static const String _kProjInverseKotta = 'ProjInverseKotta';
  static const String _kProjUseTitle = 'ProjUseTitle';
  static const String _kProjKottaArany = 'ProjKottaArany';
  static const String _kProjAkkordArany = 'ProjAkkordArany';
  static const String _kProjBoldText = 'ProjBoldText';
  static const String _kProjBgMode = 'ProjBgMode';
  static const String _kProjBackTrans = 'ProjBackTrans';
  static const String _kProjBlankTrans = 'ProjBlankTrans';
  static const String _kProjShowBackgroundImage = 'ProjShowBackgroundImage';
  static const String _kHomeViewMode = 'HomeViewMode';
  static const String _kHomeShowHighlightControls = 'HomeShowHighlightControls';
  static const String _kHomeLayoutMode = 'HomeLayoutMode';
  static const String _kPresentationControlsVisible =
      'PresentationControlsVisible';
  static const String _kHomeTopBarHidden = 'HomeTopBarHidden';
  static const String _kLandscapeControlsRatio = 'LandscapeControlsRatio';
  static const String _kAppThemeMode = 'AppThemeMode';
  static const String _kAppLanguage = 'AppLanguage';
  static const String _kMaxCustomOrderSets = 'MaxCustomOrderSets';
  static const String _kProjectionLocked = 'ProjectionLocked';
  static const String _kDesktopProjectorEnabled = 'DesktopProjectorEnabled';
  static const String _kDesktopProjectorMonitor = 'DesktopProjectorMonitor';
  static const String _kDesktopActionHotkeys = 'DesktopActionHotkeys';
  static const String _kDesktopActionHotkeysInitialized =
      'DesktopActionHotkeysInitialized';
  static const String _kDesktopSongHotkeys = 'DesktopSongHotkeys';
  static const String _kDesktopOrderSetHotkeys = 'DesktopOrderSetHotkeys';
  static const String _kExternalCommandOnStart = 'ExternalCommandOnStart';
  static const String _kExternalCommandOnExit = 'ExternalCommandOnExit';
  static const String _kExternalCommandOnProjectionOn =
      'ExternalCommandOnProjectionOn';
  static const String _kExternalCommandOnProjectionOff =
      'ExternalCommandOnProjectionOff';
  static const String _kUseSound = 'UseSound';
  static const String _kAdvanceAfterMusic = 'AdvanceAfterMusic';
  static const String _kLiveSubtitlesEnabled = 'LiveSubtitlesEnabled';
  static const String _kSpeechFeatureVisible = 'SpeechFeatureVisible';
  static const String _kLiveSubtitleDeviceId = 'LiveSubtitleDeviceId';
  static const String _kLiveSubtitleLanguage = 'LiveSubtitleLanguage';
  static const String _kSzentirasApiKey = 'SzentirasApiKey';
  static const String _kTranspositions = 'Transpositions';
  static const String _kLastSongPerBook = 'LastSongPerBook';
  static const String _kLastVersePerBook = 'LastVersePerBook';
  static const String _kHasSeenOnboarding = 'HasSeenOnboarding';
  static const String _kPicPlcEnabled = 'PicPlcEnabled';
  static const String _kPicPlcPort = 'PicPlcPort';
  static const String _kPicPlcButtonActions = 'PicPlcButtonActions';
  static const String _kPicPlcLedActions = 'PicPlcLedActions';
  static const String _kShowPhotoInControl = 'ShowPhotoInControl';

  static const Map<String, String> _defaultDesktopActionHotkeys =
      <String, String>{
        'prevVerse': 'ArrowUp',
        'nextVerse': 'ArrowDown',
        'prevSong': 'PageUp',
        'nextSong': 'PageDown',
        'toggleProjection': 'Escape',
        'highlightPrev': 'ArrowLeft',
        'highlightNext': 'ArrowRight',
      };

  Future<Map<String, int>> loadTranspositions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_kTranspositions);
    if (json == null) return <String, int>{};
    try {
      final Map<String, dynamic> decoded = jsonDecode(json);
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> saveTranspositions(Map<String, int> transpositions) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTranspositions, jsonEncode(transpositions));
  }

  Future<Map<String, int>> loadLastSongPerBook() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_kLastSongPerBook);
    if (json == null) return <String, int>{};
    try {
      final Map<String, dynamic> decoded = jsonDecode(json);
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> saveLastSongPerBook(Map<String, int> map) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastSongPerBook, jsonEncode(map));
  }

  Future<Map<String, int>> loadLastVersePerBook() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_kLastVersePerBook);
    if (json == null) return <String, int>{};
    try {
      final Map<String, dynamic> decoded = jsonDecode(json);
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> saveLastVersePerBook(Map<String, int> map) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastVersePerBook, jsonEncode(map));
  }

  Future<bool> loadShowPhotoInControl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowPhotoInControl) ?? false;
  }

  Future<void> saveShowPhotoInControl(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowPhotoInControl, value);
  }

  Future<bool> hasSeenOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasSeenOnboarding) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboarding, true);
  }

  Future<PicPlcConfiguration> loadPicPlcConfiguration() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> savedActions =
        prefs.getStringList(_kPicPlcButtonActions) ?? const <String>[];
    final List<PicPlcButtonAction> actions = List<PicPlcButtonAction>.generate(
      8,
      (int index) {
        if (index >= savedActions.length) {
          return PicPlcButtonAction.none;
        }
        return PicPlcButtonAction.values.firstWhere(
          (PicPlcButtonAction action) => action.name == savedActions[index],
          orElse: () => PicPlcButtonAction.none,
        );
      },
    );
    final List<String> savedLedActions =
        prefs.getStringList(_kPicPlcLedActions) ?? const <String>[];
    final List<PicPlcLedAction> ledActions = List<PicPlcLedAction>.generate(2, (
      int index,
    ) {
      if (index >= savedLedActions.length) {
        return PicPlcLedAction.none;
      }
      return PicPlcLedAction.values.firstWhere(
        (PicPlcLedAction action) => action.name == savedLedActions[index],
        orElse: () => PicPlcLedAction.none,
      );
    });
    return PicPlcConfiguration(
      enabled: prefs.getBool(_kPicPlcEnabled) ?? false,
      port: prefs.getString(_kPicPlcPort) ?? '',
      buttonActions: actions,
      ledActions: ledActions,
    );
  }

  Future<void> savePicPlcConfiguration(
    PicPlcConfiguration configuration,
  ) async {
    if (configuration.buttonActions.length != 8) {
      throw ArgumentError.value(
        configuration.buttonActions,
        'buttonActions',
        'must contain exactly eight assignments',
      );
    }
    if (configuration.ledActions.length != 2) {
      throw ArgumentError.value(
        configuration.ledActions,
        'ledActions',
        'must contain exactly two assignments',
      );
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPicPlcEnabled, configuration.enabled);
    await prefs.setString(_kPicPlcPort, configuration.port.trim());
    await prefs.setStringList(
      _kPicPlcButtonActions,
      configuration.buttonActions
          .map((PicPlcButtonAction action) => action.name)
          .toList(),
    );
    await prefs.setStringList(
      _kPicPlcLedActions,
      configuration.ledActions
          .map((PicPlcLedAction action) => action.name)
          .toList(),
    );
  }

  Future<AppSettings> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String mqttUser = prefs.getString(_kUser) ?? '';
    final bool internetRelayEnabled =
        prefs.getBool(_kInternetRelayEnabled) ?? mqttUser.trim().isNotEmpty;
    final String mqttPassword = !internetRelayEnabled
        ? ''
        : mqttUser.trim().isEmpty
        ? ''
        : (prefs.getString(_kPassword) ?? '');
    final int legacyPort = prefs.getInt(_kPort) ?? 1024;
    final List<String> tcpTargets =
        (prefs.getStringList(_kTcpTargets) ?? <String>[])
            .map((String e) => e.trim())
            .where((String e) => e.isNotEmpty)
            .toList();
    final bool tcpClientEnabled =
        prefs.getBool(_kTcpClientEnabled) ?? tcpTargets.isNotEmpty;
    final bool showCameraView = prefs.getBool(_kShowCameraView) ?? false;
    final String? cameraTarget = prefs.getString(_kCameraTarget);
    final double cameraViewWidth = prefs.getDouble(_kCameraViewWidth) ?? 200;
    final double cameraViewHeight = prefs.getDouble(_kCameraViewHeight) ?? 120;
    final bool wolEnabled = prefs.getBool(_kWolEnabled) ?? false;
    final List<String> wolTargets =
        prefs.getStringList(_kWolTargets) ?? const <String>[];
    final String wolBroadcastAddress =
        prefs.getString(_kWolBroadcastAddress) ?? '255.255.255.255';
    final int wolPort = prefs.getInt(_kWolPort) ?? 9;
    final Map<String, String> savedDesktopActionHotkeys = _decodeStringMap(
      prefs.getStringList(_kDesktopActionHotkeys),
    );
    final bool desktopActionHotkeysInitialized =
        prefs.getBool(_kDesktopActionHotkeysInitialized) ?? false;
    final Map<String, String> desktopActionHotkeys;
    if (!desktopActionHotkeysInitialized && savedDesktopActionHotkeys.isEmpty) {
      desktopActionHotkeys = _defaultDesktopActionHotkeys;
      await prefs.setStringList(
        _kDesktopActionHotkeys,
        _encodeStringMap(desktopActionHotkeys),
      );
    } else {
      desktopActionHotkeys = savedDesktopActionHotkeys;
    }
    if (!desktopActionHotkeysInitialized) {
      await prefs.setBool(_kDesktopActionHotkeysInitialized, true);
    }
    return AppSettings(
      port: legacyPort,
      tcpClientEnabled: tcpClientEnabled,
      tcpTargets: tcpTargets,
      showCameraView: showCameraView,
      cameraTarget: cameraTarget,
      cameraViewWidth: cameraViewWidth,
      cameraViewHeight: cameraViewHeight,
      wolEnabled: wolEnabled,
      wolTargets: wolTargets,
      wolBroadcastAddress: wolBroadcastAddress,
      wolPort: wolPort,
      boot: false,
      borderToClip: false,
      clipL: 0,
      clipR: 0,
      clipT: 0,
      clipB: 0,
      mirror: false,
      rotateQuarterTurns: 0,
      mqttUser: mqttUser,
      mqttPassword: mqttPassword,
      internetRelayEnabled: internetRelayEnabled,
      mqttChannel: '1',
      dtxPath: '',
      blankPicPath: prefs.getString(_kBlankPicPath) ?? '',
      diaExportPath: prefs.getString(_kDiaExportPath) ?? '',
      diaExportUri: prefs.getString(_kDiaExportUri) ?? '',
      diaExportFileName: prefs.getString(_kDiaExportFileName) ?? '',
      diaAutoSaveEnabled: prefs.getBool(_kDiaAutoSaveEnabled) ?? false,
      projFontSize: prefs.getInt(_kProjFontSize) ?? 250,
      projTitleSize: prefs.getInt(_kProjTitleSize) ?? 12,
      projLeftIndent: prefs.getInt(_kProjLeftIndent) ?? 2,
      projBorderL: prefs.getInt(_kProjBorderL) ?? 0,
      projBorderT: prefs.getInt(_kProjBorderT) ?? 0,
      projBorderR: prefs.getInt(_kProjBorderR) ?? 0,
      projBorderB: prefs.getInt(_kProjBorderB) ?? 0,
      projSpacingStep: prefs.getInt(_kProjSpacingStep) ?? 0,
      projAutoSize: true,
      projHCenter: prefs.getBool(_kProjHCenter) ?? false,
      projVCenter: prefs.getBool(_kProjVCenter) ?? true,
      projUseAkkord: prefs.getBool(_kProjUseAkkord) ?? false,
      projUseKotta: prefs.getBool(_kProjUseKotta) ?? true,
      projInverseKotta: prefs.getBool(_kProjInverseKotta) ?? false,
      projUseTitle: prefs.getBool(_kProjUseTitle) ?? true,
      projKottaArany: prefs.getInt(_kProjKottaArany) ?? 100,
      projAkkordArany: prefs.getInt(_kProjAkkordArany) ?? 100,
      projBoldText: prefs.getBool(_kProjBoldText) ?? false,
      projBgMode: prefs.getInt(_kProjBgMode) ?? 1,
      projBackTrans: prefs.getInt(_kProjBackTrans) ?? 0,
      projBlankTrans: prefs.getInt(_kProjBlankTrans) ?? 0,
      projShowBackgroundImage: prefs.getBool(_kProjShowBackgroundImage) ?? true,
      homeViewMode: prefs.getInt(_kHomeViewMode) ?? 0,
      homeShowHighlightControls:
          prefs.getBool(_kHomeShowHighlightControls) ?? false,
      homeLayoutMode: prefs.getInt(_kHomeLayoutMode) ?? 0,
      presentationControlsVisible:
          prefs.getBool(_kPresentationControlsVisible) ?? false,
      homeTopBarHidden: prefs.getBool(_kHomeTopBarHidden) ?? false,
      landscapeControlsRatio: prefs.getDouble(_kLandscapeControlsRatio),
      appThemeMode: prefs.getInt(_kAppThemeMode) ?? 0,
      appLanguage: prefs.getString(_kAppLanguage) ?? '',
      maxCustomOrderSets:
          (prefs.getInt(_kMaxCustomOrderSets) ??
                  AppSettings.defaultMaxCustomOrderSets)
              .clamp(
                AppSettings.minCustomOrderSets,
                AppSettings.maxCustomOrderSetsLimit,
              ),
      projectionLocked: prefs.getBool(_kProjectionLocked) ?? false,
      desktopProjectorEnabled: prefs.getBool(_kDesktopProjectorEnabled) ?? true,
      desktopProjectorMonitor: prefs.getInt(_kDesktopProjectorMonitor) ?? -1,
      desktopActionHotkeys: desktopActionHotkeys,
      desktopSongHotkeys: _decodeStringMap(
        prefs.getStringList(_kDesktopSongHotkeys),
      ),
      desktopOrderSetHotkeys: _decodeStringMap(
        prefs.getStringList(_kDesktopOrderSetHotkeys),
      ),
      externalCommandOnStart: prefs.getString(_kExternalCommandOnStart) ?? '',
      externalCommandOnExit: prefs.getString(_kExternalCommandOnExit) ?? '',
      externalCommandOnProjectionOn:
          prefs.getString(_kExternalCommandOnProjectionOn) ?? '',
      externalCommandOnProjectionOff:
          prefs.getString(_kExternalCommandOnProjectionOff) ?? '',
      useSound: prefs.getBool(_kUseSound) ?? false,
      advanceAfterMusic: prefs.getBool(_kAdvanceAfterMusic) ?? false,
      liveSubtitlesEnabled: prefs.getBool(_kLiveSubtitlesEnabled) ?? false,
      speechFeatureVisible: prefs.getBool(_kSpeechFeatureVisible) ?? true,
      liveSubtitleDeviceId: prefs.getString(_kLiveSubtitleDeviceId),
      liveSubtitleLanguage: prefs.getString(_kLiveSubtitleLanguage) ?? 'auto',
      szentirasApiKey: prefs.getString(_kSzentirasApiKey) ?? '',
      bkColor: Color(prefs.getInt(_kBkColor) ?? 0xFF000000),
      txtColor: Color(prefs.getInt(_kTxColor) ?? 0xFFFFFFFF),
      blankColor: Color(prefs.getInt(_kBlankColor) ?? 0xFF000000),
      hiColor: Color(prefs.getInt(_kHiColor) ?? 0xFF00FFFF),
    );
  }

  Future<void> save(AppSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> tcpTargets = settings.tcpTargets
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
    await prefs.setInt(_kPort, settings.port);
    await prefs.setBool(_kTcpClientEnabled, settings.tcpClientEnabled);
    await prefs.setStringList(_kTcpTargets, tcpTargets);
    await prefs.setBool(_kShowCameraView, settings.showCameraView);
    await prefs.setDouble(_kCameraViewWidth, settings.cameraViewWidth);
    await prefs.setDouble(_kCameraViewHeight, settings.cameraViewHeight);
    await prefs.setBool(_kWolEnabled, settings.wolEnabled);
    await prefs.setStringList(_kWolTargets, settings.wolTargets);
    await prefs.setString(_kWolBroadcastAddress, settings.wolBroadcastAddress);
    await prefs.setInt(_kWolPort, settings.wolPort);
    if (settings.cameraTarget != null) {
      await prefs.setString(_kCameraTarget, settings.cameraTarget!);
    } else {
      await prefs.remove(_kCameraTarget);
    }
    await prefs.setString(_kUser, settings.mqttUser);
    await prefs.setBool(_kInternetRelayEnabled, settings.internetRelayEnabled);
    await prefs.setString(
      _kPassword,
      settings.internetRelayEnabled && settings.mqttUser.trim().isNotEmpty
          ? settings.mqttPassword
          : '',
    );
    await prefs.setString(_kChannel, '1');
    await prefs.setString(_kBlankPicPath, settings.blankPicPath);
    await prefs.setString(_kDiaExportPath, settings.diaExportPath);
    await prefs.setString(_kDiaExportUri, settings.diaExportUri);
    await prefs.setString(_kDiaExportFileName, settings.diaExportFileName);
    await prefs.setBool(_kDiaAutoSaveEnabled, settings.diaAutoSaveEnabled);
    await prefs.setInt(_kProjFontSize, settings.projFontSize);
    await prefs.setInt(_kProjTitleSize, settings.projTitleSize);
    await prefs.setInt(_kProjLeftIndent, settings.projLeftIndent);
    await prefs.setInt(_kProjBorderL, settings.projBorderL);
    await prefs.setInt(_kProjBorderT, settings.projBorderT);
    await prefs.setInt(_kProjBorderR, settings.projBorderR);
    await prefs.setInt(_kProjBorderB, settings.projBorderB);
    await prefs.setInt(_kProjSpacingStep, settings.projSpacingStep);
    await prefs.setBool(_kProjHCenter, settings.projHCenter);
    await prefs.setBool(_kProjVCenter, settings.projVCenter);
    await prefs.setBool(_kProjUseAkkord, settings.projUseAkkord);
    await prefs.setBool(_kProjUseKotta, settings.projUseKotta);
    await prefs.setBool(_kProjInverseKotta, settings.projInverseKotta);
    await prefs.setBool(_kProjUseTitle, settings.projUseTitle);
    await prefs.setInt(_kProjKottaArany, settings.projKottaArany);
    await prefs.setInt(_kProjAkkordArany, settings.projAkkordArany);
    await prefs.setBool(_kProjBoldText, settings.projBoldText);
    await prefs.setInt(_kProjBgMode, settings.projBgMode);
    await prefs.setInt(_kProjBackTrans, settings.projBackTrans);
    await prefs.setInt(_kProjBlankTrans, settings.projBlankTrans);
    await prefs.setBool(
      _kProjShowBackgroundImage,
      settings.projShowBackgroundImage,
    );
    await prefs.setInt(_kHomeViewMode, settings.homeViewMode);
    await prefs.setBool(
      _kHomeShowHighlightControls,
      settings.homeShowHighlightControls,
    );
    await prefs.setInt(_kHomeLayoutMode, settings.homeLayoutMode);
    await prefs.setBool(
      _kPresentationControlsVisible,
      settings.presentationControlsVisible,
    );
    await prefs.setBool(_kHomeTopBarHidden, settings.homeTopBarHidden);
    if (settings.landscapeControlsRatio != null) {
      await prefs.setDouble(
        _kLandscapeControlsRatio,
        settings.landscapeControlsRatio!,
      );
    }
    await prefs.setInt(_kAppThemeMode, settings.appThemeMode);
    await prefs.setString(_kAppLanguage, settings.appLanguage);
    await prefs.setInt(_kMaxCustomOrderSets, settings.maxCustomOrderSets);
    await prefs.setBool(_kProjectionLocked, settings.projectionLocked);
    await prefs.setBool(
      _kDesktopProjectorEnabled,
      settings.desktopProjectorEnabled,
    );
    await prefs.setInt(
      _kDesktopProjectorMonitor,
      settings.desktopProjectorMonitor,
    );
    await prefs.setStringList(
      _kDesktopActionHotkeys,
      _encodeStringMap(settings.desktopActionHotkeys),
    );
    await prefs.setBool(_kDesktopActionHotkeysInitialized, true);
    await prefs.setStringList(
      _kDesktopSongHotkeys,
      _encodeStringMap(settings.desktopSongHotkeys),
    );
    await prefs.setStringList(
      _kDesktopOrderSetHotkeys,
      _encodeStringMap(settings.desktopOrderSetHotkeys),
    );
    await prefs.setString(
      _kExternalCommandOnStart,
      settings.externalCommandOnStart,
    );
    await prefs.setString(
      _kExternalCommandOnExit,
      settings.externalCommandOnExit,
    );
    await prefs.setString(
      _kExternalCommandOnProjectionOn,
      settings.externalCommandOnProjectionOn,
    );
    await prefs.setString(
      _kExternalCommandOnProjectionOff,
      settings.externalCommandOnProjectionOff,
    );
    await prefs.setBool(_kUseSound, settings.useSound);
    await prefs.setBool(_kAdvanceAfterMusic, settings.advanceAfterMusic);
    await prefs.setBool(_kLiveSubtitlesEnabled, settings.liveSubtitlesEnabled);
    await prefs.setBool(_kSpeechFeatureVisible, settings.speechFeatureVisible);
    await prefs.setString(
      _kLiveSubtitleDeviceId,
      settings.liveSubtitleDeviceId ?? '',
    );
    await prefs.setString(
      _kLiveSubtitleLanguage,
      settings.liveSubtitleLanguage,
    );
    await prefs.setString(_kSzentirasApiKey, settings.szentirasApiKey);
    await prefs.setInt(_kBkColor, settings.bkColor.toARGB32());
    await prefs.setInt(_kTxColor, settings.txtColor.toARGB32());
    await prefs.setInt(_kBlankColor, settings.blankColor.toARGB32());
    await prefs.setInt(_kHiColor, settings.hiColor.toARGB32());
  }

  Map<String, String> _decodeStringMap(List<String>? raw) {
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    final Map<String, String> result = <String, String>{};
    for (final String entry in raw) {
      final int split = entry.indexOf('\t');
      if (split <= 0 || split >= entry.length - 1) {
        continue;
      }
      final String key = entry.substring(0, split).trim();
      final String value = entry.substring(split + 1).trim();
      if (key.isEmpty || value.isEmpty) {
        continue;
      }
      result[key] = value;
    }
    return result;
  }

  List<String> _encodeStringMap(Map<String, String> source) {
    final List<String> output = <String>[];
    source.forEach((String key, String value) {
      final String normalizedKey = key.trim();
      final String normalizedValue = value.trim();
      if (normalizedKey.isEmpty || normalizedValue.isEmpty) {
        return;
      }
      output.add('$normalizedKey\t$normalizedValue');
    });
    return output;
  }
}
