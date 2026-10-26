import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/credits_repository.dart';
import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/ui/screens/lyrics/lyrics_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/enrich_fakes.dart';

void main() {
  testWidgets(
    'plain lyrics are shown with copy; the stored trivia is not (it lives in Now Playing)',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester, tracks: 1);
      await tester.runAsync(() async {
        await (h.db.update(h.db.tracks)).write(
          const TracksCompanion(
            lyricsPlain: Value('Hello darkness\nmy old friend'),
            curiosities: Value(
              'A famous song.\nhttps://en.wikipedia.org/wiki/X',
            ),
          ),
        );
        final rows = await h.db.select(h.db.tracks).get();
        await h.handler.playQueue([rows.single.id], 0);
      });
      await h.pump(tester, const LyricsScreen());
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Hello darkness'), findsOneWidget);
      // The trivia box left the lyrics page (it lives in Now Playing now).
      expect(find.text('Fonte: Wikipedia (CC BY-SA)'), findsNothing);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      await h.dispose(tester);
    },
  );

  testWidgets('a long synced line is shown in full', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const long =
        'And the signs said the words of the prophets were written '
        'on the subway walls and tenement halls';
    final h = await Harness.create(tester, tracks: 1);
    await tester.runAsync(() async {
      await (h.db.update(h.db.tracks)).write(
        const TracksCompanion(
          lyricsSynced: Value(
            '[00:01.00]Hello\n[00:05.00]$long\n[00:09.00]Bye',
          ),
        ),
      );
      final rows = await h.db.select(h.db.tracks).get();
      await h.handler.playQueue([rows.single.id], 0);
    });
    await h.pump(tester, const LyricsScreen());
    await tester.pump(const Duration(milliseconds: 300));
    final text = tester.widget<Text>(find.text(long));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('searching by hand saves the text as the user\'s own', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 1);
    final chain = FakeChain(EnrichWeb());
    await tester.runAsync(() async {
      await h.handler.playQueue([
        (await h.db.select(h.db.tracks).get()).single.id,
      ], 0);
    });
    await h.pump(
      tester,
      const LyricsScreen(),
      extraOverrides: [lyricsChainProvider.overrideWithValue(chain)],
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Cerca testo'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final (t, e) = (await tester.runAsync(
      () async => (
        (await h.db.select(h.db.tracks).get()).single,
        await CreditsRepository(h.db).enrichOf(1),
      ),
    ))!;
    expect(chain.calls, 1);
    expect(t.lyricsPlain, 'la la');
    expect(e?.lyricsByUser, isTrue);
    await h.dispose(tester);
  });
}
