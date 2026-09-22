import 'package:diatar_app/src/services/settings_store.dart';
import 'package:diatar_app/src/services/pic_plc_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Map<String, String> defaultActionHotkeys = <String, String>{
    'prevVerse': 'ArrowUp',
    'nextVerse': 'ArrowDown',
    'prevSong': 'PageUp',
    'nextSong': 'PageDown',
    'toggleProjection': 'Escape',
    'highlightPrev': 'ArrowLeft',
    'highlightNext': 'ArrowRight',
  };

  test('loads default desktop action hotkeys for new installations', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final settings = await SettingsStore().load();

    expect(settings.desktopActionHotkeys, defaultActionHotkeys);
  });

  test('migrates legacy empty desktop action hotkeys to defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'DesktopActionHotkeys': <String>[],
    });

    final settings = await SettingsStore().load();
    final prefs = await SharedPreferences.getInstance();

    expect(settings.desktopActionHotkeys, defaultActionHotkeys);
    expect(
      prefs.getStringList('DesktopActionHotkeys'),
      containsAll(<String>[
        'prevSong\tPageUp',
        'prevVerse\tArrowUp',
        'toggleProjection\tEscape',
        'nextVerse\tArrowDown',
        'nextSong\tPageDown',
        'highlightPrev\tArrowLeft',
        'highlightNext\tArrowRight',
      ]),
    );
  });

  test('preserves intentionally cleared desktop action hotkeys', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'DesktopActionHotkeys': <String>[],
      'DesktopActionHotkeysInitialized': true,
    });

    final settings = await SettingsStore().load();

    expect(settings.desktopActionHotkeys, isEmpty);
  });

  test('defaults landscape controls ratio to null', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final settings = await SettingsStore().load();

    expect(settings.landscapeControlsRatio, isNull);
  });

  test('persists landscape controls ratio round-trip', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = SettingsStore();
    final loaded = await store.load();
    final updated = loaded.copyWith(landscapeControlsRatio: 0.42);
    await store.save(updated);

    final reloaded = await store.load();

    expect(reloaded.landscapeControlsRatio, 0.42);
  });

  test('defaults and persists the maximum slideshow count', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsStore store = SettingsStore();

    expect((await store.load()).maxCustomOrderSets, 10);
    await store.save((await store.load()).copyWith(maxCustomOrderSets: 17));

    expect((await store.load()).maxCustomOrderSets, 17);
  });

  test('clamps an invalid stored maximum slideshow count', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'MaxCustomOrderSets': 99,
    });

    expect((await SettingsStore().load()).maxCustomOrderSets, 20);
  });

  test('persists inverse notation colors round-trip', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsStore store = SettingsStore();

    await store.save((await store.load()).copyWith(projInverseKotta: true));

    expect((await store.load()).projInverseKotta, isTrue);
  });

  test('defaults and persists DIA automatic saving', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsStore store = SettingsStore();

    expect((await store.load()).diaAutoSaveEnabled, isFalse);
    await store.save((await store.load()).copyWith(diaAutoSaveEnabled: true));

    expect((await store.load()).diaAutoSaveEnabled, isTrue);
  });

  test('persists control photo view state round-trip', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsStore store = SettingsStore();

    expect(await store.loadShowPhotoInControl(), isFalse);
    await store.saveShowPhotoInControl(true);

    expect(await store.loadShowPhotoInControl(), isTrue);
  });

  test('persists all eight PICPLC button assignments', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const PicPlcConfiguration configuration = PicPlcConfiguration(
      enabled: true,
      port: 'COM3',
      buttonActions: <PicPlcButtonAction>[
        PicPlcButtonAction.toggleProjection,
        PicPlcButtonAction.projectionSwitch,
        PicPlcButtonAction.previousVerse,
        PicPlcButtonAction.nextVerse,
        PicPlcButtonAction.previousSong,
        PicPlcButtonAction.nextSong,
        PicPlcButtonAction.toggleDirection,
        PicPlcButtonAction.step,
      ],
      ledActions: <PicPlcLedAction>[
        PicPlcLedAction.projectionOn,
        PicPlcLedAction.backward,
      ],
    );

    final SettingsStore store = SettingsStore();
    await store.savePicPlcConfiguration(configuration);

    final PicPlcConfiguration loaded = await store.loadPicPlcConfiguration();
    expect(loaded.enabled, isTrue);
    expect(loaded.port, 'COM3');
    expect(loaded.buttonActions, configuration.buttonActions);
    expect(loaded.ledActions, configuration.ledActions);
  });
}
