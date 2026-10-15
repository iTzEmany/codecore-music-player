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
      'Solo per uso personale. Rispetta i diritti d’autore e i termini di YouTube.';

  @override
  String get useDefaultFolder => 'Usa la cartella Musica del dispositivo';

  @override
  String get ytErrToolMissing =>
      'yt-dlp non trovato: installalo (pip install -U yt-dlp) e riprova';

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
}
