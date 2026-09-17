class SyncResult {
  const SyncResult({
    required this.newFiles,
    required this.updatedFiles,
    required this.deletedFiles,
    required this.unchangedFiles,
    required this.errors,
    required this.dryRun,
  });

  final int newFiles;
  final int updatedFiles;
  final int deletedFiles;
  final int unchangedFiles;
  final List<String> errors;
  final bool dryRun;
}