import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/online_entries.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backend.dart';
import '../support/fake_stream_preparer.dart';

YtResult _r(String id) => YtResult(id: id, title: 'T$id', channel: 'C', duration: null);

void main() {
  late AppDatabase db;
  late OnlineEntries online;
  late CodecoreAudioHandler handler;
  late PlayerController player;
  late List<int> ids;
  late bool plus;
  late bool jam;
  final toJam = <List<int>>[];
  final onlineToJam = <String>[];
  int? downloaded;
  var lookupFails = false;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    online = OnlineEntries();
    final repo = TrackRepository(db);
    handler = CodecoreAudioHandler(
      FakeBackend(),
      PlayQueue(),
      repo,
      onError: (_) {},
      online: online,
      preparer: FakeStreamPreparer(repo, Directory.systemTemp.createTempSync('play_online')),
    );
    ids = [
      for (final n in ['a', 'b'])
        await db.into(db.tracks).insert(TracksCompanion.insert(
              path: '/m/$n.mp3',
              title: 'Song $n',
              albumKey: 'k',
              format: 'mp3',
              sizeBytes: 1,
              mtimeMs: 1,
              addedAt: 1,
            )),
    ];
    plus = true;
    jam = true;
    toJam.clear();
    onlineToJam.clear();
    downloaded = null;
    lookupFails = false;
    player = PlayerController(
      handler,
      null,
      jamActive: () => jam,
      addToJam: toJam.add,
      addOnlineToJam: (r) {
        onlineToJam.add(r.id);
        return true;
      },
      shufflePlus: () => plus,
      setShufflePlus: (on) => plus = on,
      libraryIdOf: (_) async {
        if (lookupFails) throw StateError('index unreadable');
        return downloaded;
      },
    );
    await handler.playQueue(ids, 0);
  });
  tearDown(() async {
    await handler.dispose();
    await db.close();
  });

  test('with a Jam active every queueing path goes to the shared queue, not the local one', () async {
    player.addToQueue(ids[0]);
    player.playNext(ids[1]);
    await player.enqueueOnline(_r('a'));
    await player.playOnlineNext(_r('b'));
    await player.playOnline(_r('c'));
    await player.playOnlineList([_r('d'), _r('e')]);
    final rows = await db.select(db.tracks).get();
    await player.playFromList(rows, 1);
    expect(toJam, [
      [ids[0]],
      [ids[1]],
      [ids[1]],
    ]);
    expect(onlineToJam, ['a', 'b', 'c', 'd', 'e']);
    expect(handler.queueIds, ids);
  });

  test('without a Jam the same calls stay local', () async {
    jam = false;
    player.addToQueue(ids[0]);
    player.playNext(ids[1]);
    await player.enqueueOnline(_r('a'));
    expect(toJam, isEmpty);
    expect(onlineToJam, isEmpty);
    // «Riproduci dopo» right after the current track, «In coda» at the end.
    expect(handler.queueIds.sublist(0, 4), [ids[0], ids[1], ids[1], ids[0]]);
    expect(handler.queueIds.length, 5);
  });

  test('in a Jam a stream shadow row goes as an online track, a file as a track', () async {
    final shadow = await db.into(db.tracks).insert(TracksCompanion.insert(
        path: 'stream:youtube:abc', title: 'S', albumKey: 'k', format: '', sizeBytes: 0,
        mtimeMs: 0, addedAt: 1, kind: const Value(2)));
    final jamCtl = _SpyJam();
    final container = ProviderContainer(overrides: [
      trackRepositoryProvider.overrideWithValue(TrackRepository(db)),
      jamProvider.overrideWith(() => jamCtl),
    ]);
    addTearDown(container.dispose);
    await container.read(jamProvider.notifier).addLibraryIds([ids[0], shadow]);
    expect(jamCtl.online, ['abc']);
    expect(jamCtl.files, [ids[0]]);
  });
}

class _SpyJam extends JamController {
  final online = <String>[];
  final files = <int>[];
  @override
  bool addOnline(YtResult r) {
    online.add(r.id);
    return true;
  }

  @override
  Future<int> addTracks(List<Track> tracks, {bool inherited = false}) async {
    files.addAll(tracks.map((t) => t.id));
    return tracks.length;
  }
}
