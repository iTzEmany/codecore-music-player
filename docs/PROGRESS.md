# Avanzamento

Legenda: `[ ]` da fare · `[~]` codice fatto e verde nei test, manca solo una prova a mano dell'utente · `[x]` fatto.
Spunta a fine task (dopo `flutter analyze` + `flutter test` verdi). Annota **una riga** se hai deviato dal piano.
L'agente riparte sempre dal primo task non spuntato.

## Fase 0 — Setup (`fase-0-setup.md`)
- [x] 0.1 Verifica toolchain
- [x] 0.2 Creare il progetto Flutter
- [x] 0.3 Dipendenze
- [x] 0.4 Scheletro cartelle e utilità (AppLog, platform, paths, text_utils + test)
- [x] 0.5 main.dart / app.dart
- [x] 0.6 Primo build Android
- [x] 0.7 .gitignore

## Fase 1 — Dati e scansione (`fase-1-dati-e-scansione.md`)
- [x] 1.1 Tabelle drift
- [x] 1.2 TagReader + implementazione
- [x] 1.3 Repository
- [x] 1.4 Scanner
- [x] 1.5 Copertine
- [x] 1.6 Provider
- [~] 1.7 Permessi Android e cartella predefinita
- [~] 1.8 Schermata di debug

## Fase 2 — Player (`fase-2-player.md`)
- [x] 2.1 PlayQueue (+ test)
- [x] 2.2 AudioBackend / JustAudioBackend
- [x] 2.3 CodecoreAudioHandler (+ test)
- [~] 2.4 Inizializzazione per piattaforma
- [x] 2.5 Provider di stato e controller
- [~] 2.6 Persistenza e checklist manuale

## Fase 3 — Interfaccia (`fase-3-interfaccia.md`)
- [x] 3.1 Tema
- [x] 3.2 Shell adattiva
- [x] 3.3 Widget riusabili
- [~] 3.4 Tab Brani
- [x] 3.5 Tab Album + dettaglio
- [x] 3.6 Tab Artisti
- [x] 3.7 Mini-player
- [x] 3.8 Now Playing + coda
- [~] 3.9 Scorciatoie da tastiera
- [x] 3.10 Rimozione schermata di debug

## Fase 4 — Funzioni libreria (`fase-4-funzioni-libreria.md`)
- [x] 4.1 Preferiti
- [x] 4.2 Playlist
- [x] 4.3 Menu azioni brano
- [x] 4.4 Modifica info brano
- [x] 4.5 Impostazioni
- [x] 4.6 Localizzazione it/en/de/es
- [x] 4.7 Brani mancanti e stati di errore
- [x] 4.8 Ripresa riproduzione

## Fase 5 — Online (`fase-5-online.md`)
- [x] 5.1 HTTP di base
- [x] 5.2 QueryCleaner (+ test)
- [x] 5.3 Client iTunes (+ test)
- [x] 5.4 Client LRCLIB + parser LRC (+ test)
- [x] 5.5 Client Wikipedia
- [x] 5.6 EnrichmentService (+ test)
- [x] 5.7 UI arricchimento
- [x] 5.8 Schermata testi
- [~] 5.9 YoutubeService
- [~] 5.10 Coda di download
- [~] 5.11 Schermata YouTube

## Fase 6 — Condivisione LAN, opzionale (`fase-6-condivisione-lan.md`)
- [x] 6.1 Server
- [x] 6.2 Client
- [~] 6.3 UI
- [x] 6.4 Integrazione

## Fase 7 — Rifinitura (`fase-7-rifinitura.md`)
- [x] 7.1 Import dal vecchio DB Python
- [ ] 7.2 Gapless
- [x] 7.3 ReplayGain
- [~] 7.4 Controlli multimediali desktop
- [~] 7.5 Prestazioni
- [x] 7.6 Accessibilità
- [~] 7.7 Timer di spegnimento
- [x] 7.8 Icona e nome app
- [~] 7.9 Build di rilascio
- [x] 7.10 Documentazione finale

## Fase 8 — Jam sulla rete locale (`fase-8-jam.md`)
- [x] 8.1 Modello e logica pura (JamItem, JamState, comandi, permessi)
- [x] 8.2 Sessione lato host (richiesta, accettazione, stato, long polling)
- [x] 8.3 Client ospite
- [x] 8.4 Riproduzione di elementi remoti (URL + token)
- [x] 8.5 Uscita audio selezionabile e controllo remoto
- [x] 8.6 Precarico e resilienza (cache temporanea)
- [x] 8.7 Interfaccia (pulsante Jam, coda condivisa, uscita, termina)
- [~] 8.8 Background Android e rifinitura
- [x] 8.9 Documentazione

## Fase 9 — Jam con più di 2 dispositivi (`fase-9-jam-multi.md`)
- [x] 9.1 Modello (partecipanti in `JamState`)
- [x] 9.2 Host a N partecipanti (token per membro, invito, uscita, tetto)
- [x] 9.3 Client (credenziali, invito da ospite, `base`)
- [x] 9.4 Controller (URL proprietario da elenco, accettazione da ospite, scarto)
- [x] 9.5 Interfaccia (partecipanti, uscita a più voci)
- [x] 9.6 Prova su dispositivi reali
- [x] 9.7 Documentazione

## Fase 10 — Riproduzione sincronizzata (`fase-10-jam-sincronia.md`)
- [x] 10.1 Orologio condiviso (`JamClock`, rotta `/time`)
- [x] 10.2 Modello a più uscite (`outputDeviceIds`, `ready`)
- [x] 10.3 Controller di sincronia puro
- [x] 10.4 Backend: velocità e posizione precisa
- [x] 10.5 Precarico obbligatorio e handshake `ready`
- [x] 10.6 `JamOutput` multi-uscita
- [x] 10.7 Interfaccia (uscite multiple, stato di sincronia, latenza)
- [x] 10.8 Simulazione con orologi sfalsati
- [x] 10.9 Prova reale e misura (misura acustica ripetuta con il controllore proporzionale: vedi nota)
- [x] 10.10 Documentazione

## Fase 11 — Interfaccia nuova (`fase-11-interfaccia-nuova.md`)
- [x] 11.1 Banco visivo (scatti da test)
- [x] 11.2 Token, tema e font
- [x] 11.3 Componenti base
- [x] 11.4 Correzioni rapide
- [x] 11.5 Shell: tre schede e navigatore annidato
- [x] 11.6 Colore dalla copertina
- [x] 11.7 Mini-player e foglio Dispositivi
- [x] 11.8 Now Playing
- [x] 11.9 Desktop: barra laterale, barra player, pannello destro
- [x] 11.10 Libreria e «Tutti i brani»
- [x] 11.11 Pagine di raccolta: album, artista, playlist, Preferiti
- [x] 11.12 Home
- [x] 11.13 Cerca (con YouTube)
- [x] 11.14 Coda, Testi, menu del brano
- [x] 11.15 Jam
- [x] 11.16 Centro Attività
- [x] 11.17 Impostazioni, Condivisione, dialoghi
- [x] 11.18 Rifinitura e controlli finali
- [ ] 11.19 Prova a mano (utente)

## Fase 12 — Import playlist da CSV (`fase-12-import-csv.md`)
- [x] 12.1 Verifiche preliminari (YouTube Music con yt-dlp, CSV vero di Exportify)
- [x] 12.2 Parser CSV Exportify (+ test)
- [x] 12.3 Abbinamento e punteggio (+ test)
- [x] 12.4 Ricerca su YouTube Music nel `YoutubeService`
- [x] 12.5 Tabelle dell'importazione (schema v4)
- [x] 12.6 Posizione nella playlist secondo il CSV
- [x] 12.7 Coda di download con tag
- [x] 12.8 `PlaylistImportService`
- [x] 12.9 Pulsante «Importa da Exportify» e anteprima
- [x] 12.10 Avanzamento, «Da verificare» e «Non trovati»
- [x] 12.11 Rifinitura e prova a mano

## Fase 13 — Backup, ripristino ed export (`fase-13-backup-export.md`)
- [ ] 13.1 Verifiche preliminari (pacchetto archive, percorso DB, VACUUM INTO, saveFile su Android) (BLOCCATO: pacchetto `archive` da approvare)
- [x] 13.2 Formato portabile user_data.json (+ test)
- [x] 13.3 Estrazione dei dati utente dal DB (+ test)
- [x] 13.4 Riconoscere i brani al ripristino (+ test)
- [ ] 13.5 Creare il backup (+ test) (BLOCCATO: pacchetto `archive` da approvare)
- [ ] 13.6 Ripristino sullo stesso dispositivo (sostituzione al riavvio) (BLOCCATO: pacchetto `archive` da approvare)
- [ ] 13.7 Ripristino su un altro dispositivo (unione) (BLOCCATO: pacchetto `archive` da approvare)
- [ ] 13.8 Sezione «Backup» nelle Impostazioni (BLOCCATO: pacchetto `archive` da approvare)
- [x] 13.9 Esportazione delle playlist: M3U8, CSV, JSON (+ test)
- [ ] 13.10 Interfaccia di esportazione (parziale: «Esporta…» di una playlist fatto; «Esporta tutte» in zip BLOCCATO: pacchetto `archive` da approvare)
- [x] 13.11 «Esporta log» senza dati personali
- [ ] 13.12 Rifinitura, documentazione e prova a mano (in attesa dei task bloccati)

## Fase 14 — Download robusti (`fase-14-download-robusti.md`)
- [~] 14.1 Verifiche preliminari (release yt-dlp, --limit-rate, ISRC, formato originale, versione Android)
- [x] 14.2 Versione di yt-dlp e avviso «troppo vecchio»
- [x] 14.3 Aggiornamento di yt-dlp in-app (desktop)
- [x] 14.4 Download in parallelo
- [ ] 14.5 Limite di banda
- [ ] 14.6 Ritento a scalare
- [ ] 14.7 Formato: MP3 o originale senza ricodifica
- [ ] 14.8 Ricerca per ISRC come primo tentativo
- [ ] 14.9 Cache delle ricerche
- [ ] 14.10 Controllo della durata a fine download
- [ ] 14.11 Validazioni: CSV troppo grandi e ricerche bloccate
- [ ] 14.12 (Opzionale) Impronta audio con Chromaprint — chiedere all'utente
- [ ] 14.13 Rifinitura, documentazione e prova a mano

## Fase 15 — Importazione 2 (`fase-15-importazione-2.md`)
- [ ] 15.1 Verifiche preliminari (file veri dei formati, album su YouTube Music, iTunes per ISRC)
- [ ] 15.2 Schema v5 per le importazioni
- [ ] 15.3 Interfaccia comune dei lettori
- [ ] 15.4 Lettori CSV: TuneMyMusic, Soundiiz, Last.fm, generico
- [ ] 15.5 Lettori M3U/M3U8 e XSPF
- [ ] 15.6 Anteprima degli abbinamenti e «solo collega»
- [ ] 15.7 Soglie regolabili e CSV grandi
- [ ] 15.8 Contatore e tempo residuo
- [ ] 15.9 Cartella dedicata e file numerati
- [ ] 15.10 Copertine dal CSV ed esito esportabile
- [ ] 15.11 Sincronizza da CSV
- [ ] 15.12 Importazione per album intero
- [ ] 15.13 Rifinitura, documentazione e prova a mano

## Fase 16 — CI e test automatici (`fase-16-ci-test.md`)
- [ ] 16.1 Verifiche preliminari (versione Flutter, test senza rete, pacchetti apt, remote GitHub)
- [ ] 16.2 Workflow `ci.yml`: analyze e test
- [ ] 16.3 Build Android e Linux con artefatti
- [ ] 16.4 Build Windows (`windows-latest`)
- [ ] 16.5 Test d'integrazione sul telefono: base (scansione)
- [ ] 16.6 Test d'integrazione: riproduzione, playlist, importazione
- [ ] 16.7 Golden test delle schermate principali (100 % e 150 %)
- [ ] 16.8 Test live notturni e controllo delle dipendenze
- [ ] 16.9 Profilo prestazioni su 50.000 brani
- [ ] 16.10 Rifinitura, documentazione e prova a mano

## Fase 17 — Riproduzione e controlli di sistema (`fase-17-riproduzione.md`)
- [ ] 17.1 Verifiche preliminari (tono con la velocità, equalizzatore, MPRIS/SMTC, Jam e audio_service)
- [ ] 17.2 Velocità di riproduzione
- [ ] 17.3 Segnalibro «riprendi da qui» (schema v6)
- [ ] 17.4 Anteprima di 20 secondi
- [ ] 17.5 Equalizzatore: motore
- [ ] 17.6 Equalizzatore: interfaccia e profilo per uscita
- [ ] 17.7 MPRIS su Linux
- [ ] 17.8 SMTC su Windows
- [ ] 17.9 Controlli della Jam nella notifica e nella schermata di blocco
- [ ] 17.10 Rifinitura, documentazione e prova a mano

## Fase 18 — Gapless e crossfade (`fase-18-gapless-crossfade.md`)
- [ ] 18.1 Verifiche preliminari (API playlist just_audio/mpv, file di prova, prototipo e misura)
- [ ] 18.2 `PlayQueue.peekNext()` e `revision` (+ test)
- [ ] 18.3 Backend con finestra di due brani (`GaplessCapable`)
- [ ] 18.4 Handler in modalità gapless
- [ ] 18.5 Motore crossfade (+ test)
- [ ] 18.6 Handler in modalità crossfade
- [ ] 18.7 Impostazioni e interfaccia
- [ ] 18.8 Non regressione della Jam e del lettore normale
- [ ] 18.9 Misura del gap e del crossfade
- [ ] 18.10 Rifinitura, documentazione e prova a mano

## Fase 19 — Interfaccia: selezione, temi, tablet, lingue, onboarding (`fase-19-interfaccia.md`)
- [ ] 19.1 `SelectionController` (logica pura + test)
- [ ] 19.2 `TrackRow` selezionabile
- [ ] 19.3 Barra azioni e azioni di massa
- [ ] 19.4 Collegare le liste
- [ ] 19.5 Trascinare brani sulle playlist (desktop)
- [ ] 19.6 Tema chiaro e colore d'accento
- [ ] 19.7 Layout ≥ 1200 px
- [ ] 19.8 Lingue francese e portoghese
- [ ] 19.9 Onboarding al primo avvio
- [ ] 19.10 Rifinitura, documentazione e prova a mano

## Fase 20 — Libreria intelligente (`fase-20-libreria-intelligente.md`)
- [ ] 20.1 Tabelle (schema v7)
- [ ] 20.2 Registrare gli ascolti
- [ ] 20.3 Cronologia
- [ ] 20.4 Statistiche e recap
- [ ] 20.5 Linguaggio delle regole: parser e AST
- [ ] 20.6 Dalle regole all'SQL
- [ ] 20.7 Ricerca con operatori
- [ ] 20.8 Playlist intelligenti
- [ ] 20.9 Etichette utente
- [ ] 20.10 Rifinitura, documentazione e prova a mano

## Fase 21 — Pulizia libreria e tag nei file (`fase-21-pulizia-tag.md`)
- [ ] 21.1 Verifiche preliminari (pacchetto per scrivere i tag)
- [ ] 21.2 Colonna `ignored` (schema v8) e viste
- [ ] 21.3 Ricerca dei duplicati
- [ ] 21.4 Fusione dei dati utente
- [ ] 21.5 Schermata «Duplicati»
- [ ] 21.6 Unire e dividere album a mano
- [ ] 21.7 `TagWriter` (interfaccia e implementazione)
- [ ] 21.8 Opzione «Scrivi le modifiche nei file»
- [ ] 21.9 Regole e documenti aggiornati
- [ ] 21.10 Rifinitura, documentazione e prova a mano

## Fase 22 — Nuove fonti (`fase-22-nuove-fonti.md`)
- [ ] 22.1 Verifiche preliminari (SoundCloud, playlist/canali, ML Kit)
- [ ] 22.2 Fonte nel modello e nel download
- [ ] 22.3 Ricerca SoundCloud e filtro anteprime
- [ ] 22.4 Punteggio per fonte
- [ ] 22.5 Selettore di fonte in Cerca e ripiego nell'importazione
- [ ] 22.6 Playlist e canali YouTube come sorgente
- [ ] 22.7 Traduzione dei testi on-device (solo Android)
- [ ] 22.8 Rifinitura, documentazione e prova a mano

## Fase 23 — Podcast (`fase-23-podcast.md`)
- [ ] 23.1 Verifiche preliminari (feed veri, ricerca iTunes podcast, API del pacchetto `xml`)
- [ ] 23.2 Parser RSS (+ test)
- [ ] 23.3 Schema v9: `tracks.kind`, `podcasts`, `podcast_episodes`
- [ ] 23.4 Escludere gli episodi dalle viste musicali
- [ ] 23.5 `PodcastRepository` e `PodcastService`
- [ ] 23.6 Download degli episodi
- [ ] 23.7 Ascoltato, posizione e pulizia
- [ ] 23.8 Interfaccia: sezione Podcast
- [ ] 23.9 Rifinitura, documentazione e prova a mano

## Fase 24 — Dispositivi fidati e sync (`fase-24-dispositivi-fidati.md`)
- [ ] 24.1 Verifiche preliminari (certificati, bindSecure, ExoPlayer/mpv su HTTPS, mobile_scanner)
- [ ] 24.2 Identità del dispositivo
- [ ] 24.3 Elenco dei dispositivi fidati
- [ ] 24.4 HTTPS su `OfferNode` (Jam esclusa)
- [ ] 24.5 Abbinamento con PIN
- [ ] 24.6 Offerte dai fidati
- [ ] 24.7 Scanner QR (Android)
- [ ] 24.8 Schema v10: playlist con `uuid` e `updated_at`
- [ ] 24.9 Sincronizzazione delle playlist
- [ ] 24.10 Rifinitura, documentazione e prova a mano

## Fase 25 — Android esteso (`fase-25-android-esteso.md`)
- [ ] 25.1 Verifiche preliminari (audio_service browsing, tasto multimediale a freddo, DHU, home_widget)
- [ ] 25.2 Ponte dati verso il widget (lato Dart)
- [ ] 25.3 Widget Android (lato Kotlin)
- [ ] 25.4 Tile rapida
- [ ] 25.5 Albero di navigazione (`MediaBrowseTree`, + test)
- [ ] 25.6 Android Auto
- [ ] 25.7 Wear OS (verifica)
- [ ] 25.8 Modalità in auto nell'app
- [ ] 25.9 Rifinitura, documentazione e prova a mano

## Fase 26 — Distribuzione (`fase-26-distribuzione.md`)
- [ ] 26.1 Verifiche preliminari (strumenti di packaging, licenza ffmpeg, dimensioni attuali)
- [ ] 26.2 AppImage e .deb
- [ ] 26.3 Flatpak
- [ ] 26.4 Installer Windows (Inno Setup)
- [ ] 26.5 APK più leggero e flavor `lite`
- [ ] 26.6 Avviso di aggiornamento
- [ ] 26.7 Valutazione F-Droid
- [ ] 26.8 Build di prova macOS / iOS
- [ ] 26.9 Guida utente
- [ ] 26.10 Rifinitura, documentazione e prova a mano

## Note di deviazione
<!-- una riga per deviazione: data — task — cosa è cambiato e perché -->

## Note di deviazione
- 11.5 (2026-10-15): `flutter run` non accetta `--build-number`; per il Mi A3 (versionCode 5000) si usa `flutter build apk --debug --build-number=5000 --target-platform android-arm64` + `adb install -r`. Provato su telefono: avvio debug ~17 s. Nel segnaposto Home restano anche Playlist e YouTube (rifatti in 11.12/11.13). `TracksTab(primarySearch)`: solo la scheda Cerca usa il FocusNode condiviso.
- 11.7 (2026-10-15): swipe a sinistra sul mini-player è ignorato (torna al posto) se non c'è un brano successivo (`PlayQueue.hasNext`), altrimenti il player andrebbe in idle e la card sparirebbe. Provato su Mi A3: foglio Dispositivi (stato «rendi visibile»), swipe corto/lungo, swipe su → Now Playing. Modalità Jam e swipe orizzontale con Jam: non provati su telefono (nessuna Jam avviata, per regola §6.1).
- 11.8 (2026-10-15): «Info sul brano» cerca la curiosità solo con un tocco (card Now Playing); la schermata Testi continua a cercarla in automatico fino a 11.14. Tocco sull'artista: `ArtistSummary` con soli key/name (la pagina artista non usa i conteggi). Provato su Mi A3: Hero/drag-down, link artista → Libreria con mini-player, card Testo/Info/Prossimi. Desktop (≥900, due colonne) coperto solo da test, non da scatti.
- 11.9 (2026-10-15): verificato con test a 1280 px e scatto da test (`desktop_shell_playing`); l'app desktop non è stata avviata (regola «niente finestre desktop»). Il pannello destro mostra Coda/Testo (LyricsScreen `embedded`)/Info; il bottone «Info» nella barra non c'è (il pannello Info si apre da 11.14).
- 11.10 (2026-10-15): chip filtro per tipo (Playlist/Album/Artisti) e chip ordinamento + interruttore griglia in `AppSettings` (`librarySort`, `libraryGrid`). «Tutti i brani» condivide `trackQueryProvider(false)` con la scheda Cerca (si azzera all'apertura). AlbumsTab/ArtistsTab non sono più usate dalla Libreria (ArtistDetailScreen resta in artists_tab.dart fino a 11.11). Provato su Mi A3 (1110_lib.png).
- 11.11 (2026-10-16): `CollectionScaffold` unico per album/artista/playlist/Preferiti; `ArtistDetailScreen` spostata in `artist_screen.dart` (rimossi albums_tab/artists_tab). Provato su Mi A3 (artista e album, 1111_*.png); playlist e Preferiti coperti da widget test (modifica ordine con maniglie, stato vuoto), non provati a mano sul telefono (non modifico le playlist vere). Foglio «Aggiungi a playlist» con ✓ coperto solo da compilazione/test esistenti.
- 11.12 (2026-10-16): le sezioni Home sono calcolate in Dart da albums/playlist (`home_sections.dart`, testate) + query `watchTopTracks`; «Da riscoprire» = ≥3 ascolti e fermo da 60 giorni. L'indicatore Attività arriva con 11.16. Il collegamento «YouTube» resta temporaneamente in Home fino a 11.13. Provato su Mi A3 (1112_home.png).
- 11.13 (2026-10-16): la ricerca libreria è calcolata in memoria su artisti/album/playlist (`library_search.dart`, testata) + SQL per i brani. «Mostra tutti» apre `SearchTracksScreen`. Ricerche recenti e avviso YouTube visto in `AppSettings`. Il chip «Download (N)» apre `DownloadsSheet` (sostituita da 11.16). Rimossi `youtube_screen.dart` e `tracks_tab.dart`. Ricerca YouTube dal vivo non provata (rete); provati Generi, ricerca libreria, chip YouTube senza ricerca automatica su Mi A3 (1113_*.png).
- 11.14 (2026-10-16): `track_actions_sheet.dart` → `track_actions.dart` (modello `TrackActionGroup`, foglio + menu al puntatore). La Coda mostra «In riproduzione» + «Prossimi» in ordine naturale della coda (con casuale attivo l'ordine di ascolto può differire). La schermata Testi non cerca più le curiosità da sola (ora solo con tocco in Now Playing). Provato su Mi A3: coda, menu → Vai all'album (1114_*.png); testo sincronizzato dal vivo coperto solo dai test (nessun brano con testo a disposizione), riordino/rimozione coda non provati a mano.
- 11.15 (2026-10-16): Jam rifatta (header con avatar, `JamPlayerCard`, `JamOutputsSheet`; ✕ solo dove consentito, quindi il messaggio «non puoi rimuovere» non compare più). Non avviata sul telefono (regola: niente Jam verso altri dispositivi): verificata con widget test e scatto da test (phone_jam.png). L'attesa mostra avatar pulsanti.
- 11.16 (2026-10-16): `activityProvider` aggrega scansione, arricchimento, download e invii (`buildActivity` pura, testata); «Pulisci» nasconde i completati con un insieme di chiavi in memoria. `EnrichJobBanner` → `EnrichResultListener` (solo snackbar a fine lavoro); la barra di scansione è sparita dalle liste (resta il banner d'errore); il chip «Download (N)» di Cerca è sostituito dal bottone Attività. Provato solo con widget test (il telefono non ha attività in corso da mostrare senza avviare scansioni/download).
- 11.17 (2026-10-16): Impostazioni a gruppi (`_Group`), lingua in un dialogo, Condivisione con `PeerCard` e riquadro firewall, anteprima arricchimento a due colonne, modifica info a pagina intera <600 px con Anno/N° traccia affiancati, brani non trovati con ⋮ e «Rimuovi tutti» (conferma). Provato su Mi A3 solo la pagina Impostazioni (1117_*.png); gli altri dialoghi sono coperti dai test esistenti (nessuna modifica dei dati dell'utente).
- 11.18 (2026-10-16): swipe a destra = «Aggiungi in coda» su ogni riga standard/album (non coda e non pick); barra A–Z solo con ordinamento per titolo/artista (`AlphaScroller`); transizioni di pagina uniformi (`CcPageTransitionsBuilder`, nessuna con «Animazioni ridotte»); 150% di testo nei test di tutte le schermate nuove; `flutter build linux` e `flutter build apk --debug` riusciti. Il focus da tastiera si affida a `focusColor` del tema (nessun anello dedicato per chip/righe). Provato su Mi A3: Tutti i brani con A–Z e swipe (1118_*.png).
- Post-11.18 (2026-10-16), richiesta dell'utente: `ShuffleButton` legge `shuffleProvider` e si colora (ametista + puntino) in ogni pagina (album, artista, Tutti i brani, generi), non solo in Now Playing. Provato su Mi A3.
- Post-11.18 (2026-10-16), richieste dell'utente: (1) all'accettazione di una Jam la coda dell'host (da brano corrente in poi, poi i precedenti) diventa la coda iniziale; se suonava, la Jam riparte dallo stesso punto (`jamSeedTracks`, testata). (2) Elemento trascinato (coda, Jam, riordino playlist) con sfondo ametista (`ccDragProxy`). (3) Prova su PC reale (Linux in Xephyr, HOME isolato) + Mi A3: Jam avviata dal telefono, accettata sul PC, coda e riordino sincronizzati, termina dal PC. Corretti: doppia animazione «in riproduzione» nelle righe larghe, colonne delle righe larghe non allineate (heart/durata/⋯ a larghezze fisse), riga troppo larga nel pannello coda (layout per larghezza reale), titolo «Coda» doppio nel pannello, menu clic destro posizionato male (coordinate dell'overlay), ✕ e maniglia sovrapposti nella coda Jam, Play non centrato con «successivo», Jam/Impostazioni/Now Playing troppo larghi su desktop (max 720/760/560 centrati), scheda dispositivo con nome troncato (pulsanti sotto), dialoghi max 480.
- 11.1 (2026-10-15): su richiesta dell'utente la verifica visiva dei task 11.x si fa **sul telefono** (hot reload); gli scatti da test (`scripts/shots.sh`) restano per testo/layout ma le copertine non si caricano nei golden (I/O reale in fake async) e ogni scatto costa ~1 min. Font di ripiego: Liberation Sans al posto di Roboto finché non ci sono i font dell'app.
- 0.3: `generate: true` (l10n) rimandato alla fase 4 (senza ARB `flutter gen-l10n` fallirebbe). `flutter_localizations` già aggiunto.
- 0.2: MainActivity spostata nel package `com.codecore.player`; `compileSdk = 37` (richiesto da permission_handler_android).
- 1.2: test con fixture mp3/flac generate con ffmpeg in `test/fixtures/`.
- 4.5: versione app in `lib/core/app_info.dart` (nessun package_info_plus, non previsto). Cartelle musicali nel DB (tabella folders), non in shared_preferences.
- 4.6: messaggi di errore del player passano da `PlaybackFailure` (enum) e sono localizzati in UI. Nomi lingua (Italiano/English/…) restano nativi.
- 4.3/4.4: prova a mano delle azioni (menu ⋯ brano, modifica info) su telefono/desktop.
- 5.3: con artista ignoto un titolo di una sola parola (es. "Intro") non viene mai accettato; si ferma alla prima query che dà un risultato *accettato*.
- 5.9: contenitore webm salvato come `.webm` (aggiunto agli estensioni scansionate); mp4 → `.m4a`.
- 5.9–5.11: la rete YouTube non è testabile in automatico: verificare a mano (Tocca a te).
- Verifica su telefono (Mi A3, Android 11, 2026-10-14): APK debug installato; scansione di /sdcard/Music (mp3+flac) ok, riproduzione e avanzamento automatico ok, sessione media attiva (notifica). Non provati a mano: tasti cuffie, schermo spento 5 min, YouTube/arricchimento (rete; l'orologio del telefono è al 2022 → errori SSL).
- Etichette NavigationBar: solo la voce selezionata (5 voci su schermo stretto).
- 5.x: provato su telefono (2026-10-14): iTunes/LRCLIB/Wikipedia ok, anteprima e applicazione di album+copertina ok. Corretti: JSON `text/javascript` di iTunes (decodeJsonBody), sorgenti in parallelo con timeout, anno 0 → null.
- 5.9–5.11 (prova su telefono 2026-10-14): ricerca YouTube e coda OK; il download resta a 0 byte (youtube_explode_dart 3.1.0: client predefinito accetta la richiesta ma non invia dati; ios → 403; androidVr/tv → "unplayable"; safari richiede Deno, non disponibile su Android). Applicato timeout di 30 s → errore invece di coda bloccata. Piano B (R5): `kEnableYoutube=false` o yt-dlp esterno.
- 5.9 (revisione 2026-10-14): `youtube_explode_dart` rimosso (da fine 2025 YouTube richiede una sfida JavaScript per gli URL dei flussi; la libreria non la risolve → 0 byte). Desktop: `yt-dlp` come processo esterno (+ node/deno/quickjs se presenti, + ffmpeg per MP3 256k). Verificato dal vivo su Linux: ricerca e download OK. Senza runtime JS yt-dlp dà 403 (provato).
- 5.9 Android (2026-10-14): yt-dlp incorporato con `io.github.junkfood02.youtubedl-android:library+ffmpeg:0.18.1` (Python 3.12, yt-dlp, yt-dlp-ejs, QuickJS 2025-04-26, ffmpeg), richiamato da `MainActivity.kt` via MethodChannel `codecore/ytdlp` (`AndroidYtDlpService`). Nessun backend. Provato sul Mi A3: ricerca + download MP3 256k OK. Prima esecuzione ~2 min (estrazione + aggiornamento yt-dlp). Licenza libreria GPL-3.0 (uso personale). APK debug ~250 MB (solo arm64-v8a/armeabi-v7a).
- 5.8 (2026-10-14): schermata testi: «Cerca testo» salva subito (nessuna conferma) e le curiosità Wikipedia vengono cercate e salvate in automatico una volta per brano all'apertura. Provato su telefono.
- Correzioni 2026-10-14: (1) crash «schermo rosso» al cambio dimensione testo: `TextTheme.apply(fontSizeFactor)` asserisce; ora scala via `MediaQuery.textScaler` (test su 0.9 e 1.15). (2) Snackbar preferiti: `persist:false` + 3 s (con un'azione restava finché non chiusa). (3) Playlist: copertina personalizzabile (schema DB v2, colonna `playlists.cover_key`, migrazione testata) e pulsante «+» per aggiungere brani salvati. (4) «Cerca info sul web»: artista/album/anno/genere/copertina preselezionati; il titolo solo se è lo stesso senza rumore. (5) `.part` orfani rimossi all'avvio dei download; etichetta nav su una riga; build release arm64 ~65 MB.
- Fase 6 (2026-10-14): server/client LAN in Dart (shelf, PIN a 6 cifre, blocco 60 s dopo 5 errori, Range con 416, id interi, stop all'uscita e dopo 10 min). Provato sul Mi A3 via adb: /hello, 401 senza PIN, manifest, Range 206, 416, id con path → 404, blocco 429 dopo 5 errori, server fermo all'uscita dalla schermata. Non implementato: scanner QR (mobile_scanner, opzionale nel piano; il QR si mostra e il link con `?pin=` si può incollare). Da provare con due dispositivi: ricezione tramite l'app (telefono ↔ PC), annullamento a metà.
- Test desktop Linux + due dispositivi (2026-10-14): app compilata (`flutter build linux`) e avviata sul PC (libmpv2 estratto da .deb in una cartella locale, senza sudo; `LD_LIBRARY_PATH`). Provati con screenshot e click: scansione, riproduzione (libmpv), scorciatoie (Spazio, Ctrl+→), Now Playing con volume, impostazioni (tema/lingua a caldo), YouTube con yt-dlp (ricerca + download MP3 + scansione automatica), «Cerca info sul web» (artista/album/copertina applicati), condivisione PC→telefono (via `adb reverse`): 7 brani ricevuti identici. Bug trovati e corretti: `coverStoreProvider` leggeva un provider ancora in caricamento (download→scansione falliva), area di tocco del mini-player (ora `opaque`).
- Annullamento download su Linux (2026-10-14, schermo HDMI secondo): provato due volte (a ~0,8 s e a ~2,5 s, durante download+conversione): stato «Annullato», nessun .mp3/.webm/.part rimasto, nessun processo yt-dlp/ffmpeg attivo.
- Fase 7 (2026-10-14): 7.1 import vecchio DB (test con 3 casi) · 7.3 ReplayGain (colonna `replay_gain_db`, schema v3 con migrazione testata, opzione «Normalizza volume», lettura FLAC/OGG e ID3 TXXX) · 7.5 20.000 brani: ricerca ~40 ms, lista completa ~0,6 s (JIT), albums/artisti <60 ms; frame time da misurare con `flutter run --profile` · 7.6 tooltip, 150% testo senza overflow, contrasto AA nei 4 temi · 7.7 timer 15/30/45/60 min o fine brano con fade 5 s · 7.8 icona + nome «Codecore» (Android, Windows, Linux) · 7.9 Android: APK release firmati con keystore personale (`android/codecore-release.jks`, ignorato da git: **fare un backup**) arm64 65 MB; Linux: `scripts/package-linux.sh` → `build/codecore-linux-x64.zip` (43 MB); Windows non compilabile da Linux · 7.10 README. NON fatti: 7.2 gapless (richiede riscrivere la coda sul backend nativo; rischio alto, non richiesto), 7.4 MPRIS/SMTC (solo tasti multimediali a finestra attiva). Versione 1.1.0+2.
- Attenzione firma: gli APK release usano ora una chiave diversa da quella di debug; sul telefono con l'app firmata in debug serve disinstallare prima (si perdono i dati dell'app).
- 2026-10-15: disco USB montato in sola lettura (NTFS sporco dopo la rimozione); lavoro proseguito in ~/codecore_work (stesso repo git, codice integro, ultimo commit 1a44e23). Verifica su telefono: schema v3 applicato, dati intatti (13 brani, playlist «formaggio», integrity_check ok). APK debug con --build-number 5000 per evitare INSTALL_FAILED_VERSION_DOWNGRADE.
- Condivisione LAN v2 (2026-10-15): scoperta automatica (beacon UDP broadcast con codice `CODECORE/1`, solo da indirizzi privati) + offerta/accettazione: `POST /offer/` con soli metadati → pending (scadenza 10 min) → Accetta/Rifiuta → il ricevente scarica dal mittente con token monouso valido solo dopo l'accettazione. Il mittente può lasciare la schermata: l'hub (`share_hub.dart`) tiene vivo endpoint e discovery finché ci sono offerte aperte. Impostazione «Ricevi dalla rete locale» (default off). Collegamento manuale con PIN invariato. Validazione rigida (estensioni audio, ≤500 brani, rate limit, nomi sanificati, indirizzo osservato). Limiti: solo con app aperta, HTTP in chiaro, nessun abbinamento/firma (tappa 2).
- Scoperta + offerta/accettazione: provata il 2026-10-15 con due istanze dell'app sul PC (HOME separate, schermo HDMI): l'istanza A trova B nell'elenco «Dispositivi vicini», invia → su B compare il dialogo «vuole inviarti dei brani» → il mittente può uscire dalla schermata → Accetta → il file arriva in `Ricevuti` e compare nella libreria di B. Corretto: senza cartelle in libreria la destinazione è la cartella Musica di sistema (anche per i download YouTube). Da provare: PC ↔ telefono sulla stessa Wi‑Fi (il telefono non era sulla rete del PC); nomi uguali (hostname) rendono i dispositivi indistinguibili → da rinominare in Impostazioni.
- Test Android ricezione (Mi A3 ↔ PC, stessa Wi‑Fi, 2026-10-15): app in primo piano → dialogo di accettazione OK; app in background (HOME, >1 min) e schermo spento (~100 s, in carica) → il processo resta vivo, il telefono resta visibile e l'offerta arriva (log), ma l'utente non vede nulla finché non riapre l'app (nessuna notifica di sistema); app chiusa (force-stop/swipe) → sparisce dall'elenco in ~7 s e le offerte non arrivano. Per ricevere a lungo in background servono servizio in primo piano + notifica (non implementati).
- Ricezione in background su Android (2026-10-15): `ReceiveService` (servizio in primo piano `specialUse`, notifica fissa «Codecore è visibile sulla rete» con pulsante «Disattiva»), notifiche di richiesta con Accetta/Rifiuta (canale ad alta priorità), stato primo piano letto dall'activity (`ShareBridge.foreground`). L'impostazione «Ricevi dalla rete locale» governa servizio, endpoint e scoperta; si può spegnere anche dalla notifica. Verificato sul Mi A3: servizio attivo con notifica (id 4101) e telefono visibile dal PC a schermo bloccato; la notifica di richiesta e i pulsanti sono da provare con telefono sbloccato (il blocco schermo sicuro impedisce di avviare l'app da adb). `reusePort` non più richiesto su Android (errore Dart).
- Notifiche di richiesta su Android (2026-10-15, Mi A3): la notifica viene creata (log `notify offer`, `isForeground=false` con app in background) ma sul telefono di test viene subito cancellata da un'altra app con accesso alle notifiche (`com.cleanmaster.security … NotificationMonitorService`, evento `notification_canceled` motivo 10 = REASON_LISTENER_CANCEL), non dal nostro codice. La notifica fissa del servizio (ongoing) resta. Da provare dopo aver tolto a quell'app l'accesso alle notifiche (o escluso Codecore).
- Ricezione in background Android PROVATA (2026-10-15, Mi A3 ↔ PC): con l'app in background arriva la notifica «vuole inviarti dei brani» con ACCETTA/RIFIUTA; ACCETTA dalla notifica avvia il trasferimento senza aprire l'app (file in `Ricevuti`, nome con suffisso se esiste già, richiesta «Completata» sul mittente); «DISATTIVA» nella notifica fissa ferma servizio, annuncio e ricezione (impostazione → off, telefono sparisce dall'elenco del PC). Prerequisito sul telefono di test: l'app `com.cleanmaster.security` cancellava le notifiche (listener) → accesso alle notifiche tolto con `cmd notification disallow_listener`.

- 8.2 (2026-10-15): deviazione dal piano: la risposta alla richiesta Jam si ottiene con `GET /jam/request/<id>` (polling dell'ospite, token di richiesta) invece di `POST /jam/<sid>/respond` sull'ospite; l'ospite non deve quindi esporre un endpoint prima di essere accettato. `JamItem.ref` = chiave opaca del proprietario per risolvere il file locale.
- 8.4 (2026-10-15): deviazione: la Jam usa un proprio `AudioBackend` (secondo `AudioPlayer`, `JamOutput`) invece di passare dall'handler/`PlayQueue`: non sporca la coda locale. All'avvio della Jam la riproduzione locale viene messa in pausa. I controlli di notifica per la Jam sono rimandati a 8.8.
- 8.7 (2026-10-15): regole coda definitive: tutti aggiungono e riordinano, l'ospite rimuove solo i propri brani (non quello in riproduzione), solo l'host salta/«avanti». L'uscita verso l'ospite la sceglie l'host con `setOutput` (consentito all'host anche per l'id dell'ospite).
- 8.8 (2026-10-15): da provare a mano su due dispositivi reali (PC + telefono): Jam di 10 minuti con schermo spento, cambio uscita, chiusura improvvisa, accetta da notifica. Il servizio in primo piano riusa `ReceiveService` (azione «Termina Jam»).
- Prove su due telefoni reali (2026-10-15, Mi A3 = host, Motorola edge 40 = ospite): richiesta/accetta/rifiuta/annulla, aggiunta da entrambi, streaming incrociato con Range e seek, cambio uscita, regole di rimozione, uscita dell'ospite, host in background con servizio e schermo spento, accetta da notifica. Difetti trovati e corretti: HTTP in chiaro bloccato da ExoPlayer (`usesCleartextTraffic`), nome dispositivo «localhost» su Android (canale `deviceName`), ospite che esce non avvisava l'host (`/leave` + controllo di vitalità a 75 s), dialog host che usava `ref` dopo `pop`, dialog di richiesta che restava aperto dopo l'annullamento, nome lungo che spezzava l'IP in colonna nella scheda dispositivo.
- Non provato: PC (manca `libmpv` per avviare il desktop), Wi‑Fi che cade a metà brano precaricato, schermo bloccato con PIN sul Mi A3 (non sbloccabile da adb).
- Fase 9 (2026-10-15), prova su PC + Mi A3 + Motorola: Jam a 3 (host Mi A3, Motorola ospite, PC invitato dal Motorola che ha accettato per conto dell'host), streaming ospite→ospite con `fileToken`, uscita sul Motorola per un brano del PC, uscita del Motorola (invitante): PC e Mi A3 proseguono, i suoi brani spariscono e l'uscita torna all'host; l'ultimo ospite che esce chiude la Jam. Tetto 5 partecipanti (host incluso), vitalità 75 s per membro.
- Fase 10 (2026-10-15): deviazioni — (a) niente comando `ready`: l'avvio ha un anticipo fisso di 1,5 s (`jamStartLeadMs`) e chi non è pronto entra dopo con seek; (b) soglia di ignoro 25 ms invece di 40 (la simulazione con 25 ms di jitter per tratta dava 97 ms di scarto massimo con 40); (c) le uscite sincronizzate scaricano il file nella cache prima di caricare (`JamController._resolve`).
- 10.9 (2026-10-15), prova reale con Mi A3 (host), Motorola edge 40 e PC (Linux, mpv), tutti e tre come uscite per ~3,5 minuti su Wi‑Fi di casa: scarto della posizione del player rispetto a quella attesa — Mi A3 max 12 ms (media 11), Motorola max 9 ms (media 7), PC max 72 ms (media 30; mpv aggiorna la posizione a scatti). Offset degli orologi tra telefoni fino a 430 ms, compensato dallo scambio di timestamp (RTT 9–25 ms). Seek, pausa/ripresa e ingresso a metà brano riallineano entro ~5 s. **Non misurato:** lo scarto acustico (serve un microfono): i valori sopra sono posizione del player, non suono.
- 10.9: filtro sul clock — un giro con RTT ≫ del migliore noto non sostituisce la stima (sul PC un RTT di 183 ms aveva spostato l'offset di ~150 ms) e un secondo affinamento a 5 s dall'avvio.
- 10.9 misura acustica (2026-10-15, microfono del PC, Mi A3 + Motorola, altoparlanti, file di click): all'avvio i due telefoni erano sfasati di **~88 ms** (Motorola dopo); con la correzione a ±2 % l'offset è sceso a ~36 ms in ~12 s e a ~25 ms dopo 22 s, con rimbalzi fino a ~65 ms. Conclusioni: (a) la sola posizione del player (scarto 10–20 ms nei log) non basta, il tempo di uscita dei due telefoni differisce di decine di ms; (b) la convergenza era troppo lenta. Modifiche: seek oltre 120 ms (era 250), correzione di velocità ±3 % (era ±2 %). Da ripetere la misura con la nuova taratura; la compensazione manuale della latenza resta necessaria (cuffie Bluetooth: 100–250 ms).
- 10.9 difetto trovato: in uscita singola, se il sistema mette in pausa il player (audio focus perso), la Jam restava «in riproduzione» senza suonare; ora un controllo ogni 2 s lo riprende.
- 10.9 misura acustica #2 (2026-10-15, microfono del PC, 2 altoparlanti, click ogni secondo, 31 click): con la taratura «seek 120 ms + ±3 % fisso» l'offset oscillava tra −14 e +94 ms (ciclo limite del controllore a gradino con ritardo di attuazione): peggio della versione precedente. Corretto con controllo **proporzionale** (velocità = 1 − errore/4000 ms, tetto ±2,5 %, soglia di ignoro 25 ms, nessun comando per variazioni < 0,3 %): misura #3, **dopo ~14 s di assestamento lo scarto resta a −9 ms (Motorola 9 ms prima del Xiaomi) per 17 click consecutivi**; nei primi 14 s tra −9 e +49 ms. L'ultimo click (12, 56 ms) coincide con la chiusura della Jam. La simulazione ora include ritardo di attuazione di un tick e rumore ±10 ms sulla posizione.

## Note di deviazione (Fase 13+)
- 14.1 (2026-10-16, Linux): release yt-dlp `2026.08.19`, asset `yt-dlp_linux`, `yt-dlp_linux_aarch64`, `yt-dlp.exe` (+ `yt-dlp_arm64.exe`), `SHA2-256SUMS` con righe `<sha256>  <nome>`; `--version` → `2026.08.19`. `--limit-rate 300K` rispettato (media 292 KiB/s su 2,8 MiB). ISRC: 5 righe di `Just_a_mood.csv` cercate come `music.youtube.com/search?q=<ISRC>#songs` → **5/5 con il brano giusto al primo posto** → 14.8 si fa. Formato originale (`-f 'bestaudio[ext=m4a]/bestaudio' -x`, senza `--audio-format`): `.m4a` AAC 2,9 MB, durata 179,6 s, «Not converting audio»; `AudioMetadataTagReader` legge la durata (fixture `test/fixtures/original.m4a`, test aggiunto) e mpv lo riproduce. Android: la libreria 0.18.1 espone `YoutubeDL.version(Context)` e `versionName(Context)` (verificato con javap). Da provare sul telefono: riproduzione m4a con ExoPlayer e cosa restituisce `version()` (vedi «Tocca a te»).
- 14.2: `YoutubeService.toolVersion()` è astratto (anche `FakeYoutube` nei test); su desktop un errore `changed`/`unavailable` con yt-dlp < 2025.11.12 diventa `YtErrorKind.toolOutdated` (messaggio dedicato, anche nell'importazione che va in pausa). Controllo di versione avviato dallo shell solo su desktop (`ytDlpStatusProvider`); banner `YtDlpOutdatedBanner` in Cerca→YouTube e nel Centro Attività, **senza** pulsante «Aggiorna» fino a 14.3. Kotlin `version` aggiunto a `MainActivity.kt`: sarà compilato con la build APK di fine fase.
- 14.3: `YtDlpUpdater` usa `Dio` direttamente (il `WebClient` limita le risposte a 5 MB, il binario ne pesa 40). Ordine di ricerca del binario in `locateYtDlp()` (`yt_dlp_update_providers.dart`): `<appSupport>/bin` → cartella dell'eseguibile → `/app/bin` → PATH; **ffmpeg** resta cercato solo nel PATH (l'estensione a ffmpeg arriva con la fase 26, quando serve `--ffmpeg-location`). Dopo l'aggiornamento il servizio fa `refresh()` (non si invalida il provider: ricostruirebbe la coda dei download). Pulsante «Aggiorna» nel banner e nel gruppo «Download» delle Impostazioni (`DownloadSettingsTiles`, esteso dai task successivi). Provato dal vivo: `CODECORE_LIVE=1 flutter test test/live/yt_dlp_update_live_test.dart` (scarica 2026.08.19, hash ok, esegue).
- 14.4: `DownloadQueue(maxParallel)` (1–3, ricalibrabile a caldo; abbassare non ferma i download in corso). `_removeStalePartFiles` diventa `removeStalePartFiles` e gira **una volta** per sessione (future condivisa: i download successivi la aspettano); `resolveDownloadFolder` non pulisce più (lo usano anche condivisione e ricezione). `DownloadIndex.add` ora serializza le scritture di `downloads.json`. Impostazione `downloadParallel` (predefinito 2) nel gruppo «Download» come menu a tendina.
- 14.1 nota: se bestaudio non ha un m4a, `-x` estrae `.opus`; l'estensione `opus` è già tra quelle scansionate.
- 13.3: `tracks` di `user_data.json` contiene solo i brani con preferito/modifica/testi/ascolti; chi sta solo in una playlist compare nei riferimenti della playlist (niente duplicati). Brano fuori da ogni cartella: `folder` = percorso assoluto del file, `relPath` null. `trackRefFor` è pubblica (serve all'export JSON).
- 13.4: `LibraryEntryLite` guadagna `path` (opzionale, riempito da `liteEntries`); `TrackResolver` tenta percorso relativo → titolo+artista+durata ±2 s → sha256.

## Note di deviazione (Fase 12)
- 12.1 (2026-10-16): CSV vero = `Just_a_mood.csv` (34 brani; intestazioni `Track URI, ISRC, Track Name, Album Name, Artist Name(s), …, Duration (ms)`; **più artisti separati da `;`**). yt-dlp di sistema 2024.04.09 NON legge più YouTube («Please sign in»): provato con yt-dlp 2026.08.19 (binario standalone). `https://music.youtube.com/search?q=…#songs` funziona; in modalità flat dà ~460 voci con solo `id`/`title` (nessuna durata), **senza `--flat-playlist` e con `--playlist-items 1-5`** ogni voce ha `channel`, `artists[]`, `track`, `album`, `duration` in ~5–8 s → si usa quella. `YtResult` guadagna `artists` e `album`.
- 12.4 (2026-10-16): `searchSongs` usa `-J --playlist-items 1-N` (non flat) sull'URL YouTube Music; Android: `items` nel canale `search` (nessun parametro `target`). Nuovo errore `rateLimited` (HTTP 429 / «not a bot») distinto da `unavailable`; chiave ARB `ytErrRateLimited` in it/en/de/es.
- 12.5 (2026-10-16): gli artisti di una riga si salvano separati da `;` (separatore del CSV, quindi mai dentro un nome) invece di « · ». Nessun indice extra (PK `import_id,row_index` basta). `ImportRow` sta in `lib/core/import_row.dart` per non far dipendere `data` da `services`.
- 12.6: `placeImported` inserisce prima del primo brano **già presente** che viene da una riga successiva; se non c'è, in coda (un brano aggiunto a mano resta dov'è, ma i brani importati dopo di lui vanno in fondo).
- 12.7: `YtResult.downloadName` (nome file fisso) invece di un parametro in più su `download`; `DownloadQueue` guadagna `tag`, `onSettled`, `cancelWhere`; `DownloadsNotifier.settled` è lo stream che ascolta il motore.
- 12.8: `loadLibrary` carica solo id/titolo/artista/durata (`TrackRepository.liteEntries`); throttle di 3 download in coda per importazione; 3 errori di ricerca di fila → pausa (`failing`). Artista nei tag = «A, B», `albumArtist` = primo artista (un album Spotify resta unito). Brani con `videoId` già in `downloads.json` si collegano senza riscaricare.
- 12.9: il pulsante sta nell'intestazione della Libreria (icona + voce del menu ⋮ «Importa da Exportify (CSV)») e nel FAB di `PlaylistsScreen`; il foglio d'istruzioni nomina **exportify.net** con «Copia indirizzo» (niente `url_launcher`). Anteprima: conteggi calcolati prima del dialogo (`import_flow.dart`), il dialogo è puro. Su Android il selettore file mostra tutti i file (filtro MIME `csv` inaffidabile).
- 12.10: «Cerca a mano» è un foglio nella schermata di revisione (ricerca YouTube normale), non un salto alla scheda Cerca. Importazioni concluse non restano in «Completate»: esito in snackbar + banner nella playlist finché ci sono righe da risolvere.
- Prova dal vivo PC (2026-10-16, yt-dlp 2026.08.19 standalone in PATH, ffmpeg di sistema): `test/live/import_live_test.dart` — le 34 righe di `Just_a_mood.csv` risolte tutte con punteggio 1,00 al primo giro su YouTube Music, durate entro ±1 s; `test/live/import_e2e_test.dart` — 3 righe cercate, scaricate (mp3), scansionate, taggate dal CSV (`userEdited`) e messe in playlist nell'ordine del CSV. Sono test a pagamento di rete: si lanciano con `CODECORE_LIVE=1 YTDLP=<percorso> flutter test test/live/…`.
- Prova su telefono (Mi A3, APK debug 5000): importazione di 5 righe: foglio con exportify.net, selettore di sistema, anteprima («5 brani · 0 già in libreria · 5 da scaricare»), Centro Attività con Pausa/Annulla, banner nella playlist, schermata «Rivedi», «Riprova tutti» (la riga fallita al primo giro — probabile 403 transitorio — è andata al secondo). Dopo la prova: `LibraryIndex.find` accetta ±5 s (Blowin' in the Wind: 168,8 s su Spotify, 165,5 s su YouTube → prima ±3 s la mancava) e il motore ritenta **una volta** un download fallito per errore transitorio (`changed`/`network`).
- Linux (2026-10-16): `flutter build linux` riuscito; app avviata con HOME isolato e `GDK_BACKEND=x11`, pilotata con xdotool e `xwd`: menu «+» della barra laterale con «Importa da Exportify (CSV)», foglio d'istruzioni, banner «Importazione in pausa: 15/34…» con Riprendi/Rivedi, schermata di revisione, «Cerca a mano» con risultati reali. Il selettore file (portal GNOME, finestra Wayland nativa) non si pilota con xdotool: vedi la riga «Selettore file su Linux» qui sotto.
- Prova completa sul telefono (2026-10-16, Mi A3): `Just_a_mood.csv` (34 righe) importata dalla UI: 29 scaricate + 5 collegate, **34 brani nella playlist, nell'ordine del CSV**, copertine dal collage; un 403 transitorio risolto con «Riprova tutti»; app aggiornata a metà importazione → al riavvio «Importazione in pausa: 13/34» → «Riprendi» ha ripreso dal punto giusto; reimport dello stesso CSV con «Aggiorna quella esistente» → «34 già in libreria · 0 da scaricare», «0 aggiunti».
- Prova completa su Linux (stessa data, HOME isolato): importazione in 34 righe con la build senza ritento → 26 scaricate, 3 collegate, 1 non trovata, 4 con 403 (log `codecore.log`: «HTTP Error 403: Forbidden» su flussi di yt-dlp 2026.08.19); da qui il ritento automatico.
- Selettore file su Linux (2026-10-16, GNOME/Wayland, portal `xdg-desktop-portal-gnome`): provato **con il portal vero** pilotandolo via AT-SPI (`Atspi.Selection` sulle righe + `click` su «Open»/«Cancel», nessun input sintetico; la sidebar GTK non naviga con la sola selezione, quindi il test parte da Download). «Scegli file CSV» → dialogo → `Just_a_mood.csv` → anteprima «34 brani · 0 già in libreria · 34 da scaricare»; «Annulla» lascia il foglio aperto senza errori; importazione avviata e brani scaricati (log senza errori, salvo un 403 transitorio). Difetti trovati e corretti in `import_intro_sheet.dart`: il dialogo si chiamava «flutter picker» (titolo di default del plugin) → `dialogTitle` = «Scegli file CSV»; si apriva su «File recenti» → su desktop parte da Download (`getDownloadsDirectory`). Restano con il titolo «flutter picker» gli altri selettori (cartella musica, copertina playlist, import vecchio DB).
- yt-dlp di sistema (2026-10-16): la versione apt 2024.04.09 non legge più YouTube; installato il binario ufficiale 2026.08.19 (checksum SHA-256 verificato) in `~/.local/bin/yt-dlp`, che nel PATH precede `/usr/bin`. L'app lo trova da sé (`yt-dlp` senza percorso). Aggiornamenti futuri: `yt-dlp -U`.

## Pacchetti approvati
<!-- un pacchetto per riga: nome — fase — data. /obiettivo usa questi senza chiedere; gli altri «da approvare» bloccano solo il loro task. -->
