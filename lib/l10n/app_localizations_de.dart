// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Codecore';

  @override
  String get chooseFolder => 'Ordner wählen';

  @override
  String get scan => 'Scannen';

  @override
  String get noTracks => 'Keine Titel. Ordner wählen und scannen.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get permissionDenied => 'Leseberechtigung für Audio verweigert';

  @override
  String get permissionExplain =>
      'Codecore benötigt die Berechtigung, Audiodateien zu lesen, um deine Musik anzuzeigen.';

  @override
  String get navLibrary => 'Bibliothek';

  @override
  String get navFavorites => 'Favoriten';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get tracks => 'Titel';

  @override
  String get albums => 'Alben';

  @override
  String get artists => 'Künstler';

  @override
  String get searchHint => 'Suchen';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get addMusicFolder => 'Füge deinen Musikordner hinzu';

  @override
  String get addFolder => 'Ordner hinzufügen';

  @override
  String get folders => 'Musikordner';

  @override
  String get refreshLibrary => 'Bibliothek aktualisieren';

  @override
  String get removeFolder => 'Ordner entfernen';

  @override
  String get unknownArtist => 'Unbekannter Künstler';

  @override
  String get unknownAlbum => 'Unbekanntes Album';

  @override
  String get variousArtists => 'Verschiedene Künstler';

  @override
  String get play => 'Wiedergabe';

  @override
  String get shuffle => 'Zufall';

  @override
  String get queue => 'Warteschlange';

  @override
  String get nowPlaying => 'Wiedergabe läuft';

  @override
  String get nothingPlaying => 'Keine Wiedergabe';

  @override
  String get mute => 'Stumm';

  @override
  String get scanning => 'Scanvorgang läuft…';

  @override
  String get emptyQueue => 'Die Warteschlange ist leer';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get sortDefault => 'Standard';

  @override
  String get sortTitle => 'Titel';

  @override
  String get sortArtist => 'Künstler';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortYear => 'Jahr';

  @override
  String get sortAdded => 'Zuletzt hinzugefügt';

  @override
  String get sortDuration => 'Dauer';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Alben',
      one: '1 Album',
    );
    return '$_temp0';
  }

  @override
  String missingTracksCount(int count) {
    return 'Fehlende Titel ($count)';
  }

  @override
  String get addedToFavorites => 'Zu Favoriten hinzugefügt';

  @override
  String get removedFromFavorites => 'Aus Favoriten entfernt';

  @override
  String get undo => 'Rückgängig';

  @override
  String get noFavorites => 'Noch keine Favoriten';

  @override
  String get newPlaylist => 'Neue Playlist';

  @override
  String get newPlaylistEllipsis => 'Neue Playlist…';

  @override
  String get playlistName => 'Name der Playlist';

  @override
  String get create => 'Erstellen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get noPlaylists => 'Keine Playlists. Erstelle eine.';

  @override
  String get addToPlaylist => 'Zu Playlist hinzufügen…';

  @override
  String addedToPlaylist(String name) {
    return 'Zu „$name“ hinzugefügt';
  }

  @override
  String get playNext => 'Als Nächstes spielen';

  @override
  String get addToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String get addedToQueue => 'Zur Warteschlange hinzugefügt';

  @override
  String get favorite => 'Favorit';

  @override
  String get removeFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get removeFromList => 'Entfernen';

  @override
  String get editInfo => 'Infos bearbeiten';

  @override
  String get details => 'Details';

  @override
  String get showInFolder => 'Im Ordner anzeigen';

  @override
  String get detailPath => 'Pfad';

  @override
  String get detailFormat => 'Format';

  @override
  String get detailSize => 'Größe';

  @override
  String get detailDuration => 'Dauer';

  @override
  String get detailAdded => 'Hinzugefügt am';

  @override
  String get detailPlays => 'Wiedergaben';

  @override
  String get close => 'Schließen';

  @override
  String get fieldTitle => 'Titel';

  @override
  String get fieldArtist => 'Künstler';

  @override
  String get fieldAlbum => 'Album';

  @override
  String get fieldAlbumArtist => 'Albumkünstler';

  @override
  String get fieldYear => 'Jahr';

  @override
  String get fieldTrackNumber => 'Titelnummer';

  @override
  String get fieldGenre => 'Genre';

  @override
  String get restoreFromFile => 'Aus Datei-Tags wiederherstellen';

  @override
  String get titleRequired => 'Der Titel darf nicht leer sein';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get themeNotte => 'Violette Nacht';

  @override
  String get themeOled => 'Reines Schwarz';

  @override
  String get settingsTextSize => 'Textgröße';

  @override
  String get textSmall => 'Klein';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Groß';

  @override
  String get settingsCompact => 'Kompaktmodus';

  @override
  String get settingsReducedMotion => 'Animationen reduzieren';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLibrary => 'Bibliothek';

  @override
  String get rescanNow => 'Jetzt neu scannen';

  @override
  String get clearCoverCache => 'Cover-Cache leeren';

  @override
  String get coverCacheCleared => 'Cover-Cache geleert';

  @override
  String get settingsOnline => 'Online';

  @override
  String get autoEnrich => 'Automatische Anreicherung';

  @override
  String get autoEnrichHint =>
      'Metadaten und Cover für neue Titel online suchen';

  @override
  String get autoLyrics => 'Automatische Songtexte';

  @override
  String get autoLyricsHint => 'Songtexte von LRCLIB für neue Titel laden';

  @override
  String get settingsAbout => 'Info';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get licenses => 'Lizenzen';

  @override
  String get personalUse => 'App für den persönlichen Gebrauch';

  @override
  String get missingTracksTitle => 'Fehlende Titel';

  @override
  String get removeFromLibrary => 'Aus Bibliothek entfernen';

  @override
  String get ignore => 'Ignorieren';

  @override
  String get confirmRemoveTitle => 'Aus Bibliothek entfernen?';

  @override
  String get confirmRemoveBody =>
      'Die Datei bleibt unverändert; Favoriten und Playlists dieses Titels gehen verloren.';

  @override
  String get noMissingTracks => 'Keine fehlenden Titel';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String scanFailed(String error) {
    return 'Scan fehlgeschlagen: $error';
  }

  @override
  String playbackError(String reason, String title) {
    return '„$title“ kann nicht abgespielt werden: $reason';
  }

  @override
  String get reasonFileMissing => 'Datei nicht gefunden';

  @override
  String get reasonUnplayable => 'Datei nicht abspielbar';

  @override
  String get reasonNotInLibrary => 'Titel nicht in der Bibliothek';

  @override
  String get searchWeb => 'Infos im Web suchen';

  @override
  String get enrichPreviewTitle => 'Vorschau der Informationen';

  @override
  String get currentValue => 'Aktuell';

  @override
  String get proposedValue => 'Vorschlag';

  @override
  String get apply => 'Anwenden';

  @override
  String get nothingFound => 'Nichts gefunden';

  @override
  String get userEditedLocked => 'Von dir bearbeitet: wird nicht überschrieben';

  @override
  String get fieldCover => 'Cover';

  @override
  String get fieldLyrics => 'Songtext';

  @override
  String get fieldCuriosity => 'Wissenswertes';

  @override
  String get enrichAlbum => 'Album anreichern';

  @override
  String get enrichLibrary => 'Gesamte Bibliothek anreichern';

  @override
  String get enrichConfirmTitle => 'Bibliothek anreichern?';

  @override
  String enrichConfirmBody(int count, int minutes) {
    return '$count Titel, etwa $minutes Minuten. Es werden nur leere Felder gefüllt.';
  }

  @override
  String enrichRunning(int done, int total) {
    return 'Anreicherung $done/$total';
  }

  @override
  String enrichResult(int notFound, int updated) {
    return '$updated aktualisiert, $notFound nicht gefunden';
  }

  @override
  String get enrichBusy => 'Eine Anreicherung läuft bereits';

  @override
  String get serviceUnavailable =>
      'Dienst nicht verfügbar, später erneut versuchen';

  @override
  String get lyrics => 'Songtext';

  @override
  String get searchLyrics => 'Songtext suchen';

  @override
  String get noLyrics => 'Kein Songtext verfügbar';

  @override
  String get lyricsNotFound => 'Songtext nicht gefunden';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'Kopiert';

  @override
  String get sourceWikipedia => 'Quelle: Wikipedia (CC BY-SA)';

  @override
  String get youtube => 'YouTube';

  @override
  String get ytHint => 'Suchen oder Link einfügen';

  @override
  String get ytDownload => 'Herunterladen';

  @override
  String get ytAlreadyInLibrary => 'Bereits in der Bibliothek';

  @override
  String get ytNoResults => 'Keine Ergebnisse';

  @override
  String get ytQueued => 'In Warteschlange';

  @override
  String get ytDownloading => 'Wird heruntergeladen';

  @override
  String get ytDone => 'Fertig';

  @override
  String get ytFailed => 'Fehlgeschlagen';

  @override
  String get ytCancelled => 'Abgebrochen';

  @override
  String get ytClearCompleted => 'Abgeschlossene entfernen';

  @override
  String get ytCancel => 'Download abbrechen';

  @override
  String get ytErrUnavailable => 'Video nicht verfügbar (Alter/Region/privat)';

  @override
  String get ytErrNetwork => 'Netzwerk nicht verfügbar';

  @override
  String get ytErrChanged =>
      'YouTube hat etwas geändert: App oder Paket aktualisieren';

  @override
  String get ytNoFolder => 'Füge zuerst einen Musikordner hinzu';

  @override
  String get ytLegal =>
      'Nur für den persönlichen Gebrauch. Urheberrecht und YouTube-Bedingungen beachten.';

  @override
  String get useDefaultFolder => 'Musikordner des Geräts verwenden';

  @override
  String get ytErrToolMissing =>
      'yt-dlp nicht gefunden: installieren (pip install -U yt-dlp) und erneut versuchen';

  @override
  String get ytErrRateLimited =>
      'YouTube verlangt eine Pause: versuche es in einigen Minuten erneut';

  @override
  String get playlistChangeCover => 'Cover ändern';

  @override
  String get playlistRemoveCover => 'Cover entfernen';

  @override
  String get coverTooLarge => 'Bild zu groß (max. 4 MB)';

  @override
  String get addSongs => 'Titel hinzufügen';

  @override
  String addNSongs(int count) {
    return 'Hinzufügen ($count)';
  }

  @override
  String get allSongsInPlaylist => 'Alle Titel sind bereits in der Playlist';

  @override
  String get shareTitle => 'Teilen';

  @override
  String get shareSend => 'Senden';

  @override
  String get shareReceive => 'Empfangen';

  @override
  String get shareAll => 'Ganze Bibliothek';

  @override
  String shareSelection(int count) {
    return 'Auswahl ($count Titel)';
  }

  @override
  String get sharePick => 'Titel wählen';

  @override
  String get shareStart => 'Freigabe starten';

  @override
  String get shareStop => 'Stopp';

  @override
  String get shareActive => 'Freigabe aktiv';

  @override
  String get shareAddress => 'Adresse (IP:Port)';

  @override
  String get sharePin => 'PIN';

  @override
  String get shareConnect => 'Verbinden';

  @override
  String shareDownloadSelected(int count) {
    return 'Auswahl herunterladen ($count)';
  }

  @override
  String shareProgress(int done, int total) {
    return 'Titel $done von $total';
  }

  @override
  String shareDone(int count) {
    return '$count Titel empfangen';
  }

  @override
  String shareConnectedTo(String name) {
    return 'Verbunden mit $name';
  }

  @override
  String get shareErrUnreachable =>
      'Gerät nicht erreichbar: Adresse und WLAN prüfen';

  @override
  String get shareErrPin => 'Falsche PIN';

  @override
  String get shareErrBlocked =>
      'Zu viele Versuche: in einer Minute erneut versuchen';

  @override
  String get shareErrNotCodecore => 'Kein Codecore-Gerät';

  @override
  String get shareErrFailed => 'Übertragung fehlgeschlagen';

  @override
  String get shareNoNetwork => 'Kein lokales Netzwerk gefunden';

  @override
  String get shareFirewall =>
      'Windows fragt beim ersten Mal ggf. nach der Firewall-Freigabe.';

  @override
  String get shareHint =>
      'Im selben WLAN auf dem anderen Gerät „Empfangen“ öffnen und Adresse und PIN eingeben.';

  @override
  String get shareMenu => 'Teilen…';

  @override
  String get shareDeviceName => 'Gerätename';

  @override
  String get importOld => 'Aus der alten App importieren';

  @override
  String get importOldHint => 'codecore_library.db der Python-Version wählen';

  @override
  String importSummary(
    int favorites,
    int lyrics,
    int playlists,
    int unmatched,
  ) {
    return '$favorites Favoriten, $playlists Playlists, $lyrics Songtexte importiert, $unmatched nicht zugeordnet';
  }

  @override
  String get importFailed => 'Import fehlgeschlagen: ungültige Datei';

  @override
  String get sleepTimer => 'Schlaftimer';

  @override
  String sleepMinutes(int count) {
    return '$count Minuten';
  }

  @override
  String get sleepEndOfTrack => 'Am Ende des Titels';

  @override
  String get sleepCancel => 'Timer abbrechen';

  @override
  String get pause => 'Pause';

  @override
  String get nextTrack => 'Nächster Titel';

  @override
  String get previousTrack => 'Vorheriger Titel';

  @override
  String get repeat => 'Wiederholen';

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get back => 'Zurück';

  @override
  String get settingsPlayback => 'Wiedergabe';

  @override
  String get normalizeVolume => 'Lautstärke normalisieren';

  @override
  String get normalizeVolumeHint =>
      'Nutzt ReplayGain der Dateien, um zu laute Titel zu senken';

  @override
  String get nearbyDevices => 'Geräte in der Nähe';

  @override
  String get searchingDevices => 'Suche nach Geräten im Netzwerk…';

  @override
  String get noDevicesHint =>
      'Kein Gerät gefunden. Öffne Teilen auch auf dem anderen Gerät im selben Netzwerk.';

  @override
  String sendToDevice(String name) {
    return 'An $name senden';
  }

  @override
  String offerSent(String name) {
    return 'Anfrage an $name gesendet';
  }

  @override
  String get offerChooseFirst => 'Wähle zuerst die zu sendenden Titel';

  @override
  String get sentRequests => 'Gesendete Anfragen';

  @override
  String get receivedRequests => 'Empfangene Anfragen';

  @override
  String get offerPending => 'Warte auf Antwort';

  @override
  String get offerAccepted => 'Akzeptiert';

  @override
  String get offerDeclined => 'Abgelehnt';

  @override
  String get offerCancelled => 'Abgebrochen';

  @override
  String get offerExpired => 'Abgelaufen';

  @override
  String get offerDone => 'Abgeschlossen';

  @override
  String get offerFailed => 'Fehlgeschlagen';

  @override
  String incomingTitle(String name) {
    return '$name möchte dir Titel senden';
  }

  @override
  String incomingBody(int count, String size) {
    return '$count Titel, $size MB';
  }

  @override
  String get accept => 'Annehmen';

  @override
  String get decline => 'Ablehnen';

  @override
  String receivingProgress(int done, int total) {
    return 'Empfang $done/$total';
  }

  @override
  String get manualConnection => 'Manuelle Verbindung (IP und PIN)';

  @override
  String get receiveFromLan => 'Aus dem lokalen Netzwerk empfangen';

  @override
  String get receiveFromLanHint =>
      'Macht das Gerät sichtbar und empfängt Anfragen auch im Hintergrund. Unter Android erscheint eine feste Benachrichtigung zum Ausschalten';

  @override
  String get receiveServiceTitle => 'Codecore ist im Netzwerk sichtbar';

  @override
  String get receiveServiceText =>
      'Bereit, Titel von Geräten in der Nähe zu empfangen';

  @override
  String get receiveServiceDisable => 'Ausschalten';

  @override
  String get jamTitle => 'Jam';

  @override
  String get jamStart => 'Jam starten';

  @override
  String jamStartWith(String name) {
    return 'Jam mit $name starten';
  }

  @override
  String jamWaiting(String name) {
    return 'Warte, bis $name annimmt…';
  }

  @override
  String jamDeclined(String name) {
    return '$name hat die Jam abgelehnt';
  }

  @override
  String jamBusy(String name) {
    return '$name hat bereits eine Jam';
  }

  @override
  String get jamUnreachable => 'Gerät nicht erreichbar';

  @override
  String jamIncomingTitle(String name) {
    return '$name möchte eine Jam starten';
  }

  @override
  String get jamIncomingBody =>
      'Gemeinsam aus einer geteilten Warteschlange hören.';

  @override
  String jamIncomingDialog(String name) {
    return '$name möchte eine Jam mit dir starten. Die Musik läuft auf diesem Gerät und ihr könnt beide Titel hinzufügen.';
  }

  @override
  String get jamQueue => 'Gemeinsame Warteschlange';

  @override
  String get jamEmpty => 'Die Warteschlange ist leer. Füge Titel hinzu.';

  @override
  String jamAddedBy(String name) {
    return 'hinzugefügt von $name';
  }

  @override
  String get jamYou => 'dir';

  @override
  String get jamAddTracks => 'Titel hinzufügen';

  @override
  String get jamAddToJam => 'Zur Jam hinzufügen';

  @override
  String jamAdded(int count) {
    return 'Zur Jam hinzugefügt: $count';
  }

  @override
  String get jamOutput => 'Audioausgabe';

  @override
  String get jamOutputHere => 'Dieses Gerät';

  @override
  String jamOutputOther(String name) {
    return '$name';
  }

  @override
  String get jamEnd => 'Jam beenden';

  @override
  String get jamLeave => 'Jam verlassen';

  @override
  String get jamEnded => 'Die Jam ist beendet';

  @override
  String get jamLost => 'Verbindung verloren';

  @override
  String get jamGuestCannotSkip => 'Nur der Host kann den Titel wechseln';

  @override
  String get jamRemoveForbidden => 'Du kannst nur eigene Titel entfernen';

  @override
  String get jamNowPlaying => 'Läuft gerade';

  @override
  String get jamNothingPlaying => 'Nichts läuft';

  @override
  String jamWith(String name) {
    return 'Jam mit $name';
  }

  @override
  String get jamUnavailable => 'Nicht verfügbar';

  @override
  String get jamPlaying => 'Jam ist aktiv';

  @override
  String get jamOpen => 'Jam öffnen';

  @override
  String jamSynced(int ms) {
    return 'Synchron · Abweichung $ms ms';
  }

  @override
  String get jamSyncing => 'Synchronisierung…';

  @override
  String jamLatency(int ms) {
    return 'Latenz dieser Ausgabe: $ms ms';
  }

  @override
  String get jamLatencyHint =>
      'Für Bluetooth-Kopfhörer oder -Lautsprecher: erhöhen, bis die Ausgaben zusammenpassen.';

  @override
  String get jamOutputsHint => 'Mehrere Ausgaben spielen gleichzeitig';

  @override
  String get renamePlaylist => 'Playlist umbenennen';

  @override
  String get confirmDeletePlaylistTitle => 'Playlist löschen?';

  @override
  String confirmDeletePlaylistBody(String name) {
    return '„$name“ wird gelöscht. Die Titel bleiben in der Bibliothek.';
  }

  @override
  String get confirmRemoveFolderTitle => 'Ordner entfernen?';

  @override
  String get confirmRemoveFolderBody =>
      'Die Titel verschwinden aus der Bibliothek. Die Dateien bleiben auf dem Gerät.';

  @override
  String get confirmClearCoversTitle => 'Cover-Cache leeren?';

  @override
  String get confirmClearCoversBody =>
      'Die Cover werden beim nächsten Scan neu erstellt.';

  @override
  String get confirmRestoreTitle => 'Aus den Datei-Tags wiederherstellen?';

  @override
  String get confirmRestoreBody =>
      'Deine Änderungen an diesem Titel werden durch die Daten der Datei ersetzt.';

  @override
  String get removedFromPlaylist => 'Aus der Playlist entfernt';

  @override
  String get removedFromQueue => 'Aus der Warteschlange entfernt';

  @override
  String get playNextDone => 'Wird als Nächstes gespielt';

  @override
  String get ytSearchPrompt => 'Titel suchen oder Link einfügen';

  @override
  String get loadFailed => 'Die Daten konnten nicht geladen werden.';

  @override
  String get navHome => 'Start';

  @override
  String get navSearch => 'Suche';

  @override
  String get devicesTitle => 'Geräte';

  @override
  String get devicesJamActive => 'Aktive Jam';

  @override
  String jamPeople(int n) {
    return 'Jam · $n Personen';
  }

  @override
  String get devicesVisibleTitle => 'Dieses Gerät sichtbar machen';

  @override
  String get devicesVisibleHint =>
      'Um Titel zu empfangen oder eine Jam zu starten, müssen andere Geräte dich im Netzwerk sehen.';

  @override
  String get devicesJamShort => 'Jam';

  @override
  String get devicesSendShort => 'Senden';

  @override
  String get devicesMore => 'Teilen und manuelle Verbindung';

  @override
  String jamParticipantsCount(int n) {
    return '$n Personen';
  }

  @override
  String get playingFrom => 'Wiedergabe von';

  @override
  String get playContextSearch => 'Suche';

  @override
  String get allTracks => 'Alle Titel';

  @override
  String get trackInfo => 'Infos zum Titel';

  @override
  String get searchCuriosity => 'Wissenswertes suchen';

  @override
  String get upNext => 'Als Nächstes';

  @override
  String get openQueue => 'Warteschlange öffnen';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get sleepChipEnd => 'Titelende';

  @override
  String get yourLibrary => 'Deine Bibliothek';

  @override
  String playlistCountLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Playlist · $n Titel',
      one: 'Playlist · 1 Titel',
    );
    return '$_temp0';
  }

  @override
  String get sortRecent => 'Zuletzt gehört';

  @override
  String get sortAlphabetical => 'Alphabetisch';

  @override
  String get sortAddedRecently => 'Zuletzt hinzugefügt';

  @override
  String get viewAsGrid => 'Als Raster anzeigen';

  @override
  String get viewAsList => 'Als Liste anzeigen';

  @override
  String get kindAlbum => 'Album';

  @override
  String get kindArtist => 'Künstler';

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
    return '$n Min.';
  }

  @override
  String tracksAndDuration(String tracks, String duration) {
    return '$tracks, $duration';
  }

  @override
  String get mostPlayed => 'Meistgespielt';

  @override
  String get albumsSection => 'Alben';

  @override
  String artistMeta(String albums, String tracks) {
    return '$albums · $tracks';
  }

  @override
  String get addAllToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String addedNToQueue(int n) {
    return '$n Titel zur Warteschlange hinzugefügt';
  }

  @override
  String get editOrder => 'Reihenfolge ändern';

  @override
  String get finishEditing => 'Fertig';

  @override
  String get removeFromPlaylistAction => 'Aus Playlist entfernen';

  @override
  String get noTracksInPlaylist => 'Diese Playlist ist leer';

  @override
  String get greetingMorning => 'Guten Morgen';

  @override
  String get greetingAfternoon => 'Guten Tag';

  @override
  String get greetingEvening => 'Guten Abend';

  @override
  String get homeResume => 'Weiterhören';

  @override
  String get homeRecentlyPlayed => 'Zuletzt gehört';

  @override
  String get homeRecentlyAdded => 'Zuletzt hinzugefügt';

  @override
  String get homeTopTracks => 'Meistgespielt';

  @override
  String get homeRediscover => 'Wiederentdecken';

  @override
  String get searchMainResult => 'Bestes Ergebnis';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String searchOnYoutube(String query) {
    return '„$query“ auf YouTube suchen';
  }

  @override
  String get recentSearches => 'Letzte Suchen';

  @override
  String get genresTitle => 'Genres';

  @override
  String downloadsChip(int n) {
    return 'Downloads ($n)';
  }

  @override
  String get gotIt => 'Verstanden';

  @override
  String get searchEmptyLibrary => 'Keine Ergebnisse in der Bibliothek';

  @override
  String get ytInfoTooltip => 'Hinweis zur Nutzung';

  @override
  String get removeRecentSearch => 'Aus letzten Suchen entfernen';

  @override
  String get groupGoTo => 'Gehe zu';

  @override
  String get goToAlbum => 'Zum Album';

  @override
  String get goToArtist => 'Zum Künstler';

  @override
  String get groupQueue => 'Warteschlange';

  @override
  String get groupCollection => 'Sammlung';

  @override
  String get groupEdit => 'Bearbeiten';

  @override
  String get groupOther => 'Mehr';

  @override
  String get queueNowPlaying => 'Wiedergabe';

  @override
  String get queueNext => 'Als Nächstes';

  @override
  String get queueClear => 'Leeren';

  @override
  String get queueCleared => 'Warteschlange geleert';

  @override
  String get jamOutputsAndSync => 'Ausgänge und Sync';

  @override
  String get jamHostTag => 'Host';

  @override
  String get jamWaitingEmpty => 'Keine Jam aktiv';

  @override
  String get activityTitle => 'Aktivität';

  @override
  String activityScan(int done, int total) {
    return 'Scan · $done/$total';
  }

  @override
  String get activityScanIdle => 'Scan läuft';

  @override
  String activityEnrich(int done, int total) {
    return 'Anreichern · $done/$total';
  }

  @override
  String activityDownload(String title) {
    return 'Download · $title';
  }

  @override
  String activityTransfer(String name, int n) {
    return 'Senden an $name · $n Titel';
  }

  @override
  String get activityNone => 'Keine Aktivität';

  @override
  String get activityCompleted => 'Abgeschlossen';

  @override
  String get activityClear => 'Leeren';

  @override
  String activityRunning(int n) {
    return '$n Aktivitäten laufen';
  }

  @override
  String get settingsLocalNetwork => 'Lokales Netzwerk';

  @override
  String get removeAll => 'Alle entfernen';

  @override
  String get confirmRemoveAllTitle => 'Alle aus der Bibliothek entfernen?';

  @override
  String confirmRemoveAllBody(int n) {
    return '$n fehlende Titel werden aus der Bibliothek entfernt. Die Dateien bleiben unberührt; Favoriten und Playlist-Einträge gehen verloren.';
  }

  @override
  String get csvImportMenu => 'Aus Exportify importieren (CSV)';

  @override
  String get csvImportIntroTitle => 'Playlist importieren';

  @override
  String get csvImportIntroSource =>
      'Die CSV-Datei erstellst du kostenlos auf der Website Exportify — exportify.net (keine App nötig).';

  @override
  String get csvImportStep1 =>
      'Öffne https://exportify.net im Browser (auch am Handy).';

  @override
  String get csvImportStep2 =>
      'Tippe auf „Get Started“ und melde dich mit deinem Spotify-Konto an.';

  @override
  String get csvImportStep3 =>
      'Tippe neben der gewünschten Playlist auf „Export“: eine .csv-Datei mit dem Namen der Playlist wird heruntergeladen.';

  @override
  String get csvImportStep4 =>
      'Komm hierher zurück und tippe auf „CSV-Datei wählen“.';

  @override
  String get csvImportNote =>
      'Codecore sucht die Titel in deiner Bibliothek und lädt die übrigen von YouTube Music.';

  @override
  String get csvImportNoteOffline =>
      'Es werden nur Titel verknüpft, die bereits in deiner Bibliothek sind.';

  @override
  String get csvImportCopy => 'Adresse kopieren';

  @override
  String get csvImportCopied => 'Adresse kopiert';

  @override
  String get csvImportPick => 'Datei wählen';

  @override
  String get csvImportNotExportify =>
      'Format nicht erkannt. Wähle ein CSV (Exportify, TuneMyMusic, Soundiiz, Last.fm) oder eine M3U/M3U8/XSPF-Playlist.';

  @override
  String get csvImportReadFailed => 'Die Datei konnte nicht gelesen werden.';

  @override
  String get csvImportPreviewTitle => 'Playlist importieren';

  @override
  String get csvImportName => 'Name der Playlist';

  @override
  String csvImportSummary(int total, int known, int todo) {
    return '$total Titel · $known schon in der Bibliothek · $todo herunterzuladen';
  }

  @override
  String csvImportSkipped(int n) {
    return '$n Zeilen ignoriert (Podcasts oder lokale Dateien)';
  }

  @override
  String csvImportEstimate(int minutes) {
    return 'Geschätzte Dauer: etwa $minutes Min.';
  }

  @override
  String get csvImportExists =>
      'Eine Playlist mit diesem Namen existiert bereits';

  @override
  String get csvImportUpdate => 'Bestehende aktualisieren (nur neue Titel)';

  @override
  String get csvImportNew => 'Neue Playlist anlegen';

  @override
  String get csvImportGo => 'Importieren';

  @override
  String get csvImportStarted =>
      'Import gestartet: im Aktivitätscenter verfolgen';

  @override
  String activityImport(String name, int done, int total) {
    return 'Import „$name“ · $done/$total';
  }

  @override
  String activityImportPaused(String name, int done, int total) {
    return 'Import „$name“ · pausiert · $done/$total';
  }

  @override
  String csvImportBanner(int done, int total, int review, int missing) {
    return 'Import: $done/$total · $review zu prüfen · $missing nicht gefunden';
  }

  @override
  String csvImportBannerPaused(int done, int total, int review, int missing) {
    return 'Import pausiert: $done/$total · $review zu prüfen · $missing nicht gefunden';
  }

  @override
  String get csvImportReview => 'Prüfen';

  @override
  String get csvImportResume => 'Fortsetzen';

  @override
  String get csvImportPause => 'Pausieren';

  @override
  String get csvImportCancelTitle => 'Import abbrechen?';

  @override
  String get csvImportCancelBody =>
      'Bereits geladene Titel bleiben in der Playlist.';

  @override
  String csvImportDone(int added, int review, int missing) {
    return 'Import abgeschlossen: $added hinzugefügt, $review zu prüfen, $missing nicht gefunden';
  }

  @override
  String get csvImportFailing =>
      'Zu viele Fehler hintereinander: Import pausiert';

  @override
  String get csvImportReviewTitle => 'Prüfen';

  @override
  String get csvImportToReview => 'Zu prüfen';

  @override
  String get csvImportNotFound => 'Nicht gefunden';

  @override
  String get csvImportErrors => 'Mit Fehlern';

  @override
  String get csvImportRetryAll => 'Alle wiederholen';

  @override
  String get csvImportSkip => 'Überspringen';

  @override
  String get csvImportManual => 'Manuell suchen';

  @override
  String get csvImportNothing => 'Nichts zu prüfen.';

  @override
  String get csvImportSearch => 'Suchen';

  @override
  String csvImportWanted(String title, String artist, String duration) {
    return 'Gesucht: $title · $artist · $duration';
  }

  @override
  String get csvImportDownload => 'Herunterladen';

  @override
  String get csvImportCancelGo => 'Import abbrechen';

  @override
  String get exportLog => 'Protokoll exportieren';

  @override
  String get exportLogHint =>
      'Textdatei ohne persönliche Pfade, Netzwerkadressen oder PINs';

  @override
  String get exportLogDebugOnly =>
      'Nur in der installierten Version (im Debug-Modus wird das Protokoll nicht in eine Datei geschrieben)';

  @override
  String get exportLogNone => 'Es gibt noch kein Protokoll zum Exportieren';

  @override
  String get exportLogSaved => 'Protokoll gespeichert';

  @override
  String get exportLogFailed => 'Protokoll konnte nicht gespeichert werden';

  @override
  String get exportPlaylist => 'Exportieren…';

  @override
  String get exportPlaylistTitle => 'Playlist exportieren';

  @override
  String get exportFormatM3u8 => 'M3U8 · für andere Player';

  @override
  String get exportFormatCsv => 'CSV · wie Exportify';

  @override
  String get exportFormatJson => 'JSON · Codecore-Format';

  @override
  String get exportRelativePaths => 'Relative Pfade';

  @override
  String get exportRelativeHint =>
      'Relativ zum gemeinsamen Ordner aller Titel: Datei dort speichern';

  @override
  String get exportAction => 'Exportieren';

  @override
  String get exportSaved => 'Playlist exportiert';

  @override
  String get exportEmpty => 'Die Playlist ist leer';

  @override
  String get exportFailed => 'Playlist konnte nicht exportiert werden';

  @override
  String get ytErrToolOutdated =>
      'yt-dlp ist zu alt: aktualisiere es (Einstellungen → Downloads → Aktualisieren) und versuche es erneut';

  @override
  String ytDlpOutdatedBanner(String version) {
    return 'yt-dlp $version ist zu alt: Downloads funktionieren möglicherweise nicht';
  }

  @override
  String get settingsDownloads => 'Downloads';

  @override
  String ytDlpVersion(String version) {
    return 'yt-dlp $version';
  }

  @override
  String get ytDlpUnknownVersion => 'yt-dlp nicht gefunden';

  @override
  String get ytDlpUpdate => 'Aktualisieren';

  @override
  String ytDlpUpdating(int percent) {
    return 'Aktualisierung… $percent%';
  }

  @override
  String ytDlpUpdated(String version) {
    return 'Auf Version $version aktualisiert';
  }

  @override
  String get ytDlpTooOld => 'Zu alt: Aktualisieren tippen';

  @override
  String get ytDlpUpdateErrNetwork =>
      'Aktualisierung fehlgeschlagen: Netzwerk nicht erreichbar';

  @override
  String get ytDlpUpdateErrHash =>
      'Aktualisierung abgebrochen: Die heruntergeladene Datei hat die Integritätsprüfung nicht bestanden';

  @override
  String get ytDlpUpdateErrOther =>
      'Aktualisierung fehlgeschlagen (siehe Protokoll)';

  @override
  String get downloadParallel => 'Gleichzeitige Downloads';

  @override
  String get downloadParallelHint =>
      'Mehr gleichzeitig ist schneller, aber YouTube kann bremsen';

  @override
  String get downloadRateLimit => 'Geschwindigkeitslimit';

  @override
  String get downloadRateNone => 'Keins';

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
    return 'Download · $title · neuer Versuch in $seconds s ($attempt/$max)';
  }

  @override
  String get downloadOriginal => 'Originalqualität (ohne Neukodierung)';

  @override
  String get downloadOriginalHint =>
      'Behält das Audio von YouTube unverändert (M4A/Opus): kein zusätzlicher Verlust, kleinere Dateien. Aus: MP3 256 kbps';

  @override
  String get searchCacheClear => 'Suchcache leeren';

  @override
  String searchCacheCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gespeicherte Suchen',
      one: '1 gespeicherte Suche',
      zero: 'Leer',
    );
    return '$_temp0';
  }

  @override
  String get searchCacheCleared => 'Cache geleert';

  @override
  String csvImportLengthOff(String found, String wanted) {
    return 'Andere Länge: $found statt $wanted';
  }

  @override
  String get csvImportKeep => 'Diesen behalten';

  @override
  String get csvImportTooBig =>
      'Die Datei ist zu groß für eine Playlist (höchstens 5 MB und 10.000 Titel)';

  @override
  String get csvImportAlsoAccepts =>
      'Auch akzeptiert: TuneMyMusic, Soundiiz, Last.fm (CSV), M3U/M3U8, XSPF.';

  @override
  String get csvImportPlanned => 'Treffer bereit: prüfen und herunterladen';

  @override
  String get csvImportLinkOnly => 'Nur verknüpfen (keine Downloads)';

  @override
  String get csvImportLinkOnlyHint =>
      'Erstellt die Playlist nur aus dem, was du schon hast';

  @override
  String get csvImportPlanFirst => 'Vor dem Download prüfen';

  @override
  String get csvImportPlanFirstHint =>
      'Sucht alles, dann wählst du, was geladen wird';

  @override
  String get csvImportPlanTitle => 'Treffer';

  @override
  String csvImportPlanGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Titel laden',
      one: '1 Titel laden',
    );
    return '$_temp0';
  }

  @override
  String get csvImportPlanKnown => 'bereits geladen';

  @override
  String get csvImportPlanEmpty => 'Nichts herunterzuladen';

  @override
  String csvImportBannerPlanned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Titel zum Laden',
      one: '1 Titel zum Laden',
    );
    return 'Treffer bereit: $_temp0';
  }

  @override
  String get settingsAdvanced => 'Erweitert';

  @override
  String get importSureThreshold => 'Sicherer Treffer ab';

  @override
  String get importSureThresholdHint =>
      'Über dieser Punktzahl wird ein importierter Titel ohne Rückfrage geladen';

  @override
  String get importReviewThreshold => 'Zur Prüfung ab';

  @override
  String get importReviewThresholdHint =>
      'Zwischen dieser und der sicheren Punktzahl landet der Titel in «Zu prüfen», darunter in «Nicht gefunden»';

  @override
  String get importThresholdsReset => 'Standardwerte wiederherstellen';

  @override
  String csvImportEstimateHours(int hours, int minutes) {
    return 'Geschätzte Zeit: etwa $hours Std. $minutes Min.';
  }

  @override
  String csvImportBlocks(int size) {
    return 'In Blöcken zu $size importieren';
  }

  @override
  String csvImportBigWarning(int n) {
    return '$n Titel zum Laden: das dauert Stunden. In Blöcken, einer nach dem anderen, bleibt die Reihenfolge richtig und du kannst zwischen den Blöcken anhalten.';
  }

  @override
  String get etaLessThanMinute => 'unter 1 Min.';

  @override
  String etaMinutes(int minutes) {
    return 'etwa $minutes Min.';
  }

  @override
  String etaHours(int hours, int minutes) {
    return 'etwa $hours Std. $minutes Min.';
  }

  @override
  String get csvImportOwnFolder => 'Ordner für diese Playlist';

  @override
  String get csvImportOwnFolderHint =>
      'Speichert die Downloads in einem Unterordner mit dem Namen der Playlist';

  @override
  String get csvImportNumberFiles => 'Dateien nummerieren';

  @override
  String get csvImportNumberFilesHint =>
      '07 - Interpret - Titel: der Ordner spielt auch außerhalb von Codecore in der richtigen Reihenfolge';

  @override
  String get csvImportFetchCovers => 'Cover suchen';

  @override
  String get csvImportFetchCoversHint =>
      'Sucht nach jedem Download das Albumcover bei iTunes (Album und Interpret aus der Datei)';

  @override
  String get csvImportExport => 'Ergebnis exportieren';

  @override
  String get csvImportExported => 'Ergebnis gespeichert';

  @override
  String get csvOutHeaderRow => 'Zeile';

  @override
  String get csvOutHeaderTitle => 'Titel';

  @override
  String get csvOutHeaderArtists => 'Interpreten';

  @override
  String get csvOutHeaderAlbum => 'Album';

  @override
  String get csvOutHeaderDuration => 'Dauer (ms)';

  @override
  String get csvOutHeaderIsrc => 'ISRC';

  @override
  String get csvOutHeaderStatus => 'Ergebnis';

  @override
  String get csvOutHeaderNote => 'Grund';

  @override
  String get csvOutHeaderVideo => 'Gewähltes Video';

  @override
  String get csvOutHeaderScore => 'Punktzahl';

  @override
  String get importStatusPending => 'Zu suchen';

  @override
  String get importStatusQueued => 'In Warteschlange';

  @override
  String get importStatusDownloaded => 'Geladen';

  @override
  String get importStatusLinked => 'Schon in der Bibliothek';

  @override
  String get importStatusReview => 'Zu prüfen';

  @override
  String get importStatusNotFound => 'Nicht gefunden';

  @override
  String get importStatusFailed => 'Fehler';

  @override
  String get importStatusSkipped => 'Übersprungen';

  @override
  String get importStatusPlanned => 'Geplant';

  @override
  String get importStatusRemoved => 'Aus der Quelle entfernt';

  @override
  String get importNoteNoResults => 'Keine Ergebnisse';

  @override
  String get importNoteLowScore => 'Treffer nicht sicher genug';

  @override
  String get importNoteLinkOnly => 'Nur verknüpfen: nicht gesucht';

  @override
  String get importNoteYoutubeOff => 'Downloads sind aus';

  @override
  String get importNoteDownloadFailed => 'Download fehlgeschlagen';

  @override
  String get importNoteLengthOff => 'Länge weicht von der Datei ab';

  @override
  String get importNoteUnchanged => 'Schon in der Playlist';

  @override
  String get csvImportSync => 'Synchronisieren';

  @override
  String csvImportSyncCounts(int added, int removed) {
    return '+$added neu · −$removed aus der Playlist entfernt (Dateien bleiben)';
  }

  @override
  String get csvImportSyncChecking => 'Unterschiede werden geprüft…';

  @override
  String get playbackSpeed => 'Wiedergabegeschwindigkeit';

  @override
  String get playbackSpeedHint =>
      'Die Tonhöhe bleibt original. Der Einschlaf-Timer zählt echte Zeit, nicht die des Titels.';

  @override
  String resumeFrom(String time) {
    return 'weiter bei $time';
  }

  @override
  String get restartFromBeginning => 'Von vorn beginnen';

  @override
  String get previewTrack => '20-s-Vorschau';

  @override
  String get equalizer => 'Equalizer';

  @override
  String get eqOutputSpeaker => 'Lautsprecher';

  @override
  String get eqOutputHeadphones => 'Kopfhörer';

  @override
  String get eqHint =>
      'Jeder Ausgang merkt sich seine Kurve: sie wechselt von selbst, wenn du Kopfhörer anschließt.';

  @override
  String get eqPresetFlat => 'Flach';

  @override
  String get eqPresetBass => 'Bass';

  @override
  String get eqPresetVoice => 'Stimme';

  @override
  String get eqPresetTreble => 'Höhen';

  @override
  String get eqPresetCustom => 'Eigene';

  @override
  String get eqReset => 'Zurücksetzen';

  @override
  String get eqWaiting =>
      'Die Bänder erscheinen, sobald der erste Titel läuft.';

  @override
  String get eqUnavailable =>
      'Der Equalizer ist auf diesem Gerät nicht verfügbar.';

  @override
  String get transitionMode => 'Übergang zwischen Titeln';

  @override
  String get transitionNormal => 'Normal';

  @override
  String get transitionGapless => 'Lückenlos';

  @override
  String get transitionCrossfade => 'Überblenden';

  @override
  String get transitionHint =>
      'Lückenlos funktioniert am besten mit Titeln im selben Format (zum Beispiel alle FLAC).';

  @override
  String crossfadeLength(int seconds) {
    return 'Dauer der Überblendung: $seconds s';
  }

  @override
  String get crossfadePlainInAlbum =>
      'Innerhalb eines Albums nicht überblenden';

  @override
  String get crossfadePlainInAlbumHint =>
      'Innerhalb eines Albums folgen die Titel lückenlos aufeinander, ohne sich zu überlagern.';

  @override
  String get selectedRow => 'Ausgewählt';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
      one: '1 ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get exitSelection => 'Auswahl beenden';

  @override
  String get bulkActions => 'Aktionen';

  @override
  String playNextMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel werden als Nächstes gespielt',
      one: '1 Titel wird als Nächstes gespielt',
    );
    return '$_temp0';
  }

  @override
  String addedToQueueMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel zur Warteschlange hinzugefügt',
      one: '1 Titel zur Warteschlange hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistMany(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel zu „$name“ hinzugefügt',
      one: '1 Titel zu „$name“ hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistSkipped(int added, int skipped, String name) {
    return '$added zu „$name“ hinzugefügt, $skipped schon vorhanden';
  }

  @override
  String allAlreadyInPlaylist(String name) {
    return 'Alle waren schon in „$name“';
  }

  @override
  String favoritesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel zu den Favoriten hinzugefügt',
      one: '1 Titel zu den Favoriten hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String favoritesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel aus den Favoriten entfernt',
      one: '1 Titel aus den Favoriten entfernt',
    );
    return '$_temp0';
  }

  @override
  String get bulkAddToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get bulkRemoveFromFavorites => 'Aus Favoriten entfernen';

  @override
  String removeManyFromPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel aus der Playlist entfernen?',
      one: '1 Titel aus der Playlist entfernen?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromPlaylistBody =>
      'Die Dateien und die Bibliothek bleiben unberührt.';

  @override
  String removedManyFromPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel entfernt',
      one: '1 Titel entfernt',
    );
    return '$_temp0';
  }

  @override
  String removeManyFromLibraryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel aus der Bibliothek entfernen?',
      one: '1 Titel aus der Bibliothek entfernen?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromLibraryBody =>
      'Die Dateien existieren nicht mehr: Sie verschwinden nur aus der Bibliothek (Favoriten und Playlist-Einträge dieser Titel gehen verloren).';

  @override
  String removedManyFromLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel aus der Bibliothek entfernt',
      one: '1 Titel aus der Bibliothek entfernt',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Downloads gestartet',
      one: '1 Download gestartet',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsSkipped(int started, int skipped) {
    return '$started Downloads gestartet, $skipped bereits in der Bibliothek oder in Arbeit';
  }

  @override
  String get ytNothingToDownload =>
      'Alle sind schon in der Bibliothek oder in Arbeit';

  @override
  String get themeChiaro => 'Hell';

  @override
  String get settingsAccent => 'Akzentfarbe';

  @override
  String get accentViola => 'Violett';

  @override
  String get accentBlu => 'Blau';

  @override
  String get accentAcqua => 'Türkis';

  @override
  String get accentVerde => 'Grün';

  @override
  String get accentAmbra => 'Bernstein';

  @override
  String get accentArancio => 'Orange';

  @override
  String get accentRosa => 'Rosa';

  @override
  String get accentRosso => 'Rot';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Los geht’s';

  @override
  String onboardingPageOf(int page, int total) {
    return 'Seite $page von $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei Codecore';

  @override
  String get onboardingWelcomeBody =>
      'Dein persönlicher Musikplayer: kein Konto, kein Server. Deine Musik bleibt auf deinem Gerät.';

  @override
  String get onboardingFoldersTitle => 'Deine Musik';

  @override
  String get onboardingFoldersBody =>
      'Wähle die Ordner mit deinen Titeln. Codecore liest sie nur: Es ändert oder verschiebt sie nie.';

  @override
  String onboardingFoldersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ordner hinzugefügt',
      one: '1 Ordner hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get onboardingAllowAccess => 'Zugriff auf Audiodateien erlauben';

  @override
  String get onboardingAccessGranted => 'Zugriff erlaubt';

  @override
  String get onboardingOnlineTitle => 'Online-Funktionen';

  @override
  String get onboardingOnlineBody =>
      'Sie sind aus: Codecore geht nie von allein online. Du kannst sie jetzt oder später in den Einstellungen einschalten.';

  @override
  String get onboardingShareTitle => 'Downloads, Jam und Teilen';

  @override
  String get onboardingYoutubeBody =>
      'Du kannst Titel von YouTube auf dein Gerät laden und wie den Rest deiner Musik hören.';

  @override
  String get onboardingJamBody =>
      'Mit einer Jam hörst du dieselbe Musik gemeinsam mit einem anderen Gerät im selben Netzwerk.';

  @override
  String get onboardingSendBody =>
      'Du kannst Titel mit einer PIN an andere Geräte in der Nähe senden, ohne Umweg über das Internet.';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get historySubtitle => 'Was du gehört hast';

  @override
  String get historyToday => 'Heute';

  @override
  String get historyYesterday => 'Gestern';

  @override
  String get historyEmpty => 'Hier erscheint, was du hörst.';

  @override
  String get historyOff =>
      'Der Verlauf ist aus: Schalte ihn unter Einstellungen → Wiedergabe ein.';

  @override
  String get historyClear => 'Verlauf löschen';

  @override
  String get historyClearTitle => 'Verlauf löschen?';

  @override
  String get historyClearBody =>
      'Gelöscht wird nur die Liste der Wiedergaben: Zähler, Favoriten und Playlists bleiben unverändert.';

  @override
  String get historyCleared => 'Verlauf gelöscht';

  @override
  String get settingsRecordHistory => 'Hörverlauf speichern';

  @override
  String get settingsRecordHistoryHint =>
      'Bleibt auf dem Gerät. Wenn aus, wird nichts mehr hinzugefügt.';

  @override
  String get statsTitle => 'Statistiken';

  @override
  String get statsSubtitle => 'Wie viel und was du hörst';

  @override
  String get statsMonth => 'Monat';

  @override
  String get statsYear => 'Jahr';

  @override
  String get statsPrevious => 'Voriger Zeitraum';

  @override
  String get statsNext => 'Nächster Zeitraum';

  @override
  String get statsEmpty => 'Keine Wiedergaben in diesem Zeitraum.';

  @override
  String statsPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wiedergaben',
      one: '1 Wiedergabe',
    );
    return '$_temp0';
  }

  @override
  String statsDistinct(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verschiedene Titel',
      one: '1 anderer Titel',
    );
    return '$_temp0';
  }

  @override
  String statsHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String get statsTopTracks => 'Meistgespielte Titel';

  @override
  String get statsTopArtists => 'Meistgespielte Künstler';

  @override
  String get statsTopAlbums => 'Meistgespielte Alben';

  @override
  String get statsFavouriteHour => 'Lieblingsstunde';

  @override
  String get statsFirstListen => 'Erste Wiedergabe';

  @override
  String statsFirstValue(String title, String date) {
    return '$title · $date';
  }

  @override
  String get statsYourMonth => 'Dein Monat';

  @override
  String statsTopArtistHome(String name) {
    return 'Am meisten gehört: $name';
  }
}
