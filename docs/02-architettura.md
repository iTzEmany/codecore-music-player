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
| Notifica / lock screen | `audio_service` | non nella v1 (opzionale fase 7) |
| Permessi file | `READ_MEDIA_AUDIO` (+ `READ_EXTERNAL_STORAGE` ≤ API 32) | nessuno |
| Cartella musica predefinita | `/storage/emulated/0/Music` | `~/Music` (Linux), `%USERPROFILE%\Music` (Windows) |
| Cartella download | `getExternalStorageDirectory()/Music` (nessun permesso) | cartella musica scelta |
| Scelta cartella | `file_picker.getDirectoryPath()` | idem |

## Decisioni già prese (non rimetterle in discussione)
- Tag **solo in lettura** (`audio_metadata_reader`, puro Dart, nessun Rust). Le modifiche dell'utente vivono nel DB.
- Identità brano = `id` intero DB + `path` univoco. Hash SHA-256 calcolato **solo** su richiesta (condivisione).
- Album raggruppati con `albumKey` (vedi `03-modello-dati.md`), non per solo nome.
- Niente gapless/crossfade/"bit-perfect" nella v1: coda gestita a mano. Gapless in fase 7.
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
- **Navigazione:** tre schede (`NavTab.home|search|library`), ciascuna con un `Navigator` annidato (chiavi in
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

## CI e test (fase 16)
- **GitHub Actions** (`.github/workflows/`): `ci.yml` — job `check` (codice generato e l10n aggiornati, `flutter analyze`, `flutter test`) su ogni push/PR; `build-android`, `build-linux`, `build-windows` solo su tag `v*` o avvio manuale, con artefatti; il job Windows esegue anche la suite. `nightly.yml` — test `test/live/` con yt-dlp fissato e verificato, riepilogo di quali sorgenti rispondono (informativo). `deps.yml` — rapporto settimanale delle dipendenze (nessun aggiornamento automatico).
- **Test:** `test/` (unitari e widget, ermetici: né rete né file fuori dal repo), `test/goldens/` (20 schermate, solo Linux, comparatore al 0,5 %, `coverImageStub`), `test/live/` (dietro `CODECORE_LIVE=1`), `test/data/performance*_test.dart` (budget a 20.000 e 50.000 brani). `integration_test/` (telefono/Linux) arriva con il pacchetto `integration_test` (da approvare).
- **Banco visivo:** `test_shots/` + `scripts/shots.sh` per guardare le schermate; i golden riusano il suo `withShot`.

