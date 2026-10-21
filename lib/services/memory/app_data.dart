import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../covers/cover_store.dart';
import '../theme/background_image.dart';
import 'dir_size.dart';

/// What the app keeps besides the music, as listed in «Dati dell'app».
enum AppDataKind {
  covers,
  database,
  imageMemory,
  jamCache,
  searchCache,
  blurCopies,
  tagBackups,
  log,
  podcasts,
}

/// Kinds that are made again by themselves when needed: the only ones
/// «Svuota cache» may touch. Covers, the database and the tag backups are
/// the user's data and are never in this set.
const clearableKinds = {
  AppDataKind.imageMemory,
  AppDataKind.jamCache,
  AppDataKind.searchCache,
  AppDataKind.blurCopies,
};

class AppDataItem {
  const AppDataItem(this.kind, this.bytes, {this.detailBytes});

  final AppDataKind kind;
  final int bytes;

  /// Covers: the part taken by the thumbnails.
  final int? detailBytes;
}

/// Where each kind of app data lives. Resolved once by the provider.
class AppDataPaths {
  const AppDataPaths({
    required this.covers,
    required this.database,
    required this.jam,
    required this.theme,
    required this.tagBackups,
    required this.searchCache,
    required this.log,
  });

  final Directory covers, jam, theme, tagBackups;
  final File database, searchCache, log;

  /// SQLite keeps its journal beside the database file.
  List<String> get databaseFiles => [
    database.path,
    '${database.path}-wal',
    '${database.path}-shm',
  ];

  /// The log and its one rotated copy.
  List<String> get logFiles => [log.path, '${log.path}.1'];
}

Future<int> _filesSize(List<String> paths) async {
  var total = 0;
  for (final f in paths) {
    total += await fileSize(f);
  }
  return total;
}

/// Measures every kind (folders in background isolates). [imageMemoryBytes]
/// is the Flutter image cache: it lives in RAM, not on disk.
Future<List<AppDataItem>> measureAppData(
  AppDataPaths paths, {
  required int podcastBytes,
  int? imageMemoryBytes,
}) async {
  final thumbs = directorySize(
    paths.covers.path,
    namePattern: CoverStore.thumbNamePattern,
  );
  final covers = directorySize(paths.covers.path);
  final tags = directorySize(paths.tagBackups.path);
  final jam = directorySize(paths.jam.path);
  final blur = directorySize(
    paths.theme.path,
    namePattern: blurredCopyPattern,
  );
  return [
    AppDataItem(
      AppDataKind.covers,
      await covers,
      detailBytes: await thumbs,
    ),
    AppDataItem(AppDataKind.database, await _filesSize(paths.databaseFiles)),
    AppDataItem(
      AppDataKind.imageMemory,
      imageMemoryBytes ?? PaintingBinding.instance.imageCache.currentSizeBytes,
    ),
    AppDataItem(AppDataKind.jamCache, await jam),
    AppDataItem(AppDataKind.searchCache, await fileSize(paths.searchCache.path)),
    AppDataItem(AppDataKind.blurCopies, await blur),
    AppDataItem(AppDataKind.tagBackups, await tags),
    AppDataItem(AppDataKind.log, await _filesSize(paths.logFiles)),
    AppDataItem(AppDataKind.podcasts, podcastBytes),
  ];
}

class CacheClearResult {
  const CacheClearResult({required this.freedBytes, required this.jamSkipped});

  final int freedBytes;

  /// The Jam cache was left alone because a Jam is playing from it.
  final bool jamSkipped;
}

/// «Svuota cache»: empties the [clearableKinds] and nothing else. The
/// search cache and the image cache are owned by other objects, so their own
/// clear methods are passed in.
class CacheCleaner {
  CacheCleaner({
    required this.jamDir,
    required this.themeDir,
    required this.searchCacheFile,
    required this.clearSearchCache,
    required this.clearImageMemory,
    required this.imageMemoryBytes,
    required this.jamActive,
  });

  final Directory jamDir, themeDir;
  final File searchCacheFile;
  final Future<void> Function() clearSearchCache;
  final void Function() clearImageMemory;
  final int Function() imageMemoryBytes;
  final bool Function() jamActive;

  Future<CacheClearResult> clear() async {
    var freed = 0;
    final skipJam = jamActive();
    if (!skipJam) {
      freed += await directorySize(jamDir.path);
      await _deleteTree(jamDir);
    }
    freed += await directorySize(
      themeDir.path,
      namePattern: blurredCopyPattern,
    );
    await deleteBlurredCopies(themeDir);
    final searchBefore = await fileSize(searchCacheFile.path);
    await clearSearchCache();
    freed += math.max(0, searchBefore - await fileSize(searchCacheFile.path));
    freed += imageMemoryBytes();
    clearImageMemory();
    return CacheClearResult(freedBytes: freed, jamSkipped: skipJam);
  }

  Future<void> _deleteTree(Directory dir) async {
    if (!await dir.exists()) return;
    try {
      await dir.delete(recursive: true);
    } on FileSystemException catch (e, st) {
      AppLog.w('cache folder ${p.basename(dir.path)} not emptied', e, st);
    }
  }
}
