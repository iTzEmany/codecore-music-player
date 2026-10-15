import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  test('rotateQueueFromCurrent keeps every track, starting at the current', () {
    expect(rotateQueueFromCurrent([1, 2, 3, 4], 0), [1, 2, 3, 4]);
    expect(rotateQueueFromCurrent([1, 2, 3, 4], 2), [3, 4, 1, 2]);
    expect(rotateQueueFromCurrent([1, 2], -1), [1, 2]);
    expect(rotateQueueFromCurrent([1, 2], 5), [1, 2]);
    expect(rotateQueueFromCurrent(const [], 0), isEmpty);
  });

  testWidgets('the Jam starts with what was queued on the host',
      (tester) async {
    final h = await Harness.create(tester, tracks: 4);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    final ids = [for (final t in rows!) t.id];
    await tester.runAsync(() => h.handler.playQueue(ids, 2));
    final seed = await tester.runAsync(
        () => jamSeedTracks(h.handler, TrackRepository(h.db)));
    expect([for (final t in seed!) t.title],
        ['Song 2', 'Song 3', 'Song 0', 'Song 1']);
    await h.dispose(tester);
  });

  testWidgets('an empty queue seeds nothing', (tester) async {
    final h = await Harness.create(tester, tracks: 2);
    final seed = await tester.runAsync(
        () => jamSeedTracks(h.handler, TrackRepository(h.db)));
    expect(seed, isEmpty);
    await h.dispose(tester);
  });
}
