import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'exportify_reader.dart';

typedef PlaylistReader = ImportedPlaylist Function(String fileName, String text);

/// File extensions the importer can read, each with the function that does.
final Map<String, PlaylistReader> playlistReaders = {
  'csv': readExportify,
};

List<String> get supportedPlaylistExtensions => playlistReaders.keys.toList();

String _extension(String fileName) {
  final base = fileName.split(RegExp(r'[\\/]')).last;
  final dot = base.lastIndexOf('.');
  return dot < 0 ? '' : base.substring(dot + 1).toLowerCase();
}

/// Reads [text] with the reader for [fileName]'s extension. Throws
/// [FormatException] listing the supported formats when there is none.
ImportedPlaylist readPlaylistFile(String fileName, String text) {
  final reader = playlistReaders[_extension(fileName)];
  if (reader == null) {
    throw FormatException('unrecognised format "${_extension(fileName)}"; '
        'supported: ${supportedPlaylistExtensions.join(', ')}');
  }
  return reader(fileName, text);
}

/// Same as [readPlaylistFile], off the UI thread (a file can have thousands of rows).
Future<ImportedPlaylist> readPlaylistFileInIsolate(String fileName, String text) =>
    Isolate.run(() => readPlaylistFile(fileName, text));

/// UTF-8; `.m3u` files written by old players fall back to Latin-1 when the
/// bytes are not valid UTF-8.
String decodePlaylistBytes(String fileName, Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    final ext = _extension(fileName);
    return ext == 'm3u'
        ? latin1.decode(bytes)
        : utf8.decode(bytes, allowMalformed: true);
  }
}
