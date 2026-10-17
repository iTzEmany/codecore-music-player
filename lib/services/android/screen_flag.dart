import 'package:flutter/services.dart';

import '../../core/app_log.dart';

const _channel = MethodChannel('codecore/screen');

/// Keeps the screen on (Android `FLAG_KEEP_SCREEN_ON`) while the car mode is
/// open. Anywhere else the channel does not exist and nothing happens.
Future<void> setKeepScreenOn(bool on) async {
  try {
    await _channel.invokeMethod<void>('keepOn', on);
  } on MissingPluginException {
    // Not Android (or a test): nothing to keep on.
  } on PlatformException catch (e) {
    AppLog.w('keep screen on failed', e);
  }
}
