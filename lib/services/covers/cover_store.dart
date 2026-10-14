import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';

class CoverStore {
  CoverStore(this.dir);

  final Directory dir;

  static const maxBytes = 4 * 1024 * 1024;
  static const _folderNames = {'cover', 'folder', 'front', 'album'};
  static const _folderExts = {'.jpg', '.jpeg', '.png'};

  static String coverKeyFor(String albumKey) =>
      sha1.convert(utf8.encode(albumKey)).toString();

  /// Writes the image once per album and returns its `coverKey`.
  Future<String?> saveFromBytes(String albumKey, List<int> bytes, String? mime,
      {bool overwrite = false}) async {
    if (bytes.isEmpty) return null;
    if (bytes.length > maxBytes) {
      AppLog.w('cover too large (${bytes.length} B) for $albumKey, skipped');
      return null;
    }
    final key = coverKeyFor(albumKey);
    final existing = fileFor(key);
    if (existing != null) {
      if (!overwrite) return key;
      await existing.delete();
    }
    final ext = (mime ?? '').toLowerCase().contains('png') ? 'png' : 'jpg';
    try {
      await dir.create(recursive: true);
      final tmp = File(p.join(dir.path, '$key.$ext.tmp'));
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(p.join(dir.path, '$key.$ext'));
      return key;
    } on Object catch (e, st) {
      AppLog.e('cover save failed for $albumKey', e, st);
      return null;
    }
  }

  Future<String?> findFolderCover(String directory) async {
    try {
      await for (final e in Directory(directory).list(followLinks: false)) {
        if (e is! File) continue;
        final ext = p.extension(e.path).toLowerCase();
        final name = p.basenameWithoutExtension(e.path).toLowerCase();
        if (_folderExts.contains(ext) && _folderNames.contains(name)) {
          return e.path;
        }
      }
    } on Object catch (e, st) {
      AppLog.w('folder cover search failed: $directory', e, st);
    }
    return null;
  }

  File? fileFor(String coverKey) {
    for (final ext in const ['jpg', 'png']) {
      final f = File(p.join(dir.path, '$coverKey.$ext'));
      if (f.existsSync()) return f;
    }
    return null;
  }
}
