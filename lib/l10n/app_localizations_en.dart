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
  String get themeNotte => 'Purple night';

  @override
  String get themeOled => 'Pure black';

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

  @override
  String get ytErrRateLimited =>
      'YouTube asked to slow down: try again in a few minutes';

  @override
  String get playlistChangeCover => 'Change cover';

  @override
  String get playlistRemoveCover => 'Remove cover';

  @override
  String get coverTooLarge => 'Image too large (max 4 MB)';

  @override
  String get addSongs => 'Add songs';

  @override
  String addNSongs(int count) {
    return 'Add ($count)';
  }

  @override
  String get allSongsInPlaylist => 'All songs are already in the playlist';

  @override
  String get shareTitle => 'Sharing';

  @override
  String get shareSend => 'Send';

  @override
  String get shareReceive => 'Receive';

  @override
  String get shareAll => 'Whole library';

  @override
  String shareSelection(int count) {
    return 'Selection ($count tracks)';
  }

  @override
  String get sharePick => 'Choose tracks';

  @override
  String get shareStart => 'Start sharing';

  @override
  String get shareStop => 'Stop';

  @override
  String get shareActive => 'Sharing is on';

  @override
  String get shareAddress => 'Address (IP:port)';

  @override
  String get sharePin => 'PIN';

  @override
  String get shareConnect => 'Connect';

  @override
  String shareDownloadSelected(int count) {
    return 'Download selected ($count)';
  }

  @override
  String shareProgress(int done, int total) {
    return 'Track $done of $total';
  }

  @override
  String shareDone(int count) {
    return '$count tracks received';
  }

  @override
  String shareConnectedTo(String name) {
    return 'Connected to $name';
  }

  @override
  String get shareErrUnreachable =>
      'Device unreachable: check address and Wi‑Fi';

  @override
  String get shareErrPin => 'Wrong PIN';

  @override
  String get shareErrBlocked => 'Too many attempts: retry in a minute';

  @override
  String get shareErrNotCodecore => 'Not a Codecore device';

  @override
  String get shareErrFailed => 'Transfer failed';

  @override
  String get shareNoNetwork => 'No local network found';

  @override
  String get shareFirewall =>
      'Windows may ask for firewall permission the first time.';

  @override
  String get shareHint =>
      'On the same Wi‑Fi, open “Receive” on the other device and enter address and PIN.';

  @override
  String get shareMenu => 'Share…';

  @override
  String get shareDeviceName => 'Device name';

  @override
  String get importOld => 'Import from the old app';

  @override
  String get importOldHint =>
      'Choose codecore_library.db from the Python version';

  @override
  String importSummary(
    int favorites,
    int lyrics,
    int playlists,
    int unmatched,
  ) {
    return '$favorites favorites, $playlists playlists, $lyrics lyrics imported, $unmatched unmatched';
  }

  @override
  String get importFailed => 'Import failed: invalid file';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String sleepMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get sleepEndOfTrack => 'At end of track';

  @override
  String get sleepCancel => 'Cancel timer';

  @override
  String get pause => 'Pause';

  @override
  String get nextTrack => 'Next track';

  @override
  String get previousTrack => 'Previous track';

  @override
  String get repeat => 'Repeat';

  @override
  String get moreOptions => 'More options';

  @override
  String get back => 'Back';

  @override
  String get settingsPlayback => 'Playback';

  @override
  String get normalizeVolume => 'Normalize volume';

  @override
  String get normalizeVolumeHint =>
      'Uses files’ ReplayGain to lower tracks that are too loud';

  @override
  String get nearbyDevices => 'Nearby devices';

  @override
  String get searchingDevices => 'Looking for devices on the network…';

  @override
  String get noDevicesHint =>
      'No device found. Open Sharing on the other device too, on the same network.';

  @override
  String sendToDevice(String name) {
    return 'Send to $name';
  }

  @override
  String offerSent(String name) {
    return 'Request sent to $name';
  }

  @override
  String get offerChooseFirst => 'Choose the tracks to send first';

  @override
  String get sentRequests => 'Sent requests';

  @override
  String get receivedRequests => 'Received requests';

  @override
  String get offerPending => 'Waiting for a reply';

  @override
  String get offerAccepted => 'Accepted';

  @override
  String get offerDeclined => 'Declined';

  @override
  String get offerCancelled => 'Cancelled';

  @override
  String get offerExpired => 'Expired';

  @override
  String get offerDone => 'Completed';

  @override
  String get offerFailed => 'Failed';

  @override
  String incomingTitle(String name) {
    return '$name wants to send you tracks';
  }

  @override
  String incomingBody(int count, String size) {
    return '$count tracks, $size MB';
  }

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String receivingProgress(int done, int total) {
    return 'Receiving $done/$total';
  }

  @override
  String get manualConnection => 'Manual connection (IP and PIN)';

  @override
  String get receiveFromLan => 'Receive from the local network';

  @override
  String get receiveFromLanHint =>
      'Makes this device visible and receives requests even in the background. On Android it shows a permanent notification you can use to turn it off';

  @override
  String get receiveServiceTitle => 'Codecore is visible on the network';

  @override
  String get receiveServiceText =>
      'Ready to receive tracks from nearby devices';

  @override
  String get receiveServiceDisable => 'Turn off';

  @override
  String get jamTitle => 'Jam';

  @override
  String get jamStart => 'Start a Jam';

  @override
  String jamStartWith(String name) {
    return 'Start Jam with $name';
  }

  @override
  String jamWaiting(String name) {
    return 'Waiting for $name to accept…';
  }

  @override
  String jamDeclined(String name) {
    return '$name declined the Jam';
  }

  @override
  String jamBusy(String name) {
    return '$name already has a Jam running';
  }

  @override
  String get jamUnreachable => 'Device unreachable';

  @override
  String jamIncomingTitle(String name) {
    return '$name wants to start a Jam';
  }

  @override
  String get jamIncomingBody => 'Listen together from a shared queue.';

  @override
  String jamIncomingDialog(String name) {
    return '$name wants to start a Jam with you. Music plays from this device and you can both add tracks.';
  }

  @override
  String get jamQueue => 'Shared queue';

  @override
  String get jamEmpty => 'The queue is empty. Add some tracks.';

  @override
  String jamAddedBy(String name) {
    return 'added by $name';
  }

  @override
  String get jamYou => 'you';

  @override
  String get jamAddTracks => 'Add tracks';

  @override
  String get jamAddToJam => 'Add to Jam';

  @override
  String jamAdded(int count) {
    return 'Added to the Jam: $count';
  }

  @override
  String get jamOutput => 'Audio output';

  @override
  String get jamOutputHere => 'This device';

  @override
  String jamOutputOther(String name) {
    return '$name';
  }

  @override
  String get jamEnd => 'End Jam';

  @override
  String get jamLeave => 'Leave Jam';

  @override
  String get jamEnded => 'The Jam has ended';

  @override
  String get jamLost => 'Connection lost';

  @override
  String get jamGuestCannotSkip => 'Only the host can change track';

  @override
  String get jamRemoveForbidden => 'You can only remove your own tracks';

  @override
  String get jamNowPlaying => 'Now playing';

  @override
  String get jamNothingPlaying => 'Nothing playing';

  @override
  String jamWith(String name) {
    return 'Jam with $name';
  }

  @override
  String get jamUnavailable => 'Unavailable';

  @override
  String get jamPlaying => 'Jam is active';

  @override
  String get jamOpen => 'Open Jam';

  @override
  String jamSynced(int ms) {
    return 'In sync · offset $ms ms';
  }

  @override
  String get jamSyncing => 'Synchronising…';

  @override
  String jamLatency(int ms) {
    return 'This output\'s latency: $ms ms';
  }

  @override
  String get jamLatencyHint =>
      'For Bluetooth headphones or speakers: raise it until the outputs line up.';

  @override
  String get jamOutputsHint => 'Several outputs play together';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get confirmDeletePlaylistTitle => 'Delete the playlist?';

  @override
  String confirmDeletePlaylistBody(String name) {
    return '“$name” will be deleted. The tracks stay in your library.';
  }

  @override
  String get confirmRemoveFolderTitle => 'Remove the folder?';

  @override
  String get confirmRemoveFolderBody =>
      'Its tracks leave the library. The files stay on the device.';

  @override
  String get confirmClearCoversTitle => 'Clear the cover cache?';

  @override
  String get confirmClearCoversBody => 'Covers are rebuilt at the next scan.';

  @override
  String get confirmRestoreTitle => 'Restore from the file tags?';

  @override
  String get confirmRestoreBody =>
      'Your edits to this track are replaced with the data in the file.';

  @override
  String get removedFromPlaylist => 'Removed from the playlist';

  @override
  String get removedFromQueue => 'Removed from the queue';

  @override
  String get playNextDone => 'Will play next';

  @override
  String get ytSearchPrompt => 'Search for a track or paste a link';

  @override
  String get loadFailed => 'Couldn\'t load the data.';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get devicesTitle => 'Devices';

  @override
  String get devicesJamActive => 'Active Jam';

  @override
  String jamPeople(int n) {
    return 'Jam · $n people';
  }

  @override
  String get devicesVisibleTitle => 'Make this device visible';

  @override
  String get devicesVisibleHint =>
      'To receive tracks or start a Jam, other devices need to see you on the network.';

  @override
  String get devicesJamShort => 'Jam';

  @override
  String get devicesSendShort => 'Send';

  @override
  String get devicesMore => 'Sharing and manual connection';

  @override
  String jamParticipantsCount(int n) {
    return '$n people';
  }

  @override
  String get playingFrom => 'Playing from';

  @override
  String get playContextSearch => 'Search';

  @override
  String get allTracks => 'All tracks';

  @override
  String get trackInfo => 'About this track';

  @override
  String get searchCuriosity => 'Look up trivia';

  @override
  String get upNext => 'Up next';

  @override
  String get openQueue => 'Open queue';

  @override
  String get copyLink => 'Copy link';

  @override
  String get moreActions => 'More actions';

  @override
  String get sleepChipEnd => 'end of track';

  @override
  String get yourLibrary => 'Your library';

  @override
  String playlistCountLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Playlist · $n tracks',
      one: 'Playlist · 1 track',
    );
    return '$_temp0';
  }

  @override
  String get sortRecent => 'Recents';

  @override
  String get sortAlphabetical => 'Alphabetical';

  @override
  String get sortAddedRecently => 'Recently added';

  @override
  String get viewAsGrid => 'Show as grid';

  @override
  String get viewAsList => 'Show as list';

  @override
  String get kindAlbum => 'Album';

  @override
  String get kindArtist => 'Artist';

  @override
  String get kindPlaylist => 'Playlist';

  @override
  String discN(int n) {
    return 'Disc $n';
  }

  @override
  String albumMeta(String details) {
    return 'Album · $details';
  }

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

  @override
  String tracksAndDuration(String tracks, String duration) {
    return '$tracks, $duration';
  }

  @override
  String get mostPlayed => 'Most played';

  @override
  String get albumsSection => 'Albums';

  @override
  String artistMeta(String albums, String tracks) {
    return '$albums · $tracks';
  }

  @override
  String get addAllToQueue => 'Add to queue';

  @override
  String addedNToQueue(int n) {
    return '$n tracks added to the queue';
  }

  @override
  String get editOrder => 'Edit order';

  @override
  String get finishEditing => 'Done';

  @override
  String get removeFromPlaylistAction => 'Remove from playlist';

  @override
  String get noTracksInPlaylist => 'This playlist is empty';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get homeResume => 'Jump back in';

  @override
  String get homeRecentlyPlayed => 'Recently played';

  @override
  String get homeRecentlyAdded => 'Recently added';

  @override
  String get homeTopTracks => 'Most played';

  @override
  String get homeRediscover => 'Rediscover';

  @override
  String get searchMainResult => 'Top result';

  @override
  String get showAll => 'Show all';

  @override
  String searchOnYoutube(String query) {
    return 'Search “$query” on YouTube';
  }

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get genresTitle => 'Genres';

  @override
  String downloadsChip(int n) {
    return 'Downloads ($n)';
  }

  @override
  String get gotIt => 'Got it';

  @override
  String get searchEmptyLibrary => 'No results in your library';

  @override
  String get ytInfoTooltip => 'About usage';

  @override
  String get removeRecentSearch => 'Remove from recent searches';

  @override
  String get groupGoTo => 'Go to';

  @override
  String get goToAlbum => 'Go to album';

  @override
  String get goToArtist => 'Go to artist';

  @override
  String get groupQueue => 'Queue';

  @override
  String get groupCollection => 'Collection';

  @override
  String get groupEdit => 'Edit';

  @override
  String get groupOther => 'More';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueNext => 'Next up';

  @override
  String get queueClear => 'Clear';

  @override
  String get queueCleared => 'Queue cleared';

  @override
  String get jamOutputsAndSync => 'Outputs and sync';

  @override
  String get jamHostTag => 'host';

  @override
  String get jamWaitingEmpty => 'No Jam in progress';

  @override
  String get activityTitle => 'Activity';

  @override
  String activityScan(int done, int total) {
    return 'Scanning · $done/$total';
  }

  @override
  String get activityScanIdle => 'Scanning';

  @override
  String activityEnrich(int done, int total) {
    return 'Enriching · $done/$total';
  }

  @override
  String activityDownload(String title) {
    return 'Download · $title';
  }

  @override
  String activityTransfer(String name, int n) {
    return 'Sending to $name · $n tracks';
  }

  @override
  String get activityNone => 'No activity';

  @override
  String get activityCompleted => 'Completed';

  @override
  String get activityClear => 'Clear';

  @override
  String activityRunning(int n) {
    return '$n activities running';
  }

  @override
  String get settingsLocalNetwork => 'Local network';

  @override
  String get removeAll => 'Remove all';

  @override
  String get confirmRemoveAllTitle => 'Remove all from the library?';

  @override
  String confirmRemoveAllBody(int n) {
    return '$n missing tracks will be removed from the library. Files are not touched; you lose their favourites and playlist entries.';
  }

  @override
  String get csvImportMenu => 'Import from Exportify (CSV)';

  @override
  String get csvImportIntroTitle => 'Import a playlist';

  @override
  String get csvImportIntroSource =>
      'The CSV file is created for free on the Exportify website — exportify.net (no app needed).';

  @override
  String get csvImportStep1 =>
      'Open https://exportify.net in a browser (the phone works too).';

  @override
  String get csvImportStep2 =>
      'Tap “Get Started” and sign in with your Spotify account.';

  @override
  String get csvImportStep3 =>
      'Next to the playlist you want, tap “Export”: a .csv file named after the playlist is downloaded.';

  @override
  String get csvImportStep4 => 'Come back here and tap “Choose CSV file”.';

  @override
  String get csvImportNote =>
      'Codecore looks for the tracks in your library and downloads the others from YouTube Music.';

  @override
  String get csvImportNoteOffline =>
      'Only tracks already in your library will be linked.';

  @override
  String get csvImportCopy => 'Copy address';

  @override
  String get csvImportCopied => 'Address copied';

  @override
  String get csvImportPick => 'Choose file';

  @override
  String get csvImportNotExportify =>
      'Unrecognised format. Choose a CSV (Exportify, TuneMyMusic, Soundiiz, Last.fm) or an M3U/M3U8/XSPF playlist.';

  @override
  String get csvImportReadFailed => 'The file could not be read.';

  @override
  String get csvImportPreviewTitle => 'Import playlist';

  @override
  String get csvImportName => 'Playlist name';

  @override
  String csvImportSummary(int total, int known, int todo) {
    return '$total tracks · $known already in library · $todo to download';
  }

  @override
  String csvImportSkipped(int n) {
    return '$n rows ignored (podcasts or local files)';
  }

  @override
  String csvImportEstimate(int minutes) {
    return 'Estimated time: about $minutes min';
  }

  @override
  String get csvImportExists => 'A playlist with this name already exists';

  @override
  String get csvImportUpdate =>
      'Update the existing one (adds only new tracks)';

  @override
  String get csvImportNew => 'Create a new playlist';

  @override
  String get csvImportGo => 'Import';

  @override
  String get csvImportStarted =>
      'Import started: follow it in the Activity Center';

  @override
  String activityImport(String name, int done, int total) {
    return 'Import “$name” · $done/$total';
  }

  @override
  String activityImportPaused(String name, int done, int total) {
    return 'Import “$name” · paused · $done/$total';
  }

  @override
  String csvImportBanner(int done, int total, int review, int missing) {
    return 'Import: $done/$total · $review to review · $missing not found';
  }

  @override
  String csvImportBannerPaused(int done, int total, int review, int missing) {
    return 'Import paused: $done/$total · $review to review · $missing not found';
  }

  @override
  String get csvImportReview => 'Review';

  @override
  String get csvImportResume => 'Resume';

  @override
  String get csvImportPause => 'Pause';

  @override
  String get csvImportCancelTitle => 'Cancel the import?';

  @override
  String get csvImportCancelBody =>
      'Tracks already downloaded stay in the playlist.';

  @override
  String csvImportDone(int added, int review, int missing) {
    return 'Import finished: $added added, $review to review, $missing not found';
  }

  @override
  String get csvImportFailing => 'Too many errors in a row: import paused';

  @override
  String get csvImportReviewTitle => 'Review';

  @override
  String get csvImportToReview => 'To review';

  @override
  String get csvImportNotFound => 'Not found';

  @override
  String get csvImportErrors => 'With errors';

  @override
  String get csvImportRetryAll => 'Retry all';

  @override
  String get csvImportSkip => 'Skip';

  @override
  String get csvImportManual => 'Search manually';

  @override
  String get csvImportNothing => 'Nothing to review.';

  @override
  String get csvImportSearch => 'Search';

  @override
  String csvImportWanted(String title, String artist, String duration) {
    return 'Wanted: $title · $artist · $duration';
  }

  @override
  String get csvImportDownload => 'Download';

  @override
  String get csvImportCancelGo => 'Cancel import';

  @override
  String get exportLog => 'Export log';

  @override
  String get exportLogHint =>
      'Text file without personal paths, network addresses or PINs';

  @override
  String get exportLogDebugOnly =>
      'Only in the installed version (debug builds don\'t write the log to a file)';

  @override
  String get exportLogNone => 'There is no log to export yet';

  @override
  String get exportLogSaved => 'Log saved';

  @override
  String get exportLogFailed => 'Couldn\'t save the log';

  @override
  String get exportPlaylist => 'Export…';

  @override
  String get exportPlaylistTitle => 'Export playlist';

  @override
  String get exportFormatM3u8 => 'M3U8 · for other players';

  @override
  String get exportFormatCsv => 'CSV · like Exportify';

  @override
  String get exportFormatJson => 'JSON · Codecore format';

  @override
  String get exportRelativePaths => 'Relative paths';

  @override
  String get exportRelativeHint =>
      'Relative to the folder shared by all tracks: save the file there';

  @override
  String get exportAction => 'Export';

  @override
  String get exportSaved => 'Playlist exported';

  @override
  String get exportEmpty => 'The playlist is empty';

  @override
  String get exportFailed => 'Couldn\'t export the playlist';

  @override
  String get ytErrToolOutdated =>
      'yt-dlp is too old: update it (Settings → Downloads → Update) and try again';

  @override
  String ytDlpOutdatedBanner(String version) {
    return 'yt-dlp $version is too old: downloads may not work';
  }

  @override
  String get settingsDownloads => 'Downloads';

  @override
  String ytDlpVersion(String version) {
    return 'yt-dlp $version';
  }

  @override
  String get ytDlpUnknownVersion => 'yt-dlp not found';

  @override
  String get ytDlpUpdate => 'Update';

  @override
  String ytDlpUpdating(int percent) {
    return 'Updating… $percent%';
  }

  @override
  String ytDlpUpdated(String version) {
    return 'Updated to version $version';
  }

  @override
  String get ytDlpTooOld => 'Too old: tap Update';

  @override
  String get ytDlpUpdateErrNetwork => 'Update failed: network unreachable';

  @override
  String get ytDlpUpdateErrHash =>
      'Update cancelled: the downloaded file failed the integrity check';

  @override
  String get ytDlpUpdateErrOther => 'Update failed (see the log)';

  @override
  String get downloadParallel => 'Simultaneous downloads';

  @override
  String get downloadParallelHint =>
      'More at once is faster, but YouTube may ask you to slow down';

  @override
  String get downloadRateLimit => 'Speed limit';

  @override
  String get downloadRateNone => 'None';

  @override
  String downloadRateKb(int kb) {
    return '$kb KB/s';
  }

  @override
  String downloadRateMb(int mb) {
    return '$mb MB/s';
  }

  @override
  String activityDownloadRetry(
    String title,
    int seconds,
    int attempt,
    int max,
  ) {
    return 'Download · $title · retrying in $seconds s ($attempt/$max)';
  }

  @override
  String get downloadOriginal => 'Original quality (no re-encoding)';

  @override
  String get downloadOriginalHint =>
      'Keeps YouTube\'s audio as served (M4A/Opus): no extra loss, smaller files. Off: MP3 256 kbps';

  @override
  String get searchCacheClear => 'Clear search cache';

  @override
  String searchCacheCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved searches',
      one: '1 saved search',
      zero: 'Empty',
    );
    return '$_temp0';
  }

  @override
  String get searchCacheCleared => 'Cache cleared';

  @override
  String csvImportLengthOff(String found, String wanted) {
    return 'Different length: $found instead of $wanted';
  }

  @override
  String get csvImportKeep => 'Keep this one';

  @override
  String get csvImportTooBig =>
      'The file is too big to be a playlist (5 MB and 10,000 tracks at most)';

  @override
  String get csvImportAlsoAccepts =>
      'Also accepted: TuneMyMusic, Soundiiz, Last.fm (CSV), M3U/M3U8, XSPF.';

  @override
  String get csvImportPlanned => 'Matches ready: check them and download';

  @override
  String get csvImportLinkOnly => 'Link only (no downloads)';

  @override
  String get csvImportLinkOnlyHint =>
      'Builds the playlist from what you already have, nothing more';

  @override
  String get csvImportPlanFirst => 'Review before downloading';

  @override
  String get csvImportPlanFirstHint =>
      'Searches everything, then you pick what to download';

  @override
  String get csvImportPlanTitle => 'Matches';

  @override
  String csvImportPlanGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Download $n songs',
      one: 'Download 1 song',
    );
    return '$_temp0';
  }

  @override
  String get csvImportPlanKnown => 'already downloaded';

  @override
  String get csvImportPlanEmpty => 'Nothing to download';

  @override
  String csvImportBannerPlanned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n songs to download',
      one: '1 song to download',
    );
    return 'Matches ready: $_temp0';
  }

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get importSureThreshold => 'Sure match from';

  @override
  String get importSureThresholdHint =>
      'Above this score an imported song is downloaded without asking';

  @override
  String get importReviewThreshold => 'To review from';

  @override
  String get importReviewThresholdHint =>
      'Between this score and the sure one the song goes to «To review»; below it, to «Not found»';

  @override
  String get importThresholdsReset => 'Restore defaults';

  @override
  String csvImportEstimateHours(int hours, int minutes) {
    return 'Estimated time: about $hours h $minutes min';
  }

  @override
  String csvImportBlocks(int size) {
    return 'Import in blocks of $size';
  }

  @override
  String csvImportBigWarning(int n) {
    return '$n songs to download: it will take hours. In blocks, one after the other, the playlist order stays right and you can stop between blocks.';
  }

  @override
  String get etaLessThanMinute => 'under 1 min';

  @override
  String etaMinutes(int minutes) {
    return 'about $minutes min';
  }

  @override
  String etaHours(int hours, int minutes) {
    return 'about $hours h $minutes min';
  }

  @override
  String get csvImportOwnFolder => 'Folder for this playlist';

  @override
  String get csvImportOwnFolderHint =>
      'Saves the downloads in a sub-folder named after the playlist';

  @override
  String get csvImportNumberFiles => 'Number the files';

  @override
  String get csvImportNumberFilesHint =>
      '07 - Artist - Title: the folder plays in the right order even outside Codecore';

  @override
  String get csvImportFetchCovers => 'Look up covers';

  @override
  String get csvImportFetchCoversHint =>
      'After each download, looks the album cover up on iTunes (album and artist from the file)';

  @override
  String get csvImportExport => 'Export result';

  @override
  String get csvImportExported => 'Result saved';

  @override
  String get csvOutHeaderRow => 'Row';

  @override
  String get csvOutHeaderTitle => 'Title';

  @override
  String get csvOutHeaderArtists => 'Artists';

  @override
  String get csvOutHeaderAlbum => 'Album';

  @override
  String get csvOutHeaderDuration => 'Duration (ms)';

  @override
  String get csvOutHeaderIsrc => 'ISRC';

  @override
  String get csvOutHeaderStatus => 'Result';

  @override
  String get csvOutHeaderNote => 'Reason';

  @override
  String get csvOutHeaderVideo => 'Chosen video';

  @override
  String get csvOutHeaderScore => 'Score';

  @override
  String get importStatusPending => 'To search';

  @override
  String get importStatusQueued => 'Queued';

  @override
  String get importStatusDownloaded => 'Downloaded';

  @override
  String get importStatusLinked => 'Already in library';

  @override
  String get importStatusReview => 'To review';

  @override
  String get importStatusNotFound => 'Not found';

  @override
  String get importStatusFailed => 'Error';

  @override
  String get importStatusSkipped => 'Skipped';

  @override
  String get importStatusPlanned => 'Planned';

  @override
  String get importStatusRemoved => 'Removed from the source';

  @override
  String get importNoteNoResults => 'No results';

  @override
  String get importNoteLowScore => 'Match not sure enough';

  @override
  String get importNoteLinkOnly => 'Link only: not searched';

  @override
  String get importNoteYoutubeOff => 'Downloads are off';

  @override
  String get importNoteDownloadFailed => 'Download failed';

  @override
  String get importNoteLengthOff => 'Length differs from the file';

  @override
  String get importNoteUnchanged => 'Already in the playlist';

  @override
  String get csvImportSync => 'Sync';

  @override
  String csvImportSyncCounts(int added, int removed) {
    return '+$added new · −$removed removed from the playlist (files stay)';
  }

  @override
  String get csvImportSyncChecking => 'Checking the differences…';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get playbackSpeedHint =>
      'The pitch stays the original one. The sleep timer counts real time, not the song\'s.';

  @override
  String resumeFrom(String time) {
    return 'resume at $time';
  }

  @override
  String get restartFromBeginning => 'Start from the beginning';

  @override
  String get previewTrack => '20 s preview';

  @override
  String get equalizer => 'Equalizer';

  @override
  String get eqOutputSpeaker => 'Speaker';

  @override
  String get eqOutputHeadphones => 'Headphones';

  @override
  String get eqHint =>
      'Each output remembers its own curve: it switches by itself when you plug in headphones.';

  @override
  String get eqPresetFlat => 'Flat';

  @override
  String get eqPresetBass => 'Bass';

  @override
  String get eqPresetVoice => 'Voice';

  @override
  String get eqPresetTreble => 'Treble';

  @override
  String get eqPresetCustom => 'Custom';

  @override
  String get eqReset => 'Reset';

  @override
  String get eqWaiting => 'The bands appear once the first song starts.';

  @override
  String get eqUnavailable => 'The equalizer is not available on this device.';

  @override
  String get transitionMode => 'Between tracks';

  @override
  String get transitionNormal => 'Normal';

  @override
  String get transitionGapless => 'Gapless';

  @override
  String get transitionCrossfade => 'Crossfade';

  @override
  String get transitionHint =>
      'Gapless works best with tracks of the same format (for example all FLAC).';

  @override
  String crossfadeLength(int seconds) {
    return 'Crossfade length: $seconds s';
  }

  @override
  String get crossfadePlainInAlbum => 'Don\'t fade inside an album';

  @override
  String get crossfadePlainInAlbumHint =>
      'Inside an album the tracks follow each other without a gap and without overlapping.';

  @override
  String get selectedRow => 'Selected';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get exitSelection => 'Exit selection';

  @override
  String get bulkActions => 'Actions';

  @override
  String playNextMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks will play next',
      one: '1 track will play next',
    );
    return '$_temp0';
  }

  @override
  String addedToQueueMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks added to the queue',
      one: '1 track added to the queue',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistMany(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks added to “$name”',
      one: '1 track added to “$name”',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistSkipped(int added, int skipped, String name) {
    return '$added added to “$name”, $skipped already there';
  }

  @override
  String allAlreadyInPlaylist(String name) {
    return 'They were all in “$name” already';
  }

  @override
  String favoritesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks added to favorites',
      one: '1 track added to favorites',
    );
    return '$_temp0';
  }

  @override
  String favoritesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks removed from favorites',
      one: '1 track removed from favorites',
    );
    return '$_temp0';
  }

  @override
  String get bulkAddToFavorites => 'Add to favorites';

  @override
  String get bulkRemoveFromFavorites => 'Remove from favorites';

  @override
  String removeManyFromPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count tracks from the playlist?',
      one: 'Remove 1 track from the playlist?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromPlaylistBody =>
      'The files and the library are not touched.';

  @override
  String removedManyFromPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks removed',
      one: '1 track removed',
    );
    return '$_temp0';
  }

  @override
  String removeManyFromLibraryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count tracks from the library?',
      one: 'Remove 1 track from the library?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromLibraryBody =>
      'The files no longer exist: they only disappear from the library (you lose these tracks\' favorites and playlist entries).';

  @override
  String removedManyFromLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks removed from the library',
      one: '1 track removed from the library',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads started',
      one: '1 download started',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsSkipped(int started, int skipped) {
    return '$started downloads started, $skipped already in the library or in progress';
  }

  @override
  String get ytNothingToDownload =>
      'They are all in the library or in progress already';

  @override
  String get themeChiaro => 'Light';

  @override
  String get settingsAccent => 'Accent colour';

  @override
  String get accentViola => 'Violet';

  @override
  String get accentBlu => 'Blue';

  @override
  String get accentAcqua => 'Teal';

  @override
  String get accentVerde => 'Green';

  @override
  String get accentAmbra => 'Amber';

  @override
  String get accentArancio => 'Orange';

  @override
  String get accentRosa => 'Pink';

  @override
  String get accentRosso => 'Red';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String onboardingPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Welcome to Codecore';

  @override
  String get onboardingWelcomeBody =>
      'Your personal music player: no account, no server. Your music stays on your device.';

  @override
  String get onboardingFoldersTitle => 'Your music';

  @override
  String get onboardingFoldersBody =>
      'Choose the folders where you keep your tracks. Codecore reads them: it never edits or moves them.';

  @override
  String onboardingFoldersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders added',
      one: '1 folder added',
    );
    return '$_temp0';
  }

  @override
  String get onboardingAllowAccess => 'Allow access to audio files';

  @override
  String get onboardingAccessGranted => 'Access granted';

  @override
  String get onboardingOnlineTitle => 'Online features';

  @override
  String get onboardingOnlineBody =>
      'They are off: Codecore never goes online on its own. You can turn them on now or later in Settings.';

  @override
  String get onboardingShareTitle => 'Downloads, Jam and sharing';

  @override
  String get onboardingYoutubeBody =>
      'You can download tracks from YouTube to your device and listen to them like the rest of your music.';

  @override
  String get onboardingJamBody =>
      'With a Jam you listen to the same music together with another device on the same network.';

  @override
  String get onboardingSendBody =>
      'You can send tracks to other nearby devices with a PIN, without going through the Internet.';
}
