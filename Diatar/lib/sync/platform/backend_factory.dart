import 'package:flutter/foundation.dart';

import 'android_sync_backend.dart';
import 'sync_backend.dart';
import 'windows_sync_backend.dart';

SyncBackend createSyncBackend() {
  if (!kIsWeb) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return WindowsSyncBackend();

      case TargetPlatform.android:
        return AndroidSyncBackend();

      default:
        break;
    }
  }

  throw UnsupportedError(
    'Ehhez a platformhoz még nincs szinkron backend.',
  );
}