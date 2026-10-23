import 'dart:io';

import 'package:path/path.dart' as p;

import 'exportify_reader.dart' show CsvTooLargeException, checkCsvSize;
import 'exportify_zip.dart';
import 'playlist_reader.dart';

/// Reads a file the user picked or that arrived from outside: an
/// [ExportifyZipResult] for a ZIP, else an `ImportedPlaylist`. Throws
/// [CsvTooLargeException] or [FormatException] when it is not usable.
Future<Object> readImportPath(String path) async {
  final name = p.basename(path);
  final size = await File(path).length();
  if (name.toLowerCase().endsWith('.zip')) {
    if (size > kMaxZipBytes) throw CsvTooLargeException('ZIP of $size bytes');
    return readExportifyZip(await File(path).readAsBytes());
  }
  checkCsvSize(size);
  final text = decodePlaylistBytes(name, await File(path).readAsBytes());
  final csv = await readPlaylistFileInIsolate(name, text);
  return csv.withBaseDir(p.dirname(path));
}
