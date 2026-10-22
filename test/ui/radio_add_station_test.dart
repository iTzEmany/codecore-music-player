import 'package:codecore/data/repositories/radio_repository.dart';
import 'package:codecore/providers/radio_providers.dart';
import 'package:codecore/ui/screens/radio/add_station_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late Harness h;
  Future<String> Function(Uri) fetch = (_) async => '';

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, radio: true);
    await h.pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => AddStationDialog.show(context),
              child: const Text('apri'),
            ),
          ),
        ),
      ),
      extraOverrides: [playlistFetchProvider.overrideWithValue((u) => fetch(u))],
    );
    await tester.tap(find.text('apri'));
    await _settle(tester);
  }

  Future<void> trySave(WidgetTester tester, String url) async {
    await tester.enterText(find.byKey(const ValueKey('radio-add-url')), url);
    await tester.tap(find.byKey(const ValueKey('radio-add-save')));
    await _settle(tester);
  }

  final cases = <(String, String, String, Future<String> Function(Uri)?)>[
    ('empty', '', 'Scrivi l\'indirizzo dello stream', null),
    ('not an address', 'radio105', 'Non sembra un indirizzo: scrivilo per intero, per esempio https://…', null),
    ('wrong scheme', 'ftp://radio.test/live', 'L\'indirizzo deve iniziare con http:// o https://', null),
    ('playlist without entries', 'http://radio.test/x.pls', 'Nel file non c\'è nessun indirizzo da ascoltare',
        (_) async => '[playlist]\nNumberOfEntries=0\n'),
    ('playlist too big', 'http://radio.test/x.m3u', 'Il file è troppo grande per essere una lista di radio',
        (_) async => 'x' * 70000),
    ('playlist not downloadable', 'http://radio.test/x.m3u', 'Non riesco a scaricare il file',
        (_) async => throw Exception('404')),
  ];
  for (final (name, url, message, fetcher) in cases) {
    testWidgets('validation: $name', (tester) async {
      fetch = fetcher ?? (_) async => '';
      await open(tester);
      await trySave(tester, url);
      expect(find.text(message), findsOneWidget);
      expect(await tester.runAsync(RadioRepository(h.db).getAll), isEmpty);
      await h.dispose(tester);
    });
  }

  testWidgets('a playlist address is read and the first stream is saved by hand', (tester) async {
    fetch = (_) async => '#EXTM3U\n# comment\nhttp://stream.test/live.mp3\n';
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('radio-add-name')), 'La mia radio');
    await trySave(tester, 'http://radio.test/x.m3u');
    final saved = (await tester.runAsync(RadioRepository(h.db).getAll))!;
    expect(saved.single.name, 'La mia radio');
    expect(saved.single.streamUrl, 'http://stream.test/live.mp3');
    expect(saved.single.stationId, startsWith('manual:'));
    expect(find.byType(AlertDialog), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('«Prova» plays the address for the set time and then pauses', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('radio-add-url')), 'http://stream.test/live');
    await tester.tap(find.byKey(const ValueKey('radio-add-test')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(h.backend.loadedUris.single.uri.toString(), 'http://stream.test/live');
    expect(find.textContaining('Provo'), findsOneWidget);
    expect(h.backend.playing, isTrue);
    await tester.pump(const Duration(seconds: 11));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    expect(h.backend.playing, isFalse);
    expect(find.textContaining('Provo'), findsNothing);
    await h.dispose(tester);
  });
}
