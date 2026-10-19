import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/translation_providers.dart';
import 'package:codecore/services/online/lyrics_translator.dart';
import 'package:codecore/ui/screens/lyrics/lyrics_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

class FakeTranslator implements LyricsTranslator {
  FakeTranslator({Set<String>? ready}) : ready = ready ?? {'en', 'it'};

  final Set<String> ready;
  final downloads = <String>[];
  final calls = <List<String>>[];
  bool closed = false;

  @override
  Future<bool> isModelReady(String lang) async => ready.contains(lang);

  @override
  Future<void> downloadModel(String lang) async {
    downloads.add(lang);
    ready.add(lang);
  }

  @override
  Future<void> deleteModel(String lang) async => ready.remove(lang);

  @override
  Future<List<String>> translateLines(
    List<String> lines, {
    required String from,
    required String to,
  }) async {
    calls.add(lines);
    return [for (final l in lines) '[$to] $l'];
  }

  @override
  Future<void> close() async => closed = true;
}

void main() {
  group('translateKeepingLayout', () {
    test('blank and symbol-only lines pass through, order is kept', () async {
      final t = FakeTranslator();
      final out = await translateKeepingLayout(
        t,
        ['Hello', '', '♪', '  World  '],
        from: 'en',
        to: 'it',
      );
      expect(out, ['[it] Hello', '', '♪', '[it] World']);
      expect(t.calls.single, ['Hello', 'World']);
    });

    test('same language returns the input without calling the model', () async {
      final t = FakeTranslator();
      final out = await translateKeepingLayout(t, ['a'], from: 'it', to: 'it');
      expect(out, ['a']);
      expect(t.calls, isEmpty);
    });

    test('nothing to translate does not call the model', () async {
      final t = FakeTranslator();
      final out = await translateKeepingLayout(
        t,
        ['', '♪'],
        from: 'en',
        to: 'it',
      );
      expect(out, ['', '♪']);
      expect(t.calls, isEmpty);
    });

    test('a translator that drops lines is an error', () async {
      final t = _ShortTranslator();
      expect(
        translateKeepingLayout(t, ['a', 'b'], from: 'en', to: 'it'),
        throwsStateError,
      );
    });

    test('supported language list has the six app languages', () {
      for (final c in ['it', 'en', 'de', 'es', 'fr', 'pt']) {
        expect(translationLanguages, contains(c));
      }
    });
  });

  testWidgets('no translator (desktop): no translate button', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 1);
    await tester.runAsync(() async {
      await (h.db.update(h.db.tracks))
          .write(const TracksCompanion(lyricsPlain: Value('Hello')));
      final rows = await h.db.select(h.db.tracks).get();
      await h.handler.playQueue([rows.single.id], 0);
    });
    await h.pump(tester, const LyricsScreen());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.g_translate_rounded), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('translated lines sit under the timed originals', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeTranslator();
    final h = await Harness.create(tester, tracks: 1);
    await tester.runAsync(() async {
      await (h.db.update(h.db.tracks)).write(
        const TracksCompanion(
          lyricsSynced: Value('[00:01.00]Hello\n[00:05.00]\n[00:09.00]Bye'),
        ),
      );
      final rows = await h.db.select(h.db.tracks).get();
      await h.handler.playQueue([rows.single.id], 0);
    });
    await h.pump(
      tester,
      const LyricsScreen(),
      extraOverrides: [lyricsTranslatorProvider.overrideWithValue(fake)],
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byIcon(Icons.g_translate_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, 'Traduci'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('translated-0')), findsOneWidget);
    expect(find.text('[it] Hello'), findsOneWidget);
    expect(find.text('[it] Bye'), findsOneWidget);
    expect(find.byKey(const ValueKey('translated-1')), findsNothing);
    expect(fake.downloads, isEmpty);
    // Tapping again removes the translation.
    await tester.tap(find.byIcon(Icons.translate_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('[it] Hello'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('a missing model asks before downloading', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeTranslator(ready: {'it'});
    final h = await Harness.create(tester, tracks: 1);
    await tester.runAsync(() async {
      await (h.db.update(h.db.tracks))
          .write(const TracksCompanion(lyricsPlain: Value('Hello there')));
      final rows = await h.db.select(h.db.tracks).get();
      await h.handler.playQueue([rows.single.id], 0);
    });
    await h.pump(
      tester,
      const LyricsScreen(),
      extraOverrides: [lyricsTranslatorProvider.overrideWithValue(fake)],
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byIcon(Icons.g_translate_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, 'Traduci'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Scaricare il modello'), findsOneWidget);
    expect(fake.downloads, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Scarica'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(fake.downloads, ['en']);
    expect(find.byKey(const ValueKey('translated-plain')), findsOneWidget);
    expect(find.text('[it] Hello there'), findsOneWidget);
    await h.dispose(tester);
  });
}

class _ShortTranslator extends FakeTranslator {
  @override
  Future<List<String>> translateLines(
    List<String> lines, {
    required String from,
    required String to,
  }) async => [lines.first];
}
