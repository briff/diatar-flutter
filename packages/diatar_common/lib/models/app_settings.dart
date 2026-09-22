import 'package:flutter/widgets.dart';

class AppSettings {
  static const int minCustomOrderSets = 1;
  static const int maxCustomOrderSetsLimit = 20;
  static const int defaultMaxCustomOrderSets = 10;

  const AppSettings({
    this.port = 1024,
    this.tcpClientEnabled = true,
    this.tcpTargets = const <String>[],
    this.boot = false,
    this.remoteShutdownEnabled = false,
    this.borderToClip = false,
    this.clipL = 0,
    this.clipT = 0,
    this.clipR = 0,
    this.clipB = 0,
    this.mirror = false,
    this.showCameraView = false,
    this.cameraTarget,
    this.cameraViewWidth = 200,
    this.cameraViewHeight = 120,
    this.cameraStreamEnabled = false,
    this.cameraStreamDeviceId,
    this.rotateQuarterTurns = 0,
    this.wolEnabled = false,
    this.wolTargets = const <String>[],
    this.wolBroadcastAddress = '255.255.255.255',
    this.wolPort = 9,
    this.mqttUser = '',
    this.mqttPassword = '',
    this.internetRelayEnabled = false,
    this.mqttChannel = '1',
    this.dtxPath = '',
    this.blankPicPath = '',
    this.diaExportPath = '',
    this.diaExportUri = '',
    this.diaExportFileName = '',
    this.diaAutoSaveEnabled = false,
    this.projFontSize = 255,
    this.projTitleSize = 12,
    this.projLeftIndent = 2,
    this.projBorderL = 0,
    this.projBorderT = 0,
    this.projBorderR = 0,
    this.projBorderB = 0,
    this.projSpacingStep = 0,
    this.projAutoSize = true,
    this.projHCenter = false,
    this.projVCenter = true,
    this.projUseAkkord = false,
    this.projUseKotta = true,
    this.projInverseKotta = false,
    this.projUseTitle = true,
    this.projKottaArany = 100,
    this.projAkkordArany = 100,
    this.projBoldText = false,
    this.projBgMode = 1,
    this.projBackTrans = 0,
    this.projBlankTrans = 0,
    this.projShowBackgroundImage = true,
    this.homeViewMode = 0,
    this.homeShowHighlightControls = false,
    this.homeLayoutMode = 0,
    this.presentationControlsVisible = false,
    this.homeTopBarHidden = false,
    this.landscapeControlsRatio,
    this.appThemeMode = 0,
    this.appLanguage = '',
    this.maxCustomOrderSets = defaultMaxCustomOrderSets,
    this.projectionLocked = false,
    this.desktopProjectorEnabled = false,
    this.desktopProjectorMonitor = -1,
    this.desktopActionHotkeys = const <String, String>{},
    this.desktopSongHotkeys = const <String, String>{},
    this.desktopOrderSetHotkeys = const <String, String>{},
    this.externalCommandOnStart = '',
    this.externalCommandOnExit = '',
    this.externalCommandOnProjectionOn = '',
    this.externalCommandOnProjectionOff = '',
    this.receiverUseServerColors = true,
    this.receiverShowHighlight = true,
    this.receiverUseAkkord = true,
    this.receiverUseKotta = true,
    this.receiverKeepStartupLogo = true,
    this.useSound = false,
    this.advanceAfterMusic = false,
    this.liveSubtitlesEnabled = false,
    this.speechFeatureVisible = true,
    this.liveSubtitleDeviceId,
    this.liveSubtitleLanguage = 'auto',
    this.liveSubtitleModel = 'nemotron35_560ms',
    this.szentirasApiKey = '',
    Color? bkColor,
    Color? txtColor,
    Color? blankColor,
    Color? hiColor,
  }) : _bkColor = bkColor,
       _txtColor = txtColor,
       _blankColor = blankColor,
       _hiColor = hiColor;

  final int port;
  final bool tcpClientEnabled;
  final List<String> tcpTargets;
  final bool boot;
  final bool remoteShutdownEnabled;
  final bool borderToClip;
  final double clipL;
  final double clipT;
  final double clipR;
  final double clipB;
  final bool mirror;
  final bool showCameraView;
  final String? cameraTarget;
  final double cameraViewWidth;
  final double cameraViewHeight;
  final bool cameraStreamEnabled;
  final String? cameraStreamDeviceId;
  final int rotateQuarterTurns;
  final bool wolEnabled;
  final List<String> wolTargets;
  final String wolBroadcastAddress;
  final int wolPort;
  final String mqttUser;
  final String mqttPassword;
  final bool internetRelayEnabled;
  final String mqttChannel;
  final String dtxPath;
  final String blankPicPath;
  final String diaExportPath;
  final String diaExportUri;
  final String diaExportFileName;
  final bool diaAutoSaveEnabled;
  final int projFontSize;
  final int projTitleSize;
  final int projLeftIndent;
  final int projBorderL;
  final int projBorderT;
  final int projBorderR;
  final int projBorderB;
  final int projSpacingStep;
  final bool projAutoSize;
  final bool projHCenter;
  final bool projVCenter;
  final bool projUseAkkord;
  final bool projUseKotta;
  final bool projInverseKotta;
  final bool projUseTitle;
  final int projKottaArany;
  final int projAkkordArany;
  final bool projBoldText;
  final int projBgMode;
  final int projBackTrans;
  final int projBlankTrans;
  final bool projShowBackgroundImage;
  final int homeViewMode;
  final bool homeShowHighlightControls;
  final int homeLayoutMode;
  final bool presentationControlsVisible;
  final bool homeTopBarHidden;
  final double? landscapeControlsRatio;
  final int appThemeMode;
  final String appLanguage;
  final int maxCustomOrderSets;
  final bool projectionLocked;
  final bool desktopProjectorEnabled;
  final int desktopProjectorMonitor;
  final Map<String, String> desktopActionHotkeys;
  final Map<String, String> desktopSongHotkeys;
  final Map<String, String> desktopOrderSetHotkeys;
  final String externalCommandOnStart;
  final String externalCommandOnExit;
  final String externalCommandOnProjectionOn;
  final String externalCommandOnProjectionOff;
  final bool receiverUseServerColors;
  final bool receiverShowHighlight;
  final bool receiverUseAkkord;
  final bool receiverUseKotta;
  final bool receiverKeepStartupLogo;
  final bool useSound;
  final bool advanceAfterMusic;
  final bool liveSubtitlesEnabled;
  final bool speechFeatureVisible;
  final String? liveSubtitleDeviceId;
  final String liveSubtitleLanguage;
  final String liveSubtitleModel;
  final String szentirasApiKey;
  final Color? _bkColor;
  final Color? _txtColor;
  final Color? _blankColor;
  final Color? _hiColor;

  Color get bkColor => _bkColor ?? const Color(0xFF000000);
  Color get txtColor => _txtColor ?? const Color(0xFFFFFFFF);
  Color get blankColor => _blankColor ?? const Color(0xFF000000);
  Color get hiColor => _hiColor ?? const Color(0xFF00FFFF);

  bool get tcpEnabled =>
      !internetRelayEnabled && tcpClientEnabled && tcpTargets.isNotEmpty;

  EdgeInsets get clipInsets => EdgeInsets.fromLTRB(clipL, clipT, clipR, clipB);

  AppSettings copyWith({
    int? port,
    bool? tcpClientEnabled,
    List<String>? tcpTargets,
    bool? boot,
    bool? remoteShutdownEnabled,
    bool? borderToClip,
    double? clipL,
    double? clipT,
    double? clipR,
    double? clipB,
    bool? mirror,
    bool? showCameraView,
    String? cameraTarget,
    double? cameraViewWidth,
    double? cameraViewHeight,
    bool? cameraStreamEnabled,
    String? cameraStreamDeviceId,
    int? rotateQuarterTurns,
    bool? wolEnabled,
    List<String>? wolTargets,
    String? wolBroadcastAddress,
    int? wolPort,
    String? mqttUser,
    String? mqttPassword,
    bool? internetRelayEnabled,
    String? mqttChannel,
    String? dtxPath,
    String? blankPicPath,
    String? diaExportPath,
    String? diaExportUri,
    String? diaExportFileName,
    bool? diaAutoSaveEnabled,
    int? projFontSize,
    int? projTitleSize,
    int? projLeftIndent,
    int? projBorderL,
    int? projBorderT,
    int? projBorderR,
    int? projBorderB,
    int? projSpacingStep,
    bool? projAutoSize,
    bool? projHCenter,
    bool? projVCenter,
    bool? projUseAkkord,
    bool? projUseKotta,
    bool? projInverseKotta,
    bool? projUseTitle,
    int? projKottaArany,
    int? projAkkordArany,
    bool? projBoldText,
    int? projBgMode,
    int? projBackTrans,
    int? projBlankTrans,
    bool? projShowBackgroundImage,
    int? homeViewMode,
    bool? homeShowHighlightControls,
    int? homeLayoutMode,
    bool? presentationControlsVisible,
    bool? homeTopBarHidden,
    double? landscapeControlsRatio,
    int? appThemeMode,
    String? appLanguage,
    int? maxCustomOrderSets,
    bool? projectionLocked,
    bool? desktopProjectorEnabled,
    int? desktopProjectorMonitor,
    Map<String, String>? desktopActionHotkeys,
    Map<String, String>? desktopSongHotkeys,
    Map<String, String>? desktopOrderSetHotkeys,
    String? externalCommandOnStart,
    String? externalCommandOnExit,
    String? externalCommandOnProjectionOn,
    String? externalCommandOnProjectionOff,
    bool? receiverUseServerColors,
    bool? receiverShowHighlight,
    bool? receiverUseAkkord,
    bool? receiverUseKotta,
    bool? receiverKeepStartupLogo,
    bool? useSound,
    bool? advanceAfterMusic,
    bool? liveSubtitlesEnabled,
    bool? speechFeatureVisible,
    String? liveSubtitleDeviceId,
    String? liveSubtitleLanguage,
    String? liveSubtitleModel,
    String? szentirasApiKey,
    Color? bkColor,
    Color? txtColor,
    Color? blankColor,
    Color? hiColor,
  }) {
    return AppSettings(
      port: port ?? this.port,
      tcpClientEnabled: tcpClientEnabled ?? this.tcpClientEnabled,
      tcpTargets: tcpTargets ?? this.tcpTargets,
      boot: boot ?? this.boot,
      remoteShutdownEnabled:
          remoteShutdownEnabled ?? this.remoteShutdownEnabled,
      borderToClip: borderToClip ?? this.borderToClip,
      clipL: clipL ?? this.clipL,
      clipT: clipT ?? this.clipT,
      clipR: clipR ?? this.clipR,
      clipB: clipB ?? this.clipB,
      mirror: mirror ?? this.mirror,
      showCameraView: showCameraView ?? this.showCameraView,
      cameraTarget: cameraTarget ?? this.cameraTarget,
      cameraViewWidth: cameraViewWidth ?? this.cameraViewWidth,
      cameraViewHeight: cameraViewHeight ?? this.cameraViewHeight,
      cameraStreamEnabled: cameraStreamEnabled ?? this.cameraStreamEnabled,
      cameraStreamDeviceId: cameraStreamDeviceId ?? this.cameraStreamDeviceId,
      rotateQuarterTurns: rotateQuarterTurns ?? this.rotateQuarterTurns,
      wolEnabled: wolEnabled ?? this.wolEnabled,
      wolTargets: wolTargets ?? this.wolTargets,
      wolBroadcastAddress: wolBroadcastAddress ?? this.wolBroadcastAddress,
      wolPort: wolPort ?? this.wolPort,
      mqttUser: mqttUser ?? this.mqttUser,
      mqttPassword: mqttPassword ?? this.mqttPassword,
      internetRelayEnabled: internetRelayEnabled ?? this.internetRelayEnabled,
      mqttChannel: mqttChannel ?? this.mqttChannel,
      dtxPath: dtxPath ?? this.dtxPath,
      blankPicPath: blankPicPath ?? this.blankPicPath,
      diaExportPath: diaExportPath ?? this.diaExportPath,
      diaExportUri: diaExportUri ?? this.diaExportUri,
      diaExportFileName: diaExportFileName ?? this.diaExportFileName,
      diaAutoSaveEnabled: diaAutoSaveEnabled ?? this.diaAutoSaveEnabled,
      projFontSize: projFontSize ?? this.projFontSize,
      projTitleSize: projTitleSize ?? this.projTitleSize,
      projLeftIndent: projLeftIndent ?? this.projLeftIndent,
      projBorderL: projBorderL ?? this.projBorderL,
      projBorderT: projBorderT ?? this.projBorderT,
      projBorderR: projBorderR ?? this.projBorderR,
      projBorderB: projBorderB ?? this.projBorderB,
      projSpacingStep: projSpacingStep ?? this.projSpacingStep,
      projAutoSize: projAutoSize ?? this.projAutoSize,
      projHCenter: projHCenter ?? this.projHCenter,
      projVCenter: projVCenter ?? this.projVCenter,
      projUseAkkord: projUseAkkord ?? this.projUseAkkord,
      projUseKotta: projUseKotta ?? this.projUseKotta,
      projInverseKotta: projInverseKotta ?? this.projInverseKotta,
      projUseTitle: projUseTitle ?? this.projUseTitle,
      projKottaArany: projKottaArany ?? this.projKottaArany,
      projAkkordArany: projAkkordArany ?? this.projAkkordArany,
      projBoldText: projBoldText ?? this.projBoldText,
      projBgMode: projBgMode ?? this.projBgMode,
      projBackTrans: projBackTrans ?? this.projBackTrans,
      projBlankTrans: projBlankTrans ?? this.projBlankTrans,
      projShowBackgroundImage:
          projShowBackgroundImage ?? this.projShowBackgroundImage,
      homeViewMode: homeViewMode ?? this.homeViewMode,
      homeShowHighlightControls:
          homeShowHighlightControls ?? this.homeShowHighlightControls,
      homeLayoutMode: homeLayoutMode ?? this.homeLayoutMode,
      presentationControlsVisible:
          presentationControlsVisible ?? this.presentationControlsVisible,
      homeTopBarHidden: homeTopBarHidden ?? this.homeTopBarHidden,
      landscapeControlsRatio:
          landscapeControlsRatio ?? this.landscapeControlsRatio,
      appThemeMode: appThemeMode ?? this.appThemeMode,
      appLanguage: appLanguage ?? this.appLanguage,
      maxCustomOrderSets: maxCustomOrderSets ?? this.maxCustomOrderSets,
      projectionLocked: projectionLocked ?? this.projectionLocked,
      desktopProjectorEnabled:
          desktopProjectorEnabled ?? this.desktopProjectorEnabled,
      desktopProjectorMonitor:
          desktopProjectorMonitor ?? this.desktopProjectorMonitor,
      desktopActionHotkeys: desktopActionHotkeys ?? this.desktopActionHotkeys,
      desktopSongHotkeys: desktopSongHotkeys ?? this.desktopSongHotkeys,
      desktopOrderSetHotkeys:
          desktopOrderSetHotkeys ?? this.desktopOrderSetHotkeys,
      externalCommandOnStart:
          externalCommandOnStart ?? this.externalCommandOnStart,
      externalCommandOnExit:
          externalCommandOnExit ?? this.externalCommandOnExit,
      externalCommandOnProjectionOn:
          externalCommandOnProjectionOn ?? this.externalCommandOnProjectionOn,
      externalCommandOnProjectionOff:
          externalCommandOnProjectionOff ?? this.externalCommandOnProjectionOff,
      receiverUseServerColors:
          receiverUseServerColors ?? this.receiverUseServerColors,
      receiverShowHighlight:
          receiverShowHighlight ?? this.receiverShowHighlight,
      receiverUseAkkord: receiverUseAkkord ?? this.receiverUseAkkord,
      receiverUseKotta: receiverUseKotta ?? this.receiverUseKotta,
      receiverKeepStartupLogo:
          receiverKeepStartupLogo ?? this.receiverKeepStartupLogo,
      useSound: useSound ?? this.useSound,
      advanceAfterMusic: advanceAfterMusic ?? this.advanceAfterMusic,
      liveSubtitlesEnabled: liveSubtitlesEnabled ?? this.liveSubtitlesEnabled,
      speechFeatureVisible: speechFeatureVisible ?? this.speechFeatureVisible,
      liveSubtitleDeviceId: liveSubtitleDeviceId ?? this.liveSubtitleDeviceId,
      liveSubtitleLanguage: liveSubtitleLanguage ?? this.liveSubtitleLanguage,
      liveSubtitleModel: liveSubtitleModel ?? this.liveSubtitleModel,
      szentirasApiKey: szentirasApiKey ?? this.szentirasApiKey,
      bkColor: bkColor ?? this.bkColor,
      txtColor: txtColor ?? this.txtColor,
      blankColor: blankColor ?? this.blankColor,
      hiColor: hiColor ?? this.hiColor,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'clipL': clipL,
      'clipT': clipT,
      'clipR': clipR,
      'clipB': clipB,
      'mirror': mirror,
      'showCameraView': showCameraView,
      'cameraTarget': cameraTarget,
      'cameraStreamEnabled': cameraStreamEnabled,
      'cameraStreamDeviceId': cameraStreamDeviceId,
      'rotateQuarterTurns': rotateQuarterTurns,
      'projFontSize': projFontSize,
      'projTitleSize': projTitleSize,
      'projLeftIndent': projLeftIndent,
      'projBorderL': projBorderL,
      'projBorderT': projBorderT,
      'projBorderR': projBorderR,
      'projBorderB': projBorderB,
      'projSpacingStep': projSpacingStep,
      'projAutoSize': projAutoSize,
      'projHCenter': projHCenter,
      'projVCenter': projVCenter,
      'projUseAkkord': projUseAkkord,
      'projUseKotta': projUseKotta,
      'projInverseKotta': projInverseKotta,
      'projUseTitle': projUseTitle,
      'projKottaArany': projKottaArany,
      'projAkkordArany': projAkkordArany,
      'projBoldText': projBoldText,
      'projBgMode': projBgMode,
      'projBackTrans': projBackTrans,
      'projBlankTrans': projBlankTrans,
      'projShowBackgroundImage': projShowBackgroundImage,
      'maxCustomOrderSets': maxCustomOrderSets,
      'desktopProjectorEnabled': desktopProjectorEnabled,
      'desktopProjectorMonitor': desktopProjectorMonitor,
      'externalCommandOnStart': externalCommandOnStart,
      'externalCommandOnExit': externalCommandOnExit,
      'externalCommandOnProjectionOn': externalCommandOnProjectionOn,
      'externalCommandOnProjectionOff': externalCommandOnProjectionOff,
      'bkColor': bkColor.toARGB32(),
      'txtColor': txtColor.toARGB32(),
      'blankColor': blankColor.toARGB32(),
      'hiColor': hiColor.toARGB32(),
      'receiverUseServerColors': receiverUseServerColors,
      'receiverShowHighlight': receiverShowHighlight,
      'receiverUseAkkord': receiverUseAkkord,
      'receiverUseKotta': receiverUseKotta,
      'receiverKeepStartupLogo': receiverKeepStartupLogo,
      'useSound': useSound,
      'advanceAfterMusic': advanceAfterMusic,
      'liveSubtitlesEnabled': liveSubtitlesEnabled,
      'speechFeatureVisible': speechFeatureVisible,
      'liveSubtitleDeviceId': liveSubtitleDeviceId,
      'liveSubtitleLanguage': liveSubtitleLanguage,
      'liveSubtitleModel': liveSubtitleModel,
      'szentirasApiKey': szentirasApiKey,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    int intValue(String key, int fallback) {
      final Object? raw = map[key];
      if (raw is int) {
        return raw;
      }
      if (raw is num) {
        return raw.toInt();
      }
      return fallback;
    }

    bool boolValue(String key, bool fallback) {
      final Object? raw = map[key];
      if (raw is bool) {
        return raw;
      }
      return fallback;
    }

    Color colorValue(String key, Color fallback) {
      final Object? raw = map[key];
      if (raw is int) {
        return Color(raw);
      }
      if (raw is num) {
        return Color(raw.toInt());
      }
      return fallback;
    }

    return AppSettings(
      clipL: (map['clipL'] as num?)?.toDouble() ?? 0,
      clipT: (map['clipT'] as num?)?.toDouble() ?? 0,
      clipR: (map['clipR'] as num?)?.toDouble() ?? 0,
      clipB: (map['clipB'] as num?)?.toDouble() ?? 0,
      mirror: boolValue('mirror', false),
      showCameraView: boolValue('showCameraView', false),
      cameraTarget: map['cameraTarget'] as String?,
      cameraStreamEnabled: boolValue('cameraStreamEnabled', false),
      cameraStreamDeviceId: map['cameraStreamDeviceId'] as String?,
      rotateQuarterTurns: intValue('rotateQuarterTurns', 0),
      projFontSize: intValue('projFontSize', 70),
      projTitleSize: intValue('projTitleSize', 12),
      projLeftIndent: intValue('projLeftIndent', 2),
      projBorderL: intValue('projBorderL', 0),
      projBorderT: intValue('projBorderT', 0),
      projBorderR: intValue('projBorderR', 0),
      projBorderB: intValue('projBorderB', 0),
      projSpacingStep: intValue('projSpacingStep', 0),
      projAutoSize: boolValue('projAutoSize', true),
      projHCenter: boolValue('projHCenter', false),
      projVCenter: boolValue('projVCenter', true),
      projUseAkkord: boolValue('projUseAkkord', false),
      projUseKotta: boolValue('projUseKotta', true),
      projInverseKotta: boolValue('projInverseKotta', false),
      projUseTitle: boolValue('projUseTitle', true),
      projKottaArany: intValue('projKottaArany', 100),
      projAkkordArany: intValue('projAkkordArany', 100),
      projBoldText: boolValue('projBoldText', false),
      projBgMode: intValue('projBgMode', 0),
      projBackTrans: intValue('projBackTrans', 0),
      projBlankTrans: intValue('projBlankTrans', 0),
      projShowBackgroundImage: boolValue('projShowBackgroundImage', true),
      maxCustomOrderSets: intValue(
        'maxCustomOrderSets',
        defaultMaxCustomOrderSets,
      ).clamp(minCustomOrderSets, maxCustomOrderSetsLimit),
      desktopProjectorEnabled: boolValue('desktopProjectorEnabled', false),
      desktopProjectorMonitor: intValue('desktopProjectorMonitor', -1),
      externalCommandOnStart: map['externalCommandOnStart'] as String? ?? '',
      externalCommandOnExit: map['externalCommandOnExit'] as String? ?? '',
      externalCommandOnProjectionOn:
          map['externalCommandOnProjectionOn'] as String? ?? '',
      externalCommandOnProjectionOff:
          map['externalCommandOnProjectionOff'] as String? ?? '',
      bkColor: colorValue('bkColor', const Color(0xFF000000)),
      txtColor: colorValue('txtColor', const Color(0xFFFFFFFF)),
      blankColor: colorValue('blankColor', const Color(0xFF000000)),
      hiColor: colorValue('hiColor', const Color(0xFF00FFFF)),
      receiverUseServerColors: boolValue('receiverUseServerColors', true),
      receiverShowHighlight: boolValue('receiverShowHighlight', true),
      receiverUseAkkord: boolValue('receiverUseAkkord', true),
      receiverUseKotta: boolValue('receiverUseKotta', true),
      receiverKeepStartupLogo: boolValue('receiverKeepStartupLogo', true),
      useSound: boolValue('useSound', false),
      advanceAfterMusic: boolValue('advanceAfterMusic', false),
      liveSubtitlesEnabled: boolValue('liveSubtitlesEnabled', false),
      speechFeatureVisible: boolValue('speechFeatureVisible', true),
      liveSubtitleDeviceId: map['liveSubtitleDeviceId'] as String?,
      liveSubtitleLanguage: map['liveSubtitleLanguage'] as String? ?? 'auto',
      liveSubtitleModel:
          map['liveSubtitleModel'] as String? ?? 'nemotron35_560ms',
      szentirasApiKey: map['szentirasApiKey'] as String? ?? '',
    );
  }
}
