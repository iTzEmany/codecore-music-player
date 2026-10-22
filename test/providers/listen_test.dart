import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/listen_providers.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backend.dart';

const _song = YtResult(id: 'abc', title: 'Mother', channel: 'Pink Floyd', duration: Duration(minutes: 5));
const _other = YtResult(id: 'xyz', title: 'Time', channel: 'Pink Floyd', duration: Duration(minutes: 7));

void main() {
  late AppDatabase db;
  late FakeBackend main;
  late CodecoreAudioHandler handler;
  late List<FakeBackend> players;
  late List<String> asked;
  late List<bool> askedFast;
  late ProviderContainer c;
  late List<int> ids;
  YtException? failWith;
  var refuseQuick = false;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    main = FakeBackend();
    players = [];
    asked = [];
    askedFast = [];
    refuseQuick = false;
    failWith = null;
    for (final n in ['a', 'b']) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/$n.mp3', title: n, albumKey: 'k', format: 'mp3', sizeBytes: 1, mtimeMs: 1, addedAt: 1,
          durationMs: const Value(90000)));
    }
    ids = (await db.select(db.tracks).get()).map((t) => t.id).toList();
    handler = CodecoreAudioHandler(main, PlayQueue(), TrackRepository(db), onError: (_) {});
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      audioHandlerProvider.overrideWithValue(handler),
      streamResolverProvider.overrideWithValue((r, {bool fast = true}) async {
        asked.add(r.id);
        askedFast.add(fast);
        if (failWith != null) throw failWith!;
        return StreamAddress(Uri.parse('https://media.example/${r.id}.m4a${fast ? '?f=1' : ''}'),
            headers: const {'User-Agent': 'vr'}, fast: fast);
      }),
      listenBackendFactoryProvider.overrideWithValue(() {
        final b = FakeBackend();
        if (refuseQuick) b.expiring.add('https://media.example/abc.m4a?f=1');
        players.add(b);
        return b;
      }),
    ]);
    c.listen(listenProvider, (_, _) {});
  });
  tearDown(() async {
    c.dispose();
    await handler.dispose();
    await db.close();
  });

  ListenNotifier listen() => c.read(listenProvider.notifier);

  test('a listen plays the stream on its own player and gives the music back', () async {
    await handler.playQueue(ids, 0);
    final queue = List.of(handler.queueIds);
    await listen().start(_song);
    await pumpEventQueue();
    expect(handler.isPlaying, isFalse, reason: 'the music pauses');
    expect(players.single.loadedUris.single.uri.toString(), 'https://media.example/abc.m4a?f=1');
    expect(players.single.playing, isTrue);
    expect(c.read(listenProvider).phase, ListenPhase.playing);
    expect(main.loadedUris, isEmpty, reason: 'not through the main player');

    await listen().stop();
    await pumpEventQueue();
    expect(c.read(listenProvider).active, isFalse);
    expect(players.single.disposed, isTrue);
    expect(handler.isPlaying, isTrue, reason: 'it was playing before');
    expect(handler.queueIds, queue, reason: 'the queue is untouched');
  });

  test('the same button pauses and resumes; another result replaces the listen', () async {
    await listen().toggle(_song);
    await listen().toggle(_song);
    expect(c.read(listenProvider).phase, ListenPhase.paused);
    expect(players.single.playing, isFalse);
    await listen().toggle(_song);
    expect(c.read(listenProvider).phase, ListenPhase.playing);

    await listen().toggle(_other);
    await pumpEventQueue();
    expect(players, hasLength(2));
    expect(players.first.disposed, isTrue);
    expect(c.read(listenProvider).result!.id, 'xyz');
    expect(asked, ['abc', 'xyz'], reason: 'the address is asked at each listen');
  });

  test('the headers of the address reach the player', () async {
    await listen().start(_song);
    expect(players.single.loadedUris.single.headers, {'User-Agent': 'vr'});
  });

  test('a refused quick address is asked again with the default clients; two refusals switch the quick client off', () async {
    refuseQuick = true;
    await listen().start(_song);
    expect(askedFast, [true, false]);
    expect(c.read(listenProvider).phase, ListenPhase.playing);
    expect(players.single.loadedUris.single.uri.toString(), 'https://media.example/abc.m4a');
    await listen().stop();
    await listen().start(_song);
    expect(askedFast, [true, false, true, false]);
    expect(c.read(fastClientGateProvider).enabled, isFalse);
    await listen().stop();
    await listen().start(_song);
    expect(askedFast.skip(4), [false], reason: 'the quick client is off for the session');
  });

  test('position and length come from the player; the end of the song closes the listen', () async {
    await listen().start(_song);
    players.single.posC.add(const Duration(seconds: 42));
    players.single.durC.add(const Duration(minutes: 5, seconds: 35));
    await pumpEventQueue();
    expect(c.read(listenProvider).position, const Duration(seconds: 42));
    expect(c.read(listenProvider).duration, const Duration(minutes: 5, seconds: 35));
    players.single.stateC.add(BackendState.completed);
    await pumpEventQueue();
    expect(c.read(listenProvider).active, isFalse);
  });

  test('no address: the reason is told and the music comes back', () async {
    await handler.playQueue(ids, 0);
    failWith = const YtException(YtErrorKind.rateLimited);
    await listen().start(_song);
    await pumpEventQueue();
    expect(c.read(listenProvider).active, isFalse);
    expect(c.read(listenProvider).error, YtErrorKind.rateLimited);
    expect(players, isEmpty);
    expect(handler.isPlaying, isTrue);
  });

  test('music started from the library ends the listen and stays on', () async {
    await handler.playQueue(ids, 0);
    await listen().start(_song);
    await pumpEventQueue();
    await handler.play();
    await pumpEventQueue();
    expect(c.read(listenProvider).active, isFalse);
    expect(handler.isPlaying, isTrue);
  });

  test('the listen goes on while any online page is open and ends with the last', () async {
    await handler.playQueue(ids, 0);
    listen()
      ..attach()
      ..attach();
    await listen().start(_song);
    await pumpEventQueue();
    expect(c.read(listenProvider).active, isTrue);

    listen().detach();
    await pumpEventQueue();
    expect(c.read(listenProvider).active, isTrue, reason: 'one page is still open');
    expect(listen().attachedPages, 1);

    listen().detach();
    await pumpEventQueue();
    expect(c.read(listenProvider).active, isFalse);
    expect(handler.isPlaying, isTrue, reason: 'the music of before comes back');

    listen().detach(); // a stray extra one never goes below zero
    expect(listen().attachedPages, 0);
  });

  test('yt-dlp -g: the first web address', () {
    expect(parseStreamUrl('WARNING: x\nhttps://rr3.googlevideo.com/videoplayback?a=1\n').toString(),
        'https://rr3.googlevideo.com/videoplayback?a=1');
    expect(parseStreamUrl('ERROR: nothing'), isNull);
  });
  test('parseStreamAddress reads the url and the headers of yt-dlp -j', () {
    final a = parseStreamAddress(
        'WARNING: x\n{"url":"https://rr3.googlevideo.com/videoplayback?a=1",'
        '"http_headers":{"User-Agent":"vr/1","Accept-Encoding":"gzip","Accept-Language":"en"}}\n',
        fast: true)!;
    expect(a.uri.host, 'rr3.googlevideo.com');
    expect(a.headers, {'User-Agent': 'vr/1', 'Accept-Language': 'en'});
    expect(a.fast, isTrue);
    // A merged selection keeps the headers of its first format.
    final m = parseStreamAddress('{"requested_formats":[{"url":"https://a.test/x","http_headers":{"User-Agent":"u"}}]}')!;
    expect(m.uri.host, 'a.test');
    expect(m.headers, {'User-Agent': 'u'});
    // Plain `-g` output still works; nothing gives null.
    expect(parseStreamAddress('https://a.test/y')!.headers, isEmpty);
    expect(parseStreamAddress('ERROR: nothing'), isNull);
  });

}
