import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/app_log.dart';

/// Bridge to the platform for what must work with the app in the background:
/// a foreground service (keeps the process alive) and system notifications.
abstract class ShareNotifier {
  Future<void> startService(
      {required String title, required String text, required String disable});
  Future<void> stopService();
  Future<void> showOffer({
    required String offerId,
    required String title,
    required String body,
    required String accept,
    required String decline,
  });
  Future<void> clearOffer(String offerId);

  /// Whether the app UI is on screen (activity resumed).
  Future<bool> isForeground();

  /// Called when a notification button is pressed.
  void Function(String offerId, bool accept)? onOfferAction;

  /// Called when "turn off" is pressed in the service notification.
  void Function()? onDisableReceive;

  /// Called when the app UI comes back to the foreground.
  void Function()? onAppResumed;
}

class NoopShareNotifier implements ShareNotifier {
  @override
  void Function(String offerId, bool accept)? onOfferAction;
  @override
  void Function()? onDisableReceive;
  @override
  void Function()? onAppResumed;

  @override
  Future<void> startService(
      {required String title, required String text, required String disable}) async {}
  @override
  Future<void> stopService() async {}
  @override
  Future<void> showOffer({
    required String offerId,
    required String title,
    required String body,
    required String accept,
    required String decline,
  }) async {}
  @override
  Future<void> clearOffer(String offerId) async {}
  @override
  Future<bool> isForeground() async => true;
}

class AndroidShareNotifier implements ShareNotifier {
  AndroidShareNotifier() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const _channel = MethodChannel('codecore/share');

  @override
  void Function(String offerId, bool accept)? onOfferAction;
  @override
  void Function()? onDisableReceive;
  @override
  void Function()? onAppResumed;

  Future<dynamic> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'offerAction':
        final a = call.arguments as Map;
        onOfferAction?.call('${a['offerId']}', a['action'] == 'accept');
      case 'disableReceive':
        onDisableReceive?.call();
      case 'appResumed':
        onAppResumed?.call();
    }
    return null;
  }

  Future<void> _invoke(String method, [Map<String, Object?>? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException catch (e, st) {
      AppLog.w('share bridge $method failed', e, st);
    }
  }

  @override
  Future<void> startService(
          {required String title, required String text, required String disable}) =>
      _invoke('startService', {'title': title, 'text': text, 'disable': disable});

  @override
  Future<void> stopService() => _invoke('stopService');

  @override
  Future<void> showOffer({
    required String offerId,
    required String title,
    required String body,
    required String accept,
    required String decline,
  }) =>
      _invoke('showOffer', {
        'offerId': offerId,
        'title': title,
        'body': body,
        'accept': accept,
        'decline': decline,
      });

  @override
  Future<void> clearOffer(String offerId) =>
      _invoke('clearOffer', {'offerId': offerId});

  @override
  Future<bool> isForeground() async {
    try {
      return await _channel.invokeMethod<bool>('isForeground') ?? true;
    } on PlatformException {
      return true;
    }
  }
}

ShareNotifier createShareNotifier() =>
    Platform.isAndroid ? AndroidShareNotifier() : NoopShareNotifier();
