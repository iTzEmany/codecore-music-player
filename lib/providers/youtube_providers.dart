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
import '../services/import/playlist_import_service.dart' show parseImportTag;
import '../services/online/direct_search_service.dart';
import '../services/online/download_index.dart';
import '../services/online/download_queue.dart';
import '../services/online/innertube_client.dart';
import '../services/online/retry_policy.dart';
import '../services/online/android_yt_dlp_service.dart';
import '../services/online/yt_dlp_process_service.dart';
import '../services/online/yt_dlp_version.dart';
import '../services/online/youtube_service.dart';
import 'database_providers.dart';
import 'library_providers.dart';
import 'online_providers.dart';
import 'yt_dlp_update_providers.dart' show locateYtDlp;
import 'settings_providers.dart';

/// The videos of a pasted playlist or channel address, read once per address.
final playlistListingProvider =
    FutureProvider.autoDispose.family<PlaylistListing, String>(
  (ref, url) => ref.read(youtubeServiceProvider).listPlaylist(url),
  // A failure is shown with its own «Riprova»: no silent retries behind a spinner.
  retry: (_, _) => null,
);

/// yt-dlp: the desktop executable or the copy embedded in the Android app.
final ytDlpServiceProvider = Provider<YoutubeService>((ref) {
  final YoutubeService s = isAndroid
      ? AndroidYtDlpService()
      : YtDlpProcessService(locate: locateYtDlp);
  ref.onDispose(s.close);
  return s;
});

/// Searches with one direct request, everything else with yt-dlp.
final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  final s = DirectSearchService(ref.watch(ytDlpServiceProvider), InnerTubeClient());
  ref.onDispose(s.client.close);
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
  return _resolveDownloadFolder(repo);
}

/// Any `.part` found before the first download of a session belongs to a
/// download that was interrupted (app killed) and will never be completed.
/// Never call it while downloads are running.
Future<void> removeStalePartFiles(Directory dir) async {
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

  /// The one-off cleanup of leftovers; later downloads just wait for it.
  Future<void>? _stale;
  final _settled = StreamController<DownloadItem>.broadcast();

  /// Every item that finished (done, failed or cancelled), after the file was
  /// scanned into the library.
  Stream<DownloadItem> get settled => _settled.stream;

  @override
  List<DownloadItem> build() {
    final yt = ref.watch(youtubeServiceProvider);
    Folder? folder;
    _queue = DownloadQueue(
      maxParallel: ref.read(settingsProvider).downloadParallel,
      retryPolicy: RetryPolicy(),
      downloader: (r, dir, cancel) {
        final s = ref.read(settingsProvider);
        return yt.download(r, dir,
            cancel: cancel,
            options: DownloadOptions(
              rateLimitKBps: s.downloadRateLimitKBps,
              format: s.downloadFormat,
            ));
      },
      outDir: () async {
        final res = await resolveDownloadFolder(
          ref.read(folderRepositoryProvider),
        );
        folder = res?.$2;
        final dir = res?.$1;
        if (dir != null) await (_stale ??= removeStalePartFiles(dir));
        return dir;
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
          await idx.add(item.result.id, path, source: item.result.source);
        }
        // An import enriches its songs itself, after putting the CSV tags on.
        if (parseImportTag(item?.tag) == null) await _autoEnrich(path);
      },
    );
    ref.listen(settingsProvider.select((s) => s.downloadParallel),
        (_, n) => _queue.maxParallel = n);
    ref.onDispose(() {
      _queue.dispose();
      _settled.close();
    });
    return const [];
  }

  Future<void> _autoEnrich(String path) async {
    try {
      final id = await ref.read(trackRepositoryProvider).idForPath(path);
      if (id != null) ref.read(downloadEnricherProvider).add(id);
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
