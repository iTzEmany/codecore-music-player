import 'dart:async';

import 'package:flutter/services.dart';

import 'app_log.dart';
import 'platform.dart';

/// What the active network is, for features that must not use mobile data.
class NetworkKind {
  const NetworkKind({this.metered = false, this.online = true});

  /// Mobile data or any connection the system calls metered.
  final bool metered;
  final bool online;
}

/// Reads the `codecore/net` channel (Android). Desktop: never metered.
class NetworkProbe {
  NetworkProbe({MethodChannel? channel, bool? android})
      : _channel = channel ?? const MethodChannel('codecore/net'),
        _android = android ?? isAndroid;

  final MethodChannel _channel;
  final bool _android;
  final _changes = StreamController<void>.broadcast();

  /// Fires when the active network, or its metered flag, changes.
  Stream<void> get changes => _changes.stream;

  void listen() {
    if (!_android) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') _changes.add(null);
    });
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    unawaited(_changes.close());
  }

  Future<NetworkKind> current() async {
    if (!_android) return const NetworkKind();
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('isMetered');
      return NetworkKind(
        metered: m?['metered'] == true,
        online: m?['online'] != false,
      );
    } on PlatformException catch (e, st) {
      AppLog.w('network kind unavailable', e, st);
      return const NetworkKind();
    } on MissingPluginException catch (e, st) {
      AppLog.w('network kind unavailable', e, st);
      return const NetworkKind();
    }
  }
}
