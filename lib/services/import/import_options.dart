/// What the user chose in the preview, stored with the import.
class ImportOptions {
  const ImportOptions({
    this.linkOnly = false,
    this.planFirst = false,
    this.folderPath,
    this.numberFiles = false,
    this.fetchCovers = false,
  });

  /// Link what the library has, search and download nothing.
  final bool linkOnly;

  /// Search every row first and wait for the user before downloading.
  final bool planFirst;

  /// Download into this sub-folder of the download folder.
  final String? folderPath;

  /// Prefix file names with the row number.
  final bool numberFiles;

  /// Look the album cover up after each download.
  final bool fetchCovers;
}

/// Short codes kept in `playlist_import_items.note`; the UI turns them into text.
abstract final class ImportNote {
  static const noResults = 'no_results';
  static const lowScore = 'low_score';
  static const linkOnly = 'link_only';
  static const youtubeOff = 'youtube_off';
  static const downloadFailed = 'download_failed';
  static const lengthOff = 'length_off';
}
