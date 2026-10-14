import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'paths.dart';

/// Minimal logger: console in debug, rotated file (2 x 1 MB) in release.
class AppLog {
  AppLog._();

  static const _maxBytes = 1024 * 1024;
  static Future<void> _pending = Future.value();

  static void d(String msg, [Object? err, StackTrace? st]) =>
      _log('D', msg, err, st);
  static void i(String msg, [Object? err, StackTrace? st]) =>
      _log('I', msg, err, st);
  static void w(String msg, [Object? err, StackTrace? st]) =>
      _log('W', msg, err, st);
  static void e(String msg, [Object? err, StackTrace? st]) =>
      _log('E', msg, err, st);

  static void _log(String level, String msg, Object? err, StackTrace? st) {
    final buf = StringBuffer('[$level] $msg');
    if (err != null) buf.write(' | $err');
    if (st != null) buf.write('\n$st');
    final line = buf.toString();
    if (kDebugMode) {
      debugPrint(line);
      return;
    }
    _pending = _pending.then((_) => _append(line));
  }

  static Future<void> _append(String line) async {
    try {
      final file = File(p.join(await appSupportDir(), 'codecore.log'));
      if (await file.exists() && await file.length() > _maxBytes) {
        await file.rename('${file.path}.1');
      }
      final stamp = DateTime.now().toIso8601String();
      await file.writeAsString('$stamp $line\n', mode: FileMode.append);
    } on Object catch (e) {
      debugPrint('AppLog write failed: $e');
    }
  }
}
