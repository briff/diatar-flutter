import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/folder_selection.dart';
import '../models/sync_plan.dart';
import '../models/sync_progress.dart';
import '../models/sync_result.dart';
import '../platform/backend_factory.dart';
import '../platform/sync_backend.dart';

enum SyncDirection {
  localToUsb,
  usbToLocal,
}

class SyncPage extends StatefulWidget {
  const SyncPage({
    super.key,
    this.backend,
  });

  final SyncBackend? backend;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late final SyncBackend _backend;

  StreamSubscription<SyncProgress>?
      _progressSubscription;

  FolderSelection? _localFolder;
  FolderSelection? _usbFolder;

  SyncDirection _direction =
      SyncDirection.localToUsb;

  bool _mirrorMode = true;
  bool _dryRun = false;
  bool _syncRunning = false;

  int _percent = 0;
  int _processedFiles = 0;
  int _totalFiles = 0;

  String _statusText = 'Várakozás...';
  String _currentFile = '';
  String _resultText = '';

  @override
  void initState() {
    super.initState();

    _backend =
        widget.backend ??
        createSyncBackend();

    _progressSubscription =
        _backend.progress.listen(
      _handleProgress,
    );

    _loadSavedFolders();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  String get _localFolderTitle =>
      '${_backend.localFolderName} mappa';

  String get _localToUsbTitle =>
      '${_backend.localFolderName} → Pendrive';

  String get _usbToLocalTitle =>
      'Pendrive → ${_backend.localFolderName}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 720,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Szinkronizálás',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    _localFolderTitle,
                  ),

                  const SizedBox(height: 5),

                  _folderText(
                    _localFolder,
                  ),

                  const SizedBox(height: 8),

                  FilledButton(
                    onPressed:
                        _syncRunning
                            ? null
                            : _selectLocalFolder,
                    child: Text(
                      '$_localFolderTitle KIVÁLASZTÁSA'
                          .toUpperCase(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _sectionTitle(
                    'Pendrive mappa',
                  ),

                  const SizedBox(height: 5),

                  _folderText(
                    _usbFolder,
                  ),

                  const SizedBox(height: 8),

                  FilledButton(
                    onPressed:
                        _syncRunning
                            ? null
                            : _selectUsbFolder,
                    child: const Text(
                      'PENDRIVE MAPPA KIVÁLASZTÁSA',
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  _sectionTitle(
                    'Szinkronizálás iránya',
                  ),

                  RadioGroup<SyncDirection>(
                    groupValue: _direction,
                    onChanged: (value) {
                      if (
                          value != null &&
                          !_syncRunning
                      ) {
                        setState(() {
                          _direction = value;
                        });
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<SyncDirection>(
                          contentPadding:
                              EdgeInsets.zero,
                          title: Text(
                            _localToUsbTitle,
                          ),
                          value:
                              SyncDirection
                                  .localToUsb,
                          enabled:
                              !_syncRunning,
                        ),

                        RadioListTile<SyncDirection>(
                          contentPadding:
                              EdgeInsets.zero,
                          title: Text(
                            _usbToLocalTitle,
                          ),
                          value:
                              SyncDirection
                                  .usbToLocal,
                          enabled:
                              !_syncRunning,
                        ),
                      ],
                    ),
                  ),

                  CheckboxListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    controlAffinity:
                        ListTileControlAffinity
                            .leading,
                    title: const Text(
                      'Tükrözés – töröl is a céloldalon',
                    ),
                    value: _mirrorMode,
                    onChanged:
                        _syncRunning
                            ? null
                            : (value) {
                                setState(() {
                                  _mirrorMode =
                                      value ??
                                      false;
                                });
                              },
                  ),

                  CheckboxListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    controlAffinity:
                        ListTileControlAffinity
                            .leading,
                    title: const Text(
                      'Próbaüzem – nem módosít fájlokat',
                    ),
                    value: _dryRun,
                    onChanged:
                        _syncRunning
                            ? null
                            : (value) {
                                setState(() {
                                  _dryRun =
                                      value ??
                                      false;
                                });
                              },
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 20),

                  Text(
                    _statusText,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  if (_currentFile.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(
                      _currentFile,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  Text(
                    '$_percent%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (_totalFiles > 0)
                    Text(
                      '$_processedFiles / '
                      '$_totalFiles fájl',
                    )
                  else if (_processedFiles > 0)
                    Text(
                      'Átvizsgálva: '
                      '$_processedFiles fájl',
                    ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(
                    value:
                        _percent / 100,
                    minHeight: 12,
                  ),

                  if (_resultText.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    Text(
                      _resultText,
                    ),
                  ],

                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed:
                        _syncRunning
                            ? null
                            : _startSync,
                    child: Text(
                      _syncRunning
                          ? 'SZINKRONIZÁLÁS '
                              'FOLYAMATBAN...'
                          : _dryRun
                              ? 'PRÓBA INDÍTÁSA'
                              : 'SZINKRONIZÁLÁS',
                    ),
                  ),

                  if (_backend.supportsUsbEject) ...[
                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed:
                          _syncRunning
                              ? null
                              : _ejectUsb,
                      child: const Text(
                        'PENDRIVE LEVÁLASZTÁSA',
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String text,
  ) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight:
            FontWeight.bold,
      ),
    );
  }

  Widget _folderText(
    FolderSelection? folder,
  ) {
    return Text(
      folder?.displayName ??
          'Nincs kiválasztva',
      style: TextStyle(
        fontSize: 14,
        color:
            folder == null
                ? Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                : null,
      ),
    );
  }

  void _handleProgress(
    SyncProgress progress,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _percent = progress.percent;
      _processedFiles =
          progress.processedFiles;
      _totalFiles =
          progress.totalFiles;
      _currentFile =
          progress.currentFile;
      _statusText =
          progress.status;
    });
  }

  Future<void> _loadSavedFolders() async {
    try {
      final local =
          await _backend.loadLocalFolder();

      final usb =
          await _backend.loadUsbFolder();

      if (!mounted) {
        return;
      }

      setState(() {
        _localFolder = local;
        _usbFolder = usb;
      });
    } catch (_) {
      // A mentett beállítás hiánya vagy hibája
      // nem akadályozza az alkalmazás indulását.
    }
  }

  Future<void> _selectLocalFolder() async {
    try {
      final folder =
          await _backend.selectLocalFolder();

      if (
          folder == null ||
          !mounted
      ) {
        return;
      }

      setState(() {
        _localFolder = folder;
        _resetStatus();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusText =
            'A mappa kiválasztása '
            'nem sikerült.';
        _resultText =
            _errorText(e);
      });
    }
  }

  Future<void> _selectUsbFolder() async {
    try {
      final folder =
          await _backend.selectUsbFolder();

      if (
          folder == null ||
          !mounted
      ) {
        return;
      }

      setState(() {
        _usbFolder = folder;
        _resetStatus();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusText =
            'A pendrive mappa '
            'kiválasztása nem sikerült.';
        _resultText =
            _errorText(e);
      });
    }
  }

  Future<void> _startSync() async {
    final local =
        _localFolder;

    final usb =
        _usbFolder;

    if (local == null) {
      setState(() {
        _statusText =
            'Nincs kiválasztva a '
            'helyi mappa.';
      });
      return;
    }

    if (usb == null) {
      setState(() {
        _statusText =
            'Nincs kiválasztva a '
            'pendrive mappa.';
      });
      return;
    }

    final source =
        _direction ==
                SyncDirection.localToUsb
            ? local.value
            : usb.value;

    final target =
        _direction ==
                SyncDirection.localToUsb
            ? usb.value
            : local.value;

    setState(() {
      _syncRunning = true;
      _percent = 0;
      _processedFiles = 0;
      _totalFiles = 0;
      _currentFile = '';
      _statusText =
          'Szinkronizálás előkészítése...';
      _resultText = '';
    });

    try {
      final hasState =
          await _backend.hasSyncState(
        source: source,
        target: target,
      );

      if (
          !hasState &&
          !_dryRun
      ) {
        if (!mounted) {
          return;
        }

        final continueFirstSync =
            await _confirmFirstSync();

        if (!continueFirstSync) {
          if (!mounted) {
            return;
          }

          setState(() {
            _syncRunning = false;
            _statusText =
                'Szinkronizálás '
                'megszakítva.';
          });

          return;
        }
      }

      final plan =
          await _backend.prepare(
        source: source,
        target: target,
        mirrorMode: _mirrorMode,
        dryRun: _dryRun,
      );

      if (!mounted) {
        return;
      }

      var allowDelete = false;

      if (
          plan.mirrorMode &&
          !plan.dryRun &&
          plan.deleteCount > 0
      ) {
        final confirmed =
            await _confirmDeletion(
          plan,
        );

        if (!confirmed) {
          if (!mounted) {
            return;
          }

          setState(() {
            _syncRunning = false;
            _statusText =
                'Szinkronizálás '
                'megszakítva.';
            _resultText =
                'A törlés nem lett '
                'engedélyezve.';
          });

          return;
        }

        allowDelete = true;
      }

      final result =
          await _backend.execute(
        plan: plan,
        allowDelete: allowDelete,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _syncRunning = false;
        _percent = 100;
        _currentFile = '';

        _statusText =
            result.errors.isEmpty
                ? result.dryRun
                    ? 'Próbaüzem kész.'
                    : 'Szinkronizálás kész.'
                : 'Szinkronizálás kész, '
                    'hibákkal.';

        _resultText =
            _makeResultText(result);
      });

    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _syncRunning = false;
        _statusText =
            'A szinkronizálás '
            'nem sikerült.';
        _resultText =
            _errorText(e);
      });
    }
  }

  Future<bool> _confirmFirstSync() async {
    final result =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Első szinkronizálás',
          ),
          content: const Text(
            'Ehhez a mappapárhoz még nincs '
            'korábbi szinkronállapot.\n\n'
            'Az első összehasonlítás emiatt '
            'hosszabb ideig tarthat.\n\n'
            'Folytatod?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false);
              },
              child: const Text(
                'MÉGSE',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true);
              },
              child: const Text(
                'FOLYTATÁS',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _confirmDeletion(
    SyncPlan plan,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Törlés megerősítése',
          ),
          content: Text(
            'A tükrözés során a céloldalról '
            '${plan.deleteCount} fájl '
            'törlődik.\n\n'
            'Másolandó/frissítendő: '
            '${plan.copyCount} fájl\n'
            'Új fájl: '
            '${plan.newFileCount}\n'
            'Frissítendő fájl: '
            '${plan.updatedFileCount}\n\n'
            'Biztosan folytatod?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false);
              },
              child: const Text(
                'MÉGSE',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true);
              },
              child: const Text(
                'TÖRLÉS ÉS FOLYTATÁS',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _makeResultText(
    SyncResult result,
  ) {
    final buffer =
        StringBuffer();

    if (result.dryRun) {
      buffer.writeln(
        'Próbaüzem – nem történt '
        'fájlmódosítás.',
      );
      buffer.writeln();
    }

    buffer.writeln(
      'Új fájlok: '
      '${result.newFiles}',
    );

    buffer.writeln(
      'Frissített fájlok: '
      '${result.updatedFiles}',
    );

    buffer.writeln(
      'Törölt fájlok: '
      '${result.deletedFiles}',
    );

    buffer.writeln(
      'Változatlan fájlok: '
      '${result.unchangedFiles}',
    );

    if (result.errors.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        'Hibák: ${result.errors.length}',
      );

      for (final error in result.errors) {
        buffer.writeln(
          '• $error',
        );
      }
    }

    return buffer.toString().trim();
  }

  String _errorText(
    Object error,
  ) {
    if (error is PlatformException) {
      return error.message ??
          error.code;
    }

    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  void _resetStatus() {
    _percent = 0;
    _processedFiles = 0;
    _totalFiles = 0;
    _currentFile = '';
    _statusText = 'Várakozás...';
    _resultText = '';
  }

  Future<void> _ejectUsb() async {
    final success =
        await _backend.ejectUsb();

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText =
          success
              ? 'A pendrive leválasztása '
                  'elindítva.'
              : 'A pendrive leválasztása '
                  'nem sikerült.';
    });
  }
}