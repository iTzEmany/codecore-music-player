import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/folder_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/pending_playlist_adds.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/stream_providers.dart';
import 'package:codecore/providers/youtube_providers.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/services/online/download_index.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/stream/stream_promoter.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _r = YtResult(id: 'abc', title: 'Song', channel: 'Chan', duration: Duration(seconds: 200));

class _Yt implements YoutubeService {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => AppSettings();
}

class _Promoter implements StreamPromoter {
  int calls = 0;
  @override
  Future<bool> promote(YtResult r) async => ++calls > 0;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late DownloadIndex index;
  late Directory dir;
  late _Promoter promoter;
  late ProviderContainer c;
  var builds = 0;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    dir = await Directory.systemTemp.createTemp('dl_promo');
    addTearDown(() => dir.delete(recursive: true));
    index = DownloadIndex(File('${dir.path}/downloads.json'));
    builds = 0;
    promoter = _Promoter();
    c = ProviderContainer(overrides: [
      folderRepositoryProvider.overrideWithValue(FolderRepository(db)),
      trackRepositoryProvider.overrideWithValue(TrackRepository(db)),
      playlistRepositoryProvider.overrideWithValue(PlaylistRepository(db)),
      youtubeServiceProvider.overrideWithValue(_Yt()),
      settingsProvider.overrideWith(_Settings.new),
      streamPromoterProvider.overrideWithValue(promoter),
      downloadIndexProvider.overrideWith((ref) async {
        builds++;
        return index;
      }),
    ]);
    addTearDown(c.dispose);
    c.listen(downloadIndexProvider, (_, _) {}); // what a row watching it does
    await c.read(downloadIndexProvider.future);
  });

  test('a promotion refreshes the download index the rows watch', () async {
    expect(builds, 1);
    c.read(downloadsProvider.notifier).add(_r);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(promoter.calls, 1);
    expect(builds, 2);
  });

  test('«Scarica» on a video already in the index starts nothing', () async {
    final file = File('${dir.path}/song.m4a')..writeAsStringSync('x');
    await index.add(_r.id, file.path);
    c.read(downloadsProvider.notifier).add(_r);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(promoter.calls, 0);
    expect(c.read(downloadsProvider), isEmpty);
  });

  test('«Aggiungi a playlist» on a video already in the index joins the playlist, no download', () async {
    final file = File('${dir.path}/song.m4a')..writeAsStringSync('x');
    await index.add(_r.id, file.path);
    final trackId = await db.into(db.tracks).insert(TracksCompanion.insert(
        path: file.path, title: 'Song', albumKey: 'k', format: 'm4a', sizeBytes: 1, mtimeMs: 1, addedAt: 1));
    final playlistId = await PlaylistRepository(db).create('P');
    c.read(downloadsProvider.notifier).add(_r, tag: addToPlaylistTag(playlistId));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(promoter.calls, 0);
    expect(c.read(downloadsProvider), isEmpty);
    expect(await PlaylistRepository(db).containing([trackId]), {playlistId});
  });
}
