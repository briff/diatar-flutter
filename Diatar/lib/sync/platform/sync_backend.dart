import '../models/folder_selection.dart';
import '../models/sync_plan.dart';
import '../models/sync_progress.dart';
import '../models/sync_result.dart';

abstract class SyncBackend {
  String get localFolderName;

  bool get supportsUsbEject;

  Stream<SyncProgress> get progress;

  Future<FolderSelection?> selectLocalFolder();

  Future<FolderSelection?> selectUsbFolder();

  Future<FolderSelection?> loadLocalFolder();

  Future<FolderSelection?> loadUsbFolder();

  Future<bool> hasSyncState({
    required String source,
    required String target,
  });

  Future<SyncPlan> prepare({
    required String source,
    required String target,
    required bool mirrorMode,
    required bool dryRun,
  });

  Future<SyncResult> execute({
    required SyncPlan plan,
    required bool allowDelete,
  });

  Future<bool> ejectUsb();
}