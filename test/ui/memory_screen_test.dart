import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/memory_providers.dart';
import 'package:codecore/providers/nav_providers.dart';
import 'package:codecore/services/memory/app_data.dart';
import 'package:codecore/services/memory/disk_space.dart';
import 'package:codecore/ui/screens/memory/memory_ring.dart';
import 'package:codecore/ui/screens/memory/memory_screen.dart';
import 'package:codecore/ui/widgets/format_utils.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

const _gb = 1073741824, _mb = 1048576;

/// The Memoria tab is shown (its tab index is selected).
class _MemoryTab extends NavIndexNotifier {
  @override
  int build() => NavTab.memory.index;
}

class _FakeActions implements MemoryActions {
  int calls = 0;

  @override
  Future<CacheClearResult> clearCaches() async {
    calls++;
    return const CacheClearResult(freedBytes: 5 * _mb, jamSkipped: false);
  }
}

final _disk = DiskSpace(totalBytes: 128 * _gb, freeBytes: (11.2 * _gb).round());

Future<void> _addTrack(AppDatabase db, String title, int size, {String format = 'mp3'}) =>
    db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/$title.$format',
          title: title,
          albumKey: 'artist|$title',
          format: format,
          sizeBytes: size,
          mtimeMs: 1,
          addedAt: 1,
          artist: const Value('Artist'),
          album: Value('Album $title'),
          durationMs: const Value(185000),
        ));

void main() {
  late Harness h;
  late _FakeActions actions;

  /// 38.4 GB of music: one big FLAC and six 10 MB mp3 (7 heavy tracks), a
  /// playlist holding the FLAC.
  Future<void> open(
    WidgetTester tester, {
    DiskSpace? disk,
    Size size = const Size(400, 5000),
    double textScale = 1,
    String playlistName = 'Gym',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester);
    actions = _FakeActions();
    await tester.runAsync(() async {
      await _addTrack(h.db, 'Big Flac', 41231686042 - 6 * 10 * _mb, format: 'flac');
      for (var i = 0; i < 6; i++) {
        await _addTrack(h.db, 'Heavy $i', 10 * _mb);
      }
      final pid = await h.db.into(h.db.playlists).insert(PlaylistsCompanion.insert(name: playlistName, createdAt: 1));
      final tid = await (h.db.select(h.db.tracks)..where((t) => t.title.equals('Big Flac'))).map((t) => t.id).getSingle();
      await h.db.into(h.db.playlistTracks).insert(PlaylistTracksCompanion.insert(playlistId: pid, trackId: tid, position: 0));
    });
    await h.pump(
      tester,
      const MemoryScreen(),
      textScale: textScale,
      extraOverrides: [
        navIndexProvider.overrideWith(_MemoryTab.new),
        memoryActionsProvider.overrideWithValue(actions),
        musicDiskSpaceProvider.overrideWith((ref) async => disk),
        appDataUsageProvider.overrideWith((ref) async => const [
              AppDataItem(AppDataKind.covers, 52 * _mb, detailBytes: 8 * _mb),
              AppDataItem(AppDataKind.database, 4 * _mb),
              AppDataItem(AppDataKind.imageMemory, 20 * _mb),
              AppDataItem(AppDataKind.jamCache, 0),
              AppDataItem(AppDataKind.tagBackups, 200 * 1024),
              AppDataItem(AppDataKind.log, 500 * 1024),
            ]),
      ],
    );
    // The providers read the in-memory database for real.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('formatBytes writes the decimal comma by locale', (tester) async {
    expect(formatBytes(1610612736, 'it'), '1,5 GB');
    expect(formatBytes(1610612736, 'en'), '1.5 GB');
    expect(formatBytes(128 * _gb, 'it'), '128 GB');
  });

  testWidgets('the ring shows the music, the free space and the legend', (tester) async {
    await open(tester, disk: _disk);
    final ring = find.byType(MemoryRing);
    expect(find.descendant(of: ring, matching: find.text('38,4 GB')), findsOneWidget);
    expect(find.text('11,2 GB liberi su 128 GB'), findsOneWidget);
    expect(find.text('Libero'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('without the disk size: the unavailable note and no legend', (tester) async {
    await open(tester);
    expect(find.descendant(of: find.byType(MemoryRing), matching: find.text('38,4 GB')), findsOneWidget);
    expect(find.text('Non disponibile'), findsOneWidget);
    expect(find.text('Libero'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('the Formati block swaps the list below', (tester) async {
    await open(tester, disk: _disk);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('FLAC'), findsNothing);
    await tester.tap(find.text('Formati'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('FLAC'), findsOneWidget);
    expect(find.text('Gym'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('small app data is not listed, there is a note and never 0 B', (tester) async {
    await open(tester, disk: _disk);
    expect(find.text('Copertine'), findsOneWidget);
    expect(find.text('Cache'), findsOneWidget);
    expect(find.text('Libreria'), findsOneWidget);
    expect(find.text('Backup dei tag'), findsNothing);
    expect(find.text('Registro'), findsNothing);
    expect(find.text('I dati sotto 1 MB non sono elencati.'), findsOneWidget);
    final zero = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').endsWith(' 0 B'));
    expect(zero, findsNothing);
    await h.dispose(tester);
  });

  testWidgets('Svuota cache clears at once, without a dialog', (tester) async {
    await open(tester, disk: _disk);
    expect(find.text('Libera 20,0 MB. Brani, copertine e ascolti restano.'), findsOneWidget);
    await tester.tap(find.text('Svuota cache'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(actions.calls, 1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Liberati 5,0 MB'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('Mostra tutti expands the five heaviest tracks in place', (tester) async {
    await open(tester, disk: _disk);
    final rows = find.textContaining(RegExp(r'^(Heavy \d|Big Flac)$'));
    expect(rows, findsNWidgets(5));
    await tester.tap(find.text('Mostra tutti'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(rows, findsNWidgets(7));
    expect(find.text('Mostra tutti'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('360 px at 150 % with long names does not overflow', (tester) async {
    await open(
      tester,
      disk: _disk,
      size: const Size(360, 780),
      textScale: 1.5,
      playlistName: 'Una playlist con un nome davvero molto molto lungo da non stare in una riga',
    );
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('wide window: ring column on the left, no exceptions', (tester) async {
    await open(tester, disk: _disk, size: const Size(1200, 1400));
    expect(find.byType(MemoryRing), findsOneWidget);
    expect(find.text('Strumenti'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });
}
