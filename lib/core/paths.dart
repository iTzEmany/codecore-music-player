import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> appSupportDir() async {
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  return dir.path;
}

Future<String> coversDir() async {
  final dir = Directory(p.join(await appSupportDir(), 'covers'));
  await dir.create(recursive: true);
  return dir.path;
}

/// The database file `driftDatabase(name: 'codecore')` opens.
Future<File> databaseFile() async =>
    File(p.join((await getApplicationDocumentsDirectory()).path, 'codecore.sqlite'));

/// Where a backup waits to replace the database at the next start.
Future<Directory> restoreStagingDir() async => Directory(p.join(await appSupportDir(), 'restore'));
