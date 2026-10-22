import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/radio_repository.dart';
import 'package:codecore/services/radio/radio_browser_client.dart';
import 'package:codecore/services/radio/radio_prefs.dart';
import 'package:codecore/services/radio/radio_station.dart';
import 'package:codecore/services/radio/saved_refresh.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Client implements RadioBrowserClient {
  List<RadioStation> answer = [];
  Object? error;
  final asked = <List<String>>[];

  @override
  Future<List<RadioStation>> byUuids(List<String> ids) async {
    asked.add(ids);
    if (error != null) throw error!;
    return answer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Prefs extends RadioPrefs {
  int? at;

  @override
  Future<int?> refreshedAt() async => at;

  @override
  Future<void> setRefreshedAt(int ms) async => at = ms;
}

RadioStation st(String id, {String url = 'http://s', bool ok = true}) =>
    RadioStation(id: id, name: 'Station $id', streamUrl: '$url/$id', lastCheckOk: ok);

void main() {
  late AppDatabase db;
  late RadioRepository repo;
  late _Client client;
  late _Prefs prefs;
  final now = DateTime(2026, 10, 22, 12);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = RadioRepository(db);
    client = _Client();
    prefs = _Prefs();
    await repo.save(st('a'));
    await repo.save(st('b'));
    await repo.saveManual('Mine', 'http://mine.test/live');
  });
  tearDown(() => db.close());

  Future<bool> run() => refreshSavedRadios(repo: repo, client: client, prefs: prefs, now: () => now);

  test('asks only for the Radio Browser stations; a new address is saved, a missing one is marked, none deleted',
      () async {
    client.answer = [st('a', url: 'http://new')];
    expect(await run(), isTrue);
    expect(client.asked.single, ['a', 'b']);
    final all = {for (final r in await repo.getAll()) r.stationId: r};
    expect(all['a']!.streamUrl, 'http://new/a');
    expect(all['b']!.unreachable, isTrue);
    expect(all.length, 3);
    expect(prefs.at, now.millisecondsSinceEpoch);
  });

  test('a second visit within a day does not ask again; a day later it does', () async {
    client.answer = [st('a'), st('b')];
    await run();
    expect(await run(), isFalse);
    expect(client.asked, hasLength(1));
    prefs.at = now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch;
    expect(await run(), isTrue);
  });

  test('an unreachable Radio Browser changes nothing and is tried again next time', () async {
    client.error = const RadioOffline();
    expect(await run(), isFalse);
    expect(prefs.at, isNull);
    expect((await repo.getAll()).every((r) => !r.unreachable), isTrue);
  });
}
