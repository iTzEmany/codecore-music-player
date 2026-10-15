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
}
