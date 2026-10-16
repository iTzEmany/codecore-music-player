import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_log.dart';
import '../core/paths.dart';
import '../core/platform.dart';
import '../data/db/app_database.dart';
import '../data/repositories/folder_repository.dart';
import '../services/online/download_index.dart';
import '../services/online/download_queue.dart';
import '../services/online/android_yt_dlp_service.dart';
import '../services/online/yt_dlp_process_service.dart';
import '../services/online/yt_dlp_version.dart';
import '../services/online/youtube_service.dart';
import 'database_providers.dart';
import 'library_providers.dart';
import 'online_providers.dart';
import 'yt_dlp_update_providers.dart' show locateYtDlp;
import 'settings_providers.dart';

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  final YoutubeService s = isAndroid
      ? AndroidYtDlpService()
      : YtDlpProcessService(locate: locateYtDlp);
  ref.onDispose(s.close);
  return s;
});

/// What `yt-dlp --version` said; [outdated] drives the banner on desktop.
class YtDlpStatus {
  const YtDlpStatus(this.version);

  final String? version;
  bool get outdated => isYtDlpOutdated(version);
}

final ytDlpStatusProvider = FutureProvider<YtDlpStatus>((ref) async {
  final v = await ref.watch(youtubeServiceProvider).toolVersion();
  return YtDlpStatus(v);
});

final downloadIndexProvider = FutureProvider<DownloadIndex>((ref) async {
  final idx = DownloadIndex(DownloadIndex.defaultFile(await appSupportDir()));
  await idx.load();
  return idx;
});

/// Destination folder for downloads, registered as a scanned folder.
Future<(Directory, Folder)?> resolveDownloadFolder(
  FolderRepository repo,
) async {
  final res = await _resolveDownloadFolder(repo);
  if (res != null) await _removeStalePartFiles(res.$1);
  return res;
}

/// The queue is sequential, so any `.part` left here belongs to a download
/// that was interrupted (app killed) and will never be completed.
Future<void> _removeStalePartFiles(Directory dir) async {
  try {
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.part')) await e.delete();
    }
  } on FileSystemException catch (e, st) {
    AppLog.w('stale .part cleanup failed: ${dir.path}', e, st);
  }
}

Future<(Directory, Folder)?> _resolveDownloadFolder(
  FolderRepository repo,
) async {
  if (isAndroid) {
    final ext = await getExternalStorageDirectory();
    if (ext == null) return null;
    final dir = Directory(p.join(ext.path, 'Music'));
    await dir.create(recursive: true);
    return (dir, await repo.add(dir.path));
  }
  final folders = await repo.getAll();
  if (folders.isNotEmpty) {
    return (Directory(folders.first.path), folders.first);
  }
  // No library folder yet: fall back to the system Music folder.
  final music = Directory(await defaultMusicDir());
  await music.create(recursive: true);
  return (music, await repo.add(music.path));
}

class DownloadsNotifier extends Notifier<List<DownloadItem>> {
  late final DownloadQueue _queue;
  final _settled = StreamController<DownloadItem>.broadcast();

  /// Every item that finished (done, failed or cancelled), after the file was
  /// scanned into the library.
  Stream<DownloadItem> get settled => _settled.stream;

  @override
  List<DownloadItem> build() {
    final yt = ref.watch(youtubeServiceProvider);
    Folder? folder;
    _queue = DownloadQueue(
      downloader: (r, dir, cancel) => yt.download(r, dir, cancel: cancel),
      outDir: () async {
        final res = await resolveDownloadFolder(
          ref.read(folderRepositoryProvider),
        );
        folder = res?.$2;
        return res?.$1;
      },
      onChanged: (items) => state = items,
      onSettled: (item) {
        if (!_settled.isClosed) _settled.add(item);
      },
      onDownloaded: (path) async {
        final f = folder;
        if (f == null) return;
        await for (final _ in ref.read(libraryScannerProvider).scanFiles(f, [
          path,
        ])) {}
        final item = _queue.items.where((e) => e.path == path).firstOrNull;
        if (item != null) {
          final idx = await ref.read(downloadIndexProvider.future);
          await idx.add(item.result.id, path);
        }
        await _autoEnrich(path);
      },
    );
    ref.onDispose(() {
      _queue.dispose();
      _settled.close();
    });
    return const [];
  }

  Future<void> _autoEnrich(String path) async {
    final s = ref.read(settingsProvider);
    if (!s.autoEnrich && !s.autoLyrics) return;
    try {
      final id = await ref.read(trackRepositoryProvider).idForPath(path);
      if (id == null) return;
      ref
          .read(enrichJobProvider.notifier)
          .start(
            [id],
            includeLyrics: s.autoLyrics,
            includeMetadata: s.autoEnrich,
          );
    } on Object catch (e, st) {
      AppLog.w('auto enrich after download failed', e, st);
    }
  }

  void add(YtResult r, {String? tag}) => _queue.add(r, tag: tag);
  void cancel(int id) => _queue.cancel(id);
  void cancelWhere(bool Function(DownloadItem item) test) =>
      _queue.cancelWhere(test);
  void clearFinished() => _queue.clearFinished();
}

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, List<DownloadItem>>(
      DownloadsNotifier.new,
    );
