// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Codecore';

  @override
  String get chooseFolder => 'Choose folder';

  @override
  String get scan => 'Scan';

  @override
  String get noTracks => 'No tracks. Choose a folder and scan.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get permissionDenied => 'Audio read permission denied';

  @override
  String get permissionExplain =>
      'Codecore needs permission to read audio files to show your music.';

  @override
  String get navLibrary => 'Library';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSettings => 'Settings';

  @override
  String get tracks => 'Tracks';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artists';

  @override
  String get searchHint => 'Search';

  @override
  String get sortBy => 'Sort by';

  @override
  String get addMusicFolder => 'Add your music folder';

  @override
  String get addFolder => 'Add folder';

  @override
  String get folders => 'Music folders';

  @override
  String get refreshLibrary => 'Refresh library';

  @override
  String get removeFolder => 'Remove folder';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get variousArtists => 'Various artists';

  @override
  String get play => 'Play';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get queue => 'Queue';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get nothingPlaying => 'Nothing playing';

  @override
  String get mute => 'Mute';

  @override
  String get scanning => 'Scanning…';

  @override
  String get emptyQueue => 'The queue is empty';

  @override
  String get noResults => 'No results';

  @override
  String get sortDefault => 'Default';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortYear => 'Year';

  @override
  String get sortAdded => 'Recently added';

  @override
  String get sortDuration => 'Duration';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String missingTracksCount(int count) {
    return 'Missing tracks ($count)';
  }

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get undo => 'Undo';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get newPlaylistEllipsis => 'New playlist…';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get create => 'Create';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get noPlaylists => 'No playlists. Create one.';

  @override
  String get addToPlaylist => 'Add to playlist…';

  @override
  String addedToPlaylist(String name) {
    return 'Added to “$name”';
  }

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get favorite => 'Favorite';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get removeFromList => 'Remove';

  @override
  String get editInfo => 'Edit info';

  @override
  String get details => 'Details';

  @override
  String get showInFolder => 'Show in folder';

  @override
  String get detailPath => 'Path';

  @override
  String get detailFormat => 'Format';

  @override
  String get detailSize => 'Size';

  @override
  String get detailDuration => 'Duration';

  @override
  String get detailAdded => 'Added on';

  @override
  String get detailPlays => 'Plays';

  @override
  String get close => 'Close';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldArtist => 'Artist';

  @override
  String get fieldAlbum => 'Album';

  @override
  String get fieldAlbumArtist => 'Album artist';

  @override
  String get fieldYear => 'Year';

  @override
  String get fieldTrackNumber => 'Track number';

  @override
  String get fieldGenre => 'Genre';

  @override
  String get restoreFromFile => 'Restore from file tags';

  @override
  String get titleRequired => 'Title cannot be empty';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeCarbon => 'Carbon';

  @override
  String get themeNavy => 'Navy';

  @override
  String get themeLight => 'Light';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get textSmall => 'Small';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Large';

  @override
  String get settingsCompact => 'Compact mode';

  @override
  String get settingsReducedMotion => 'Reduce animations';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLibrary => 'Library';

  @override
  String get rescanNow => 'Rescan now';

  @override
  String get clearCoverCache => 'Clear cover cache';

  @override
  String get coverCacheCleared => 'Cover cache cleared';

  @override
  String get settingsOnline => 'Online';

  @override
  String get autoEnrich => 'Automatic enrichment';

  @override
  String get autoEnrichHint =>
      'Look up metadata and covers online for new tracks';

  @override
  String get autoLyrics => 'Automatic lyrics';

  @override
  String get autoLyricsHint => 'Download lyrics from LRCLIB for new tracks';

  @override
  String get settingsAbout => 'About';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get licenses => 'Licenses';

  @override
  String get personalUse => 'Personal-use app';

  @override
  String get missingTracksTitle => 'Missing tracks';

  @override
  String get removeFromLibrary => 'Remove from library';

  @override
  String get ignore => 'Ignore';

  @override
  String get confirmRemoveTitle => 'Remove from library?';

  @override
  String get confirmRemoveBody =>
      'The file is not touched; you lose favorites and playlists for this track.';

  @override
  String get noMissingTracks => 'No missing tracks';

  @override
  String get retry => 'Retry';

  @override
  String scanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String playbackError(String reason, String title) {
    return 'Cannot play “$title”: $reason';
  }

  @override
  String get reasonFileMissing => 'file not found';

  @override
  String get reasonUnplayable => 'file cannot be played';

  @override
  String get reasonNotInLibrary => 'track not in library';

  @override
  String get searchWeb => 'Search info online';

  @override
  String get enrichPreviewTitle => 'Information preview';

  @override
  String get currentValue => 'Current';

  @override
  String get proposedValue => 'Proposed';

  @override
  String get apply => 'Apply';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get userEditedLocked => 'Edited by you: will not be overwritten';

  @override
  String get fieldCover => 'Cover';

  @override
  String get fieldLyrics => 'Lyrics';

  @override
  String get fieldCuriosity => 'Trivia';

  @override
  String get enrichAlbum => 'Enrich album';

  @override
  String get enrichLibrary => 'Enrich whole library';

  @override
  String get enrichConfirmTitle => 'Enrich the library?';

  @override
  String enrichConfirmBody(int count, int minutes) {
    return '$count tracks, about $minutes minutes. Only empty fields are filled.';
  }

  @override
  String enrichRunning(int done, int total) {
    return 'Enriching $done/$total';
  }

  @override
  String enrichResult(int notFound, int updated) {
    return '$updated updated, $notFound not found';
  }

  @override
  String get enrichBusy => 'An enrichment is already running';

  @override
  String get serviceUnavailable => 'Service unavailable, try again later';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get searchLyrics => 'Search lyrics';

  @override
  String get noLyrics => 'No lyrics available';

  @override
  String get lyricsNotFound => 'Lyrics not found';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get sourceWikipedia => 'Source: Wikipedia (CC BY-SA)';

  @override
  String get youtube => 'YouTube';

  @override
  String get ytHint => 'Search or paste a link';

  @override
  String get ytDownload => 'Download';

  @override
  String get ytAlreadyInLibrary => 'Already in library';

  @override
  String get ytNoResults => 'No results';

  @override
  String get ytQueued => 'Queued';

  @override
  String get ytDownloading => 'Downloading';

  @override
  String get ytDone => 'Done';

  @override
  String get ytFailed => 'Failed';

  @override
  String get ytCancelled => 'Cancelled';

  @override
  String get ytClearCompleted => 'Clear completed';

  @override
  String get ytCancel => 'Cancel download';

  @override
  String get ytErrUnavailable => 'Video unavailable (age/region/private)';

  @override
  String get ytErrNetwork => 'Network unavailable';

  @override
  String get ytErrChanged =>
      'YouTube changed something: update the app or package';

  @override
  String get ytNoFolder => 'Add a music folder first';

  @override
  String get ytLegal =>
      'Personal use only. Respect copyright and YouTube’s terms.';

  @override
  String get useDefaultFolder => 'Use the device Music folder';

  @override
  String get ytErrToolMissing =>
      'yt-dlp not found: install it (pip install -U yt-dlp) and retry';
}
