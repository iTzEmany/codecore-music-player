import 'package:flutter/services.dart';

import '../../core/app_log.dart';
import 'bluetooth_outputs.dart';

/// `headphones` or `speaker`, as the Android side reports it; anything else
/// is taken as the speaker.
bool isHeadphonesRoute(Object? name) => name == 'headphones';

/// Wires the `codecore/audio` channel: [onRoute] gets the route now and every
/// time it changes. Returns the channel (for tests).
MethodChannel watchOutputRoute(void Function(bool headphones) onRoute) {
  const channel = MethodChannel('codecore/audio');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'outputRoute') {
      onRoute(isHeadphonesRoute(call.arguments));
    } else {
      handleBluetoothCall(call.method);
    }
    return null;
  });
  channel.invokeMethod<String>('outputRoute').then(
    (name) => onRoute(isHeadphonesRoute(name)),
    onError: (Object e, StackTrace st) =>
        AppLog.w('output route unknown', e, st),
  );
  return channel;
}
