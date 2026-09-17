import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../models/folder_selection.dart';
import '../models/sync_plan.dart';
import '../models/sync_progress.dart';
import '../models/sync_result.dart';
import 'sync_backend.dart';

class WindowsSyncBackend implements SyncBackend {
  final StreamController<SyncProgress> _progressController =
      StreamController<SyncProgress>.broadcast();

  SyncPlan? _preparedPlan;
  String? _preparedSource;
  String? _preparedTarget;

  @override
  String get localFolderName => 'Számítógép';

  @override
  bool get supportsUsbEject => false;

  @override
  Stream<SyncProgress> get progress => _progressController.stream;

  File get _settingsFile {
    final appData = Platform.environment['APPDATA'];

    final baseDirectory = appData != null && appData.isNotEmpty
        ? Directory(appData)
        : Directory.systemTemp;

    return File(
      '${baseDirectory.path}'
      '${Platform.pathSeparator}'
      'sync_app'
      '${Platform.pathSeparator}'
      'folders.json',
    );
  }

  String get _enginePath {
    final executableDirectory = File(Platform.resolvedExecutable).parent;

    final installedPath = File(
      '${executableDirectory.path}'
      '${Platform.pathSeparator}'
      'sync_engine.ps1',
    );

    if (installedPath.existsSync()) {
      return installedPath.path;
    }

    final developmentPath = File(
      '${Directory.current.path}'
      '${Platform.pathSeparator}'
      'windows'
      '${Platform.pathSeparator}'
      'sync_engine.ps1',
    );

    return developmentPath.path;
  }

  @override
  Future<FolderSelection?> selectLocalFolder() async {
    final path = await getDirectoryPath(
      confirmButtonText: 'Mappa kiválasztása',
    );

    if (path == null) {
      return null;
    }

    final selection = FolderSelection(
      value: path,
      displayName: path,
    );

    await _saveFolder(
      'localFolder',
      selection,
    );

    return selection;
  }

  @override
  Future<FolderSelection?> selectUsbFolder() async {
    final path = await getDirectoryPath(
      confirmButtonText: 'Mappa kiválasztása',
    );

    if (path == null) {
      return null;
    }

    final selection = FolderSelection(
      value: path,
      displayName: path,
    );

    await _saveFolder(
      'usbFolder',
      selection,
    );

    return selection;
  }

  @override
  Future<FolderSelection?> loadLocalFolder() {
    return _loadFolder(
      'localFolder',
    );
  }

  @override
  Future<FolderSelection?> loadUsbFolder() {
    return _loadFolder(
      'usbFolder',
    );
  }

  @override
  Future<bool> hasSyncState({
    required String source,
    required String target,
  }) async {
    // A Windows-motor Robocopy + aktuális fájlrendszer-felmérés alapján
    // dolgozik, ezért nincs szüksége az Androidhoz hasonló SyncState-ra.
    return true;
  }

  Future<Map<String, dynamic>> _readSettings() async {
    try {
      final file = _settingsFile;

      if (!await file.exists()) {
        return <String, dynamic>{};
      }

      final text = await file.readAsString();

      if (text.trim().isEmpty) {
        return <String, dynamic>{};
      }

      final decoded = jsonDecode(text);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeSettings(
    Map<String, dynamic> settings,
  ) async {
    final file = _settingsFile;

    await file.parent.create(
      recursive: true,
    );

    await file.writeAsString(
      const JsonEncoder.withIndent(' ').convert(settings),
      flush: true,
    );
  }

  Future<void> _saveFolder(
    String key,
    FolderSelection selection,
  ) async {
    final settings = await _readSettings();

    settings[key] = <String, String>{
      'value': selection.value,
      'displayName': selection.displayName,
    };

    await _writeSettings(
      settings,
    );
  }

  Future<FolderSelection?> _loadFolder(
    String key,
  ) async {
    final settings = await _readSettings();

    final item = settings[key];

    if (item is! Map) {
      return null;
    }

    final value = item['value'];
    final displayName = item['displayName'];

    if (value is! String || value.isEmpty) {
      return null;
    }

    return FolderSelection(
      value: value,
      displayName: displayName is String && displayName.isNotEmpty
          ? displayName
          : value,
    );
  }

  @override
  Future<SyncPlan> prepare({
    required String source,
    required String target,
    required bool mirrorMode,
    required bool dryRun,
  }) async {
    _preparedPlan = null;
    _preparedSource = null;
    _preparedTarget = null;

    final response = await _runEngine(
      mode: 'prepare',
      source: source,
      target: target,
      mirrorMode: mirrorMode,
      dryRun: dryRun,
    );

    final planMap = response.firstWhere(
      (item) => item['type'] == 'plan',
      orElse: () => <String, dynamic>{},
    );

    if (planMap.isEmpty) {
      throw Exception(
        'A Windows szinkronterv nem készült el.',
      );
    }

    final plan = SyncPlan(
      copyCount: (planMap['copyCount'] as num?)?.toInt() ?? 0,
      deleteCount: (planMap['deleteCount'] as num?)?.toInt() ?? 0,
      newFileCount: (planMap['newFileCount'] as num?)?.toInt() ?? 0,
      updatedFileCount:
          (planMap['updatedFileCount'] as num?)?.toInt() ?? 0,
      mirrorMode: planMap['mirrorMode'] as bool? ?? mirrorMode,
      dryRun: planMap['dryRun'] as bool? ?? dryRun,
    );

    _preparedPlan = plan;
    _preparedSource = source;
    _preparedTarget = target;

    return plan;
  }

  @override
  Future<SyncResult> execute({
    required SyncPlan plan,
    required bool allowDelete,
  }) async {
    final preparedPlan = _preparedPlan;
    final source = _preparedSource;
    final target = _preparedTarget;

    if (preparedPlan == null || source == null || target == null) {
      throw Exception(
        'Nincs végrehajtható Windows szinkronterv.',
      );
    }

    if (preparedPlan.mirrorMode &&
        !preparedPlan.dryRun &&
        preparedPlan.deleteCount > 0 &&
        !allowDelete) {
      throw Exception(
        'A szinkronizálás '
        '${preparedPlan.deleteCount} fájl törlését igényli.',
      );
    }

    try {
      final response = await _runEngine(
        mode: 'execute',
        source: source,
        target: target,
        mirrorMode: preparedPlan.mirrorMode,
        dryRun: preparedPlan.dryRun,
      );

      final resultMap = response.firstWhere(
        (item) => item['type'] == 'result',
        orElse: () => <String, dynamic>{},
      );

      if (resultMap.isEmpty) {
        throw Exception(
          'A Windows szinkronizálás nem adott eredményt.',
        );
      }

      final errors = (resultMap['errors'] as List?)
              ?.map(
                (item) => item.toString(),
              )
              .toList() ??
          <String>[];

      return SyncResult(
        newFiles: (resultMap['newFiles'] as num?)?.toInt() ?? 0,
        updatedFiles:
            (resultMap['updatedFiles'] as num?)?.toInt() ?? 0,
        deletedFiles:
            (resultMap['deletedFiles'] as num?)?.toInt() ?? 0,
        unchangedFiles:
            (resultMap['unchangedFiles'] as num?)?.toInt() ?? 0,
        errors: errors,
        dryRun: resultMap['dryRun'] as bool? ?? preparedPlan.dryRun,
      );
    } finally {
      _preparedPlan = null;
      _preparedSource = null;
      _preparedTarget = null;
    }
  }

  Future<List<Map<String, dynamic>>> _runEngine({
    required String mode,
    required String source,
    required String target,
    required bool mirrorMode,
    required bool dryRun,
  }) async {
    final engine = File(_enginePath);

    if (!await engine.exists()) {
      throw Exception(
        'Nem található a Windows szinkronmotor:\n${engine.path}',
      );
    }

    final powerShell = await _findPowerShell();

    final process = await Process.start(
      powerShell,
      <String>[
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        engine.path,
        '-Mode',
        mode,
        '-Source',
        source,
        '-Target',
        target,
        '-MirrorMode',
        mirrorMode ? '1' : '0',
        '-DryRun',
        dryRun ? '1' : '0',
      ],
      runInShell: false,
    );

    final messages = <Map<String, dynamic>>[];
    final stderrBuffer = StringBuffer();

    final stdoutFuture = process.stdout
        .transform(
          const Utf8Decoder(
            allowMalformed: true,
          ),
        )
        .transform(const LineSplitter())
        .forEach(
      (line) {
        final trimmed = line.trim();

        if (trimmed.isEmpty) {
          return;
        }

        try {
          final decoded = jsonDecode(trimmed);

          if (decoded is! Map) {
            return;
          }

          final message = Map<String, dynamic>.from(decoded);
          messages.add(message);

          if (message['type'] == 'progress') {
            _progressController.add(
              SyncProgress(
                percent:
                    (message['percent'] as num?)?.toInt() ?? 0,
                processedFiles:
                    (message['processedFiles'] as num?)?.toInt() ?? 0,
                totalFiles:
                    (message['totalFiles'] as num?)?.toInt() ?? 0,
                currentFile:
                    message['currentFile']?.toString() ?? '',
                status: message['status']?.toString() ?? '',
              ),
            );
          }
        } catch (_) {
          // A motor normál esetben kizárólag JSON sorokat ír stdout-ra.
          // Egy esetleges külső PowerShell üzenetet itt figyelmen kívül hagyunk.
        }
      },
    );

    final stderrFuture = process.stderr
        .transform(
          const SystemEncoding().decoder,
        )
        .forEach(stderrBuffer.write);

    final exitCode = await process.exitCode;

    await stdoutFuture;
    await stderrFuture;

    final engineError = messages
        .where((item) => item['type'] == 'error')
        .map((item) => item['message']?.toString() ?? '')
        .where((message) => message.isNotEmpty)
        .firstOrNull;

    if (exitCode != 0) {
      final stderrText = stderrBuffer.toString().trim();

      throw Exception(
        engineError ??
            (stderrText.isNotEmpty
                ? stderrText
                : 'A Windows szinkronmotor hibával leállt '
                    '(exitcode=$exitCode).'),
      );
    }

    return messages;
  }

  Future<String> _findPowerShell() async {
    final systemRoot =
        Platform.environment['SystemRoot'] ?? r'C:\Windows';

    final windowsPowerShell = File(
      '$systemRoot'
      r'\System32\WindowsPowerShell\v1.0\powershell.exe',
    );

    if (await windowsPowerShell.exists()) {
      return windowsPowerShell.path;
    }

    return 'powershell.exe';
  }

  @override
  Future<bool> ejectUsb() async {
    return false;
  }

  void dispose() {
    _progressController.close();
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;

    if (!iterator.moveNext()) {
      return null;
    }

    return iterator.current;
  }
}
