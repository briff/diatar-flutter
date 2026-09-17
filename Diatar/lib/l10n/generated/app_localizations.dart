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
  /// **'Diatár'**
  String get appTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Beállítások'**
  String get settingsTooltip;

  /// No description provided for @playlistsTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Diasorok'**
  String get playlistsTooltip;

  /// No description provided for @playlistsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Diasorok'**
  String get playlistsTitle;

  /// No description provided for @customOrderTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Szerkesztő'**
  String get customOrderTooltip;

  /// No description provided for @zsolozsmaTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Zsolozsma'**
  String get zsolozsmaTooltip;

  /// No description provided for @zsolozsmaTitle.
  ///
  /// In hu, this message translates to:
  /// **'Zsolozsma kiválasztása'**
  String get zsolozsmaTitle;

  /// No description provided for @zsolozsmaDateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Dátum'**
  String get zsolozsmaDateLabel;

  /// No description provided for @zsolozsmaPickDate.
  ///
  /// In hu, this message translates to:
  /// **'Dátum választása'**
  String get zsolozsmaPickDate;

  /// No description provided for @zsolozsmaSyncButton.
  ///
  /// In hu, this message translates to:
  /// **'Éves ZIP frissítés'**
  String get zsolozsmaSyncButton;

  /// No description provided for @zsolozsmaNoItems.
  ///
  /// In hu, this message translates to:
  /// **'Erre a napra nincs elérhető napszak lista.'**
  String get zsolozsmaNoItems;

  /// No description provided for @zsolozsmaDiagnosticsLabel.
  ///
  /// In hu, this message translates to:
  /// **'Diagnosztika'**
  String get zsolozsmaDiagnosticsLabel;

  /// No description provided for @zsolozsmaSelectionHint.
  ///
  /// In hu, this message translates to:
  /// **'A kiválasztás most még csak listáz és kijelöl. A diasorra bontás a következő lépésben érkezik.'**
  String get zsolozsmaSelectionHint;

  /// No description provided for @batyuTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Napi lelki batyu'**
  String get batyuTooltip;

  /// No description provided for @batyuTitle.
  ///
  /// In hu, this message translates to:
  /// **'Napi lelki batyu importálása'**
  String get batyuTitle;

  /// No description provided for @batyuDateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Dátum'**
  String get batyuDateLabel;

  /// No description provided for @batyuWordsPerSlide.
  ///
  /// In hu, this message translates to:
  /// **'Szavak száma diánként'**
  String get batyuWordsPerSlide;

  /// No description provided for @batyuNoItems.
  ///
  /// In hu, this message translates to:
  /// **'Erre a napra nincs elérhető olvasmány a Napi lelki batyuban.'**
  String get batyuNoItems;

  /// No description provided for @batyuBookLabel.
  ///
  /// In hu, this message translates to:
  /// **'Napi lelki batyu ({name})'**
  String batyuBookLabel(Object name);

  /// No description provided for @addSlideTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Dia hozzáadása'**
  String get addSlideTooltip;

  /// No description provided for @addTextSlide.
  ///
  /// In hu, this message translates to:
  /// **'Szöveges dia'**
  String get addTextSlide;

  /// No description provided for @addImageSlide.
  ///
  /// In hu, this message translates to:
  /// **'Képes dia'**
  String get addImageSlide;

  /// No description provided for @addImageSlideTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Kép hozzáadása'**
  String get addImageSlideTooltip;

  /// No description provided for @downloadBooksTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Énektárak letöltése'**
  String get downloadBooksTooltip;

  /// No description provided for @downloadDtz.
  ///
  /// In hu, this message translates to:
  /// **'DTZ letöltése'**
  String get downloadDtz;

  /// No description provided for @downloadDtzTitle.
  ///
  /// In hu, this message translates to:
  /// **'DTX kották (DTZ) letöltése'**
  String get downloadDtzTitle;

  /// No description provided for @downloadDtzHint.
  ///
  /// In hu, this message translates to:
  /// **'Jelöld be a letölteni kívánt DTZ fájlokat és a hozzájuk tartozó képeket (zip).'**
  String get downloadDtzHint;

  /// No description provided for @downloadDtzWithImages.
  ///
  /// In hu, this message translates to:
  /// **'Képek (zip) is'**
  String get downloadDtzWithImages;

  /// No description provided for @downloadDtzCount.
  ///
  /// In hu, this message translates to:
  /// **'{count} elem kijelölve'**
  String downloadDtzCount(int count);

  /// No description provided for @downloadDtzNoItems.
  ///
  /// In hu, this message translates to:
  /// **'Nincs letölthető DTZ fájl.'**
  String get downloadDtzNoItems;

  /// No description provided for @downloadTabDtx.
  ///
  /// In hu, this message translates to:
  /// **'Kötetek'**
  String get downloadTabDtx;

  /// No description provided for @downloadTabDtz.
  ///
  /// In hu, this message translates to:
  /// **'Kották'**
  String get downloadTabDtz;

  /// No description provided for @downloadTabMusic.
  ///
  /// In hu, this message translates to:
  /// **'Zenék'**
  String get downloadTabMusic;

  /// No description provided for @downloadTitle.
  ///
  /// In hu, this message translates to:
  /// **'Letöltés'**
  String get downloadTitle;

  /// No description provided for @downloadManagerNameColumn.
  ///
  /// In hu, this message translates to:
  /// **'Kötetek'**
  String get downloadManagerNameColumn;

  /// No description provided for @downloadManagerUpdateColumn.
  ///
  /// In hu, this message translates to:
  /// **'Frissítés'**
  String get downloadManagerUpdateColumn;

  /// No description provided for @downloadManagerExcludedColumn.
  ///
  /// In hu, this message translates to:
  /// **'Mellőzött'**
  String get downloadManagerExcludedColumn;

  /// No description provided for @downloadManagerUserImportedTag.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználói import'**
  String get downloadManagerUserImportedTag;

  /// No description provided for @downloadManagerUpdateAvailable.
  ///
  /// In hu, this message translates to:
  /// **'Frissíthető'**
  String get downloadManagerUpdateAvailable;

  /// No description provided for @downloadManagerUpToDate.
  ///
  /// In hu, this message translates to:
  /// **'Naprakész'**
  String get downloadManagerUpToDate;

  /// No description provided for @downloadUserImportedGroup.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználói'**
  String get downloadUserImportedGroup;

  /// No description provided for @downloadMessage.
  ///
  /// In hu, this message translates to:
  /// **'A letöltési párbeszéd később visszahelyezhető.'**
  String get downloadMessage;

  /// No description provided for @refreshTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Frissítés'**
  String get refreshTooltip;

  /// No description provided for @ok.
  ///
  /// In hu, this message translates to:
  /// **'Rendben'**
  String get ok;

  /// No description provided for @songPrev.
  ///
  /// In hu, this message translates to:
  /// **'Ének -'**
  String get songPrev;

  /// No description provided for @songNext.
  ///
  /// In hu, this message translates to:
  /// **'Ének +'**
  String get songNext;

  /// No description provided for @projectionOn.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés BE'**
  String get projectionOn;

  /// No description provided for @projectionOff.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés KI'**
  String get projectionOff;

  /// No description provided for @hideControlWindow.
  ///
  /// In hu, this message translates to:
  /// **'Vezérlő ablak elrejtése'**
  String get hideControlWindow;

  /// No description provided for @previous.
  ///
  /// In hu, this message translates to:
  /// **'Előző'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In hu, this message translates to:
  /// **'Következő'**
  String get next;

  /// No description provided for @highlightPrev.
  ///
  /// In hu, this message translates to:
  /// **'Szókiemelés ←'**
  String get highlightPrev;

  /// No description provided for @highlightNext.
  ///
  /// In hu, this message translates to:
  /// **'Szókiemelés →'**
  String get highlightNext;

  /// No description provided for @positionLabel.
  ///
  /// In hu, this message translates to:
  /// **'Pozíció: {current}/{total}'**
  String positionLabel(int current, int total);

  /// No description provided for @statusLabel.
  ///
  /// In hu, this message translates to:
  /// **'Státusz: {status}'**
  String statusLabel(Object status);

  /// No description provided for @statusStarting.
  ///
  /// In hu, this message translates to:
  /// **'Indítás...'**
  String get statusStarting;

  /// No description provided for @statusSenderError.
  ///
  /// In hu, this message translates to:
  /// **'{message}'**
  String statusSenderError(Object message);

  /// No description provided for @statusSenderTcpError.
  ///
  /// In hu, this message translates to:
  /// **'TCP hiba: {error}'**
  String statusSenderTcpError(Object error);

  /// No description provided for @statusSenderOpenPortFailed.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült portot nyitni ({port}): {error}'**
  String statusSenderOpenPortFailed(int port, Object error);

  /// No description provided for @statusSenderMqttConnectFailed.
  ///
  /// In hu, this message translates to:
  /// **'MQTT sender kapcsolódás sikertelen.'**
  String get statusSenderMqttConnectFailed;

  /// No description provided for @statusSenderMqttError.
  ///
  /// In hu, this message translates to:
  /// **'MQTT sender hiba: {error}'**
  String statusSenderMqttError(Object error);

  /// No description provided for @statusMqttSending.
  ///
  /// In hu, this message translates to:
  /// **'MQTT küldés: {user}/{channel}'**
  String statusMqttSending(Object user, Object channel);

  /// No description provided for @statusTcpSending.
  ///
  /// In hu, this message translates to:
  /// **'TCP küldés: {port}'**
  String statusTcpSending(int port);

  /// No description provided for @statusNoDtxFiles.
  ///
  /// In hu, this message translates to:
  /// **'Nincs .dtx fájl: {path}'**
  String statusNoDtxFiles(Object path);

  /// No description provided for @statusAllSongbooksDisabled.
  ///
  /// In hu, this message translates to:
  /// **'Minden énektár le van tiltva a diasorban.'**
  String get statusAllSongbooksDisabled;

  /// No description provided for @statusSongbooksLoaded.
  ///
  /// In hu, this message translates to:
  /// **'{count} kötet betöltve'**
  String statusSongbooksLoaded(int count);

  /// No description provided for @statusLoadError.
  ///
  /// In hu, this message translates to:
  /// **'Betöltési hiba: {error}'**
  String statusLoadError(Object error);

  /// No description provided for @statusCustomOrderSelected.
  ///
  /// In hu, this message translates to:
  /// **'Saját sorrend: {label}'**
  String statusCustomOrderSelected(Object label);

  /// No description provided for @statusOrderSaved.
  ///
  /// In hu, this message translates to:
  /// **'Sorrend mentve: {path}'**
  String statusOrderSaved(Object path);

  /// No description provided for @statusDiaFileMissing.
  ///
  /// In hu, this message translates to:
  /// **'Nincs ilyen .DIA fájl: {path}'**
  String statusDiaFileMissing(Object path);

  /// No description provided for @statusOrderLoaded.
  ///
  /// In hu, this message translates to:
  /// **'Sorrend betöltve ({count} elem): {path}'**
  String statusOrderLoaded(int count, Object path);

  /// No description provided for @statusDownloadListLoading.
  ///
  /// In hu, this message translates to:
  /// **'Énektár lista letöltése...'**
  String get statusDownloadListLoading;

  /// No description provided for @statusDownloadProgress.
  ///
  /// In hu, this message translates to:
  /// **'Letöltés: {current}/{total} {name} {percent}%'**
  String statusDownloadProgress(
    int current,
    int total,
    Object name,
    int percent,
  );

  /// No description provided for @statusDownloadSummaryNone.
  ///
  /// In hu, this message translates to:
  /// **'Nincs új énektár frissítés.'**
  String get statusDownloadSummaryNone;

  /// No description provided for @statusDownloadSummary.
  ///
  /// In hu, this message translates to:
  /// **'{downloaded} fájl letöltve, {skipped} változatlan.'**
  String statusDownloadSummary(int downloaded, int skipped);

  /// No description provided for @statusDownloadError.
  ///
  /// In hu, this message translates to:
  /// **'Letöltési hiba: {error}'**
  String statusDownloadError(Object error);

  /// No description provided for @statusZsolozsmaSyncOk.
  ///
  /// In hu, this message translates to:
  /// **'Zsolozsma ZIP frissítve: {downloaded} letöltve, {failed} hiba.'**
  String statusZsolozsmaSyncOk(int downloaded, int failed);

  /// No description provided for @statusZsolozsmaSyncError.
  ///
  /// In hu, this message translates to:
  /// **'Zsolozsma ZIP frissítési hiba: {error}'**
  String statusZsolozsmaSyncError(Object error);

  /// No description provided for @statusZsolozsmaDayLoaded.
  ///
  /// In hu, this message translates to:
  /// **'Zsolozsma lista betöltve ({count}) - {date}'**
  String statusZsolozsmaDayLoaded(int count, Object date);

  /// No description provided for @statusZsolozsmaDayEmpty.
  ///
  /// In hu, this message translates to:
  /// **'Erre a napra nincs zsolozsma lista: {date}'**
  String statusZsolozsmaDayEmpty(Object date);

  /// No description provided for @statusZsolozsmaDayError.
  ///
  /// In hu, this message translates to:
  /// **'Zsolozsma lista hiba: {error}'**
  String statusZsolozsmaDayError(Object error);

  /// No description provided for @statusZsolozsmaPartSelected.
  ///
  /// In hu, this message translates to:
  /// **'Zsolozsma kijelölve ({date}): {title}'**
  String statusZsolozsmaPartSelected(Object date, Object title);

  /// No description provided for @statusZsolozsmaPartLoaded.
  ///
  /// In hu, this message translates to:
  /// **'Zsolozsma betöltve ({count} dia) - {date}: {title}'**
  String statusZsolozsmaPartLoaded(int count, Object date, Object title);

  /// No description provided for @statusZsolozsmaPartLoadError.
  ///
  /// In hu, this message translates to:
  /// **'A kiválasztott zsolozsma napszak nem tölthető be: {title}'**
  String statusZsolozsmaPartLoadError(Object title);

  /// No description provided for @statusBookSelected.
  ///
  /// In hu, this message translates to:
  /// **'Kötet: {name}'**
  String statusBookSelected(Object name);

  /// No description provided for @statusSongPicked.
  ///
  /// In hu, this message translates to:
  /// **'Ének: {name}'**
  String statusSongPicked(Object name);

  /// No description provided for @statusVersePicked.
  ///
  /// In hu, this message translates to:
  /// **'Versszak: {name}'**
  String statusVersePicked(Object name);

  /// No description provided for @statusSongSelected.
  ///
  /// In hu, this message translates to:
  /// **'Ének: {title}'**
  String statusSongSelected(Object title);

  /// No description provided for @statusSongVerseSelected.
  ///
  /// In hu, this message translates to:
  /// **'Ének/versszak: {title}'**
  String statusSongVerseSelected(Object title);

  /// No description provided for @statusProjectionOn.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés: BE'**
  String get statusProjectionOn;

  /// No description provided for @statusProjectionOff.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés: KI'**
  String get statusProjectionOff;

  /// No description provided for @statusImagePathEmpty.
  ///
  /// In hu, this message translates to:
  /// **'A kép fájl útvonala üres.'**
  String get statusImagePathEmpty;

  /// No description provided for @statusCustomTextEmpty.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg címet vagy legalább egy sort.'**
  String get statusCustomTextEmpty;

  /// No description provided for @statusCustomTextSent.
  ///
  /// In hu, this message translates to:
  /// **'Szöveges dia elküldve: {title}'**
  String statusCustomTextSent(Object title);

  /// No description provided for @statusCustomTextError.
  ///
  /// In hu, this message translates to:
  /// **'Szöveges dia küldési hiba: {error}'**
  String statusCustomTextError(Object error);

  /// No description provided for @statusImageNotFound.
  ///
  /// In hu, this message translates to:
  /// **'A kép fájl nem található: {path}'**
  String statusImageNotFound(Object path);

  /// No description provided for @statusImageSent.
  ///
  /// In hu, this message translates to:
  /// **'Kép elküldve: {name}'**
  String statusImageSent(Object name);

  /// No description provided for @statusImageSendError.
  ///
  /// In hu, this message translates to:
  /// **'Kép küldési hiba: {error}'**
  String statusImageSendError(Object error);

  /// No description provided for @statusBlankPathEmpty.
  ///
  /// In hu, this message translates to:
  /// **'A háttérkép fájl útvonala üres.'**
  String get statusBlankPathEmpty;

  /// No description provided for @statusBlankNotFound.
  ///
  /// In hu, this message translates to:
  /// **'A háttérkép fájl nem található: {path}'**
  String statusBlankNotFound(Object path);

  /// No description provided for @statusBlankSet.
  ///
  /// In hu, this message translates to:
  /// **'Háttérkép beállítva: {name}'**
  String statusBlankSet(Object name);

  /// No description provided for @statusBlankSendError.
  ///
  /// In hu, this message translates to:
  /// **'Háttérkép küldési hiba: {error}'**
  String statusBlankSendError(Object error);

  /// No description provided for @statusBlankCleared.
  ///
  /// In hu, this message translates to:
  /// **'Háttérkép törölve.'**
  String get statusBlankCleared;

  /// No description provided for @statusBlankClearError.
  ///
  /// In hu, this message translates to:
  /// **'Háttérkép törlési hiba: {error}'**
  String statusBlankClearError(Object error);

  /// No description provided for @statusShutdownCommandSent.
  ///
  /// In hu, this message translates to:
  /// **'Lezárás utasitas elküldve.'**
  String get statusShutdownCommandSent;

  /// No description provided for @statusStopCommandSent.
  ///
  /// In hu, this message translates to:
  /// **'Megállítás utasitas elküldve.'**
  String get statusStopCommandSent;

  /// No description provided for @statusCommandSendError.
  ///
  /// In hu, this message translates to:
  /// **'Utasítás küldési hiba: {error}'**
  String statusCommandSendError(Object error);

  /// No description provided for @sendStatusLabel.
  ///
  /// In hu, this message translates to:
  /// **'Küldés ({protocol}): {senderState}, kliens: {clientState}'**
  String sendStatusLabel(
    Object protocol,
    Object senderState,
    Object clientState,
  );

  /// No description provided for @protocolMqtt.
  ///
  /// In hu, this message translates to:
  /// **'MQTT'**
  String get protocolMqtt;

  /// No description provided for @protocolTcp.
  ///
  /// In hu, this message translates to:
  /// **'TCP'**
  String get protocolTcp;

  /// No description provided for @senderStateActive.
  ///
  /// In hu, this message translates to:
  /// **'aktív'**
  String get senderStateActive;

  /// No description provided for @senderStateOff.
  ///
  /// In hu, this message translates to:
  /// **'kikapcsolva'**
  String get senderStateOff;

  /// No description provided for @clientStateConnected.
  ///
  /// In hu, this message translates to:
  /// **'csatlakozva'**
  String get clientStateConnected;

  /// No description provided for @clientStateWaiting.
  ///
  /// In hu, this message translates to:
  /// **'várakozik'**
  String get clientStateWaiting;

  /// No description provided for @tcpPortLabel.
  ///
  /// In hu, this message translates to:
  /// **'TCP port: {port}'**
  String tcpPortLabel(int port);

  /// No description provided for @downloadProgress.
  ///
  /// In hu, this message translates to:
  /// **'Letöltés: {current}/{total} {name}'**
  String downloadProgress(int current, int total, Object name);

  /// No description provided for @noLoadedSlide.
  ///
  /// In hu, this message translates to:
  /// **'Nincs betöltött dia.'**
  String get noLoadedSlide;

  /// No description provided for @homeControlModeTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Képernyőmód'**
  String get homeControlModeTooltip;

  /// No description provided for @homeControlModeBooks.
  ///
  /// In hu, this message translates to:
  /// **'Kötetek'**
  String get homeControlModeBooks;

  /// No description provided for @homeControlModeDialist.
  ///
  /// In hu, this message translates to:
  /// **'Diasor'**
  String get homeControlModeDialist;

  /// No description provided for @homeControlModePresentation.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés'**
  String get homeControlModePresentation;

  /// No description provided for @dialistNamedLabel.
  ///
  /// In hu, this message translates to:
  /// **'Diasor: {name}'**
  String dialistNamedLabel(Object name);

  /// No description provided for @bookLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kötet'**
  String get bookLabel;

  /// No description provided for @ungroupedBookGroupLabel.
  ///
  /// In hu, this message translates to:
  /// **'(nem besorolt)'**
  String get ungroupedBookGroupLabel;

  /// No description provided for @diaBookLabel.
  ///
  /// In hu, this message translates to:
  /// **'DIA: {name}'**
  String diaBookLabel(Object name);

  /// No description provided for @zsolozsmaBookLabel.
  ///
  /// In hu, this message translates to:
  /// **'Zsolozsma: {name}'**
  String zsolozsmaBookLabel(Object name);

  /// No description provided for @songLabel.
  ///
  /// In hu, this message translates to:
  /// **'Ének'**
  String get songLabel;

  /// No description provided for @verseLabel.
  ///
  /// In hu, this message translates to:
  /// **'Versszak'**
  String get verseLabel;

  /// No description provided for @versePanelTitle.
  ///
  /// In hu, this message translates to:
  /// **'{title}: {verse}'**
  String versePanelTitle(Object title, Object verse);

  /// No description provided for @searchLabel.
  ///
  /// In hu, this message translates to:
  /// **'Diakereső'**
  String get searchLabel;

  /// No description provided for @searchHint.
  ///
  /// In hu, this message translates to:
  /// **'Kötet, énekcím vagy dal szövege'**
  String get searchHint;

  /// No description provided for @searchHintOrderEdit.
  ///
  /// In hu, this message translates to:
  /// **'Ének száma'**
  String get searchHintOrderEdit;

  /// No description provided for @noResults.
  ///
  /// In hu, this message translates to:
  /// **'Nincs találat.'**
  String get noResults;

  /// No description provided for @customOrderStatus.
  ///
  /// In hu, this message translates to:
  /// **'Saját sorrend: {state}'**
  String customOrderStatus(Object state);

  /// No description provided for @stateActive.
  ///
  /// In hu, this message translates to:
  /// **'Aktív'**
  String get stateActive;

  /// No description provided for @stateInactive.
  ///
  /// In hu, this message translates to:
  /// **'Inaktív'**
  String get stateInactive;

  /// No description provided for @nextShort.
  ///
  /// In hu, this message translates to:
  /// **'Kov.'**
  String get nextShort;

  /// No description provided for @previewTitle.
  ///
  /// In hu, this message translates to:
  /// **'Dia előnézet'**
  String get previewTitle;

  /// No description provided for @previewResizeInProgress.
  ///
  /// In hu, this message translates to:
  /// **'Előnézet átméretezése...'**
  String get previewResizeInProgress;

  /// No description provided for @customTextEntryLabel.
  ///
  /// In hu, this message translates to:
  /// **'Dia: {name}'**
  String customTextEntryLabel(Object name);

  /// No description provided for @customImageEntryLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kép: {name}'**
  String customImageEntryLabel(Object name);

  /// No description provided for @projectedImage.
  ///
  /// In hu, this message translates to:
  /// **'Vetített kép:'**
  String get projectedImage;

  /// No description provided for @settingsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Diatár beállítások'**
  String get settingsTitle;

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

  /// No description provided for @tcpPortRange.
  ///
  /// In hu, this message translates to:
  /// **'TCP port (0..65535)'**
  String get tcpPortRange;

  /// No description provided for @mqttUserHint.
  ///
  /// In hu, this message translates to:
  /// **'MQTT user (üres = TCP mód)'**
  String get mqttUserHint;

  /// No description provided for @mqttPassword.
  ///
  /// In hu, this message translates to:
  /// **'MQTT jelszó'**
  String get mqttPassword;

  /// No description provided for @mqttChannel.
  ///
  /// In hu, this message translates to:
  /// **'MQTT csatorna'**
  String get mqttChannel;

  /// No description provided for @internetRelayQrButton.
  ///
  /// In hu, this message translates to:
  /// **'QR-kód'**
  String get internetRelayQrButton;

  /// No description provided for @internetRelayQrTitle.
  ///
  /// In hu, this message translates to:
  /// **'DiaVetítő QR-kód'**
  String get internetRelayQrTitle;

  /// No description provided for @internetRelayQrHint.
  ///
  /// In hu, this message translates to:
  /// **'Olvasd be a QR-kódot a webes DiaVetítő gyors megnyitásához.'**
  String get internetRelayQrHint;

  /// No description provided for @internetRelayLinkLabel.
  ///
  /// In hu, this message translates to:
  /// **'Megnyitási link'**
  String get internetRelayLinkLabel;

  /// No description provided for @internetRelayCopyLink.
  ///
  /// In hu, this message translates to:
  /// **'Link másolása'**
  String get internetRelayCopyLink;

  /// No description provided for @internetRelayLinkCopied.
  ///
  /// In hu, this message translates to:
  /// **'A link a vágólapra került'**
  String get internetRelayLinkCopied;

  /// No description provided for @internetRelaySaveQrImage.
  ///
  /// In hu, this message translates to:
  /// **'QR mentése PNG-ként'**
  String get internetRelaySaveQrImage;

  /// No description provided for @internetRelayQrSaved.
  ///
  /// In hu, this message translates to:
  /// **'QR kép mentve: {fileName}'**
  String internetRelayQrSaved(Object fileName);

  /// No description provided for @internetRelayQrSaveFailed.
  ///
  /// In hu, this message translates to:
  /// **'A QR kép mentése sikertelen: {error}'**
  String internetRelayQrSaveFailed(Object error);

  /// No description provided for @uiTheme.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználói felület témája'**
  String get uiTheme;

  /// No description provided for @themeDark.
  ///
  /// In hu, this message translates to:
  /// **'Sötét'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In hu, this message translates to:
  /// **'Világos'**
  String get themeLight;

  /// No description provided for @blankImagePath.
  ///
  /// In hu, this message translates to:
  /// **'Háttérkép útvonal'**
  String get blankImagePath;

  /// No description provided for @diaExportFolderPath.
  ///
  /// In hu, this message translates to:
  /// **'DIA mentési mappa'**
  String get diaExportFolderPath;

  /// No description provided for @fileChoose.
  ///
  /// In hu, this message translates to:
  /// **'Fájl választása'**
  String get fileChoose;

  /// No description provided for @blankImageDelete.
  ///
  /// In hu, this message translates to:
  /// **'Háttérkép törlése'**
  String get blankImageDelete;

  /// No description provided for @openDtxFolder.
  ///
  /// In hu, this message translates to:
  /// **'Diatár állományok megnyitása'**
  String get openDtxFolder;

  /// No description provided for @openDtxFolderTooltip.
  ///
  /// In hu, this message translates to:
  /// **'A Diatár állományait tartalmazó mappa megnyitása'**
  String get openDtxFolderTooltip;

  /// No description provided for @copyPathTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Eredeti útvonal másolása'**
  String get copyPathTooltip;

  /// No description provided for @pathCopied.
  ///
  /// In hu, this message translates to:
  /// **'Az eredeti útvonal a vágólapra került'**
  String get pathCopied;

  /// No description provided for @pathLabelInternalStorage.
  ///
  /// In hu, this message translates to:
  /// **'Belső tárhely'**
  String get pathLabelInternalStorage;

  /// No description provided for @pathSegmentDocuments.
  ///
  /// In hu, this message translates to:
  /// **'Dokumentumok'**
  String get pathSegmentDocuments;

  /// No description provided for @pathSegmentDownloads.
  ///
  /// In hu, this message translates to:
  /// **'Letöltések'**
  String get pathSegmentDownloads;

  /// No description provided for @pathSegmentCamera.
  ///
  /// In hu, this message translates to:
  /// **'Kamera'**
  String get pathSegmentCamera;

  /// No description provided for @pathSegmentPictures.
  ///
  /// In hu, this message translates to:
  /// **'Képek'**
  String get pathSegmentPictures;

  /// No description provided for @pathSegmentMusic.
  ///
  /// In hu, this message translates to:
  /// **'Zene'**
  String get pathSegmentMusic;

  /// No description provided for @pathSegmentMovies.
  ///
  /// In hu, this message translates to:
  /// **'Videók'**
  String get pathSegmentMovies;

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

  /// No description provided for @projectionSettingsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Vetítési beállítások'**
  String get projectionSettingsTitle;

  /// No description provided for @fontSize.
  ///
  /// In hu, this message translates to:
  /// **'Betűméret'**
  String get fontSize;

  /// No description provided for @titleSize.
  ///
  /// In hu, this message translates to:
  /// **'Cím méret'**
  String get titleSize;

  /// No description provided for @leftMargin.
  ///
  /// In hu, this message translates to:
  /// **'Bal behúzás'**
  String get leftMargin;

  /// No description provided for @borderLeft.
  ///
  /// In hu, this message translates to:
  /// **'Border L'**
  String get borderLeft;

  /// No description provided for @borderTop.
  ///
  /// In hu, this message translates to:
  /// **'Border T'**
  String get borderTop;

  /// No description provided for @borderRight.
  ///
  /// In hu, this message translates to:
  /// **'Border R'**
  String get borderRight;

  /// No description provided for @borderBottom.
  ///
  /// In hu, this message translates to:
  /// **'Border B'**
  String get borderBottom;

  /// No description provided for @lineSpacing.
  ///
  /// In hu, this message translates to:
  /// **'Sorköz'**
  String get lineSpacing;

  /// No description provided for @kottaScale.
  ///
  /// In hu, this message translates to:
  /// **'Kotta méret arány'**
  String get kottaScale;

  /// No description provided for @chordScale.
  ///
  /// In hu, this message translates to:
  /// **'Akkord méret arány'**
  String get chordScale;

  /// No description provided for @backgroundMode.
  ///
  /// In hu, this message translates to:
  /// **'Háttér kép mód'**
  String get backgroundMode;

  /// No description provided for @bgModeCenter.
  ///
  /// In hu, this message translates to:
  /// **'Középre'**
  String get bgModeCenter;

  /// No description provided for @bgModeZoom.
  ///
  /// In hu, this message translates to:
  /// **'Arányosan'**
  String get bgModeZoom;

  /// No description provided for @bgModeFull.
  ///
  /// In hu, this message translates to:
  /// **'Kitöltve'**
  String get bgModeFull;

  /// No description provided for @bgModeCascade.
  ///
  /// In hu, this message translates to:
  /// **'Csempézve'**
  String get bgModeCascade;

  /// No description provided for @bgModeMirror.
  ///
  /// In hu, this message translates to:
  /// **'Tükrözve'**
  String get bgModeMirror;

  /// No description provided for @backgroundOpacity.
  ///
  /// In hu, this message translates to:
  /// **'Háttér átlátszóság'**
  String get backgroundOpacity;

  /// No description provided for @blankOpacity.
  ///
  /// In hu, this message translates to:
  /// **'Háttérkép átlátszóság'**
  String get blankOpacity;

  /// No description provided for @autoSize.
  ///
  /// In hu, this message translates to:
  /// **'Automatikus méretezés'**
  String get autoSize;

  /// No description provided for @showTitle.
  ///
  /// In hu, this message translates to:
  /// **'Cím mutatása'**
  String get showTitle;

  /// No description provided for @projectionLock.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés zárolása'**
  String get projectionLock;

  /// No description provided for @projectionUnlock.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés feloldása'**
  String get projectionUnlock;

  /// No description provided for @hCenter.
  ///
  /// In hu, this message translates to:
  /// **'Vízszintes középre igazítás'**
  String get hCenter;

  /// No description provided for @vCenter.
  ///
  /// In hu, this message translates to:
  /// **'Függőleges középre igazítás'**
  String get vCenter;

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

  /// No description provided for @showBackgroundImage.
  ///
  /// In hu, this message translates to:
  /// **'Háttérkép mutatása'**
  String get showBackgroundImage;

  /// No description provided for @wordHighlight.
  ///
  /// In hu, this message translates to:
  /// **'Szókiemelés'**
  String get wordHighlight;

  /// No description provided for @boldText.
  ///
  /// In hu, this message translates to:
  /// **'Félkövér szöveg'**
  String get boldText;

  /// No description provided for @italicText.
  ///
  /// In hu, this message translates to:
  /// **'Dőlt szöveg'**
  String get italicText;

  /// No description provided for @underlineText.
  ///
  /// In hu, this message translates to:
  /// **'Aláhúzott szöveg'**
  String get underlineText;

  /// No description provided for @strikethroughText.
  ///
  /// In hu, this message translates to:
  /// **'Áthúzott szöveg'**
  String get strikethroughText;

  /// No description provided for @insertSpecialCharacter.
  ///
  /// In hu, this message translates to:
  /// **'Speciális karakter beszúrása'**
  String get insertSpecialCharacter;

  /// No description provided for @conditionalHyphen.
  ///
  /// In hu, this message translates to:
  /// **'Feltételes kötőjel'**
  String get conditionalHyphen;

  /// No description provided for @nonBreakingSpace.
  ///
  /// In hu, this message translates to:
  /// **'Nemtörhető szóköz'**
  String get nonBreakingSpace;

  /// No description provided for @nonBreakingHyphen.
  ///
  /// In hu, this message translates to:
  /// **'Nemtörhető kötőjel'**
  String get nonBreakingHyphen;

  /// No description provided for @preferredLineBreak.
  ///
  /// In hu, this message translates to:
  /// **'Sortörési javaslat'**
  String get preferredLineBreak;

  /// No description provided for @colorsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Színek'**
  String get colorsTitle;

  /// No description provided for @backgroundColor.
  ///
  /// In hu, this message translates to:
  /// **'Háttér'**
  String get backgroundColor;

  /// No description provided for @textColor.
  ///
  /// In hu, this message translates to:
  /// **'Szöveg'**
  String get textColor;

  /// No description provided for @emptySlideColor.
  ///
  /// In hu, this message translates to:
  /// **'Üres dia'**
  String get emptySlideColor;

  /// No description provided for @highlightColor.
  ///
  /// In hu, this message translates to:
  /// **'Kiemelés'**
  String get highlightColor;

  /// No description provided for @backgroundColorTitle.
  ///
  /// In hu, this message translates to:
  /// **'Háttér színe'**
  String get backgroundColorTitle;

  /// No description provided for @textColorTitle.
  ///
  /// In hu, this message translates to:
  /// **'Szöveg színe'**
  String get textColorTitle;

  /// No description provided for @emptySlideColorTitle.
  ///
  /// In hu, this message translates to:
  /// **'Üres dia színe'**
  String get emptySlideColorTitle;

  /// No description provided for @highlightColorTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kiemelés színe'**
  String get highlightColorTitle;

  /// No description provided for @cancel.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get delete;

  /// No description provided for @deleteFilesTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Fájl törlése'**
  String get deleteFilesTooltip;

  /// No description provided for @confirmDeleteDtxFiles.
  ///
  /// In hu, this message translates to:
  /// **'Törlöd a(z) „{name}” énektár-fájlt a készülékről? Ez a művelet nem vonható vissza.'**
  String confirmDeleteDtxFiles(Object name);

  /// No description provided for @confirmDeleteDtzFiles.
  ///
  /// In hu, this message translates to:
  /// **'Törlöd a(z) „{name}” vetítő-fájlt a készülékről? Ez a művelet nem vonható vissza.'**
  String confirmDeleteDtzFiles(Object name);

  /// No description provided for @save.
  ///
  /// In hu, this message translates to:
  /// **'Ment'**
  String get save;

  /// No description provided for @invalidPortRange.
  ///
  /// In hu, this message translates to:
  /// **'A port 0..65535 között legyen.'**
  String get invalidPortRange;

  /// No description provided for @hexColorHint.
  ///
  /// In hu, this message translates to:
  /// **'Hex szín (#AARRGGBB vagy #RRGGBB)'**
  String get hexColorHint;

  /// No description provided for @close.
  ///
  /// In hu, this message translates to:
  /// **'Bezárás'**
  String get close;

  /// No description provided for @imagesFileTypeLabel.
  ///
  /// In hu, this message translates to:
  /// **'képek'**
  String get imagesFileTypeLabel;

  /// No description provided for @diatarPlaylistFileTypeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Diatár playlist'**
  String get diatarPlaylistFileTypeLabel;

  /// No description provided for @customOrderSuggestedFileName.
  ///
  /// In hu, this message translates to:
  /// **'sorrend.dia'**
  String get customOrderSuggestedFileName;

  /// No description provided for @customOrderEditTitle.
  ///
  /// In hu, this message translates to:
  /// **'Szerkesztő'**
  String get customOrderEditTitle;

  /// No description provided for @customOrderEditTitleWithName.
  ///
  /// In hu, this message translates to:
  /// **'{name} - Szerkesztő'**
  String customOrderEditTitleWithName(Object name);

  /// No description provided for @customOrderModifiedName.
  ///
  /// In hu, this message translates to:
  /// **'✦ {name}'**
  String customOrderModifiedName(Object name);

  /// No description provided for @customOrderGroupReorder.
  ///
  /// In hu, this message translates to:
  /// **'Csoportos áthelyezés'**
  String get customOrderGroupReorder;

  /// No description provided for @customOrderPlaySoundTooltip.
  ///
  /// In hu, this message translates to:
  /// **'A dia zenéjének lejátszása'**
  String get customOrderPlaySoundTooltip;

  /// No description provided for @customOrderAdvanceAfterSoundTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Továbblépés a zene végén'**
  String get customOrderAdvanceAfterSoundTooltip;

  /// No description provided for @customOrderSkipSlideTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Dia kihagyása vetítéskor'**
  String get customOrderSkipSlideTooltip;

  /// No description provided for @addSong.
  ///
  /// In hu, this message translates to:
  /// **'Ének hozzáadása'**
  String get addSong;

  /// No description provided for @searchSongHint.
  ///
  /// In hu, this message translates to:
  /// **'Kötet, énekcím vagy dal szövege'**
  String get searchSongHint;

  /// No description provided for @customOrderInsertBookLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kötet'**
  String get customOrderInsertBookLabel;

  /// No description provided for @customOrderInsertSongLabel.
  ///
  /// In hu, this message translates to:
  /// **'Ének'**
  String get customOrderInsertSongLabel;

  /// No description provided for @customOrderInsertVersesAction.
  ///
  /// In hu, this message translates to:
  /// **'Versszakok beszúrása'**
  String get customOrderInsertVersesAction;

  /// No description provided for @customOrderInsertSeparatorAction.
  ///
  /// In hu, this message translates to:
  /// **'Elválasztó beszúrása'**
  String get customOrderInsertSeparatorAction;

  /// No description provided for @customOrderClearAllTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Mindent töröl'**
  String get customOrderClearAllTooltip;

  /// No description provided for @customOrderClearAllConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Megerősítés'**
  String get customOrderClearAllConfirmTitle;

  /// No description provided for @customOrderClearAllConfirmMessage.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan törölni szeretnéd az egész saját diasort?'**
  String get customOrderClearAllConfirmMessage;

  /// No description provided for @customOrderClearAllConfirmButton.
  ///
  /// In hu, this message translates to:
  /// **'Mindent töröl'**
  String get customOrderClearAllConfirmButton;

  /// No description provided for @customOrderSeparatorNameLabel.
  ///
  /// In hu, this message translates to:
  /// **'Elválasztó neve'**
  String get customOrderSeparatorNameLabel;

  /// No description provided for @customOrderSeparatorDefaultName.
  ///
  /// In hu, this message translates to:
  /// **'elválasztó'**
  String get customOrderSeparatorDefaultName;

  /// No description provided for @customOrderEditSeparatorTitle.
  ///
  /// In hu, this message translates to:
  /// **'Elválasztó szerkesztése'**
  String get customOrderEditSeparatorTitle;

  /// No description provided for @customOrderEditTextSlideTitle.
  ///
  /// In hu, this message translates to:
  /// **'Szöveges dia szerkesztése'**
  String get customOrderEditTextSlideTitle;

  /// No description provided for @customOrderInsertVersesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Beszúrandó versszakok'**
  String get customOrderInsertVersesTitle;

  /// No description provided for @customOrderInsertVersesSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Jelöld ki, mely versszakok kerüljenek a diasorba.'**
  String get customOrderInsertVersesSubtitle;

  /// No description provided for @textSlideDialogTitle.
  ///
  /// In hu, this message translates to:
  /// **'Szöveges dia hozzáadása'**
  String get textSlideDialogTitle;

  /// No description provided for @textSlideTitleLabel.
  ///
  /// In hu, this message translates to:
  /// **'Cím'**
  String get textSlideTitleLabel;

  /// No description provided for @textSlideBodyLabel.
  ///
  /// In hu, this message translates to:
  /// **'Szöveg (soronként)'**
  String get textSlideBodyLabel;

  /// No description provided for @textSlideDefaultTitle.
  ///
  /// In hu, this message translates to:
  /// **'Dia'**
  String get textSlideDefaultTitle;

  /// No description provided for @loadDia.
  ///
  /// In hu, this message translates to:
  /// **'Betöltés'**
  String get loadDia;

  /// No description provided for @saveDia.
  ///
  /// In hu, this message translates to:
  /// **'Mentés'**
  String get saveDia;

  /// No description provided for @customOrderSaveDiaErrorTitle.
  ///
  /// In hu, this message translates to:
  /// **'Mentés sikertelen'**
  String get customOrderSaveDiaErrorTitle;

  /// No description provided for @customOrderSaveDiaPermissionDenied.
  ///
  /// In hu, this message translates to:
  /// **'A DIA fájl mentése közben az Android nem tudta írni a kiválasztott célhelyet. Próbáld újra, és a rendszer mentési ablakában válassz másik mappát vagy fájlnevet.'**
  String get customOrderSaveDiaPermissionDenied;

  /// No description provided for @customOrderSaveDiaGenericError.
  ///
  /// In hu, this message translates to:
  /// **'A DIA fájl mentése nem sikerült. Részletek: {error}'**
  String customOrderSaveDiaGenericError(Object error);

  /// No description provided for @customOrderOverwriteSavedDiaTitle.
  ///
  /// In hu, this message translates to:
  /// **'Felülírás?'**
  String get customOrderOverwriteSavedDiaTitle;

  /// No description provided for @customOrderOverwriteSavedDiaBody.
  ///
  /// In hu, this message translates to:
  /// **'Már van elmentve egy DIA fájl: {fileName}. Mit szeretnél?'**
  String customOrderOverwriteSavedDiaBody(Object fileName);

  /// No description provided for @customOrderOverwriteSavedDiaOverwrite.
  ///
  /// In hu, this message translates to:
  /// **'Felülírás'**
  String get customOrderOverwriteSavedDiaOverwrite;

  /// No description provided for @customOrderOverwriteSavedDiaNewLocation.
  ///
  /// In hu, this message translates to:
  /// **'Új hely választása'**
  String get customOrderOverwriteSavedDiaNewLocation;

  /// No description provided for @customOrderDiaFileNameLabel.
  ///
  /// In hu, this message translates to:
  /// **'Fájlnév'**
  String get customOrderDiaFileNameLabel;

  /// No description provided for @customOrderUnnamedFileName.
  ///
  /// In hu, this message translates to:
  /// **'Névtelen'**
  String get customOrderUnnamedFileName;

  /// No description provided for @customOrderDiaOverwriteTitle.
  ///
  /// In hu, this message translates to:
  /// **'Fájl felülírása'**
  String get customOrderDiaOverwriteTitle;

  /// No description provided for @customOrderDiaOverwriteMessage.
  ///
  /// In hu, this message translates to:
  /// **'A(z) „{name}” fájl már létezik. Felülírja?'**
  String customOrderDiaOverwriteMessage(Object name);

  /// No description provided for @savedPath.
  ///
  /// In hu, this message translates to:
  /// **'Mentve: {path}'**
  String savedPath(Object path);

  /// No description provided for @loadedCount.
  ///
  /// In hu, this message translates to:
  /// **'Betöltve: {count} elem'**
  String loadedCount(int count);

  /// No description provided for @customOrderEmpty.
  ///
  /// In hu, this message translates to:
  /// **'A sorrend üres.\nKeress énekeket a szerkesztéshez.'**
  String get customOrderEmpty;

  /// No description provided for @versePicker.
  ///
  /// In hu, this message translates to:
  /// **'Versszak'**
  String get versePicker;

  /// No description provided for @selectedVersesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kiválasztott versszakok'**
  String get selectedVersesTitle;

  /// No description provided for @selectedVersesSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Többet is kijelölhetsz.'**
  String get selectedVersesSubtitle;

  /// No description provided for @customOrderSelectAllVerses.
  ///
  /// In hu, this message translates to:
  /// **'Összes'**
  String get customOrderSelectAllVerses;

  /// No description provided for @customOrderClearVerseSelection.
  ///
  /// In hu, this message translates to:
  /// **'Egyik sem'**
  String get customOrderClearVerseSelection;

  /// Section header for the list of loaded custom orders (diasorok) in the volume list dialog.
  ///
  /// In hu, this message translates to:
  /// **'Diasorok'**
  String get customOrderSetsSection;

  /// Label for the dropdown that selects the active diasor in the Diasor (dialist) panel.
  ///
  /// In hu, this message translates to:
  /// **'Aktív diasor'**
  String get customOrderSetSelectorLabel;

  /// Badge shown next to the currently active custom order
  ///
  /// In hu, this message translates to:
  /// **'Aktív'**
  String get customOrderSetActive;

  /// Shown when a loaded custom order has no entries
  ///
  /// In hu, this message translates to:
  /// **'Üres diasor'**
  String get customOrderSetEmpty;

  /// Shows the number of entries in a loaded custom order
  ///
  /// In hu, this message translates to:
  /// **'{count} tétel'**
  String customOrderSetEntryCount(int count);

  /// Menu item to rename a loaded custom order
  ///
  /// In hu, this message translates to:
  /// **'Átnevezés'**
  String get customOrderSetRename;

  /// Menu item to remove a loaded custom order
  ///
  /// In hu, this message translates to:
  /// **'Eltávolítás'**
  String get customOrderSetRemove;

  /// Title of the rename custom order dialog
  ///
  /// In hu, this message translates to:
  /// **'Diasor átnevezése'**
  String get customOrderSetRenameTitle;

  /// Confirmation message before removing a loaded custom order
  ///
  /// In hu, this message translates to:
  /// **'Biztosan eltávolítod ezt a diasort?'**
  String get customOrderSetRemoveConfirm;

  /// Warning when trying to remove a custom order that has a hotkey assigned
  ///
  /// In hu, this message translates to:
  /// **'Ez a diasor gyorsbillentyűhöz van rendelve ({hotkey}). Előbb távolítsd el a gyorsbillentyűt a Beállításokban.'**
  String customOrderSetRemoveHotkeyWarning(Object hotkey);

  /// Tooltip to enable or disable a custom order in the editor
  ///
  /// In hu, this message translates to:
  /// **'Diasor be- és kikapcsolása (a kikapcsolt nem jelenik meg a nézetekben)'**
  String get customOrderSetToggleEnabledTooltip;

  /// Button to create a new custom order
  ///
  /// In hu, this message translates to:
  /// **'Új diasor'**
  String get customOrderSetCreate;

  /// Title of the create new custom order dialog
  ///
  /// In hu, this message translates to:
  /// **'Új diasor létrehozása'**
  String get customOrderSetCreateTitle;

  /// Label for the name field when creating a new custom order
  ///
  /// In hu, this message translates to:
  /// **'Diasor neve'**
  String get customOrderSetCreateNameLabel;

  /// Title of the dialog asking how to load an imported custom order
  ///
  /// In hu, this message translates to:
  /// **'Diasor betöltése'**
  String get customOrderLoadModeTitle;

  /// Option to overwrite the currently active custom order with the imported one
  ///
  /// In hu, this message translates to:
  /// **'Felülírja az aktuálist'**
  String get customOrderLoadModeOverwrite;

  /// Option to load the imported custom order alongside the already loaded ones
  ///
  /// In hu, this message translates to:
  /// **'Mellé tölti (párhuzamos)'**
  String get customOrderLoadModeAdd;

  /// Question shown in the load mode dialog
  ///
  /// In hu, this message translates to:
  /// **'Hogyan töltsük be a kiválasztott diasort?'**
  String get customOrderLoadModeMessage;

  /// Title of the volume list dialog
  ///
  /// In hu, this message translates to:
  /// **'Kötetlista'**
  String get volumeListTitle;

  /// No description provided for @apply.
  ///
  /// In hu, this message translates to:
  /// **'Alkalmaz'**
  String get apply;

  /// No description provided for @internetUserActionsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználói műveletek (API)'**
  String get internetUserActionsTitle;

  /// No description provided for @internetStatusOn.
  ///
  /// In hu, this message translates to:
  /// **'Be'**
  String get internetStatusOn;

  /// No description provided for @internetStatusOff.
  ///
  /// In hu, this message translates to:
  /// **'Ki'**
  String get internetStatusOff;

  /// No description provided for @internetStatusConnecting.
  ///
  /// In hu, this message translates to:
  /// **'Kapcsolódás'**
  String get internetStatusConnecting;

  /// No description provided for @internetStatusError.
  ///
  /// In hu, this message translates to:
  /// **'Hiba'**
  String get internetStatusError;

  /// No description provided for @connectionStatusTooltip.
  ///
  /// In hu, this message translates to:
  /// **'{name}: {status}'**
  String connectionStatusTooltip(Object name, Object status);

  /// No description provided for @valueNotSet.
  ///
  /// In hu, this message translates to:
  /// **'-'**
  String get valueNotSet;

  /// No description provided for @tcpNoTargets.
  ///
  /// In hu, this message translates to:
  /// **'Nincs célpont'**
  String get tcpNoTargets;

  /// No description provided for @tcpTargetsCount.
  ///
  /// In hu, this message translates to:
  /// **'{count} célpont'**
  String tcpTargetsCount(int count);

  /// No description provided for @settingsSearchLabel.
  ///
  /// In hu, this message translates to:
  /// **'Keresés a beállításokban'**
  String get settingsSearchLabel;

  /// No description provided for @settingsInternetTitle.
  ///
  /// In hu, this message translates to:
  /// **'Internet'**
  String get settingsInternetTitle;

  /// No description provided for @settingsInternetSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Internetes közvetítés: {status}, felhasználó: {user}'**
  String settingsInternetSubtitle(Object status, Object user);

  /// No description provided for @settingsLocalNetworkTitle.
  ///
  /// In hu, this message translates to:
  /// **'Helyi hálózat (TCP/IP)'**
  String get settingsLocalNetworkTitle;

  /// No description provided for @settingsLocalNetworkSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'TCP kliens: {status}, célpontok: {summary}'**
  String settingsLocalNetworkSubtitle(Object status, Object summary);

  /// No description provided for @settingsWolTitle.
  ///
  /// In hu, this message translates to:
  /// **'Wake on LAN'**
  String get settingsWolTitle;

  /// No description provided for @settingsWolSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Wake on LAN: {status}, célpontok: {summary}'**
  String settingsWolSubtitle(Object status, Object summary);

  /// No description provided for @settingsWolDescription.
  ///
  /// In hu, this message translates to:
  /// **'Célgépek felébresztése a helyi hálózaton egy UDP-n keresztül küldött varázscsomaggal (magic packet).'**
  String get settingsWolDescription;

  /// No description provided for @wolEnabledTitle.
  ///
  /// In hu, this message translates to:
  /// **'Wake on LAN bekapcsolása'**
  String get wolEnabledTitle;

  /// No description provided for @wolEnabledHint.
  ///
  /// In hu, this message translates to:
  /// **'Ha be van kapcsolva, az eszköztár gombjával minden célgépet felébreszthetsz.'**
  String get wolEnabledHint;

  /// No description provided for @wolTargetsLabel.
  ///
  /// In hu, this message translates to:
  /// **'Célgépek (MAC@IP[:port])'**
  String get wolTargetsLabel;

  /// No description provided for @wolTargetsHint.
  ///
  /// In hu, this message translates to:
  /// **'AA:BB:CC:DD:EE:FF, soronként egy'**
  String get wolTargetsHint;

  /// No description provided for @wolTargetsHelp.
  ///
  /// In hu, this message translates to:
  /// **'A puszta MAC-cím a lentebb beállított broadcast címre küldi az ébresztőt. A MAC után @IP vagy @IP:port hozzáadásával egy adott gépet közvetlenül ébreszthetsz.'**
  String get wolTargetsHelp;

  /// No description provided for @wolBroadcastLabel.
  ///
  /// In hu, this message translates to:
  /// **'Broadcast cím'**
  String get wolBroadcastLabel;

  /// No description provided for @wolPortLabel.
  ///
  /// In hu, this message translates to:
  /// **'UDP port'**
  String get wolPortLabel;

  /// No description provided for @wolNoTargets.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg legalább egy célgépet.'**
  String get wolNoTargets;

  /// No description provided for @wolInvalidTarget.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen célpont: {target}'**
  String wolInvalidTarget(Object target);

  /// No description provided for @wolInvalidBroadcast.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen broadcast cím. IPv4-címet adj meg, például 255.255.255.255.'**
  String get wolInvalidBroadcast;

  /// No description provided for @wolInvalidPort.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen port. 1 és 65535 között használható érték.'**
  String get wolInvalidPort;

  /// No description provided for @wolTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Wake on LAN'**
  String get wolTooltip;

  /// No description provided for @wolMessageSent.
  ///
  /// In hu, this message translates to:
  /// **'Wake on LAN elküldve {count} gépnek.'**
  String wolMessageSent(int count);

  /// No description provided for @wolMessageError.
  ///
  /// In hu, this message translates to:
  /// **'Wake on LAN hiba: {error}'**
  String wolMessageError(Object error);

  /// No description provided for @settingsColorSummary.
  ///
  /// In hu, this message translates to:
  /// **'Háttér: {background}, Szöveg: {text}'**
  String settingsColorSummary(Object background, Object text);

  /// No description provided for @settingsProjectionSummary.
  ///
  /// In hu, this message translates to:
  /// **'Betű: {font}px, Cím: {title}px'**
  String settingsProjectionSummary(Object font, Object title);

  /// No description provided for @settingsFilesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Énektárak és fájlok'**
  String get settingsFilesTitle;

  /// No description provided for @settingsFilesSummary.
  ///
  /// In hu, this message translates to:
  /// **'Háttérkép: {blank}'**
  String settingsFilesSummary(Object blank);

  /// No description provided for @importDtxFilesButton.
  ///
  /// In hu, this message translates to:
  /// **'Importálás fájlból'**
  String get importDtxFilesButton;

  /// No description provided for @importDtzFilesButton.
  ///
  /// In hu, this message translates to:
  /// **'Kotta importálás'**
  String get importDtzFilesButton;

  /// No description provided for @importMusicFilesButton.
  ///
  /// In hu, this message translates to:
  /// **'Zene importálás'**
  String get importMusicFilesButton;

  /// No description provided for @importMusicNotImplemented.
  ///
  /// In hu, this message translates to:
  /// **'A zeneimport még nincs implementálva.'**
  String get importMusicNotImplemented;

  /// No description provided for @importDtzPreviewTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kotta importálás'**
  String get importDtzPreviewTitle;

  /// No description provided for @importDtzDtzSection.
  ///
  /// In hu, this message translates to:
  /// **'DTZ fájl'**
  String get importDtzDtzSection;

  /// No description provided for @importDtzZipSection.
  ///
  /// In hu, this message translates to:
  /// **'ZIP fájlok (képek, hangok)'**
  String get importDtzZipSection;

  /// No description provided for @importDtzNoDtzSelected.
  ///
  /// In hu, this message translates to:
  /// **'Nincs DTZ fájl kiválasztva'**
  String get importDtzNoDtzSelected;

  /// No description provided for @importDtzSelectDtz.
  ///
  /// In hu, this message translates to:
  /// **'DTZ kiválasztása'**
  String get importDtzSelectDtz;

  /// No description provided for @importDtzAddZip.
  ///
  /// In hu, this message translates to:
  /// **'ZIP hozzáadása'**
  String get importDtzAddZip;

  /// No description provided for @importDtzValidateButton.
  ///
  /// In hu, this message translates to:
  /// **'Ellenőrzés'**
  String get importDtzValidateButton;

  /// No description provided for @importDtzPreviewNoDtz.
  ///
  /// In hu, this message translates to:
  /// **'Nem adtál meg .dtz fájlt. Válassz legalább egy DTZ fájlt!'**
  String get importDtzPreviewNoDtz;

  /// No description provided for @importDtzPreviewOrphanZips.
  ///
  /// In hu, this message translates to:
  /// **'{count} ZIP fájl nem párosítható DTZ fájlhoz.'**
  String importDtzPreviewOrphanZips(int count);

  /// No description provided for @importDtzStatusOk.
  ///
  /// In hu, this message translates to:
  /// **'Importálható – {matched} médiafájl rendben'**
  String importDtzStatusOk(int matched);

  /// No description provided for @importDtzStatusNoRefs.
  ///
  /// In hu, this message translates to:
  /// **'Importálható – nincs hivatkozott médiafájl'**
  String get importDtzStatusNoRefs;

  /// No description provided for @importDtzStatusWarning.
  ///
  /// In hu, this message translates to:
  /// **'Importálható (figyelmeztetéssel) – {missing}/{total} médiafájl hiányzik'**
  String importDtzStatusWarning(int missing, int total);

  /// No description provided for @importDtzStatusError.
  ///
  /// In hu, this message translates to:
  /// **'Nem importálható – {missing}/{total} médiafájl hiányzik'**
  String importDtzStatusError(int missing, int total);

  /// No description provided for @importDtzStatusParseError.
  ///
  /// In hu, this message translates to:
  /// **'Nem importálható – érvénytelen DTZ fájl'**
  String get importDtzStatusParseError;

  /// No description provided for @importDtzStatusMissingDiaIdsCount.
  ///
  /// In hu, this message translates to:
  /// **'Ismeretlen dia-ID a DTZ-ben: {count} db'**
  String importDtzStatusMissingDiaIdsCount(int count);

  /// No description provided for @importDtzDetails.
  ///
  /// In hu, this message translates to:
  /// **'Részletek'**
  String get importDtzDetails;

  /// No description provided for @importDtzMissingFilesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Hiányzó médiafájlok'**
  String get importDtzMissingFilesTitle;

  /// No description provided for @importDtzMissingDiaIdsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Ismeretlen dia-ID-k'**
  String get importDtzMissingDiaIdsTitle;

  /// No description provided for @importDtzConfirmErrorsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Hibás csomag importálása'**
  String get importDtzConfirmErrorsTitle;

  /// No description provided for @importDtzConfirmErrorsBody.
  ///
  /// In hu, this message translates to:
  /// **'A kijelölt {count} csomag hibás (hiányzó médiafájl vagy ismeretlen dia-ID). A hiányzó fájlok nem kerülnek kibontásra. Mégis importálod?'**
  String importDtzConfirmErrorsBody(int count);

  /// No description provided for @importDtzImportButton.
  ///
  /// In hu, this message translates to:
  /// **'Importálás'**
  String get importDtzImportButton;

  /// No description provided for @importDtzSuccess.
  ///
  /// In hu, this message translates to:
  /// **'{dtz} DTZ fájl importálva, {files} médiafájl kibontva'**
  String importDtzSuccess(int dtz, int files);

  /// No description provided for @importDtzSuccessNoMedia.
  ///
  /// In hu, this message translates to:
  /// **'{dtz} DTZ fájl importálva'**
  String importDtzSuccessNoMedia(int dtz);

  /// No description provided for @importDtzError.
  ///
  /// In hu, this message translates to:
  /// **'Hiba a kotta importálás során: {reason}'**
  String importDtzError(Object reason);

  /// No description provided for @importDtzFailureDialogTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kottaimportálási hiba'**
  String get importDtzFailureDialogTitle;

  /// No description provided for @importDtzPartialImportTitle.
  ///
  /// In hu, this message translates to:
  /// **'A kottaimportálás hibákkal fejeződött be'**
  String get importDtzPartialImportTitle;

  /// No description provided for @importDtzFailureSourceUnreadable.
  ///
  /// In hu, this message translates to:
  /// **'A kiválasztott ZIP fájl nem olvasható.'**
  String get importDtzFailureSourceUnreadable;

  /// No description provided for @importDtzFailureInvalidArchive.
  ///
  /// In hu, this message translates to:
  /// **'A kiválasztott fájl nem érvényes ZIP archívum.'**
  String get importDtzFailureInvalidArchive;

  /// No description provided for @importDtzFailureTooManyEntries.
  ///
  /// In hu, this message translates to:
  /// **'A ZIP túl sok fájlt tartalmaz.'**
  String get importDtzFailureTooManyEntries;

  /// No description provided for @importDtzFailureEntryTooLarge.
  ///
  /// In hu, this message translates to:
  /// **'A ZIP egy biztonságosan importálhatónál nagyobb fájlt tartalmaz.'**
  String get importDtzFailureEntryTooLarge;

  /// No description provided for @importDtzFailureTotalTooLarge.
  ///
  /// In hu, this message translates to:
  /// **'A ZIP túl sok adatot bontana ki a biztonságos importáláshoz.'**
  String get importDtzFailureTotalTooLarge;

  /// No description provided for @importDtzFailureCancelled.
  ///
  /// In hu, this message translates to:
  /// **'Az importálást megszakítottad.'**
  String get importDtzFailureCancelled;

  /// No description provided for @importDtzFailureEntryUnreadable.
  ///
  /// In hu, this message translates to:
  /// **'A ZIP egyik fájlja nem bontható ki.'**
  String get importDtzFailureEntryUnreadable;

  /// No description provided for @importDtzFailureWriteFailed.
  ///
  /// In hu, this message translates to:
  /// **'A kibontott fájl nem írható. Ellenőrizd a szabad tárhelyet.'**
  String get importDtzFailureWriteFailed;

  /// No description provided for @importDtzFailureDetails.
  ///
  /// In hu, this message translates to:
  /// **'{zip}: {reason}'**
  String importDtzFailureDetails(Object zip, Object reason);

  /// No description provided for @importDtzProgress.
  ///
  /// In hu, this message translates to:
  /// **'Kibontás: {entry} ({current}/{total})'**
  String importDtzProgress(Object entry, int current, int total);

  /// No description provided for @importDtxFilesSuccess.
  ///
  /// In hu, this message translates to:
  /// **'{count} .dtx fájl beimportálva'**
  String importDtxFilesSuccess(int count);

  /// No description provided for @importDtxFilesError.
  ///
  /// In hu, this message translates to:
  /// **'Hiba a .dtx importálás során'**
  String get importDtxFilesError;

  /// No description provided for @importDtxFilesErrorDetailed.
  ///
  /// In hu, this message translates to:
  /// **'Hiba a .dtx importálás során: {reason}'**
  String importDtxFilesErrorDetailed(Object reason);

  /// No description provided for @importDtxFilesPartial.
  ///
  /// In hu, this message translates to:
  /// **'{count} .dtx fájl beimportálva, {failed} sikertelen: {reason}'**
  String importDtxFilesPartial(int count, int failed, Object reason);

  /// No description provided for @settingsGeneralTitle.
  ///
  /// In hu, this message translates to:
  /// **'Általános'**
  String get settingsGeneralTitle;

  /// No description provided for @settingsGeneralSummary.
  ///
  /// In hu, this message translates to:
  /// **'Téma: {theme}, Nyelv: {language}'**
  String settingsGeneralSummary(Object theme, Object language);

  /// No description provided for @systemActionsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Rendszer műveletek'**
  String get systemActionsTitle;

  /// No description provided for @systemActionsSummary.
  ///
  /// In hu, this message translates to:
  /// **'Kilépés, frissítés, távoli program leállítása, távoli gép leállítása'**
  String get systemActionsSummary;

  /// No description provided for @systemActionsBack.
  ///
  /// In hu, this message translates to:
  /// **'Vissza'**
  String get systemActionsBack;

  /// No description provided for @externalCommandsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Külső parancsok'**
  String get externalCommandsTitle;

  /// No description provided for @externalCommandsSummary.
  ///
  /// In hu, this message translates to:
  /// **'Külső műveletek indítása program- és vetítési eseményekkor'**
  String get externalCommandsSummary;

  /// No description provided for @externalCommandsDescriptionDesktop.
  ///
  /// In hu, this message translates to:
  /// **'A program vagy a vetítés állapotának változásakor Windows és Linux rendszeren futó shell parancsok beállítása.'**
  String get externalCommandsDescriptionDesktop;

  /// No description provided for @externalCommandsDescriptionAndroid.
  ///
  /// In hu, this message translates to:
  /// **'A program vagy a vetítés állapotának változásakor indított URI, deep link, Android intent vagy broadcast beállítása.'**
  String get externalCommandsDescriptionAndroid;

  /// No description provided for @externalCommandsDescriptionIos.
  ///
  /// In hu, this message translates to:
  /// **'A program vagy a vetítés állapotának változásakor megnyíló URL vagy deep link beállítása.'**
  String get externalCommandsDescriptionIos;

  /// No description provided for @externalCommandsHintDesktop.
  ///
  /// In hu, this message translates to:
  /// **'Az üresen hagyott eseményhez nem fut parancs. A parancsokat az operációs rendszer parancsértelmezője indítja.'**
  String get externalCommandsHintDesktop;

  /// No description provided for @externalCommandsHintAndroid.
  ///
  /// In hu, this message translates to:
  /// **'Az üresen hagyott eseményhez nem fut parancs. URI vagy deep link, Android Intent URI, illetve broadcast küldéséhez \"broadcast:\" előtaggal ellátott Intent URI adható meg. Az Intent URI extrákat is kezel, például: intent:#Intent;action=com.example.ACTION;S.name=value;i.count=1;end'**
  String get externalCommandsHintAndroid;

  /// No description provided for @externalCommandsHintIos.
  ///
  /// In hu, this message translates to:
  /// **'Az üresen hagyott eseményhez nem fut parancs. Telepített alkalmazás által kezelt URL vagy deep link adható meg, például: mycontroller://projection?state=on. A paraméterek az URL lekérdezési részében adhatók át.'**
  String get externalCommandsHintIos;

  /// No description provided for @externalCommandOnStart.
  ///
  /// In hu, this message translates to:
  /// **'A program indulásakor'**
  String get externalCommandOnStart;

  /// No description provided for @externalCommandOnExit.
  ///
  /// In hu, this message translates to:
  /// **'A program kilépésekor'**
  String get externalCommandOnExit;

  /// No description provided for @externalCommandOnProjectionOn.
  ///
  /// In hu, this message translates to:
  /// **'A vetítés bekapcsolásakor'**
  String get externalCommandOnProjectionOn;

  /// No description provided for @externalCommandOnProjectionOff.
  ///
  /// In hu, this message translates to:
  /// **'A vetítés kikapcsolásakor'**
  String get externalCommandOnProjectionOff;

  /// No description provided for @externalCommandClear.
  ///
  /// In hu, this message translates to:
  /// **'Parancs törlése'**
  String get externalCommandClear;

  /// No description provided for @externalCommandTest.
  ///
  /// In hu, this message translates to:
  /// **'Teszt'**
  String get externalCommandTest;

  /// No description provided for @externalCommandTestStarted.
  ///
  /// In hu, this message translates to:
  /// **'A parancs elindult.'**
  String get externalCommandTestStarted;

  /// No description provided for @externalCommandTestSucceededTitle.
  ///
  /// In hu, this message translates to:
  /// **'Teszt sikeres'**
  String get externalCommandTestSucceededTitle;

  /// No description provided for @externalCommandTestFailedTitle.
  ///
  /// In hu, this message translates to:
  /// **'Teszt sikertelen'**
  String get externalCommandTestFailedTitle;

  /// No description provided for @externalCommandTestFailed.
  ///
  /// In hu, this message translates to:
  /// **'A parancs indítása sikertelen: {error}'**
  String externalCommandTestFailed(Object error);

  /// No description provided for @externalCommandTestExitCode.
  ///
  /// In hu, this message translates to:
  /// **'A parancs {code} hibakóddal fejeződött be.'**
  String externalCommandTestExitCode(int code);

  /// No description provided for @localExit.
  ///
  /// In hu, this message translates to:
  /// **'Kilépés'**
  String get localExit;

  /// No description provided for @remoteProgramStop.
  ///
  /// In hu, this message translates to:
  /// **'Távoli program leállítása'**
  String get remoteProgramStop;

  /// No description provided for @remoteMachineStop.
  ///
  /// In hu, this message translates to:
  /// **'Távoli gép leállítása'**
  String get remoteMachineStop;

  /// No description provided for @settingsHotkeysTitle.
  ///
  /// In hu, this message translates to:
  /// **'Gyorsbillentyűk'**
  String get settingsHotkeysTitle;

  /// No description provided for @settingsHotkeysSummary.
  ///
  /// In hu, this message translates to:
  /// **'Vezérlő műveletek és ének-hozzárendelés billentyűhöz'**
  String get settingsHotkeysSummary;

  /// No description provided for @settingsDesktopHotkeysTitle.
  ///
  /// In hu, this message translates to:
  /// **'Gyorsbillentyűk (asztali)'**
  String get settingsDesktopHotkeysTitle;

  /// No description provided for @settingsHotkeysActionsSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Vezérlő műveletek'**
  String get settingsHotkeysActionsSectionTitle;

  /// No description provided for @settingsHotkeysSongsSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Ének gyorsbillentyűhöz'**
  String get settingsHotkeysSongsSectionTitle;

  /// No description provided for @settingsHotkeysNoSongs.
  ///
  /// In hu, this message translates to:
  /// **'Nincs betöltött ének, ezért nem lehet hozzárendelni.'**
  String get settingsHotkeysNoSongs;

  /// No description provided for @settingsHotkeyActionHint.
  ///
  /// In hu, this message translates to:
  /// **'pl. Ctrl+Right vagy F8'**
  String get settingsHotkeyActionHint;

  /// No description provided for @settingsHotkeyFieldLabel.
  ///
  /// In hu, this message translates to:
  /// **'Gyorsbillentyű'**
  String get settingsHotkeyFieldLabel;

  /// No description provided for @settingsHotkeySongHint.
  ///
  /// In hu, this message translates to:
  /// **'pl. Ctrl+1 vagy F2'**
  String get settingsHotkeySongHint;

  /// No description provided for @settingsHotkeyAssign.
  ///
  /// In hu, this message translates to:
  /// **'Hozzárendelés'**
  String get settingsHotkeyAssign;

  /// No description provided for @settingsHotkeyDelete.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get settingsHotkeyDelete;

  /// No description provided for @settingsHotkeyActionPrevSong.
  ///
  /// In hu, this message translates to:
  /// **'Előző ének'**
  String get settingsHotkeyActionPrevSong;

  /// No description provided for @settingsHotkeyActionPrevVerse.
  ///
  /// In hu, this message translates to:
  /// **'Előző versszak'**
  String get settingsHotkeyActionPrevVerse;

  /// No description provided for @settingsHotkeyActionToggleProjection.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés ki/be'**
  String get settingsHotkeyActionToggleProjection;

  /// No description provided for @settingsHotkeyActionNextVerse.
  ///
  /// In hu, this message translates to:
  /// **'Következő versszak'**
  String get settingsHotkeyActionNextVerse;

  /// No description provided for @settingsHotkeyActionNextSong.
  ///
  /// In hu, this message translates to:
  /// **'Következő ének'**
  String get settingsHotkeyActionNextSong;

  /// No description provided for @settingsHotkeyActionPrevOrderSet.
  ///
  /// In hu, this message translates to:
  /// **'Előző diasor'**
  String get settingsHotkeyActionPrevOrderSet;

  /// No description provided for @settingsHotkeyActionNextOrderSet.
  ///
  /// In hu, this message translates to:
  /// **'Következő diasor'**
  String get settingsHotkeyActionNextOrderSet;

  /// No description provided for @settingsHotkeyActionHighlightPrev.
  ///
  /// In hu, this message translates to:
  /// **'Kiemelés előző szó'**
  String get settingsHotkeyActionHighlightPrev;

  /// No description provided for @settingsHotkeyActionHighlightNext.
  ///
  /// In hu, this message translates to:
  /// **'Kiemelés következő szó'**
  String get settingsHotkeyActionHighlightNext;

  /// No description provided for @settingsHotkeyActionTogglePhoto.
  ///
  /// In hu, this message translates to:
  /// **'Fénykép ki/be'**
  String get settingsHotkeyActionTogglePhoto;

  /// No description provided for @settingsHotkeyActionToggleChords.
  ///
  /// In hu, this message translates to:
  /// **'Akkordok ki/be'**
  String get settingsHotkeyActionToggleChords;

  /// No description provided for @settingsHotkeyActionToggleBackground.
  ///
  /// In hu, this message translates to:
  /// **'Háttér ki/be'**
  String get settingsHotkeyActionToggleBackground;

  /// No description provided for @settingsHotkeyActionToggleSheetMusic.
  ///
  /// In hu, this message translates to:
  /// **'Kotta ki/be'**
  String get settingsHotkeyActionToggleSheetMusic;

  /// No description provided for @settingsHotkeyActionHomeBooks.
  ///
  /// In hu, this message translates to:
  /// **'Kötetek megjelenítése'**
  String get settingsHotkeyActionHomeBooks;

  /// No description provided for @settingsHotkeyActionHomeDialist.
  ///
  /// In hu, this message translates to:
  /// **'Diasor megjelenítése'**
  String get settingsHotkeyActionHomeDialist;

  /// No description provided for @settingsHotkeyActionHomePresentation.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés megjelenítése'**
  String get settingsHotkeyActionHomePresentation;

  /// No description provided for @settingsDesktopOrderSetHotkeysTitle.
  ///
  /// In hu, this message translates to:
  /// **'Diasor gyorsbillentyűk'**
  String get settingsDesktopOrderSetHotkeysTitle;

  /// No description provided for @settingsOrderSetLabel.
  ///
  /// In hu, this message translates to:
  /// **'Diasor'**
  String get settingsOrderSetLabel;

  /// No description provided for @settingsHotkeysNoOrderSets.
  ///
  /// In hu, this message translates to:
  /// **'Nincs betöltött diasor, így nincs mit hozzárendelni.'**
  String get settingsHotkeysNoOrderSets;

  /// No description provided for @settingsHotkeysOrderSetExistingTitle.
  ///
  /// In hu, this message translates to:
  /// **'Meglévő hozzárendelések'**
  String get settingsHotkeysOrderSetExistingTitle;

  /// No description provided for @settingsOrderSetPickerTitle.
  ///
  /// In hu, this message translates to:
  /// **'Diasor kiválasztása'**
  String get settingsOrderSetPickerTitle;

  /// No description provided for @settingsHotkeyConflict.
  ///
  /// In hu, this message translates to:
  /// **'Ütköző gyorsbillentyű: {hotkey}'**
  String settingsHotkeyConflict(Object hotkey);

  /// No description provided for @settingsNoResults.
  ///
  /// In hu, this message translates to:
  /// **'Nincs találat a keresésre.'**
  String get settingsNoResults;

  /// No description provided for @internetRelaySwitchTitle.
  ///
  /// In hu, this message translates to:
  /// **'Internetes közvetítés'**
  String get internetRelaySwitchTitle;

  /// No description provided for @localNetworkRelaySwitchTitle.
  ///
  /// In hu, this message translates to:
  /// **'Helyi hálózat (TCP/IP)'**
  String get localNetworkRelaySwitchTitle;

  /// No description provided for @passwordHideTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Elrejtés'**
  String get passwordHideTooltip;

  /// No description provided for @passwordShowTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Megjelenítés'**
  String get passwordShowTooltip;

  /// No description provided for @tcpTargetsLabel.
  ///
  /// In hu, this message translates to:
  /// **'Célpontok (IP:port soronként)'**
  String get tcpTargetsLabel;

  /// No description provided for @tcpTargetsHint.
  ///
  /// In hu, this message translates to:
  /// **'192.168.1.50:1024\n192.168.1.51:1024'**
  String get tcpTargetsHint;

  /// No description provided for @tcpTargetsHelp.
  ///
  /// In hu, this message translates to:
  /// **'A sender kliensként csatlakozik a fenti címekhez.'**
  String get tcpTargetsHelp;

  /// No description provided for @projectionMarginsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Margók'**
  String get projectionMarginsTitle;

  /// No description provided for @projectionMarginLeft.
  ///
  /// In hu, this message translates to:
  /// **'Bal margó'**
  String get projectionMarginLeft;

  /// No description provided for @projectionMarginRight.
  ///
  /// In hu, this message translates to:
  /// **'Jobb margó'**
  String get projectionMarginRight;

  /// No description provided for @projectionMarginTop.
  ///
  /// In hu, this message translates to:
  /// **'Felső margó'**
  String get projectionMarginTop;

  /// No description provided for @projectionMarginBottom.
  ///
  /// In hu, this message translates to:
  /// **'Alsó margó'**
  String get projectionMarginBottom;

  /// No description provided for @projectorMonitor.
  ///
  /// In hu, this message translates to:
  /// **'Vetítő kijelzője'**
  String get projectorMonitor;

  /// No description provided for @projectorEnabled.
  ///
  /// In hu, this message translates to:
  /// **'Vetítőablak használata'**
  String get projectorEnabled;

  /// No description provided for @projectorEnabledHint.
  ///
  /// In hu, this message translates to:
  /// **'Külön ablakban vetít asztali környezeten. Kikapcsolva a program csak vezérlőként működik vetítőablak nélkül.'**
  String get projectorEnabledHint;

  /// No description provided for @cameraViewTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kántorszem – Kamerakép mutatása'**
  String get cameraViewTitle;

  /// No description provided for @cameraViewHint.
  ///
  /// In hu, this message translates to:
  /// **'A vetítő eszköz kameraképét mutatja a helyi hálózaton keresztül.'**
  String get cameraViewHint;

  /// No description provided for @cameraSourceLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kamera forrása'**
  String get cameraSourceLabel;

  /// No description provided for @cameraSourceHelp.
  ///
  /// In hu, this message translates to:
  /// **'Válaszd ki, melyik kliens kameraképét várja a nézet. Ha egyetlen célpont van megadva, az automatikusan használódik.'**
  String get cameraSourceHelp;

  /// No description provided for @projectorMonitorAuto.
  ///
  /// In hu, this message translates to:
  /// **'Automatikus (utolsó kijelző)'**
  String get projectorMonitorAuto;

  /// No description provided for @projectorMonitorIndex.
  ///
  /// In hu, this message translates to:
  /// **'{index}. kijelző ({size})'**
  String projectorMonitorIndex(int index, Object size);

  /// No description provided for @projectorMonitorIndexShort.
  ///
  /// In hu, this message translates to:
  /// **'{index}. kijelző'**
  String projectorMonitorIndexShort(int index);

  /// No description provided for @tcpInvalidTargetFormat.
  ///
  /// In hu, this message translates to:
  /// **'Hibás célpont formátum: {target}'**
  String tcpInvalidTargetFormat(Object target);

  /// No description provided for @userActionRegister.
  ///
  /// In hu, this message translates to:
  /// **'Regisztráció'**
  String get userActionRegister;

  /// No description provided for @userActionResendVerification.
  ///
  /// In hu, this message translates to:
  /// **'E-mail újraküldés'**
  String get userActionResendVerification;

  /// No description provided for @userActionForgotPassword.
  ///
  /// In hu, this message translates to:
  /// **'Elfelejtett jelszó'**
  String get userActionForgotPassword;

  /// No description provided for @userActionDeleteUser.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználó törlése'**
  String get userActionDeleteUser;

  /// No description provided for @userActionChangePassword.
  ///
  /// In hu, this message translates to:
  /// **'Jelszóváltoztatás'**
  String get userActionChangePassword;

  /// No description provided for @userActionChangeEmail.
  ///
  /// In hu, this message translates to:
  /// **'E-mail-változtatás'**
  String get userActionChangeEmail;

  /// No description provided for @userActionChangeUsername.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználónév-változtatás'**
  String get userActionChangeUsername;

  /// No description provided for @userFieldUsername.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználónév'**
  String get userFieldUsername;

  /// No description provided for @userFieldPassword.
  ///
  /// In hu, this message translates to:
  /// **'Jelszó'**
  String get userFieldPassword;

  /// No description provided for @userFieldEmail.
  ///
  /// In hu, this message translates to:
  /// **'E-mail'**
  String get userFieldEmail;

  /// No description provided for @userFieldCurrentPassword.
  ///
  /// In hu, this message translates to:
  /// **'Jelenlegi jelszó'**
  String get userFieldCurrentPassword;

  /// No description provided for @userFieldNewPassword.
  ///
  /// In hu, this message translates to:
  /// **'Új jelszó'**
  String get userFieldNewPassword;

  /// No description provided for @userFieldNewEmail.
  ///
  /// In hu, this message translates to:
  /// **'Új e-mail'**
  String get userFieldNewEmail;

  /// No description provided for @userFieldCurrentUsername.
  ///
  /// In hu, this message translates to:
  /// **'Jelenlegi felhasználónév'**
  String get userFieldCurrentUsername;

  /// No description provided for @userFieldNewUsername.
  ///
  /// In hu, this message translates to:
  /// **'Új felhasználónév'**
  String get userFieldNewUsername;

  /// No description provided for @userActionRegisterSuccess.
  ///
  /// In hu, this message translates to:
  /// **'Sikeres adatfelvétel. A regisztráció véglegesítéséhez nézze meg az e-mail-fiókját.'**
  String get userActionRegisterSuccess;

  /// No description provided for @userActionResendVerificationSuccess.
  ///
  /// In hu, this message translates to:
  /// **'Megerősítő e-mail újraküldve. Kérjük, ellenőrizze az e-mailjeit.'**
  String get userActionResendVerificationSuccess;

  /// No description provided for @userActionForgotPasswordSuccess.
  ///
  /// In hu, this message translates to:
  /// **'Ha a fiók létezik, jelszó-visszaállító e-mailt küldtünk.'**
  String get userActionForgotPasswordSuccess;

  /// No description provided for @userActionValidationRequiredFields.
  ///
  /// In hu, this message translates to:
  /// **'A felhasználónév és az e-mail megadása kötelező.'**
  String get userActionValidationRequiredFields;

  /// No description provided for @userActionValidationRequiredPasswordFields.
  ///
  /// In hu, this message translates to:
  /// **'A felhasználónév, a jelenlegi jelszó és az új jelszó megadása kötelező.'**
  String get userActionValidationRequiredPasswordFields;

  /// No description provided for @userActionValidationRequiredChangeEmailFields.
  ///
  /// In hu, this message translates to:
  /// **'A felhasználónév, a jelenlegi jelszó és az új e-mail megadása kötelező.'**
  String get userActionValidationRequiredChangeEmailFields;

  /// No description provided for @userActionValidationRequiredChangeUsernameFields.
  ///
  /// In hu, this message translates to:
  /// **'A jelenlegi felhasználónév, a jelszó és az új felhasználónév megadása kötelező.'**
  String get userActionValidationRequiredChangeUsernameFields;

  /// No description provided for @userActionValidationInvalidEmail.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen e-mail-cím.'**
  String get userActionValidationInvalidEmail;

  /// No description provided for @userActionDeleteUserSuccess.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználó törölve.'**
  String get userActionDeleteUserSuccess;

  /// No description provided for @userActionChangePasswordSuccess.
  ///
  /// In hu, this message translates to:
  /// **'Jelszó sikeresen módosítva.'**
  String get userActionChangePasswordSuccess;

  /// No description provided for @userActionChangeEmailSuccess.
  ///
  /// In hu, this message translates to:
  /// **'E-mail-cím módosítási kérés elküldve. A véglegesítéshez nézze meg az e-mail-fiókját.'**
  String get userActionChangeEmailSuccess;

  /// No description provided for @userActionChangeUsernameSuccess.
  ///
  /// In hu, this message translates to:
  /// **'Felhasználónév módosítva.'**
  String get userActionChangeUsernameSuccess;

  /// No description provided for @userDeleteConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Megerősítés'**
  String get userDeleteConfirmTitle;

  /// No description provided for @userDeleteConfirmMessage.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan törölni szeretnéd ezt a felhasználót? Ez a művelet nem visszavonható.'**
  String get userDeleteConfirmMessage;

  /// No description provided for @userDeleteConfirmButton.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get userDeleteConfirmButton;

  /// No description provided for @userApiError.
  ///
  /// In hu, this message translates to:
  /// **'API hiba: {error}'**
  String userApiError(Object error);

  /// No description provided for @userApiUnauthorized.
  ///
  /// In hu, this message translates to:
  /// **'Sikertelen hitelesítés. Ellenőrizze a felhasználónevet és a jelszót.'**
  String get userApiUnauthorized;

  /// No description provided for @userApiUnknownError.
  ///
  /// In hu, this message translates to:
  /// **'Váratlan API-hiba.'**
  String get userApiUnknownError;

  /// No description provided for @settingsHotkeyPressAnyKey.
  ///
  /// In hu, this message translates to:
  /// **'Nyomj meg bármelyik billentyű kombinációt...'**
  String get settingsHotkeyPressAnyKey;

  /// No description provided for @settingsHotkeyDialogTitle.
  ///
  /// In hu, this message translates to:
  /// **'Gyorsbillentyű rögzítése'**
  String get settingsHotkeyDialogTitle;

  /// No description provided for @settingsHotkeyConfirm.
  ///
  /// In hu, this message translates to:
  /// **'Megerősítés'**
  String get settingsHotkeyConfirm;

  /// No description provided for @settingsHotkeyClearCapture.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get settingsHotkeyClearCapture;

  /// No description provided for @settingsHotkeyClear.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get settingsHotkeyClear;

  /// No description provided for @settingsHotkeyCapture.
  ///
  /// In hu, this message translates to:
  /// **'Rögzítés'**
  String get settingsHotkeyCapture;

  /// No description provided for @settingsSearchKeywordsSystem.
  ///
  /// In hu, this message translates to:
  /// **'rendszer kilepes leallas stop shutdown epstop epshutdown'**
  String get settingsSearchKeywordsSystem;

  /// No description provided for @controlPhotoView.
  ///
  /// In hu, this message translates to:
  /// **'Fénykép / vetítés váltása'**
  String get controlPhotoView;

  /// No description provided for @controlPhotoViewPhoto.
  ///
  /// In hu, this message translates to:
  /// **'Fénykép nézet'**
  String get controlPhotoViewPhoto;

  /// No description provided for @controlPhotoViewPreview.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés előnézet'**
  String get controlPhotoViewPreview;

  /// No description provided for @useSound.
  ///
  /// In hu, this message translates to:
  /// **'Zene lejátszása'**
  String get useSound;

  /// No description provided for @advanceAfterMusic.
  ///
  /// In hu, this message translates to:
  /// **'Továbbítás a zene végén'**
  String get advanceAfterMusic;

  /// No description provided for @liveSubtitlesOn.
  ///
  /// In hu, this message translates to:
  /// **'Élő felirat bekapcsolása'**
  String get liveSubtitlesOn;

  /// No description provided for @liveSubtitlesOff.
  ///
  /// In hu, this message translates to:
  /// **'Élő felirat kikapcsolása'**
  String get liveSubtitlesOff;

  /// No description provided for @liveSubtitlesDownloadTitle.
  ///
  /// In hu, this message translates to:
  /// **'Beszédmodell letöltése'**
  String get liveSubtitlesDownloadTitle;

  /// No description provided for @liveSubtitlesDownloadMessage.
  ///
  /// In hu, this message translates to:
  /// **'A beszédfelismeréshez szükséges modell. Letöltjük most?'**
  String get liveSubtitlesDownloadMessage;

  /// No description provided for @liveSubtitlesDownloading.
  ///
  /// In hu, this message translates to:
  /// **'Beszédmodell letöltése folyamatban...'**
  String get liveSubtitlesDownloading;

  /// No description provided for @liveSubtitlesError.
  ///
  /// In hu, this message translates to:
  /// **'Beszédfelismerési hiba'**
  String get liveSubtitlesError;

  /// No description provided for @vadDownloadTitle.
  ///
  /// In hu, this message translates to:
  /// **'Beszédaktivitás-modell letöltése'**
  String get vadDownloadTitle;

  /// No description provided for @vadDownloadMessage.
  ///
  /// In hu, this message translates to:
  /// **'Az offline beszédfelismeréshez beszédaktivitás-észlelő (VAD) modell szükséges. Letöltjük most?'**
  String get vadDownloadMessage;

  /// No description provided for @vadDownloading.
  ///
  /// In hu, this message translates to:
  /// **'Beszédaktivitás-modell letöltése folyamatban...'**
  String get vadDownloading;

  /// No description provided for @liveSubtitlesMicDevice.
  ///
  /// In hu, this message translates to:
  /// **'Mikrofon'**
  String get liveSubtitlesMicDevice;

  /// No description provided for @liveSubtitlesMicDeviceDefault.
  ///
  /// In hu, this message translates to:
  /// **'Rendszer alapértelmezett'**
  String get liveSubtitlesMicDeviceDefault;

  /// No description provided for @speechSettingsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Beszédfelismerő'**
  String get speechSettingsTitle;

  /// No description provided for @speechFeatureEnabled.
  ///
  /// In hu, this message translates to:
  /// **'Beszédfelismerő engedélyezése'**
  String get speechFeatureEnabled;

  /// No description provided for @speechSettingsSummary.
  ///
  /// In hu, this message translates to:
  /// **'Mikrofon'**
  String get speechSettingsSummary;

  /// No description provided for @speechModelTitle.
  ///
  /// In hu, this message translates to:
  /// **'Beszédmodell'**
  String get speechModelTitle;

  /// No description provided for @speechModelStreaming.
  ///
  /// In hu, this message translates to:
  /// **'Streaming (alacsony késleltetés)'**
  String get speechModelStreaming;

  /// No description provided for @speechModelOffline.
  ///
  /// In hu, this message translates to:
  /// **'Offline (magasabb pontosság)'**
  String get speechModelOffline;

  /// No description provided for @transposeDown.
  ///
  /// In hu, this message translates to:
  /// **'Transzpozíció le'**
  String get transposeDown;

  /// No description provided for @transposeUp.
  ///
  /// In hu, this message translates to:
  /// **'Transzpozíció fel'**
  String get transposeUp;

  /// No description provided for @transposeReset.
  ///
  /// In hu, this message translates to:
  /// **'Transzpozíció alap'**
  String get transposeReset;

  /// No description provided for @diatarDataTransferTitle.
  ///
  /// In hu, this message translates to:
  /// **'Biztonsági mentés'**
  String get diatarDataTransferTitle;

  /// No description provided for @diatarDataTransferDescription.
  ///
  /// In hu, this message translates to:
  /// **'A teljes belső diatar mappa mentése ZIP fájlba, illetve visszaállítása ZIP fájlból.'**
  String get diatarDataTransferDescription;

  /// No description provided for @diatarExportButton.
  ///
  /// In hu, this message translates to:
  /// **'Exportálás'**
  String get diatarExportButton;

  /// No description provided for @diatarImportButton.
  ///
  /// In hu, this message translates to:
  /// **'Importálás'**
  String get diatarImportButton;

  /// No description provided for @diatarZipFileTypeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Diatár biztonsági mentés'**
  String get diatarZipFileTypeLabel;

  /// No description provided for @diatarExportSuccess.
  ///
  /// In hu, this message translates to:
  /// **'Az exportálás elkészült: {fileName}'**
  String diatarExportSuccess(Object fileName);

  /// No description provided for @diatarImportSuccess.
  ///
  /// In hu, this message translates to:
  /// **'{imported} fájl visszaállítva.'**
  String diatarImportSuccess(int imported);

  /// No description provided for @diatarImportConflictTitle.
  ///
  /// In hu, this message translates to:
  /// **'Már létező fájlok'**
  String get diatarImportConflictTitle;

  /// No description provided for @diatarImportConflictMessage.
  ///
  /// In hu, this message translates to:
  /// **'{count} importálandó fájl már létezik. A teljes importálás során felülírjuk vagy mellőzzük ezeket?'**
  String diatarImportConflictMessage(int count);

  /// No description provided for @diatarImportOverwriteAll.
  ///
  /// In hu, this message translates to:
  /// **'Felülírás'**
  String get diatarImportOverwriteAll;

  /// No description provided for @diatarImportSkipAll.
  ///
  /// In hu, this message translates to:
  /// **'Mellőzés'**
  String get diatarImportSkipAll;

  /// No description provided for @diatarExportSourceMissing.
  ///
  /// In hu, this message translates to:
  /// **'A belső diatar mappa nem található.'**
  String get diatarExportSourceMissing;

  /// No description provided for @diatarImportInvalidArchive.
  ///
  /// In hu, this message translates to:
  /// **'A kiválasztott fájl nem érvényes Diatár biztonsági mentés.'**
  String get diatarImportInvalidArchive;

  /// No description provided for @diatarTransferArchive.
  ///
  /// In hu, this message translates to:
  /// **'ZIP fájl: {fileName}'**
  String diatarTransferArchive(Object fileName);

  /// No description provided for @diatarTransferCurrentFile.
  ///
  /// In hu, this message translates to:
  /// **'Feldolgozás: {fileName}'**
  String diatarTransferCurrentFile(Object fileName);

  /// No description provided for @diatarTransferProgress.
  ///
  /// In hu, this message translates to:
  /// **'{percent}%'**
  String diatarTransferProgress(int percent);

  /// No description provided for @diatarTransferCancelled.
  ///
  /// In hu, this message translates to:
  /// **'A műveletet megszakítottad.'**
  String get diatarTransferCancelled;

  /// No description provided for @diatarTransferError.
  ///
  /// In hu, this message translates to:
  /// **'A művelet nem sikerült: {error}'**
  String diatarTransferError(Object error);

  /// No description provided for @szentirasTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Szentírás'**
  String get szentirasTooltip;

  /// No description provided for @szentirasTitle.
  ///
  /// In hu, this message translates to:
  /// **'Szentírás beillesztése'**
  String get szentirasTitle;

  /// No description provided for @szentirasReferenceLabel.
  ///
  /// In hu, this message translates to:
  /// **'Hivatkozás'**
  String get szentirasReferenceLabel;

  /// No description provided for @szentirasReferenceHint.
  ///
  /// In hu, this message translates to:
  /// **'pl. 1Kor13,10-13'**
  String get szentirasReferenceHint;

  /// No description provided for @szentirasTranslationLabel.
  ///
  /// In hu, this message translates to:
  /// **'Fordítás'**
  String get szentirasTranslationLabel;

  /// No description provided for @szentirasTranslationDefault.
  ///
  /// In hu, this message translates to:
  /// **'Alapértelmezett'**
  String get szentirasTranslationDefault;

  /// No description provided for @szentirasFetchButton.
  ///
  /// In hu, this message translates to:
  /// **'Betöltés'**
  String get szentirasFetchButton;

  /// No description provided for @szentirasImportButton.
  ///
  /// In hu, this message translates to:
  /// **'Beillesztés'**
  String get szentirasImportButton;

  /// No description provided for @szentirasInsertAll.
  ///
  /// In hu, this message translates to:
  /// **'Összes beszúrása ({count} vers)'**
  String szentirasInsertAll(int count);

  /// No description provided for @szentirasLoading.
  ///
  /// In hu, this message translates to:
  /// **'Betöltés…'**
  String get szentirasLoading;

  /// No description provided for @szentirasError.
  ///
  /// In hu, this message translates to:
  /// **'Hiba: {error}'**
  String szentirasError(Object error);

  /// No description provided for @szentirasNoVerses.
  ///
  /// In hu, this message translates to:
  /// **'Nem található vers.'**
  String get szentirasNoVerses;

  /// No description provided for @szentirasChunkSizeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Dia szóhatár'**
  String get szentirasChunkSizeLabel;

  /// No description provided for @szentirasChunkSizeHint.
  ///
  /// In hu, this message translates to:
  /// **'max. szavak diánként'**
  String get szentirasChunkSizeHint;

  /// No description provided for @settingsSzentirasApiKeyLabel.
  ///
  /// In hu, this message translates to:
  /// **'szentiras.eu API kulcs'**
  String get settingsSzentirasApiKeyLabel;

  /// No description provided for @settingsSzentirasApiKeyHint.
  ///
  /// In hu, this message translates to:
  /// **'Kulcs a szentiras.eu oldalról'**
  String get settingsSzentirasApiKeyHint;

  /// No description provided for @szentirasApiKeyPrompt.
  ///
  /// In hu, this message translates to:
  /// **'Add meg a szentiras.eu API kulcsot a Szentírás funkció használatához.'**
  String get szentirasApiKeyPrompt;

  /// No description provided for @statusSzentirasApiKeyMissing.
  ///
  /// In hu, this message translates to:
  /// **'Nincs beállítva a szentiras.eu API kulcs.'**
  String get statusSzentirasApiKeyMissing;

  /// No description provided for @settingsApiKeysTitle.
  ///
  /// In hu, this message translates to:
  /// **'API kulcsok'**
  String get settingsApiKeysTitle;

  /// No description provided for @settingsApiKeysSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Szentírás: {status}'**
  String settingsApiKeysSubtitle(Object status);

  /// No description provided for @settingsApiKeysStatusSet.
  ///
  /// In hu, this message translates to:
  /// **'Beállítva'**
  String get settingsApiKeysStatusSet;

  /// No description provided for @settingsApiKeysStatusMissing.
  ///
  /// In hu, this message translates to:
  /// **'Nincs beállítva'**
  String get settingsApiKeysStatusMissing;

  /// No description provided for @szentirasApiKeyHelp.
  ///
  /// In hu, this message translates to:
  /// **'Szerezd be a kulcsot:\nszentiras.eu → Belépés → Profil → API kulcsok'**
  String get szentirasApiKeyHelp;

  /// No description provided for @szentirasApiKeySave.
  ///
  /// In hu, this message translates to:
  /// **'Mentés'**
  String get szentirasApiKeySave;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In hu, this message translates to:
  /// **'Üdvözöl a Diatár!'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In hu, this message translates to:
  /// **'Templomi énekkivetítő alkalmazás.\n\nVálassz énekeskönyvet, állíts össze énekrendet, majd küldd ki a kivetítőre.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In hu, this message translates to:
  /// **'Főképernyő'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In hu, this message translates to:
  /// **'Három mód közül választhatsz:\n\n• Kötetek: énekeskönyv böngészése, ének és versszak kiválasztása\n• Diasor: diasor megtekintése a vetítés mellett\n• Vetítés: teljes képernyős előnézet'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In hu, this message translates to:
  /// **'Énekrend készítése'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In hu, this message translates to:
  /// **'1. Keresd ki az énekeket a Kötetek módban\n2. Nyisd meg a Diasor szerkesztőt\n3. Add hozzá a versszakokat, szöveges diákat, elválasztókat\n4. Mentsd el .dia fájlként későbbi használatra'**
  String get onboardingPage3Body;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In hu, this message translates to:
  /// **'Speciális funkciók'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingPage4Body.
  ///
  /// In hu, this message translates to:
  /// **'• Zsolozsma: napi zsolozsma betöltése\n• Napi lelki batyu: napi olvasmányok\n• Szentírás: bibliaversek beillesztése\n• Keresés: teljes szöveges keresés\n• Gyorsbillentyűk: asztali billentyűparancsok'**
  String get onboardingPage4Body;

  /// No description provided for @onboardingGotIt.
  ///
  /// In hu, this message translates to:
  /// **'Értem, kezdjük!'**
  String get onboardingGotIt;

  /// No description provided for @onboardingSkip.
  ///
  /// In hu, this message translates to:
  /// **'Kihagyás'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In hu, this message translates to:
  /// **'Tovább'**
  String get onboardingNext;

  /// No description provided for @onboardingDone.
  ///
  /// In hu, this message translates to:
  /// **'Kész'**
  String get onboardingDone;

  /// No description provided for @settingsInternetDescription.
  ///
  /// In hu, this message translates to:
  /// **'Internetes közvetítés MQTT protokollal. Hozz létre felhasználót, majd oszd meg a QR-kódot a távoli DiaVetítővel.'**
  String get settingsInternetDescription;

  /// No description provided for @settingsLocalNetworkDescription.
  ///
  /// In hu, this message translates to:
  /// **'TCP/IP kapcsolat helyi hálózaton. Add meg a vetítő IP-címét és portját.'**
  String get settingsLocalNetworkDescription;

  /// No description provided for @colorsDescription.
  ///
  /// In hu, this message translates to:
  /// **'A vetített diák színeinek testreszabása: háttér, szöveg, üres dia és kiemelés.'**
  String get colorsDescription;

  /// No description provided for @projectionSettingsDescription.
  ///
  /// In hu, this message translates to:
  /// **'Betűméret, margók, háttérkép és egyéb vetítési paraméterek beállítása.'**
  String get projectionSettingsDescription;

  /// No description provided for @settingsFilesDescription.
  ///
  /// In hu, this message translates to:
  /// **'Énektárak importálása, DTZ kották, biztonsági mentés készítése és visszaállítása.'**
  String get settingsFilesDescription;

  /// No description provided for @settingsGeneralDescription.
  ///
  /// In hu, this message translates to:
  /// **'Alkalmazás téma (sötét/világos) és nyelv beállítása.'**
  String get settingsGeneralDescription;

  /// No description provided for @systemActionsDescription.
  ///
  /// In hu, this message translates to:
  /// **'Kilépés, énektárak újratöltése, távoli vetítő leállítása.'**
  String get systemActionsDescription;

  /// No description provided for @settingsHotkeysDescription.
  ///
  /// In hu, this message translates to:
  /// **'Billentyűparancsok a gyors vezérléshez asztali környezetben.'**
  String get settingsHotkeysDescription;

  /// No description provided for @settingsOnboardingButton.
  ///
  /// In hu, this message translates to:
  /// **'Kezdő lépések'**
  String get settingsOnboardingButton;

  /// No description provided for @impresszumTitle.
  ///
  /// In hu, this message translates to:
  /// **'Impresszum'**
  String get impresszumTitle;

  /// No description provided for @impresszumSummary.
  ///
  /// In hu, this message translates to:
  /// **'Fejlesztők, licenszek és források'**
  String get impresszumSummary;

  /// No description provided for @impresszumDescription.
  ///
  /// In hu, this message translates to:
  /// **'A Diatár fejlesztőinek és a felhasznált szoftvereknek a bemutatása.'**
  String get impresszumDescription;

  /// No description provided for @impresszumDevelopers.
  ///
  /// In hu, this message translates to:
  /// **'Fejlesztők'**
  String get impresszumDevelopers;

  /// No description provided for @impresszumDevelopersBody.
  ///
  /// In hu, this message translates to:
  /// **'A Diatár a Szent József Hackathon közösségének munkája.'**
  String get impresszumDevelopersBody;

  /// No description provided for @impresszumHackathonTitle.
  ///
  /// In hu, this message translates to:
  /// **'Szent József Hackathon'**
  String get impresszumHackathonTitle;

  /// No description provided for @impresszumHackathonBody.
  ///
  /// In hu, this message translates to:
  /// **'A Diatár a IV. Szent József Hackathon (2026, Szeged) keretében készült.'**
  String get impresszumHackathonBody;

  /// No description provided for @impresszumDataSources.
  ///
  /// In hu, this message translates to:
  /// **'Adatforrások'**
  String get impresszumDataSources;

  /// No description provided for @impresszumSzentiras.
  ///
  /// In hu, this message translates to:
  /// **'Szentírás.eu — a bibliai szövegek forrása'**
  String get impresszumSzentiras;

  /// No description provided for @impresszumLicenses.
  ///
  /// In hu, this message translates to:
  /// **'Felhasznált szoftverek és licenek'**
  String get impresszumLicenses;

  /// No description provided for @impresszumNemotron.
  ///
  /// In hu, this message translates to:
  /// **'NVIDIA Nemotron 3.5 ASR — OpenMDW-1.1 licensz'**
  String get impresszumNemotron;

  /// No description provided for @impresszumSherpaOnnx.
  ///
  /// In hu, this message translates to:
  /// **'Sherpa-ONNX (k2-fsa) — Apache-2.0 licensz'**
  String get impresszumSherpaOnnx;

  /// No description provided for @impresszumFlutter.
  ///
  /// In hu, this message translates to:
  /// **'Flutter — BSD-3 licensz'**
  String get impresszumFlutter;

  /// No description provided for @impresszumRecord.
  ///
  /// In hu, this message translates to:
  /// **'Record (llfbandit) — MIT licensz'**
  String get impresszumRecord;

  /// No description provided for @impresszumLinks.
  ///
  /// In hu, this message translates to:
  /// **'Linkek'**
  String get impresszumLinks;

  /// No description provided for @impresszumWebsite.
  ///
  /// In hu, this message translates to:
  /// **'diatar.eu'**
  String get impresszumWebsite;

  /// No description provided for @impresszumGitHub.
  ///
  /// In hu, this message translates to:
  /// **'GitHub'**
  String get impresszumGitHub;

  /// No description provided for @impresszumHackathonLink.
  ///
  /// In hu, this message translates to:
  /// **'Szent József Hackathon'**
  String get impresszumHackathonLink;

  /// No description provided for @impresszumSzentirasLink.
  ///
  /// In hu, this message translates to:
  /// **'szentiras.eu'**
  String get impresszumSzentirasLink;

  /// No description provided for @speechLanguageTitle.
  ///
  /// In hu, this message translates to:
  /// **'Beszédfelismerő nyelve'**
  String get speechLanguageTitle;

  /// No description provided for @speechLangAuto.
  ///
  /// In hu, this message translates to:
  /// **'Automatikus (minden nyelv)'**
  String get speechLangAuto;

  /// No description provided for @speechLangEsUS.
  ///
  /// In hu, this message translates to:
  /// **'Spanyol (es-US)'**
  String get speechLangEsUS;

  /// No description provided for @speechLangEsES.
  ///
  /// In hu, this message translates to:
  /// **'Spanyol (es-ES)'**
  String get speechLangEsES;

  /// No description provided for @speechLangItIT.
  ///
  /// In hu, this message translates to:
  /// **'Olasz (it-IT)'**
  String get speechLangItIT;

  /// No description provided for @speechLangPtBR.
  ///
  /// In hu, this message translates to:
  /// **'Portugál (pt-BR)'**
  String get speechLangPtBR;

  /// No description provided for @speechLangPtPT.
  ///
  /// In hu, this message translates to:
  /// **'Portugál (pt-PT)'**
  String get speechLangPtPT;

  /// No description provided for @speechLangHiIN.
  ///
  /// In hu, this message translates to:
  /// **'Hindi (hi-IN)'**
  String get speechLangHiIN;

  /// No description provided for @speechLangKoKR.
  ///
  /// In hu, this message translates to:
  /// **'Koreai (ko-KR)'**
  String get speechLangKoKR;

  /// No description provided for @speechLangEnUS.
  ///
  /// In hu, this message translates to:
  /// **'Angol (en-US)'**
  String get speechLangEnUS;

  /// No description provided for @speechLangEnGB.
  ///
  /// In hu, this message translates to:
  /// **'Angol (en-GB)'**
  String get speechLangEnGB;

  /// No description provided for @speechLangDeDE.
  ///
  /// In hu, this message translates to:
  /// **'Német (de-DE)'**
  String get speechLangDeDE;

  /// No description provided for @speechLangFrFR.
  ///
  /// In hu, this message translates to:
  /// **'Francia (fr-FR)'**
  String get speechLangFrFR;

  /// No description provided for @speechLangFrCA.
  ///
  /// In hu, this message translates to:
  /// **'Francia (fr-CA)'**
  String get speechLangFrCA;

  /// No description provided for @speechLangRuRU.
  ///
  /// In hu, this message translates to:
  /// **'Orosz (ru-RU)'**
  String get speechLangRuRU;

  /// No description provided for @speechLangTrTR.
  ///
  /// In hu, this message translates to:
  /// **'Török (tr-TR)'**
  String get speechLangTrTR;

  /// No description provided for @speechLangViVN.
  ///
  /// In hu, this message translates to:
  /// **'Vietnami (vi-VN)'**
  String get speechLangViVN;

  /// No description provided for @speechLangNlNL.
  ///
  /// In hu, this message translates to:
  /// **'Holland (nl-NL)'**
  String get speechLangNlNL;

  /// No description provided for @speechLangJaJP.
  ///
  /// In hu, this message translates to:
  /// **'Japán (ja-JP)'**
  String get speechLangJaJP;

  /// No description provided for @speechLangArAR.
  ///
  /// In hu, this message translates to:
  /// **'Arab (ar-AR)'**
  String get speechLangArAR;

  /// No description provided for @speechLangUkUA.
  ///
  /// In hu, this message translates to:
  /// **'Ukrán (uk-UA)'**
  String get speechLangUkUA;

  /// No description provided for @speechLangPlPL.
  ///
  /// In hu, this message translates to:
  /// **'Lengyel (pl-PL)'**
  String get speechLangPlPL;

  /// No description provided for @speechLangNbNO.
  ///
  /// In hu, this message translates to:
  /// **'Norvég bokmål (nb-NO)'**
  String get speechLangNbNO;

  /// No description provided for @speechLangFiFI.
  ///
  /// In hu, this message translates to:
  /// **'Finn (fi-FI)'**
  String get speechLangFiFI;

  /// No description provided for @speechLangZhCN.
  ///
  /// In hu, this message translates to:
  /// **'Mandarin (zh-CN)'**
  String get speechLangZhCN;

  /// No description provided for @speechLangCsCZ.
  ///
  /// In hu, this message translates to:
  /// **'Cseh (cs-CZ)'**
  String get speechLangCsCZ;

  /// No description provided for @speechLangBgBG.
  ///
  /// In hu, this message translates to:
  /// **'Bolgár (bg-BG)'**
  String get speechLangBgBG;

  /// No description provided for @speechLangSkSK.
  ///
  /// In hu, this message translates to:
  /// **'Szlovák (sk-SK)'**
  String get speechLangSkSK;

  /// No description provided for @speechLangSvSE.
  ///
  /// In hu, this message translates to:
  /// **'Svéd (sv-SE)'**
  String get speechLangSvSE;

  /// No description provided for @speechLangHrHR.
  ///
  /// In hu, this message translates to:
  /// **'Horvát (hr-HR)'**
  String get speechLangHrHR;

  /// No description provided for @speechLangRoRO.
  ///
  /// In hu, this message translates to:
  /// **'Román (ro-RO)'**
  String get speechLangRoRO;

  /// No description provided for @speechLangEtEE.
  ///
  /// In hu, this message translates to:
  /// **'Észt (et-EE)'**
  String get speechLangEtEE;

  /// No description provided for @speechLangDaDK.
  ///
  /// In hu, this message translates to:
  /// **'Dán (da-DK)'**
  String get speechLangDaDK;

  /// No description provided for @speechLangHuHU.
  ///
  /// In hu, this message translates to:
  /// **'Magyar (hu-HU)'**
  String get speechLangHuHU;

  /// No description provided for @picPlcSettingsTitle.
  ///
  /// In hu, this message translates to:
  /// **'PICPLC vezérlő'**
  String get picPlcSettingsTitle;

  /// No description provided for @picPlcSettingsEnabledSummary.
  ///
  /// In hu, this message translates to:
  /// **'Engedélyezve, port: {port}'**
  String picPlcSettingsEnabledSummary(Object port);

  /// No description provided for @picPlcSettingsDisabledSummary.
  ///
  /// In hu, this message translates to:
  /// **'Kikapcsolva'**
  String get picPlcSettingsDisabledSummary;

  /// No description provided for @picPlcSettingsDescription.
  ///
  /// In hu, this message translates to:
  /// **'A PICPLC soros vezérlő, a gombkiosztások és a LED-ek beállítása.'**
  String get picPlcSettingsDescription;

  /// No description provided for @picPlcEnabledLabel.
  ///
  /// In hu, this message translates to:
  /// **'PICPLC vezérlő engedélyezése'**
  String get picPlcEnabledLabel;

  /// No description provided for @picPlcPortLabel.
  ///
  /// In hu, this message translates to:
  /// **'Soros port'**
  String get picPlcPortLabel;

  /// No description provided for @picPlcPortHint.
  ///
  /// In hu, this message translates to:
  /// **'pl. COM3 vagy /dev/ttyUSB0'**
  String get picPlcPortHint;

  /// No description provided for @picPlcPortRequired.
  ///
  /// In hu, this message translates to:
  /// **'A PICPLC vezérlő engedélyezéséhez add meg a soros portot.'**
  String get picPlcPortRequired;

  /// No description provided for @picPlcButtonsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Gombkiosztások'**
  String get picPlcButtonsTitle;

  /// No description provided for @picPlcButtonLabel.
  ///
  /// In hu, this message translates to:
  /// **'{number}. gomb'**
  String picPlcButtonLabel(int number);

  /// No description provided for @picPlcLedsTitle.
  ///
  /// In hu, this message translates to:
  /// **'LED-kiosztások'**
  String get picPlcLedsTitle;

  /// No description provided for @picPlcLedLabel.
  ///
  /// In hu, this message translates to:
  /// **'{number}. LED'**
  String picPlcLedLabel(int number);

  /// No description provided for @picPlcActionNone.
  ///
  /// In hu, this message translates to:
  /// **'Nincs funkciója'**
  String get picPlcActionNone;

  /// No description provided for @picPlcActionToggleProjection.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés ki/be nyomógomb'**
  String get picPlcActionToggleProjection;

  /// No description provided for @picPlcActionProjectionSwitch.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés ki/be kapcsoló'**
  String get picPlcActionProjectionSwitch;

  /// No description provided for @picPlcActionPreviousVerse.
  ///
  /// In hu, this message translates to:
  /// **'Előző dia'**
  String get picPlcActionPreviousVerse;

  /// No description provided for @picPlcActionNextVerse.
  ///
  /// In hu, this message translates to:
  /// **'Következő dia'**
  String get picPlcActionNextVerse;

  /// No description provided for @picPlcActionPreviousSong.
  ///
  /// In hu, this message translates to:
  /// **'Előző ének'**
  String get picPlcActionPreviousSong;

  /// No description provided for @picPlcActionNextSong.
  ///
  /// In hu, this message translates to:
  /// **'Következő ének'**
  String get picPlcActionNextSong;

  /// No description provided for @picPlcActionToggleDirection.
  ///
  /// In hu, this message translates to:
  /// **'Irányváltó nyomógomb'**
  String get picPlcActionToggleDirection;

  /// No description provided for @picPlcActionDirectionSwitch.
  ///
  /// In hu, this message translates to:
  /// **'Előre/hátra kapcsoló'**
  String get picPlcActionDirectionSwitch;

  /// No description provided for @picPlcActionStep.
  ///
  /// In hu, this message translates to:
  /// **'Dia léptető gomb'**
  String get picPlcActionStep;

  /// No description provided for @picPlcLedProjectionOn.
  ///
  /// In hu, this message translates to:
  /// **'Vetítés bekapcsolva'**
  String get picPlcLedProjectionOn;

  /// No description provided for @picPlcLedForward.
  ///
  /// In hu, this message translates to:
  /// **'Előre irány'**
  String get picPlcLedForward;

  /// No description provided for @picPlcLedBackward.
  ///
  /// In hu, this message translates to:
  /// **'Hátra irány'**
  String get picPlcLedBackward;

  /// No description provided for @songOrder.
  ///
  /// In hu, this message translates to:
  /// **'Énekrend'**
  String get songOrder;

  /// No description provided for @customOrderEmbedImagesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Képek beágyazása?'**
  String get customOrderEmbedImagesTitle;

  /// No description provided for @customOrderEmbedImagesMessage.
  ///
  /// In hu, this message translates to:
  /// **'A diasor képeket tartalmaz. Beágyazzuk őket a DIA fájlba, hogy az eredeti képfájlok nélkül is használható legyen?'**
  String get customOrderEmbedImagesMessage;

  /// No description provided for @customOrderEmbedImagesNo.
  ///
  /// In hu, this message translates to:
  /// **'Ne ágyazza be'**
  String get customOrderEmbedImagesNo;

  /// No description provided for @customOrderEmbedImagesYes.
  ///
  /// In hu, this message translates to:
  /// **'Beágyazás'**
  String get customOrderEmbedImagesYes;

  /// No description provided for @customOrderEmbedImageMissing.
  ///
  /// In hu, this message translates to:
  /// **'A beágyazandó kép nem található: {path}'**
  String customOrderEmbedImageMissing(Object path);
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
