import 'dart:isolate';

import 'csv_profiles.dart';
import 'imported_playlist.dart';

export 'csv_profiles.dart'
    show
        CsvTooLargeException,
        checkCsvSize,
        kMaxCsvBytes,
        kMaxCsvRows,
        playlistNameFromFile;
export 'imported_playlist.dart';

/// Kept for the callers and tests written when Exportify was the only source.
typedef ExportifyPlaylist = ImportedPlaylist;

/// Exportify files are read like any other CSV: columns are found by name.
ImportedPlaylist readExportify(String fileName, String text) =>
    readCsvPlaylist(fileName, text);

/// Same as [readExportify], off the UI thread (a CSV can have thousands of rows).
Future<ImportedPlaylist> readExportifyInIsolate(String fileName, String text) =>
    Isolate.run(() => readExportify(fileName, text));
