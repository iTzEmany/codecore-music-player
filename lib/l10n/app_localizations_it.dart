// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Codecore';

  @override
  String get chooseFolder => 'Scegli cartella';

  @override
  String get scan => 'Scansiona';

  @override
  String get noTracks => 'Nessun brano. Scegli una cartella e scansiona.';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get permissionDenied => 'Permesso di lettura audio negato';

  @override
  String get permissionExplain =>
      'Codecore ha bisogno del permesso di leggere i file audio per mostrare la tua musica.';

  @override
  String get navLibrary => 'Libreria';

  @override
  String get navFavorites => 'Preferiti';

  @override
  String get navPlaylists => 'Playlist';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get tracks => 'Brani';

  @override
  String get albums => 'Album';

  @override
  String get artists => 'Artisti';

  @override
  String get searchHint => 'Cerca';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get addMusicFolder => 'Aggiungi la tua cartella musicale';

  @override
  String get addFolder => 'Aggiungi cartella';

  @override
  String get folders => 'Cartelle musicali';

  @override
  String get refreshLibrary => 'Aggiorna libreria';

  @override
  String get removeFolder => 'Rimuovi cartella';

  @override
  String get unknownArtist => 'Artista sconosciuto';

  @override
  String get unknownAlbum => 'Album sconosciuto';

  @override
  String get variousArtists => 'Artisti vari';

  @override
  String get play => 'Riproduci';

  @override
  String get shuffle => 'Casuale';

  @override
  String get queue => 'Coda';

  @override
  String get nowPlaying => 'In riproduzione';

  @override
  String get nothingPlaying => 'Nessun brano in riproduzione';

  @override
  String get mute => 'Muto';

  @override
  String get scanning => 'Scansione in corso…';

  @override
  String get emptyQueue => 'La coda è vuota';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get sortDefault => 'Predefinito';

  @override
  String get sortTitle => 'Titolo';

  @override
  String get sortArtist => 'Artista';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortYear => 'Anno';

  @override
  String get sortAdded => 'Aggiunti di recente';

  @override
  String get sortDuration => 'Durata';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String missingTracksCount(int count) {
    return 'Brani non trovati ($count)';
  }

  @override
  String get addedToFavorites => 'Aggiunto ai preferiti';

  @override
  String get removedFromFavorites => 'Rimosso dai preferiti';

  @override
  String get undo => 'Annulla';

  @override
  String get noFavorites => 'Nessun preferito ancora';

  @override
  String get newPlaylist => 'Nuova playlist';

  @override
  String get newPlaylistEllipsis => 'Nuova playlist…';

  @override
  String get playlistName => 'Nome della playlist';

  @override
  String get create => 'Crea';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get rename => 'Rinomina';

  @override
  String get noPlaylists => 'Nessuna playlist. Creane una.';

  @override
  String get addToPlaylist => 'Aggiungi a playlist…';

  @override
  String addedToPlaylist(String name) {
    return 'Aggiunto a «$name»';
  }

  @override
  String get playNext => 'Riproduci dopo';

  @override
  String get addToQueue => 'Aggiungi alla coda';

  @override
  String get addedToQueue => 'Aggiunto alla coda';

  @override
  String get favorite => 'Preferito';

  @override
  String get removeFromFavorites => 'Rimuovi dai preferiti';

  @override
  String get removeFromList => 'Rimuovi';

  @override
  String get editInfo => 'Modifica info';

  @override
  String get details => 'Dettagli';

  @override
  String get showInFolder => 'Mostra nella cartella';

  @override
  String get detailPath => 'Percorso';

  @override
  String get detailFormat => 'Formato';

  @override
  String get detailSize => 'Dimensione';

  @override
  String get detailDuration => 'Durata';

  @override
  String get detailAdded => 'Aggiunto il';

  @override
  String get detailPlays => 'Riproduzioni';

  @override
  String get close => 'Chiudi';

  @override
  String get fieldTitle => 'Titolo';

  @override
  String get fieldArtist => 'Artista';

  @override
  String get fieldAlbum => 'Album';

  @override
  String get fieldAlbumArtist => 'Artista album';

  @override
  String get fieldYear => 'Anno';

  @override
  String get fieldTrackNumber => 'Numero traccia';

  @override
  String get fieldGenre => 'Genere';

  @override
  String get restoreFromFile => 'Ripristina dai tag del file';

  @override
  String get titleRequired => 'Il titolo non può essere vuoto';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeCarbon => 'Carbone';

  @override
  String get themeNavy => 'Blu notte';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get settingsTextSize => 'Dimensione testo';

  @override
  String get textSmall => 'Piccolo';

  @override
  String get textNormal => 'Normale';

  @override
  String get textLarge => 'Grande';

  @override
  String get settingsCompact => 'Modalità compatta';

  @override
  String get settingsReducedMotion => 'Animazioni ridotte';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLibrary => 'Libreria';

  @override
  String get rescanNow => 'Riscansiona ora';

  @override
  String get clearCoverCache => 'Svuota cache copertine';

  @override
  String get coverCacheCleared => 'Cache copertine svuotata';

  @override
  String get settingsOnline => 'Online';

  @override
  String get autoEnrich => 'Arricchimento automatico';

  @override
  String get autoEnrichHint =>
      'Cerca metadati e copertine online per i brani nuovi';

  @override
  String get autoLyrics => 'Testi automatici';

  @override
  String get autoLyricsHint => 'Scarica i testi da LRCLIB per i brani nuovi';

  @override
  String get settingsAbout => 'Info';

  @override
  String appVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get licenses => 'Licenze';

  @override
  String get personalUse => 'App per uso personale';

  @override
  String get missingTracksTitle => 'Brani non trovati';

  @override
  String get removeFromLibrary => 'Rimuovi dalla libreria';

  @override
  String get ignore => 'Ignora';

  @override
  String get confirmRemoveTitle => 'Rimuovere dalla libreria?';

  @override
  String get confirmRemoveBody =>
      'Il file non viene toccato; perdi preferiti e playlist di questo brano.';

  @override
  String get noMissingTracks => 'Nessun brano mancante';

  @override
  String get retry => 'Riprova';

  @override
  String scanFailed(String error) {
    return 'Scansione non riuscita: $error';
  }

  @override
  String playbackError(String reason, String title) {
    return 'Impossibile riprodurre «$title»: $reason';
  }

  @override
  String get reasonFileMissing => 'file non trovato';

  @override
  String get reasonUnplayable => 'file non riproducibile';

  @override
  String get reasonNotInLibrary => 'brano non presente in libreria';

  @override
  String get searchWeb => 'Cerca info sul web';

  @override
  String get enrichPreviewTitle => 'Anteprima informazioni';

  @override
  String get currentValue => 'Attuale';

  @override
  String get proposedValue => 'Proposto';

  @override
  String get apply => 'Applica';

  @override
  String get nothingFound => 'Nessuna informazione trovata';

  @override
  String get userEditedLocked => 'Modificato da te: non viene sovrascritto';

  @override
  String get fieldCover => 'Copertina';

  @override
  String get fieldLyrics => 'Testo';

  @override
  String get fieldCuriosity => 'Curiosità';

  @override
  String get enrichAlbum => 'Arricchisci album';

  @override
  String get enrichLibrary => 'Arricchisci tutta la libreria';

  @override
  String get enrichConfirmTitle => 'Arricchire la libreria?';

  @override
  String enrichConfirmBody(int count, int minutes) {
    return '$count brani, circa $minutes minuti. Vengono riempiti solo i campi vuoti.';
  }

  @override
  String enrichRunning(int done, int total) {
    return 'Arricchimento $done/$total';
  }

  @override
  String enrichResult(int notFound, int updated) {
    return '$updated aggiornati, $notFound non trovati';
  }

  @override
  String get enrichBusy => 'Un arricchimento è già in corso';

  @override
  String get serviceUnavailable =>
      'Servizio non disponibile, riprova più tardi';

  @override
  String get lyrics => 'Testo';

  @override
  String get searchLyrics => 'Cerca testo';

  @override
  String get noLyrics => 'Nessun testo disponibile';

  @override
  String get lyricsNotFound => 'Testo non trovato';

  @override
  String get copy => 'Copia';

  @override
  String get copied => 'Copiato';

  @override
  String get sourceWikipedia => 'Fonte: Wikipedia (CC BY-SA)';

  @override
  String get youtube => 'YouTube';

  @override
  String get ytHint => 'Cerca o incolla un link';

  @override
  String get ytDownload => 'Scarica';

  @override
  String get ytAlreadyInLibrary => 'Già in libreria';

  @override
  String get ytNoResults => 'Nessun risultato';

  @override
  String get ytQueued => 'In coda';

  @override
  String get ytDownloading => 'Download in corso';

  @override
  String get ytDone => 'Completato';

  @override
  String get ytFailed => 'Non riuscito';

  @override
  String get ytCancelled => 'Annullato';

  @override
  String get ytClearCompleted => 'Svuota completati';

  @override
  String get ytCancel => 'Annulla download';

  @override
  String get ytErrUnavailable => 'Video non disponibile (età/regione/privato)';

  @override
  String get ytErrNetwork => 'Rete non disponibile';

  @override
  String get ytErrChanged =>
      'YouTube ha cambiato qualcosa: aggiorna l’app o il pacchetto';

  @override
  String get ytNoFolder => 'Aggiungi prima una cartella musicale';

  @override
  String get ytLegal =>
      'Solo per uso personale. Rispetta i diritti d’autore e i termini di YouTube.';

  @override
  String get useDefaultFolder => 'Usa la cartella Musica del dispositivo';
}
