import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scan: the files of an added folder become tracks in «Tutti i brani»', (tester) async {
    final app = await AppUnderTest.create();
    await tester.runAsync(() async {});
    await app.launch(tester);

    expect(await tester.runAsync(() => app.db.select(app.db.tracks).get()), isEmpty);
    await tester.runAsync(() => app.addMusicFolder(tester));
    await settle(tester);

    final c = app.container(tester);
    final rows = (await tester.runAsync(() => c.read(trackRepositoryProvider).watchTracks().first))!;
    expect(rows, hasLength(AppUnderTest.names.length));
    expect([for (final t in rows) t.title.toLowerCase()],
        unorderedEquals([for (final n in AppUnderTest.names) n.toLowerCase()]));
    expect(rows.every((t) => t.durationMs > 1000), isTrue, reason: 'the real decoder read the length');

    // A second scan finds the same files: still four tracks.
    await tester.runAsync(() => c.read(scanStateProvider.notifier).scanAll());
    final again = (await tester.runAsync(() => c.read(trackRepositoryProvider).watchTracks().first))!;
    expect(again, hasLength(AppUnderTest.names.length));
    await app.dispose(tester);
  });
}
