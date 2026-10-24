// Characterization (38.5): the «ask for a name» dialog exists as three
// implementations (F-06), and the call sites listed in analisi.md F-06 use
// them: askPlaylistName (playlist_dialogs.dart:66, desktop_sidebar.dart:220,
// playlist_picker.dart:32, playlists_screen.dart:38) and askTagName
// (tags_screen.dart:38, tags_sheet.dart:196,287); the third is the private
// rename dialog of radio_station_sheet.dart:57. Their rules differ today; the
// differences are pinned here so a shared promptName() chooses them on purpose.
import 'package:codecore/data/repositories/radio_repository.dart';
import 'package:codecore/providers/radio_providers.dart';
import 'package:codecore/services/radio/radio_station.dart';
import 'package:codecore/ui/screens/playlists/playlist_dialogs.dart';
import 'package:codecore/ui/screens/radio/radio_station_sheet.dart';
import 'package:codecore/ui/screens/tags/tags_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

class _RecordingRadio extends RadioRepository {
  _RecordingRadio(super.db);
  final renamed = <String>[];
  @override
  Future<void> rename(String id, String name) async => renamed.add(name);
}

class _Run {
  String? result;
  bool done = false;
}

Future<(Harness, _Run)> _open(
  WidgetTester tester,
  Future<String?> Function(BuildContext) ask,
) async {
  final h = await Harness.create(tester);
  final run = _Run();
  await h.pump(
    tester,
    Builder(
      builder: (c) => Scaffold(
        body: TextButton(
          onPressed: () async {
            run.result = await ask(c);
            run.done = true;
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump(const Duration(milliseconds: 400));
  return (h, run);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 400));
}

TextField _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  group('askPlaylistName', () {
    testWidgets(
      'title «Nuova playlist», confirm «Crea», 60 characters, no capitalisation hint',
      (tester) async {
        final (h, _) = await _open(tester, askPlaylistName);
        expect(find.text('Nuova playlist'), findsOneWidget);
        expect(find.text('Crea'), findsOneWidget);
        expect(_field(tester).maxLength, 60);
        expect(_field(tester).textCapitalization, TextCapitalization.none);
        expect(_field(tester).decoration?.hintText, 'Nome della playlist');
        await h.dispose(tester);
      },
    );

    testWidgets('the name is trimmed', (tester) async {
      final (h, run) = await _open(tester, askPlaylistName);
      await _type(tester, '  Mix  ');
      await _tap(tester, 'Crea');
      expect(run.result, 'Mix');
      await h.dispose(tester);
    });

    testWidgets(
      'a blank name does nothing: the dialog stays open (the tag dialog closes instead)',
      (tester) async {
        final (h, run) = await _open(tester, askPlaylistName);
        await _type(tester, '   ');
        await _tap(tester, 'Crea');
        expect(run.done, isFalse);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(
          run.done,
          isFalse,
          reason: 'the keyboard submit follows the same rule',
        );
        await h.dispose(tester);
      },
    );

    testWidgets('longer than 60 characters is cut at 60', (tester) async {
      final (h, run) = await _open(tester, askPlaylistName);
      await _type(tester, 'a' * 80);
      await _tap(tester, 'Crea');
      expect(run.result, 'a' * 60);
      await h.dispose(tester);
    });

    testWidgets(
      '«Annulla» returns null; initial text and labels are taken as given',
      (tester) async {
        final (h, run) = await _open(
          tester,
          (c) => askPlaylistName(
            c,
            initial: 'Old',
            title: 'Rinomina',
            confirmLabel: 'Salva',
          ),
        );
        expect(find.text('Rinomina'), findsOneWidget);
        expect(find.text('Old'), findsOneWidget);
        await _tap(tester, 'Annulla');
        expect(run.done, isTrue);
        expect(run.result, isNull);
        await h.dispose(tester);
      },
    );
  });

  group('askTagName', () {
    testWidgets(
      'title «Nuova etichetta», confirm «Salva», 40 characters, sentence capitalisation',
      (tester) async {
        final (h, _) = await _open(tester, askTagName);
        expect(find.text('Nuova etichetta'), findsOneWidget);
        expect(find.text('Salva'), findsOneWidget);
        expect(_field(tester).maxLength, 40);
        expect(_field(tester).textCapitalization, TextCapitalization.sentences);
        expect(
          _field(tester).decoration?.hintText,
          isNull,
          reason: 'the tag dialog has no hint',
        );
        await h.dispose(tester);
      },
    );

    testWidgets('the name is trimmed', (tester) async {
      final (h, run) = await _open(tester, askTagName);
      await _type(tester, '  Gym  ');
      await _tap(tester, 'Salva');
      expect(run.result, 'Gym');
      await h.dispose(tester);
    });

    testWidgets(
      'a blank name closes the dialog with null (the playlist dialog stays open instead)',
      (tester) async {
        final (h, run) = await _open(tester, askTagName);
        await _type(tester, '   ');
        await _tap(tester, 'Salva');
        expect(run.done, isTrue);
        expect(run.result, isNull);
        expect(find.byType(AlertDialog), findsNothing);
        await h.dispose(tester);
      },
    );

    testWidgets('keyboard submit trims, like the button', (tester) async {
      final (h, run) = await _open(tester, askTagName);
      await _type(tester, ' Gym ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));
      expect(run.result, 'Gym');
      await h.dispose(tester);
    });

    testWidgets('keyboard submit of a blank name closes the dialog with null', (
      tester,
    ) async {
      final (h, run) = await _open(tester, askTagName);
      await _type(tester, '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));
      expect(run.done, isTrue);
      expect(run.result, isNull);
      expect(find.byType(AlertDialog), findsNothing);
      await h.dispose(tester);
    });

    testWidgets('longer than 40 characters is cut at 40', (tester) async {
      final (h, run) = await _open(tester, askTagName);
      await _type(tester, 'b' * 60);
      await _tap(tester, 'Salva');
      expect(run.result, 'b' * 40);
      await h.dispose(tester);
    });

    testWidgets(
      '«Annulla» returns null; initial and title are taken as given',
      (tester) async {
        final (h, run) = await _open(
          tester,
          (c) => askTagName(c, initial: 'Old', title: 'Rinomina'),
        );
        expect(find.text('Rinomina'), findsOneWidget);
        expect(find.text('Old'), findsOneWidget);
        await _tap(tester, 'Annulla');
        expect(run.result, isNull);
        await h.dispose(tester);
      },
    );
  });

  group('radio rename (private dialog of the station sheet)', () {
    // The dialog sends the raw text; the repository is what trims and ignores
    // a blank (RadioRepository.rename), so the repository is recorded here.
    Future<(Harness, _RecordingRadio)> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester);
      final repo = _RecordingRadio(h.db);
      const station = RadioStation(
        id: 'r1',
        name: 'Radio Uno',
        streamUrl: 'https://x/s',
      );
      await tester.runAsync(() => repo.save(station));
      await h.pump(
        tester,
        const Scaffold(body: RadioStationSheet(station: station)),
        extraOverrides: [radioRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Rinomina'));
      await tester.pump(const Duration(milliseconds: 400));
      return (h, repo);
    }

    testWidgets('the button sends the text as typed: no trim', (tester) async {
      final (h, repo) = await open(tester);
      await _type(tester, '  x  ');
      await _tap(tester, 'Salva');
      expect(repo.renamed, ['  x  ']);
      await h.dispose(tester);
    });

    testWidgets('a blank name is accepted and sent', (tester) async {
      final (h, repo) = await open(tester);
      await _type(tester, '   ');
      await _tap(tester, 'Salva');
      expect(repo.renamed, ['   ']);
      await h.dispose(tester);
    });

    testWidgets('no length limit: 100 characters pass', (tester) async {
      final (h, repo) = await open(tester);
      expect(_field(tester).maxLength, isNull);
      await _type(tester, 'c' * 100);
      await _tap(tester, 'Salva');
      expect(repo.renamed, ['c' * 100]);
      await h.dispose(tester);
    });

    testWidgets('keyboard submit sends the raw value', (tester) async {
      final (h, repo) = await open(tester);
      await _type(tester, ' y ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.renamed, [' y ']);
      await h.dispose(tester);
    });

    testWidgets('«Annulla» sends nothing', (tester) async {
      final (h, repo) = await open(tester);
      await _tap(tester, 'Annulla');
      expect(repo.renamed, isEmpty);
      await h.dispose(tester);
    });
  });
}
