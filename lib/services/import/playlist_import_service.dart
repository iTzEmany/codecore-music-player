import 'dart:async';

import 'package:drift/drift.dart' show Value;

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/import_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../online/download_queue.dart';
import '../online/youtube_service.dart';
import 'exportify_reader.dart';
import 'import_candidate.dart';
import 'track_matcher.dart';

const _tagPrefix = 'import:';

String importTag(int importId, int rowIndex) => '$_tagPrefix$importId:$rowIndex';

/// `(importId, rowIndex)` of a download tag made by [importTag], else null.
(int, int)? parseImportTag(String? tag) {
  if (tag == null || !tag.startsWith(_tagPrefix)) return null;
  final parts = tag.substring(_tagPrefix.length).split(':');
  if (parts.length != 2) return null;
  final a = int.tryParse(parts[0]), b = int.tryParse(parts[1]);
  return a == null || b == null ? null : (a, b);
}

enum ImportEventKind { rateLimited, network, toolMissing, failing, completed }

class ImportEvent {
  const ImportEvent(this.kind, this.importId);

  final ImportEventKind kind;
  final int importId;
}

/// Turns the rows of a CSV into a playlist: links what the library already
/// has, searches the rest, downloads it and puts it at its place.
class PlaylistImportService {
  PlaylistImportService({
    required this.imports,
    required this.playlists,
    required this.loadLibrary,
    required this.youtube,
    required this.enqueue,
    required this.cancelDownloads,
    required this.settled,
    required this.trackIdForPath,
    required this.pathForVideo,
    required this.applyTags,
    this.youtubeEnabled = true,
    this.searchGap = const Duration(milliseconds: 1500),
    this.pollDelay = const Duration(milliseconds: 400),
    this.maxInFlight = 3,
  }) {
    _sub = settled.listen((i) => unawaited(_onSettled(i)));
  }

  final ImportRepository imports;
  final PlaylistRepository playlists;
  final Future<List<LibraryEntryLite>> Function() loadLibrary;
  final YoutubeService youtube;
  final void Function(YtResult result, String tag) enqueue;
  final void Function(bool Function(DownloadItem item) test) cancelDownloads;
  final Stream<DownloadItem> settled;
  final Future<int?> Function(String path) trackIdForPath;
  final Future<String?> Function(String videoId) pathForVideo;
  final Future<void> Function(int trackId, ImportRow row) applyTags;
  final bool youtubeEnabled;

  /// Pause between two YouTube searches (be gentle: 429 is the main risk).
  final Duration searchGap;
  final Duration pollDelay;

  /// Downloads of one import allowed to wait in the queue at the same time.
  final int maxInFlight;

  final _events = StreamController<ImportEvent>.broadcast();
  late final StreamSubscription<DownloadItem> _sub;
  bool _looping = false;
  bool _disposed = false;
  int _failStreak = 0;

  /// Rows whose download already got its one automatic retry (YouTube often
  /// answers a transient 403 that a second attempt does not get).
  final _retried = <String>{};

  Stream<ImportEvent> get events => _events.stream;

  void dispose() {
    _disposed = true;
    _sub.cancel();
    _events.close();
  }

  /// Creates the playlist (or reuses [intoPlaylistId]) and starts the import.
  /// Rows already imported into that playlist are left out.
  Future<int> start(
    ExportifyPlaylist csv, {
    String? name,
    int? intoPlaylistId,
  }) async {
    final label = (name?.trim().isNotEmpty ?? false) ? name!.trim() : csv.name;
    final playlistId = intoPlaylistId ?? await playlists.create(label);
    var rows = csv.rows;
    if (intoPlaylistId != null) {
      rows = await _withoutAlreadyImported(intoPlaylistId, rows);
    }
    final id = await imports.create(
        playlistId: playlistId, sourceName: label, rows: rows);
    if (rows.isEmpty) {
      await imports.setStatus(id, ImportStatus.finished);
      _emit(ImportEvent(ImportEventKind.completed, id));
    } else {
      _kick();
    }
    return id;
  }

  Future<List<ImportRow>> _withoutAlreadyImported(
      int playlistId, List<ImportRow> rows) async {
    final inPlaylist =
        (await playlists.watchTracks(playlistId).first).map((t) => t.id).toSet();
    final isrcs = <String>{}, keys = <String>{};
    for (final imp in await imports.forPlaylist(playlistId)) {
      for (final it in await imports.items(imp.id)) {
        if (it.trackId == null || !inPlaylist.contains(it.trackId)) continue;
        if (it.isrc != null) isrcs.add(it.isrc!);
        keys.add(_rowKey(it.toRow()));
      }
    }
    return [
      for (final r in rows)
        if (!(r.isrc != null && isrcs.contains(r.isrc)) &&
            !keys.contains(_rowKey(r)))
          r,
    ];
  }

  String _rowKey(ImportRow r) =>
      '${matchTitleKey(r.title)}|${matchKey(r.primaryArtist)}';

  // ---- user actions -------------------------------------------------------

  Future<void> pause(int importId) async {
    final imp = await imports.get(importId);
    if (imp?.state == ImportStatus.running) {
      await imports.setStatus(importId, ImportStatus.paused);
    }
  }

  Future<void> resume(int importId) async {
    final imp = await imports.get(importId);
    if (imp == null || imp.state != ImportStatus.paused) return;
    await imports.setStatus(importId, ImportStatus.running);
    _kick();
  }

  /// Stops searching and drops the downloads still waiting; tracks already
  /// downloaded stay in the playlist.
  Future<void> cancel(int importId) async {
    await imports.setStatus(importId, ImportStatus.cancelled);
    cancelDownloads((i) => parseImportTag(i.tag)?.$1 == importId);
  }

  /// "Retry all": rows not found or failed are searched again.
  Future<void> retry(int importId) async {
    await imports.resetItems(
        importId, {ImportItemStatus.notFound, ImportItemStatus.failed});
    await imports.setStatus(importId, ImportStatus.running);
    _kick();
  }

  Future<void> skip(int importId, int rowIndex) => imports.setItem(
      importId, rowIndex,
      status: ImportItemStatus.skipped, candidates: const Value(null));

  /// Download [result] for a row (a candidate picked by the user, or one found
  /// with the normal search).
  Future<void> download(int importId, int rowIndex, YtResult result) async {
    final it = await imports.item(importId, rowIndex);
    if (it == null) return;
    await _queueDownload(it.toRow(), importId, result);
    final imp = await imports.get(importId);
    if (imp != null && imp.state != ImportStatus.running) {
      await imports.setStatus(importId, ImportStatus.running);
    }
  }

  /// App start: nothing resumes by itself (no network without a user action).
  Future<void> recoverAfterRestart() => imports.recoverAfterRestart();

  // ---- engine -------------------------------------------------------------

  void _kick() {
    if (!_looping && !_disposed) unawaited(_loop());
  }

  Future<void> _loop() async {
    if (_looping) return;
    _looping = true;
    try {
      final library = LibraryIndex(await loadLibrary());
      while (!_disposed) {
        final running = await _runningImports();
        if (running.isEmpty) break;
        var worked = false, waiting = false;
        for (final imp in running) {
          final item = await imports.nextPending(imp.id);
          if (item == null) {
            await _checkFinished(imp.id);
            continue;
          }
          final counts = await imports.counts(imp.id);
          if ((counts[ImportItemStatus.queued] ?? 0) >= maxInFlight) {
            waiting = true;
            continue;
          }
          await _process(imp.id, item, library);
          worked = true;
          break;
        }
        // Only waiting for downloads to leave the queue: look again soon.
        if (!worked) {
          if (!waiting) break;
          await Future<void>.delayed(pollDelay);
        }
      }
    } on Object catch (e, st) {
      AppLog.e('import loop crashed', e, st);
    } finally {
      _looping = false;
    }
  }

  Future<List<PlaylistImport>> _runningImports() async {
    final all = await imports.watchUnfinished().first;
    return [for (final i in all) if (i.state == ImportStatus.running) i];
  }

  Future<void> _process(
      int importId, PlaylistImportItem item, LibraryIndex library) async {
    final row = item.toRow();
    final hit = library.find(row);
    if (hit != null) {
      await _link(importId, row, hit.id);
      return;
    }
    if (!youtubeEnabled) {
      await imports.setItem(importId, row.index,
          status: ImportItemStatus.notFound);
      return;
    }
    try {
      final decision = await _find(row);
      _failStreak = 0;
      switch (decision.kind) {
        case MatchKind.sure:
          await _queueDownload(row, importId, decision.best!.result,
              score: decision.best!.score);
        case MatchKind.review:
          await imports.setItem(importId, row.index,
              status: ImportItemStatus.review,
              candidates: Value(encodeCandidates(decision.top)),
              score: Value(decision.best!.score));
        case MatchKind.notFound:
          await imports.setItem(importId, row.index,
              status: ImportItemStatus.notFound);
      }
    } on YtException catch (e, st) {
      AppLog.w('import search failed for "${row.title}"', e, st);
      await _onSearchError(importId, row, e);
      return;
    }
    await Future<void>.delayed(searchGap);
  }

  Future<MatchDecision> _find(ImportRow row) async {
    final query = '${matchKey(row.primaryArtist)} ${matchTitleKey(row.title)}'.trim();
    final songs = await youtube.searchSongs(query, limit: 5);
    var decision = decide(row, songs);
    if (decision.kind == MatchKind.sure) return decision;
    await Future<void>.delayed(searchGap);
    final plain = await youtube.search('${row.primaryArtist} - ${row.title}');
    final seen = {for (final s in songs) s.id};
    decision = decide(row, [
      ...songs,
      for (final p in plain.take(5))
        if (seen.add(p.id)) p,
    ]);
    return decision;
  }

  Future<void> _onSearchError(
      int importId, ImportRow row, YtException e) async {
    ImportEventKind? stop;
    switch (e.kind) {
      case YtErrorKind.rateLimited:
        stop = ImportEventKind.rateLimited;
      case YtErrorKind.network:
        stop = ImportEventKind.network;
      case YtErrorKind.toolMissing:
        stop = ImportEventKind.toolMissing;
      case YtErrorKind.unavailable:
      case YtErrorKind.changed:
        _failStreak++;
        await imports.setItem(importId, row.index,
            status: ImportItemStatus.failed);
        if (_failStreak >= 3) {
          _failStreak = 0;
          stop = ImportEventKind.failing;
        }
    }
    if (stop != null) {
      await imports.setStatus(importId, ImportStatus.paused);
      _emit(ImportEvent(stop, importId));
    }
  }

  Future<void> _link(int importId, ImportRow row, int trackId) async {
    await imports.setItem(importId, row.index,
        status: ImportItemStatus.linked, trackId: Value(trackId));
    final imp = await imports.get(importId);
    if (imp != null) {
      await playlists.placeImported(imp.playlistId, importId, row.index, trackId);
    }
  }

  Future<void> _queueDownload(ImportRow row, int importId, YtResult r,
      {double? score}) async {
    final existing = await pathForVideo(r.id);
    if (existing != null) {
      final id = await trackIdForPath(existing);
      if (id != null) {
        await _link(importId, row, id);
        return;
      }
    }
    await imports.setItem(importId, row.index,
        status: ImportItemStatus.queued,
        videoId: Value(r.id),
        candidates: const Value(null),
        score: Value(score));
    enqueue(
      YtResult(
        id: r.id,
        title: r.title,
        channel: r.channel,
        duration: r.duration,
        thumbnailUrl: r.thumbnailUrl,
        artists: r.artists,
        album: r.album,
        downloadName: '${row.artistLine} - ${row.title}',
      ),
      importTag(importId, row.index),
    );
  }

  Future<void> _onSettled(DownloadItem item) async {
    final ref = parseImportTag(item.tag);
    if (ref == null || _disposed) return;
    final (importId, rowIndex) = ref;
    try {
      final imp = await imports.get(importId);
      final it = await imports.item(importId, rowIndex);
      if (imp == null || it == null) return;
      if (imp.state == ImportStatus.cancelled) return;
      switch (item.status) {
        case DownloadStatus.done:
          await _finishDownload(imp, it, item.path);
        case DownloadStatus.failed:
          final transient = item.error == YtErrorKind.changed ||
              item.error == YtErrorKind.network;
          if (transient && _retried.add('$importId:$rowIndex')) {
            enqueue(item.result, importTag(importId, rowIndex));
            return;
          }
          await imports.setItem(importId, rowIndex,
              status: ImportItemStatus.failed);
          if (item.error == YtErrorKind.rateLimited) {
            await imports.setStatus(importId, ImportStatus.paused);
            _emit(ImportEvent(ImportEventKind.rateLimited, importId));
          }
        case DownloadStatus.cancelled:
          await imports.setItem(importId, rowIndex,
              status: ImportItemStatus.failed);
        case DownloadStatus.queued:
        case DownloadStatus.downloading:
          return;
      }
      await _checkFinished(importId);
      _kick();
    } on Object catch (e, st) {
      AppLog.e('import: handling a finished download failed', e, st);
    }
  }

  Future<void> _finishDownload(
      PlaylistImport imp, PlaylistImportItem it, String? path) async {
    final trackId = path == null ? null : await trackIdForPath(path);
    if (trackId == null) {
      await imports.setItem(imp.id, it.rowIndex,
          status: ImportItemStatus.failed);
      return;
    }
    try {
      await applyTags(trackId, it.toRow());
    } on Object catch (e, st) {
      AppLog.w('import: could not apply CSV tags to track $trackId', e, st);
    }
    await playlists.placeImported(imp.playlistId, imp.id, it.rowIndex, trackId);
    await imports.setItem(imp.id, it.rowIndex,
        status: ImportItemStatus.downloaded, trackId: Value(trackId));
  }

  Future<void> _checkFinished(int importId) async {
    final imp = await imports.get(importId);
    if (imp == null || imp.state != ImportStatus.running) return;
    final c = await imports.counts(importId);
    if ((c[ImportItemStatus.pending] ?? 0) == 0 &&
        (c[ImportItemStatus.queued] ?? 0) == 0) {
      await imports.setStatus(importId, ImportStatus.finished);
      _emit(ImportEvent(ImportEventKind.completed, importId));
    }
  }

  void _emit(ImportEvent e) {
    if (!_events.isClosed) _events.add(e);
  }
}
