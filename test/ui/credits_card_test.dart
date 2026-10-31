import 'dart:convert';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/credits_repository.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/providers/ytm_catalog_providers.dart';
import 'package:codecore/services/online/artist_link_resolver.dart';
import 'package:codecore/services/online/credits.dart';
import 'package:codecore/services/online/curiosity_finder.dart';
import 'package:codecore/services/online/enrich_engine.dart';
import 'package:codecore/services/online/enrich_parts.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/ui/screens/library/artist_screen.dart';
import 'package:codecore/ui/screens/now_playing/credits_card.dart';
import 'package:codecore/ui/screens/online/artist_page_screen.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/widgets/credits_section.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

class _Finder extends Fake implements CuriosityFinder {
  @override
  Future<CuriosityPair> find(
    String title,
    String artist,
    String lang, {
    String? isrc,
    int durationMs = 0,
    cancel,
  }) async => const CuriosityPair();
}

/// Stands for the network: counts the requests and saves [onAsk]'s credits.
class _Service extends Fake implements EnrichEngine {
  _Service(this.repo, this.onAsk);

  final CreditsRepository repo;
  final Future<PartOutcome> Function(CreditsRepository) onAsk;
  var asked = 0;
  bool? lastForce;
  Set<EnrichPart>? lastParts;

  @override
  Future<Map<EnrichPart, PartOutcome>> completeOne(
    int trackId,
    Set<EnrichPart> parts, {
    bool force = false,
    cancel,
  }) async {
    asked++;
    lastForce = force;
    lastParts = parts;
    return {EnrichPart.credits: await onAsk(repo)};
  }
}

List<TrackCreditsCompanion> _credits(int id, int n) => [
  for (var i = 0; i < n; i++)
    TrackCreditsCompanion.insert(
      trackId: id,
      name: 'Person $i',
      nameKey: 'person $i',
      role: 'producer',
      source: 'deezer',
    ),
];

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late Harness h;
  late Track track;

  Future<void> open(
    WidgetTester tester, {
    int credits = 0,
    TrackDetails? details,
    bool setting = false,
    Future<PartOutcome> Function(CreditsRepository)? onAsk,
    DateTime? noneAt,
  }) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, tracks: 1);
    track = (await tester.runAsync(
      () => h.db.select(h.db.tracks).getSingle(),
    ))!;
    final repo = CreditsRepository(h.db);
    await tester.runAsync(() async {
      await h.store.writeSettings(
        h.store.readSettings().copyWith(creditsDetails: setting),
      );
      await repo.save(
        track.id,
        _credits(track.id, credits),
        TrackEnrichCompanion(
          trackId: Value(track.id),
          details: Value(details == null ? null : _json(details)),
          creditsNoneAt: Value(noneAt?.millisecondsSinceEpoch),
        ),
      );
    });
    _service = _Service(repo, onAsk ?? (_) async => PartOutcome.found);
    await h.pump(
      tester,
      Scaffold(
        body: SingleChildScrollView(child: CreditsCard(track: track)),
      ),
      extraOverrides: [
        enrichEngineProvider.overrideWithValue(_service),
        curiosityFinderProvider.overrideWithValue(_Finder()),
      ],
    );
    await _settle(tester);
  }

  testWidgets('12 credits: 8 rows and «Mostra tutto», then all 12', (
    tester,
  ) async {
    await open(tester, credits: 12);
    expect(find.textContaining('Person '), findsNWidgets(8));
    await tester.tap(find.text('Mostra tutto'));
    await tester.pump();
    expect(find.textContaining('Person '), findsNWidgets(12));
    expect(find.text('Mostra tutto'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('long names and roles at 320 dp do not overflow', (tester) async {
    await open(tester, credits: 0);
    await h.dispose(tester);
    tester.view.physicalSize = const Size(320, 1200);
    h = await Harness.create(tester, tracks: 0);
    await h.pump(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: CreditsSection(
            [
              TrackCredit(
                'A very long artist name that keeps going and going forever',
                'producer',
                'deezer',
              ),
              TrackCredit(
                'A very long artist name that keeps going and going forever',
                'some role nobody translated yet at all',
                'deezer',
              ),
            ],
            const TrackDetails(
              bpm: 120,
              label: 'Some Very Long Record Label Name Inc',
              copyright: '(c) 2020 a long copyright holder name',
              explicit: true,
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('details without bpm: no BPM, the rest is there', (tester) async {
    await open(
      tester,
      details: const TrackDetails(label: 'Big Label', explicit: true),
    );
    expect(find.textContaining('BPM'), findsNothing);
    expect(find.textContaining('Big Label'), findsOneWidget);
    expect(find.text('Esplicito'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('nothing to show and no refresh: no card', (tester) async {
    await open(tester);
    expect(find.text('Crediti e dettagli'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('setting off: no refresh button', (tester) async {
    await open(tester, credits: 1);
    expect(find.text('Aggiorna'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets(
    'refresh after «searched, nothing» asks again and shows the new credits',
    (tester) async {
      await open(
        tester,
        setting: true,
        noneAt: DateTime.now().subtract(const Duration(days: 1)),
        onAsk: (repo) async {
          await repo.saveCredits(track.id, _credits(track.id, 2));
          return PartOutcome.found;
        },
      );
      expect(find.text('Person 0'), findsNothing);
      await tester.tap(find.text('Aggiorna'));
      await _settle(tester);
      expect(_service.asked, 1);
      expect(_service.lastForce, isTrue);
      expect(find.text('Person 0'), findsOneWidget);
      await h.dispose(tester);
    },
  );

  testWidgets(
    'refresh is a manual command: it redoes the curiosities whatever the automatic switch says',
    (tester) async {
      await open(tester, credits: 1, setting: true);
      await tester.tap(find.text('Aggiorna'));
      await _settle(tester);
      expect(_service.lastParts, {EnrichPart.credits, EnrichPart.curio});
      expect(_service.lastForce, isTrue);
      await h.dispose(tester);
    },
  );

  testWidgets('refresh that fails: message, old credits stay', (tester) async {
    await open(
      tester,
      credits: 2,
      setting: true,
      onAsk: (_) async => throw Exception('net'),
    );
    await tester.tap(find.text('Aggiorna'));
    await _settle(tester);
    expect(find.text('Impossibile aggiornare i crediti'), findsOneWidget);
    expect(find.text('Person 1'), findsOneWidget);
    await h.dispose(tester);
  });

  group('names are links', () {
    final resolver = ArtistLinkResolver(
      library: (n) async => n == 'In Library'
          ? const ArtistSummary(
              key: 'k',
              name: 'In Library',
              trackCount: 1,
              albumCount: 1,
            )
          : null,
      search: (n) async => [YtmArtistRef(id: 'UC1', name: n)],
    );

    Future<void> tapName(WidgetTester tester, String name) async {
      h = await Harness.create(tester, tracks: 0);
      await h.pump(
        tester,
        const AppShell(),
        extraOverrides: [
          artistLinkResolverProvider.overrideWithValue(resolver),
          artistPageProvider.overrideWith(
            (ref, id) => Future<Never>.delayed(const Duration(days: 1)),
          ),
        ],
      );
      final ctx = tester.element(find.byType(AppShell));
      Navigator.of(ctx, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: CreditsSection([
              TrackCredit(name, 'producer', 'deezer'),
            ], null),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text(name));
      await _settle(tester);
    }

    testWidgets('a library artist opens the local page', (tester) async {
      await tapName(tester, 'In Library');
      expect(find.byType(ArtistDetailScreen), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('an artist not in the library opens the online page', (
      tester,
    ) async {
      await tapName(tester, 'Stranger');
      expect(find.byType(ArtistPageScreen), findsOneWidget);
      await h.dispose(tester);
    });
  });
}

late _Service _service;

String _json(TrackDetails d) => jsonEncode(d.toJson());
