import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/activity_log_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ActivityLogRepository repo;
  const now = 100 * 86400000;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ActivityLogRepository(db);
  });
  tearDown(() => db.close());

  test('pages come newest first and the count is the whole table', () async {
    for (final at in [3, 1, 2]) {
      await repo.add(at: at, kind: 'scan', name: 'n$at');
    }
    expect((await repo.page(limit: 2)).map((r) => r.name), ['n3', 'n2']);
    expect((await repo.page(limit: 2, offset: 2)).map((r) => r.name), ['n1']);
    expect(await repo.count(), 3);
  });

  test('clear empties the table', () async {
    await repo.add(at: now, kind: 'radio', name: '', detail: '{"a":1}');
    await repo.clear();
    expect(await repo.count(), 0);
  });
}
