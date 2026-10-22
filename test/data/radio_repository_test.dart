import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/radio_repository.dart';
import 'package:codecore/services/radio/radio_station.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

RadioStation st(String id, {String url = 'http://s', bool ok = true}) => RadioStation(
    id: id, name: 'Station $id', streamUrl: '$url/$id', homepage: 'https://h/$id', tags: const ['pop', 'rock'],
    codec: 'MP3', bitrate: 128, lastCheckOk: ok);

void main() {
  late AppDatabase db;
  late RadioRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = RadioRepository(db);
  });
  tearDown(() => db.close());

  Future<List<String>> ids() async => [for (final r in await repo.getAll()) r.stationId];

  test('save adds at the end, keeps every field and ignores a station already saved', () async {
    await repo.save(st('a'));
    await repo.save(st('b'));
    await repo.save(st('a').copyWith(name: 'Other'));
    expect(await ids(), ['a', 'b']);
    final a = (await repo.getAll()).first;
    expect(a.name, 'Station a');
    expect((a.codec, a.bitrate, a.tags), ('MP3', 128, 'pop,rock'));
    final back = a.toStation();
    expect(back.tags, ['pop', 'rock']);
    expect((back.streamUrl, back.homepage), ('http://s/a', 'https://h/a'));
  });

  test('reorder follows the list and keeps stations it does not mention after them', () async {
    for (final id in ['a', 'b', 'c', 'd']) {
      await repo.save(st(id));
    }
    await repo.reorder(['c', 'a']);
    expect(await ids(), ['c', 'a', 'b', 'd']);
    expect(await repo.watchAll().first.then((l) => [for (final r in l) r.stationId]), ['c', 'a', 'b', 'd']);
  });

  test('rename changes the name (a blank one is ignored), remove deletes, touchPlayed stamps', () async {
    await repo.save(st('a'));
    await repo.save(st('b'));
    await repo.rename('a', '  My radio ');
    await repo.rename('b', '   ');
    await repo.touchPlayed('a');
    await repo.remove('b');
    final rows = await repo.getAll();
    expect(rows.map((r) => r.name), ['My radio']);
    expect(rows.single.lastPlayedAt, isNotNull);
  });

  test('a position freed by a removal is not reused out of order', () async {
    for (final id in ['a', 'b', 'c']) {
      await repo.save(st(id));
    }
    await repo.remove('b');
    await repo.save(st('d'));
    expect(await ids(), ['a', 'c', 'd']);
  });

  test('applyRefresh changes the address, keeps the user name, marks the missing ones and deletes nothing', () async {
    for (final id in ['a', 'b', 'c']) {
      await repo.save(st(id));
    }
    await repo.rename('a', 'Mine');
    await repo.applyRefresh([
      st('a', url: 'https://new'),
      st('c', ok: false),
    ], ['b']);
    final rows = {for (final r in await repo.getAll()) r.stationId: r};
    expect(rows.keys, containsAll(['a', 'b', 'c']));
    expect((rows['a']!.streamUrl, rows['a']!.name, rows['a']!.unreachable), ('https://new/a', 'Mine', false));
    expect(rows['b']!.unreachable, isTrue);
    expect(rows['b']!.streamUrl, 'http://s/b', reason: 'the saved address still plays');
    expect(rows['c']!.unreachable, isTrue);
    // It comes back: the next refresh clears the mark.
    await repo.applyRefresh([st('b')], []);
    expect((await repo.getAll()).firstWhere((r) => r.stationId == 'b').unreachable, isFalse);
  });
}
