import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/backup_queries.dart';
import 'package:codecore/data/repositories/hidden_playlists.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seed() async {
    final shown = await db.into(db.playlists).insert(
        PlaylistsCompanion.insert(name: 'Mine', createdAt: 1));
    final hidden = await db.into(db.playlists).insert(
        PlaylistsCompanion.insert(name: 'The Wall', createdAt: 2));
    for (final (id, kind) in [(shown, 'exportify'), (hidden, ytmAlbumSourceKind)]) {
      await db.into(db.playlistImports).insert(PlaylistImportsCompanion.insert(
          playlistId: id, sourceName: 'x', createdAt: 1, sourceKind: Value(kind)));
    }
  }

  test('visiblePlaylists leaves out the technical album playlist', () async {
    await seed();
    expect((await db.select(db.playlists).get()).length, 2);
    expect([for (final p in await db.visiblePlaylists()) p.name], ['Mine']);
  });

  test('the portable backup has neither the playlist nor its import', () async {
    await seed();
    final data = await collectUserData(db);
    expect([for (final p in data.playlists) p.name], ['Mine']);
    expect(data.imports.length, 1);
  });
}
