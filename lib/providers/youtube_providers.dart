import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_log.dart';
import '../core/paths.dart';
import '../core/platform.dart';
import '../data/db/app_database.dart';
import '../services/online/download_index.dart';
import '../services/online/download_queue.dart';
import '../services/online/yt_dlp_process_service.dart';
import '../services/online/youtube_service.dart';
import 'database_providers.dart';
import 'library_providers.dart';
import 'online_providers.dart';
import 'settings_providers.dart';

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  final YoutubeService s = YtDlpProcessService();
  ref.onDispose(s.close);
  return s;
});

final downloadIndexProvider = FutureProvider<DownloadIndex>((ref) async {
  final idx = DownloadIndex(DownloadIndex.defaultFile(await appSupportDir()));
  await idx.load();
  return idx;
});

/// Destination folder for downloads, registered as a scanned folder.
Future<(Directory, Folder)?> resolveDownloadFolder(Ref ref) async {
  final repo = ref.read(folderRepositoryProvider);
  if (isAndroid) {
    final ext = await getExternalStorageDirectory();
    if (ext == null) return null;
    final dir = Directory(p.join(ext.path, 'Music'));
    await dir.create(recursive: true);
    return (dir, await repo.add(dir.path));
  }
  final folders = await repo.getAll();
  if (folders.isEmpty) return null;
  return (Directory(folders.first.path), folders.first);
}

class DownloadsNotifier extends Notifier<List<DownloadItem>> {
  late final DownloadQueue _queue;

  @override
  List<DownloadItem> build() {
    final yt = ref.watch(youtubeServiceProvider);
    Folder? folder;
    _queue = DownloadQueue(
      downloader: (r, dir, cancel) => yt.download(r, dir, cancel: cancel),
      outDir: () async {
        final res = await resolveDownloadFolder(ref);
        folder = res?.$2;
        return res?.$1;
      },
      onChanged: (items) => state = items,
      onDownloaded: (path) async {
        final f = folder;
        if (f == null) return;
        await for (final _ in ref
            .read(libraryScannerProvider)
            .scanFiles(f, [path])) {}
        final item = _queue.items.where((e) => e.path == path).firstOrNull;
        if (item != null) {
          final idx = await ref.read(downloadIndexProvider.future);
          await idx.add(item.result.id, path);
        }
        await _autoEnrich(path);
      },
    );
    ref.onDispose(_queue.dispose);
    return const [];
  }

  Future<void> _autoEnrich(String path) async {
    final s = ref.read(settingsProvider);
    if (!s.autoEnrich && !s.autoLyrics) return;
    try {
      final id = await ref.read(trackRepositoryProvider).idForPath(path);
      if (id == null) return;
      ref.read(enrichJobProvider.notifier).start([id],
          includeLyrics: s.autoLyrics, includeMetadata: s.autoEnrich);
    } on Object catch (e, st) {
      AppLog.w('auto enrich after download failed', e, st);
    }
  }

  void add(YtResult r) => _queue.add(r);
  void cancel(int id) => _queue.cancel(id);
  void clearFinished() => _queue.clearFinished();
}

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, List<DownloadItem>>(
        DownloadsNotifier.new);
