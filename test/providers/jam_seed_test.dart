import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backend.dart';

void main() {
  test('rotateQueueFromCurrent keeps every track, starting at the current', () {
    expect(rotateQueueFromCurrent([1, 2, 3, 4], 0), [1, 2, 3, 4]);
    expect(rotateQueueFromCurrent([1, 2, 3, 4], 2), [3, 4, 1, 2]);
    expect(rotateQueueFromCurrent([1, 2], -1), [1, 2]);
    expect(rotateQueueFromCurrent([1, 2], 5), [1, 2]);
    expect(rotateQueueFromCurrent(const [], 0), isEmpty);
  });

  test('the Jam starts with what was queued on the host; an empty queue seeds nothing',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = TrackRepository(db);
    final handler =
        CodecoreAudioHandler(FakeBackend(), PlayQueue(), repo, onError: (_) {});
    addTearDown(handler.dispose);
    final ids = [
      for (var i = 0; i < 4; i++)
        await db.into(db.tracks).insert(TracksCompanion.insert(
              path: '/m/t$i.mp3',
              title: 'Song $i',
              albumKey: 'k',
              format: 'mp3',
              sizeBytes: 1,
              mtimeMs: 1,
              addedAt: i,
            )),
    ];

    expect(await jamSeedTracks(handler, repo), isEmpty);

    await handler.playQueue(ids, 2);
    final seed = await jamSeedTracks(handler, repo);
    expect([for (final t in seed) t.title],
        ['Song 2', 'Song 3', 'Song 0', 'Song 1']);
  });
}
