// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DiaVetito';

  @override
  String get logoTitle => 'Diatar Vetito';

  @override
  String get startupLogoSemanticLabel => 'Startup logo screen';

  @override
  String splashVersionSubtitle(Object version, Object buildNumber) {
    return 'Version v$version ($buildNumber)';
  }

  @override
  String get settingsTitleReceiver => 'Settings';

  @override
  String settingsVersionLabel(Object version, Object buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get settingsSearchLabel => 'Search in settings';

  @override
  String get settingsNoResults => 'No results for your search.';

  @override
  String get settingsInternetTitle => 'Internet';

  @override
  String settingsInternetSubtitle(Object internet, Object sender) {
    return 'Internet relay: $internet, User: $sender';
  }

  @override
  String get settingsLocalNetworkTitle => 'Local network (TCP/IP)';

  @override
  String settingsLocalNetworkSubtitle(Object status, Object port) {
    return 'TCP server: $status, port: $port';
  }

  @override
  String settingsLocalNetworkIpLabel(Object ip) {
    return 'Device IP: $ip';
  }

  @override
  String get projectionImageTitle => 'Projection image';

  @override
  String projectionImageSummary(Object rotation, Object mirror) {
    return 'Rotation: $rotation, Mirroring: $mirror';
  }

  @override
  String get projectionColorSourceServer => 'Server colors';

  @override
  String get projectionColorSourceLocal => 'Local colors';

  @override
  String projectionFilterSummary(Object source, Object scrollable) {
    return 'Color source: $source, Scrollable: $scrollable';
  }

  @override
  String localColorsSummary(Object background, Object text) {
    return 'Background: $background, Text: $text';
  }

  @override
  String get settingsGeneralTitle => 'General';

  @override
  String settingsGeneralSubtitle(Object language, Object autostart) {
    return 'Language: $language, Autostart: $autostart';
  }

  @override
  String get systemActionsTitle => 'System actions';

  @override
  String systemActionsSummary(Object state) {
    return 'Remote shutdown: $state';
  }

  @override
  String get cameraStreamTitle => 'Cantor\'s Eye – Camera stream';

  @override
  String get cameraStreamSummary => 'Camera stream enabled';

  @override
  String get cameraStreamDevicesTitle => 'Camera source';

  @override
  String get cameraStreamShortcutHint =>
      'The controller can request the camera stream over the local network.';

  @override
  String get cameraStreamEnabledTitle => 'Enable camera stream';

  @override
  String get cameraStreamEnabledHint =>
      'When enabled, the controller can request the camera feed. Camera access permission is required.';

  @override
  String get cameraStreamNoDevices => 'No camera found';

  @override
  String get refreshDevices => 'Refresh devices';

  @override
  String get settingsSearchKeywordsCamera =>
      'camera stream webrtc video preview';

  @override
  String get systemActionsBack => 'Back';

  @override
  String get remoteShutdownTitle => 'Remote shutdown';

  @override
  String get remoteShutdownSubtitle =>
      'When enabled, remote epStop and epShutdown commands can stop the program.';

  @override
  String get internetBroadcastTitle => 'Internet relay';

  @override
  String get valueOn => 'On';

  @override
  String get valueOff => 'Off';

  @override
  String get settingsSearchKeywordsInternet =>
      'internet mqtt sender channel relay user';

  @override
  String get settingsSearchKeywordsLan => 'local network tcp ip port';

  @override
  String get settingsSearchKeywordsProjectionImage =>
      'projection image rotation mirror clip margins';

  @override
  String get settingsSearchKeywordsProjectionFilter =>
      'projection filters chords notation highlight scroll';

  @override
  String get settingsSearchKeywordsColors => 'colors background text blank';

  @override
  String get settingsSearchKeywordsGeneral => 'general language autostart boot';

  @override
  String get settingsSearchKeywordsSystem => 'system exit shutdown';

  @override
  String get modeIp => 'IP';

  @override
  String get modeInternet => 'Internet';

  @override
  String get tcpPortRange => 'TCP port (0..65535)';

  @override
  String get senderLabel => 'Sender';

  @override
  String get senderHelper => 'MQTT sender name';

  @override
  String get senderRefreshTooltip => 'Refresh sender list';

  @override
  String get invalidMqttUsernameTitle => 'Invalid MQTT sender';

  @override
  String get invalidMqttUsername => 'Select a registered MQTT sender name.';

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
  String get uiLanguage => 'User interface language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageHungarian => 'Hungarian';

  @override
  String get languageEnglish => 'English';

  @override
  String get projectionFilteringTitle => 'Projection filters';

  @override
  String get receiverUseServerColors => 'Server colors';

  @override
  String get receiverUseServerColorsHint =>
      'If disabled, local colors are used.';

  @override
  String get receiverShowHighlight => 'Show highlight';

  @override
  String get showChords => 'Show chords';

  @override
  String get showKotta => 'Show notation';

  @override
  String get scrollableProjection => 'Scrollable projection';

  @override
  String get scrollableProjectionHint =>
      'If turned off, text is auto-sized to fit the projection area.';

  @override
  String get keepStartupLogo => 'Startup logo when disconnected';

  @override
  String get keepStartupLogoHint =>
      'If internet or local network connection is lost, show the logo screen again until connection is restored.';

  @override
  String get settingsLongPressHint => 'Settings: press and hold.';

  @override
  String get qrScanButton => 'Scan QR';

  @override
  String get qrScanTitle => 'Scan QR code';

  @override
  String get qrScanHint => 'Point the camera at the QR code.';

  @override
  String get qrScanUnsupportedTitle => 'QR scanning unavailable';

  @override
  String get qrScanUnsupportedMessage =>
      'Camera QR scanning is not supported on this device.';

  @override
  String get qrScanUnknownLinkTitle => 'Unknown link';

  @override
  String get qrScanUnknownLinkMessage =>
      'The scanned QR code is not a supported DiaVetito link.';

  @override
  String get qrScanConnectSuccessTitle => 'Connection successful';

  @override
  String get qrScanConnectFailedTitle => 'Connection failed';

  @override
  String get qrScanConnectResultPrefix => 'Detected user: ';

  @override
  String get qrScanConnectSuccessSuffix =>
      '\nInternet connection started. TCP connection has been turned off.';

  @override
  String get qrScanConnectFailedSuffix =>
      '\nCould not establish internet connection.';

  @override
  String get qrScanSenderSetTitle => 'Sender set';

  @override
  String qrScanSenderSetMessage(Object user) {
    return 'Sender field updated to: $user';
  }

  @override
  String get localColorsTitle => 'Local colors';

  @override
  String get backgroundColorLabel => 'Background color';

  @override
  String get textColorLabel => 'Text color';

  @override
  String get blankColorLabel => 'Blank color';

  @override
  String get highlightColorLabel => 'Highlight color';

  @override
  String get change => 'Change';

  @override
  String get colorPickerTitle => 'Color picker';

  @override
  String get exit => 'Exit';

  @override
  String get shutdown => 'Shutdown';

  @override
  String get reboot => 'Reboot';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get ok => 'OK';

  @override
  String get invalidPortRange => 'Port must be between 0 and 65535.';

  @override
  String get statusStarting => 'Starting...';

  @override
  String get statusExitRequested => 'Exiting...';

  @override
  String get statusShutdownRequested => 'Shutdown requested...';

  @override
  String get statusShutdownUnsupported =>
      'System shutdown is not supported in Flutter.';

  @override
  String get statusShutdownDenied =>
      'The operating system denied the shutdown request.';

  @override
  String get shutdownConfirmDialogMessage =>
      'Are you sure you want to shut down the computer?';

  @override
  String get shutdownPermissionDeniedDialogMessage =>
      'No permission to shut down the device.';

  @override
  String get statusRebootUnsupported =>
      'System reboot is not supported in Flutter.';

  @override
  String get statusStopRequested => 'Stop requested (epStop).';

  @override
  String get statusShutdownRequestedUnsupported =>
      'Shutdown requested (epShutdown), unsupported in Flutter.';

  @override
  String statusReceiverError(Object message) {
    return '$message';
  }

  @override
  String get statusMqttOff => 'MQTT disabled';

  @override
  String statusMqttReceiving(Object user, Object channel) {
    return 'MQTT receiving: $user/$channel';
  }

  @override
  String statusConnected(int port) {
    return 'Connected ($port)';
  }

  @override
  String statusWaitingForClient(int port) {
    return 'Waiting for client ($port)';
  }

  @override
  String get statusTcpOff => 'TCP disabled';

  @override
  String statusTcpListening(int port) {
    return 'TCP listening: $port';
  }

  @override
  String statusTcpServerError(Object error) {
    return 'TCP error: $error';
  }

  @override
  String statusTcpServerOpenPortFailed(int port, Object error) {
    return 'Failed to open port ($port): $error';
  }

  @override
  String statusTcpServerClientError(Object error) {
    return 'Client error: $error';
  }

  @override
  String statusTcpServerPacketParseError(Object error) {
    return 'Packet parse error: $error';
  }

  @override
  String statusTcpServerSendError(Object error) {
    return 'Send error: $error';
  }
}
