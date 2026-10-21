import 'dart:async';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/providers/activity_log_providers.dart';
import 'package:codecore/providers/activity_providers.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/import_providers.dart';
import 'package:codecore/services/import/playlist_import_service.dart';
import 'package:codecore/core/import_row.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Activity extends Notifier<ActivityState> {
  @override
  ActivityState build() => const ActivityState([], []);
  void set(ActivityState s) => state = s;
}

final _activity = NotifierProvider<_Activity, ActivityState>(_Activity.new);

ActivityItem _done(String key, String name, {bool failed = false}) =>
    ActivityItem(kind: ActivityKind.download, key: key, name: name, running: false, failed: failed);

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('each ended item is written once, newest first; imports by name; «Pulisci» empties', () async {
    final events = StreamController<ImportEvent>();
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      activityProvider.overrideWith((ref) => ref.watch(_activity)),
      importEventsProvider.overrideWith((ref) => events.stream),
    ]);
    addTearDown(c.dispose);
    c.listen(activityLogProvider, (_, _) {});
    final playlistId = await db.into(db.playlists).insert(PlaylistsCompanion.insert(name: 'L', createdAt: 0));
    final importId = await ImportRepository(db).create(
        playlistId: playlistId,
        sourceName: 'Liked Songs (23/23)',
        rows: const [ImportRow(index: 0, title: 'T', artists: ['A'])]);

    c.read(_activity.notifier).set(ActivityState(const [], [_done('dl-1', 'Uno')]));
    c.read(_activity.notifier).set(ActivityState(const [], [_done('dl-1', 'Uno'), _done('dl-2', 'Due', failed: true)]));
    expect(c.read(activityLogProvider).map((e) => e.item!.name), ['Due', 'Uno']);
    expect(c.read(activityLogProvider).first.failed, isTrue);

    events.add(ImportEvent(ImportEventKind.completed, importId));
    await pumpEventQueue();
    final top = c.read(activityLogProvider).first;
    expect(top.importName, 'Liked Songs', reason: 'the import, not the block');
    expect(top.failed, isFalse);
    events.add(ImportEvent(ImportEventKind.rateLimited, importId));
    await pumpEventQueue();
    expect(c.read(activityLogProvider).first.failed, isTrue);
    await events.close();
  });
}
