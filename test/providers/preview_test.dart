import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/providers/preview_providers.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backend.dart';

class _ActiveJam extends JamController {
  @override
  JamUiState build() => const JamUiState(phase: JamPhase.active, role: JamRole.host);
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late AppDatabase db;
  late FakeBackend main;
  late CodecoreAudioHandler handler;
  late List<FakeBackend> previews;
  late ProviderContainer c;
  late List<int> ids;

  ProviderContainer container({bool jam = false}) => ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        audioHandlerProvider.overrideWithValue(handler),
        previewBackendFactoryProvider.overrideWithValue(() {
          final b = FakeBackend();
          previews.add(b);
          return b;
        }),
        if (jam) jamProvider.overrideWith(_ActiveJam.new),
      ]);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    main = FakeBackend();
    previews = [];
    for (final n in ['a', 'b', 'c']) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
            path: '/m/$n.mp3',
            title: n,
            albumKey: 'k',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1,
            durationMs: const Value(90000),
          ));
    }
    ids = (await db.select(db.tracks).get()).map((t) => t.id).toList();
    handler = CodecoreAudioHandler(main, PlayQueue(), TrackRepository(db),
        onError: (_) {});
    c = container();
    c.listen(previewProvider, (_, _) {});
  });
  tearDown(() async {
    c.dispose();
    await handler.dispose();
    await db.close();
  });

  Future<Track> track(int id) async => (await TrackRepository(db).getById(id))!;

  test('the main player pauses while previewing and plays again after', () async {
    await handler.playQueue(ids, 0);
    expect(handler.isPlaying, isTrue);
    await c.read(previewProvider.notifier).start(await track(ids[2]));
    await settle();
    expect(handler.isPlaying, isFalse);
    expect(previews.single.loaded, ['/m/c.mp3']);
    expect(c.read(previewProvider).trackId, ids[2]);

    await c.read(previewProvider.notifier).stop();
    await settle();
    expect(c.read(previewProvider).active, isFalse);
    expect(handler.isPlaying, isTrue, reason: 'it was playing before');
  });

  test('if the main player was paused it stays paused', () async {
    await handler.playQueue(ids, 0);
    await handler.pause();
    await settle();
    await c.read(previewProvider.notifier).start(await track(ids[1]));
    await settle();
    await c.read(previewProvider.notifier).stop();
    await settle();
    expect(handler.isPlaying, isFalse);
  });

  test('the queue, the current track and the play counts do not change', () async {
    await handler.playQueue(ids, 1);
    final queue = List.of(handler.queueIds);
    final index = handler.currentIndex;
    final current = handler.currentTrack!.id;
    await c.read(previewProvider.notifier).start(await track(ids[0]));
    await settle();
    await c.read(previewProvider.notifier).stop();
    await settle();
    expect(handler.queueIds, queue);
    expect(handler.currentIndex, index);
    expect(handler.currentTrack!.id, current);
    expect((await track(ids[0])).playCount, 0);
    expect(main.loaded, ['/m/b.mp3'], reason: 'the main player loaded nothing else');
  });

  test('previewing another track while one plays keeps a single resume', () async {
    await handler.playQueue(ids, 0);
    final n = c.read(previewProvider.notifier);
    await n.start(await track(ids[1]));
    await n.start(await track(ids[2]));
    await settle();
    expect(handler.isPlaying, isFalse);
    await n.stop();
    await settle();
    expect(handler.isPlaying, isTrue);
  });

  test('the preview ending by itself gives the music back', () async {
    await handler.playQueue(ids, 0);
    await c.read(previewProvider.notifier).start(await track(ids[1]));
    previews.single.stateC.add(BackendState.completed);
    await settle();
    expect(c.read(previewProvider).active, isFalse);
    expect(handler.isPlaying, isTrue);
  });

  test('no preview during a Jam', () async {
    final jam = container(jam: true);
    addTearDown(jam.dispose);
    jam.listen(previewProvider, (_, _) {});
    await handler.playQueue(ids, 0);
    await jam.read(previewProvider.notifier).start(await track(ids[1]));
    await settle();
    expect(previews, isEmpty);
    expect(handler.isPlaying, isTrue, reason: 'left alone');
  });

  test('a preview that cannot start leaves the music playing', () async {
    final bad = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      audioHandlerProvider.overrideWithValue(handler),
      previewBackendFactoryProvider
          .overrideWithValue(() => FakeBackend()..failing.add('/m/b.mp3')),
    ]);
    addTearDown(bad.dispose);
    bad.listen(previewProvider, (_, _) {});
    await handler.playQueue(ids, 0);
    await bad.read(previewProvider.notifier).start(await track(ids[1]));
    await settle();
    expect(handler.isPlaying, isTrue);
  });
}
