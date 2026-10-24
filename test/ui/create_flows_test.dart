import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/ui/widgets/create_flows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<Harness> _open(WidgetTester tester, Future<void> Function(BuildContext, WidgetRef) run) async {
  final h = await Harness.create(tester);
  await h.pump(
    tester,
    Consumer(
      builder: (c, ref, _) => Scaffold(
        body: TextButton(onPressed: () => run(c, ref), child: const Text('open')),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump(const Duration(milliseconds: 400));
  return h;
}

Future<void> _submit(WidgetTester tester, String text, String button) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.text(button));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('createPlaylistFlow creates the trimmed name; cancel creates nothing', (tester) async {
    final h = await _open(tester, (c, ref) => createPlaylistFlow(c, ref));
    await _submit(tester, '  Mix  ', 'Crea');
    expect((await h.db.select(h.db.playlists).get()).map((p) => p.name), contains('Mix'));
    final before = (await h.db.select(h.db.playlists).get()).length;
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Annulla'));
    await tester.pump(const Duration(milliseconds: 400));
    expect((await h.db.select(h.db.playlists).get()).length, before);
    await h.dispose(tester);
  });

  testWidgets('createTagFlow creates the tag; cancel creates nothing', (tester) async {
    UserTag? made;
    final h = await _open(tester, (c, ref) async => made = await createTagFlow(c, ref));
    await _submit(tester, ' Rock ', 'Salva');
    expect(made?.name, 'Rock');
    expect(await h.db.select(h.db.userTags).get(), hasLength(1));
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Annulla'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(await h.db.select(h.db.userTags).get(), hasLength(1));
    await h.dispose(tester);
  });
}
