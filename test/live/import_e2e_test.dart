// Opt-in, real network + yt-dlp + ffmpeg: imports 3 rows of the CSV all the way
// (search, download, scan, tags, playlist order) with the production providers.
//   CODECORE_LIVE=1 YTDLP=/path/to/yt-dlp [CC_PARALLEL=1|2|3] flutter test test/live/import_e2e_test.dart
import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/folder_repository.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/import_providers.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/youtube_providers.dart';
import 'package:codecore/services/import/exportify_reader.dart';
import 'package:codecore/services/online/download_index.dart';
import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final live = Platform.environment['CODECORE_LIVE'] == '1';

  test('3 real rows: found, downloaded, tagged and ordered', () async {
    final parallel = int.tryParse(Platform.environment['CC_PARALLEL'] ?? '');
    SharedPreferences.setMockInitialValues(
        {if (parallel != null) 'downloadParallel': parallel});
    final clock = Stopwatch()..start();
    final store = await SettingsStore.open();
    final tmp = Directory.systemTemp.createTempSync('cc_e2e');
    final music = Directory(p.join(tmp.path, 'Music'))..createSync();
    final covers = Directory(p.join(tmp.path, 'covers'))..createSync();
    final db = AppDatabase(NativeDatabase.memory());
    await FolderRepository(db).add(music.path);
    final index = DownloadIndex(File(p.join(tmp.path, 'downloads.json')));
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(store),
      coversDirProvider.overrideWithValue(covers),
      youtubeServiceProvider.overrideWithValue(
          YtDlpProcessService(executable: Platform.environment['YTDLP'])),
      downloadIndexProvider.overrideWith((ref) async => index),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
      tmp.deleteSync(recursive: true);
    });

    final csv = readExportify('E2E_mood.csv',
        File('test/fixtures/Just_a_mood.csv').readAsStringSync());
    const wanted = {'Sigarette', "Blowin' in the Wind", "Rockin' Robin"};
    final rows = [
      for (final r in csv.rows)
        if (wanted.contains(r.title)) r,
    ];
    expect(rows, hasLength(3));

    final svc = container.read(playlistImportServiceProvider);
    final id = await svc.start(ExportifyPlaylist(name: csv.name, rows: rows));
    final imports = container.read(importRepositoryProvider);
    for (var i = 0; i < 720; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final imp = await imports.get(id);
      if (imp!.state == ImportStatus.finished) break;
    }
    final items = await imports.items(id);
    final out = StringBuffer();
    for (final it in items) {
      out.writeln('${it.rowIndex} ${it.state.name} ${it.title} -> '
          'track ${it.trackId} video ${it.videoId} score ${it.score}');
    }
    out.writeln('elapsed: ${clock.elapsed.inSeconds} s (parallel ${store.readSettings().downloadParallel})');
    final files = music.listSync().map((e) => p.basename(e.path)).toList();
    out.writeln('files: $files');
    final tracks = await db.select(db.tracks).get();
    for (final t in tracks) {
      out.writeln('track ${t.id}: "${t.title}" | ${t.artist} | ${t.album} | '
          '${t.durationMs ~/ 1000}s | ${t.format} | userEdited=${t.userEdited}');
    }
    final imp = (await imports.get(id))!;
    final pl = await container
        .read(playlistRepositoryProvider)
        .watchTracks(imp.playlistId)
        .first;
    out.writeln('playlist: ${pl.map((t) => t.title).toList()}');
    File(Platform.environment['OUT'] ?? '/tmp/import_e2e.txt')
        .writeAsStringSync(out.toString());

    expect(imp.state, ImportStatus.finished, reason: '$out');
    expect(items.every((i) => i.state == ImportItemStatus.downloaded),
        isTrue, reason: '$out');
    expect(files.where((f) => f.endsWith('.mp3')), hasLength(3));
    expect(pl.map((t) => t.title).toList(),
        rows.map((r) => r.title).toList());
    expect(pl.every((t) => t.userEdited), isTrue);
  }, skip: live ? false : 'set CODECORE_LIVE=1', timeout: const Timeout(Duration(minutes: 10)));
}
