import 'dart:io';

import 'package:codecore/services/import/exportify_reader.dart';
import 'package:codecore/ui/screens/import/import_intro_sheet.dart';
import 'package:codecore/ui/screens/import/import_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

ExportifyPlaylist fixture() => readExportify('Just_a_mood.csv',
    File('test/fixtures/Just_a_mood.csv').readAsStringSync());

void main() {
  testWidgets('intro sheet says where the CSV comes from and copies the address',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final h = await Harness.create(tester);
    await h.pump(tester, const Scaffold(body: ImportIntroSheet()));

    expect(find.text('Importa una playlist'), findsOneWidget);
    expect(find.textContaining('Exportify — exportify.net'), findsOneWidget);
    expect(find.textContaining('https://exportify.net nel browser'),
        findsOneWidget);
    expect(find.text('Scegli file'), findsOneWidget);

    await tester.tap(find.text('Copia indirizzo'));
    await tester.pump();
    expect(copied, 'https://exportify.net');
    expect(find.text('Indirizzo copiato'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('preview counts what is already in the library', (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(
        tester,
        Scaffold(
            body: ImportPreviewDialog(csv: fixture(), known: 1, existing: const {})));

    expect(find.text('Importa playlist'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Just a mood'), findsOneWidget);
    expect(find.text('34 brani · 1 già in libreria · 33 da scaricare'),
        findsOneWidget);
    expect(find.textContaining('Tempo stimato'), findsOneWidget);
    expect(find.text('Esiste già una playlist con questo nome'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('same-name playlist offers update or new and returns the choice',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    ImportChoice? picked;
    await h.pump(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async => picked = await showDialog<ImportChoice>(
                        context: context,
                        builder: (_) => ImportPreviewDialog(
                            csv: fixture(),
                            known: 0,
                            existing: const {7: 'just a mood'})),
                    child: const Text('open')))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Esiste già una playlist con questo nome'),
        findsOneWidget);
    expect(find.textContaining('Aggiorna quella esistente'), findsOneWidget);
    expect(find.text('Crea una nuova playlist'), findsOneWidget);
    await tester.tap(find.text('Importa'));
    await tester.pumpAndSettle();
    expect(picked!.intoPlaylistId, 7);
    expect(picked!.name, 'Just a mood');

    // Renaming away from the existing one hides the question.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Other name');
    await tester.pump();
    expect(find.text('Esiste già una playlist con questo nome'), findsNothing);
    await tester.tap(find.text('Importa'));
    await tester.pumpAndSettle();
    expect(picked!.intoPlaylistId, isNull);
    await h.dispose(tester);
  });
}
