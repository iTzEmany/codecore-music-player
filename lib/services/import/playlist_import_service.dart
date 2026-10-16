import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/import_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../online/download_queue.dart';
import '../online/youtube_service.dart';
import 'exportify_reader.dart';
import 'import_candidate.dart';
import 'import_options.dart';
import 'playlist_paths.dart';
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

enum ImportEventKind {
  planned,
  rateLimited,
  network,
  toolMissing,
  toolOutdated,
  failing,
  completed,
}

class ImportEvent {
  const ImportEvent(this.kind, this.importId);

  final ImportEventKind kind;
  final int importId;
}

/// A downloaded file this far (ms) from the CSV length is asked about.
const durationMismatchMs = 10000;

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
    this.forgetSearches,
    this.trackDurationMs,
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

  /// Length of the downloaded file as read by the scanner; without it the
  /// «wrong length» check is skipped.
  final Future<int?> Function(int trackId)? trackDurationMs;

  /// Drops cached search answers; called when a chosen video proved unavailable.
  final void Function(List<String> queries)? forgetSearches;

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

  Stream<ImportEvent> get events => _events.stream;

  void dispose() {
    _disposed = true;
    _sub.cancel();
    _events.close();
  }

  /// Creates the playlist (or reuses [intoPlaylistId]) and starts the import.
  /// Rows already imported into that playlist are left out.
  Future<int> start(
    ImportedPlaylist csv, {
    String? name,
    int? intoPlaylistId,
    ImportOptions options = const ImportOptions(),
  }) async {
    final label = (name?.trim().isNotEmpty ?? false) ? name!.trim() : csv.name;
    final playlistId = intoPlaylistId ?? await playlists.create(label);
    var rows = _withAbsoluteLocations(csv);
    if (intoPlaylistId != null) {
      rows = await _withoutAlreadyImported(intoPlaylistId, rows);
    }
    final id = await imports.create(
        playlistId: playlistId,
        sourceName: label,
        rows: rows,
        sourceKind: csv.kind,
        folderPath: options.folderPath,
        numberFiles: options.numberFiles,
        linkOnly: options.linkOnly,
        planFirst: options.planFirst,
        fetchCovers: options.fetchCovers);
    if (rows.isEmpty) {
      await imports.setStatus(id, ImportStatus.finished);
      _emit(ImportEvent(ImportEventKind.completed, id));
    } else {
      _kick();
    }
    return id;
  }

  /// Relative entries of a playlist file are saved relative to its folder, so
  /// resuming later does not depend on where the file was.
  List<ImportRow> _withAbsoluteLocations(ImportedPlaylist list) {
    final base = list.baseDir;
    if (base == null) return list.rows;
    return [
      for (final r in list.rows)
        r.location != null && !isAbsoluteLocalPath(r.location!)
            ? r.withLocation(p.posix.normalize(
                '${base.replaceAll(r'\', '/')}/${r.location}'))
            : r,
    ];
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
    final imp = await imports.get(importId);
    if (!youtubeEnabled || (imp?.linkOnly ?? false)) {
      await imports.setItem(importId, row.index,
          status: ImportItemStatus.notFound,
          note: Value(youtubeEnabled ? ImportNote.linkOnly : ImportNote.youtubeOff));
      return;
    }
    // Approved in the plan screen: the choice is already made, no search.
    final approved = _approvedChoice(item);
    if (approved != null) {
      await _queueDownload(row, importId, approved.toYtResult(),
          score: item.score);
      return;
    }
    try {
      final decision = await _find(row);
      _failStreak = 0;
      switch (decision.kind) {
        case MatchKind.sure when imp?.planFirst ?? false:
          await imports.setItem(importId, row.index,
              status: ImportItemStatus.planned,
              videoId: Value(decision.best!.result.id),
              candidates: Value(encodeCandidates(decision.top)),
              score: Value(decision.best!.score));
        case MatchKind.sure:
          await _queueDownload(row, importId, decision.best!.result,
              score: decision.best!.score);
        case MatchKind.review:
          await imports.setItem(importId, row.index,
              status: ImportItemStatus.review,
              candidates: Value(encodeCandidates(decision.top)),
              score: Value(decision.best!.score),
              note: const Value(ImportNote.lowScore));
        case MatchKind.notFound:
          await imports.setItem(importId, row.index,
              status: ImportItemStatus.notFound,
              note: const Value(ImportNote.noResults));
      }
    } on YtException catch (e, st) {
      AppLog.w('import search failed for "${row.title}"', e, st);
      await _onSearchError(importId, row, e);
      return;
    }
    await Future<void>.delayed(searchGap);
  }

  /// A row put back to «pending» by [startPlanned] still carries the candidates
  /// it was planned with; its chosen video is the one to download.
  ImportCandidate? _approvedChoice(PlaylistImportItem item) {
    final id = item.videoId;
    if (id == null || item.candidates == null) return null;
    final all = decodeCandidates(item.candidates);
    for (final c in all) {
      if (c.id == id) return c;
    }
    return all.isEmpty ? null : all.first;
  }

  // ---- planning -----------------------------------------------------------

  /// The user picked another of the planned candidates for a row.
  Future<void> choosePlanned(
      int importId, int rowIndex, ImportCandidate choice) =>
      imports.setItem(importId, rowIndex,
          status: ImportItemStatus.planned,
          videoId: Value(choice.id),
          score: Value(choice.score));

  /// «Scarica N brani»: every planned row goes back to the engine as already
  /// decided, so the usual throttling and pausing apply. Returns how many.
  Future<int> startPlanned(int importId) async {
    var n = 0;
    for (final it in await imports.items(importId)) {
      if (it.state != ImportItemStatus.planned) continue;
      await imports.setItem(importId, it.rowIndex,
          status: ImportItemStatus.pending);
      n++;
    }
    await imports.setStatus(importId, ImportStatus.running);
    _kick();
    return n;
  }

  /// The three searches made for [row]: ISRC, `artist title`, `artist - title`.
  static List<String> searchQueries(ImportRow row) => [
        row.isrc ?? '',
        '${matchKey(row.primaryArtist)} ${matchTitleKey(row.title)}'.trim(),
        '${row.primaryArtist} - ${row.title}',
      ];

  Future<MatchDecision> _find(ImportRow row) async {
    // The ISRC identifies the recording: when it lands on a sure match we are
    // done. Otherwise those results are dropped, so a wrong code cannot lift
    // a candidate's score, and the usual title + artist search follows.
    final isrc = row.isrc;
    if (isrc != null && isrc.isNotEmpty) {
      final byIsrc = await youtube.searchSongs(isrc, limit: 3);
      final d = decide(row, byIsrc);
      if (d.kind == MatchKind.sure) return d;
      await Future<void>.delayed(searchGap);
    }
    final queries = searchQueries(row);
    final query = queries[1];
    final songs = await youtube.searchSongs(query, limit: 5);
    var decision = decide(row, songs);
    if (decision.kind == MatchKind.sure) return decision;
    await Future<void>.delayed(searchGap);
    final plain = await youtube.search(queries[2]);
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
      case YtErrorKind.toolOutdated:
        stop = ImportEventKind.toolOutdated;
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
          if (item.error == YtErrorKind.unavailable) {
            forgetSearches?.call(searchQueries(it.toRow()));
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
        case DownloadStatus.waitingRetry:
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
    // The file stays and the track stays in the playlist; a very different
    // length just asks the user to confirm it was the right version.
    final off = await _lengthIsOff(it, trackId);
    await imports.setItem(imp.id, it.rowIndex,
        status: off ? ImportItemStatus.review : ImportItemStatus.downloaded,
        trackId: Value(trackId));
  }

  Future<bool> _lengthIsOff(PlaylistImportItem it, int trackId) async {
    final want = it.durationMs;
    final read = trackDurationMs;
    if (want == null || want <= 0 || read == null) return false;
    final got = await read(trackId);
    return got != null && got > 0 && (got - want).abs() > durationMismatchMs;
  }

  /// The user confirms a downloaded file whose length differed from the CSV.
  Future<void> keepDownloaded(int importId, int rowIndex) =>
      imports.setItem(importId, rowIndex, status: ImportItemStatus.downloaded);

  Future<void> _checkFinished(int importId) async {
    final imp = await imports.get(importId);
    if (imp == null || imp.state != ImportStatus.running) return;
    final c = await imports.counts(importId);
    if ((c[ImportItemStatus.pending] ?? 0) == 0 &&
        (c[ImportItemStatus.queued] ?? 0) == 0) {
      if ((c[ImportItemStatus.planned] ?? 0) > 0) {
        await imports.setStatus(importId, ImportStatus.paused);
        _emit(ImportEvent(ImportEventKind.planned, importId));
        return;
      }
      await imports.setStatus(importId, ImportStatus.finished);
      _emit(ImportEvent(ImportEventKind.completed, importId));
    }
  }

  void _emit(ImportEvent e) {
    if (!_events.isClosed) _events.add(e);
  }
}
