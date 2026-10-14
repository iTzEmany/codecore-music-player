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
