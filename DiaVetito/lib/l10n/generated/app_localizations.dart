import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In hu, this message translates to:
  /// **'DiaVetítő'**
  String get appTitle;

  /// No description provided for @logoTitle.
  ///
  /// In hu, this message translates to:
  /// **'Diatár Vetítő'**
  String get logoTitle;

  /// No description provided for @startupLogoSemanticLabel.
  ///
  /// In hu, this message translates to:
  /// **'Indító logó képernyő'**
  String get startupLogoSemanticLabel;

  /// No description provided for @splashVersionSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Verzió v{version} ({buildNumber})'**
  String splashVersionSubtitle(Object version, Object buildNumber);

  /// No description provided for @settingsTitleReceiver.
  ///
  /// In hu, this message translates to:
  /// **'Beállítások'**
  String get settingsTitleReceiver;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In hu, this message translates to:
  /// **'Verzió {version} ({buildNumber})'**
  String settingsVersionLabel(Object version, Object buildNumber);

  /// No description provided for @settingsSearchLabel.
  ///
  /// In hu, this message translates to:
  /// **'Keresés a beállításokban'**
  String get settingsSearchLabel;

  /// No description provided for @settingsNoResults.
  ///
  /// In hu, this message translates to:
  /// **'Nincs találat a keresésre.'**
  String get settingsNoResults;

  /// No description provided for @settingsInternetTitle.
  ///
  /// In hu, this message translates to:
  /// **'Internet'**
  String get settingsInternetTitle;

  /// No description provided for @settingsInternetSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Internetes közvetítés: {internet}, Felhasználó: {sender}'**
  String settingsInternetSubtitle(Object internet, Object sender);

  /// No description provided for @settingsLocalNetworkTitle.
  ///
  /// In hu, this message translates to:
  /// **'Helyi hálózat (TCP/IP)'**
  String get settingsLocalNetworkTitle;

  /// No description provided for @settingsLocalNetworkSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'TCP szerver: {status}, port: {port}'**
  String settingsLocalNetworkSubtitle(Object status, Object port);

  /// No description provided for @settingsLocalNetworkIpLabel.
  ///
  /// In hu, this message translates to:
  /// **'Eszköz IP: {ip}'**
  String settingsLocalNetworkIpLabel(Object ip);

  /// No description provided for @projectionImageTitle.
  ///
  /// In hu, this message translates to:
  /// **'Vetítési kép'**
  String get projectionImageTitle;

  /// No description provided for @projectionImageSummary.
  ///
  /// In hu, this message translates to:
  /// **'Forgatás: {rotation}, Tükrözés: {mirror}'**
  String projectionImageSummary(Object rotation, Object mirror);

  /// No description provided for @projectionColorSourceServer.
  ///
  /// In hu, this message translates to:
  /// **'Szerver színek'**
  String get projectionColorSourceServer;

  /// No description provided for @projectionColorSourceLocal.
  ///
  /// In hu, this message translates to:
  /// **'Helyi színek'**
  String get projectionColorSourceLocal;

  /// No description provided for @projectionFilterSummary.
  ///
  /// In hu, this message translates to:
  /// **'Színforrás: {source}, Görgethető: {scrollable}'**
  String projectionFilterSummary(Object source, Object scrollable);

  /// No description provided for @localColorsSummary.
  ///
  /// In hu, this message translates to:
  /// **'Háttér: {background}, Szöveg: {text}'**
  String localColorsSummary(Object background, Object text);

  /// No description provided for @settingsGeneralTitle.
  ///
  /// In hu, this message translates to:
  /// **'Általános'**
  String get settingsGeneralTitle;

  /// No description provided for @settingsGeneralSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Nyelv: {language}, Autostart: {autostart}'**
  String settingsGeneralSubtitle(Object language, Object autostart);

  /// No description provided for @systemActionsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Rendszer műveletek'**
  String get systemActionsTitle;

  /// No description provided for @systemActionsSummary.
  ///
  /// In hu, this message translates to:
  /// **'Távoli leállítás: {state}'**
  String systemActionsSummary(Object state);

  /// No description provided for @cameraStreamTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kántorszem – Kamera stream'**
  String get cameraStreamTitle;

  /// No description provided for @cameraStreamSummary.
  ///
  /// In hu, this message translates to:
  /// **'Kamera stream engedélyezve'**
  String get cameraStreamSummary;

  /// No description provided for @cameraStreamDevicesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kamera forrás'**
  String get cameraStreamDevicesTitle;

  /// No description provided for @cameraStreamShortcutHint.
  ///
  /// In hu, this message translates to:
  /// **'A vezérlő a helyi hálózaton keresztül kérheti a kameraképet.'**
  String get cameraStreamShortcutHint;

  /// No description provided for @cameraStreamEnabledTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kamera stream engedélyezése'**
  String get cameraStreamEnabledTitle;

  /// No description provided for @cameraStreamEnabledHint.
  ///
  /// In hu, this message translates to:
  /// **'Bekapcsolás után a vezérlő kérheti a kameraképet. Ehhez kamera-hozzáférés szükséges.'**
  String get cameraStreamEnabledHint;

  /// No description provided for @cameraStreamNoDevices.
  ///
  /// In hu, this message translates to:
  /// **'Nem található kamera'**
  String get cameraStreamNoDevices;

  /// No description provided for @refreshDevices.
  ///
  /// In hu, this message translates to:
  /// **'Eszközök frissítése'**
  String get refreshDevices;

  /// No description provided for @settingsSearchKeywordsCamera.
  ///
  /// In hu, this message translates to:
  /// **'kamera stream webrtc video előnézet'**
  String get settingsSearchKeywordsCamera;

  /// No description provided for @systemActionsBack.
  ///
  /// In hu, this message translates to:
  /// **'Vissza'**
  String get systemActionsBack;

  /// No description provided for @remoteShutdownTitle.
  ///
  /// In hu, this message translates to:
  /// **'Távoli leállítás'**
  String get remoteShutdownTitle;

  /// No description provided for @remoteShutdownSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Ha be van kapcsolva, a távoli vetítő leállíthatja a programot.'**
  String get remoteShutdownSubtitle;

  /// No description provided for @internetBroadcastTitle.
  ///
  /// In hu, this message translates to:
  /// **'Internetes közvetítés'**
  String get internetBroadcastTitle;

  /// No description provided for @valueOn.
  ///
  /// In hu, this message translates to:
  /// **'Be'**
  String get valueOn;

  /// No description provided for @valueOff.
  ///
  /// In hu, this message translates to:
  /// **'Ki'**
  String get valueOff;

  /// No description provided for @settingsSearchKeywordsInternet.
  ///
  /// In hu, this message translates to:
  /// **'internet mqtt sender channel kozvetites felhasznalo'**
  String get settingsSearchKeywordsInternet;

  /// No description provided for @settingsSearchKeywordsLan.
  ///
  /// In hu, this message translates to:
  /// **'helyi halozat tcp ip port'**
  String get settingsSearchKeywordsLan;

  /// No description provided for @settingsSearchKeywordsProjectionImage.
  ///
  /// In hu, this message translates to:
  /// **'vetitesi kep forgatas tukrozes clip margok'**
  String get settingsSearchKeywordsProjectionImage;

  /// No description provided for @settingsSearchKeywordsProjectionFilter.
  ///
  /// In hu, this message translates to:
  /// **'vetitesi szures akkord kotta highlight scroll'**
  String get settingsSearchKeywordsProjectionFilter;

  /// No description provided for @settingsSearchKeywordsColors.
  ///
  /// In hu, this message translates to:
  /// **'szinek hatter szoveg blank'**
  String get settingsSearchKeywordsColors;

  /// No description provided for @settingsSearchKeywordsGeneral.
  ///
  /// In hu, this message translates to:
  /// **'altalanos nyelv autostart boot'**
  String get settingsSearchKeywordsGeneral;

  /// No description provided for @settingsSearchKeywordsSystem.
  ///
  /// In hu, this message translates to:
  /// **'rendszer kilepes leallas'**
  String get settingsSearchKeywordsSystem;

  /// No description provided for @modeIp.
  ///
  /// In hu, this message translates to:
  /// **'IP'**
  String get modeIp;

  /// No description provided for @modeInternet.
  ///
  /// In hu, this message translates to:
  /// **'Internet'**
  String get modeInternet;

  /// No description provided for @tcpPortRange.
  ///
  /// In hu, this message translates to:
  /// **'TCP port (0..65535)'**
  String get tcpPortRange;

  /// No description provided for @senderLabel.
  ///
  /// In hu, this message translates to:
  /// **'Küldő'**
  String get senderLabel;

  /// No description provided for @senderHelper.
  ///
  /// In hu, this message translates to:
  /// **'MQTT sender neve'**
  String get senderHelper;

  /// No description provided for @senderRefreshTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Küldő lista frissítés'**
  String get senderRefreshTooltip;

  /// No description provided for @invalidMqttUsernameTitle.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen MQTT küldő'**
  String get invalidMqttUsernameTitle;

  /// No description provided for @invalidMqttUsername.
  ///
  /// In hu, this message translates to:
  /// **'Válassz regisztrált MQTT küldőnevet.'**
  String get invalidMqttUsername;

  /// No description provided for @channelLabel.
  ///
  /// In hu, this message translates to:
  /// **'Csatorna'**
  String get channelLabel;

  /// No description provided for @clipLeft.
  ///
  /// In hu, this message translates to:
  /// **'Bal'**
  String get clipLeft;

  /// No description provided for @clipTop.
  ///
  /// In hu, this message translates to:
  /// **'Felső'**
  String get clipTop;

  /// No description provided for @clipRight.
  ///
  /// In hu, this message translates to:
  /// **'Jobb'**
  String get clipRight;

  /// No description provided for @clipBottom.
  ///
  /// In hu, this message translates to:
  /// **'Alsó'**
  String get clipBottom;

  /// No description provided for @borderToClip.
  ///
  /// In hu, this message translates to:
  /// **'Margok a vezérlőtől (Border2Clip)'**
  String get borderToClip;

  /// No description provided for @mirror.
  ///
  /// In hu, this message translates to:
  /// **'Tükrözés'**
  String get mirror;

  /// No description provided for @autoBootIndicator.
  ///
  /// In hu, this message translates to:
  /// **'Automatikus indítás (jelző)'**
  String get autoBootIndicator;

  /// No description provided for @rotationLabel.
  ///
  /// In hu, this message translates to:
  /// **'Forgatás'**
  String get rotationLabel;

  /// No description provided for @uiLanguage.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználói felület nyelve'**
  String get uiLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In hu, this message translates to:
  /// **'Rendszer alapértelmezett'**
  String get languageSystem;

  /// No description provided for @languageHungarian.
  ///
  /// In hu, this message translates to:
  /// **'Magyar'**
  String get languageHungarian;

  /// No description provided for @languageEnglish.
  ///
  /// In hu, this message translates to:
  /// **'Angol'**
  String get languageEnglish;

  /// No description provided for @projectionFilteringTitle.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés szűrése'**
  String get projectionFilteringTitle;

  /// No description provided for @receiverUseServerColors.
  ///
  /// In hu, this message translates to:
  /// **'Szerver színei'**
  String get receiverUseServerColors;

  /// No description provided for @receiverUseServerColorsHint.
  ///
  /// In hu, this message translates to:
  /// **'Ha ki van kapcsolva, a helyi színek lesznek használva.'**
  String get receiverUseServerColorsHint;

  /// No description provided for @receiverShowHighlight.
  ///
  /// In hu, this message translates to:
  /// **'Kiemelés megjelenítése'**
  String get receiverShowHighlight;

  /// No description provided for @showChords.
  ///
  /// In hu, this message translates to:
  /// **'Akkordok mutatása'**
  String get showChords;

  /// No description provided for @showKotta.
  ///
  /// In hu, this message translates to:
  /// **'Kotta mutatása'**
  String get showKotta;

  /// No description provided for @scrollableProjection.
  ///
  /// In hu, this message translates to:
  /// **'Görgethető vetítés'**
  String get scrollableProjection;

  /// No description provided for @scrollableProjectionHint.
  ///
  /// In hu, this message translates to:
  /// **'Ha ki van kapcsolva, a szöveg automatikusan a vetítési területhez igazodik.'**
  String get scrollableProjectionHint;

  /// No description provided for @keepStartupLogo.
  ///
  /// In hu, this message translates to:
  /// **'Induló logo, ha nincs kapcsolat'**
  String get keepStartupLogo;

  /// No description provided for @keepStartupLogoHint.
  ///
  /// In hu, this message translates to:
  /// **'Ha megszakad az internet vagy a helyi hálózati kapcsolat, jelenjen meg újra a logo, amíg nincs kapcsolat.'**
  String get keepStartupLogoHint;

  /// No description provided for @settingsLongPressHint.
  ///
  /// In hu, this message translates to:
  /// **'Beállítások: nyomd hosszan.'**
  String get settingsLongPressHint;

  /// No description provided for @qrScanButton.
  ///
  /// In hu, this message translates to:
  /// **'QR beolvasás'**
  String get qrScanButton;

  /// No description provided for @qrScanTitle.
  ///
  /// In hu, this message translates to:
  /// **'QR-kód beolvasása'**
  String get qrScanTitle;

  /// No description provided for @qrScanHint.
  ///
  /// In hu, this message translates to:
  /// **'Irányítsd a kamerát a QR-kódra.'**
  String get qrScanHint;

  /// No description provided for @qrScanUnsupportedTitle.
  ///
  /// In hu, this message translates to:
  /// **'QR beolvasás nem elérhető'**
  String get qrScanUnsupportedTitle;

  /// No description provided for @qrScanUnsupportedMessage.
  ///
  /// In hu, this message translates to:
  /// **'Ezen az eszközön a kamerás QR beolvasás nem támogatott.'**
  String get qrScanUnsupportedMessage;

  /// No description provided for @qrScanUnknownLinkTitle.
  ///
  /// In hu, this message translates to:
  /// **'Ismeretlen link'**
  String get qrScanUnknownLinkTitle;

  /// No description provided for @qrScanUnknownLinkMessage.
  ///
  /// In hu, this message translates to:
  /// **'A beolvasott QR-kód nem a támogatott DiaVetítő hivatkozás.'**
  String get qrScanUnknownLinkMessage;

  /// No description provided for @qrScanConnectSuccessTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kapcsolódás sikeres'**
  String get qrScanConnectSuccessTitle;

  /// No description provided for @qrScanConnectFailedTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kapcsolódás sikertelen'**
  String get qrScanConnectFailedTitle;

  /// No description provided for @qrScanConnectResultPrefix.
  ///
  /// In hu, this message translates to:
  /// **'Felismert felhasználó: '**
  String get qrScanConnectResultPrefix;

  /// No description provided for @qrScanConnectSuccessSuffix.
  ///
  /// In hu, this message translates to:
  /// **'\nInternetes kapcsolat elindítva. A TCP kapcsolat kikapcsolt állapotba került.'**
  String get qrScanConnectSuccessSuffix;

  /// No description provided for @qrScanConnectFailedSuffix.
  ///
  /// In hu, this message translates to:
  /// **'\nNem sikerült internetes kapcsolódást létrehozni.'**
  String get qrScanConnectFailedSuffix;

  /// No description provided for @qrScanSenderSetTitle.
  ///
  /// In hu, this message translates to:
  /// **'Küldő beállítva'**
  String get qrScanSenderSetTitle;

  /// No description provided for @qrScanSenderSetMessage.
  ///
  /// In hu, this message translates to:
  /// **'A küldő mezőbe beírva: {user}'**
  String qrScanSenderSetMessage(Object user);

  /// No description provided for @localColorsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Helyi színek'**
  String get localColorsTitle;

  /// No description provided for @backgroundColorLabel.
  ///
  /// In hu, this message translates to:
  /// **'Háttérszín'**
  String get backgroundColorLabel;

  /// No description provided for @textColorLabel.
  ///
  /// In hu, this message translates to:
  /// **'Szövegszín'**
  String get textColorLabel;

  /// No description provided for @blankColorLabel.
  ///
  /// In hu, this message translates to:
  /// **'Blank szín'**
  String get blankColorLabel;

  /// No description provided for @highlightColorLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiemelés szín'**
  String get highlightColorLabel;

  /// No description provided for @change.
  ///
  /// In hu, this message translates to:
  /// **'Vált'**
  String get change;

  /// No description provided for @colorPickerTitle.
  ///
  /// In hu, this message translates to:
  /// **'Színválasztó'**
  String get colorPickerTitle;

  /// No description provided for @exit.
  ///
  /// In hu, this message translates to:
  /// **'Kilépés'**
  String get exit;

  /// No description provided for @shutdown.
  ///
  /// In hu, this message translates to:
  /// **'Leállítás'**
  String get shutdown;

  /// No description provided for @reboot.
  ///
  /// In hu, this message translates to:
  /// **'Újraindítás'**
  String get reboot;

  /// No description provided for @cancel.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In hu, this message translates to:
  /// **'Ment'**
  String get save;

  /// No description provided for @ok.
  ///
  /// In hu, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @invalidPortRange.
  ///
  /// In hu, this message translates to:
  /// **'A port 0..65535 között legyen.'**
  String get invalidPortRange;

  /// No description provided for @statusStarting.
  ///
  /// In hu, this message translates to:
  /// **'Indítás...'**
  String get statusStarting;

  /// No description provided for @statusExitRequested.
  ///
  /// In hu, this message translates to:
  /// **'Kilépés...'**
  String get statusExitRequested;

  /// No description provided for @statusShutdownRequested.
  ///
  /// In hu, this message translates to:
  /// **'Leállítás indítva...'**
  String get statusShutdownRequested;

  /// No description provided for @statusShutdownUnsupported.
  ///
  /// In hu, this message translates to:
  /// **'Rendszerleállítás Flutteren nem támogatott.'**
  String get statusShutdownUnsupported;

  /// No description provided for @statusShutdownDenied.
  ///
  /// In hu, this message translates to:
  /// **'Az operációs rendszer elutasította a leállítási kérést.'**
  String get statusShutdownDenied;

  /// No description provided for @shutdownConfirmDialogMessage.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan leállítod a számítógépet?'**
  String get shutdownConfirmDialogMessage;

  /// No description provided for @shutdownPermissionDeniedDialogMessage.
  ///
  /// In hu, this message translates to:
  /// **'Nincs jogosultság az eszköz leállításához.'**
  String get shutdownPermissionDeniedDialogMessage;

  /// No description provided for @statusRebootUnsupported.
  ///
  /// In hu, this message translates to:
  /// **'Rendszer újraindítás Flutteren nem támogatott.'**
  String get statusRebootUnsupported;

  /// No description provided for @statusStopRequested.
  ///
  /// In hu, this message translates to:
  /// **'Leállítás kérve (epStop).'**
  String get statusStopRequested;

  /// No description provided for @statusShutdownRequestedUnsupported.
  ///
  /// In hu, this message translates to:
  /// **'Rendszerleállítás kérve (epShutdown), Flutterben nem támogatott.'**
  String get statusShutdownRequestedUnsupported;

  /// No description provided for @statusReceiverError.
  ///
  /// In hu, this message translates to:
  /// **'{message}'**
  String statusReceiverError(Object message);

  /// No description provided for @statusMqttOff.
  ///
  /// In hu, this message translates to:
  /// **'MQTT kikapcsolva'**
  String get statusMqttOff;

  /// No description provided for @statusMqttReceiving.
  ///
  /// In hu, this message translates to:
  /// **'MQTT fogadás: {user}/{channel}'**
  String statusMqttReceiving(Object user, Object channel);

  /// No description provided for @statusConnected.
  ///
  /// In hu, this message translates to:
  /// **'Kapcsolódva ({port})'**
  String statusConnected(int port);

  /// No description provided for @statusWaitingForClient.
  ///
  /// In hu, this message translates to:
  /// **'Várakozás kliensre ({port})'**
  String statusWaitingForClient(int port);

  /// No description provided for @statusTcpOff.
  ///
  /// In hu, this message translates to:
  /// **'TCP kikapcsolva'**
  String get statusTcpOff;

  /// No description provided for @statusTcpListening.
  ///
  /// In hu, this message translates to:
  /// **'TCP figyelés: {port}'**
  String statusTcpListening(int port);

  /// No description provided for @statusTcpServerError.
  ///
  /// In hu, this message translates to:
  /// **'TCP hiba: {error}'**
  String statusTcpServerError(Object error);

  /// No description provided for @statusTcpServerOpenPortFailed.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült portot nyitni ({port}): {error}'**
  String statusTcpServerOpenPortFailed(int port, Object error);

  /// No description provided for @statusTcpServerClientError.
  ///
  /// In hu, this message translates to:
  /// **'Kliens hiba: {error}'**
  String statusTcpServerClientError(Object error);

  /// No description provided for @statusTcpServerPacketParseError.
  ///
  /// In hu, this message translates to:
  /// **'Csomag feldolgozási hiba: {error}'**
  String statusTcpServerPacketParseError(Object error);

  /// No description provided for @statusTcpServerSendError.
  ///
  /// In hu, this message translates to:
  /// **'Küldési hiba: {error}'**
  String statusTcpServerSendError(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
