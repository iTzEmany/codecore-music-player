import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import '../../core/app_log.dart';
import 'duplicate_finder.dart';

typedef FileHasher = Future<String> Function(String path);

/// SHA-256 of a file, read as a stream in another isolate so a big FLAC does
/// not stall the UI.
Future<String> sha256OfFile(String path) => Isolate.run(() async {
  final digest = await sha256.bind(File(path).openRead()).first;
  return digest.toString();
});

/// Hashes [hashCandidates] of [lib] one file at a time (a disk does not read
/// two big files faster than one) and returns `id -> hash` for those that
/// could be read. An unreadable file is logged and left out. [onProgress]
/// gets (done, total); [isCancelled] is polled between files.
Future<Map<int, String>> hashDuplicateCandidates(
  List<DupEntry> lib, {
  FileHasher hasher = sha256OfFile,
  void Function(int done, int total)? onProgress,
  bool Function()? isCancelled,
}) async {
  final todo = hashCandidates(lib);
  final out = <int, String>{};
  for (var i = 0; i < todo.length; i++) {
    if (isCancelled?.call() ?? false) break;
    try {
      out[todo[i].id] = await hasher(todo[i].path);
    } on Object catch (e, st) {
      AppLog.w('hash failed: ${todo[i].path}', e, st);
    }
    onProgress?.call(i + 1, todo.length);
  }
  return out;
}
