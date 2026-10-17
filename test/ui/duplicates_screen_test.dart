import 'dart:async';
import 'dart:io';

import 'package:codecore/providers/duplicate_providers.dart';
import 'package:codecore/services/library/duplicate_cleanup.dart';
import 'package:codecore/services/library/duplicate_finder.dart';
import 'package:codecore/ui/screens/cleanup/duplicates_screen.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Real file IO only moves while real time passes: settle until [finder] shows.
Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await _settle(tester);
  }
}

void main() {
  late Harness h;
  late Directory dir;
  late List<String> paths;

  /// Three tracks as real 1-byte files; Song 0 and Song 1 get the same hash.
  Future<void> open(WidgetTester tester, {FileHasherFn? fakeHasher, FileDeleter? deleter}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, tracks: 3);
    dir = Directory.systemTemp.createTempSync('dupui');
    addTearDown(() => dir.deleteSync(recursive: true));
    paths = [for (var i = 0; i < 3; i++) p.join(dir.path, 'f$i.mp3')];
    await tester.runAsync(() async {
      for (var i = 0; i < 3; i++) {
        File(paths[i]).writeAsBytesSync([i]);
        await h.db.customUpdate('UPDATE tracks SET path = ? WHERE title = ?',
            variables: [Variable<String>(paths[i]), Variable<String>('Song $i')]);
      }
    });
    final useHasher = fakeHasher ?? (path) async => path == paths[2] ? 'other' : 'same';
    await h.pump(tester, const DuplicatesScreen(), extraOverrides: [
      duplicateHasherProvider.overrideWithValue(useHasher),
      duplicateDeleterProvider.overrideWithValue(deleter),
      duplicateGrouperProvider.overrideWithValue((lib, hashes) async => findDuplicates(lib, hashes: hashes)),
    ]);
  }

  testWidgets('before searching: the explanation and the search button', (tester) async {
    await open(tester);
    expect(find.text('Duplicati'), findsOneWidget);
    expect(find.textContaining('Nessun file viene cancellato senza una doppia conferma'), findsOneWidget);
    expect(find.text('Cerca duplicati'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('a search shows the identical group with the proposed track marked', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cerca duplicati'));
    await _settle(tester);

    expect(find.text('Identici'), findsOneWidget);
    expect(find.text('Da tenere'), findsOneWidget);
    expect(find.textContaining('1 gruppo'), findsOneWidget);
    expect(find.text(paths[0]), findsOneWidget);
    expect(find.text(paths[1]), findsOneWidget);
    expect(find.text(paths[2]), findsNothing, reason: 'a different hash is no duplicate');
    await h.dispose(tester);
  });

  testWidgets('tapping another track changes which one is kept', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cerca duplicati'));
    await _settle(tester);
    final other = ProviderScope.containerOf(tester.element(find.byType(DuplicatesScreen)))
        .read(duplicateSearchProvider)
        .groups
        .single
        .members
        .last;

    await tester.tap(find.byKey(ValueKey('dup-member-${other.id}')));
    await tester.pump();
    await tester.tap(find.text('Unisci'));
    await _settle(tester);

    final ignored = await tester.runAsync(() => h.db.customSelect('SELECT id FROM tracks WHERE ignored = 1').get());
    expect(ignored!.map((r) => r.data['id']), isNot(contains(other.id)));
    expect(ignored, hasLength(1));
    expect(find.text('Identici'), findsNothing, reason: 'the merged group is gone');
    await h.dispose(tester);
  });

  testWidgets('«Non sono duplicati» removes the group and it stays away on the next search', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cerca duplicati'));
    await _settle(tester);
    await tester.tap(find.text('Non sono duplicati'));
    await _settle(tester);
    expect(find.text('Nessun duplicato trovato'), findsOneWidget);

    await tester.tap(find.text('Cerca di nuovo'));
    await _settle(tester);
    expect(find.text('Nessun duplicato trovato'), findsOneWidget);
    final hidden = await tester.runAsync(() => h.db.customSelect('SELECT COUNT(*) AS n FROM tracks WHERE ignored = 1').getSingle());
    expect(hidden!.data['n'], 0, reason: 'nothing was merged');
    await h.dispose(tester);
  });

  testWidgets('«Unisci tutti gli identici» asks first, then hides the copies', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cerca duplicati'));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('merge-all-exact')));
    await _settle(tester);
    expect(find.text('Unire tutti gli identici?'), findsOneWidget);
    expect(find.textContaining('1 gruppo, 1 brano nascosto'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await _settle(tester);
    var n = await tester.runAsync(() => h.db.customSelect('SELECT COUNT(*) AS n FROM tracks WHERE ignored = 1').getSingle());
    expect(n!.data['n'], 0, reason: 'cancelled: nothing merged');

    await tester.tap(find.byKey(const ValueKey('merge-all-exact')));
    await _settle(tester);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Unisci')));
    await _settle(tester);
    n = await tester.runAsync(() => h.db.customSelect('SELECT COUNT(*) AS n FROM tracks WHERE ignored = 1').getSingle());
    expect(n!.data['n'], 1);
    await h.dispose(tester);
  });

  testWidgets('deleting the files needs two confirmations; backing out of either deletes nothing', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cerca duplicati'));
    await _settle(tester);
    await tester.tap(find.text('Unisci'));
    await _settle(tester);
    final gone = ProviderScope.containerOf(tester.element(find.byType(DuplicatesScreen)))
        .read(duplicateSearchProvider)
        .merged
        .single
        .dropped
        .single
        .path;
    final kept = ProviderScope.containerOf(tester.element(find.byType(DuplicatesScreen)))
        .read(duplicateSearchProvider)
        .merged
        .single
        .keeper
        .path;
    expect(find.textContaining('Elimina anche i file (1,'), findsOneWidget);

    // First dialog: the path is listed; «Annulla» deletes nothing.
    await tester.tap(find.byKey(const ValueKey('delete-files')));
    await _settle(tester);
    expect(find.text('Eliminare questi file?'), findsOneWidget);
    expect(find.text(gone), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await _settle(tester);
    expect(File(gone).existsSync(), isTrue);

    // Second dialog: reached only through «Continua»; «Annulla» deletes nothing.
    await tester.tap(find.byKey(const ValueKey('delete-files')));
    await _settle(tester);
    await tester.tap(find.text('Continua'));
    await _settle(tester);
    expect(find.text('Eliminare definitivamente 1 file?'), findsOneWidget);
    expect(File(gone).existsSync(), isTrue, reason: 'still there after the first «Continua»');
    await tester.tap(find.text('Annulla'));
    await _settle(tester);
    expect(File(gone).existsSync(), isTrue);

    // Both confirmed: only the duplicate goes, the kept file stays.
    await tester.tap(find.byKey(const ValueKey('delete-files')));
    await _settle(tester);
    await tester.tap(find.text('Continua'));
    await _settle(tester);
    await tester.tap(find.text('Elimina definitivamente'));
    await _until(tester, find.text('1 file eliminato (1 B).'));
    expect(find.text('1 file eliminato (1 B).'), findsOneWidget);
    expect(File(gone).existsSync(), isFalse);
    expect(File(kept).existsSync(), isTrue);
    await tester.tap(find.text('Chiudi'));
    await _settle(tester);
    final rows = await tester.runAsync(() => h.db.customSelect('SELECT path FROM tracks').get());
    expect(rows!.map((r) => r.data['path']), isNot(contains(gone)), reason: 'its library row goes too');
    await h.dispose(tester);
  });

  testWidgets('a file that cannot be deleted is reported with the reason, and its row stays', (tester) async {
    await open(
      tester,
      deleter: (path) async =>
          throw FileSystemException('denied', path, const OSError('Permission denied', 13)),
    );
    await tester.tap(find.text('Cerca duplicati'));
    await _settle(tester);
    await tester.tap(find.text('Unisci'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('delete-files')));
    await _settle(tester);
    await tester.tap(find.text('Continua'));
    await _settle(tester);
    await tester.tap(find.text('Elimina definitivamente'));
    await _until(tester, find.text('Fatto'));

    expect(find.text('0 file eliminati (0 B).'), findsOneWidget);
    expect(find.text('1 file non eliminato:'), findsOneWidget);
    expect(find.textContaining('Permission denied'), findsOneWidget);
    await tester.tap(find.text('Chiudi'));
    await _settle(tester);
    final rows = await tester.runAsync(() => h.db.customSelect('SELECT COUNT(*) AS n FROM tracks').getSingle());
    expect(rows!.data['n'], 3, reason: 'nothing was forgotten');
    expect(paths.where((f) => File(f).existsSync()), hasLength(3));
    await h.dispose(tester);
  });

  testWidgets('while it hashes: progress and cancel; cancelling goes back to the start', (tester) async {
    final gate = Completer<String>();
    await open(tester, fakeHasher: (path) => gate.future);
    await tester.tap(find.text('Cerca duplicati'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Controllo i file: 0 di 3'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    gate.complete('x');
    await _settle(tester);
    expect(find.text('Cerca duplicati'), findsOneWidget);
    await h.dispose(tester);
  });
}

typedef FileHasherFn = Future<String> Function(String path);
