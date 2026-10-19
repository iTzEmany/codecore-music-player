import 'package:codecore/providers/player_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('play, position advances, next, pause, and the end of a track moves on', (tester) async {
    final app = await AppUnderTest.create(seconds: 2.5);
    await app.launch(tester);
    await tester.runAsync(() => app.addMusicFolder(tester));
    await settle(tester);

    final c = app.container(tester);
    final tracks = (await tester.runAsync(() => app.db.select(app.db.tracks).get()))!
      ..sort((a, b) => a.title.compareTo(b.title));
    final ctrl = c.read(playerControllerProvider);
    await tester.runAsync(() => ctrl.playFromList(tracks, 0));

    await waitFor(tester, () => app.handler.isPlaying, within: const Duration(seconds: 3), reason: 'playing within 3 s');
    expect(app.handler.currentTrack!.id, tracks[0].id);
    final p0 = await app.handler.positionStream.first;
    await settle(tester, by: const Duration(milliseconds: 900));
    final p1 = await app.handler.positionStream.first;
    expect(p1, greaterThan(p0), reason: 'the position moves');

    await tester.runAsync(ctrl.next);
    await waitFor(tester, () => app.handler.currentTrack?.id == tracks[1].id, reason: 'next changes the track');

    await tester.runAsync(app.handler.pause);
    await waitFor(tester, () => !app.handler.isPlaying, reason: 'paused');

    // Let the second track play to its end: the third starts by itself.
    await tester.runAsync(() => app.handler.seek(const Duration(milliseconds: 2000)));
    await tester.runAsync(app.handler.play);
    await waitFor(tester, () => app.handler.currentTrack?.id == tracks[2].id,
        within: const Duration(seconds: 6), reason: 'the queue advances at the end of a track');
    await app.dispose(tester);
  });
}
