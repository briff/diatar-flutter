import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalCommandService {
  const ExternalCommandService();

  static const MethodChannel _androidChannel = MethodChannel(
    'diatar.eu/external_command',
  );

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> run(String command) async {
    if (!isSupported || command.trim().isEmpty) {
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _androidChannel.invokeMethod<void>('run', <String, String>{
        'command': command.trim(),
      });
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _launchIosUrl(command.trim());
      return;
    }
    await Process.start(
      command,
      const <String>[],
      mode: ProcessStartMode.detached,
      runInShell: true,
    );
  }

  Future<ExternalCommandTestResult> test(String command) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _androidChannel.invokeMethod<void>('run', <String, String>{
        'command': command.trim(),
      });
      return const ExternalCommandTestResult(exitCode: null, errorOutput: '');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _launchIosUrl(command.trim());
      return const ExternalCommandTestResult(exitCode: null, errorOutput: '');
    }
    final Process process = await Process.start(
      command,
      const <String>[],
      runInShell: true,
    );
    final Future<String> errorOutput = process.stderr
        .transform(utf8.decoder)
        .join();
    unawaited(process.stdout.drain<void>());
    final int? exitCode = await process.exitCode
        .then<int?>((int value) => value)
        .timeout(const Duration(seconds: 2), onTimeout: () => null);

    return ExternalCommandTestResult(
      exitCode: exitCode,
      errorOutput: exitCode == null ? '' : await errorOutput,
    );
  }

  Future<void> _launchIosUrl(String command) async {
    final Uri? uri = Uri.tryParse(command);
    if (uri == null || !uri.hasScheme) {
      throw ExternalCommandException('The URL must include a scheme.');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw ExternalCommandException('Could not open URL: $command');
    }
  }
}

class ExternalCommandException implements Exception {
  const ExternalCommandException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExternalCommandTestResult {
  const ExternalCommandTestResult({
    required this.exitCode,
    required this.errorOutput,
  });

  final int? exitCode;
  final String errorOutput;

  bool get succeeded => exitCode == null || exitCode == 0;
}
