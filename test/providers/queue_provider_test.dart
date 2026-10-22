import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/online_entries.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/audio/stream_address_cache.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backend.dart';

void main() {
  late AppDatabase db;
  late OnlineEntries online;
  late CodecoreAudioHandler handler;
  late ProviderContainer c;
  late List<int> ids;
  late int onlineId;

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
      addresses: StreamAddressCache(
        (r) async => Uri.parse('https://stream.test/${r.id}'),
      ),
    );
    ids = [
      for (final n in ['a', 'b', 'c'])
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                path: '/m/$n.mp3',
                title: 'Song $n',
                albumKey: 'k',
                format: 'mp3',
                sizeBytes: 1,
                mtimeMs: 1,
                addedAt: 1,
              ),
            ),
    ];
    onlineId = online.register(
      const YtResult(
        id: 'v1',
        title: 'Streamed',
        channel: 'Chan',
        duration: null,
        artists: ['Ann'],
      ),
    );
    c = ProviderContainer(
      overrides: [
        audioHandlerProvider.overrideWithValue(handler),
        trackRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });
  tearDown(() async {
    c.dispose();
    await handler.dispose();
    await db.close();
  });

  test(
    'the queue lists an online entry in its position with its title',
    () async {
      await handler.playQueue([ids[0], onlineId, ids[1], ids[2]], 0);
      c.listen(queueProvider, (_, _) {});
      final queue = await c.read(queueProvider.future);
      expect(
        [for (final t in queue) t.title],
        ['Song a', 'Streamed', 'Song b', 'Song c'],
      );
    },
  );

  test(
    'the current track provider gives the synthetic track for an online id',
    () async {
      await handler.playQueue([onlineId, ids[0]], 0);
      c.listen(currentTrackProvider, (_, _) {});
      c.listen(liveCurrentTrackProvider, (_, _) {});
      await pumpEventQueue();
      final t = await c.read(liveCurrentTrackProvider.future);
      expect(t?.id, onlineId);
      expect(t?.title, 'Streamed');
    },
  );

  test('the Jam seed leaves online entries out', () async {
    await handler.playQueue([ids[0], onlineId, ids[1]], 0);
    final seed = await jamSeedTracks(handler, TrackRepository(db));
    expect([for (final t in seed) t.title], ['Song a', 'Song b']);
  });
}
