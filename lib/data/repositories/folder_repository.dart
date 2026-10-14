import 'package:drift/drift.dart';

import '../db/app_database.dart';

class FolderRepository {
  FolderRepository(this._db);

  final AppDatabase _db;

  Future<Folder> add(String path) async {
    await _db.into(_db.folders).insert(
          FoldersCompanion.insert(
              path: path, addedAt: DateTime.now().millisecondsSinceEpoch),
          mode: InsertMode.insertOrIgnore,
        );
    return (_db.select(_db.folders)..where((f) => f.path.equals(path)))
        .getSingle();
  }

  Future<void> remove(int id) =>
      (_db.delete(_db.folders)..where((f) => f.id.equals(id))).go();

  Stream<List<Folder>> watchAll() => _db.select(_db.folders).watch();

  Future<List<Folder>> getAll() => _db.select(_db.folders).get();
}
