import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../core/app_log.dart';

/// Bytes of the regular files under a folder, and how many entries could not
/// be read (permissions, files that vanished while walking).
class DirSize {
  const DirSize(this.bytes, this.unreadable);

  final int bytes, unreadable;
}

/// Walks [path] without following links. [namePattern] (a RegExp source)
/// keeps only the files whose name matches. A missing folder is empty.
DirSize directorySizeSync(String path, {String? namePattern}) {
  final test = namePattern == null ? null : RegExp(namePattern);
  var bytes = 0, unreadable = 0;
  final pending = <Directory>[Directory(path)];
  while (pending.isNotEmpty) {
    final dir = pending.removeLast();
    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      // A folder that does not exist is simply empty; anything else is counted.
      if (dir.existsSync()) unreadable++;
      continue;
    }
    for (final e in entries) {
      if (e is Directory) {
        pending.add(e);
      } else if (e is File) {
        if (test != null && !test.hasMatch(p.basename(e.path))) continue;
        try {
          bytes += e.lengthSync();
        } on FileSystemException {
          unreadable++;
        }
      }
    }
  }
  return DirSize(bytes, unreadable);
}

/// [directorySizeSync] in a background isolate: a covers folder holds
/// thousands of files and must never be walked on the UI isolate.
Future<int> directorySize(String path, {String? namePattern}) async {
  final r = await Isolate.run(
    () => directorySizeSync(path, namePattern: namePattern),
  );
  if (r.unreadable > 0) {
    AppLog.w('${r.unreadable} entries of $path could not be measured');
  }
  return r.bytes;
}

/// Size of one file (0 when it does not exist).
Future<int> fileSize(String path) async {
  final f = File(path);
  try {
    return await f.exists() ? await f.length() : 0;
  } on FileSystemException catch (e, st) {
    AppLog.w('size of $path unreadable', e, st);
    return 0;
  }
}
