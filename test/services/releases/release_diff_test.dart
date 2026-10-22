import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_artist_parser.dart';
import 'package:codecore/services/releases/release_diff.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real pages (2026-10-22), trimmed, read with the phase-30 parser.
List<YtmReleaseShelf> shelves(String name) {
  final json = jsonDecode(File('test/fixtures/innertube/$name.json').readAsStringSync()) as Map;
  return parseArtistPage(json, 'UCx').shelves.whereType<YtmReleaseShelf>().toList();
}

Set<String> ids(List<YtmReleaseShelf> s) =>
    {for (final x in s) for (final r in x.releases) r.browseId};

final now = DateTime(2026, 10, 22);

YtmReleaseShelf shelf(List<(String, String)> items) => YtmReleaseShelf('x', [
      for (final (i, (title, sub)) in items.indexed)
        YtmRelease(browseId: 'MPREb_$title$i', title: title, subtitle: sub),
    ]);

void main() {
  test('the year is the first plausible number of the subtitle', () {
    expect(releaseYear('2025', now: now), 2025);
    expect(releaseYear('Single • 2025', now: now), 2025);
    expect(releaseYear('Singolo • 2026', now: now), 2026);
    expect(releaseYear('EP • 12345 • 1999', now: now), 1999);
    expect(releaseYear('Single • 2031', now: now), isNull);
    expect(releaseYear('Album', now: now), isNull);
  });

  test('variants of a title share a key, a reissue with its own title does not', () {
    const life = 'The Life of a Showgirl';
    for (final t in ['$life: The Encore', '$life + Acoustic Collection', '$life (Track by Track Version)']) {
      expect(releaseGroupKey(t), releaseGroupKey(life), reason: t);
    }
    expect(releaseGroupKey('Moon Music (Full Moon Edition)'), releaseGroupKey('Moon Music'));
    expect(releaseGroupKey('Midnights (Deluxe Version)'), releaseGroupKey('Midnights'));
    expect(releaseGroupKey('Bollicine 40° RPLAY Special Edition (Remastered 2023)'),
        isNot(releaseGroupKey('Bollicine')));
  });

  test('the first check stores everything and nothing is new', () {
    final s = shelves('ytm_artist_releases');
    final d = diffReleases(known: {}, fetched: s, firstCheck: true, now: now);
    expect(d.toStore.length, ids(s).length);
    expect(d.fresh, isEmpty);
  });

  test('a new id of this year is new; the variants of a new album make one entry', () {
    final s = shelves('ytm_artist_releases');
    // Everything but the 2026 single was known.
    final patient = s.expand((x) => x.releases).firstWhere((r) => r.title == 'Patient Zero');
    final d = diffReleases(known: ids(s)..remove(patient.browseId), fetched: s, firstCheck: false, now: now);
    expect(d.fresh.single.release.title, 'Patient Zero');
    expect(d.fresh.single.kind, ReleaseKind.single);
    expect(d.fresh.single.year, 2026);
    expect(d.toStore.single.release.browseId, patient.browseId);
  });

  test('four versions of one album arriving together are one entry with 3 variants', () {
    final s = shelves('ytm_artist_releases');
    final life = {
      for (final r in s.first.releases)
        if (r.title.startsWith('The Life of a Showgirl')) r.browseId,
    };
    expect(life.length, 4);
    final d = diffReleases(known: ids(s)..removeAll(life), fetched: s, firstCheck: false, now: now);
    expect(d.fresh.length, 1);
    expect(d.fresh.single.release.title, 'The Life of a Showgirl');
    expect(d.fresh.single.variants.length, 3);
    expect(d.toStore.length, 4);
  });

  test('a variant of an album already stored is not new', () {
    final s = shelves('ytm_artist_releases');
    final encore = s.first.releases.firstWhere((r) => r.title.endsWith('The Encore'));
    final d = diffReleases(known: ids(s)..remove(encore.browseId), fetched: s, firstCheck: false, now: now);
    expect(d.fresh, isEmpty);
    expect(d.toStore.single.release.browseId, encore.browseId);
  });

  test('a single with the title of an album is not taken as its variant', () {
    final d = diffReleases(
      known: {'MPREb_A'},
      fetched: [shelf([('Siamo Qui', '2021'), ('Siamo Qui', 'Singolo • 2026')])],
      firstCheck: false,
      now: now,
      knownGroups: {releaseGroupId(ReleaseKind.album, releaseGroupKey('Siamo Qui'))},
    );
    expect(d.fresh.single.kind, ReleaseKind.single);
  });

  test('an old release that appears only now is stored but not new', () {
    final d = diffReleases(
      known: {},
      fetched: [shelf([('Old Gem', '2021'), ('Last Year', '2025'), ('No Year', 'Album')])],
      firstCheck: false,
      now: now,
    );
    expect(d.toStore.length, 3);
    expect([for (final f in d.fresh) f.release.title], ['Last Year']);
  });

  test('a reissue with a title of its own is new', () {
    final s = shelves('ytm_artist_releases_reissues');
    final reissue = s.first.releases.first;
    expect(reissue.title, contains('40° RPLAY'));
    final d = diffReleases(known: ids(s)..remove(reissue.browseId), fetched: s, firstCheck: false, now: now);
    expect(d.fresh.single.release.browseId, reissue.browseId);
  });

  test('the order is by year, not by position in the carousel', () {
    final s = shelves('ytm_artist_releases_it');
    expect(s.first.releases.last.title, 'La Chitarra Nella Roccia (Live)'); // 2025 after 2015
    final d = diffReleases(known: {}, fetched: s, firstCheck: false, now: now);
    expect([for (final f in d.fresh) f.year], [2025, 2025, 2025, 2025]);
    // 2025 titles sorted by name; a mix of years is ordered newest first.
    final mixed = diffReleases(
        known: {}, fetched: [shelf([('B', '2025'), ('A', '2026'), ('C', '2025')])], firstCheck: false, now: now);
    expect([for (final f in mixed.fresh) f.release.title], ['A', 'B', 'C']);
  });

  test('a missing carousel, or none, is not an error', () {
    final d = diffReleases(known: {}, fetched: const [], firstCheck: false, now: now);
    expect(d.fresh, isEmpty);
    expect(d.toStore, isEmpty);
    final single = shelves('ytm_artist_releases_it');
    final d2 = diffReleases(known: ids(single), fetched: [single.last], firstCheck: false, now: now);
    expect(d2.fresh, isEmpty);
  });

  test('the minus-one fixture differs from the full page by one release', () {
    final full = ids(shelves('ytm_artist_releases'));
    final less = ids(shelves('ytm_artist_releases_minus_one'));
    expect(full.difference(less).length, 1);
    expect(less.difference(full), isEmpty);
  });
}
