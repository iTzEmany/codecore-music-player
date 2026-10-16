// Opt-in: talks to YouTube through the real yt-dlp.
//   CODECORE_LIVE=1 YTDLP=/path/to/yt-dlp flutter test test/live/import_live_test.dart
import 'dart:async';
import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/import/exportify_reader.dart';
import 'package:codecore/services/import/import_candidate.dart';
import 'package:codecore/services/import/playlist_import_service.dart';
import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  test('real CSV against real YouTube Music (search + decision only)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final imports = ImportRepository(db);
    final tracks = TrackRepository(db);
    final yt = YtDlpProcessService(executable: Platform.environment['YTDLP']);
    final queued = <String>[];
    final service = PlaylistImportService(
      imports: imports,
      playlists: PlaylistRepository(db),
      loadLibrary: tracks.liteEntries,
      youtube: yt,
      enqueue: (r, tag) => queued.add('$tag ${r.id} "${r.title}" '
          '[${r.channel}] ${r.duration?.inSeconds}s -> ${r.downloadName}'),
      cancelDownloads: (_) {},
      settled: const Stream.empty(),
      trackIdForPath: tracks.idForPath,
      pathForVideo: (_) async => null,
      applyTags: (_, _) async {},
      maxInFlight: 1000, // nothing settles here: do not throttle
    );
    final text = File('test/fixtures/Just_a_mood.csv').readAsStringSync();
    final limit = int.tryParse(Platform.environment['ROWS'] ?? '') ?? 999;
    final csv = readExportify('Just_a_mood.csv', text);
    final id = await service.start(ExportifyPlaylist(
        name: csv.name, rows: csv.rows.take(limit).toList()));
    for (var i = 0; i < 1200; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final c = await imports.counts(id);
      if ((c[ImportItemStatus.pending] ?? 0) == 0) break;
    }
    final items = await imports.items(id);
    final out = StringBuffer();
    for (final it in items) {
      out.writeln('${it.rowIndex.toString().padLeft(2)} ${it.state.name.padRight(8)} '
          '${(it.score ?? 0).toStringAsFixed(2)}  ${it.title} — ${it.artists}');
      for (final c in decodeCandidates(it.candidates)) {
        out.writeln('       ? ${c.score.toStringAsFixed(2)} ${c.title} [${c.channel}] ${c.durationSec}s');
      }
    }
    final file = File(Platform.environment['OUT'] ?? '/tmp/import_live.txt');
    file.writeAsStringSync('$out\n--- queued\n${queued.join('\n')}\n');
    service.dispose();
    await db.close();
  }, skip: live ? false : 'set CODECORE_LIVE=1', timeout: const Timeout(Duration(minutes: 25)));
}
