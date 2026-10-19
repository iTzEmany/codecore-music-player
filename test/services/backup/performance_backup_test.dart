import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/services/backup/backup_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final margin = int.tryParse(Platform.environment['CODECORE_PERF_MARGIN'] ?? '') ?? 2;

  test('a backup of 20 000 tracks, 2 000 covers and 200 playlists is made in well under 15 s', () async {
    final dir = Directory.systemTemp.createTempSync('bkperf');
    addTearDown(() => dir.deleteSync(recursive: true));
    // The library is built in memory and written out with one `VACUUM INTO`:
    // built on disk, every playlist insert was a commit with its own sync and
    // the setup took far longer than the backup being measured. The backup
    // still reads a real database file, as in the app.
    final live = File(p.join(dir.path, 'live.sqlite'));
    final seed = AppDatabase(NativeDatabase.memory());
    await seed.batch((b) {
      b.insertAll(seed.tracks, [
        for (var i = 0; i < 20000; i++)
          TracksCompanion.insert(
              path: '/music/a${i % 500}/t$i.mp3', title: 'Song $i', albumKey: 'k${i % 500}', format: 'mp3',
              sizeBytes: 4000000, mtimeMs: 1, addedAt: i, artist: Value('Artist ${i % 300}'),
              album: Value('Album ${i % 500}'), durationMs: const Value(200000),
              isFavorite: Value(i % 10 == 0), playCount: Value(i % 7)),
      ]);
      b.insertAll(seed.playlists, [
        for (var i = 0; i < 200; i++) PlaylistsCompanion.insert(id: Value(i + 1), name: 'P$i', createdAt: i),
      ]);
      b.insertAll(seed.playlistTracks, [
        for (var i = 0; i < 200; i++)
          for (var j = 0; j < 100; j++)
            PlaylistTracksCompanion.insert(playlistId: i + 1, trackId: 1 + (i * 97 + j) % 20000, position: j),
      ]);
    });
    await seed.customStatement('VACUUM INTO ?', [live.path]);
    await seed.close();
    final db = AppDatabase(NativeDatabase(live));
    addTearDown(db.close);
    final covers = Directory(p.join(dir.path, 'covers'))..createSync();
    final jpeg = List<int>.generate(30 * 1024, (i) => (i * 31) % 256);
    for (var i = 0; i < 2000; i++) {
      File(p.join(covers.path, 'c$i.jpg')).writeAsBytesSync(jpeg);
    }
    SharedPreferences.setMockInitialValues({'theme': 'oled'});
    final service = BackupService(
      db: db, prefs: await SharedPreferences.getInstance(), coversDir: covers,
      downloadsFile: File(p.join(dir.path, 'none.json')), deviceId: 'perf',
    );

    final watch = Stopwatch()..start();
    final out = p.join(dir.path, 'b.zip');
    final summary = await service.createBackup(out);
    watch.stop();
    // ignore: avoid_print
    print('backup: ${watch.elapsedMilliseconds} ms, ${(summary.bytes / 1048576).toStringAsFixed(1)} MB');
    expect(summary.covers, 2000);
    expect(summary.tracks, 20000);
    expect(watch.elapsedMilliseconds, lessThan(15000 * margin));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
