import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/second_opinion_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/smart_search_providers.dart';
import 'package:codecore/services/online/enrichment_service.dart' show EnrichField;
import 'package:codecore/services/online/query_match.dart';
import 'package:codecore/services/online/second_opinion.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers each track with the next outcome of [script] and remembers the asked ones.
class _Fake implements SecondOpinion {
  _Fake(this.script);

  final List<SecondOpinionKind> script;
  final asked = <int>[];

  @override
  Future<SecondOpinionOutcome> check(Track track, {CancelToken? cancel}) async {
    asked.add(track.id);
    final kind = script[(asked.length - 1) % script.length];
    return SecondOpinionOutcome(kind,
        written: kind == SecondOpinionKind.confirmed ? {EnrichField.genre} : const {});
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  late _Fake fake;

  Future<void> setUpWith(List<SecondOpinionKind> script, {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    fake = _Fake(script);
    db = AppDatabase(NativeDatabase.memory());
    c = ProviderContainer(overrides: [
      secondOpinionProvider.overrideWithValue(fake),
      trackRepositoryProvider.overrideWithValue(TrackRepository(db)),
      settingsStoreProvider.overrideWithValue(SettingsStore(await SharedPreferences.getInstance())),
    ]);
  }

  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<List<int>> add(int n) async => [
        for (var i = 0; i < n; i++)
          await db.into(db.tracks).insert(TracksCompanion.insert(
                path: '/m/$i.mp3',
                title: 'T$i',
                albumKey: 'k',
                format: 'mp3',
                sizeBytes: 1,
                mtimeMs: 1,
                addedAt: 1,
                enrichStatus: const Value(1),
              )),
      ];

  test('only tracks never checked are asked, and the answered ones are remembered', () async {
    await setUpWith([SecondOpinionKind.notConfirmed]);
    final ids = await add(3);
    await c.read(reviewCheckedProvider.notifier).add(ids[0]);
    await c.read(secondOpinionJobProvider.notifier).run(ids);
    expect(fake.asked, [ids[1], ids[2]]);
    expect(c.read(reviewCheckedProvider), ids.toSet());
    expect(c.read(secondOpinionJobProvider).running, isFalse);
    expect(c.read(secondOpinionJobProvider).done, 2);
  });

  test('a network error does not mark the track as checked', () async {
    await setUpWith([SecondOpinionKind.networkError]);
    final ids = await add(1);
    await c.read(secondOpinionJobProvider.notifier).run(ids);
    expect(c.read(reviewCheckedProvider), isEmpty);
  });

  test('«too many requests» stops the job and rests the source', () async {
    await setUpWith([SecondOpinionKind.throttled]);
    final ids = await add(3);
    await c.read(secondOpinionJobProvider.notifier).run(ids);
    expect(fake.asked, hasLength(1));
    expect(c.read(secondOpinionJobProvider).throttled, isTrue);
    expect(c.read(sourceCooldownProvider).isPaused(MediaKind.ytmSong), isTrue);
    expect(c.read(reviewCheckedProvider), isEmpty, reason: 'the throttled one is not marked either');
  });

  test('while the source rests the job does not start', () async {
    await setUpWith([SecondOpinionKind.notConfirmed]);
    final ids = await add(2);
    c.read(sourceCooldownProvider).trip(MediaKind.ytmSong);
    await c.read(secondOpinionJobProvider.notifier).run(ids);
    expect(fake.asked, isEmpty);
  });

  test('every checked track leaves a line with its outcome, newest first', () async {
    await setUpWith([SecondOpinionKind.confirmed, SecondOpinionKind.notConfirmed]);
    final ids = await add(2);
    await c.read(secondOpinionJobProvider.notifier).run(ids);
    final log = c.read(secondOpinionJobProvider).log;
    expect(log.map((e) => e.trackId), [ids[1], ids[0]]);
    expect(log.map((e) => e.title), ['T1', 'T0']);
    expect(log[1].kind, SecondOpinionKind.confirmed);
    expect(log[1].written, {EnrichField.genre});
    expect(log[0].kind, SecondOpinionKind.notConfirmed);
  });
}
