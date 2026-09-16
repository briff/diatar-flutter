class SyncPlan {
  const SyncPlan({
    required this.copyCount,
    required this.deleteCount,
    required this.newFileCount,
    required this.updatedFileCount,
    required this.mirrorMode,
    required this.dryRun,
  });

  final int copyCount;
  final int deleteCount;
  final int newFileCount;
  final int updatedFileCount;
  final bool mirrorMode;
  final bool dryRun;
}