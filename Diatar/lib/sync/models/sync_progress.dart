class SyncProgress {
  const SyncProgress({
    required this.percent,
    required this.processedFiles,
    required this.totalFiles,
    required this.currentFile,
    required this.status,
  });

  final int percent;
  final int processedFiles;
  final int totalFiles;
  final String currentFile;
  final String status;

  static const idle = SyncProgress(
    percent: 0,
    processedFiles: 0,
    totalFiles: 0,
    currentFile: '',
    status: 'Várakozás...',
  );
}