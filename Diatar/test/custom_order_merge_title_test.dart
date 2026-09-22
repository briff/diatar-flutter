import 'dart:async';

import 'dart:io';

import 'package:diatar_common/diatar_common.dart';
import 'package:diatar_app/src/controllers/diatar_main_controller.dart';
import 'package:diatar_app/src/core/custom_order/custom_order_navigation_policy.dart';
import 'package:diatar_app/src/core/settings/transport_settings_policy.dart';
import 'package:diatar_app/src/services/dtx_order_store.dart';
import 'package:diatar_app/src/services/mqtt_sender_service.dart';
import 'package:diatar_app/src/services/sender_transport_coordinator.dart';
import 'package:diatar_app/src/services/tcp_sender_service.dart';
import 'package:diatar_app/src/ui/home_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (
        MethodCall methodCall,
      ) async {
        if (methodCall.method == 'create') {
          return <String, dynamic>{'playerId': 'mock-player'};
        }
        return null;
      });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getAll':
              return <String, dynamic>{};
            case 'setBool':
            case 'setDouble':
            case 'setInt':
            case 'setString':
            case 'setStringList':
            case 'remove':
              return true;
            default:
              return null;
          }
        },
      );

  group('merge title formatting', () {
    test('keeps shared book and song prefix once', () {
      final String merged = DiatarMainController.formatMergedProjectionLabel(
        'Kötet: ének/vers1',
        'Kötet: ének/vers2',
      );

      expect(merged, 'Kötet: ének/vers1, vers2');
    });

    group('song order summary', () {
      test('groups consecutive verses and omits skipped entries', () {
        const List<DtxBook> books = <DtxBook>[
          DtxBook(
            fileName: 'book.dtx',
            title: 'Teljes kötetnév',
            nick: 'Rövid',
            songs: <DtxSong>[
              DtxSong(
                title: '42',
                verses: <DtxVerse>[
                  DtxVerse(name: '1', lines: <String>[]),
                  DtxVerse(name: '2', lines: <String>[]),
                ],
              ),
            ],
          ),
        ];
        const List<CustomOrderEntry> entries = <CustomOrderEntry>[
          CustomOrderEntry(
            fileName: 'book.dtx',
            songIndex: 0,
            verseIndex: 0,
            label: '',
          ),
          CustomOrderEntry(
            fileName: 'book.dtx',
            songIndex: 0,
            verseIndex: 1,
            label: '',
          ),
          CustomOrderEntry(
            fileName: '__custom_image__',
            songIndex: -2,
            verseIndex: 0,
            label: '',
            customImagePath: r'C:\images\cover.png',
            customType: 'image',
          ),
          CustomOrderEntry(
            fileName: 'book.dtx',
            songIndex: 0,
            verseIndex: 0,
            label: '',
            skipped: true,
          ),
          CustomOrderEntry(
            fileName: 'book.dtx',
            songIndex: 0,
            verseIndex: 0,
            label: '',
          ),
        ];

        expect(
          DiatarMainController.buildSongOrderLines(
            entries: entries,
            books: books,
          ),
          <String>['Rövid: 42/1, 2', 'cover.png', 'Rövid: 42/1'],
        );
      });

      test('starts a new line after a separator', () {
        const List<DtxBook> books = <DtxBook>[
          DtxBook(
            fileName: 'book.dtx',
            title: 'Kötet',
            songs: <DtxSong>[
              DtxSong(
                title: 'Ének',
                verses: <DtxVerse>[DtxVerse(name: '1', lines: <String>[])],
              ),
            ],
          ),
        ];
        const CustomOrderEntry song = CustomOrderEntry(
          fileName: 'book.dtx',
          songIndex: 0,
          verseIndex: 0,
          label: '',
        );

        expect(
          DiatarMainController.buildSongOrderLines(
            entries: <CustomOrderEntry>[
              song,
              CustomOrderEntry(
                fileName: CustomOrderEntry.separatorFileName,
                songIndex: CustomOrderEntry.separatorSongIndex,
                verseIndex: 0,
                label: '',
              ),
              song,
            ],
            books: books,
          ),
          <String>['Kötet: Ének/1', 'Kötet: Ének/1'],
        );
      });
    });

    group('custom order skipped slides', () {
      const CustomOrderNavigationPolicy navigation =
          CustomOrderNavigationPolicy();

      test('does not return skipped slides while stepping', () {
        const List<CustomOrderEntry> entries = <CustomOrderEntry>[
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: 'Skipped',
            skipped: true,
          ),
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: 'Shown',
          ),
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: 'Skipped too',
            skipped: true,
          ),
        ];

        expect(navigation.findNextProjectableIndex(entries, 0), 1);
        expect(navigation.findPrevProjectableIndex(entries, 2), 1);
      });
    });

    test('keeps shared book prefix and separates differing song/verse', () {
      final String merged = DiatarMainController.formatMergedProjectionLabel(
        'Kötet: ének1/vers1',
        'Kötet: ének2/vers2',
      );

      expect(merged, 'Kötet: ének1/vers1, ének2/vers2');
    });

    test('falls back to comma-separated full labels when no shared prefix', () {
      final String merged = DiatarMainController.formatMergedProjectionLabel(
        'Kötet1: ének1/Vers1',
        'kötet2: ének2/vers2',
      );

      expect(merged, 'Kötet1: ének1/Vers1, kötet2: ének2/vers2');
    });

    test('normalizes slash spacing before merge formatting', () {
      final String merged = DiatarMainController.formatMergedProjectionLabel(
        'Kötet: ének / vers1',
        'Kötet: ének/vers2',
      );

      expect(merged, 'Kötet: ének/vers1, vers2');
    });
  });

  group('custom order naming', () {
    test('writes and reads unnamed separators', () async {
      final DiatarMainController controller = DiatarMainController();
      final Directory directory = await Directory.systemTemp.createTemp(
        'diatar_unnamed_separator_test_',
      );
      final String path = '${directory.path}${Platform.pathSeparator}order.dia';
      addTearDown(() => directory.delete(recursive: true));

      await controller.applyCustomOrder(const <CustomOrderEntry>[
        CustomOrderEntry(
          fileName: CustomOrderEntry.separatorFileName,
          songIndex: CustomOrderEntry.separatorSongIndex,
          verseIndex: 0,
          label: '---  ---',
          customTextTitle: '',
        ),
      ], activate: true);
      await controller.exportCustomOrderToDia(path, recordSave: false);

      final String content = await File(path).readAsString();
      expect(content, contains('separator=\n'));

      expect(await controller.importCustomOrderFromDia(path), 1);
      expect(controller.customOrder.single.isSeparator, isTrue);
      expect(controller.customOrder.single.customTextTitle, isEmpty);
    });

    test('writes the DTX verse ID to DIA files', () async {
      final DiatarMainController controller = DiatarMainController();
      controller.books = const <DtxBook>[
        DtxBook(
          fileName: 'szvu.dtx',
          title: 'Szent vagy, Uram',
          songs: <DtxSong>[
            DtxSong(
              title: 'Ének',
              verses: <DtxVerse>[
                DtxVerse(
                  name: '1',
                  lines: <String>['Szöveg'],
                  diaId: '12345678',
                ),
              ],
            ),
          ],
        ),
      ];
      final Directory directory = await Directory.systemTemp.createTemp(
        'diatar_dia_id_test_',
      );
      final String path = '${directory.path}${Platform.pathSeparator}order.dia';
      addTearDown(() => directory.delete(recursive: true));

      await controller.applyCustomOrder(const <CustomOrderEntry>[
        CustomOrderEntry(
          fileName: 'szvu.dtx',
          songIndex: 0,
          verseIndex: 0,
          label: 'Ének/1',
        ),
      ], activate: true);
      await controller.exportCustomOrderToDia(path, recordSave: false);

      final String content = await File(path).readAsString();
      expect(content, contains('id=12345678'));
      expect(content, isNot(contains('id=szvu.dtx|0|0')));

      final DiatarMainController imported = DiatarMainController()
        ..books = controller.books;
      expect(await imported.importCustomOrderFromDia(path), 1);
      expect(imported.customOrder.single.fileName, 'szvu.dtx');
    });

    test(
      'uses an embedded image when the DIA image path is unavailable',
      () async {
        final DiatarMainController controller = DiatarMainController();
        final Directory directory = await Directory.systemTemp.createTemp(
          'diatar_embedded_image_test_',
        );
        final String diaPath =
            '${directory.path}${Platform.pathSeparator}order.dia';
        final File imageFile = File(
          '${directory.path}${Platform.pathSeparator}image.png',
        );
        await imageFile.writeAsBytes(<int>[137, 80, 78, 71]);
        addTearDown(() => directory.delete(recursive: true));
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'),
              (MethodCall methodCall) async => directory.path,
            );
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('plugins.flutter.io/path_provider'),
                null,
              ),
        );

        await controller.applyCustomOrder(<CustomOrderEntry>[
          CustomOrderEntry(
            fileName: '__custom_image__',
            songIndex: -2,
            verseIndex: 0,
            label: '[Image] image.png',
            customImagePath: imageFile.path,
            customType: 'image',
          ),
        ], activate: true);
        await controller.exportCustomOrderToDia(
          diaPath,
          recordSave: false,
          embedImages: true,
        );
        await imageFile.delete();

        final DiatarMainController imported = DiatarMainController();
        expect(await imported.importCustomOrderFromDia(diaPath), 1);
        final File restoredImage = File(
          imported.customOrder.single.customImagePath!,
        );
        addTearDown(() => restoredImage.parent.delete(recursive: true));

        expect(await restoredImage.readAsBytes(), <int>[137, 80, 78, 71]);
      },
    );

    test(
      'updates the active set display name after a save-as rename',
      () async {
        final DiatarMainController controller = DiatarMainController();

        await controller.createCustomOrderSet('Régi név');
        await controller.markCustomOrderDiaExportSaved('C:/Temp/Új név.dia');

        expect(controller.customOrderSets, hasLength(1));
        expect(controller.customOrderSets.first.name, 'Új név');
        expect(controller.customOrderSets.first.baseName, 'Új név');
        expect(controller.customOrderSets.first.displayName, 'Új név');
        expect(
          controller.customOrderSets.first.diaFilePath,
          'C:/Temp/Új név.dia',
        );
        expect(controller.customOrderSets.first.isModified, isFalse);
        expect(controller.suggestedCustomOrderBaseName, 'Új név');
      },
    );

    test(
      'keeps an unnamed empty set available after editing and removal',
      () async {
        final DiatarMainController controller = DiatarMainController();

        await controller.applyCustomOrder(const <CustomOrderEntry>[
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: '[Text] Test',
            customTextTitle: 'Test',
            customTextBody: 'Text',
            customType: 'text',
          ),
        ], activate: true);
        await controller.createCustomOrderSet('Második diasor');

        expect(controller.customOrderSets, hasLength(2));
        expect(controller.customOrderSets.first.entries, hasLength(1));

        await controller.removeCustomOrderSet(1);
        await controller.removeCustomOrderSet(0);

        expect(controller.customOrderSets, hasLength(1));
        expect(controller.activeCustomOrderSetIndex, 0);
        expect(controller.customOrderSets.single.name, isEmpty);
        expect(controller.customOrderSets.single.entries, isEmpty);
        expect(controller.customOrderActive, isFalse);
      },
    );

    test('allows toggling the only unnamed set', () async {
      final DiatarMainController controller = DiatarMainController();

      await controller.applyCustomOrder(
        const <CustomOrderEntry>[],
        activate: true,
      );
      await controller.toggleCustomOrderSetEnabled(0);

      expect(controller.customOrderSets.single.enabled, isFalse);
    });

    test(
      'evicts the least recently used set when creating one at the limit',
      () async {
        final DiatarMainController controller = DiatarMainController()
          ..settings = const AppSettings(maxCustomOrderSets: 2);

        await controller.createCustomOrderSet('First');
        await Future<void>.delayed(const Duration(milliseconds: 2));
        await controller.createCustomOrderSet('Second');
        await Future<void>.delayed(const Duration(milliseconds: 2));
        await controller.setActiveCustomOrderSet(0);
        await Future<void>.delayed(const Duration(milliseconds: 2));
        await controller.createCustomOrderSet('Third');

        expect(controller.customOrderSets.map((set) => set.name), <String>[
          'First',
          'Third',
        ]);
      },
    );

    test('keeps only the newly created set when the limit is one', () async {
      final DiatarMainController controller = DiatarMainController()
        ..settings = const AppSettings(maxCustomOrderSets: 1);

      await controller.createCustomOrderSet('First');
      await controller.createCustomOrderSet('Second');

      expect(controller.customOrderSets, hasLength(1));
      expect(controller.customOrderSets.single.name, 'Second');
    });

    test('keeps hotkey sets and reports a temporary limit overflow', () async {
      final DiatarMainController controller = DiatarMainController()
        ..settings = const AppSettings(
          maxCustomOrderSets: 1,
          desktopOrderSetHotkeys: <String, String>{'F1': 'protected'},
        );
      await controller.createCustomOrderSet('Protected');
      final String protectedId = controller.customOrderSets.single.id;
      controller.settings = controller.settings.copyWith(
        desktopOrderSetHotkeys: <String, String>{'F1': protectedId},
      );

      await controller.createCustomOrderSet('New');

      expect(controller.customOrderSets.map((set) => set.name), <String>[
        'Protected',
        'New',
      ]);
      expect(controller.customOrderLimitExceeded, isTrue);
    });

    test('tracks unsaved changes to a custom order set', () async {
      final DiatarMainController controller = DiatarMainController();
      final Directory directory = await Directory.systemTemp.createTemp(
        'diatar_modified_order_test_',
      );
      final String path = '${directory.path}${Platform.pathSeparator}order.dia';
      addTearDown(() => directory.delete(recursive: true));

      await controller.createCustomOrderSet('Új diasor');
      expect(controller.customOrderSets.single.isModified, isFalse);

      await controller.applyCustomOrder(const <CustomOrderEntry>[
        CustomOrderEntry(
          fileName: '__custom_text__',
          songIndex: -1,
          verseIndex: 0,
          label: '[Text] Test',
          customTextTitle: 'Test',
          customTextBody: 'Text',
          customType: 'text',
        ),
      ], activate: true);
      expect(controller.customOrderSets.single.isModified, isTrue);

      await controller.exportCustomOrderToDia(path);
      expect(controller.customOrderSets.single.isModified, isFalse);
    });

    test(
      'exports a modified inactive set without changing the active set',
      () async {
        final DiatarMainController controller = DiatarMainController();
        final Directory directory = await Directory.systemTemp.createTemp(
          'diatar_inactive_order_export_test_',
        );
        final String initialPath =
            '${directory.path}${Platform.pathSeparator}first-initial.dia';
        final String autoSavePath =
            '${directory.path}${Platform.pathSeparator}first-autosave.dia';
        addTearDown(() => directory.delete(recursive: true));

        await controller.createCustomOrderSet('First');
        await controller.applyCustomOrder(const <CustomOrderEntry>[
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: '[Text] First',
            customTextTitle: 'First',
            customTextBody: 'Initial text',
            customType: 'text',
          ),
        ], activate: true);
        final String firstId = controller.activeCustomOrderSetId!;
        await controller.exportCustomOrderToDia(initialPath);

        await controller.createCustomOrderSet('Second');
        await controller.applyCustomOrder(const <CustomOrderEntry>[
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: '[Text] Second',
            customTextTitle: 'Second',
            customTextBody: 'Second text',
            customType: 'text',
          ),
        ], activate: true);
        final String secondId = controller.activeCustomOrderSetId!;

        await controller.setActiveCustomOrderSetById(firstId);
        await controller.applyCustomOrder(const <CustomOrderEntry>[
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: '[Text] First',
            customTextTitle: 'First',
            customTextBody: 'Updated text',
            customType: 'text',
          ),
        ], activate: true);
        await controller.setActiveCustomOrderSetById(secondId);

        await controller.exportCustomOrderToDia(
          autoSavePath,
          customOrderSetId: firstId,
        );

        expect(controller.activeCustomOrderSetId, secondId);
        expect(
          await File(autoSavePath).readAsString(),
          contains('line0=Updated text'),
        );
        expect(
          await File(autoSavePath).readAsString(),
          isNot(contains('Second text')),
        );
        final firstSet = controller.customOrderSets.singleWhere(
          (set) => set.id == firstId,
        );
        final secondSet = controller.customOrderSets.singleWhere(
          (set) => set.id == secondId,
        );
        expect(firstSet.diaFilePath, autoSavePath);
        expect(firstSet.isModified, isFalse);
        expect(secondSet.isModified, isTrue);
      },
    );

    group('custom order sound settings', () {
      test('persists slide-specific sound flags', () {
        const StoredCustomOrderEntry entry = StoredCustomOrderEntry(
          fileName: 'songs.dtx',
          songIndex: 1,
          verseIndex: 2,
          label: 'Song/Verse',
          playSound: true,
          advanceAfterSound: true,
        );

        final StoredCustomOrderEntry? restored =
            StoredCustomOrderEntry.fromJson(entry.toJson());

        expect(restored, isNotNull);
        expect(restored!.playSound, isTrue);
        expect(restored.advanceAfterSound, isTrue);
      });

      test('writes and reads DIA sound options', () async {
        final DiatarMainController controller = DiatarMainController();
        final Directory directory = await Directory.systemTemp.createTemp(
          'diatar_sound_options_test_',
        );
        final String path =
            '${directory.path}${Platform.pathSeparator}order.dia';
        addTearDown(() => directory.delete(recursive: true));

        await controller.applyCustomOrder(const <CustomOrderEntry>[
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: '[Text] Test',
            customTextTitle: 'Test',
            customTextBody: 'Text',
            customType: 'text',
            playSound: true,
            advanceAfterSound: true,
          ),
        ], activate: true);
        await controller.exportCustomOrderToDia(path, recordSave: false);

        final String content = await File(path).readAsString();
        expect(content, contains('sound=1'));
        expect(content, contains('soundforward=1'));

        await controller.importCustomOrderFromDia(
          path,
          mode: CustomOrderImportMode.overwriteActive,
        );
        expect(controller.customOrder.single.playSound, isTrue);
        expect(controller.customOrder.single.advanceAfterSound, isTrue);
      });

      test('writes and reads DIA skipped state', () async {
        final DiatarMainController controller = DiatarMainController();
        final Directory directory = await Directory.systemTemp.createTemp(
          'diatar_skipped_slide_test_',
        );
        final String path =
            '${directory.path}${Platform.pathSeparator}order.dia';
        addTearDown(() => directory.delete(recursive: true));

        await controller.applyCustomOrder(const <CustomOrderEntry>[
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: '[Text] Skipped',
            customTextTitle: 'Skipped',
            customTextBody: 'Text',
            customType: 'text',
            skipped: true,
          ),
        ], activate: true);
        await controller.exportCustomOrderToDia(path, recordSave: false);

        final String content = await File(path).readAsString();
        expect(content, contains('skipped=1'));

        await File(path).writeAsString('''
[main]
diaszam=2

[1]
skipped=true
caption=First
lines=1
line0=First text

[2]
skipped=0
caption=Second
lines=1
line0=Second text
''');
        await controller.importCustomOrderFromDia(
          path,
          mode: CustomOrderImportMode.overwriteActive,
        );
        expect(controller.customOrder[0].skipped, isTrue);
        expect(controller.customOrder[1].skipped, isFalse);
      });

      test('reads boolean and numeric DIA options', () async {
        final Directory directory = await Directory.systemTemp.createTemp(
          'diatar_sound_option_parsing_test_',
        );
        final String path =
            '${directory.path}${Platform.pathSeparator}order.dia';
        addTearDown(() => directory.delete(recursive: true));

        await File(path).writeAsString('''
[main]
diaszam=2

[1]
sound=-1
soundforward=true
dbldia=2
caption=First
lines=1
line0=First text

[2]
sound=0
soundforward=false
dbldia=false
caption=Second
lines=1
line0=Second text
''');

        final DiatarMainController controller = DiatarMainController();
        expect(
          await controller.importCustomOrderFromDia(
            path,
            mode: CustomOrderImportMode.overwriteActive,
          ),
          2,
        );
        expect(controller.customOrder[0].playSound, isTrue);
        expect(controller.customOrder[0].advanceAfterSound, isTrue);
        expect(controller.customOrder[0].mergeWithNext, isTrue);
        expect(controller.customOrder[1].playSound, isFalse);
        expect(controller.customOrder[1].advanceAfterSound, isFalse);
        expect(controller.customOrder[1].mergeWithNext, isFalse);
      });
    });

    test(
      'writes and reads DIA double slide marker on the first slide',
      () async {
        final DiatarMainController controller = DiatarMainController();
        final Directory directory = await Directory.systemTemp.createTemp(
          'diatar_double_slide_test_',
        );
        final String path =
            '${directory.path}${Platform.pathSeparator}order.dia';
        addTearDown(() => directory.delete(recursive: true));

        await controller.applyCustomOrder(const <CustomOrderEntry>[
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: '[Text] First',
            customTextTitle: 'First',
            customTextBody: 'First text',
            customType: 'text',
            mergeWithNext: true,
          ),
          CustomOrderEntry(
            fileName: '__custom_text__',
            songIndex: -1,
            verseIndex: 0,
            label: '[Text] Second',
            customTextTitle: 'Second',
            customTextBody: 'Second text',
            customType: 'text',
          ),
        ], activate: true);
        await controller.exportCustomOrderToDia(path, recordSave: false);

        final String content = await File(path).readAsString();
        expect(content, contains('[1]\ndbldia=1'));
        expect(content, isNot(contains('[2]\ndbldia=1')));
        expect(controller.customOrderProjectionLinesAt(0), <String>[
          'First text',
          '',
          'Second text',
        ]);

        await controller.importCustomOrderFromDia(
          path,
          mode: CustomOrderImportMode.overwriteActive,
        );
        expect(controller.customOrder, hasLength(2));
        expect(controller.customOrder.first.mergeWithNext, isTrue);
        expect(controller.customOrder.last.mergeWithNext, isFalse);
        expect(controller.customOrderProjectionLinesAt(0), <String>[
          'First text',
          '',
          'Second text',
        ]);
      },
    );
  });

  group('connection indicator precedence', () {
    test(
      'TCP stays green when the connection is live even if the internet side is failing',
      () {
        expect(
          resolveTcpIndicatorState(
            tcpActive: true,
            tcpConnected: true,
            tcpHasError: true,
          ),
          TransportIndicatorState.connected,
        );
      },
    );

    test(
      'TCP remains yellow while it is still waiting for a TCP connection',
      () {
        expect(
          resolveTcpIndicatorState(
            tcpActive: true,
            tcpConnected: false,
            tcpHasError: false,
          ),
          TransportIndicatorState.connecting,
        );
      },
    );

    test('Internet status is still independent from TCP', () {
      expect(
        resolveMqttIndicatorState(
          mqttActive: true,
          mqttConnected: false,
          mqttHasError: true,
        ),
        TransportIndicatorState.error,
      );
    });
  });

  group('transport startup independence', () {
    test(
      'TCP startup is not blocked by a slow or failing MQTT connection',
      () async {
        final Completer<void> mqttOpenGate = Completer<void>();
        final _BlockingMqttSender mqtt = _BlockingMqttSender(mqttOpenGate);
        final _TrackingTcpSender tcp = _TrackingTcpSender();
        final SenderTransportCoordinator coordinator =
            const SenderTransportCoordinator();

        final Future<void> applyFuture = coordinator.apply(
          mqttSender: mqtt,
          tcpSender: tcp,
          runtime: const TransportRuntimeState(
            mqttUser: 'user',
            tcpTargets: <String>['127.0.0.1:1024'],
            mqttActive: true,
            tcpConfigured: true,
            mqttConnectAttemptAt: null,
            tcpConnectAttemptAt: null,
          ),
          mqttPassword: 'pw',
          mqttChannel: '1',
          screenWidth: 1920,
          screenHeight: 1080,
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          tcp.restartCalled,
          isTrue,
          reason:
              'TCP restart should be started independently of MQTT connection attempts.',
        );

        mqttOpenGate.complete();
        await applyFuture;
      },
    );
  });
}

class _BlockingMqttSender extends MqttSenderService {
  _BlockingMqttSender(this._openGate)
    : super(onStatusChanged: (_) {}, onError: (_, __) {});

  final Completer<void> _openGate;

  @override
  Future<void> open({
    required String username,
    required String password,
    required String channel,
  }) async {
    await _openGate.future;
  }

  @override
  Future<void> clearRetainedMessages() async {}

  @override
  Future<void> close({bool clearRetained = true}) async {}
}

class _TrackingTcpSender extends TcpSenderService {
  _TrackingTcpSender()
    : super(onStatusChanged: (_) {}, onError: (_, __) {}, onCamera: (_, _) {});

  bool restartCalled = false;

  @override
  Future<void> restart(List<String> targets) async {
    restartCalled = true;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> sendScreenSize({
    required int width,
    required int height,
  }) async {}
}
