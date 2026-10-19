import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/artist_info_repository.dart';
import 'package:codecore/providers/translation_providers.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_cards.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import 'lyrics_translate_test.dart' show FakeTranslator;

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final long = List.generate(30, (i) => 'Frase numero $i del brano.').join(' ');

  Future<(Harness, Track)> open(
    WidgetTester tester, {
    String? songText,
    String? artistText,
    String songWiki = 'it',
    String artistWiki = 'it',
    FakeTranslator? translator,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 1);
    final first = (await tester.runAsync(() => h.db.select(h.db.tracks).getSingle()))!;
    await tester.runAsync(() async {
      await (h.db.update(h.db.tracks)..where((t) => t.id.equals(first.id))).write(
        TracksCompanion(
          artist: const Value('Band'),
          curiosities: Value(songText == null ? null : '$songText\nhttps://$songWiki.wikipedia.org/wiki/Song'),
        ),
      );
      if (artistText != null) {
        await ArtistInfoRepository(h.db).save('Band',
            body: artistText, source: Uri.parse('https://$artistWiki.wikipedia.org/wiki/Band'), lang: artistWiki);
      }
    });
    final track = (await tester.runAsync(() => h.db.select(h.db.tracks).getSingle()))!;
    await h.pump(
      tester,
      Scaffold(body: SingleChildScrollView(child: InfoCard(track: track))),
      extraOverrides: [lyricsTranslatorProvider.overrideWithValue(translator)],
    );
    await _settle(tester);
    return (h, track);
  }

  testWidgets('nothing stored yet: only the search button', (tester) async {
    final (h, _) = await open(tester);
    expect(find.text('Cerca curiosità'), findsOneWidget);
    expect(find.text('Sul brano'), findsNothing);
    expect(find.text('Sull\'artista'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('song and artist each have their own section', (tester) async {
    final (h, _) = await open(tester, songText: 'Testo sul brano', artistText: 'Testo sull artista');
    expect(find.text('Sul brano'), findsOneWidget);
    expect(find.text('Sull\'artista'), findsOneWidget);
    expect(find.textContaining('Testo sul brano'), findsOneWidget);
    expect(find.textContaining('Testo sull artista'), findsOneWidget);
    expect(find.text('Mostra tutto'), findsNothing, reason: 'short text: nothing to expand');
    await h.dispose(tester);
  });

  testWidgets('a long text can be expanded and folded again', (tester) async {
    final (h, _) = await open(tester, songText: long, artistText: 'Nota breve');
    double height() => tester.getSize(find.textContaining('Frase numero 0')).height;
    final folded = height();
    expect(find.text('Mostra tutto'), findsOneWidget);

    await tester.tap(find.text('Mostra tutto'));
    await _settle(tester);
    expect(height(), greaterThan(folded * 2), reason: 'the whole text is shown');
    expect(find.text('Mostra meno'), findsOneWidget);

    await tester.ensureVisible(find.text('Mostra meno'));
    await tester.tap(find.text('Mostra meno'));
    await _settle(tester);
    expect(height(), folded);
    await h.dispose(tester);
  });

  testWidgets('tapping the text itself also expands it', (tester) async {
    final (h, _) = await open(tester, songText: long);
    final folded = tester.getSize(find.textContaining('Frase numero 0')).height;
    await tester.tap(find.textContaining('Frase numero 0'));
    await _settle(tester);
    expect(tester.getSize(find.textContaining('Frase numero 0')).height, greaterThan(folded * 2));
    await h.dispose(tester);
  });

  testWidgets('only the artist found: the song says there is no page, the artist is shown', (tester) async {
    final (h, _) = await open(tester, artistText: 'Testo sull artista');
    expect(find.text('Nessuna pagina dedicata a questo brano'), findsOneWidget);
    expect(find.text('Sull\'artista'), findsOneWidget);
    expect(find.text('Sul brano'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('a text in another language than the app\'s can be translated, and taken back', (tester) async {
    final tr = FakeTranslator();
    final (h, _) = await open(tester, songText: 'The song is about a lady.', songWiki: 'en', translator: tr);
    expect(find.text('Traduci'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('curiosity-translate')));
    await _settle(tester);
    expect(find.text('[it] The song is about a lady.'), findsOneWidget);
    expect(tr.calls.single, ['The song is about a lady.']);
    expect(find.text('Mostra solo l\'originale'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('curiosity-translate')));
    await _settle(tester);
    expect(find.text('The song is about a lady.'), findsOneWidget);
    expect(find.text('Traduci'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('each block of a longer text is translated paragraph by paragraph, blank lines kept', (tester) async {
    final tr = FakeTranslator();
    final (h, _) = await open(tester, songText: 'First paragraph.\nSecond paragraph.', songWiki: 'en', translator: tr);
    await tester.tap(find.byKey(const ValueKey('curiosity-translate')));
    await _settle(tester);
    expect(tr.calls.single, ['First paragraph.', 'Second paragraph.']);
    await h.dispose(tester);
  });

  testWidgets('no button for a text already in the app\'s language, or without a translator', (tester) async {
    final (h, _) = await open(tester, songText: 'Testo italiano.', artistText: 'Artista in inglese.', artistWiki: 'en', translator: FakeTranslator());
    expect(find.byKey(const ValueKey('curiosity-translate')), findsOneWidget, reason: 'only the English artist block');
    await h.dispose(tester);

    final (h2, _) = await open(tester, songText: 'English text.', songWiki: 'en');
    expect(find.byKey(const ValueKey('curiosity-translate')), findsNothing, reason: 'desktop: no translator');
    await h2.dispose(tester);
  });

  testWidgets('a missing model is offered for download first; declining translates nothing', (tester) async {
    final tr = FakeTranslator(ready: {});
    final (h, _) = await open(tester, songText: 'English text.', songWiki: 'en', translator: tr);
    await tester.tap(find.byKey(const ValueKey('curiosity-translate')));
    await _settle(tester);
    expect(find.textContaining('Scaricare il modello'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await _settle(tester);
    expect(tr.calls, isEmpty);
    expect(tr.downloads, isEmpty);
    expect(find.byKey(const ValueKey('curiosity-translate')), findsOneWidget, reason: 'the button comes back');

    await tester.tap(find.byKey(const ValueKey('curiosity-translate')));
    await _settle(tester);
    await tester.tap(find.text('Scarica')); // the text's language
    await _settle(tester);
    await tester.tap(find.text('Scarica')); // then the app's
    await _settle(tester);
    expect(tr.downloads, ['en', 'it']);
    expect(find.text('[it] English text.'), findsOneWidget);
    await h.dispose(tester);
  });

  test('the language of a Wikipedia address', () {
    expect(wikiLangOf('https://en.wikipedia.org/wiki/X'), 'en');
    expect(wikiLangOf('https://pt-br.wikipedia.org/wiki/X'), 'pt-br');
    expect(wikiLangOf('https://example.org/wiki/X'), isNull);
    expect(wikiLangOf(null), isNull);
    expect(wikiLangOf('not a url'), isNull);
  });
}
