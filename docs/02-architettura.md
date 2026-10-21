# Architettura

## Principi
- **Un solo processo, nessun server.** Tutto gira nell'app.
- **Livelli** (le dipendenze vanno solo verso il basso):
  `ui` → `providers` → `services` / `data` → `core`.
- Servizi con interfacce per ciò che dipende da pacchetti esterni fragili.
- Android e desktop condividono tutto il codice; le differenze stanno in `lib/core/platform.dart`
  e in 3 punti ben isolati (permessi, cartella predefinita, notifica media).

## Struttura cartelle (`lib/`)
```
lib/
  main.dart                       # init (media_kit su desktop, audio_service su Android), ProviderScope
  app.dart                        # MaterialApp, tema, localizzazioni
  core/
    app_log.dart                  # AppLog.d/i/w/e (print in debug, file di log ruotato in release)
    platform.dart                 # isAndroid, isDesktop, defaultMusicDir()
    paths.dart                    # appSupportDir, coversDir, downloadsDir
    text_utils.dart               # normalize(), stripDiacritics(), sanitizeFileName()
  data/
    db/tables.dart                # definizioni drift
    db/app_database.dart          # AppDatabase (+ .g.dart generato)
    repositories/
      track_repository.dart
      playlist_repository.dart
      folder_repository.dart
    settings/settings_store.dart  # shared_preferences + modello AppSettings
  services/
    tags/tag_reader.dart                  # interfaccia + TagInfo
    tags/audio_metadata_tag_reader.dart   # implementazione con audio_metadata_reader
    tags/tag_writer.dart                  # TagWriter + TagChanges + TagWriteException (solo con opt-in)
    tags/metadata_god_tag_writer.dart     # implementazione con metadata_god (Rust/lofty)
    tags/safe_tag_writer.dart             # copia → scrittura → rilettura → backup → rename atomico
    tags/tag_backups.dart                 # TagBackupStore (ultimi 200 / 2 GB), installFile
    scanner/library_scanner.dart
    covers/cover_store.dart               # salva/trova copertine su disco
    audio/play_queue.dart                 # logica pura di coda/shuffle/repeat
    audio/codecore_audio_handler.dart     # wrapper just_audio (+ BaseAudioHandler)
    online/query_cleaner.dart             # (fase 5)
    online/itunes_client.dart
    online/lrclib_client.dart
    online/lrc_parser.dart
    online/wikipedia_client.dart
    online/enrichment_service.dart
    online/youtube_service.dart
    import/csv_parser.dart, exportify_reader.dart, track_matcher.dart,
           import_candidate.dart, playlist_import_service.dart            # (fase 12)
    share/lan_server.dart, lan_client.dart, offers.dart, discovery.dart  # (fase 6)
    jam/jam_state.dart, jam_host.dart, jam_guest.dart, jam_output.dart, jam_cache.dart  # (fase 8)
  providers/                      # provider Riverpod (database, settings, player, library, ...)
  ui/
    theme/tokens.dart             # colori (CcColors), dimensioni (CcDims), movimento, font
    theme/app_theme.dart          # ThemeData dai token (Notte viola / Nero puro)
    theme/cover_tint.dart         # colore dalla copertina (heroTint, coverTintProvider)
    shell/app_shell.dart          # 3 schede (Home/Cerca/Libreria), un Navigator per scheda, tasto indietro
    shell/shell_nav.dart          # open / openInLibrary: aprire pagine senza perdere mini-player e barra
    shell/bottom_bar.dart, desktop_sidebar.dart, desktop_player_bar.dart, side_panel.dart
    screens/                      # una cartella per schermata (home, search, library, now_playing, jam, ...)
    widgets/                      # TrackRow/LiveTrackRow, CoverImage, CollectionScaffold, mini_player, ...
  l10n/                           # app_it.arb, app_en.arb, app_de.arb, app_es.arb (fase 4)
test/                             # specchio di lib/ per la logica pura
```

## Flussi principali
**Scansione:** UI (cartelle scelte) → `LibraryScanner.scan()` in isolate → `TagReader` →
`TrackRepository.upsertBatch()` → `Stream<List<Track>>` → UI si aggiorna da sola.

**Riproduzione:** UI tocca un brano → `PlayerController.playQueue(snapshot, index)` →
`CodecoreAudioHandler` (just_audio) → stream di stato → provider → mini player / now playing.
Su Android, `AudioService` espone lo stesso handler a notifica, schermata di blocco, cuffie.

**Impostazioni:** `SettingsStore` (shared_preferences) → `settingsProvider` (Notifier) → tema/lingua/ecc.
Scritture con debounce 400 ms, mai in un handler di slider a ogni tick.

## Differenze per piattaforma
| Aspetto | Android | Windows / Linux |
|---|---|---|
| Backend audio | ExoPlayer (just_audio) | libmpv (just_audio_media_kit) |
| Notifica / lock screen | `audio_service` (anche per la Jam, fase 17) | controlli di sistema (MPRIS/SMTC) rimandati: pacchetti da approvare (fase 17.7/17.8) |
| Equalizzatore | `AndroidEqualizer` (bande reali del telefono, profilo cuffie/altoparlante) | assente (il filtro `af` di mpv è occupato da `scaletempo`); voce nascosta |
| Velocità 0,5×–2× | `setPlaybackParameters` (tono invariato) | mpv `scaletempo` (tono invariato, misurato) |
| Permessi file | `READ_MEDIA_AUDIO` (+ `READ_EXTERNAL_STORAGE` ≤ API 32) | nessuno |
| Cartella musica predefinita | `/storage/emulated/0/Music` | `~/Music` (Linux), `%USERPROFILE%\Music` (Windows) |
| Cartella download | `getExternalStorageDirectory()/Music` (nessun permesso) | cartella musica scelta |
| Scelta cartella | `file_picker.getDirectoryPath()` | idem |

## Decisioni già prese (non rimetterle in discussione)
- Tag **in lettura** con `audio_metadata_reader` (puro Dart). Le modifiche dell'utente vivono nel DB, che resta la fonte di verità;
  **solo con l'opzione `writeTagsToFiles`** (spenta di default, Fase 21) vengono scritte anche nei file da `metadata_god`
  (Rust) dietro `TagWriter`, **sempre** tramite `SafeTagWriter`: copia di lavoro, rilettura e confronto, backup dell'originale
  in `tag_backups/`, `rename` atomico. `metadata_god` è una copia locale in `third_party/metadata_god/` (patch Gradle 9).
- Identità brano = `id` intero DB + `path` univoco. Hash SHA-256 calcolato **solo** su richiesta (condivisione).
- Album raggruppati con `albumKey` (vedi `03-modello-dati.md`), non per solo nome.
- Niente "bit-perfect"/uscita esclusiva. Gapless e crossfade dalla fase 18, **dietro un'impostazione** (predefinito «Normale»); la coda resta gestita da `PlayQueue`.
- Niente traduzione automatica nella v1 (era un endpoint Google non ufficiale). Eventuale ML Kit solo Android, più avanti.
- Niente server web, niente protocollo MSTP: la fase 6 è un semplice scambio HTTP con PIN.

## Jam (fase 8)
- Un dispositivo suona alla volta (uscita selezionabile); l'altro è telecomando. Nessuna sincronia tra due uscite.
- Stato condiviso autoritativo sull'host (`JamState` con `version`); comandi validati da una funzione pura
  (`applyCommand`) con i permessi: l'ospite non può cambiare brano direttamente.
- I brani restano sul dispositivo del proprietario e si leggono in streaming (`Range`, token di sessione) solo
  se sono in coda; nessuna libreria esposta. Precarico del successivo in cache temporanea.
- Trasporto: lo stesso endpoint HTTP delle offerte (`OfferNode`), aggiornamenti con long polling.
- Codice: `lib/services/jam/` (`jam_models`, `jam_state` = riduttore puro, `jam_host` = rotte `/jam` montate da `OfferNode`,
  `jam_guest` = client, `jam_output` = applica lo stato a un `AudioBackend`, `jam_cache`), orchestrazione in
  `lib/providers/jam_providers.dart` (`JamController`), UI in `lib/ui/screens/jam/`.
- La Jam usa un proprio `AudioBackend`: la coda locale (`PlayQueue`) non viene toccata; la riproduzione locale va in pausa all'avvio.
- Permessi coda: tutti aggiungono e riordinano; l'ospite rimuove solo i propri brani (mai quello in riproduzione) e non
  cambia brano; l'host fa tutto.
- Fase 9: più ospiti. `JamState.participants` (elenco con indirizzi), token d'identità per membro + `fileToken` di sessione (intestazione `x-jam-file`), invito inoltrato da un ospite all'host (`/<sid>/invite`), uscita di un membro (`/<sid>/leave`) che toglie i suoi brani. Sincronia di più uscite prevista in Fase 10 (vedi `docs/fase-9-jam-multi.md`).
- Fase 10: uscite multiple sincronizzate. `JamClock` (offset verso l'orologio dell'host, rotta `/time`, filtro sui giri lenti), `JamSyncController` (decisioni pure: avvio programmato, velocità ±2 %, seek), `JamOutput` in modalità sincrona (cache obbligatoria, anticipo di `jamStartLeadMs`), compensazione manuale della latenza in `AppSettings.jamLatencyMs`.

## Interfaccia (fase 11)
- **Navigazione:** quattro schede (`NavTab.home|search|library|memory`), ciascuna con un `Navigator` annidato (chiavi in
  `tabNavigatorKeysProvider`) dentro un `IndexedStack`. Album, artista, playlist, Preferiti, Impostazioni si aprono
  con `ShellNav.open` nella scheda corrente; `ShellNav.openInLibrary` (Now Playing, menu «Vai a») chiude le rotte
  del navigatore principale e apre la pagina nella Libreria. Now Playing, Testi, Jam, dialoghi e fogli restano sul
  navigatore principale. Indietro di Android: navigatore annidato → Home → uscita (`PopScope` in `AppShell`).
- **Layout per larghezza (≥ 840):** barra laterale 240 (72 sotto i 1000 px) + barra player 80 + pannello destro
  320 (`sidePanelProvider`: coda, testo, info). Sotto: mini-player a card sopra la barra in basso.
- **Token:** nessun esadecimale nei widget; `context.cc` (estensione `CcColors`) e `Theme.of(context)`.
  Font Figtree + Unbounded (asset OFL). Solo temi `notte` e `oled`.
- **Colore dalla copertina:** `coverTintProvider` (24 px, in cache) → `heroTint` (luminosità limitata, testo ≥ 7:1)
  → `CoverBackdrop` (Now Playing, Testi, pagine di raccolta) e fondo del mini-player.
- **Una riga brano:** `TrackRow`/`LiveTrackRow` con varianti `standard|album|queue|pick`; tocco suona, pressione
  lunga / clic destro = `trackActions` (modello unico dei gruppi di azioni), swipe a destra = «Aggiungi in coda».
- **Contesto di riproduzione:** `PlayContext` (album, artista, playlist, Preferiti, libreria, ricerca) in
  `playContextProvider`, solo in memoria; «In riproduzione da» in Now Playing.
- **Attività:** `activityProvider` (scansione, arricchimento, download, invii) → `ActivityButton` → `ActivitySheet`.
- **Dispositivi:** `DevicesSheet` (Jam attiva + dispositivi vicini con [Jam] [Invia]) dal mini-player, Now Playing e
  barra desktop; `ShareScreen` resta per il collegamento manuale.
- **Test visivi:** `test_shots/` (fuori da `flutter test`), `scripts/shots.sh`; prova su telefono con
  `flutter build apk --debug --build-number=5000` + `adb install -r` (vedi nota in `docs/PROGRESS.md`, 11.5).

## Importazione da CSV (fase 12)
- **Flusso:** `ImportIntroSheet` (istruzioni, sito **exportify.net**) → `readExportify` (isolate) → `ImportPreviewDialog`
  → `PlaylistImportService.start` → per riga: libreria (`LibraryIndex`, nessuna rete) → YouTube Music
  (`YoutubeService.searchSongs`, `yt-dlp --playlist-items 1-5`) → ricerca YouTube normale → `decide` (punteggio:
  durata 45 %, titolo 35 %, artista 20 %, bonus «- Topic») → `sure` scarica / `review` salva 3 candidati / `notFound`.
- **Stato su DB** (schema v4: `playlist_imports`, `playlist_import_items`): sopravvive alla chiusura; all'avvio
  `recoverAfterRestart` mette «in pausa» le importazioni in corso (nessuna rete senza azione dell'utente).
- **Download:** `DownloadQueue` con `tag` `import:<id>:<riga>`; `DownloadsNotifier.settled` avvisa il motore, che
  applica i tag del CSV (`TrackEditor.save`, `userEdited`) e inserisce il brano nella posizione del CSV
  (`PlaylistRepository.placeImported`). Al più 3 download in coda per importazione, 1,5 s tra due ricerche; 429 → pausa.
- **UI:** `ImportBanner` nella pagina playlist, `ImportReviewScreen` (+ `ImportManualSearchSheet`), riga nel Centro Attività.

## Download (fase 14)
- **Coda:** `DownloadQueue(maxParallel 1–3, retryPolicy)` esegue in ordine di arrivo; un errore transitorio (`network`/`changed`) mette l'elemento in `waitingRetry` (non occupa lo slot) e lo riaccoda dopo 5/20/60 s ±20 % (`RetryPolicy`); `onSettled` arriva solo all'esito definitivo. I `.part` orfani si cancellano **una volta** per sessione (`removeStalePartFiles`).
- **Opzioni:** `DownloadOptions(rateLimitKBps, format)` lette dalle impostazioni a ogni download; `buildDownloadArgs` (`yt_dlp_args.dart`) costruisce la riga di comando desktop, Android riceve `rateLimit`/`convert` dal canale `codecore/ytdlp`.
- **yt-dlp desktop:** `locateYtDlp()` (`<appSupport>/bin` → accanto all'eseguibile → `/app/bin` → PATH); `YtDlpUpdater` scarica e verifica; `ytDlpStatusProvider` + `YtDlpOutdatedBanner` avvisano se < `kMinYtDlpVersion`. Un errore su un yt-dlp vecchio diventa `YtErrorKind.toolOutdated`.
- **Importazione:** ricerca per ISRC prima (solo se «sicuro»), `CachedYoutubeService` + `SearchCache` (`search_cache.json`), controllo della durata a fine download (scarto > 10 s → «da verificare» con «Tieni questo»), limiti di 5 MB / 10.000 righe sul CSV, timeout di 45 s sulle ricerche (il processo viene terminato).

## Importazione 2 (fase 15)
- **Lettori:** `playlist_reader.dart` sceglie per estensione (`csv` → `csv_profiles.dart`, `m3u`/`m3u8` → `m3u_reader.dart`, `xspf` → `xspf_reader.dart`); tutti restituiscono `ImportedPlaylist(kind, rows, baseDir)`. Il CSV si legge per **intestazione** (sinonimi di colonna) e la sorgente (`exportify`, `tunemymusic`, `soundiiz`, `lastfm`, `csv`) è solo un'etichetta.
- **Libreria:** `LibraryIndex.find` prova prima `findByPath` (assoluto, poi per cartelle finali; relativo alla cartella del file), poi titolo+artista+durata ±5 s.
- **Motore:** per riga → libreria → album (≥ 3 righe dello stesso album: una ricerca album, solo titoli equivalenti e `sure`) → ISRC → titolo+artista → `decide(soglie)`. `ImportOptions` (solo collega, rivedi prima, cartella, numerazione, copertine) sta sull'importazione; `planned` + `startPlanned` per l'anteprima; blocchi da 100 come importazioni in fila; `sync` crea un'importazione con tutto il file (`diffImport` + `reorderForSync`).
- **Stato per riga:** note come codici (`ImportNote`), tradotte in `import_labels.dart`; `EtaEstimator` per il tempo residuo.
- **Catena di blocchi** (2026-10-21): i blocchi «Nome (n/N)» si ricavano dal DB (`import_chain.dart`: `groupImportChains`, `nextBlockAfter`), non da una mappa in memoria, così la catena riparte anche dopo un riavvio; pausa/riprendi/annulla agiscono sull'intera catena (`pauseChain`/`resumeChain`/`cancelChain`) e `completed` arriva solo a fine catena. L'interfaccia mostra **un'importazione** (`ImportProgress.chain`, `saved` = scaricati + collegati).
- **Fase di ogni riga:** `rowPhase` (`import_row_phase.dart`) unisce lo stato su DB, i passi in corso del motore (`currentSteps`: più righe insieme, ricerca e tag) e la coda di download; dopo i tag del CSV il brano passa a `QuietEnricher` (testi e campi mancanti, uno alla volta, **senza** riga «Arricchimento» nel Centro Attività né snackbar: vale per ogni download). `ImportDetailScreen` elenca tutte le righe con filtri.
- **In background (Android):** `ImportService` (Kotlin, FGS `specialUse`, wake lock parziale + Wi‑Fi lock) resta acceso finché un'importazione o dei download girano; Dart lo pilota da `importNotificationProvider` (canale `codecore/import`, al più un aggiornamento al secondo) con la notifica di avanzamento e «Pausa»; a fine catena una notifica di riepilogo. Senza servizio in primo piano Android 15 congela l'app pochi secondi dopo che esce dallo schermo.
- **Centro Attività:** l'importazione è una riga con nome e scaricati/totali; i download dell'import non vi compaiono; ciò che finisce va nel **Registro** (`activityLogProvider`, in memoria, ultimi 500 eventi).

## CI e test (fase 16)
- **GitHub Actions** (`.github/workflows/`): `ci.yml` — job `check` (codice generato e l10n aggiornati, `flutter analyze`, `flutter test`) su ogni push/PR; `build-android`, `build-linux`, `build-windows` solo su tag `v*` o avvio manuale, con artefatti; il job Windows esegue anche la suite. `nightly.yml` — test `test/live/` con yt-dlp fissato e verificato, riepilogo di quali sorgenti rispondono (informativo). `deps.yml` — rapporto settimanale delle dipendenze (nessun aggiornamento automatico).
- **Test:** `test/` (unitari e widget, ermetici: né rete né file fuori dal repo), `test/goldens/` (20 schermate, solo Linux, comparatore al 0,5 %, `coverImageStub`), `test/live/` (dietro `CODECORE_LIVE=1`), `test/data/performance*_test.dart` (budget a 20.000 e 50.000 brani). `integration_test/` (telefono/Linux) arriva con il pacchetto `integration_test` (da approvare).
- **Banco visivo:** `test_shots/` + `scripts/shots.sh` per guardare le schermate; i golden riusano il suo `withShot`.

## Riproduzione avanzata (fase 17)
- **Velocità:** la possiede `CodecoreAudioHandler.setSpeed` (0,5–2, impostazione globale `playbackSpeed`), riapplicata dopo ogni `load` e pubblicata in `playbackState.speed`. La Jam non la usa (R37).
- **Segnalibro:** `tracks.resume_position_ms` (schema v6). Logica pura in `resume_point.dart`: solo brani ≥ 20 min, niente nei primi/ultimi 30 s, si riparte 5 s prima. L'handler salva a pausa, a cambio brano e ogni 15 s di avanzamento.
- **Anteprima:** `PreviewPlayer` è un secondo `AudioBackend` (come quello della Jam): 20 s da un terzo del brano con rampe di volume; `previewProvider` mette in pausa il lettore principale solo se suonava e lo riprende dopo. Coda e conteggi non si toccano.
- **Equalizzatore:** interfaccia `Equalizer` (`bands()`, `setEnabled`, `setGains`) esposta da `AudioBackend.equalizer` (null dove non esiste). Preset in `presetGains` (10 bande di riferimento interpolate sul logaritmo della frequenza, tagliate ai limiti del dispositivo). Due profili (`eqSpeaker`, `eqHeadphones`); `outputRouteSyncProvider` legge l'uscita dal canale `codecore/audio` e `equalizerApplierProvider` applica la curva giusta.
- **Controlli di sistema per la Jam:** `RemoteTransport` (stato + play/pausa/avanti/seek). `JamTransport` lo ricava da `JamState`; `CodecoreAudioHandler.attachRemote` lo collega a notifica e schermata di blocco: finché è attaccato i tasti vanno alla Jam e mai al lettore locale. `JamController` lo attacca in `_begin` e lo stacca in `_teardown`.

## Gapless e crossfade (fase 18)
- **Principio:** `PlayQueue` è l'unica autorità sull'ordine. Il backend riceve solo una **finestra di due brani** (corrente + successivo, `GaplessCapable.setNext`) e avvisa con `advanced` quando è passato al successivo; non decide mai cosa suonare.
- `PlayQueue.items` è sempre l'**ordine di ascolto** (dal 2026-10-21): attivare la riproduzione casuale riordina ciò che segue il brano corrente, così la Coda mostra quello che «avanti» suonerà davvero (anche dai tasti delle cuffie). Ogni voce ha una chiave: disattivare la casuale rimette l'ordine naturale, e cronologia, «indietro», spostamenti e rimozioni sopravvivono ai rimescolamenti. Si salva solo l'ordine di ascolto: dopo un riavvio con la casuale attiva, disattivarla lascia l'ordine com'è.
- `PlayQueue.peekNext()` dice quale brano seguirà (anche a fine giro in shuffle, fissando l'ordine in anticipo) e `revision` cresce a ogni modifica. `NextWindow` li usa per tenere allineato il backend e non fa nulla se non è cambiato niente.
- `CodecoreAudioHandler.setTransition(mode, …)` (`TransitionMode`: normale · senza pause · dissolvenza). Al passaggio automatico (`_onAdvanced`) aggiorna brano, conteggio ascolti, ReplayGain e notifica **senza ricaricare**; se la coda non è più quella annunciata, carica il brano giusto nel modo normale. Un brano con segnalibro o fuori libreria non entra nella finestra (passaggio normale).
- **Senza pause:** `JustAudioBackend` tiene nella playlist `[corrente, successivo]` e toglie il finito. Su desktop mpv fa il resto (`prefetch-playlist` non serve: misurato, 0 ms).
- **Dissolvenza:** `CrossfadeEngine` (due backend alternati, creati alla prima dissolvenza) è il backend del lettore principale: in Normale e Senza pause è un passante. Il secondo lettore prepara il brano a volume 0; a `durata − durata_dissolvenza × velocità` parte la rampa a potenza costante in 20 passi; **a metà** i ruoli si scambiano e `advanced` esce. Brani corti (< 2 × durata) e brani dello stesso album (opzione) passano alla finestra gapless.
- **Jam:** invariata (backend e sincronia propri); nessun sorgente di `lib/services/jam/` conosce la finestra (test).
- **Differenza desktop/Android in Normale:** su desktop mpv segnala la fine quando il decoder arriva a EOF, prima che l'audio nel buffer sia uscito: il caricamento del successivo ne scarta ~0,2 s (misurato). «Senza pause» lo evita.

## Interfaccia (fase 19)
- **Selezione multipla:** `Selection` (immutabile: `toggle`, `selectRange` dall'ancora, `selectAll`, `retainWhere`, `inOrderOf`) in `selectionProvider(chiave)` — uno per lista (`all`, `favorites`, `album:<chiave>`, `artist:<chiave>`, `playlist:<id>`, `genre:<nome>`, `search`, `search-all`, `youtube`), quindi uscire dalla pagina o cambiare scheda la annulla. `LiveTrackRow(selection: RowSelection(chiave, idVisibili))` la rende selezionabile: pressione lunga sul telefono (il menu resta su ⋯), Ctrl/Maiusc+clic su desktop. `SelectionScope` gestisce Indietro, Esc, Ctrl+A e il filtro che nasconde righe; `SelectionBar` / `SelectableAppBar` / `SelectionBarSlot` sono la barra; `bulkActions(…)` riusa il modello `TrackAction` del menu del brano con i brani **nell'ordine della lista**. Nessuna azione tocca i file: «rimuovi» è solo riga di DB o di playlist; dalla libreria si tolgono **soltanto** i brani `missing`.
- **Trascinamento (desktop):** `Draggable<TrackDragData>` sulle righe (la selezione intera se la riga ne fa parte), `TrackDropTarget` sulle voci playlist/Preferiti di `DesktopSidebar`.
- **Limiti dei servizi online (Wikimedia, MusicBrainz, iTunes):** documentati in `request_budget.dart`. Wikimedia (Action e REST API, limite **globale** per client e **al minuto**, fonte: <https://www.mediawiki.org/wiki/Wikimedia_APIs/Rate_limits>, 2026, «soggetto a modifiche»): client senza identificazione (solo IP) **10/min**; bot non autenticato con User-Agent conforme (che indichi come contattare chi lo gestisce) **200/min**; al massimo **3 richieste in parallelo**; oltre il limite HTTP **429** (o 503 se sovraccarico) con `Retry-After`, e se manca attendere ≥ 5 s con attese crescenti. Le regole d'uso (<https://www.mediawiki.org/wiki/API:Etiquette>) chiedono richieste **in serie**, `User-Agent` nel formato `nome/versione (contatto)` (senza, 403 o blocco dell'IP) e `maxlag` per i lavori non interattivi. L'app manda `Codecore/1.0 (uso personale)`, senza contatto: conta come **non identificata**, quindi il tetto è **8/min** (`kWikimediaAnonymousPerMinute`); con `kApiContact` valorizzato (`lib/core/app_info.dart`: e-mail, indirizzo web o utente wiki; è pubblico) il User-Agent diventa `Codecore/<versione> (<contatto>)` e il tetto **150/min**. `DioWebClient` fa attendere (non fallire) ogni richiesta a `*.wikipedia.org`, `*.wikidata.org`, `*.wikimedia.org` tramite un solo `WindowLimiter` finestra di 60 s, anche per i nuovi tentativi dopo un 429 (`Retry-After` ≤ 10 s). MusicBrainz: **1 richiesta/s** e User-Agent con contatto (`MusicBrainzClient.gap`, 1,1 s, un nuovo tentativo sui 503). iTunes Search: circa 20 chiamate/min (il lotto usa 3 s di distanza).
- **Temi personalizzati (fase 27):** `custom_theme.dart` (`CcToken` = i 12 colori, `CustomTheme {id, nome, base, overrides, background}`, `resolve()` → `CcColors`: i token non scelti a mano si **derivano** da sfondo/accento/testo; `isLight` dalla luminanza dello sfondo; `ensureContrast` per «Correggi»), `CustomThemes` (lista ≤ 20, JSON in `SharedPreferences` chiave `customThemes`, quindi nel backup). `theme` accetta `custom:<id>` (id sparito = Notte). `theme_providers.dart`: `customThemesProvider`, `themeColorsProvider`, `themeBackgroundProvider`. `app.dart` costruisce `buildThemeFromColors(colori, compatto, pageBackdrop:)`; con sfumatura o immagine `AppBackground` sta dietro tutte le pagine (`MaterialApp.builder`) e scaffold/app bar diventano trasparenti. Immagini in `<appSupport>/theme/bg-<id>-<ms>.png` (≤ 1600 px, `background_image.dart`; potate all'apertura delle Impostazioni). UI: `theme_tiles.dart` (elenco e azioni), `theme_editor_screen.dart` (+ `theme_background_editor.dart`, `color_picker.dart`). Test di regressione: nessun colore letterale fuori da `lib/ui/theme/` (`no_stray_colors_test.dart`).
- **Temi:** `palette.dart` (`AppThemeId {notte, oled, chiaro}`, `CcAccent` con 8 accenti, `buildPalette(tema, accento)`); nel chiaro gli accenti sono scuri. Contrasto AA verificato per **tutti** gli abbinamenti (`contrast_test.dart`); `heroTint(…, light:)` per il fondo dietro le copertine.
- **Layout ≥ 1200 px:** pannello destro (coda) automatico a 360 px quando parte un brano (finché l'utente non lo chiude), griglia album con celle ≥ 168 px, Home a 3 colonne da 900 px, cerniera verticale rispettata (`MediaQuery.displayFeatures`).
- **Lingue:** it (template), en, de, es, fr, pt (europeo); `test/l10n/arb_test.dart` controlla chiavi, segnaposto e stringhe rimaste in italiano.
- **Onboarding:** `OnboardingGate` davanti ad `AppShell`; solo con libreria e cartelle vuote e `onboardingDone` falso.

## Libreria intelligente (fase 20)
- **Un solo linguaggio di regole** per la ricerca e per le playlist intelligenti, in `lib/services/library/rules/`: `rule_ast.dart` (albero sigillato con forma canonica), `rule_parser.dart` (`parseRules` **non lancia mai**: un termine incomprensibile diventa testo libero + avviso; `hasOperators`, `freeTextOf`), `rule_sql.dart` (`toSql`: AST → `WHERE` con **soli `Variable`**, ogni foglia in `COALESCE(…,0)` così la negazione tiene i valori assenti), `rule_rewrite.dart` (rinomina di un'etichetta dentro le regole salvate). `TrackRepository.watchByRules`/`tracksByRules`/`countByRules` le eseguono (`readsFrom: tracks, track_tags, user_tags`).
- **Ricerca:** con operatori i brani vengono dalle regole e le altre sezioni filtrano solo le parole semplici; senza operatori nulla cambia. Chip di suggerimento, avvisi e foglio «?» in Cerca.
- **Cronologia:** `CodecoreAudioHandler` cronometra l'ascolto (somma dei passi di posizione in `playing`) e scrive `plays` tramite `PlayHistoryRepository` alla stessa soglia di `registerPlay`; chiude la riga a ogni pausa, ogni 30 s, al cambio brano e alla chiusura. `StatsQueries` calcola ricapitoli per mese/anno in SQL (una passata per brano, barre con una somma per intervallo, ore del giorno raggruppate per ora) e li ricalcola quando `plays` cambia.
- **Playlist intelligenti:** `SmartPlaylistRepository` (ordini `SmartSort`, «a caso» stabile per sessione); pagina in sola lettura; si possono convertire in playlist normale (copia dell'elenco).
- **Etichette:** `TagRepository` (assegnazione in massa in una transazione, rinomina che aggiorna le regole); foglio con caselle a tre stati, azioni in massa, Libreria → Etichette.

## Nuove fonti (fase 22)
- **Fonti**: `MediaSource { youtube, soundcloud }` su `YtResult` (con `webpageUrl`, `downloadUrl`, `indexKey`); `SearchSource { youtube, youtubeMusic, soundcloud }` è la scelta dell'utente in Cerca (`AppSettings.searchSource`). Tutto passa da yt-dlp (desktop: processo; Android: canale `codecore/ytdlp`), nessun endpoint non ufficiale.
- **SoundCloud**: `searchSoundCloud` usa un elenco **flat** (`scsearch<N>`) perché su Android una sola voce DRM farebbe fallire l'intera chiamata; le anteprime da 30 s si scartano per durata (≤ 31 s) o per formati `*_preview`. Il download usa la **pagina** (`webpage_url`), non l'id; per YouTube resta `watch?v=<id>`. `downloads.json` ha chiavi `<fonte>:<id>` (le vecchie senza prefisso valgono come `youtube:`).
- **Punteggio**: `scoreCandidate` guarda `c.source` (niente «- Topic»/VEVO su SoundCloud, bonus per l'uploader, penalità per bootleg/edit/flip…). Il ripiego SoundCloud dell'importazione è un'opzione spenta di serie, una sola ricerca per riga ancora «non trovata».
- **Playlist e canali**: `youtube_urls.dart` (classificazione e `listingUrl`), `YoutubeService.listPlaylist` → `PlaylistListing`, `PlaylistImportService.startFromResults` (righe già decise, niente ricerca, stesso motore e stesse pause/ripresa/annulla di una CSV). I provider che falliscono vanno gestiti con `retry` esplicito: Riverpod 3 ritenta da solo.
- **Traduzione dei testi** (22.7): `LyricsTranslator` (`services/online/lyrics_translator.dart`) con `MlKitLyricsTranslator` (`google_mlkit_translation`, solo Android, on-device, nessun testo in rete). `lyricsTranslatorProvider` vale `null` fuori da Android: la UI (pulsante nella schermata testi, gruppo «Modelli di traduzione» in Impostazioni) si nasconde. `translateKeepingLayout` mantiene l'allineamento con i tempi LRC; la traduzione sta in `lyricsTranslationProvider` (memoria, non nel DB) e `LyricsView` la mostra sotto ogni riga. Nei test si sostituisce il provider con un traduttore finto.

## Podcast (fase 23)
- **Dati**: schema v9, `tracks.kind` (0 musica · 1 episodio) e le tabelle `podcasts` / `podcast_episodes`. Un episodio **scaricato** è una riga di `tracks` con `kind = 1`, `folderId = null` e il file in `<appSupportDir>/podcasts/<podcastId>/`, cartella che non sta in `folders`: la scansione non la vede. Il player, la coda e la notifica funzionano senza modifiche perché lavorano su `Track.id`.
- **Esclusione**: ogni vista musicale (brani, album, artisti, generi, ricerca, regole, Home, playlist, doppioni, abbinamenti dell'import) filtra `kind = 0`; `PlaylistRepository.addTracks` ignora gli episodi; gli ascolti degli episodi non entrano nella cronologia (`CodecoreAudioHandler._beginListen`).
- **Servizi** (`lib/services/podcast/`): `podcast_models` (tipi e `FeedFetcher`/`FeedParser` iniettabili), `feed_fetcher` (Dio a flusso, limite 20 MB, solo http/https), `podcast_service` (iscrizione, aggiornamento, `refreshIfStale` a 6 ore, ricerca iTunes, annulla iscrizione che cancella solo dentro `podcasts/`), `episode_downloader` (file `.part` + `rename`, riga `kind = 1`, estensione dal `content-type`), `podcast_cleanup` (episodi ascoltati più vecchi di N giorni, mai in coda, mai fuori cartella). **La rete parte solo da un'azione dell'utente** (iscriversi, «Aggiorna», aprire una pagina con l'ultimo controllo di oltre 6 ore fa, «Scarica»), mai all'avvio.
- **Segnalibro e «ascoltato»**: per gli episodi il segnalibro vale sempre (niente soglia di 20 minuti, tranne i primi 10 s) e da 95 % in poi l'episodio è ascoltato; il gestore audio non conosce i podcast: chiama un callback (`onEpisodeHeard`) che `main.dart` collega a `PodcastRepository.markPlayedByTrack`.
- **Interfaccia**: Libreria → voce fissa «Podcast» → `PodcastsScreen` → `PodcastDetailScreen`; iscrizione da `PodcastSubscribeSheet`. Download nel Centro Attività come righe `ActivityKind.download`.
- **Lettore dei feed**: `rss_parser.dart` (`parseFeed` in un isolate, pacchetto `xml`; date RFC 822 con parser nostro; item senza audio saltati e contati; non-RSS → `FormatException`).

## Dispositivi fidati e sync (fase 24)
- **Fatto**: `TrustedDevices` (`lib/services/share/trusted_devices.dart`, immutabile, salvato come JSON nella chiave `trustedDevices` di `SharedPreferences`, `TrustedDevicesNotifier` in `share_providers.dart`) con confronto dell'impronta **normalizzata** (`matches`, `byFingerprint`); schema v10 (`playlists.uuid` unico e `updated_at` toccato da ogni scrittura di `PlaylistRepository`); `lib/services/share/playlist_sync.dart` (`planSync` puro) + `PlaylistSyncRepository` (esporta, risolve con `TrackResolver` di fase 13, applica in una transazione) + `sync_preview_dialog.dart`; Impostazioni → «Dispositivi fidati» (compare con almeno un abbinato).
- **Da fare (bloccato dai pacchetti)**: identità del dispositivo = certificato EC autofirmato generato una volta (24.2, `basic_utils`/`pointycastle`), `OfferNode` su HTTPS con verifica dell'impronta (24.4), abbinamento con PIN (24.5) e QR (24.7, `mobile_scanner`), offerte senza PIN dai fidati (24.6), rotte `/sync/playlists` e pulsante «Sincronizza playlist» nella scheda del fidato (24.9). La **Jam resta su HTTP con token** (ExoPlayer/mpv e HTTPS autofirmato: R61), su un socket separato da quello delle offerte.
- **Sincronia delle playlist**: per `uuid`; vince la modifica più recente (`updated_at`), solo dopo anteprima; i brani si abbinano con lo stesso `TrackResolver` del ripristino (percorso relativo → titolo+artista+durata → hash); quelli che mancano si elencano e si possono chiedere con un'offerta inversa (24.6). Le cancellazioni **non** si propagano e preferiti/testi/modifiche non si sincronizzano (fuori fase).

## Android esteso (fase 25)
- **La sessione media è l'unico punto di comando**: widget (`NowPlayingWidget4x1/2x2`), tile (`PlayTileService`), Android Auto e orologio mandano tasti/comandi alla sessione di `audio_service`; non toccano DB o file.
- **Dati verso widget e tile**: `WidgetSync` (Dart, cablato in `main.dart`, solo Android) scrive titolo/artista/copertina/stato con `PrefsWidgetBridge` in `FlutterSharedPreferences` (`flutter.widget.*`); `CodecoreApp` (Kotlin, `Application`) ascolta `flutter.widget.stamp` e ridisegna widget e tile. Niente `home_widget`, niente canale: il motore che `audio_service` avvia senza attività non ha i canali di `MainActivity`.
- **A freddo**: `MediaKeys.pressSurely` (vedi R63). `WidgetStore.playerReady` = `widget.readyAt` più recente dell'avvio del processo.
- **Android Auto**: `MediaBrowseTree` (puro, sui repository esistenti) dietro `CodecoreAudioHandler.browse`; ids `root/fav/playlists/playlist:<id>/albums/album:<key>/top/recent/track:<id>@<cartella>`, liste ≤ 200, ricerca ≤ 50; la coda di un brano scelto è la lista mostrata. Un browser collegato prima che Dart sia pronto riceve una lista vuota (limite di `audio_service`; `notifyChildrenChanged` richiede `rxdart`, non approvato).
- **Wear OS**: nessun codice; i controlli di sistema per la sessione del telefono (da verificare a mano).
- **Modalità in auto** (`lib/ui/screens/car/`): schermata a mano dal menu di Now Playing (solo mobile), pulsanti ≥ 96 dp, Preferito, foglio con Preferiti + 5 playlist recenti, «schermo sempre acceso» opzionale via canale `codecore/screen` (`FLAG_KEEP_SCREEN_ON`).

## Distribuzione (fase 26)
- **Linux**: `scripts/package-linux.sh [--deb]` da `flutter build linux --release`; `.desktop` condiviso in `packaging/linux/`, `control.in` per il .deb (`/opt/codecore`, `/usr/bin/codecore`). AppImage/Flatpak/Inno Setup non ci sono ancora (strumenti da approvare).
- **Android**: release con minify + shrink (`proguard-rules.pro`); **variante `lite`** = `CODECORE_LITE=1` (Gradle toglie `youtubedl-android` e usa `src/lite/kotlin`, il canale `codecore/ytdlp` è in `YtDlpChannel` solo in `src/full/kotlin`) + `--dart-define=CODECORE_YOUTUBE=false` (`kEnableYoutube`).
- **Aggiornamenti**: `update_checker.dart` (`compareVersions`, `UpdateChecker` su `releases/latest` di GitHub), solo su richiesta o con «Controlla all'avvio» (spento, al più 1 al giorno); nascosto finché `kReleaseRepo` è vuoto. Nessun download/installazione automatici.

## Backup, ripristino ed export (fase 13)
- `lib/services/backup/`: `user_data.dart` (formato portabile), `track_resolver.dart`, `backup_service.dart` (zip: `manifest.json`, `settings.json` senza `deviceId`/`deviceName`/`trustedDevices`, `user_data.json`, `codecore.sqlite` da `VACUUM INTO`, `covers/`, `downloads.json`; compressione in un isolate), `restore_service.dart` (`inspectBackup`, `stageFullRestore`, `applyPendingRestore`, `mergeBackup`); l'unione è in `data/repositories/backup_merge.dart`.
- **Sostituzione**: `stageFullRestore` estrae solo le tre cose attese (nessun nome esterno a `staging`); `main.dart` chiama `applyPendingRestore` **prima** di aprire il DB. **Unione**: `mergeUserData` in una transazione, nessuna cancellazione.
- `lib/services/export/`: M3U8/CSV/JSON per playlist e «Esporta tutte» (zip). UI: Impostazioni → Backup (`backup_section.dart`, `restore_dialog.dart`).


## Prestazioni e fluidità (fase 28)
- **Ricerca online diretta**: `innertube_client.dart` (una richiesta POST all'API interna di YouTube e YouTube Music, con `X-Goog-FieldMask` per avere solo i campi letti; risposta vuota o illeggibile → di nuovo senza maschera) dietro `DirectSearchService`, che passa a yt-dlp tutto il resto e, se la risposta non si legge, anche la ricerca per 10 minuti (R70). `youtubeServiceProvider` = diretto, `ytDlpServiceProvider` = yt-dlp.
- **Elenchi leggeri**: `light_tracks.dart` — le query degli elenchi leggono tutte le colonne tranne testi, testi sincronizzati e curiosità, che nella riga valgono `''` (ci sono) o null (non ci sono); `lightSelect` riusa il SQL di una `select(tracks)` tipizzata. La riga intera solo da `getById`, `getByIds` e `watchById` (scheda, «In riproduzione», testi, backup, duplicati, condivisione).
- **Copertine**: miniatura PNG di 320 px (`<chiave>_t.png`) fatta in coda dopo ogni salvataggio e, per quelle vecchie, 5 s dopo il primo frame (`fillMissingThumbnails`); l'interfaccia legge un indice in memoria (`coverIndexProvider`: una lettura della cartella, poi gli eventi `CoverStore.changes`) e usa la miniatura sotto i 320 px. Cache delle immagini a 48 MB sui telefoni con ≤ 4,5 GB.
- **Ascolta**: `listenProvider` su un player suo (`AudioBackend.loadUri`), indirizzo da yt-dlp `-g` a ogni ascolto (`StreamSource`), nessuna cache su disco (R71).
- **Sfondo sfocato**: copia già sfocata (`blurredBackground`, ≤ 800 px) invece di un filtro a schermo.
- **Avvio**: dopo il primo frame la coda salvata, la ricezione LAN e il controllo aggiornamenti (`startupSettledProvider`), le miniature mancanti.
- **Microanimazioni**: `lib/ui/widgets/motion.dart` (`PressScale`, `EnterOnce`/`EntranceScope`, `TabFade`, `RiseIn`, `HeartIcon`, `popIn`); solo opacità e trasformazioni, `RepaintBoundary`, ferme con «Riduci animazioni».
- **Misure**: app separata `com.codecore.player.perf` (`CODECORE_PERF=1` + `--dart-define=CODECORE_PERF=true`) con `PerfProbe` (frame, primo frame, passi di `main`, scansione); `scripts/perf_library.py` e `scripts/perf_device.py`; risultati in `docs/fase-28-misure.md`.

## Catalogo YouTube Music (fase 30)
- **Catalogo** (`services/online/ytm_catalog.dart`, `YtmCatalog`; provider in `providers/ytm_catalog_providers.dart`): una richiesta InnerTube `browse` per pagina artista, pagina album, elenco «Brani più ascoltati» (fino a 100) e discografia, più la ricerca della **card artista** (`topArtist`: compare solo se il primo risultato di YouTube Music è un artista; `searchArtists` per la scelta fra più omonimi). Titoli delle sezioni e biografia arrivano da YouTube nella lingua dell'app (`hl`, `ytmLanguage`). La card vale anche con la fonte YouTube (richiesta separata a YouTube Music).
- **Lettura** (`ytm_artist_parser.dart`, `ytm_album_parser.dart`, modelli in `ytm_artist.dart`): per tipo di elemento e non per titolo (scaffale di brani, carosello di uscite, artisti simili, informazioni); una sezione mancante è una sezione nascosta; nessuna sezione «Video». Con maschera `X-Goog-FieldMask` e, se la risposta è vuota, di nuovo senza (come la ricerca, R70). Errori distinti: `ArtistNotFound`, `InnerTubeChanged`, rete.
- **Cache** (`catalog_cache.dart`, `CatalogCache`): un solo file `catalog_cache.json` (60 pagine, le meno usate escono per prime); durata di una copia: artista e brani 2 giorni, album e discografia 14. Una copia scaduta resta valida **fuori linea**: se la rete fallisce si mostra con l'avviso «Non in linea · dati del …» (`CatalogResult.stale`); «non trovato» non si salva mai. Compare in Memoria → Dati dell'app come «Catalogo online» e «Svuota cache» la elimina (si ricrea; la copia fuori linea si perde).
- **Pagine** (`ui/screens/online/`): `artist_page_screen.dart` (Nella tua libreria, Brani più ascoltati, uscite, artisti simili, Informazioni), `artist_songs_screen.dart`, `discography_screen.dart`, `online_album_screen.dart`, `artist_picker_sheet.dart`, `catalog_error_view.dart` (Riprova distinto per errore). «Ascolta» è il `listenProvider` della 28.6, condiviso: finisce quando si chiude l'ultima pagina online.
- **Album senza playlist visibile**: «Scarica album» è un'importazione (`PlaylistImportService.startFromResults`, ripresa e pause della fase 15), che richiede una playlist: se ne crea una tecnica con `playlist_imports.source_kind = 'ytm-album'` (`ytmAlbumSourceKind`). L'album compare in Libreria → Album, mai fra le playlist. La regola sta in **un solo punto**, `data/repositories/hidden_playlists.dart` (`visiblePlaylistSql(alias)`, `AppDatabase.visiblePlaylists()`), usata da: elenco playlist (`PlaylistRepository.watchAll`, quindi anche l'albero di Android Auto), backup portabile `user_data.json` (playlist **e** importazione), «Esporta tutte», sincronizzazione playlist fra dispositivi (`PlaylistSyncRepository`), Memoria per playlist. Il backup completo del database (VACUUM INTO) la conserva: è una riga come le altre. Chi aggiunge un nuovo elenco di playlist deve usare lo stesso helper.
- **Test**: parser su fixture in `test/fixtures/innertube/`; dal vivo `test/live/ytm_catalog_live_test.dart` (nightly).

## Elimina dal dispositivo
- **Voce di menu** «Elimina dal dispositivo» (`track_actions.dart`, `bulk_actions.dart`, comune: `delete_tracks.dart` con conferma distruttiva): cancella il **file** e poi la riga della libreria (playlist, preferiti, cronologia e tag spariscono a cascata). Solo musica (`kind = 0`): gli episodi hanno la loro pulizia.
- **Servizio** `services/library/track_deleter.dart` (`trackDeleterProvider`): 1) toglie i brani dalla coda con `CodecoreAudioHandler.removeTracks` (anche da `_source`, così «Svuota» non li ricrea; se suonava, carica il successivo e aspetta il ricaricamento: su Windows un file aperto non si cancella); 2) per ogni brano, file assente = già eliminato, altrimenti `File.delete`; 3) su Android i rifiuti per permesso (EPERM/EACCES: file non creati dall'app, Android 11+) vanno **in una sola chiamata** al `PlatformDeleter` (`MediaDeleteBridge.kt`, canale `codecore/media`, `MediaStore.createDeleteRequest` = un dialogo di sistema) e si ricontrolla il disco; 4) `TrackRepository.deleteTracks` toglie solo le righe dei file spariti (una transazione, a blocchi di 500). Un brano non cancellabile resta com'era e finisce nel rapporto con il motivo del sistema.
- «Duplicati → elimina i file»: su Android i file rifiutati da `File.delete` vanno, tutti insieme, a `duplicatePlatformDeleterProvider` (un solo dialogo) in `deleteMergedFiles`; si tolgono le righe solo dei file spariti.
- **Importazioni**: la riga di import del brano eliminato passa a `track_id = null` (`setNull`) ma il suo stato (scaricato/collegato) non cambia: riprendere un'importazione non lo riscarica. «Sincronizza da CSV» può riaggiungerlo.

## Da revisionare
- **Query** (`data/repositories/review_queries.dart`, `ReviewQueries`): musica (`kind = 0`, non `missing`, non `ignored`) con `enrichStatus` 1 o 2 (0 = mai provato, non compare) che ha trovato niente (2), oppure non ha testo (né `lyricsPlain` né `lyricsSynced`), copertina, album, anno o genere. Righe «leggere» (`lightSelect`); i motivi per riga li calcola `reviewReasons`. Stream per l'elenco e `watchCount` per la voce della Libreria.
- **«Va bene così»**: gli id sono nelle impostazioni (`reviewDismissed`, come `notDuplicates`) e arrivano alla query come `NOT IN`. Dopo un ripristino da backup gli id possono non coincidere: il brano torna nell'elenco, nessun danno.
- **«Riprova»** (`providers/review_providers.dart`, `ReviewActions.retry`): rimette `enrichStatus = 0` e avvia lo stesso lavoro di «Arricchisci» (`enrichJobProvider`, visibile nel centro Attività). Se un altro lavoro è in corso non cambia nulla (altrimenti i brani uscirebbero dall'elenco senza essere stati cercati). Un lavoro interrotto lascia a 0 i brani non ancora visti: tornano nell'elenco solo se un nuovo tentativo non trova nulla.
- **UI**: `ui/screens/library/review_screen.dart` (filtri per motivo, selezione come le altre liste, menu per riga: Cerca info sul web, Modifica info, Riprova, Va bene così); la voce «Da revisionare» compare nella Libreria solo se il conteggio è > 0.

## Memoria
- **Scheda**: quarta voce della barra in basso (`NavTab.memory`, icona `storage`) e, su desktop, ultima voce della barra laterale; ha il suo `Navigator` come le altre. `MemoryScreen` (`ui/screens/memory/`) non misura nulla finché la scheda non è mostrata la prima volta (l'`IndexedStack` costruisce tutte le schede all'avvio); poi rilegge i dati a ogni apertura della scheda e con il trascinamento verso il basso.
- **Query** (`data/repositories/memory_queries.dart`, `MemoryQueries`): tutto `GROUP BY` in SQL, nessun brano caricato per sommare. Contano i brani musicali (`kind = 0`) non `missing` (i nascosti occupano spazio e quindi contano, tranne in «Album più pesanti» e «Mai ascoltati», che mostrano solo ciò che l'utente vede). Per playlist (solo quelle visibili, con Preferiti, un brano in due playlist conta in entrambe), per formato (`lower(format)`), per cartella radice (`folder_id`, i brani senza cartella in una riga a parte), top 10 brani e album, «mai ascoltati» = nessuna riga in `plays`, `play_count = 0`, `last_played_at` nullo. I totali sono uno stream (`memoryTotalsProvider`), il resto un `FutureProvider` (`memoryBreakdownProvider`) invalidato dalla pagina. `albumSummaryFromRow` e `albumSelectSql` (ora con `size_bytes`) sono condivisi con `LibraryQueries`.
- **Spazio del dispositivo** (`services/memory/disk_space.dart`): Android `StatFs` dal canale `codecore/storage` (`StorageBridge.kt`), Linux `df -B1 --output=size,avail <cartella>` (`parseDf`), Windows nulla (la barra «musica · altro · libero» non compare). Il volume è quello della cartella radice con più musica.
- **Dati dell'app** (`services/memory/app_data.dart`, `dir_size.dart`): le cartelle si percorrono in un isolate (`Isolate.run`, senza seguire i collegamenti); le dimensioni sono copertine (+ miniature `_t.png`), database (+ `-wal`/`-shm`), immagini in memoria (`ImageCache`: la RAM, non il disco), cache Jam, cache delle ricerche (`search_cache.json`), catalogo online (`catalog_cache.json`), copie sfocate dello sfondo (`blurredCopyPattern`), backup dei tag, registro (+ `.1`) ed episodi dei podcast (somma SQL dei brani `kind = 1`).
- **«Svuota cache»** (`CacheCleaner`, `MemoryActions.clearCaches`): tocca solo `clearableKinds` = immagini in memoria, cache Jam, cache delle ricerche (`SearchCache.clear`), catalogo online (`CatalogCache.clear`), copie sfocate (`deleteBlurredCopies`: solo `bg-*-blur<n>.png`, le foto restano). Mai copertine, database, backup dei tag, podcast. La cache Jam non si tocca mentre una Jam è attiva. Conferma prima, poi un avviso con lo spazio liberato.
- **«Mai ascoltati»** (`never_played_screen.dart`): elenco con selezione (`SelectableAppBar`), quindi le azioni di gruppo, «Elimina dal dispositivo» compreso (`confirmAndDeleteTracks`).
