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
  String get addToQueue => 'Aggiungi in coda';

  @override
  String get addedToQueue => 'Aggiunto in coda';

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
  String get themeNotte => 'Notte viola';

  @override
  String get themeOled => 'Nero puro';

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
      'Solo per uso personale. Rispetta i diritti d’autore e i termini di YouTube e SoundCloud.';

  @override
  String get useDefaultFolder => 'Usa la cartella Musica del dispositivo';

  @override
  String get ytErrToolMissing =>
      'yt-dlp non trovato: installalo (pip install -U yt-dlp) e riprova';

  @override
  String get ytErrRateLimited =>
      'YouTube ha chiesto di rallentare: riprova tra qualche minuto';

  @override
  String get playlistChangeCover => 'Cambia copertina';

  @override
  String get playlistRemoveCover => 'Rimuovi copertina';

  @override
  String get coverTooLarge => 'Immagine troppo grande (max 4 MB)';

  @override
  String get addSongs => 'Aggiungi brani';

  @override
  String addNSongs(int count) {
    return 'Aggiungi ($count)';
  }

  @override
  String get allSongsInPlaylist => 'Tutti i brani sono già nella playlist';

  @override
  String get shareTitle => 'Condivisione';

  @override
  String get shareSend => 'Invia';

  @override
  String get shareReceive => 'Ricevi';

  @override
  String get shareAll => 'Tutta la libreria';

  @override
  String shareSelection(int count) {
    return 'Selezione ($count brani)';
  }

  @override
  String get sharePick => 'Scegli brani';

  @override
  String get shareStart => 'Avvia condivisione';

  @override
  String get shareStop => 'Ferma';

  @override
  String get shareActive => 'Condivisione attiva';

  @override
  String get shareAddress => 'Indirizzo (IP:porta)';

  @override
  String get sharePin => 'PIN';

  @override
  String get shareConnect => 'Connetti';

  @override
  String shareDownloadSelected(int count) {
    return 'Scarica selezionati ($count)';
  }

  @override
  String shareProgress(int done, int total) {
    return 'Brano $done di $total';
  }

  @override
  String shareDone(int count) {
    return '$count brani ricevuti';
  }

  @override
  String shareConnectedTo(String name) {
    return 'Connesso a $name';
  }

  @override
  String get shareErrUnreachable =>
      'Dispositivo non raggiungibile: controlla indirizzo e Wi‑Fi';

  @override
  String get shareErrPin => 'PIN errato';

  @override
  String get shareErrBlocked => 'Troppi tentativi: riprova tra un minuto';

  @override
  String get shareErrNotCodecore => 'Non è un dispositivo Codecore';

  @override
  String get shareErrFailed => 'Trasferimento non riuscito';

  @override
  String get shareNoNetwork => 'Nessuna rete locale trovata';

  @override
  String get shareFirewall =>
      'Windows può chiedere il permesso del firewall alla prima condivisione.';

  @override
  String get shareHint =>
      'Sullo stesso Wi‑Fi, apri «Ricevi» sull’altro dispositivo e inserisci indirizzo e PIN.';

  @override
  String get shareMenu => 'Condividi…';

  @override
  String get shareDeviceName => 'Nome dispositivo';

  @override
  String get importOld => 'Importa dalla vecchia app';

  @override
  String get importOldHint =>
      'Scegli codecore_library.db della versione Python';

  @override
  String importSummary(
    int favorites,
    int lyrics,
    int playlists,
    int unmatched,
  ) {
    return '$favorites preferiti, $playlists playlist, $lyrics testi importati, $unmatched non abbinati';
  }

  @override
  String get importFailed => 'Importazione non riuscita: file non valido';

  @override
  String get sleepTimer => 'Timer di spegnimento';

  @override
  String sleepMinutes(int count) {
    return '$count minuti';
  }

  @override
  String get sleepEndOfTrack => 'A fine brano';

  @override
  String get sleepCancel => 'Annulla timer';

  @override
  String get pause => 'Pausa';

  @override
  String get nextTrack => 'Brano successivo';

  @override
  String get previousTrack => 'Brano precedente';

  @override
  String get repeat => 'Ripeti';

  @override
  String get moreOptions => 'Altre opzioni';

  @override
  String get back => 'Indietro';

  @override
  String get settingsPlayback => 'Riproduzione';

  @override
  String get normalizeVolume => 'Normalizza volume';

  @override
  String get normalizeVolumeHint =>
      'Usa il ReplayGain dei file per ridurre i brani troppo forti';

  @override
  String get nearbyDevices => 'Dispositivi vicini';

  @override
  String get searchingDevices => 'Ricerca di dispositivi sulla rete…';

  @override
  String get noDevicesHint =>
      'Nessun dispositivo trovato. Apri Condivisione anche sull’altro dispositivo, sulla stessa rete.';

  @override
  String sendToDevice(String name) {
    return 'Invia a $name';
  }

  @override
  String offerSent(String name) {
    return 'Richiesta inviata a $name';
  }

  @override
  String get offerChooseFirst => 'Scegli prima i brani da inviare';

  @override
  String get sentRequests => 'Richieste inviate';

  @override
  String get receivedRequests => 'Richieste ricevute';

  @override
  String get offerPending => 'In attesa di risposta';

  @override
  String get offerAccepted => 'Accettata';

  @override
  String get offerDeclined => 'Rifiutata';

  @override
  String get offerCancelled => 'Annullata';

  @override
  String get offerExpired => 'Scaduta';

  @override
  String get offerDone => 'Completata';

  @override
  String get offerFailed => 'Non riuscita';

  @override
  String incomingTitle(String name) {
    return '$name vuole inviarti dei brani';
  }

  @override
  String incomingBody(int count, String size) {
    return '$count brani, $size MB';
  }

  @override
  String get accept => 'Accetta';

  @override
  String get decline => 'Rifiuta';

  @override
  String receivingProgress(int done, int total) {
    return 'Ricezione $done/$total';
  }

  @override
  String get manualConnection => 'Collegamento manuale (IP e PIN)';

  @override
  String get receiveFromLan => 'Ricevi dalla rete locale';

  @override
  String get receiveFromLanHint =>
      'Rende il dispositivo visibile e riceve richieste anche in background. Su Android mostra una notifica fissa con cui puoi disattivarlo';

  @override
  String get receiveServiceTitle => 'Codecore è visibile sulla rete';

  @override
  String get receiveServiceText =>
      'Pronto a ricevere brani dai dispositivi vicini';

  @override
  String get receiveServiceDisable => 'Disattiva';

  @override
  String get jamTitle => 'Jam';

  @override
  String get jamStart => 'Avvia una Jam';

  @override
  String jamStartWith(String name) {
    return 'Avvia Jam con $name';
  }

  @override
  String jamWaiting(String name) {
    return 'In attesa che $name accetti…';
  }

  @override
  String jamDeclined(String name) {
    return '$name ha rifiutato la Jam';
  }

  @override
  String jamBusy(String name) {
    return '$name ha già una Jam in corso';
  }

  @override
  String get jamUnreachable => 'Dispositivo non raggiungibile';

  @override
  String jamIncomingTitle(String name) {
    return '$name vuole avviare una Jam';
  }

  @override
  String get jamIncomingBody => 'Ascoltate insieme da una coda condivisa.';

  @override
  String jamIncomingDialog(String name) {
    return '$name vuole avviare una Jam con te. La musica parte da questo dispositivo e potete aggiungere brani entrambi.';
  }

  @override
  String get jamQueue => 'Coda condivisa';

  @override
  String get jamEmpty => 'La coda è vuota. Aggiungi dei brani.';

  @override
  String jamAddedBy(String name) {
    return 'aggiunto da $name';
  }

  @override
  String get jamYou => 'te';

  @override
  String get jamAddTracks => 'Aggiungi brani';

  @override
  String get jamAddToJam => 'Aggiungi alla Jam';

  @override
  String jamAdded(int count) {
    return 'Aggiunti alla Jam: $count';
  }

  @override
  String get jamOutput => 'Uscita audio';

  @override
  String get jamOutputHere => 'Questo dispositivo';

  @override
  String jamOutputOther(String name) {
    return '$name';
  }

  @override
  String get jamEnd => 'Termina Jam';

  @override
  String get jamLeave => 'Esci dalla Jam';

  @override
  String get jamEnded => 'La Jam è terminata';

  @override
  String get jamLost => 'Connessione persa';

  @override
  String get jamGuestCannotSkip =>
      'Solo chi ha avviato la Jam può cambiare brano';

  @override
  String get jamRemoveForbidden => 'Puoi rimuovere solo i tuoi brani';

  @override
  String get jamNowPlaying => 'In riproduzione';

  @override
  String get jamNothingPlaying => 'Niente in riproduzione';

  @override
  String jamWith(String name) {
    return 'Jam con $name';
  }

  @override
  String get jamUnavailable => 'Non disponibile';

  @override
  String get jamPlaying => 'La Jam è attiva';

  @override
  String get jamOpen => 'Apri la Jam';

  @override
  String jamSynced(int ms) {
    return 'Sincronizzato · scarto $ms ms';
  }

  @override
  String get jamSyncing => 'Sincronizzazione in corso…';

  @override
  String jamLatency(int ms) {
    return 'Latenza di questa uscita: $ms ms';
  }

  @override
  String get jamLatencyHint =>
      'Per cuffie o casse Bluetooth: aumenta finché le uscite suonano insieme.';

  @override
  String get jamOutputsHint => 'Più uscite suonano insieme';

  @override
  String get renamePlaylist => 'Rinomina playlist';

  @override
  String get confirmDeletePlaylistTitle => 'Eliminare la playlist?';

  @override
  String confirmDeletePlaylistBody(String name) {
    return '«$name» verrà eliminata. I brani restano nella libreria.';
  }

  @override
  String get confirmRemoveFolderTitle => 'Rimuovere la cartella?';

  @override
  String get confirmRemoveFolderBody =>
      'I suoi brani spariscono dalla libreria. I file restano sul dispositivo.';

  @override
  String get confirmClearCoversTitle => 'Svuotare la cache delle copertine?';

  @override
  String get confirmClearCoversBody =>
      'Le copertine verranno ricreate alla prossima scansione.';

  @override
  String get confirmRestoreTitle => 'Ripristinare dai tag del file?';

  @override
  String get confirmRestoreBody =>
      'Le tue modifiche a questo brano verranno sostituite con i dati del file.';

  @override
  String get removedFromPlaylist => 'Rimosso dalla playlist';

  @override
  String get removedFromQueue => 'Rimosso dalla coda';

  @override
  String get playNextDone => 'Verrà riprodotto dopo';

  @override
  String get ytSearchPrompt => 'Cerca un brano o incolla un link';

  @override
  String get loadFailed => 'Non riesco a caricare i dati.';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Cerca';

  @override
  String get devicesTitle => 'Dispositivi';

  @override
  String get devicesJamActive => 'Jam attiva';

  @override
  String jamPeople(int n) {
    return 'Jam · $n persone';
  }

  @override
  String get devicesVisibleTitle => 'Rendi visibile questo dispositivo';

  @override
  String get devicesVisibleHint =>
      'Per ricevere brani o fare una Jam, gli altri dispositivi devono poterti vedere sulla rete.';

  @override
  String get devicesJamShort => 'Jam';

  @override
  String get devicesSendShort => 'Invia';

  @override
  String get devicesMore => 'Condivisione e collegamento manuale';

  @override
  String jamParticipantsCount(int n) {
    return '$n persone';
  }

  @override
  String get playingFrom => 'In riproduzione da';

  @override
  String get playContextSearch => 'Ricerca';

  @override
  String get allTracks => 'Tutti i brani';

  @override
  String get trackInfo => 'Info sul brano';

  @override
  String get searchCuriosity => 'Cerca curiosità';

  @override
  String get upNext => 'Prossimi';

  @override
  String get openQueue => 'Apri coda';

  @override
  String get copyLink => 'Copia link';

  @override
  String get moreActions => 'Altre azioni';

  @override
  String get sleepChipEnd => 'fine brano';

  @override
  String get yourLibrary => 'La tua libreria';

  @override
  String playlistCountLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Playlist · $n brani',
      one: 'Playlist · 1 brano',
    );
    return '$_temp0';
  }

  @override
  String get sortRecent => 'Recenti';

  @override
  String get sortAlphabetical => 'Alfabetico';

  @override
  String get sortAddedRecently => 'Aggiunti di recente';

  @override
  String get viewAsGrid => 'Mostra come griglia';

  @override
  String get viewAsList => 'Mostra come elenco';

  @override
  String get kindAlbum => 'Album';

  @override
  String get kindArtist => 'Artista';

  @override
  String get kindPlaylist => 'Playlist';

  @override
  String discN(int n) {
    return 'Disco $n';
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
  String get mostPlayed => 'Più ascoltati';

  @override
  String get albumsSection => 'Album';

  @override
  String artistMeta(String albums, String tracks) {
    return '$albums · $tracks';
  }

  @override
  String get addAllToQueue => 'Aggiungi in coda';

  @override
  String addedNToQueue(int n) {
    return '$n brani aggiunti in coda';
  }

  @override
  String get editOrder => 'Modifica ordine';

  @override
  String get finishEditing => 'Fine';

  @override
  String get removeFromPlaylistAction => 'Rimuovi dalla playlist';

  @override
  String get noTracksInPlaylist => 'Questa playlist è vuota';

  @override
  String get greetingMorning => 'Buongiorno';

  @override
  String get greetingAfternoon => 'Buon pomeriggio';

  @override
  String get greetingEvening => 'Buonasera';

  @override
  String get homeResume => 'Riprendi';

  @override
  String get homeRecentlyPlayed => 'Ascoltati di recente';

  @override
  String get homeRecentlyAdded => 'Aggiunti di recente';

  @override
  String get homeTopTracks => 'I più ascoltati';

  @override
  String get homeRediscover => 'Da riscoprire';

  @override
  String get searchMainResult => 'Risultato principale';

  @override
  String get showAll => 'Mostra tutti';

  @override
  String searchOnYoutube(String query) {
    return 'Cerca «$query» su YouTube';
  }

  @override
  String get recentSearches => 'Ricerche recenti';

  @override
  String get genresTitle => 'Generi';

  @override
  String downloadsChip(int n) {
    return 'Download ($n)';
  }

  @override
  String get gotIt => 'Ho capito';

  @override
  String get searchEmptyLibrary => 'Nessun risultato in libreria';

  @override
  String get ytInfoTooltip => 'Informazioni sull’uso';

  @override
  String get removeRecentSearch => 'Rimuovi dalle ricerche recenti';

  @override
  String get groupGoTo => 'Vai a';

  @override
  String get goToAlbum => 'Vai all’album';

  @override
  String get goToArtist => 'Vai all’artista';

  @override
  String get groupQueue => 'Coda';

  @override
  String get groupCollection => 'Raccolta';

  @override
  String get groupEdit => 'Modifica';

  @override
  String get groupOther => 'Altro';

  @override
  String get queueNowPlaying => 'In riproduzione';

  @override
  String get queueNext => 'Prossimi';

  @override
  String get queueClear => 'Svuota';

  @override
  String get queueCleared => 'Coda svuotata';

  @override
  String get jamOutputsAndSync => 'Uscite e sincronia';

  @override
  String get jamHostTag => 'host';

  @override
  String get jamWaitingEmpty => 'Nessuna Jam in corso';

  @override
  String get activityTitle => 'Attività';

  @override
  String activityScan(int done, int total) {
    return 'Scansione · $done/$total';
  }

  @override
  String get activityScanIdle => 'Scansione in corso';

  @override
  String activityEnrich(int done, int total) {
    return 'Arricchimento · $done/$total';
  }

  @override
  String activityDownload(String title) {
    return 'Download · $title';
  }

  @override
  String activityTransfer(String name, int n) {
    return 'Invio a $name · $n brani';
  }

  @override
  String get activityNone => 'Nessuna attività';

  @override
  String get activityCompleted => 'Completate';

  @override
  String get activityClear => 'Pulisci';

  @override
  String activityRunning(int n) {
    return '$n attività in corso';
  }

  @override
  String get settingsLocalNetwork => 'Rete locale';

  @override
  String get removeAll => 'Rimuovi tutti';

  @override
  String get confirmRemoveAllTitle => 'Rimuovere tutti dalla libreria?';

  @override
  String confirmRemoveAllBody(int n) {
    return '$n brani non trovati verranno tolti dalla libreria. I file non vengono toccati; perdi preferiti e playlist di questi brani.';
  }

  @override
  String get csvImportMenu => 'Importa da Exportify (CSV)';

  @override
  String get csvImportIntroTitle => 'Importa una playlist';

  @override
  String get csvImportIntroSource =>
      'Il file CSV si crea gratis dal sito Exportify — exportify.net (non serve nessuna app).';

  @override
  String get csvImportStep1 =>
      'Apri https://exportify.net nel browser (anche dal telefono).';

  @override
  String get csvImportStep2 =>
      'Tocca «Get Started» e accedi con il tuo account Spotify.';

  @override
  String get csvImportStep3 =>
      'Accanto alla playlist che vuoi tocca «Export»: si scarica un file .csv col nome della playlist.';

  @override
  String get csvImportStep4 => 'Torna qui e tocca «Scegli file CSV».';

  @override
  String get csvImportNote =>
      'Codecore cerca i brani nella tua libreria e scarica gli altri da YouTube Music.';

  @override
  String get csvImportNoteOffline =>
      'Verranno collegati solo i brani già presenti nella tua libreria.';

  @override
  String get csvImportCopy => 'Copia indirizzo';

  @override
  String get csvImportCopied => 'Indirizzo copiato';

  @override
  String get csvImportPick => 'Scegli file';

  @override
  String get csvImportNotExportify =>
      'Formato non riconosciuto. Scegli un CSV (Exportify, TuneMyMusic, Soundiiz, Last.fm) o una playlist M3U/M3U8/XSPF.';

  @override
  String get csvImportReadFailed => 'Impossibile leggere il file.';

  @override
  String get csvImportPreviewTitle => 'Importa playlist';

  @override
  String get csvImportName => 'Nome della playlist';

  @override
  String csvImportSummary(int total, int known, int todo) {
    return '$total brani · $known già in libreria · $todo da scaricare';
  }

  @override
  String csvImportSkipped(int n) {
    return '$n righe ignorate (podcast o file locali)';
  }

  @override
  String csvImportEstimate(int minutes) {
    return 'Tempo stimato: circa $minutes min';
  }

  @override
  String get csvImportExists => 'Esiste già una playlist con questo nome';

  @override
  String get csvImportUpdate =>
      'Aggiorna quella esistente (aggiunge solo i brani nuovi)';

  @override
  String get csvImportNew => 'Crea una nuova playlist';

  @override
  String get csvImportGo => 'Importa';

  @override
  String get csvImportStarted =>
      'Importazione avviata: la segui nel Centro Attività';

  @override
  String activityImport(String name, int done, int total) {
    return 'Importazione «$name» · $done/$total';
  }

  @override
  String activityImportPaused(String name, int done, int total) {
    return 'Importazione «$name» · in pausa · $done/$total';
  }

  @override
  String csvImportBanner(int done, int total, int review, int missing) {
    return 'Importazione: $done/$total · $review da verificare · $missing non trovati';
  }

  @override
  String csvImportBannerPaused(int done, int total, int review, int missing) {
    return 'Importazione in pausa: $done/$total · $review da verificare · $missing non trovati';
  }

  @override
  String get csvImportReview => 'Rivedi';

  @override
  String get csvImportResume => 'Riprendi';

  @override
  String get csvImportPause => 'Pausa';

  @override
  String get csvImportCancelTitle => 'Annullare l\'importazione?';

  @override
  String get csvImportCancelBody =>
      'I brani già scaricati restano nella playlist.';

  @override
  String csvImportDone(int added, int review, int missing) {
    return 'Importazione completata: $added aggiunti, $review da verificare, $missing non trovati';
  }

  @override
  String get csvImportFailing => 'Troppi errori di fila: importazione in pausa';

  @override
  String get csvImportReviewTitle => 'Rivedi';

  @override
  String get csvImportToReview => 'Da verificare';

  @override
  String get csvImportNotFound => 'Non trovati';

  @override
  String get csvImportErrors => 'Con errori';

  @override
  String get csvImportRetryAll => 'Riprova tutti';

  @override
  String get csvImportSkip => 'Salta';

  @override
  String get csvImportManual => 'Cerca a mano';

  @override
  String get csvImportNothing => 'Niente da rivedere.';

  @override
  String get csvImportSearch => 'Cerca';

  @override
  String csvImportWanted(String title, String artist, String duration) {
    return 'Cercato: $title · $artist · $duration';
  }

  @override
  String get csvImportDownload => 'Scarica';

  @override
  String get csvImportCancelGo => 'Annulla importazione';

  @override
  String get exportLog => 'Esporta log';

  @override
  String get exportLogHint =>
      'File di testo senza percorsi personali, indirizzi di rete né PIN';

  @override
  String get exportLogDebugOnly =>
      'Disponibile solo nella versione installata (in debug il log non viene scritto su file)';

  @override
  String get exportLogNone => 'Non c\'è ancora nessun log da esportare';

  @override
  String get exportLogSaved => 'Log salvato';

  @override
  String get exportLogFailed => 'Impossibile salvare il log';

  @override
  String get exportPlaylist => 'Esporta…';

  @override
  String get exportPlaylistTitle => 'Esporta playlist';

  @override
  String get exportFormatM3u8 => 'M3U8 · per altri lettori';

  @override
  String get exportFormatCsv => 'CSV · come Exportify';

  @override
  String get exportFormatJson => 'JSON · formato Codecore';

  @override
  String get exportRelativePaths => 'Percorsi relativi';

  @override
  String get exportRelativeHint =>
      'Rispetto alla cartella comune dei brani: salva il file lì';

  @override
  String get exportAction => 'Esporta';

  @override
  String get exportSaved => 'Playlist esportata';

  @override
  String get exportEmpty => 'La playlist è vuota';

  @override
  String get exportFailed => 'Impossibile esportare la playlist';

  @override
  String get ytErrToolOutdated =>
      'yt-dlp è troppo vecchio: aggiornalo (Impostazioni → Download → Aggiorna) e riprova';

  @override
  String ytDlpOutdatedBanner(String version) {
    return 'yt-dlp $version è troppo vecchio: i download potrebbero non funzionare';
  }

  @override
  String get settingsDownloads => 'Download';

  @override
  String ytDlpVersion(String version) {
    return 'yt-dlp $version';
  }

  @override
  String get ytDlpUnknownVersion => 'yt-dlp non trovato';

  @override
  String get ytDlpUpdate => 'Aggiorna';

  @override
  String ytDlpUpdating(int percent) {
    return 'Aggiornamento… $percent%';
  }

  @override
  String ytDlpUpdated(String version) {
    return 'Aggiornato alla versione $version';
  }

  @override
  String get ytDlpTooOld => 'Troppo vecchio: tocca Aggiorna';

  @override
  String get ytDlpUpdateErrNetwork =>
      'Aggiornamento non riuscito: rete non raggiungibile';

  @override
  String get ytDlpUpdateErrHash =>
      'Aggiornamento annullato: il file scaricato non ha superato il controllo di integrità';

  @override
  String get ytDlpUpdateErrOther =>
      'Aggiornamento non riuscito (dettagli nel log)';

  @override
  String get downloadParallel => 'Download contemporanei';

  @override
  String get downloadParallelHint =>
      'Più insieme è più veloce, ma YouTube può chiedere di rallentare';

  @override
  String get downloadRateLimit => 'Limite di velocità';

  @override
  String get downloadRateNone => 'Nessuno';

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
    return 'Download · $title · nuovo tentativo tra $seconds s ($attempt/$max)';
  }

  @override
  String get downloadOriginal => 'Qualità originale (senza ricodifica)';

  @override
  String get downloadOriginalHint =>
      'Tiene l\'audio di YouTube com\'è (M4A/Opus): nessuna perdita, file più piccoli. Spento: MP3 256 kbps';

  @override
  String get searchCacheClear => 'Svuota cache ricerche';

  @override
  String searchCacheCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ricerche salvate',
      one: '1 ricerca salvata',
      zero: 'Vuota',
    );
    return '$_temp0';
  }

  @override
  String get searchCacheCleared => 'Cache svuotata';

  @override
  String csvImportLengthOff(String found, String wanted) {
    return 'Durata diversa: $found invece di $wanted';
  }

  @override
  String get csvImportKeep => 'Tieni questo';

  @override
  String get csvImportTooBig =>
      'Il file è troppo grande per essere una playlist (massimo 5 MB e 10.000 brani)';

  @override
  String get csvImportAlsoAccepts =>
      'Accetta anche: TuneMyMusic, Soundiiz, Last.fm (CSV), M3U/M3U8, XSPF.';

  @override
  String get csvImportPlanned => 'Abbinamenti pronti: controllali e scarica';

  @override
  String get csvImportLinkOnly => 'Solo collega (nessun download)';

  @override
  String get csvImportLinkOnlyHint =>
      'Crea la playlist con quello che hai già e basta';

  @override
  String get csvImportPlanFirst => 'Rivedi prima di scaricare';

  @override
  String get csvImportPlanFirstHint => 'Cerca tutto, poi scegli cosa scaricare';

  @override
  String get csvImportPlanTitle => 'Abbinamenti';

  @override
  String csvImportPlanGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Scarica $n brani',
      one: 'Scarica 1 brano',
    );
    return '$_temp0';
  }

  @override
  String get csvImportPlanKnown => 'già scaricato';

  @override
  String get csvImportPlanEmpty => 'Niente da scaricare';

  @override
  String csvImportBannerPlanned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n brani da scaricare',
      one: '1 brano da scaricare',
    );
    return 'Abbinamenti pronti: $_temp0';
  }

  @override
  String get settingsAdvanced => 'Avanzate';

  @override
  String get importSureThreshold => 'Abbinamento sicuro da';

  @override
  String get importSureThresholdHint =>
      'Sopra questo punteggio un brano dell\'importazione si scarica senza chiedere';

  @override
  String get importReviewThreshold => 'Da verificare da';

  @override
  String get importReviewThresholdHint =>
      'Tra questo punteggio e quello sicuro il brano finisce in «Da verificare»; sotto, in «Non trovati»';

  @override
  String get importThresholdsReset => 'Ripristina i valori predefiniti';

  @override
  String csvImportEstimateHours(int hours, int minutes) {
    return 'Tempo stimato: circa $hours h $minutes min';
  }

  @override
  String csvImportBlocks(int size) {
    return 'Importa a blocchi da $size';
  }

  @override
  String csvImportBigWarning(int n) {
    return 'Sono $n brani da scaricare: ci vorranno ore. A blocchi, uno dopo l\'altro, l\'ordine della playlist resta giusto e puoi fermarti tra un blocco e l\'altro.';
  }

  @override
  String get etaLessThanMinute => 'meno di 1 min';

  @override
  String etaMinutes(int minutes) {
    return 'circa $minutes min';
  }

  @override
  String etaHours(int hours, int minutes) {
    return 'circa $hours h $minutes min';
  }

  @override
  String get csvImportOwnFolder => 'Cartella per questa playlist';

  @override
  String get csvImportOwnFolderHint =>
      'Salva i brani scaricati in una sottocartella col nome della playlist';

  @override
  String get csvImportNumberFiles => 'Numera i file';

  @override
  String get csvImportNumberFilesHint =>
      '07 - Artista - Titolo: la cartella si ascolta nell\'ordine giusto anche fuori da Codecore';

  @override
  String get csvImportFetchCovers => 'Cerca le copertine';

  @override
  String get csvImportFetchCoversHint =>
      'Dopo ogni download cerca la copertina dell\'album su iTunes (album e artista del file)';

  @override
  String get csvImportExport => 'Esporta esito';

  @override
  String get csvImportExported => 'Esito salvato';

  @override
  String get csvOutHeaderRow => 'Riga';

  @override
  String get csvOutHeaderTitle => 'Titolo';

  @override
  String get csvOutHeaderArtists => 'Artisti';

  @override
  String get csvOutHeaderAlbum => 'Album';

  @override
  String get csvOutHeaderDuration => 'Durata (ms)';

  @override
  String get csvOutHeaderIsrc => 'ISRC';

  @override
  String get csvOutHeaderStatus => 'Esito';

  @override
  String get csvOutHeaderNote => 'Motivo';

  @override
  String get csvOutHeaderVideo => 'Video scelto';

  @override
  String get csvOutHeaderScore => 'Punteggio';

  @override
  String get importStatusPending => 'Da cercare';

  @override
  String get importStatusQueued => 'In coda';

  @override
  String get importStatusDownloaded => 'Scaricato';

  @override
  String get importStatusLinked => 'Già in libreria';

  @override
  String get importStatusReview => 'Da verificare';

  @override
  String get importStatusNotFound => 'Non trovato';

  @override
  String get importStatusFailed => 'Errore';

  @override
  String get importStatusSkipped => 'Saltato';

  @override
  String get importStatusPlanned => 'Pianificato';

  @override
  String get importStatusRemoved => 'Rimosso dalla sorgente';

  @override
  String get importNoteNoResults => 'Nessun risultato';

  @override
  String get importNoteLowScore => 'Abbinamento poco sicuro';

  @override
  String get importNoteLinkOnly => 'Solo collegamento: non cercato';

  @override
  String get importNoteYoutubeOff => 'Download disattivato';

  @override
  String get importNoteDownloadFailed => 'Download non riuscito';

  @override
  String get importNoteLengthOff => 'Durata diversa dal file';

  @override
  String get importNoteUnchanged => 'Già nella playlist';

  @override
  String get csvImportSync => 'Sincronizza';

  @override
  String csvImportSyncCounts(int added, int removed) {
    return '+$added nuovi · −$removed rimossi dalla playlist (i file restano)';
  }

  @override
  String get csvImportSyncChecking => 'Controllo le differenze…';

  @override
  String get playbackSpeed => 'Velocità di riproduzione';

  @override
  String get playbackSpeedHint =>
      'Il tono resta quello originale. Il timer di spegnimento conta il tempo reale, non quello del brano.';

  @override
  String resumeFrom(String time) {
    return 'riprendi da $time';
  }

  @override
  String get restartFromBeginning => 'Ricomincia dall’inizio';

  @override
  String get previewTrack => 'Anteprima 20 s';

  @override
  String get equalizer => 'Equalizzatore';

  @override
  String get eqOutputSpeaker => 'Altoparlante';

  @override
  String get eqOutputHeadphones => 'Cuffie';

  @override
  String get eqHint =>
      'Ogni uscita ricorda la sua curva: cambia da sola quando colleghi le cuffie.';

  @override
  String get eqPresetFlat => 'Piatto';

  @override
  String get eqPresetBass => 'Bassi';

  @override
  String get eqPresetVoice => 'Voce';

  @override
  String get eqPresetTreble => 'Acuti';

  @override
  String get eqPresetCustom => 'Personalizzato';

  @override
  String get eqReset => 'Reimposta';

  @override
  String get eqWaiting => 'Le bande compaiono quando parte il primo brano.';

  @override
  String get eqUnavailable =>
      'L\'equalizzatore non è disponibile su questo dispositivo.';

  @override
  String get transitionMode => 'Passaggio tra i brani';

  @override
  String get transitionNormal => 'Normale';

  @override
  String get transitionGapless => 'Senza pause';

  @override
  String get transitionCrossfade => 'Dissolvenza';

  @override
  String get transitionHint =>
      'Senza pause funziona meglio con brani dello stesso formato (per esempio tutti FLAC).';

  @override
  String crossfadeLength(int seconds) {
    return 'Durata della dissolvenza: $seconds s';
  }

  @override
  String get crossfadePlainInAlbum => 'Non sfumare nello stesso album';

  @override
  String get crossfadePlainInAlbumHint =>
      'Dentro un album i brani si susseguono senza pause, senza sovrapporsi.';

  @override
  String get selectedRow => 'Selezionato';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionati',
      one: '1 selezionato',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Seleziona tutto';

  @override
  String get exitSelection => 'Esci dalla selezione';

  @override
  String get bulkActions => 'Azioni';

  @override
  String playNextMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani verranno riprodotti dopo',
      one: '1 brano verrà riprodotto dopo',
    );
    return '$_temp0';
  }

  @override
  String addedToQueueMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani aggiunti in coda',
      one: '1 brano aggiunto in coda',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistMany(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani aggiunti a «$name»',
      one: '1 brano aggiunto a «$name»',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistSkipped(int added, int skipped, String name) {
    return '$added aggiunti a «$name», $skipped già presenti';
  }

  @override
  String allAlreadyInPlaylist(String name) {
    return 'Erano già tutti in «$name»';
  }

  @override
  String favoritesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani nei preferiti',
      one: '1 brano nei preferiti',
    );
    return '$_temp0';
  }

  @override
  String favoritesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani tolti dai preferiti',
      one: '1 brano tolto dai preferiti',
    );
    return '$_temp0';
  }

  @override
  String get bulkAddToFavorites => 'Aggiungi ai preferiti';

  @override
  String get bulkRemoveFromFavorites => 'Togli dai preferiti';

  @override
  String removeManyFromPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rimuovere $count brani dalla playlist?',
      one: 'Rimuovere 1 brano dalla playlist?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromPlaylistBody =>
      'I file e la libreria non vengono toccati.';

  @override
  String removedManyFromPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani rimossi',
      one: '1 brano rimosso',
    );
    return '$_temp0';
  }

  @override
  String removeManyFromLibraryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Togliere $count brani dalla libreria?',
      one: 'Togliere 1 brano dalla libreria?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromLibraryBody =>
      'I file non esistono più: spariscono solo dalla libreria (perdi preferiti e playlist di questi brani).';

  @override
  String removedManyFromLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani tolti dalla libreria',
      one: '1 brano tolto dalla libreria',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count download avviati',
      one: '1 download avviato',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsSkipped(int started, int skipped) {
    return '$started download avviati, $skipped già in libreria o in corso';
  }

  @override
  String get ytNothingToDownload => 'Sono già tutti in libreria o in corso';

  @override
  String get themeChiaro => 'Chiaro';

  @override
  String get settingsAccent => 'Colore d\'accento';

  @override
  String get accentViola => 'Viola';

  @override
  String get accentBlu => 'Blu';

  @override
  String get accentAcqua => 'Verde acqua';

  @override
  String get accentVerde => 'Verde';

  @override
  String get accentAmbra => 'Ambra';

  @override
  String get accentArancio => 'Arancio';

  @override
  String get accentRosa => 'Rosa';

  @override
  String get accentRosso => 'Rosso';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingStart => 'Inizia';

  @override
  String onboardingPageOf(int page, int total) {
    return 'Pagina $page di $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Benvenuto in Codecore';

  @override
  String get onboardingWelcomeBody =>
      'Il tuo lettore musicale personale: niente account, niente server. La musica resta sul tuo dispositivo.';

  @override
  String get onboardingFoldersTitle => 'La tua musica';

  @override
  String get onboardingFoldersBody =>
      'Scegli le cartelle dove tieni i brani. Codecore li legge: non li modifica e non li sposta.';

  @override
  String onboardingFoldersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartelle aggiunte',
      one: '1 cartella aggiunta',
    );
    return '$_temp0';
  }

  @override
  String get onboardingAllowAccess => 'Consenti l’accesso ai file audio';

  @override
  String get onboardingAccessGranted => 'Accesso consentito';

  @override
  String get onboardingOnlineTitle => 'Funzioni online';

  @override
  String get onboardingOnlineBody =>
      'Sono spente: Codecore non si collega a Internet per conto suo. Puoi accenderle ora o più tardi dalle Impostazioni.';

  @override
  String get onboardingShareTitle => 'Download, Jam e condivisione';

  @override
  String get onboardingYoutubeBody =>
      'Puoi scaricare brani da YouTube sul tuo dispositivo, per ascoltarli come il resto della tua musica.';

  @override
  String get onboardingJamBody =>
      'Con una Jam ascolti la stessa musica insieme a un altro dispositivo sulla stessa rete.';

  @override
  String get onboardingSendBody =>
      'Puoi inviare brani ad altri dispositivi vicini, con un PIN, senza passare da Internet.';

  @override
  String get historyTitle => 'Cronologia';

  @override
  String get historySubtitle => 'Quello che hai ascoltato';

  @override
  String get historyToday => 'Oggi';

  @override
  String get historyYesterday => 'Ieri';

  @override
  String get historyEmpty => 'Qui comparirà quello che ascolti.';

  @override
  String get historyOff =>
      'La cronologia è spenta: attivala in Impostazioni → Riproduzione.';

  @override
  String get historyClear => 'Cancella cronologia';

  @override
  String get historyClearTitle => 'Cancellare la cronologia?';

  @override
  String get historyClearBody =>
      'Si cancella solo l’elenco degli ascolti: contatori, preferiti e playlist restano come sono.';

  @override
  String get historyCleared => 'Cronologia cancellata';

  @override
  String get settingsRecordHistory => 'Registra la cronologia di ascolto';

  @override
  String get settingsRecordHistoryHint =>
      'Resta sul dispositivo. Spenta, non si aggiunge nient’altro all’elenco.';

  @override
  String get statsTitle => 'Statistiche';

  @override
  String get statsSubtitle => 'Quanto e cosa ascolti';

  @override
  String get statsMonth => 'Mese';

  @override
  String get statsYear => 'Anno';

  @override
  String get statsPrevious => 'Periodo precedente';

  @override
  String get statsNext => 'Periodo successivo';

  @override
  String get statsEmpty => 'Nessun ascolto in questo periodo.';

  @override
  String statsPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ascolti',
      one: '1 ascolto',
    );
    return '$_temp0';
  }

  @override
  String statsDistinct(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani diversi',
      one: '1 brano diverso',
    );
    return '$_temp0';
  }

  @override
  String statsHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get statsTopTracks => 'Brani più ascoltati';

  @override
  String get statsTopArtists => 'Artisti più ascoltati';

  @override
  String get statsTopAlbums => 'Album più ascoltati';

  @override
  String get statsFavouriteHour => 'Ora preferita';

  @override
  String get statsFirstListen => 'Primo ascolto';

  @override
  String statsFirstValue(String title, String date) {
    return '$title · $date';
  }

  @override
  String get statsYourMonth => 'Il tuo mese';

  @override
  String statsTopArtistHome(String name) {
    return 'Il più ascoltato: $name';
  }

  @override
  String get ruleChipArtist => 'artista:';

  @override
  String get ruleChipYear => 'anno:';

  @override
  String get ruleChipGenre => 'genere:';

  @override
  String get ruleChipTag => 'tag:';

  @override
  String get ruleChipFavorites => 'preferiti';

  @override
  String ruleWarning(String term) {
    return 'Non capisco «$term»: lo cerco come testo.';
  }

  @override
  String get ruleHelpTooltip => 'Aiuto sulla ricerca';

  @override
  String get smartPlaylistNew => 'Nuova playlist intelligente';

  @override
  String get smartPlaylistEdit => 'Modifica playlist intelligente';

  @override
  String get smartPlaylistLabel => 'Playlist intelligente';

  @override
  String smartSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Playlist intelligente · $count brani',
      one: 'Playlist intelligente · 1 brano',
    );
    return '$_temp0';
  }

  @override
  String get smartName => 'Nome';

  @override
  String get smartNameRequired => 'Scrivi un nome';

  @override
  String get smartRules => 'Regole';

  @override
  String get smartRulesHint => 'artista:\"pink floyd\" -live anno:1970..1979';

  @override
  String get smartNoRules =>
      'Senza regole la playlist contiene tutta la libreria.';

  @override
  String get smartSortBy => 'Ordina per';

  @override
  String get smartSortMostPlayed => 'Più ascoltati';

  @override
  String get smartSortRandom => 'A caso';

  @override
  String get smartLimit => 'Limite di brani (facoltativo)';

  @override
  String get smartTemplates => 'Modelli';

  @override
  String get smartTplNever => 'Mai ascoltati';

  @override
  String get smartTplRecent => 'Aggiunti di recente';

  @override
  String get smartTplTop => 'I più ascoltati';

  @override
  String get smartTpl90s => 'Anni ’90';

  @override
  String get smartConvert => 'Converti in playlist normale';

  @override
  String smartConverted(String name) {
    return 'Creata la playlist «$name» con l’elenco attuale';
  }

  @override
  String smartDeleteTitle(String name) {
    return 'Eliminare «$name»?';
  }

  @override
  String get smartDeleteBody =>
      'Si elimina solo la regola: i brani restano dove sono.';

  @override
  String get smartAutoNote => 'L’elenco si aggiorna da solo.';

  @override
  String get tagsTitle => 'Etichette';

  @override
  String get tagsSubtitle => 'Le tue etichette';

  @override
  String tagsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etichette',
      one: '1 etichetta',
    );
    return '$_temp0';
  }

  @override
  String get tagsEllipsis => 'Etichette…';

  @override
  String get tagNew => 'Nuova etichetta';

  @override
  String get tagRename => 'Rinomina etichetta';

  @override
  String get tagColor => 'Colore';

  @override
  String get tagNoColor => 'Nessun colore';

  @override
  String get tagNameTaken => 'Esiste già un’etichetta con questo nome';

  @override
  String tagDeleteTitle(String name) {
    return 'Eliminare l’etichetta «$name»?';
  }

  @override
  String get tagDeleteBody =>
      'Si toglie solo l’etichetta dai brani: i brani restano nella libreria.';

  @override
  String get tagsEmpty => 'Nessuna etichetta: creane una dal menu di un brano.';

  @override
  String get tagAddToSelection => 'Aggiungi etichetta…';

  @override
  String get tagRemoveFromSelection => 'Togli etichetta…';

  @override
  String tagAssigned(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani etichettati «$name»',
      one: '1 brano etichettato «$name»',
    );
    return '$_temp0';
  }

  @override
  String tagUnassigned(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '«$name» tolta da $count brani',
      one: '«$name» tolta da 1 brano',
    );
    return '$_temp0';
  }

  @override
  String get tagNoneToRemove => 'I brani scelti non hanno etichette.';

  @override
  String get ruleHelpTitle => 'Cercare con gli operatori';

  @override
  String get ruleHelpIntro =>
      'Scrivi parole come sempre, oppure aggiungi operatori: tutti devono valere insieme.';

  @override
  String get ruleHelpArtist =>
      'artista:\"pink floyd\" — brani di un artista (basta una parte del nome); lo stesso con album:, genere:, cartella:';

  @override
  String get ruleHelpYear =>
      'anno:1990..1999 — un intervallo (anche aperto: anno:..1980, anno:2000..); anno>1990, anno<=1985';

  @override
  String get ruleHelpDuration =>
      'durata>5m — durata (m minuti, s secondi): durata<90s, durata:2m..4m';

  @override
  String get ruleHelpAdded =>
      'aggiunto<30g — aggiunti da meno di 30 giorni (g giorni, sett settimane, mesi): aggiunto>6mesi';

  @override
  String get ruleHelpNot =>
      '-live — il segno meno esclude: -artista:floyd, -\"dal vivo\"';

  @override
  String get ruleHelpOr =>
      'rock OR jazz — OR (maiuscolo) tra due termini: ne basta uno';

  @override
  String get ruleHelpFlags =>
      'preferiti, mai-ascoltati — solo i preferiti, o i brani mai ascoltati; ascolti>10 per quelli più ascoltati';

  @override
  String get ruleHelpOthers =>
      'tag:live, formato:flac — un’etichetta tua, o il formato del file (nome intero, senza maiuscole)';

  @override
  String get ruleHelpSmart =>
      'Le stesse regole servono per le playlist intelligenti (Libreria → + → Nuova playlist intelligente).';

  @override
  String get cleanupSection => 'Pulizia libreria';

  @override
  String get duplicatesTitle => 'Duplicati';

  @override
  String get duplicatesTileHint => 'Lo stesso brano in più copie o qualità';

  @override
  String get duplicatesIntro =>
      'Cerca lo stesso brano in più copie: lo stesso file in due cartelle o lo stesso brano in due qualità. Prima di unire vedi un’anteprima. Preferiti, playlist, ascolti, testi ed etichette passano al brano che tieni; gli altri vengono solo nascosti e li ripristini da «Brani nascosti». Nessun file viene cancellato senza una doppia conferma.';

  @override
  String get duplicatesSearch => 'Cerca duplicati';

  @override
  String get duplicatesSearchAgain => 'Cerca di nuovo';

  @override
  String get duplicatesReading => 'Leggo la libreria…';

  @override
  String duplicatesHashing(int done, int total) {
    return 'Controllo i file: $done di $total';
  }

  @override
  String get duplicatesGrouping => 'Confronto i brani…';

  @override
  String get duplicatesFailed => 'La ricerca non è riuscita. Riprova.';

  @override
  String get duplicatesNone => 'Nessun duplicato trovato';

  @override
  String duplicatesSummary(int groups, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups gruppi',
      one: '1 gruppo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hidden,
      locale: localeName,
      other: '$hidden brani da nascondere',
      one: '1 brano da nascondere',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get duplicatesExactBadge => 'Identici';

  @override
  String get duplicatesProbableBadge => 'Probabili';

  @override
  String get duplicatesKeepLabel => 'Da tenere';

  @override
  String get duplicatesPickKeep => 'Tocca un brano per tenerlo';

  @override
  String get duplicatesMerge => 'Unisci';

  @override
  String get duplicatesNotDuplicates => 'Non sono duplicati';

  @override
  String duplicatesMergeAllExact(int count) {
    return 'Unisci tutti gli identici ($count)';
  }

  @override
  String get duplicatesMergeAllTitle => 'Unire tutti gli identici?';

  @override
  String duplicatesMergeAllBody(int groups, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups gruppi',
      one: '1 gruppo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hidden,
      locale: localeName,
      other: '$hidden brani nascosti',
      one: '1 brano nascosto',
    );
    return '$_temp0, $_temp1. Preferiti, playlist, ascolti e testi passano ai brani che restano.';
  }

  @override
  String duplicatesMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani nascosti',
      one: '1 brano nascosto',
    );
    return 'Unito: $_temp0';
  }

  @override
  String duplicatesDeleteFiles(int count, String size) {
    return 'Elimina anche i file ($count, $size)';
  }

  @override
  String get duplicatesDeleteListTitle => 'Eliminare questi file?';

  @override
  String get duplicatesDeleteListBody =>
      'Verranno cancellati dal dispositivo e non si possono recuperare. I brani che tieni restano dove sono.';

  @override
  String get duplicatesDeleteContinue => 'Continua';

  @override
  String duplicatesDeleteFinalTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminare definitivamente $count file?',
      one: 'Eliminare definitivamente 1 file?',
    );
    return '$_temp0';
  }

  @override
  String duplicatesDeleteFinalBody(String size) {
    return 'Spazio liberato: $size. Questa azione non si può annullare.';
  }

  @override
  String get duplicatesDeleteGo => 'Elimina definitivamente';

  @override
  String get duplicatesDeleteDoneTitle => 'Fatto';

  @override
  String duplicatesDeleteDone(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file eliminati',
      one: '1 file eliminato',
    );
    return '$_temp0 ($size).';
  }

  @override
  String duplicatesDeleteFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file non eliminati:',
      one: '1 file non eliminato:',
    );
    return '$_temp0';
  }

  @override
  String duplicatesDeleteSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file non toccati: sono lo stesso file del brano tenuto.',
      one: '1 file non toccato: è lo stesso file del brano tenuto.',
    );
    return '$_temp0';
  }

  @override
  String get duplicatesDeleteAndroidHint =>
      'Su Android si possono eliminare solo i file nelle cartelle a cui l’app ha accesso.';

  @override
  String activityCleanup(int done, int total) {
    return 'Ricerca duplicati: $done di $total';
  }

  @override
  String get hiddenTracksTitle => 'Brani nascosti';

  @override
  String hiddenTracksCount(int count) {
    return 'Brani nascosti ($count)';
  }

  @override
  String get hiddenTracksEmpty => 'Nessun brano nascosto';

  @override
  String get hiddenTracksHint =>
      'I doppioni uniti non compaiono in libreria. «Ripristina» li rimette al loro posto.';

  @override
  String get hiddenRestore => 'Ripristina';

  @override
  String hiddenRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani ripristinati',
      one: '1 brano ripristinato',
    );
    return '$_temp0';
  }

  @override
  String get albumMergeWith => 'Unisci con…';

  @override
  String get albumMergeTitle => 'Unisci album';

  @override
  String albumMergeIntro(String name) {
    return 'Scegli gli album da unire a «$name». I brani passano a un solo album con il titolo e l’artista che indichi; la copertina resta quella di «$name».';
  }

  @override
  String get albumMergeSearch => 'Cerca un album';

  @override
  String get albumMergeNone => 'Non ci sono altri album';

  @override
  String get albumFieldTitle => 'Titolo dell’album';

  @override
  String get albumFieldArtist => 'Artista dell’album';

  @override
  String get albumMergeAction => 'Unisci album';

  @override
  String albumMerged(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album uniti in «$name»',
      one: '1 album unito in «$name»',
    );
    return '$_temp0';
  }

  @override
  String get moveToAlbum => 'Sposta in un nuovo album…';

  @override
  String get moveToAlbumTitle => 'Sposta in un album';

  @override
  String moveToAlbumBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani andranno',
      one: '1 brano andrà',
    );
    return '$_temp0 nell’album indicato. Se esiste già, si uniranno ad esso.';
  }

  @override
  String get moveToAlbumGo => 'Sposta';

  @override
  String movedToAlbum(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani spostati in «$name»',
      one: '1 brano spostato in «$name»',
    );
    return '$_temp0';
  }

  @override
  String get searchSourceYoutube => 'YouTube';

  @override
  String get searchSourceYoutubeMusic => 'YouTube Music';

  @override
  String get searchSourceSoundcloud => 'SoundCloud';

  @override
  String get importSoundCloud =>
      'Cerca anche su SoundCloud se un brano non si trova';

  @override
  String get importSoundCloudHint =>
      'Solo per le righe di un’importazione che YouTube non trova: una ricerca in più per riga. Spento di serie.';

  @override
  String get ytHintSoundcloud => 'Cerca su SoundCloud';

  @override
  String get playlistSourceTitle => 'Playlist o canale YouTube';

  @override
  String get playlistSourceLoading => 'Leggo l’elenco dei video…';

  @override
  String get playlistSourceName => 'Nome della playlist';

  @override
  String playlistSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      one: '1 video',
    );
    return '$_temp0';
  }

  @override
  String playlistSourceUnavailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video non disponibili (privati o rimossi)',
      one: '1 video non disponibile (privato o rimosso)',
    );
    return '$_temp0';
  }

  @override
  String playlistSourceTruncated(int count) {
    return 'Mostro i primi $count video.';
  }

  @override
  String playlistSourceLong(int count, String time) {
    return 'Sono $count video: ci vorrà $time.';
  }

  @override
  String get playlistSourceNone => 'Nessuno';

  @override
  String get playlistSourceEmpty => 'Non ci sono video da scaricare qui.';

  @override
  String playlistSourceGo(int count) {
    return 'Scarica in una playlist ($count)';
  }

  @override
  String playlistSourceStarted(String name) {
    return 'Download avviati nella playlist «$name»';
  }

  @override
  String get podcastsTitle => 'Podcast';

  @override
  String podcastsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count podcast',
      one: '1 podcast',
    );
    return '$_temp0';
  }

  @override
  String get podcastsNotice => 'I podcast si aggiornano solo quando lo chiedi.';

  @override
  String get podcastsEmpty => 'Non sei iscritto a nessun podcast.';

  @override
  String get podcastAdd => 'Aggiungi podcast';

  @override
  String get podcastRefreshAll => 'Aggiorna tutti';

  @override
  String get podcastRefresh => 'Aggiorna';

  @override
  String podcastRefreshed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodi nuovi',
      one: '1 episodio nuovo',
      zero: 'Nessun episodio nuovo',
    );
    return '$_temp0';
  }

  @override
  String podcastRefreshFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count podcast non aggiornati',
      one: '1 podcast non aggiornato',
    );
    return '$_temp0';
  }

  @override
  String get podcastFeedUrl => 'URL del feed';

  @override
  String get podcastSubscribe => 'Iscriviti';

  @override
  String get podcastSearchHint => 'Cerca un podcast per nome';

  @override
  String get podcastSearchNone => 'Nessun podcast trovato';

  @override
  String podcastSubscribed(String name) {
    return 'Iscritto a «$name»';
  }

  @override
  String podcastEpisodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodi',
      one: '1 episodio',
    );
    return '$_temp0';
  }

  @override
  String podcastToListen(int count) {
    return '$count da ascoltare';
  }

  @override
  String get podcastNoEpisodes => 'Nessun episodio.';

  @override
  String get podcastStateDownloaded => 'Scaricato';

  @override
  String podcastStateDownloading(int percent) {
    return 'Scarico… $percent%';
  }

  @override
  String get podcastStateHeard => 'Ascoltato';

  @override
  String podcastStateRemaining(String time) {
    return 'Mancano $time';
  }

  @override
  String get podcastMarkHeard => 'Segna come ascoltato';

  @override
  String get podcastMarkNotHeard => 'Segna come da ascoltare';

  @override
  String get podcastDeleteFile => 'Elimina il file';

  @override
  String get podcastAutoDelete => 'Elimina gli episodi ascoltati';

  @override
  String get podcastAutoDeleteNever => 'Mai';

  @override
  String podcastAutoDeleteAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Dopo $days giorni',
      one: 'Dopo 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get podcastUnsubscribe => 'Annulla l’iscrizione';

  @override
  String get podcastUnsubscribeTitle => 'Annullare l’iscrizione?';

  @override
  String podcastUnsubscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodi scaricati',
      one: '1 episodio scaricato',
    );
    return 'Il podcast e $_temp0 verranno eliminati dal dispositivo.';
  }

  @override
  String podcastLastChecked(String when) {
    return 'Aggiornato $when';
  }

  @override
  String get podcastNeverChecked => 'Mai aggiornato';

  @override
  String get podcastErrInvalidUrl =>
      'Questo non sembra un indirizzo web valido.';

  @override
  String get podcastErrTooLarge => 'Il feed è troppo grande.';

  @override
  String get podcastErrNetwork => 'Non riesco a raggiungere il server.';

  @override
  String get podcastErrNotFeed => 'Questo indirizzo non è un feed di podcast.';

  @override
  String get podcastErrParserMissing =>
      'La lettura dei feed non è ancora disponibile in questa versione.';

  @override
  String get podcastErrUnsupportedFormat => 'Formato audio non supportato.';

  @override
  String get syncTitle => 'Sincronizza playlist';

  @override
  String syncAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuove',
      one: '1 nuova',
    );
    return '$_temp0';
  }

  @override
  String syncUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aggiornate',
      one: '1 aggiornata',
    );
    return '$_temp0';
  }

  @override
  String syncMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani mancanti',
      one: '1 brano mancante',
    );
    return '$_temp0';
  }

  @override
  String get syncUpToDate => 'Le playlist sono già allineate';

  @override
  String syncKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlist sono più recenti qui e restano come sono',
      one: '1 playlist è più recente qui e resta com’è',
    );
    return '$_temp0';
  }

  @override
  String get syncReplaceNote =>
      'Le playlist aggiornate sostituiscono quelle di questo dispositivo.';

  @override
  String get syncTagNew => 'Nuova';

  @override
  String get syncTagUpdated => 'Aggiornata';

  @override
  String get syncDetailRenamed => 'rinominata';

  @override
  String get syncDetailReordered => 'riordinata';

  @override
  String syncDetailRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani tolti',
      one: '1 brano tolto',
    );
    return '$_temp0';
  }

  @override
  String get syncAskMissing => 'Chiedi i brani mancanti';

  @override
  String syncApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlist sincronizzate',
      one: '1 playlist sincronizzata',
    );
    return '$_temp0';
  }

  @override
  String get trustedSection => 'Dispositivi fidati';

  @override
  String trustedFingerprint(String fingerprint) {
    return 'Impronta $fingerprint';
  }

  @override
  String trustedPairedOn(String date) {
    return 'Abbinato il $date';
  }

  @override
  String get trustedAutoAccept => 'Accetta automaticamente';

  @override
  String get trustedAutoAcceptHint =>
      'Ricevi i brani da questo dispositivo senza chiedere.';

  @override
  String get trustedRevoke => 'Revoca';

  @override
  String trustedRevokeTitle(String name) {
    return 'Revocare «$name»?';
  }

  @override
  String get trustedRevokeBody =>
      'Per inviare di nuovo senza PIN dovrete abbinarvi ancora.';

  @override
  String get carMode => 'Modalità in auto';

  @override
  String get carExit => 'Esci';

  @override
  String get carKeepAwake => 'Schermo sempre acceso';

  @override
  String get carPlaylists => 'Playlist';

  @override
  String get carNothing => 'Niente in riproduzione';

  @override
  String get updateCheck => 'Controlla aggiornamenti';

  @override
  String get updateCheckHint =>
      'Chiede a GitHub l’ultima versione, solo quando lo chiedi.';

  @override
  String get updateOnStart => 'Controlla all’avvio';

  @override
  String get updateOnStartHint =>
      'Al più una volta al giorno. Non scarica né installa niente.';

  @override
  String get updateChecking => 'Controllo in corso…';

  @override
  String updateAvailable(String version) {
    return 'Disponibile la versione $version';
  }

  @override
  String updateUpToDate(String version) {
    return 'Hai l’ultima versione ($version)';
  }

  @override
  String get updateRateLimited =>
      'GitHub chiede di aspettare: riprova più tardi.';

  @override
  String get updateFailed =>
      'Non riesco a leggere l’ultima versione. Controlla la connessione.';

  @override
  String get updateCopyLink => 'Copia indirizzo';

  @override
  String get updateLinkCopied => 'Indirizzo copiato';

  @override
  String get backupSection => 'Backup';

  @override
  String get backupCreate => 'Crea backup';

  @override
  String get backupCreateHint =>
      'Playlist, preferiti, testi e modifiche in un file zip. La musica non c’è.';

  @override
  String get backupRestore => 'Ripristina da backup';

  @override
  String get backupRestoreHint =>
      'Sostituisci questa libreria o unisci i dati di un altro dispositivo.';

  @override
  String get backupCreating => 'Creo il backup…';

  @override
  String get backupSaved => 'Backup salvato';

  @override
  String get backupFailed => 'Backup non riuscito';

  @override
  String get restoreTitle => 'Ripristina da backup';

  @override
  String restoreInfo(String date, String version, int tracks, int playlists) {
    return 'Del $date · app $version · $tracks brani · $playlists playlist';
  }

  @override
  String get restoreReplace => 'Sostituisci tutto (stesso dispositivo)';

  @override
  String get restoreMerge => 'Unisci a questa libreria';

  @override
  String get restoreMergeHint =>
      'Aggiunge preferiti, playlist, testi e modifiche ai brani che trova. Non cancella niente.';

  @override
  String get restoreReplaceConfirmTitle => 'Sostituire tutta la libreria?';

  @override
  String get restoreReplaceConfirmBody =>
      'Al prossimo avvio i dati di questa app diventano quelli del backup. Quelli attuali restano in una copia di sicurezza accanto al database.';

  @override
  String get restoreReplaceGo => 'Sostituisci';

  @override
  String get restoreNotBackup =>
      'Questo file non è un backup di Codecore che posso leggere.';

  @override
  String get restoreRestartNeeded =>
      'Pronto: chiudi l’app e riaprila per completare il ripristino.';

  @override
  String restoreMergeDone(
    int recognized,
    int missing,
    int playlists,
    int favorites,
  ) {
    return 'Unione fatta: $recognized brani riconosciuti, $missing non trovati, $playlists playlist create, $favorites preferiti aggiunti.';
  }

  @override
  String get restoreNotFound => 'Brani non trovati';

  @override
  String get restoreCopyList => 'Copia elenco';

  @override
  String get restoreFailed => 'Ripristino non riuscito';

  @override
  String get exportAllPlaylists => 'Esporta tutte le playlist';

  @override
  String get translateLyrics => 'Traduci';

  @override
  String get translateLyricsFrom => 'Lingua del testo';

  @override
  String get translateLyricsHint =>
      'Traduzione sul telefono, nessun testo viene inviato in rete.';

  @override
  String get translateRemove => 'Mostra solo l\'originale';

  @override
  String translateDownloadTitle(String language) {
    return 'Scaricare il modello $language?';
  }

  @override
  String translateDownloadBody(int mb) {
    return 'Servono circa $mb MB per ogni lingua, meglio con il Wi-Fi. Si scarica una volta sola e poi funziona anche offline.';
  }

  @override
  String get translateDownload => 'Scarica';

  @override
  String translateDownloading(String language) {
    return 'Scarico il modello $language…';
  }

  @override
  String get translateDownloadFailed =>
      'Modello non scaricato. Controlla la connessione e lo spazio.';

  @override
  String get translateFailed => 'Traduzione non riuscita.';

  @override
  String get translateSameLanguage => 'Il testo è già in questa lingua.';

  @override
  String get translationModels => 'Modelli di traduzione';

  @override
  String get translationModelsNone =>
      'Nessun modello scaricato. Si scaricano dalla schermata dei testi, con «Traduci».';

  @override
  String translationModelDelete(String language) {
    return 'Elimina il modello $language';
  }
}
