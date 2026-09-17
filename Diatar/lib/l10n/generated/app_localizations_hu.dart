// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Diatár';

  @override
  String get settingsTooltip => 'Beállítások';

  @override
  String get playlistsTooltip => 'Diasorok';

  @override
  String get playlistsTitle => 'Diasorok';

  @override
  String get customOrderTooltip => 'Szerkesztő';

  @override
  String get zsolozsmaTooltip => 'Zsolozsma';

  @override
  String get zsolozsmaTitle => 'Zsolozsma kiválasztása';

  @override
  String get zsolozsmaDateLabel => 'Dátum';

  @override
  String get zsolozsmaPickDate => 'Dátum választása';

  @override
  String get zsolozsmaSyncButton => 'Éves ZIP frissítés';

  @override
  String get zsolozsmaNoItems => 'Erre a napra nincs elérhető napszak lista.';

  @override
  String get zsolozsmaDiagnosticsLabel => 'Diagnosztika';

  @override
  String get zsolozsmaSelectionHint =>
      'A kiválasztás most még csak listáz és kijelöl. A diasorra bontás a következő lépésben érkezik.';

  @override
  String get batyuTooltip => 'Napi lelki batyu';

  @override
  String get batyuTitle => 'Napi lelki batyu importálása';

  @override
  String get batyuDateLabel => 'Dátum';

  @override
  String get batyuWordsPerSlide => 'Szavak száma diánként';

  @override
  String get batyuNoItems =>
      'Erre a napra nincs elérhető olvasmány a Napi lelki batyuban.';

  @override
  String batyuBookLabel(Object name) {
    return 'Napi lelki batyu ($name)';
  }

  @override
  String get addSlideTooltip => 'Dia hozzáadása';

  @override
  String get addTextSlide => 'Szöveges dia';

  @override
  String get addImageSlide => 'Képes dia';

  @override
  String get addImageSlideTooltip => 'Kép hozzáadása';

  @override
  String get downloadBooksTooltip => 'Énektárak letöltése';

  @override
  String get downloadDtz => 'DTZ letöltése';

  @override
  String get downloadDtzTitle => 'DTX kották (DTZ) letöltése';

  @override
  String get downloadDtzHint =>
      'Jelöld be a letölteni kívánt DTZ fájlokat és a hozzájuk tartozó képeket (zip).';

  @override
  String get downloadDtzWithImages => 'Képek (zip) is';

  @override
  String downloadDtzCount(int count) {
    return '$count elem kijelölve';
  }

  @override
  String get downloadDtzNoItems => 'Nincs letölthető DTZ fájl.';

  @override
  String get downloadTabDtx => 'Kötetek';

  @override
  String get downloadTabDtz => 'Kották';

  @override
  String get downloadTabMusic => 'Zenék';

  @override
  String get downloadTitle => 'Letöltés';

  @override
  String get downloadManagerNameColumn => 'Kötetek';

  @override
  String get downloadManagerUpdateColumn => 'Frissítés';

  @override
  String get downloadManagerExcludedColumn => 'Mellőzött';

  @override
  String get downloadManagerUserImportedTag => 'Felhasználói import';

  @override
  String get downloadManagerUpdateAvailable => 'Frissíthető';

  @override
  String get downloadManagerUpToDate => 'Naprakész';

  @override
  String get downloadUserImportedGroup => 'Felhasználói';

  @override
  String get downloadMessage =>
      'A letöltési párbeszéd később visszahelyezhető.';

  @override
  String get refreshTooltip => 'Frissítés';

  @override
  String get ok => 'Rendben';

  @override
  String get songPrev => 'Ének -';

  @override
  String get songNext => 'Ének +';

  @override
  String get projectionOn => 'Vetítés BE';

  @override
  String get projectionOff => 'Vetítés KI';

  @override
  String get hideControlWindow => 'Vezérlő ablak elrejtése';

  @override
  String get previous => 'Előző';

  @override
  String get next => 'Következő';

  @override
  String get highlightPrev => 'Szókiemelés ←';

  @override
  String get highlightNext => 'Szókiemelés →';

  @override
  String positionLabel(int current, int total) {
    return 'Pozíció: $current/$total';
  }

  @override
  String statusLabel(Object status) {
    return 'Státusz: $status';
  }

  @override
  String get statusStarting => 'Indítás...';

  @override
  String statusSenderError(Object message) {
    return '$message';
  }

  @override
  String statusSenderTcpError(Object error) {
    return 'TCP hiba: $error';
  }

  @override
  String statusSenderOpenPortFailed(int port, Object error) {
    return 'Nem sikerült portot nyitni ($port): $error';
  }

  @override
  String get statusSenderMqttConnectFailed =>
      'MQTT sender kapcsolódás sikertelen.';

  @override
  String statusSenderMqttError(Object error) {
    return 'MQTT sender hiba: $error';
  }

  @override
  String statusMqttSending(Object user, Object channel) {
    return 'MQTT küldés: $user/$channel';
  }

  @override
  String statusTcpSending(int port) {
    return 'TCP küldés: $port';
  }

  @override
  String statusNoDtxFiles(Object path) {
    return 'Nincs .dtx fájl: $path';
  }

  @override
  String get statusAllSongbooksDisabled =>
      'Minden énektár le van tiltva a diasorban.';

  @override
  String statusSongbooksLoaded(int count) {
    return '$count kötet betöltve';
  }

  @override
  String statusLoadError(Object error) {
    return 'Betöltési hiba: $error';
  }

  @override
  String statusCustomOrderSelected(Object label) {
    return 'Saját sorrend: $label';
  }

  @override
  String statusOrderSaved(Object path) {
    return 'Sorrend mentve: $path';
  }

  @override
  String statusDiaFileMissing(Object path) {
    return 'Nincs ilyen .DIA fájl: $path';
  }

  @override
  String statusOrderLoaded(int count, Object path) {
    return 'Sorrend betöltve ($count elem): $path';
  }

  @override
  String get statusDownloadListLoading => 'Énektár lista letöltése...';

  @override
  String statusDownloadProgress(
    int current,
    int total,
    Object name,
    int percent,
  ) {
    return 'Letöltés: $current/$total $name $percent%';
  }

  @override
  String get statusDownloadSummaryNone => 'Nincs új énektár frissítés.';

  @override
  String statusDownloadSummary(int downloaded, int skipped) {
    return '$downloaded fájl letöltve, $skipped változatlan.';
  }

  @override
  String statusDownloadError(Object error) {
    return 'Letöltési hiba: $error';
  }

  @override
  String statusZsolozsmaSyncOk(int downloaded, int failed) {
    return 'Zsolozsma ZIP frissítve: $downloaded letöltve, $failed hiba.';
  }

  @override
  String statusZsolozsmaSyncError(Object error) {
    return 'Zsolozsma ZIP frissítési hiba: $error';
  }

  @override
  String statusZsolozsmaDayLoaded(int count, Object date) {
    return 'Zsolozsma lista betöltve ($count) - $date';
  }

  @override
  String statusZsolozsmaDayEmpty(Object date) {
    return 'Erre a napra nincs zsolozsma lista: $date';
  }

  @override
  String statusZsolozsmaDayError(Object error) {
    return 'Zsolozsma lista hiba: $error';
  }

  @override
  String statusZsolozsmaPartSelected(Object date, Object title) {
    return 'Zsolozsma kijelölve ($date): $title';
  }

  @override
  String statusZsolozsmaPartLoaded(int count, Object date, Object title) {
    return 'Zsolozsma betöltve ($count dia) - $date: $title';
  }

  @override
  String statusZsolozsmaPartLoadError(Object title) {
    return 'A kiválasztott zsolozsma napszak nem tölthető be: $title';
  }

  @override
  String statusBookSelected(Object name) {
    return 'Kötet: $name';
  }

  @override
  String statusSongPicked(Object name) {
    return 'Ének: $name';
  }

  @override
  String statusVersePicked(Object name) {
    return 'Versszak: $name';
  }

  @override
  String statusSongSelected(Object title) {
    return 'Ének: $title';
  }

  @override
  String statusSongVerseSelected(Object title) {
    return 'Ének/versszak: $title';
  }

  @override
  String get statusProjectionOn => 'Vetítés: BE';

  @override
  String get statusProjectionOff => 'Vetítés: KI';

  @override
  String get statusImagePathEmpty => 'A kép fájl útvonala üres.';

  @override
  String get statusCustomTextEmpty => 'Adj meg címet vagy legalább egy sort.';

  @override
  String statusCustomTextSent(Object title) {
    return 'Szöveges dia elküldve: $title';
  }

  @override
  String statusCustomTextError(Object error) {
    return 'Szöveges dia küldési hiba: $error';
  }

  @override
  String statusImageNotFound(Object path) {
    return 'A kép fájl nem található: $path';
  }

  @override
  String statusImageSent(Object name) {
    return 'Kép elküldve: $name';
  }

  @override
  String statusImageSendError(Object error) {
    return 'Kép küldési hiba: $error';
  }

  @override
  String get statusBlankPathEmpty => 'A háttérkép fájl útvonala üres.';

  @override
  String statusBlankNotFound(Object path) {
    return 'A háttérkép fájl nem található: $path';
  }

  @override
  String statusBlankSet(Object name) {
    return 'Háttérkép beállítva: $name';
  }

  @override
  String statusBlankSendError(Object error) {
    return 'Háttérkép küldési hiba: $error';
  }

  @override
  String get statusBlankCleared => 'Háttérkép törölve.';

  @override
  String statusBlankClearError(Object error) {
    return 'Háttérkép törlési hiba: $error';
  }

  @override
  String get statusShutdownCommandSent => 'Lezárás utasitas elküldve.';

  @override
  String get statusStopCommandSent => 'Megállítás utasitas elküldve.';

  @override
  String statusCommandSendError(Object error) {
    return 'Utasítás küldési hiba: $error';
  }

  @override
  String sendStatusLabel(
    Object protocol,
    Object senderState,
    Object clientState,
  ) {
    return 'Küldés ($protocol): $senderState, kliens: $clientState';
  }

  @override
  String get protocolMqtt => 'MQTT';

  @override
  String get protocolTcp => 'TCP';

  @override
  String get senderStateActive => 'aktív';

  @override
  String get senderStateOff => 'kikapcsolva';

  @override
  String get clientStateConnected => 'csatlakozva';

  @override
  String get clientStateWaiting => 'várakozik';

  @override
  String tcpPortLabel(int port) {
    return 'TCP port: $port';
  }

  @override
  String downloadProgress(int current, int total, Object name) {
    return 'Letöltés: $current/$total $name';
  }

  @override
  String get noLoadedSlide => 'Nincs betöltött dia.';

  @override
  String get homeControlModeTooltip => 'Képernyőmód';

  @override
  String get homeControlModeBooks => 'Kötetek';

  @override
  String get homeControlModeDialist => 'Diasor';

  @override
  String get homeControlModePresentation => 'Vetítés';

  @override
  String dialistNamedLabel(Object name) {
    return 'Diasor: $name';
  }

  @override
  String get bookLabel => 'Kötet';

  @override
  String get ungroupedBookGroupLabel => '(nem besorolt)';

  @override
  String diaBookLabel(Object name) {
    return 'DIA: $name';
  }

  @override
  String zsolozsmaBookLabel(Object name) {
    return 'Zsolozsma: $name';
  }

  @override
  String get songLabel => 'Ének';

  @override
  String get verseLabel => 'Versszak';

  @override
  String versePanelTitle(Object title, Object verse) {
    return '$title: $verse';
  }

  @override
  String get searchLabel => 'Diakereső';

  @override
  String get searchHint => 'Kötet, énekcím vagy dal szövege';

  @override
  String get searchHintOrderEdit => 'Ének száma';

  @override
  String get noResults => 'Nincs találat.';

  @override
  String customOrderStatus(Object state) {
    return 'Saját sorrend: $state';
  }

  @override
  String get stateActive => 'Aktív';

  @override
  String get stateInactive => 'Inaktív';

  @override
  String get nextShort => 'Kov.';

  @override
  String get previewTitle => 'Dia előnézet';

  @override
  String get previewResizeInProgress => 'Előnézet átméretezése...';

  @override
  String customTextEntryLabel(Object name) {
    return 'Dia: $name';
  }

  @override
  String customImageEntryLabel(Object name) {
    return 'Kép: $name';
  }

  @override
  String get projectedImage => 'Vetített kép:';

  @override
  String get settingsTitle => 'Diatár beállítások';

  @override
  String get settingsTitleReceiver => 'Beállítások';

  @override
  String settingsVersionLabel(Object version, Object buildNumber) {
    return 'Verzió $version ($buildNumber)';
  }

  @override
  String get modeIp => 'IP';

  @override
  String get modeInternet => 'Internet';

  @override
  String get senderLabel => 'Küldő';

  @override
  String get senderHelper => 'MQTT sender neve';

  @override
  String get senderRefreshTooltip => 'Küldő lista frissítés';

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
  String get tcpPortRange => 'TCP port (0..65535)';

  @override
  String get mqttUserHint => 'MQTT user (üres = TCP mód)';

  @override
  String get mqttPassword => 'MQTT jelszó';

  @override
  String get mqttChannel => 'MQTT csatorna';

  @override
  String get internetRelayQrButton => 'QR-kód';

  @override
  String get internetRelayQrTitle => 'DiaVetítő QR-kód';

  @override
  String get internetRelayQrHint =>
      'Olvasd be a QR-kódot a webes DiaVetítő gyors megnyitásához.';

  @override
  String get internetRelayLinkLabel => 'Megnyitási link';

  @override
  String get internetRelayCopyLink => 'Link másolása';

  @override
  String get internetRelayLinkCopied => 'A link a vágólapra került';

  @override
  String get internetRelaySaveQrImage => 'QR mentése PNG-ként';

  @override
  String internetRelayQrSaved(Object fileName) {
    return 'QR kép mentve: $fileName';
  }

  @override
  String internetRelayQrSaveFailed(Object error) {
    return 'A QR kép mentése sikertelen: $error';
  }

  @override
  String get uiTheme => 'Felhasználói felület témája';

  @override
  String get themeDark => 'Sötét';

  @override
  String get themeLight => 'Világos';

  @override
  String get blankImagePath => 'Háttérkép útvonal';

  @override
  String get diaExportFolderPath => 'DIA mentési mappa';

  @override
  String get fileChoose => 'Fájl választása';

  @override
  String get blankImageDelete => 'Háttérkép törlése';

  @override
  String get openDtxFolder => 'Diatár állományok megnyitása';

  @override
  String get openDtxFolderTooltip =>
      'A Diatár állományait tartalmazó mappa megnyitása';

  @override
  String get copyPathTooltip => 'Eredeti útvonal másolása';

  @override
  String get pathCopied => 'Az eredeti útvonal a vágólapra került';

  @override
  String get pathLabelInternalStorage => 'Belső tárhely';

  @override
  String get pathSegmentDocuments => 'Dokumentumok';

  @override
  String get pathSegmentDownloads => 'Letöltések';

  @override
  String get pathSegmentCamera => 'Kamera';

  @override
  String get pathSegmentPictures => 'Képek';

  @override
  String get pathSegmentMusic => 'Zene';

  @override
  String get pathSegmentMovies => 'Videók';

  @override
  String get uiLanguage => 'Felhasználói felület nyelve';

  @override
  String get languageSystem => 'Rendszer alapértelmezett';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get languageEnglish => 'Angol';

  @override
  String get projectionSettingsTitle => 'Vetítési beállítások';

  @override
  String get fontSize => 'Betűméret';

  @override
  String get titleSize => 'Cím méret';

  @override
  String get leftMargin => 'Bal behúzás';

  @override
  String get borderLeft => 'Border L';

  @override
  String get borderTop => 'Border T';

  @override
  String get borderRight => 'Border R';

  @override
  String get borderBottom => 'Border B';

  @override
  String get lineSpacing => 'Sorköz';

  @override
  String get kottaScale => 'Kotta méret arány';

  @override
  String get chordScale => 'Akkord méret arány';

  @override
  String get backgroundMode => 'Háttér kép mód';

  @override
  String get bgModeCenter => 'Középre';

  @override
  String get bgModeZoom => 'Arányosan';

  @override
  String get bgModeFull => 'Kitöltve';

  @override
  String get bgModeCascade => 'Csempézve';

  @override
  String get bgModeMirror => 'Tükrözve';

  @override
  String get backgroundOpacity => 'Háttér átlátszóság';

  @override
  String get blankOpacity => 'Háttérkép átlátszóság';

  @override
  String get autoSize => 'Automatikus méretezés';

  @override
  String get showTitle => 'Cím mutatása';

  @override
  String get projectionLock => 'Vetítés zárolása';

  @override
  String get projectionUnlock => 'Vetítés feloldása';

  @override
  String get hCenter => 'Vízszintes középre igazítás';

  @override
  String get vCenter => 'Függőleges középre igazítás';

  @override
  String get showChords => 'Akkordok mutatása';

  @override
  String get showKotta => 'Kotta mutatása';

  @override
  String get showBackgroundImage => 'Háttérkép mutatása';

  @override
  String get wordHighlight => 'Szókiemelés';

  @override
  String get boldText => 'Félkövér szöveg';

  @override
  String get italicText => 'Dőlt szöveg';

  @override
  String get underlineText => 'Aláhúzott szöveg';

  @override
  String get strikethroughText => 'Áthúzott szöveg';

  @override
  String get insertSpecialCharacter => 'Speciális karakter beszúrása';

  @override
  String get conditionalHyphen => 'Feltételes kötőjel';

  @override
  String get nonBreakingSpace => 'Nemtörhető szóköz';

  @override
  String get nonBreakingHyphen => 'Nemtörhető kötőjel';

  @override
  String get preferredLineBreak => 'Sortörési javaslat';

  @override
  String get colorsTitle => 'Színek';

  @override
  String get backgroundColor => 'Háttér';

  @override
  String get textColor => 'Szöveg';

  @override
  String get emptySlideColor => 'Üres dia';

  @override
  String get highlightColor => 'Kiemelés';

  @override
  String get backgroundColorTitle => 'Háttér színe';

  @override
  String get textColorTitle => 'Szöveg színe';

  @override
  String get emptySlideColorTitle => 'Üres dia színe';

  @override
  String get highlightColorTitle => 'Kiemelés színe';

  @override
  String get cancel => 'Mégse';

  @override
  String get delete => 'Törlés';

  @override
  String get deleteFilesTooltip => 'Fájl törlése';

  @override
  String confirmDeleteDtxFiles(Object name) {
    return 'Törlöd a(z) „$name” énektár-fájlt a készülékről? Ez a művelet nem vonható vissza.';
  }

  @override
  String confirmDeleteDtzFiles(Object name) {
    return 'Törlöd a(z) „$name” vetítő-fájlt a készülékről? Ez a művelet nem vonható vissza.';
  }

  @override
  String get save => 'Ment';

  @override
  String get invalidPortRange => 'A port 0..65535 között legyen.';

  @override
  String get hexColorHint => 'Hex szín (#AARRGGBB vagy #RRGGBB)';

  @override
  String get close => 'Bezárás';

  @override
  String get imagesFileTypeLabel => 'képek';

  @override
  String get diatarPlaylistFileTypeLabel => 'Diatár playlist';

  @override
  String get customOrderSuggestedFileName => 'sorrend.dia';

  @override
  String get customOrderEditTitle => 'Szerkesztő';

  @override
  String customOrderEditTitleWithName(Object name) {
    return '$name - Szerkesztő';
  }

  @override
  String customOrderModifiedName(Object name) {
    return '✦ $name';
  }

  @override
  String get customOrderGroupReorder => 'Csoportos áthelyezés';

  @override
  String get customOrderPlaySoundTooltip => 'A dia zenéjének lejátszása';

  @override
  String get customOrderAdvanceAfterSoundTooltip => 'Továbblépés a zene végén';

  @override
  String get customOrderSkipSlideTooltip => 'Dia kihagyása vetítéskor';

  @override
  String get addSong => 'Ének hozzáadása';

  @override
  String get searchSongHint => 'Kötet, énekcím vagy dal szövege';

  @override
  String get customOrderInsertBookLabel => 'Kötet';

  @override
  String get customOrderInsertSongLabel => 'Ének';

  @override
  String get customOrderInsertVersesAction => 'Versszakok beszúrása';

  @override
  String get customOrderInsertSeparatorAction => 'Elválasztó beszúrása';

  @override
  String get customOrderClearAllTooltip => 'Mindent töröl';

  @override
  String get customOrderClearAllConfirmTitle => 'Megerősítés';

  @override
  String get customOrderClearAllConfirmMessage =>
      'Biztosan törölni szeretnéd az egész saját diasort?';

  @override
  String get customOrderClearAllConfirmButton => 'Mindent töröl';

  @override
  String get customOrderSeparatorNameLabel => 'Elválasztó neve';

  @override
  String get customOrderSeparatorDefaultName => 'elválasztó';

  @override
  String get customOrderEditSeparatorTitle => 'Elválasztó szerkesztése';

  @override
  String get customOrderEditTextSlideTitle => 'Szöveges dia szerkesztése';

  @override
  String get customOrderInsertVersesTitle => 'Beszúrandó versszakok';

  @override
  String get customOrderInsertVersesSubtitle =>
      'Jelöld ki, mely versszakok kerüljenek a diasorba.';

  @override
  String get textSlideDialogTitle => 'Szöveges dia hozzáadása';

  @override
  String get textSlideTitleLabel => 'Cím';

  @override
  String get textSlideBodyLabel => 'Szöveg (soronként)';

  @override
  String get textSlideDefaultTitle => 'Dia';

  @override
  String get loadDia => 'Betöltés';

  @override
  String get saveDia => 'Mentés';

  @override
  String get customOrderSaveDiaErrorTitle => 'Mentés sikertelen';

  @override
  String get customOrderSaveDiaPermissionDenied =>
      'A DIA fájl mentése közben az Android nem tudta írni a kiválasztott célhelyet. Próbáld újra, és a rendszer mentési ablakában válassz másik mappát vagy fájlnevet.';

  @override
  String customOrderSaveDiaGenericError(Object error) {
    return 'A DIA fájl mentése nem sikerült. Részletek: $error';
  }

  @override
  String get customOrderOverwriteSavedDiaTitle => 'Felülírás?';

  @override
  String customOrderOverwriteSavedDiaBody(Object fileName) {
    return 'Már van elmentve egy DIA fájl: $fileName. Mit szeretnél?';
  }

  @override
  String get customOrderOverwriteSavedDiaOverwrite => 'Felülírás';

  @override
  String get customOrderOverwriteSavedDiaNewLocation => 'Új hely választása';

  @override
  String get customOrderDiaFileNameLabel => 'Fájlnév';

  @override
  String get customOrderUnnamedFileName => 'Névtelen';

  @override
  String get customOrderDiaOverwriteTitle => 'Fájl felülírása';

  @override
  String customOrderDiaOverwriteMessage(Object name) {
    return 'A(z) „$name” fájl már létezik. Felülírja?';
  }

  @override
  String savedPath(Object path) {
    return 'Mentve: $path';
  }

  @override
  String loadedCount(int count) {
    return 'Betöltve: $count elem';
  }

  @override
  String get customOrderEmpty =>
      'A sorrend üres.\nKeress énekeket a szerkesztéshez.';

  @override
  String get versePicker => 'Versszak';

  @override
  String get selectedVersesTitle => 'Kiválasztott versszakok';

  @override
  String get selectedVersesSubtitle => 'Többet is kijelölhetsz.';

  @override
  String get customOrderSelectAllVerses => 'Összes';

  @override
  String get customOrderClearVerseSelection => 'Egyik sem';

  @override
  String get customOrderSetsSection => 'Diasorok';

  @override
  String get customOrderSetSelectorLabel => 'Aktív diasor';

  @override
  String get customOrderSetActive => 'Aktív';

  @override
  String get customOrderSetEmpty => 'Üres diasor';

  @override
  String customOrderSetEntryCount(int count) {
    return '$count tétel';
  }

  @override
  String get customOrderSetRename => 'Átnevezés';

  @override
  String get customOrderSetRemove => 'Eltávolítás';

  @override
  String get customOrderSetRenameTitle => 'Diasor átnevezése';

  @override
  String get customOrderSetRemoveConfirm =>
      'Biztosan eltávolítod ezt a diasort?';

  @override
  String customOrderSetRemoveHotkeyWarning(Object hotkey) {
    return 'Ez a diasor gyorsbillentyűhöz van rendelve ($hotkey). Előbb távolítsd el a gyorsbillentyűt a Beállításokban.';
  }

  @override
  String get customOrderSetToggleEnabledTooltip =>
      'Diasor be- és kikapcsolása (a kikapcsolt nem jelenik meg a nézetekben)';

  @override
  String get customOrderSetCreate => 'Új diasor';

  @override
  String get customOrderSetCreateTitle => 'Új diasor létrehozása';

  @override
  String get customOrderSetCreateNameLabel => 'Diasor neve';

  @override
  String get customOrderLoadModeTitle => 'Diasor betöltése';

  @override
  String get customOrderLoadModeOverwrite => 'Felülírja az aktuálist';

  @override
  String get customOrderLoadModeAdd => 'Mellé tölti (párhuzamos)';

  @override
  String get customOrderLoadModeMessage =>
      'Hogyan töltsük be a kiválasztott diasort?';

  @override
  String get volumeListTitle => 'Kötetlista';

  @override
  String get apply => 'Alkalmaz';

  @override
  String get internetUserActionsTitle => 'Felhasználói műveletek (API)';

  @override
  String get internetStatusOn => 'Be';

  @override
  String get internetStatusOff => 'Ki';

  @override
  String get internetStatusConnecting => 'Kapcsolódás';

  @override
  String get internetStatusError => 'Hiba';

  @override
  String connectionStatusTooltip(Object name, Object status) {
    return '$name: $status';
  }

  @override
  String get valueNotSet => '-';

  @override
  String get tcpNoTargets => 'Nincs célpont';

  @override
  String tcpTargetsCount(int count) {
    return '$count célpont';
  }

  @override
  String get settingsSearchLabel => 'Keresés a beállításokban';

  @override
  String get settingsInternetTitle => 'Internet';

  @override
  String settingsInternetSubtitle(Object status, Object user) {
    return 'Internetes közvetítés: $status, felhasználó: $user';
  }

  @override
  String get settingsLocalNetworkTitle => 'Helyi hálózat (TCP/IP)';

  @override
  String settingsLocalNetworkSubtitle(Object status, Object summary) {
    return 'TCP kliens: $status, célpontok: $summary';
  }

  @override
  String get settingsWolTitle => 'Wake on LAN';

  @override
  String settingsWolSubtitle(Object status, Object summary) {
    return 'Wake on LAN: $status, célpontok: $summary';
  }

  @override
  String get settingsWolDescription =>
      'Célgépek felébresztése a helyi hálózaton egy UDP-n keresztül küldött varázscsomaggal (magic packet).';

  @override
  String get wolEnabledTitle => 'Wake on LAN bekapcsolása';

  @override
  String get wolEnabledHint =>
      'Ha be van kapcsolva, az eszköztár gombjával minden célgépet felébreszthetsz.';

  @override
  String get wolTargetsLabel => 'Célgépek (MAC@IP[:port])';

  @override
  String get wolTargetsHint => 'AA:BB:CC:DD:EE:FF, soronként egy';

  @override
  String get wolTargetsHelp =>
      'A puszta MAC-cím a lentebb beállított broadcast címre küldi az ébresztőt. A MAC után @IP vagy @IP:port hozzáadásával egy adott gépet közvetlenül ébreszthetsz.';

  @override
  String get wolBroadcastLabel => 'Broadcast cím';

  @override
  String get wolPortLabel => 'UDP port';

  @override
  String get wolNoTargets => 'Adj meg legalább egy célgépet.';

  @override
  String wolInvalidTarget(Object target) {
    return 'Érvénytelen célpont: $target';
  }

  @override
  String get wolInvalidBroadcast =>
      'Érvénytelen broadcast cím. IPv4-címet adj meg, például 255.255.255.255.';

  @override
  String get wolInvalidPort =>
      'Érvénytelen port. 1 és 65535 között használható érték.';

  @override
  String get wolTooltip => 'Wake on LAN';

  @override
  String wolMessageSent(int count) {
    return 'Wake on LAN elküldve $count gépnek.';
  }

  @override
  String wolMessageError(Object error) {
    return 'Wake on LAN hiba: $error';
  }

  @override
  String settingsColorSummary(Object background, Object text) {
    return 'Háttér: $background, Szöveg: $text';
  }

  @override
  String settingsProjectionSummary(Object font, Object title) {
    return 'Betű: ${font}px, Cím: ${title}px';
  }

  @override
  String get settingsFilesTitle => 'Énektárak és fájlok';

  @override
  String settingsFilesSummary(Object blank) {
    return 'Háttérkép: $blank';
  }

  @override
  String get importDtxFilesButton => 'Importálás fájlból';

  @override
  String get importDtzFilesButton => 'Kotta importálás';

  @override
  String get importMusicFilesButton => 'Zene importálás';

  @override
  String get importMusicNotImplemented =>
      'A zeneimport még nincs implementálva.';

  @override
  String get importDtzPreviewTitle => 'Kotta importálás';

  @override
  String get importDtzDtzSection => 'DTZ fájl';

  @override
  String get importDtzZipSection => 'ZIP fájlok (képek, hangok)';

  @override
  String get importDtzNoDtzSelected => 'Nincs DTZ fájl kiválasztva';

  @override
  String get importDtzSelectDtz => 'DTZ kiválasztása';

  @override
  String get importDtzAddZip => 'ZIP hozzáadása';

  @override
  String get importDtzValidateButton => 'Ellenőrzés';

  @override
  String get importDtzPreviewNoDtz =>
      'Nem adtál meg .dtz fájlt. Válassz legalább egy DTZ fájlt!';

  @override
  String importDtzPreviewOrphanZips(int count) {
    return '$count ZIP fájl nem párosítható DTZ fájlhoz.';
  }

  @override
  String importDtzStatusOk(int matched) {
    return 'Importálható – $matched médiafájl rendben';
  }

  @override
  String get importDtzStatusNoRefs =>
      'Importálható – nincs hivatkozott médiafájl';

  @override
  String importDtzStatusWarning(int missing, int total) {
    return 'Importálható (figyelmeztetéssel) – $missing/$total médiafájl hiányzik';
  }

  @override
  String importDtzStatusError(int missing, int total) {
    return 'Nem importálható – $missing/$total médiafájl hiányzik';
  }

  @override
  String get importDtzStatusParseError =>
      'Nem importálható – érvénytelen DTZ fájl';

  @override
  String importDtzStatusMissingDiaIdsCount(int count) {
    return 'Ismeretlen dia-ID a DTZ-ben: $count db';
  }

  @override
  String get importDtzDetails => 'Részletek';

  @override
  String get importDtzMissingFilesTitle => 'Hiányzó médiafájlok';

  @override
  String get importDtzMissingDiaIdsTitle => 'Ismeretlen dia-ID-k';

  @override
  String get importDtzConfirmErrorsTitle => 'Hibás csomag importálása';

  @override
  String importDtzConfirmErrorsBody(int count) {
    return 'A kijelölt $count csomag hibás (hiányzó médiafájl vagy ismeretlen dia-ID). A hiányzó fájlok nem kerülnek kibontásra. Mégis importálod?';
  }

  @override
  String get importDtzImportButton => 'Importálás';

  @override
  String importDtzSuccess(int dtz, int files) {
    return '$dtz DTZ fájl importálva, $files médiafájl kibontva';
  }

  @override
  String importDtzSuccessNoMedia(int dtz) {
    return '$dtz DTZ fájl importálva';
  }

  @override
  String importDtzError(Object reason) {
    return 'Hiba a kotta importálás során: $reason';
  }

  @override
  String get importDtzFailureDialogTitle => 'Kottaimportálási hiba';

  @override
  String get importDtzPartialImportTitle =>
      'A kottaimportálás hibákkal fejeződött be';

  @override
  String get importDtzFailureSourceUnreadable =>
      'A kiválasztott ZIP fájl nem olvasható.';

  @override
  String get importDtzFailureInvalidArchive =>
      'A kiválasztott fájl nem érvényes ZIP archívum.';

  @override
  String get importDtzFailureTooManyEntries => 'A ZIP túl sok fájlt tartalmaz.';

  @override
  String get importDtzFailureEntryTooLarge =>
      'A ZIP egy biztonságosan importálhatónál nagyobb fájlt tartalmaz.';

  @override
  String get importDtzFailureTotalTooLarge =>
      'A ZIP túl sok adatot bontana ki a biztonságos importáláshoz.';

  @override
  String get importDtzFailureCancelled => 'Az importálást megszakítottad.';

  @override
  String get importDtzFailureEntryUnreadable =>
      'A ZIP egyik fájlja nem bontható ki.';

  @override
  String get importDtzFailureWriteFailed =>
      'A kibontott fájl nem írható. Ellenőrizd a szabad tárhelyet.';

  @override
  String importDtzFailureDetails(Object zip, Object reason) {
    return '$zip: $reason';
  }

  @override
  String importDtzProgress(Object entry, int current, int total) {
    return 'Kibontás: $entry ($current/$total)';
  }

  @override
  String importDtxFilesSuccess(int count) {
    return '$count .dtx fájl beimportálva';
  }

  @override
  String get importDtxFilesError => 'Hiba a .dtx importálás során';

  @override
  String importDtxFilesErrorDetailed(Object reason) {
    return 'Hiba a .dtx importálás során: $reason';
  }

  @override
  String importDtxFilesPartial(int count, int failed, Object reason) {
    return '$count .dtx fájl beimportálva, $failed sikertelen: $reason';
  }

  @override
  String get settingsGeneralTitle => 'Általános';

  @override
  String settingsGeneralSummary(Object theme, Object language) {
    return 'Téma: $theme, Nyelv: $language';
  }

  @override
  String get systemActionsTitle => 'Rendszer műveletek';

  @override
  String get systemActionsSummary =>
      'Kilépés, frissítés, távoli program leállítása, távoli gép leállítása';

  @override
  String get systemActionsBack => 'Vissza';

  @override
  String get externalCommandsTitle => 'Külső parancsok';

  @override
  String get externalCommandsSummary =>
      'Külső műveletek indítása program- és vetítési eseményekkor';

  @override
  String get externalCommandsDescriptionDesktop =>
      'A program vagy a vetítés állapotának változásakor Windows és Linux rendszeren futó shell parancsok beállítása.';

  @override
  String get externalCommandsDescriptionAndroid =>
      'A program vagy a vetítés állapotának változásakor indított URI, deep link, Android intent vagy broadcast beállítása.';

  @override
  String get externalCommandsDescriptionIos =>
      'A program vagy a vetítés állapotának változásakor megnyíló URL vagy deep link beállítása.';

  @override
  String get externalCommandsHintDesktop =>
      'Az üresen hagyott eseményhez nem fut parancs. A parancsokat az operációs rendszer parancsértelmezője indítja.';

  @override
  String get externalCommandsHintAndroid =>
      'Az üresen hagyott eseményhez nem fut parancs. URI vagy deep link, Android Intent URI, illetve broadcast küldéséhez \"broadcast:\" előtaggal ellátott Intent URI adható meg. Az Intent URI extrákat is kezel, például: intent:#Intent;action=com.example.ACTION;S.name=value;i.count=1;end';

  @override
  String get externalCommandsHintIos =>
      'Az üresen hagyott eseményhez nem fut parancs. Telepített alkalmazás által kezelt URL vagy deep link adható meg, például: mycontroller://projection?state=on. A paraméterek az URL lekérdezési részében adhatók át.';

  @override
  String get externalCommandOnStart => 'A program indulásakor';

  @override
  String get externalCommandOnExit => 'A program kilépésekor';

  @override
  String get externalCommandOnProjectionOn => 'A vetítés bekapcsolásakor';

  @override
  String get externalCommandOnProjectionOff => 'A vetítés kikapcsolásakor';

  @override
  String get externalCommandClear => 'Parancs törlése';

  @override
  String get externalCommandTest => 'Teszt';

  @override
  String get externalCommandTestStarted => 'A parancs elindult.';

  @override
  String get externalCommandTestSucceededTitle => 'Teszt sikeres';

  @override
  String get externalCommandTestFailedTitle => 'Teszt sikertelen';

  @override
  String externalCommandTestFailed(Object error) {
    return 'A parancs indítása sikertelen: $error';
  }

  @override
  String externalCommandTestExitCode(int code) {
    return 'A parancs $code hibakóddal fejeződött be.';
  }

  @override
  String get localExit => 'Kilépés';

  @override
  String get remoteProgramStop => 'Távoli program leállítása';

  @override
  String get remoteMachineStop => 'Távoli gép leállítása';

  @override
  String get settingsHotkeysTitle => 'Gyorsbillentyűk';

  @override
  String get settingsHotkeysSummary =>
      'Vezérlő műveletek és ének-hozzárendelés billentyűhöz';

  @override
  String get settingsDesktopHotkeysTitle => 'Gyorsbillentyűk (asztali)';

  @override
  String get settingsHotkeysActionsSectionTitle => 'Vezérlő műveletek';

  @override
  String get settingsHotkeysSongsSectionTitle => 'Ének gyorsbillentyűhöz';

  @override
  String get settingsHotkeysNoSongs =>
      'Nincs betöltött ének, ezért nem lehet hozzárendelni.';

  @override
  String get settingsHotkeyActionHint => 'pl. Ctrl+Right vagy F8';

  @override
  String get settingsHotkeyFieldLabel => 'Gyorsbillentyű';

  @override
  String get settingsHotkeySongHint => 'pl. Ctrl+1 vagy F2';

  @override
  String get settingsHotkeyAssign => 'Hozzárendelés';

  @override
  String get settingsHotkeyDelete => 'Törlés';

  @override
  String get settingsHotkeyActionPrevSong => 'Előző ének';

  @override
  String get settingsHotkeyActionPrevVerse => 'Előző versszak';

  @override
  String get settingsHotkeyActionToggleProjection => 'Vetítés ki/be';

  @override
  String get settingsHotkeyActionNextVerse => 'Következő versszak';

  @override
  String get settingsHotkeyActionNextSong => 'Következő ének';

  @override
  String get settingsHotkeyActionPrevOrderSet => 'Előző diasor';

  @override
  String get settingsHotkeyActionNextOrderSet => 'Következő diasor';

  @override
  String get settingsHotkeyActionHighlightPrev => 'Kiemelés előző szó';

  @override
  String get settingsHotkeyActionHighlightNext => 'Kiemelés következő szó';

  @override
  String get settingsHotkeyActionTogglePhoto => 'Fénykép ki/be';

  @override
  String get settingsHotkeyActionToggleChords => 'Akkordok ki/be';

  @override
  String get settingsHotkeyActionToggleBackground => 'Háttér ki/be';

  @override
  String get settingsHotkeyActionToggleSheetMusic => 'Kotta ki/be';

  @override
  String get settingsHotkeyActionHomeBooks => 'Kötetek megjelenítése';

  @override
  String get settingsHotkeyActionHomeDialist => 'Diasor megjelenítése';

  @override
  String get settingsHotkeyActionHomePresentation => 'Vetítés megjelenítése';

  @override
  String get settingsDesktopOrderSetHotkeysTitle => 'Diasor gyorsbillentyűk';

  @override
  String get settingsOrderSetLabel => 'Diasor';

  @override
  String get settingsHotkeysNoOrderSets =>
      'Nincs betöltött diasor, így nincs mit hozzárendelni.';

  @override
  String get settingsHotkeysOrderSetExistingTitle => 'Meglévő hozzárendelések';

  @override
  String get settingsOrderSetPickerTitle => 'Diasor kiválasztása';

  @override
  String settingsHotkeyConflict(Object hotkey) {
    return 'Ütköző gyorsbillentyű: $hotkey';
  }

  @override
  String get settingsNoResults => 'Nincs találat a keresésre.';

  @override
  String get internetRelaySwitchTitle => 'Internetes közvetítés';

  @override
  String get localNetworkRelaySwitchTitle => 'Helyi hálózat (TCP/IP)';

  @override
  String get passwordHideTooltip => 'Elrejtés';

  @override
  String get passwordShowTooltip => 'Megjelenítés';

  @override
  String get tcpTargetsLabel => 'Célpontok (IP:port soronként)';

  @override
  String get tcpTargetsHint => '192.168.1.50:1024\n192.168.1.51:1024';

  @override
  String get tcpTargetsHelp =>
      'A sender kliensként csatlakozik a fenti címekhez.';

  @override
  String get projectionMarginsTitle => 'Margók';

  @override
  String get projectionMarginLeft => 'Bal margó';

  @override
  String get projectionMarginRight => 'Jobb margó';

  @override
  String get projectionMarginTop => 'Felső margó';

  @override
  String get projectionMarginBottom => 'Alsó margó';

  @override
  String get projectorMonitor => 'Vetítő kijelzője';

  @override
  String get projectorEnabled => 'Vetítőablak használata';

  @override
  String get projectorEnabledHint =>
      'Külön ablakban vetít asztali környezeten. Kikapcsolva a program csak vezérlőként működik vetítőablak nélkül.';

  @override
  String get cameraViewTitle => 'Kántorszem – Kamerakép mutatása';

  @override
  String get cameraViewHint =>
      'A vetítő eszköz kameraképét mutatja a helyi hálózaton keresztül.';

  @override
  String get cameraSourceLabel => 'Kamera forrása';

  @override
  String get cameraSourceHelp =>
      'Válaszd ki, melyik kliens kameraképét várja a nézet. Ha egyetlen célpont van megadva, az automatikusan használódik.';

  @override
  String get projectorMonitorAuto => 'Automatikus (utolsó kijelző)';

  @override
  String projectorMonitorIndex(int index, Object size) {
    return '$index. kijelző ($size)';
  }

  @override
  String projectorMonitorIndexShort(int index) {
    return '$index. kijelző';
  }

  @override
  String tcpInvalidTargetFormat(Object target) {
    return 'Hibás célpont formátum: $target';
  }

  @override
  String get userActionRegister => 'Regisztráció';

  @override
  String get userActionResendVerification => 'E-mail újraküldés';

  @override
  String get userActionForgotPassword => 'Elfelejtett jelszó';

  @override
  String get userActionDeleteUser => 'Felhasználó törlése';

  @override
  String get userActionChangePassword => 'Jelszóváltoztatás';

  @override
  String get userActionChangeEmail => 'E-mail-változtatás';

  @override
  String get userActionChangeUsername => 'Felhasználónév-változtatás';

  @override
  String get userFieldUsername => 'Felhasználónév';

  @override
  String get userFieldPassword => 'Jelszó';

  @override
  String get userFieldEmail => 'E-mail';

  @override
  String get userFieldCurrentPassword => 'Jelenlegi jelszó';

  @override
  String get userFieldNewPassword => 'Új jelszó';

  @override
  String get userFieldNewEmail => 'Új e-mail';

  @override
  String get userFieldCurrentUsername => 'Jelenlegi felhasználónév';

  @override
  String get userFieldNewUsername => 'Új felhasználónév';

  @override
  String get userActionRegisterSuccess =>
      'Sikeres adatfelvétel. A regisztráció véglegesítéséhez nézze meg az e-mail-fiókját.';

  @override
  String get userActionResendVerificationSuccess =>
      'Megerősítő e-mail újraküldve. Kérjük, ellenőrizze az e-mailjeit.';

  @override
  String get userActionForgotPasswordSuccess =>
      'Ha a fiók létezik, jelszó-visszaállító e-mailt küldtünk.';

  @override
  String get userActionValidationRequiredFields =>
      'A felhasználónév és az e-mail megadása kötelező.';

  @override
  String get userActionValidationRequiredPasswordFields =>
      'A felhasználónév, a jelenlegi jelszó és az új jelszó megadása kötelező.';

  @override
  String get userActionValidationRequiredChangeEmailFields =>
      'A felhasználónév, a jelenlegi jelszó és az új e-mail megadása kötelező.';

  @override
  String get userActionValidationRequiredChangeUsernameFields =>
      'A jelenlegi felhasználónév, a jelszó és az új felhasználónév megadása kötelező.';

  @override
  String get userActionValidationInvalidEmail => 'Érvénytelen e-mail-cím.';

  @override
  String get userActionDeleteUserSuccess => 'Felhasználó törölve.';

  @override
  String get userActionChangePasswordSuccess => 'Jelszó sikeresen módosítva.';

  @override
  String get userActionChangeEmailSuccess =>
      'E-mail-cím módosítási kérés elküldve. A véglegesítéshez nézze meg az e-mail-fiókját.';

  @override
  String get userActionChangeUsernameSuccess => 'Felhasználónév módosítva.';

  @override
  String get userDeleteConfirmTitle => 'Megerősítés';

  @override
  String get userDeleteConfirmMessage =>
      'Biztosan törölni szeretnéd ezt a felhasználót? Ez a művelet nem visszavonható.';

  @override
  String get userDeleteConfirmButton => 'Törlés';

  @override
  String userApiError(Object error) {
    return 'API hiba: $error';
  }

  @override
  String get userApiUnauthorized =>
      'Sikertelen hitelesítés. Ellenőrizze a felhasználónevet és a jelszót.';

  @override
  String get userApiUnknownError => 'Váratlan API-hiba.';

  @override
  String get settingsHotkeyPressAnyKey =>
      'Nyomj meg bármelyik billentyű kombinációt...';

  @override
  String get settingsHotkeyDialogTitle => 'Gyorsbillentyű rögzítése';

  @override
  String get settingsHotkeyConfirm => 'Megerősítés';

  @override
  String get settingsHotkeyClearCapture => 'Törlés';

  @override
  String get settingsHotkeyClear => 'Törlés';

  @override
  String get settingsHotkeyCapture => 'Rögzítés';

  @override
  String get settingsSearchKeywordsSystem =>
      'rendszer kilepes leallas stop shutdown epstop epshutdown';

  @override
  String get controlPhotoView => 'Fénykép / vetítés váltása';

  @override
  String get controlPhotoViewPhoto => 'Fénykép nézet';

  @override
  String get controlPhotoViewPreview => 'Vetítés előnézet';

  @override
  String get useSound => 'Zene lejátszása';

  @override
  String get advanceAfterMusic => 'Továbbítás a zene végén';

  @override
  String get liveSubtitlesOn => 'Élő felirat bekapcsolása';

  @override
  String get liveSubtitlesOff => 'Élő felirat kikapcsolása';

  @override
  String get liveSubtitlesDownloadTitle => 'Beszédmodell letöltése';

  @override
  String get liveSubtitlesDownloadMessage =>
      'A beszédfelismeréshez szükséges modell. Letöltjük most?';

  @override
  String get liveSubtitlesDownloading =>
      'Beszédmodell letöltése folyamatban...';

  @override
  String get liveSubtitlesError => 'Beszédfelismerési hiba';

  @override
  String get vadDownloadTitle => 'Beszédaktivitás-modell letöltése';

  @override
  String get vadDownloadMessage =>
      'Az offline beszédfelismeréshez beszédaktivitás-észlelő (VAD) modell szükséges. Letöltjük most?';

  @override
  String get vadDownloading =>
      'Beszédaktivitás-modell letöltése folyamatban...';

  @override
  String get liveSubtitlesMicDevice => 'Mikrofon';

  @override
  String get liveSubtitlesMicDeviceDefault => 'Rendszer alapértelmezett';

  @override
  String get speechSettingsTitle => 'Beszédfelismerő';

  @override
  String get speechFeatureEnabled => 'Beszédfelismerő engedélyezése';

  @override
  String get speechSettingsSummary => 'Mikrofon';

  @override
  String get speechModelTitle => 'Beszédmodell';

  @override
  String get speechModelStreaming => 'Streaming (alacsony késleltetés)';

  @override
  String get speechModelOffline => 'Offline (magasabb pontosság)';

  @override
  String get transposeDown => 'Transzpozíció le';

  @override
  String get transposeUp => 'Transzpozíció fel';

  @override
  String get transposeReset => 'Transzpozíció alap';

  @override
  String get diatarDataTransferTitle => 'Biztonsági mentés';

  @override
  String get diatarDataTransferDescription =>
      'A teljes belső diatar mappa mentése ZIP fájlba, illetve visszaállítása ZIP fájlból.';

  @override
  String get diatarExportButton => 'Exportálás';

  @override
  String get diatarImportButton => 'Importálás';

  @override
  String get diatarZipFileTypeLabel => 'Diatár biztonsági mentés';

  @override
  String diatarExportSuccess(Object fileName) {
    return 'Az exportálás elkészült: $fileName';
  }

  @override
  String diatarImportSuccess(int imported) {
    return '$imported fájl visszaállítva.';
  }

  @override
  String get diatarImportConflictTitle => 'Már létező fájlok';

  @override
  String diatarImportConflictMessage(int count) {
    return '$count importálandó fájl már létezik. A teljes importálás során felülírjuk vagy mellőzzük ezeket?';
  }

  @override
  String get diatarImportOverwriteAll => 'Felülírás';

  @override
  String get diatarImportSkipAll => 'Mellőzés';

  @override
  String get diatarExportSourceMissing => 'A belső diatar mappa nem található.';

  @override
  String get diatarImportInvalidArchive =>
      'A kiválasztott fájl nem érvényes Diatár biztonsági mentés.';

  @override
  String diatarTransferArchive(Object fileName) {
    return 'ZIP fájl: $fileName';
  }

  @override
  String diatarTransferCurrentFile(Object fileName) {
    return 'Feldolgozás: $fileName';
  }

  @override
  String diatarTransferProgress(int percent) {
    return '$percent%';
  }

  @override
  String get diatarTransferCancelled => 'A műveletet megszakítottad.';

  @override
  String diatarTransferError(Object error) {
    return 'A művelet nem sikerült: $error';
  }

  @override
  String get szentirasTooltip => 'Szentírás';

  @override
  String get szentirasTitle => 'Szentírás beillesztése';

  @override
  String get szentirasReferenceLabel => 'Hivatkozás';

  @override
  String get szentirasReferenceHint => 'pl. 1Kor13,10-13';

  @override
  String get szentirasTranslationLabel => 'Fordítás';

  @override
  String get szentirasTranslationDefault => 'Alapértelmezett';

  @override
  String get szentirasFetchButton => 'Betöltés';

  @override
  String get szentirasImportButton => 'Beillesztés';

  @override
  String szentirasInsertAll(int count) {
    return 'Összes beszúrása ($count vers)';
  }

  @override
  String get szentirasLoading => 'Betöltés…';

  @override
  String szentirasError(Object error) {
    return 'Hiba: $error';
  }

  @override
  String get szentirasNoVerses => 'Nem található vers.';

  @override
  String get szentirasChunkSizeLabel => 'Dia szóhatár';

  @override
  String get szentirasChunkSizeHint => 'max. szavak diánként';

  @override
  String get settingsSzentirasApiKeyLabel => 'szentiras.eu API kulcs';

  @override
  String get settingsSzentirasApiKeyHint => 'Kulcs a szentiras.eu oldalról';

  @override
  String get szentirasApiKeyPrompt =>
      'Add meg a szentiras.eu API kulcsot a Szentírás funkció használatához.';

  @override
  String get statusSzentirasApiKeyMissing =>
      'Nincs beállítva a szentiras.eu API kulcs.';

  @override
  String get settingsApiKeysTitle => 'API kulcsok';

  @override
  String settingsApiKeysSubtitle(Object status) {
    return 'Szentírás: $status';
  }

  @override
  String get settingsApiKeysStatusSet => 'Beállítva';

  @override
  String get settingsApiKeysStatusMissing => 'Nincs beállítva';

  @override
  String get szentirasApiKeyHelp =>
      'Szerezd be a kulcsot:\nszentiras.eu → Belépés → Profil → API kulcsok';

  @override
  String get szentirasApiKeySave => 'Mentés';

  @override
  String get onboardingWelcomeTitle => 'Üdvözöl a Diatár!';

  @override
  String get onboardingWelcomeBody =>
      'Templomi énekkivetítő alkalmazás.\n\nVálassz énekeskönyvet, állíts össze énekrendet, majd küldd ki a kivetítőre.';

  @override
  String get onboardingPage2Title => 'Főképernyő';

  @override
  String get onboardingPage2Body =>
      'Három mód közül választhatsz:\n\n• Kötetek: énekeskönyv böngészése, ének és versszak kiválasztása\n• Diasor: diasor megtekintése a vetítés mellett\n• Vetítés: teljes képernyős előnézet';

  @override
  String get onboardingPage3Title => 'Énekrend készítése';

  @override
  String get onboardingPage3Body =>
      '1. Keresd ki az énekeket a Kötetek módban\n2. Nyisd meg a Diasor szerkesztőt\n3. Add hozzá a versszakokat, szöveges diákat, elválasztókat\n4. Mentsd el .dia fájlként későbbi használatra';

  @override
  String get onboardingPage4Title => 'Speciális funkciók';

  @override
  String get onboardingPage4Body =>
      '• Zsolozsma: napi zsolozsma betöltése\n• Napi lelki batyu: napi olvasmányok\n• Szentírás: bibliaversek beillesztése\n• Keresés: teljes szöveges keresés\n• Gyorsbillentyűk: asztali billentyűparancsok';

  @override
  String get onboardingGotIt => 'Értem, kezdjük!';

  @override
  String get onboardingSkip => 'Kihagyás';

  @override
  String get onboardingNext => 'Tovább';

  @override
  String get onboardingDone => 'Kész';

  @override
  String get settingsInternetDescription =>
      'Internetes közvetítés MQTT protokollal. Hozz létre felhasználót, majd oszd meg a QR-kódot a távoli DiaVetítővel.';

  @override
  String get settingsLocalNetworkDescription =>
      'TCP/IP kapcsolat helyi hálózaton. Add meg a vetítő IP-címét és portját.';

  @override
  String get colorsDescription =>
      'A vetített diák színeinek testreszabása: háttér, szöveg, üres dia és kiemelés.';

  @override
  String get projectionSettingsDescription =>
      'Betűméret, margók, háttérkép és egyéb vetítési paraméterek beállítása.';

  @override
  String get settingsFilesDescription =>
      'Énektárak importálása, DTZ kották, biztonsági mentés készítése és visszaállítása.';

  @override
  String get settingsGeneralDescription =>
      'Alkalmazás téma (sötét/világos) és nyelv beállítása.';

  @override
  String get systemActionsDescription =>
      'Kilépés, énektárak újratöltése, távoli vetítő leállítása.';

  @override
  String get settingsHotkeysDescription =>
      'Billentyűparancsok a gyors vezérléshez asztali környezetben.';

  @override
  String get settingsOnboardingButton => 'Kezdő lépések';

  @override
  String get impresszumTitle => 'Impresszum';

  @override
  String get impresszumSummary => 'Fejlesztők, licenszek és források';

  @override
  String get impresszumDescription =>
      'A Diatár fejlesztőinek és a felhasznált szoftvereknek a bemutatása.';

  @override
  String get impresszumDevelopers => 'Fejlesztők';

  @override
  String get impresszumDevelopersBody =>
      'A Diatár a Szent József Hackathon közösségének munkája.';

  @override
  String get impresszumHackathonTitle => 'Szent József Hackathon';

  @override
  String get impresszumHackathonBody =>
      'A Diatár a IV. Szent József Hackathon (2026, Szeged) keretében készült.';

  @override
  String get impresszumDataSources => 'Adatforrások';

  @override
  String get impresszumSzentiras => 'Szentírás.eu — a bibliai szövegek forrása';

  @override
  String get impresszumLicenses => 'Felhasznált szoftverek és licenek';

  @override
  String get impresszumNemotron =>
      'NVIDIA Nemotron 3.5 ASR — OpenMDW-1.1 licensz';

  @override
  String get impresszumSherpaOnnx =>
      'Sherpa-ONNX (k2-fsa) — Apache-2.0 licensz';

  @override
  String get impresszumFlutter => 'Flutter — BSD-3 licensz';

  @override
  String get impresszumRecord => 'Record (llfbandit) — MIT licensz';

  @override
  String get impresszumLinks => 'Linkek';

  @override
  String get impresszumWebsite => 'diatar.eu';

  @override
  String get impresszumGitHub => 'GitHub';

  @override
  String get impresszumHackathonLink => 'Szent József Hackathon';

  @override
  String get impresszumSzentirasLink => 'szentiras.eu';

  @override
  String get speechLanguageTitle => 'Beszédfelismerő nyelve';

  @override
  String get speechLangAuto => 'Automatikus (minden nyelv)';

  @override
  String get speechLangEsUS => 'Spanyol (es-US)';

  @override
  String get speechLangEsES => 'Spanyol (es-ES)';

  @override
  String get speechLangItIT => 'Olasz (it-IT)';

  @override
  String get speechLangPtBR => 'Portugál (pt-BR)';

  @override
  String get speechLangPtPT => 'Portugál (pt-PT)';

  @override
  String get speechLangHiIN => 'Hindi (hi-IN)';

  @override
  String get speechLangKoKR => 'Koreai (ko-KR)';

  @override
  String get speechLangEnUS => 'Angol (en-US)';

  @override
  String get speechLangEnGB => 'Angol (en-GB)';

  @override
  String get speechLangDeDE => 'Német (de-DE)';

  @override
  String get speechLangFrFR => 'Francia (fr-FR)';

  @override
  String get speechLangFrCA => 'Francia (fr-CA)';

  @override
  String get speechLangRuRU => 'Orosz (ru-RU)';

  @override
  String get speechLangTrTR => 'Török (tr-TR)';

  @override
  String get speechLangViVN => 'Vietnami (vi-VN)';

  @override
  String get speechLangNlNL => 'Holland (nl-NL)';

  @override
  String get speechLangJaJP => 'Japán (ja-JP)';

  @override
  String get speechLangArAR => 'Arab (ar-AR)';

  @override
  String get speechLangUkUA => 'Ukrán (uk-UA)';

  @override
  String get speechLangPlPL => 'Lengyel (pl-PL)';

  @override
  String get speechLangNbNO => 'Norvég bokmål (nb-NO)';

  @override
  String get speechLangFiFI => 'Finn (fi-FI)';

  @override
  String get speechLangZhCN => 'Mandarin (zh-CN)';

  @override
  String get speechLangCsCZ => 'Cseh (cs-CZ)';

  @override
  String get speechLangBgBG => 'Bolgár (bg-BG)';

  @override
  String get speechLangSkSK => 'Szlovák (sk-SK)';

  @override
  String get speechLangSvSE => 'Svéd (sv-SE)';

  @override
  String get speechLangHrHR => 'Horvát (hr-HR)';

  @override
  String get speechLangRoRO => 'Román (ro-RO)';

  @override
  String get speechLangEtEE => 'Észt (et-EE)';

  @override
  String get speechLangDaDK => 'Dán (da-DK)';

  @override
  String get speechLangHuHU => 'Magyar (hu-HU)';

  @override
  String get picPlcSettingsTitle => 'PICPLC vezérlő';

  @override
  String picPlcSettingsEnabledSummary(Object port) {
    return 'Engedélyezve, port: $port';
  }

  @override
  String get picPlcSettingsDisabledSummary => 'Kikapcsolva';

  @override
  String get picPlcSettingsDescription =>
      'A PICPLC soros vezérlő, a gombkiosztások és a LED-ek beállítása.';

  @override
  String get picPlcEnabledLabel => 'PICPLC vezérlő engedélyezése';

  @override
  String get picPlcPortLabel => 'Soros port';

  @override
  String get picPlcPortHint => 'pl. COM3 vagy /dev/ttyUSB0';

  @override
  String get picPlcPortRequired =>
      'A PICPLC vezérlő engedélyezéséhez add meg a soros portot.';

  @override
  String get picPlcButtonsTitle => 'Gombkiosztások';

  @override
  String picPlcButtonLabel(int number) {
    return '$number. gomb';
  }

  @override
  String get picPlcLedsTitle => 'LED-kiosztások';

  @override
  String picPlcLedLabel(int number) {
    return '$number. LED';
  }

  @override
  String get picPlcActionNone => 'Nincs funkciója';

  @override
  String get picPlcActionToggleProjection => 'Vetítés ki/be nyomógomb';

  @override
  String get picPlcActionProjectionSwitch => 'Vetítés ki/be kapcsoló';

  @override
  String get picPlcActionPreviousVerse => 'Előző dia';

  @override
  String get picPlcActionNextVerse => 'Következő dia';

  @override
  String get picPlcActionPreviousSong => 'Előző ének';

  @override
  String get picPlcActionNextSong => 'Következő ének';

  @override
  String get picPlcActionToggleDirection => 'Irányváltó nyomógomb';

  @override
  String get picPlcActionDirectionSwitch => 'Előre/hátra kapcsoló';

  @override
  String get picPlcActionStep => 'Dia léptető gomb';

  @override
  String get picPlcLedProjectionOn => 'Vetítés bekapcsolva';

  @override
  String get picPlcLedForward => 'Előre irány';

  @override
  String get picPlcLedBackward => 'Hátra irány';

  @override
  String get songOrder => 'Énekrend';

  @override
  String get customOrderEmbedImagesTitle => 'Képek beágyazása?';

  @override
  String get customOrderEmbedImagesMessage =>
      'A diasor képeket tartalmaz. Beágyazzuk őket a DIA fájlba, hogy az eredeti képfájlok nélkül is használható legyen?';

  @override
  String get customOrderEmbedImagesNo => 'Ne ágyazza be';

  @override
  String get customOrderEmbedImagesYes => 'Beágyazás';

  @override
  String customOrderEmbedImageMissing(Object path) {
    return 'A beágyazandó kép nem található: $path';
  }
}
