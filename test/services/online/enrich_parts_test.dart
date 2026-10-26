import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/services/online/enrich_parts.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final _day0 = DateTime(2026, 1, 1);
DateTime _at(int day) => _day0.add(Duration(days: day));
int _ms(int day) => _at(day).millisecondsSinceEpoch;

TrackEnrichData _enrich({
  int? lyricsNone,
  int? syncedNone,
  int? creditsNone,
  bool byUser = false,
}) => TrackEnrichData(
  trackId: 1,
  lyricsNoneAt: lyricsNone,
  syncedNoneAt: syncedNone,
  creditsNoneAt: creditsNone,
  lyricsByUser: byUser,
);

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Track> track({String? plain, String? synced}) async {
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/a.mp3',
            title: 'Song',
            albumKey: 'k',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1,
            lyricsPlain: Value(plain),
            lyricsSynced: Value(synced),
          ),
        );
    return db.select(db.tracks).getSingle();
  }

  test(
    'never searched: due; none at day 0: not due at 29, due at 31',
    () async {
      final t = await track();
      expect(isDue(EnrichPart.lyrics, t, null, _at(0)), isTrue);
      final e = _enrich(lyricsNone: _ms(0));
      expect(isDue(EnrichPart.lyrics, t, e, _at(29)), isFalse);
      expect(isDue(EnrichPart.lyrics, t, e, _at(31)), isTrue);
    },
  );

  test('a filled part is never due', () async {
    final t = await track(plain: 'la la');
    expect(isDue(EnrichPart.lyrics, t, null, _at(99)), isFalse);
    expect(
      isDue(EnrichPart.credits, t, null, _at(0), hasCredits: true),
      isFalse,
    );
    expect(isDue(EnrichPart.credits, t, null, _at(0)), isTrue);
  });

  test(
    'synced: only with a plain text, not the user\'s, and no synced one',
    () async {
      final none = _enrich(syncedNone: _ms(0));
      final withPlain = await track(plain: 'la la');
      expect(isDue(EnrichPart.synced, withPlain, null, _at(0)), isTrue);
      expect(isDue(EnrichPart.synced, withPlain, none, _at(29)), isFalse);
      expect(isDue(EnrichPart.synced, withPlain, none, _at(31)), isTrue);
      expect(
        isDue(EnrichPart.synced, withPlain, _enrich(byUser: true), _at(0)),
        isFalse,
      );
      await db.delete(db.tracks).go();
      expect(isDue(EnrichPart.synced, await track(), null, _at(0)), isFalse);
      await db.delete(db.tracks).go();
      expect(
        isDue(
          EnrichPart.synced,
          await track(plain: 'a', synced: '[0]a'),
          null,
          _at(0),
        ),
        isFalse,
      );
    },
  );

  test('credits follow the same 30 days', () async {
    final t = await track();
    final e = _enrich(creditsNone: _ms(0));
    expect(isDue(EnrichPart.credits, t, e, _at(29)), isFalse);
    expect(isDue(EnrichPart.credits, t, e, _at(31)), isTrue);
  });

  test('exactly 30 days is not yet due', () async {
    final t = await track();
    expect(
      isDue(EnrichPart.lyrics, t, _enrich(lyricsNone: _ms(0)), _at(30)),
      isFalse,
    );
  });

  test('lyrics written by the user are never due', () async {
    final t = await track();
    expect(
      isDue(EnrichPart.lyrics, t, _enrich(byUser: true), _at(99)),
      isFalse,
    );
  });
}
