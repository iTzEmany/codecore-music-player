import 'dart:io';

import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/tag_backup_providers.dart';
import 'package:codecore/services/tags/tag_backups.dart';
import 'package:codecore/services/tags/tag_writer.dart';
import 'package:codecore/ui/screens/cleanup/tag_backups_screen.dart';
import 'package:codecore/ui/screens/settings/tag_write_tiles.dart';
import 'package:codecore/ui/screens/track_edit_dialog.dart';
import 'package:codecore/ui/widgets/tag_write_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

class _Tiles extends ConsumerWidget {
  const _Tiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: ListView(children: tagWriteTiles(context, ref)),
  );
}

void main() {
  late Harness h;
  late Directory root;

  Future<void> open(
    WidgetTester tester,
    Widget child, {
    bool optionOn = false,
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, tracks: 1);
    if (optionOn) {
      await h.store.writeSettings(
        const AppSettings(writeTagsToFiles: true),
      );
    }
    root = Directory.systemTemp.createTempSync('tagui');
    addTearDown(() => root.deleteSync(recursive: true));
    await h.pump(tester, child, extraOverrides: extra);
    await _settle(tester);
  }

  bool optionNow(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(Scaffold).first),
  ).read(settingsProvider).writeTagsToFiles;

  testWidgets('turning the option on shows the warning; Cancel leaves it off', (tester) async {
    await open(tester, const _Tiles());
    expect(optionNow(tester), isFalse);

    await tester.tap(find.text('Scrivi le modifiche nei file'));
    await _settle(tester);
    expect(find.text('Scrivere le modifiche nei file?'), findsOneWidget);
    expect(find.textContaining('Backup dei tag'), findsWidgets);
    expect(find.textContaining('gli ultimi 200 o 2 GB'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await _settle(tester);
    expect(optionNow(tester), isFalse);

    await tester.tap(find.text('Scrivi le modifiche nei file'));
    await _settle(tester);
    await tester.tap(find.text('Attiva'));
    await _settle(tester);
    expect(optionNow(tester), isTrue);

    // Turning it off needs no warning.
    await tester.tap(find.text('Scrivi le modifiche nei file'));
    await _settle(tester);
    expect(optionNow(tester), isFalse);
    await h.dispose(tester);
  });

  testWidgets('the edit dialog has «Scrivi anche nel file» only with the option on, and gives the reason when blocked', (tester) async {
    final blocked = tagWritableProvider('/m/t0.mp3').overrideWith(
      (ref) async => TagWriteReason.unsupported,
    );
    await open(
      tester,
      Builder(
        builder: (c) => TextButton(
          onPressed: () async {
            final t = await h.db.select(h.db.tracks).getSingle();
            if (c.mounted) await showTrackEditDialog(c, t);
          },
          child: const Text('open'),
        ),
      ),
      optionOn: true,
      extra: [blocked],
    );
    await tester.tap(find.text('open'));
    await _settle(tester);
    expect(find.text('Scrivi anche nel file'), findsOneWidget);
    expect(find.textContaining('Formato non modificabile (MP3)'), findsOneWidget);
    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.onChanged, isNull, reason: 'disabled for a file we cannot write');
    await h.dispose(tester);
  });

  testWidgets('with the option off the edit dialog does not mention files', (tester) async {
    await open(
      tester,
      Builder(
        builder: (c) => TextButton(
          onPressed: () async {
            final t = await h.db.select(h.db.tracks).getSingle();
            if (c.mounted) await showTrackEditDialog(c, t);
          },
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await _settle(tester);
    expect(find.byType(AlsoInFileTile), findsOneWidget);
    expect(find.text('Scrivi anche nel file'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('tag backups: list, restore the original (with confirmation) and delete', (tester) async {
    final store = _FakeStore([
      TagBackup(
        id: '1',
        path: '/m/song.mp3',
        createdAt: DateTime(2026, 10, 19, 12, 30),
        sizeBytes: 4 << 20,
      ),
    ]);
    await open(
      tester,
      const TagBackupsScreen(),
      extra: [tagBackupStoreProvider.overrideWith((ref) async => store)],
    );
    expect(find.text('Backup dei tag'), findsOneWidget);
    expect(find.text('song.mp3'), findsOneWidget);
    expect(find.textContaining('4.0 MB'), findsOneWidget);

    // Cancel at the confirmation: nothing is restored.
    await tester.tap(find.byType(PopupMenuButton<String>));
    await _settle(tester);
    await tester.tap(find.text('Ripristina originale').last);
    await _settle(tester);
    expect(find.textContaining('torna com’era prima della modifica'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await _settle(tester);
    expect(store.restored, isEmpty);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await _settle(tester);
    await tester.tap(find.text('Ripristina originale').last);
    await _settle(tester);
    await tester.tap(find.text('Ripristina originale').last);
    await _settle(tester);
    expect(store.restored, ['1']);
    expect(find.text('Originale ripristinato'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await _settle(tester);
    await tester.tap(find.text('Elimina backup'));
    await _settle(tester);
    await tester.tap(find.text('Elimina backup').last);
    await _settle(tester);
    expect(store.items, isEmpty);
    expect(find.text('song.mp3'), findsNothing);
    expect(find.text('Backup eliminato'), findsOneWidget);
    await h.dispose(tester);
  });
}

/// In-memory store: file I/O started under FakeAsync never completes.
class _FakeStore extends TagBackupStore {
  _FakeStore(this.items) : super(Directory.systemTemp);

  final List<TagBackup> items;
  final restored = <String>[];

  @override
  Future<List<TagBackup>> list() async => List.of(items);

  @override
  Future<FileStamp> restore(TagBackup b) async {
    restored.add(b.id);
    return const FileStamp(1, 1);
  }

  @override
  Future<void> delete(TagBackup b) async =>
      items.removeWhere((x) => x.id == b.id);
}

