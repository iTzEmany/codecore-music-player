import 'dart:async';
import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/folder_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/covers/cover_store.dart';
import 'package:codecore/services/online/download_index.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/stream_providers.dart';
import 'package:codecore/providers/youtube_providers.dart';
import 'package:codecore/services/stream/stream_cache.dart';
import 'package:codecore/services/stream/stream_promoter.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _r = YtResult(
  id: 'abc',
  title: 'Song',
  channel: 'Chan',
  duration: Duration(seconds: 200),
  artists: ['Artist'],
  album: 'Album',
);
const _key = 'youtube:abc';

class _Yt implements YoutubeService {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => AppSettings();
}

class _FakePromoter implements StreamPromoter {
  _FakePromoter(this.calls, [this.gate]);
  final List<String> calls;
  final Completer<void>? gate;
  @override
  Future<bool> promote(YtResult r) async {
    calls.add(r.indexKey);
    await gate?.future;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

Future<ProviderContainer> _notifierWith(StreamPromoter promoter) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final dir = await Directory.systemTemp.createTemp('dl');
  addTearDown(() => dir.delete(recursive: true));
  await FolderRepository(db).add(dir.path);
  final c = ProviderContainer(overrides: [
    folderRepositoryProvider.overrideWithValue(FolderRepository(db)),
    youtubeServiceProvider.overrideWithValue(_Yt()),
    settingsProvider.overrideWith(_Settings.new),
    streamPromoterProvider.overrideWithValue(promoter),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  late Directory root;
  late AppDatabase db;
  late TrackRepository tracks;
  late StreamCache cache;
  late CoverStore covers;
  late DownloadIndex index;
  late Folder folder;
  late StreamPromoter promoter;
  late int shadowId;
  final tagged = <int>[];
  final scanned = <String>[];
  var scanSkipped = false;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('promoter');
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    cache = StreamCache(Directory(p.join(root.path, 'cache')), freeSpace: () async => null);
    await cache.open();
    covers = CoverStore(Directory(p.join(root.path, 'covers')));
    index = DownloadIndex(File(p.join(root.path, 'downloads.json')));
    final music = Directory(p.join(root.path, 'Music'))..createSync();
    folder = await FolderRepository(db).add(music.path);
    tagged.clear();
    scanned.clear();
    promoter = StreamPromoter(
      cache: cache,
      tracks: tracks,
      covers: covers,
      downloadFolder: () async => (music, folder),
      index: () async => index,
      scan: (f, path) async {
        scanned.add(path);
        // The scanner skips a path whose size and mtime the row already has (K-02).
        final known = (await tracks.fileIndexForFolder(f.id))[path];
        final st = File(path).statSync();
        scanSkipped = known != null &&
            known.size == st.size &&
            known.mtime == st.modified.millisecondsSinceEpoch;
      },
      tag: (id) async => tagged.add(id),
    );
    final part = File(p.join(cache.dir.path, 'youtube_abc.m4a.part'))..writeAsBytesSync([1, 2, 3, 4]);
    final cached = await cache.put(_key, part);
    shadowId = await tracks.upsertStreamRow(_key, _r, cached);
    await (db.update(db.tracks)..where((t) => t.id.equals(shadowId))).write(const TracksCompanion(
      lyricsPlain: Value('la la'),
      curiosities: Value('fact'),
      playCount: Value(3),
    ));
    await db.into(db.plays).insert(PlaysCompanion.insert(trackId: shadowId, playedAt: 10));
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  test('promote moves the cached file and keeps the row, its plays and its text', () async {
    expect(await promoter.promote(_r), isTrue);

    final dest = p.join(root.path, 'Music', '${downloadBaseName(_r)}.m4a');
    expect(File(dest).existsSync(), isTrue);
    expect(await cache.fileFor(_key), isNull);
    final row = (await tracks.getById(shadowId))!;
    expect((row.kind, row.path, row.folderId), (0, dest, folder.id));
    expect((row.lyricsPlain, row.curiosities, row.playCount), ('la la', 'fact', 3));
    expect(row.albumKey, 'artist|album');
    expect(await db.select(db.plays).get(), hasLength(1));
    expect(index.pathFor(_key), dest);
    expect(tagged, [shadowId]);
    expect(scanned, [dest]);
    expect(scanSkipped, isTrue, reason: 'no second row after the scan');
    expect(await db.select(db.tracks).get(), hasLength(1));
  });

  test('the cover of the shadow row follows the new album key', () async {
    final key = await covers.saveFromBytes('stream|$_key', [9, 9], 'image/jpeg');
    await tracks.setCoverForAlbum('stream|$_key', true, key);
    await promoter.promote(_r);

    final row = (await tracks.getById(shadowId))!;
    expect(row.coverKey, CoverStore.coverKeyFor('artist|album'));
    expect(covers.fileFor(row.coverKey!)!.readAsBytesSync(), [9, 9]);
  });

  test('promote with no file in the cache does nothing', () async {
    await File((await cache.fileFor(_key))!.path).delete();
    cache = StreamCache(cache.dir, freeSpace: () async => null);
    promoter = StreamPromoter(
        cache: cache,
        tracks: tracks,
        covers: covers,
        downloadFolder: () async => fail('not asked'),
        index: () async => index,
        scan: (_, _) async {},
        tag: (_) async {});
    expect(await promoter.promote(_r), isFalse);
    expect((await tracks.getById(shadowId))!.kind, 2);
  });

  test('mergeStreamRow moves plays and text to the downloaded row and drops the shadow', () async {
    final newId = await db.into(db.tracks).insert(TracksCompanion.insert(
        path: '/m/new.m4a', title: 'Song', albumKey: 'artist|album', format: 'm4a', sizeBytes: 1, mtimeMs: 1, addedAt: 1));
    await tracks.mergeStreamRow(_key, newId);

    final row = (await tracks.getById(newId))!;
    expect((row.playCount, row.lyricsPlain, row.curiosities), (3, 'la la', 'fact'));
    expect((await db.select(db.plays).get()).single.trackId, newId);
    expect(await tracks.getById(shadowId), isNull);
  });

  test('a failing step after the move is logged and the track still counts as promoted', () async {
    promoter = StreamPromoter(
        cache: cache,
        tracks: tracks,
        covers: covers,
        downloadFolder: () async => (Directory(p.join(root.path, 'Music')), folder),
        index: () async => index,
        scan: (_, _) async => throw StateError('scan'),
        tag: (_) async => throw StateError('tag'));
    expect(await promoter.promote(_r), isTrue);
    expect(File(p.join(root.path, 'Music', '${downloadBaseName(_r)}.m4a')).existsSync(), isTrue);
  });

  test('the shadow row gone after the move still scans the file and frees the cache entry', () async {
    await db.delete(db.tracks).go();
    // streamRow answers once (the guard), then the row is gone.
    final gone = _VanishingTracks(db);
    promoter = StreamPromoter(
        cache: cache,
        tracks: gone,
        covers: covers,
        downloadFolder: () async => (Directory(p.join(root.path, 'Music')), folder),
        index: () async => index,
        scan: (_, path) async => scanned.add(path),
        tag: (id) async => tagged.add(id));
    expect(await promoter.promote(_r), isTrue);
    expect(scanned, hasLength(1));
    expect(tagged, isEmpty);
    expect(await cache.fileFor(_key), isNull);
  });

  test('a second add of the same track while it moves is ignored', () async {
    final calls = <String>[];
    final gate = Completer<void>();
    final c = await _notifierWith(_FakePromoter(calls, gate));
    final n = c.read(downloadsProvider.notifier);
    n.add(_r);
    n.add(_r);
    await Future<void>.delayed(Duration.zero);
    expect(calls, [_key]);
    gate.complete();
  });

  test('a tagged add (addto:, imports) skips the promoter', () async {
    final calls = <String>[];
    final c = await _notifierWith(_FakePromoter(calls));
    c.read(downloadsProvider.notifier).add(_r, tag: 'addto:1');
    await Future<void>.delayed(Duration.zero);
    expect(calls, isEmpty);
    expect(c.read(downloadsProvider), hasLength(1));
  });
}

/// The guard in `promote` sees the shadow row; right after the move it is gone.
class _VanishingTracks extends TrackRepository {
  _VanishingTracks(super.db);
  @override
  Future<Track?> streamRow(String key) async => _first++ == 0 ? _fake : null;
  var _first = 0;
  final _fake = Track(
      id: 1, path: 'stream:x', title: 't', albumKey: '', durationMs: 0, format: 'm4a', sizeBytes: 0, mtimeMs: 0,
      hasCover: false, isFavorite: false, enrichStatus: 0, userEdited: false, missing: false, ignored: false,
      kind: 2, addedAt: 0, playCount: 0);
  @override
  Future<Track?> promoteStreamRow(String key, String path, int folderId, File file) async => null;
}
