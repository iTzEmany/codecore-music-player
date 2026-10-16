import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import 'yt_dlp_version.dart';
import 'youtube_service.dart';

/// Parses `yt-dlp -J --flat-playlist` output (a playlist or a single video).
List<YtResult> parseYtDlpJson(String raw) {
  final data = jsonDecode(raw);
  if (data is! Map) return const [];
  final entries = data['entries'] is List ? data['entries'] as List : [data];
  final out = <YtResult>[];
  for (final e in entries) {
    if (e is! Map) continue;
    final id = e['id'] as String?;
    final title = e['title'] as String?;
    if (id == null || title == null) continue;
    String? thumb = e['thumbnail'] as String?;
    final thumbs = e['thumbnails'];
    if (thumb == null && thumbs is List && thumbs.isNotEmpty) {
      final last = thumbs.last;
      if (last is Map) thumb = last['url'] as String?;
    }
    final artists = [
      for (final a in (e['artists'] is List ? e['artists'] as List : const []))
        if (a is String && a.trim().isNotEmpty) a.trim(),
    ];
    final d = e['duration'];
    out.add(YtResult(
      id: id,
      title: title,
      channel: (e['channel'] ??
          e['uploader'] ??
          (artists.isEmpty ? '' : artists.first)) as String,
      duration: d is num ? Duration(seconds: d.round()) : null,
      thumbnailUrl: thumb,
      artists: artists,
      album: e['album'] as String?,
    ));
  }
  return out;
}

/// Parses a line produced by our `--progress-template`:
/// `PROG <downloaded> <total> <estimate>` ("NA" when unknown).
DownloadProgress? parseProgressLine(String line) {
  if (!line.startsWith('PROG ')) return null;
  final parts = line.trim().split(RegExp(r'\s+'));
  if (parts.length < 4) return null;
  int? n(String s) => int.tryParse(s) ?? double.tryParse(s)?.round();
  final done = n(parts[1]) ?? 0;
  final total = n(parts[2]) ?? n(parts[3]) ?? 0;
  return DownloadProgress(received: done, total: total);
}

/// Maps yt-dlp's stderr to a user-facing error kind.
YtException ytExceptionFromStderr(String err) {
  final t = err.toLowerCase();
  if (t.contains('http error 429') ||
      t.contains('too many requests') ||
      (t.contains('confirm') && t.contains('not a bot'))) {
    return YtException(YtErrorKind.rateLimited, err);
  }
  if (t.contains('name or service') ||
      t.contains('network is unreachable') ||
      t.contains('temporary failure in name resolution') ||
      t.contains('timed out')) {
    return YtException(YtErrorKind.network, err);
  }
  if (t.contains('private video') ||
      t.contains('video unavailable') ||
      t.contains('not available') ||
      t.contains('sign in') ||
      t.contains('age-restricted')) {
    return YtException(YtErrorKind.unavailable, err);
  }
  return YtException(YtErrorKind.changed, err);
}

class YtDlpProcessService implements YoutubeService {
  YtDlpProcessService({String? executable}) : _exe = executable ?? 'yt-dlp';

  final String _exe;
  List<String>? _jsRuntimeArgs;
  bool? _hasFfmpeg;

  Future<bool> _exists(String exe) async {
    try {
      // ffmpeg only understands the single-dash form.
      final r = await Process.run(
          exe, [exe == 'ffmpeg' ? '-version' : '--version']);
      return r.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  Future<List<String>> _jsArgs() async {
    final cached = _jsRuntimeArgs;
    if (cached != null) return cached;
    // yt-dlp enables only Deno by default; enable any other runtime we find.
    final args = <String>[];
    for (final rt in const ['deno', 'node', 'bun', 'qjs']) {
      if (await _exists(rt)) {
        args.addAll(['--js-runtimes', rt == 'qjs' ? 'quickjs' : rt]);
      }
    }
    return _jsRuntimeArgs = args;
  }

  Future<String?>? _version;

  @override
  Future<String?> toolVersion() => _version ??= () async {
        try {
          final r = await Process.run(_exe, ['--version']);
          if (r.exitCode != 0) return null;
          return '${r.stdout}'.trim().split('\n').first.trim();
        } on ProcessException {
          return null;
        }
      }();

  /// A failure on an outdated yt-dlp is most likely YouTube having moved on.
  Future<YtException> _explain(Object stderr) async {
    final e = ytExceptionFromStderr('$stderr');
    final stale = e.kind == YtErrorKind.changed ||
        e.kind == YtErrorKind.unavailable;
    if (stale && isYtDlpOutdated(await toolVersion())) {
      return YtException(YtErrorKind.toolOutdated, e.detail);
    }
    return e;
  }

  Future<void> _ensureTool() async {
    if (!await _exists(_exe)) {
      throw const YtException(YtErrorKind.toolMissing, 'yt-dlp');
    }
  }

  @override
  Future<List<YtResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    await _ensureTool();
    final isUrl = isYoutubeUrl(q);
    final args = [
      '-J',
      '--no-warnings',
      if (isUrl) '--no-playlist' else '--flat-playlist',
      isUrl ? q : 'ytsearch10:$q',
    ];
    final r = await Process.run(_exe, args,
        stdoutEncoding: utf8, stderrEncoding: utf8);
    if (r.exitCode != 0) throw await _explain(r.stderr);
    try {
      return parseYtDlpJson('${r.stdout}');
    } on FormatException catch (e, st) {
      AppLog.w('yt-dlp search output not JSON', e, st);
      throw const YtException(YtErrorKind.changed, 'bad output');
    }
  }

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    await _ensureTool();
    final r = await Process.run(
        _exe,
        [
          '-J',
          '--no-warnings',
          '--playlist-items',
          '1-$limit',
          ...await _jsArgs(),
          youtubeMusicSearchUri(q).toString(),
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8);
    if (r.exitCode != 0) throw await _explain(r.stderr);
    try {
      return parseYtDlpJson('${r.stdout}');
    } on FormatException catch (e, st) {
      AppLog.w('yt-dlp music search output not JSON', e, st);
      throw const YtException(YtErrorKind.changed, 'bad output');
    }
  }

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
      {CancelToken? cancel}) async* {
    await _ensureTool();
    await outDir.create(recursive: true);
    _hasFfmpeg ??= await _exists('ffmpeg');
    final convert = _hasFfmpeg!;
    final ext = convert ? 'mp3' : 'm4a';
    final target = uniquePath(
        outDir.path, downloadBaseName(r), ext, (f) => File(f).existsSync());
    final stem = p.withoutExtension(target);
    final args = [
      '--no-playlist',
      '--no-warnings',
      '--newline',
      '--no-part',
      '--progress-template',
      'download:PROG %(progress.downloaded_bytes)s '
          '%(progress.total_bytes)s %(progress.total_bytes_estimate)s',
      ...await _jsArgs(),
      '-f',
      convert ? 'bestaudio/best' : 'bestaudio[ext=m4a]/bestaudio/best',
      if (convert) ...['-x', '--audio-format', 'mp3', '--audio-quality', '256K'],
      '-o',
      '$stem.%(ext)s',
      'https://www.youtube.com/watch?v=${r.id}',
    ];
    final proc = await Process.start(_exe, args);
    final err = StringBuffer();
    proc.stderr.transform(utf8.decoder).listen(err.write);
    final lines =
        proc.stdout.transform(utf8.decoder).transform(const LineSplitter());
    final cancelTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (cancel?.isCancelled ?? false) proc.kill();
    });
    try {
      await for (final line in lines) {
        final prog = parseProgressLine(line);
        if (prog != null) yield prog;
      }
      final code = await proc.exitCode;
      if (cancel?.isCancelled ?? false) {
        await _cleanup(stem);
        return;
      }
      if (code != 0) {
        await _cleanup(stem);
        throw await _explain(err);
      }
      final out = await _findOutput(stem);
      if (out == null) throw const YtException(YtErrorKind.changed, 'no output');
      yield DownloadProgress(received: 1, total: 1, path: out);
    } finally {
      cancelTimer.cancel();
      proc.kill();
    }
  }

  Future<String?> _findOutput(String stem) async {
    final dir = Directory(p.dirname(stem));
    final base = p.basename(stem);
    await for (final e in dir.list()) {
      final name = p.basename(e.path);
      if (e is File && name.startsWith('$base.') && !name.endsWith('.part')) {
        return e.path;
      }
    }
    return null;
  }

  Future<void> _cleanup(String stem) async {
    final dir = Directory(p.dirname(stem));
    final base = p.basename(stem);
    await for (final e in dir.list()) {
      if (e is File && p.basename(e.path).startsWith('$base.')) {
        try {
          await e.delete();
        } on FileSystemException catch (err, st) {
          AppLog.w('cleanup failed: ${e.path}', err, st);
        }
      }
    }
  }

  @override
  void close() {}
}
