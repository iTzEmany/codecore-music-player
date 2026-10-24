import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import 'database_providers.dart';
import 'youtube_providers.dart';

/// Library folders: adding, removing and the download destination.
class FolderOps {
  FolderOps(this._ref);

  final Ref _ref;

  Future<Folder> add(String path) => _ref.read(folderRepositoryProvider).add(path);

  /// Its tracks leave the library with it.
  Future<void> remove(int id) => _ref.read(folderRepositoryProvider).remove(id);

  /// Where downloads go (registered as a library folder), or null if none.
  Future<(Directory, Folder)?> downloadFolder() => resolveDownloadFolder(_ref.read(folderRepositoryProvider));
}

final folderOpsProvider = Provider<FolderOps>(FolderOps.new);
