import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'paths.dart';

/// Minimal logger: rotated file (2 x 1 MB), plus the console in debug. Debug
/// builds keep the file too: what happened during a night's import is read
/// back from the phone the next morning (the console is gone by then).
class AppLog {
  AppLog._();

  static const _maxBytes = 1024 * 1024;
  static Future<void> _pending = Future.value();

  /// Not under `flutter test`: no app folder there, and no file to leave.
  static final bool _toFile =
      !kDebugMode || !Platform.environment.containsKey('FLUTTER_TEST');

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
    if (kDebugMode) debugPrint(line);
    if (_toFile) _pending = _pending.then((_) => _append(line));
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
