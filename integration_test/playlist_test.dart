import 'package:codecore/providers/database_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create, add three tracks, reorder, rename, delete; the data survives a restart of the scope', (tester) async {
    final app = await AppUnderTest.create();
    await app.launch(tester);
    await tester.runAsync(() => app.addMusicFolder(tester));
    await settle(tester);

    var repo = app.container(tester).read(playlistRepositoryProvider);
    final tracks = (await tester.runAsync(() => app.db.select(app.db.tracks).get()))!
      ..sort((a, b) => a.title.compareTo(b.title));
    final id = (await tester.runAsync(() => repo.create('Giro')))!;
    expect(await tester.runAsync(() => repo.addTracks(id, [tracks[0].id, tracks[1].id, tracks[2].id])), 3);
    await tester.runAsync(() => repo.reorder(id, 0, 2)); // B, C, A
    await tester.runAsync(() => repo.rename(id, 'Giro 2'));

    await app.restart(tester);
    repo = app.container(tester).read(playlistRepositoryProvider);
    final summary = (await tester.runAsync(() => repo.watchAll().first))!.single;
    expect(summary.playlist.name, 'Giro 2');
    final order = (await tester.runAsync(() => repo.watchTracks(id).first))!.map((t) => t.title).toList();
    expect(order, [tracks[1].title, tracks[2].title, tracks[0].title]);

    await tester.runAsync(() => repo.delete(id));
    expect(await tester.runAsync(() => repo.watchAll().first), isEmpty);
    expect((await tester.runAsync(() => app.db.select(app.db.tracks).get()))!, hasLength(4), reason: 'the tracks stay');
    await app.dispose(tester);
  });
}
