import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/services/online/enrich_parts.dart';
import 'package:codecore/services/online/enrich_runner.dart';
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/enrich_fakes.dart';

void main() {
  late EnrichRig r;

  setUp(() => r = EnrichRig());
  tearDown(() => r.dispose());

  Future<Track> row(int id) async => (await r.repo.getById(id))!;

  test('a track with nothing left to ask is not asked again', () async {
    final id = await r.add();
    await r.runManual([id], parts: manualParts(AppSettings()));
    r.web.urls.clear();
    final round = await r.runManual([id], parts: manualParts(AppSettings()));
    expect(round.updatedTracks, 0);
    expect(r.web.count('itunes'), 0);
  });

  test('a track missing something is asked', () async {
    final id = await r.add();
    final round = await r.runManual([id], parts: manualParts(AppSettings()));
    expect(round.updatedTracks, 1);
    expect((await row(id)).lyricsPlain, isNotNull);
  });

  test('the manual parts ask the curiosities', () async {
    final id = await r.add();
    await r.runManual([id], parts: manualParts(AppSettings()));
    expect((await row(id)).curiosities, isNotNull);
  });

  test('credits are asked by a manual job only with «Crediti e dettagli»', () async {
    await r.runManual([await r.add(path: '/a.mp3')], parts: manualParts(AppSettings()));
    expect(r.web.count('musicbrainz'), 0);
    await r.runManual([await r.add(path: '/b.mp3')], parts: manualParts(AppSettings(creditsDetails: true)));
    expect(r.web.count('musicbrainz'), greaterThan(0));
  });

  test('every part refused before the list is used up: the round says so', () async {
    r.web.itunes = ItunesMode.limited;
    r.chain.limited = true;
    final ids = [for (var i = 0; i < 4; i++) await r.add(path: '/$i.mp3')];
    final round = await r.runManual(ids, parts: {EnrichPart.meta, EnrichPart.lyrics});
    expect([round.allRefused, round.processed], [true, 1]);
  });

  test('a cancelled job leaves the track it did not reach as it was', () async {
    final ids = [for (var i = 0; i < 12; i++) await r.add(path: '/$i.mp3')];
    late final EnrichRunner run;
    run = EnrichRunner(
      engine: r.engine,
      ids: FixedIds(ids),
      parts: () => {EnrichPart.meta},
      waitIdle: () async {},
      mode: AskMode.retryNone,
      onProgress: (d, t) => run.cancel(),
    );
    await run.run();
    final last = await row(ids.last);
    expect(last.enrichStatus, 0);
  });
}
