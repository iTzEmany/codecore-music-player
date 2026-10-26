// Characterization (38.5): the PopupMenuButton menus of lib/ui, one enum per menu (42.5);
// the values read are the enum names. Whoever changes a menu updates its test in the same step.
//
// The podcast «podcast-menu», the episode menu and the tag-backups menu are
// driven for real by podcast_screens_test.dart and tag_write_options_test.dart
// (heard, unsubscribe, restore, delete); here only their value lists are
// pinned. Of the other menus, one item is driven (named in each test) and the
// rest are only listed.
import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/podcast_repository.dart';
import 'package:codecore/providers/podcast_providers.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/services/podcast/episode_downloader.dart';
import 'package:codecore/services/podcast/podcast_models.dart';
import 'package:codecore/services/podcast/podcast_service.dart';
import 'package:codecore/services/tags/tag_backups.dart';
import 'package:codecore/services/tags/tag_reader.dart';
import 'package:codecore/ui/screens/cleanup/tag_backups_screen.dart';
import 'package:codecore/ui/screens/podcast/podcast_detail_screen.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:path/path.dart' as p;
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/smart_playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:codecore/ui/screens/library/folders_sheet.dart';
import 'package:codecore/ui/screens/library/library_screen.dart';
import 'package:codecore/ui/screens/playlists/playlist_detail_screen.dart';
import 'package:codecore/ui/screens/settings/missing_tracks_screen.dart';
import 'package:codecore/ui/screens/smart/smart_playlist_screen.dart';
import 'package:codecore/ui/shell/desktop_sidebar.dart';
import 'package:drift/drift.dart'
    show BooleanExpressionOperators, OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Opens the menu behind [button] and returns the values of its items, in order.
Future<List<String>> _open(WidgetTester tester, Finder button) async {
  await tester.tap(button);
  await _settle(tester);
  return [
    for (final i in tester.widgetList<PopupMenuItem>(
      find.byWidgetPredicate((w) => w is PopupMenuItem),
    ))
      // Menus are enums now (42.5); the names are the old string values.
      i.value is Enum ? (i.value as Enum).name : i.value as String,
  ];
}

Future<List<Track>> _tracks(WidgetTester tester, Harness h) async =>
    (await tester.runAsync(
      () => (h.db.select(
        h.db.tracks,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get(),
    ))!;

Future<List<String>> _playlistNames(WidgetTester tester, Harness h) async =>
    (await tester.runAsync(
      () async => [
        for (final p in await h.db.select(h.db.playlists).get()) p.name,
      ],
    ))!;

class _Web implements WebClient {
  @override
  Future<Object?> getJson(
    String url, {
    Map<String, String>? query,
    CancelToken? cancel, bool strict = false,
  }) async => null;
  @override
  Future<List<int>?> getBytes(
    String url, {
    int maxBytes = 5 * 1024 * 1024,
    CancelToken? cancel,
  }) async => null;
}

class _NoTags implements TagReader {
  @override
  Future<TagInfo> read(String path, {bool withCover = true}) async =>
      const TagInfo();
}

class _FakeStore extends TagBackupStore {
  _FakeStore(this.items) : super(Directory.systemTemp);
  final List<TagBackup> items;
  @override
  Future<List<TagBackup>> list() async => List.of(items);
}

const _newMenu = ['create', 'smart', 'csv'];

void main() {
  testWidgets(
    'desktop sidebar «+»: new, smart, csv; «new» asks a name and creates the playlist',
    (tester) async {
      _phone(tester);
      final h = await Harness.create(tester);
      await h.pump(
        tester,
        const Scaffold(
          body: SizedBox(width: 280, child: DesktopSidebar(collapsed: false)),
        ),
      );
      await _settle(tester);
      expect(await _open(tester, find.byTooltip('Nuova playlist')), _newMenu);
      await tester.tap(find.text('Nuova playlist').last);
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Dal menu');
      await tester.tap(find.text('Crea'));
      await _settle(tester);
      expect(await _playlistNames(tester, h), ['Dal menu']);
      await h.dispose(tester);
    },
  );

  testWidgets(
    'library «+»: the same three values as the sidebar; «new» creates the playlist',
    (tester) async {
      _phone(tester);
      final h = await Harness.create(tester);
      await h.pump(tester, const Scaffold(body: LibraryScreen()));
      await _settle(tester);
      expect(await _open(tester, find.byTooltip('Nuova playlist')), _newMenu);
      await tester.tap(find.text('Nuova playlist').last);
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Dalla libreria');
      await tester.tap(find.text('Crea'));
      await _settle(tester);
      expect(await _playlistNames(tester, h), ['Dalla libreria']);
      await h.dispose(tester);
    },
  );

  testWidgets(
    'library «more»: folders, scan, share, exportAll; «folders» opens the sheet',
    (tester) async {
      _phone(tester);
      final h = await Harness.create(tester);
      await h.pump(tester, const Scaffold(body: LibraryScreen()));
      await _settle(tester);
      expect(await _open(tester, find.byTooltip('Altre azioni')), [
        'folders',
        'scan',
        'share',
        'exportAll',
      ]);
      await tester.tap(find.text('Cartelle musicali'));
      await _settle(tester);
      expect(find.byType(FoldersSheet), findsOneWidget);
      await h.dispose(tester);
    },
  );

  testWidgets(
    'playlist page: edit, add, cover, export, rename, delete («clear» only with a custom cover); «rename» renames',
    (tester) async {
      _phone(tester);
      final h = await Harness.create(tester, tracks: 2);
      final playlist = (await tester.runAsync(() async {
        final repo = PlaylistRepository(h.db);
        final id = await repo.create('Notte');
        await repo.addTracks(id, [1, 2]);
        return (await h.db.select(h.db.playlists).get()).single;
      }))!;
      await h.pump(tester, PlaylistDetailScreen(playlist: playlist));
      await _settle(tester);
      expect(await _open(tester, find.byTooltip('Altre azioni')), [
        'edit',
        'add',
        'cover',
        'export',
        'rename',
        'delete',
      ]);
      await tester.tap(find.text('Rinomina'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Giorno');
      await tester.tap(find.text('Salva'));
      await _settle(tester);
      expect(await _playlistNames(tester, h), ['Giorno']);
      expect(find.text('Giorno'), findsWidgets);
      await h.dispose(tester);
    },
  );

  testWidgets(
    'album page: queue, playlist, share, enrich, merge; «queue» adds the album and says so',
    (tester) async {
      _phone(tester);
      final h = await Harness.create(tester, tracks: 4);
      final album = (await tester.runAsync(
        () => LibraryQueries(h.db).watchAlbums().first,
      ))!.firstWhere((a) => a.title == 'Album 0');
      await h.pump(tester, AlbumDetailScreen(album: album));
      await _settle(tester);
      expect(await _open(tester, find.byTooltip('Altre azioni')), [
        'queue',
        'playlist',
        'share',
        'enrich',
        'merge',
      ]);
      await tester.tap(find.text('Aggiungi in coda'));
      await _settle(tester);
      expect(find.text('Aggiunto in coda'), findsOneWidget);
      expect(h.handler.queueIds, hasLength(2));
      await h.dispose(tester);
    },
  );

  testWidgets('smart playlist page: edit, convert, delete', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 2);
    final id = (await tester.runAsync(
      () => SmartPlaylistRepository(h.db, TrackRepository(h.db)).create(
        name: 'Tutti',
        rules: 'artista:artist',
        sort: SmartSort.title,
        limit: null,
      ),
    ))!;
    await h.pump(tester, SmartPlaylistScreen(id: id));
    await _settle(tester);
    expect(await _open(tester, find.byTooltip('Altre azioni')), [
      'edit',
      'convert',
      'delete',
    ]);
    await h.dispose(tester);
  });

  testWidgets(
    'missing tracks, row menu: ignore, remove; «ignore» hides the row and keeps the track',
    (tester) async {
      _phone(tester);
      final h = await Harness.create(tester, tracks: 2);
      final rows = await _tracks(tester, h);
      await tester.runAsync(
        () => TrackRepository(h.db).markMissing({rows[0].path}, true),
      );
      await h.pump(tester, const MissingTracksScreen());
      await _settle(tester);
      expect(find.text('Song 0'), findsOneWidget);
      expect(
        await _open(
          tester,
          find.byWidgetPredicate((w) => w is PopupMenuButton),
        ),
        ['ignore', 'remove'],
      );
      await tester.tap(find.text('Ignora'));
      await _settle(tester);
      expect(find.text('Song 0'), findsNothing);
      expect(
        (await _tracks(tester, h)),
        hasLength(2),
        reason: 'only hidden from this list',
      );
      await h.dispose(tester);
    },
  );

  testWidgets(
    'podcast page «podcast-menu» and the episode menus: unsubscribe; heard (+ delete once downloaded)',
    (tester) async {
      _phone(tester);
      final h = await Harness.create(tester, tracks: 1);
      final dir = Directory.systemTemp.createTempSync('menus');
      addTearDown(() => dir.deleteSync(recursive: true));
      final base = p.join(dir.path, 'podcasts');
      final repo = PodcastRepository(h.db);
      final service = PodcastService(
        repo: repo,
        fetch: (url) async => url,
        parse: (text) async => throw const FormatException('not rss'),
        web: _Web(),
        podcastsDir: base,
        now: () => DateTime.utc(2026, 10, 17, 12),
      );
      final pid = (await tester.runAsync(() async {
        final id = await repo.subscribe(
          'https://x/feed',
          PodcastFeed(
            title: 'Show',
            episodes: [
              for (final g in ['1', '2'])
                PodcastEpisodeInfo(
                  guid: g,
                  title: 'Ep $g',
                  audioUrl: 'https://x/$g.mp3',
                  duration: const Duration(minutes: 20),
                ),
            ],
          ),
          now: 1,
        );
        final e =
            await (h.db.select(h.db.podcastEpisodes)
                  ..where((x) => x.podcastId.equals(id) & x.guid.equals('2')))
                .getSingle();
        final file = File(p.join(base, '$id', '2.mp3'))
          ..createSync(recursive: true)
          ..writeAsBytesSync([1, 2, 3]);
        final t = await h.db
            .into(h.db.tracks)
            .insert(
              TracksCompanion.insert(
                path: file.path,
                title: 'Ep 2',
                albumKey: 'podcast|$id',
                format: 'mp3',
                sizeBytes: 3,
                mtimeMs: 1,
                addedAt: 1,
                durationMs: const Value(1200000),
                kind: const Value(1),
              ),
            );
        await repo.setTrackId(e.id, t);
        return id;
      }))!;
      await h.pump(
        tester,
        PodcastDetailScreen(podcastId: pid),
        extraOverrides: [
          podcastServiceProvider.overrideWithValue(service),
          podcastsDirProvider.overrideWith((ref) async => base),
          episodeDownloaderProvider.overrideWith(
            (ref) async => EpisodeDownloader(
              repo: repo,
              tracks: TrackRepository(h.db),
              tags: _NoTags(),
              baseDir: base,
              readTagsInIsolate: false,
            ),
          ),
        ],
      );
      await _settle(tester);
      expect(await _open(tester, find.byKey(const ValueKey('podcast-menu'))), [
        'unsubscribe',
      ]);
      await tester.tapAt(const Offset(5, 5));
      await _settle(tester);
      final eps = await tester.runAsync(
        () => h.db.select(h.db.podcastEpisodes).get(),
      );
      final by = {for (final e in eps!) e.guid: e.id};
      expect(await _open(tester, find.byKey(ValueKey('menu-${by['1']}'))), [
        'heard',
      ], reason: 'not downloaded');
      await tester.tapAt(const Offset(5, 5));
      await _settle(tester);
      expect(await _open(tester, find.byKey(ValueKey('menu-${by['2']}'))), [
        'heard',
        'delete',
      ], reason: 'downloaded');
      await h.dispose(tester);
    },
  );

  testWidgets('tag backups row menu: restore, delete', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester);
    final store = _FakeStore([
      TagBackup(
        id: '1',
        path: '/m/song.mp3',
        createdAt: DateTime(2026, 10, 19),
        sizeBytes: 1024,
      ),
    ]);
    await h.pump(
      tester,
      const TagBackupsScreen(),
      extraOverrides: [
        tagBackupStoreProvider.overrideWith((ref) async => store),
      ],
    );
    await _settle(tester);
    expect(
      await _open(tester, find.byWidgetPredicate((w) => w is PopupMenuButton)),
      ['restore', 'delete'],
    );
    await h.dispose(tester);
  });
}
