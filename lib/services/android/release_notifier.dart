import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';

import '../../core/app_log.dart';
import '../../l10n/app_localizations.dart';
import '../releases/release_check_controller.dart' show ReleaseNotifyHook;
import '../releases/release_notification_text.dart';

/// The Android side of «Nuove uscite» (channel `codecore/notify`): shows the
/// notification and tells Dart when a tap on it opened the app.
class ReleaseNotifier {
  ReleaseNotifier({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('codecore/notify');

  final MethodChannel _channel;
  final _pushed = StreamController<void>.broadcast();
  bool _listening = false;

  /// False when the system does not let the app post notifications.
  Future<bool> show({
    required String title,
    required String body,
    required String channelName,
    required String actionLabel,
  }) async {
    final shown = await _channel.invokeMethod<bool>('showReleases', {
      'title': title,
      'body': body,
      'channelName': channelName,
      'actionLabel': actionLabel,
    });
    return shown ?? false;
  }

  /// The target of the intent that opened the app (read once, then cleared).
  Future<String?> takeLaunchTarget() async {
    try {
      return await _channel.invokeMethod<String>('takeLaunchTarget');
    } on PlatformException catch (e) {
      AppLog.w('notification target not readable: $e');
      return null;
    }
  }

  /// The target of the start, then every later tap while the app lives.
  Stream<String> targets() async* {
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'launchTarget') _pushed.add(null);
      });
    }
    final first = await takeLaunchTarget();
    if (first != null) yield first;
    await for (final _ in _pushed.stream) {
      final t = await takeLaunchTarget();
      if (t != null) yield t;
    }
  }
}

/// The hook of the check controller: words the notification in the app's
/// language ([language] is read when it fires) and posts it through [notifier].
ReleaseNotifyHook releaseNotifyHookFor(ReleaseNotifier notifier, String Function() language) {
  return (fresh) async {
    final l = lookupAppLocalizations(Locale(language()));
    final text = releaseNotificationText(fresh, l);
    if (text == null) return;
    await notifier.show(
      title: text.title,
      body: text.body,
      channelName: l.newReleasesTitle,
      actionLabel: l.releaseNotifyShow,
    );
  };
}
