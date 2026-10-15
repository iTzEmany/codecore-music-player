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
  String get addToQueue => 'Zur Warteschlange';

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
  String get themeOled => 'OLED';

  @override
  String get themeCarbon => 'Karbon';

  @override
  String get themeNavy => 'Marineblau';

  @override
  String get themeLight => 'Hell';

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
}
