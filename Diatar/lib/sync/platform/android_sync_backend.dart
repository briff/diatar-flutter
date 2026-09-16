import 'dart:async';

import 'package:flutter/services.dart';

import '../models/folder_selection.dart';
import '../models/sync_plan.dart';
import '../models/sync_progress.dart';
import '../models/sync_result.dart';
import 'sync_backend.dart';

class AndroidSyncBackend implements SyncBackend {
  static const MethodChannel _storageChannel =
      MethodChannel(
        'com.example.sync_app/storage',
      );

  static const MethodChannel _syncChannel =
      MethodChannel(
        'com.example.sync_app/sync',
      );

  final StreamController<SyncProgress>
      _progressController =
      StreamController<SyncProgress>.broadcast();

  AndroidSyncBackend() {
    _syncChannel.setMethodCallHandler(
      _handleSyncMethodCall,
    );
  }

  @override
  String get localFolderName => 'Android';

  @override
  bool get supportsUsbEject => true;

  @override
  Stream<SyncProgress> get progress =>
      _progressController.stream;

  Future<dynamic> _handleSyncMethodCall(
    MethodCall call,
  ) async {
    if (call.method != 'progress') {
      return null;
    }

    final arguments =
        Map<dynamic, dynamic>.from(
      call.arguments as Map,
    );

    _progressController.add(
      SyncProgress(
        percent:
            (arguments['percent'] as num?)
                    ?.toInt() ??
                0,
        processedFiles:
            (arguments['processedFiles']
                        as num?)
                    ?.toInt() ??
                0,
        totalFiles:
            (arguments['totalFiles'] as num?)
                    ?.toInt() ??
                0,
        currentFile:
            arguments['currentFile']
                    as String? ??
                '',
        status:
            arguments['status']
                    as String? ??
                '',
      ),
    );

    return null;
  }

  @override
  Future<FolderSelection?> selectLocalFolder() {
    return _selectFolder(
      'local',
    );
  }

  @override
  Future<FolderSelection?> selectUsbFolder() {
    return _selectFolder(
      'usb',
    );
  }

  @override
  Future<FolderSelection?> loadLocalFolder() {
    return _loadFolder(
      'local',
    );
  }

  @override
  Future<FolderSelection?> loadUsbFolder() {
    return _loadFolder(
      'usb',
    );
  }

  Future<FolderSelection?> _selectFolder(
    String type,
  ) async {
    final result =
        await _storageChannel
            .invokeMapMethod<String, dynamic>(
      'selectFolder',
      <String, dynamic>{
        'type': type,
      },
    );

    return _folderFromMap(
      result,
    );
  }

  Future<FolderSelection?> _loadFolder(
    String type,
  ) async {
    final result =
        await _storageChannel
            .invokeMapMethod<String, dynamic>(
      'loadFolder',
      <String, dynamic>{
        'type': type,
      },
    );

    return _folderFromMap(
      result,
    );
  }

  FolderSelection? _folderFromMap(
    Map<String, dynamic>? map,
  ) {
    if (map == null) {
      return null;
    }

    final value =
        map['value'];

    final displayName =
        map['displayName'];

    if (value is! String ||
        value.isEmpty) {
      return null;
    }

    return FolderSelection(
      value: value,
      displayName:
          displayName is String &&
                  displayName.isNotEmpty
              ? displayName
              : value,
    );
  }

  @override
  Future<bool> hasSyncState({
    required String source,
    required String target,
  }) async {
    return await _syncChannel
            .invokeMethod<bool>(
          'hasSyncState',
          <String, dynamic>{
            'source': source,
            'target': target,
          },
        ) ??
        false;
  }

  @override
  Future<SyncPlan> prepare({
    required String source,
    required String target,
    required bool mirrorMode,
    required bool dryRun,
  }) async {
    final result =
        await _syncChannel
            .invokeMapMethod<String, dynamic>(
      'prepareSync',
      <String, dynamic>{
        'source': source,
        'target': target,
        'mirrorMode': mirrorMode,
        'dryRun': dryRun,
      },
    );

    if (result == null) {
      throw Exception(
        'A szinkronterv nem készült el.',
      );
    }

    return SyncPlan(
      copyCount:
          (result['copyCount'] as num)
              .toInt(),
      deleteCount:
          (result['deleteCount'] as num)
              .toInt(),
      newFileCount:
          (result['newFileCount'] as num)
              .toInt(),
      updatedFileCount:
          (result['updatedFileCount'] as num)
              .toInt(),
      mirrorMode:
          result['mirrorMode'] as bool,
      dryRun:
          result['dryRun'] as bool,
    );
  }

  @override
  Future<SyncResult> execute({
    required SyncPlan plan,
    required bool allowDelete,
  }) async {
    final result =
        await _syncChannel
            .invokeMapMethod<String, dynamic>(
      'executeSync',
      <String, dynamic>{
        'allowDelete': allowDelete,
      },
    );

    if (result == null) {
      throw Exception(
        'A szinkronizálás nem adott eredményt.',
      );
    }

    final errors =
        (result['errors'] as List?)
                ?.map(
                  (item) =>
                      item.toString(),
                )
                .toList() ??
            <String>[];

    return SyncResult(
      newFiles:
          (result['newFiles'] as num)
              .toInt(),
      updatedFiles:
          (result['updatedFiles'] as num)
              .toInt(),
      deletedFiles:
          (result['deletedFiles'] as num)
              .toInt(),
      unchangedFiles:
          (result['unchangedFiles'] as num)
              .toInt(),
      errors: errors,
      dryRun:
          result['dryRun'] as bool,
    );
  }

  @override
  Future<bool> ejectUsb() async {
    return await _syncChannel
            .invokeMethod<bool>(
          'ejectUsb',
        ) ??
        false;
  }

  void dispose() {
    _syncChannel.setMethodCallHandler(
      null,
    );

    _progressController.close();
  }
}
