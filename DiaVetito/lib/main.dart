import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The wakelock is not critical: some Linux/WSL sessions provide no
  // org.freedesktop.ScreenSaver D-Bus service, and the thrown exception would
  // abort main() before runApp() ever runs, leaving a black window.
  try {
    await WakelockPlus.enable();
  } catch (error, stackTrace) {
    debugPrint('WakelockPlus.enable() failed, continuing without it: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const DiaVetitoApp());
}
