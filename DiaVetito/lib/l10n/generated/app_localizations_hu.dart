// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'DiaVetítő';

  @override
  String get logoTitle => 'Diatár Vetítő';

  @override
  String get startupLogoSemanticLabel => 'Indító logó képernyő';

  @override
  String splashVersionSubtitle(Object version, Object buildNumber) {
    return 'Verzió v$version ($buildNumber)';
  }

  @override
  String get settingsTitleReceiver => 'Beállítások';

  @override
  String settingsVersionLabel(Object version, Object buildNumber) {
    return 'Verzió $version ($buildNumber)';
  }

  @override
  String get settingsSearchLabel => 'Keresés a beállításokban';

  @override
  String get settingsNoResults => 'Nincs találat a keresésre.';

  @override
  String get settingsInternetTitle => 'Internet';

  @override
  String settingsInternetSubtitle(Object internet, Object sender) {
    return 'Internetes közvetítés: $internet, Felhasználó: $sender';
  }

  @override
  String get settingsLocalNetworkTitle => 'Helyi hálózat (TCP/IP)';

  @override
  String settingsLocalNetworkSubtitle(Object status, Object port) {
    return 'TCP szerver: $status, port: $port';
  }

  @override
  String settingsLocalNetworkIpLabel(Object ip) {
    return 'Eszköz IP: $ip';
  }

  @override
  String get projectionImageTitle => 'Vetítési kép';

  @override
  String projectionImageSummary(Object rotation, Object mirror) {
    return 'Forgatás: $rotation, Tükrözés: $mirror';
  }

  @override
  String get projectionColorSourceServer => 'Szerver színek';

  @override
  String get projectionColorSourceLocal => 'Helyi színek';

  @override
  String projectionFilterSummary(Object source, Object scrollable) {
    return 'Színforrás: $source, Görgethető: $scrollable';
  }

  @override
  String localColorsSummary(Object background, Object text) {
    return 'Háttér: $background, Szöveg: $text';
  }

  @override
  String get settingsGeneralTitle => 'Általános';

  @override
  String settingsGeneralSubtitle(Object language, Object autostart) {
    return 'Nyelv: $language, Autostart: $autostart';
  }

  @override
  String get systemActionsTitle => 'Rendszer műveletek';

  @override
  String systemActionsSummary(Object state) {
    return 'Távoli leállítás: $state';
  }

  @override
  String get cameraStreamTitle => 'Kántorszem – Kamera stream';

  @override
  String get cameraStreamSummary => 'Kamera stream engedélyezve';

  @override
  String get cameraStreamDevicesTitle => 'Kamera forrás';

  @override
  String get cameraStreamShortcutHint =>
      'A vezérlő a helyi hálózaton keresztül kérheti a kameraképet.';

  @override
  String get cameraStreamEnabledTitle => 'Kamera stream engedélyezése';

  @override
  String get cameraStreamEnabledHint =>
      'Bekapcsolás után a vezérlő kérheti a kameraképet. Ehhez kamera-hozzáférés szükséges.';

  @override
  String get cameraStreamNoDevices => 'Nem található kamera';

  @override
  String get refreshDevices => 'Eszközök frissítése';

  @override
  String get settingsSearchKeywordsCamera =>
      'kamera stream webrtc video előnézet';

  @override
  String get systemActionsBack => 'Vissza';

  @override
  String get remoteShutdownTitle => 'Távoli leállítás';

  @override
  String get remoteShutdownSubtitle =>
      'Ha be van kapcsolva, a távoli vetítő leállíthatja a programot.';

  @override
  String get internetBroadcastTitle => 'Internetes közvetítés';

  @override
  String get valueOn => 'Be';

  @override
  String get valueOff => 'Ki';

  @override
  String get settingsSearchKeywordsInternet =>
      'internet mqtt sender channel kozvetites felhasznalo';

  @override
  String get settingsSearchKeywordsLan => 'helyi halozat tcp ip port';

  @override
  String get settingsSearchKeywordsProjectionImage =>
      'vetitesi kep forgatas tukrozes clip margok';

  @override
  String get settingsSearchKeywordsProjectionFilter =>
      'vetitesi szures akkord kotta highlight scroll';

  @override
  String get settingsSearchKeywordsColors => 'szinek hatter szoveg blank';

  @override
  String get settingsSearchKeywordsGeneral => 'altalanos nyelv autostart boot';

  @override
  String get settingsSearchKeywordsSystem => 'rendszer kilepes leallas';

  @override
  String get modeIp => 'IP';

  @override
  String get modeInternet => 'Internet';

  @override
  String get tcpPortRange => 'TCP port (0..65535)';

  @override
  String get senderLabel => 'Küldő';

  @override
  String get senderHelper => 'MQTT sender neve';

  @override
  String get senderRefreshTooltip => 'Küldő lista frissítés';

  @override
  String get invalidMqttUsernameTitle => 'Érvénytelen MQTT küldő';

  @override
  String get invalidMqttUsername => 'Válassz regisztrált MQTT küldőnevet.';

  @override
  String get channelLabel => 'Csatorna';

  @override
  String get clipLeft => 'Bal';

  @override
  String get clipTop => 'Felső';

  @override
  String get clipRight => 'Jobb';

  @override
  String get clipBottom => 'Alsó';

  @override
  String get borderToClip => 'Margok a vezérlőtől (Border2Clip)';

  @override
  String get mirror => 'Tükrözés';

  @override
  String get autoBootIndicator => 'Automatikus indítás (jelző)';

  @override
  String get rotationLabel => 'Forgatás';

  @override
  String get uiLanguage => 'Felhasználói felület nyelve';

  @override
  String get languageSystem => 'Rendszer alapértelmezett';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get languageEnglish => 'Angol';

  @override
  String get projectionFilteringTitle => 'Vetítés szűrése';

  @override
  String get receiverUseServerColors => 'Szerver színei';

  @override
  String get receiverUseServerColorsHint =>
      'Ha ki van kapcsolva, a helyi színek lesznek használva.';

  @override
  String get receiverShowHighlight => 'Kiemelés megjelenítése';

  @override
  String get showChords => 'Akkordok mutatása';

  @override
  String get showKotta => 'Kotta mutatása';

  @override
  String get scrollableProjection => 'Görgethető vetítés';

  @override
  String get scrollableProjectionHint =>
      'Ha ki van kapcsolva, a szöveg automatikusan a vetítési területhez igazodik.';

  @override
  String get keepStartupLogo => 'Induló logo, ha nincs kapcsolat';

  @override
  String get keepStartupLogoHint =>
      'Ha megszakad az internet vagy a helyi hálózati kapcsolat, jelenjen meg újra a logo, amíg nincs kapcsolat.';

  @override
  String get settingsLongPressHint => 'Beállítások: nyomd hosszan.';

  @override
  String get qrScanButton => 'QR beolvasás';

  @override
  String get qrScanTitle => 'QR-kód beolvasása';

  @override
  String get qrScanHint => 'Irányítsd a kamerát a QR-kódra.';

  @override
  String get qrScanUnsupportedTitle => 'QR beolvasás nem elérhető';

  @override
  String get qrScanUnsupportedMessage =>
      'Ezen az eszközön a kamerás QR beolvasás nem támogatott.';

  @override
  String get qrScanUnknownLinkTitle => 'Ismeretlen link';

  @override
  String get qrScanUnknownLinkMessage =>
      'A beolvasott QR-kód nem a támogatott DiaVetítő hivatkozás.';

  @override
  String get qrScanConnectSuccessTitle => 'Kapcsolódás sikeres';

  @override
  String get qrScanConnectFailedTitle => 'Kapcsolódás sikertelen';

  @override
  String get qrScanConnectResultPrefix => 'Felismert felhasználó: ';

  @override
  String get qrScanConnectSuccessSuffix =>
      '\nInternetes kapcsolat elindítva. A TCP kapcsolat kikapcsolt állapotba került.';

  @override
  String get qrScanConnectFailedSuffix =>
      '\nNem sikerült internetes kapcsolódást létrehozni.';

  @override
  String get qrScanSenderSetTitle => 'Küldő beállítva';

  @override
  String qrScanSenderSetMessage(Object user) {
    return 'A küldő mezőbe beírva: $user';
  }

  @override
  String get localColorsTitle => 'Helyi színek';

  @override
  String get backgroundColorLabel => 'Háttérszín';

  @override
  String get textColorLabel => 'Szövegszín';

  @override
  String get blankColorLabel => 'Blank szín';

  @override
  String get highlightColorLabel => 'Kiemelés szín';

  @override
  String get change => 'Vált';

  @override
  String get colorPickerTitle => 'Színválasztó';

  @override
  String get exit => 'Kilépés';

  @override
  String get shutdown => 'Leállítás';

  @override
  String get reboot => 'Újraindítás';

  @override
  String get cancel => 'Mégse';

  @override
  String get save => 'Ment';

  @override
  String get ok => 'OK';

  @override
  String get invalidPortRange => 'A port 0..65535 között legyen.';

  @override
  String get statusStarting => 'Indítás...';

  @override
  String get statusExitRequested => 'Kilépés...';

  @override
  String get statusShutdownRequested => 'Leállítás indítva...';

  @override
  String get statusShutdownUnsupported =>
      'Rendszerleállítás Flutteren nem támogatott.';

  @override
  String get statusShutdownDenied =>
      'Az operációs rendszer elutasította a leállítási kérést.';

  @override
  String get shutdownConfirmDialogMessage =>
      'Biztosan leállítod a számítógépet?';

  @override
  String get shutdownPermissionDeniedDialogMessage =>
      'Nincs jogosultság az eszköz leállításához.';

  @override
  String get statusRebootUnsupported =>
      'Rendszer újraindítás Flutteren nem támogatott.';

  @override
  String get statusStopRequested => 'Leállítás kérve (epStop).';

  @override
  String get statusShutdownRequestedUnsupported =>
      'Rendszerleállítás kérve (epShutdown), Flutterben nem támogatott.';

  @override
  String statusReceiverError(Object message) {
    return '$message';
  }

  @override
  String get statusMqttOff => 'MQTT kikapcsolva';

  @override
  String statusMqttReceiving(Object user, Object channel) {
    return 'MQTT fogadás: $user/$channel';
  }

  @override
  String statusConnected(int port) {
    return 'Kapcsolódva ($port)';
  }

  @override
  String statusWaitingForClient(int port) {
    return 'Várakozás kliensre ($port)';
  }

  @override
  String get statusTcpOff => 'TCP kikapcsolva';

  @override
  String statusTcpListening(int port) {
    return 'TCP figyelés: $port';
  }

  @override
  String statusTcpServerError(Object error) {
    return 'TCP hiba: $error';
  }

  @override
  String statusTcpServerOpenPortFailed(int port, Object error) {
    return 'Nem sikerült portot nyitni ($port): $error';
  }

  @override
  String statusTcpServerClientError(Object error) {
    return 'Kliens hiba: $error';
  }

  @override
  String statusTcpServerPacketParseError(Object error) {
    return 'Csomag feldolgozási hiba: $error';
  }

  @override
  String statusTcpServerSendError(Object error) {
    return 'Küldési hiba: $error';
  }
}
