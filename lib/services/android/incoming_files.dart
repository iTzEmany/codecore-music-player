import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/app_log.dart';

/// Files other apps hand to Codecore (channel `codecore/incoming`): Kotlin
/// copies them to the cache and keeps the path until Dart takes it.
class IncomingFiles {
  IncomingFiles({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('codecore/incoming');

  final MethodChannel _channel;
  final _pushed = StreamController<void>.broadcast();
  bool _listening = false;

  Future<String?> takeIncoming() async {
    try {
      return await _channel.invokeMethod<String>('takeIncoming');
    } on PlatformException catch (e, st) {
      AppLog.w('incoming file not readable', e, st);
      return null;
    }
  }

  /// The file that started the app, then every later one while it lives.
  Stream<String> paths() async* {
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'incoming') _pushed.add(null);
      });
    }
    final first = await takeIncoming();
    if (first != null) yield first;
    await for (final _ in _pushed.stream) {
      final p = await takeIncoming();
      if (p != null) yield p;
    }
  }
}
