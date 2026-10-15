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
- [ ] 11.2 Token, tema e font
- [ ] 11.3 Componenti base
- [ ] 11.4 Correzioni rapide
- [ ] 11.5 Shell: tre schede e navigatore annidato
- [ ] 11.6 Colore dalla copertina
- [ ] 11.7 Mini-player e foglio Dispositivi
- [ ] 11.8 Now Playing
- [ ] 11.9 Desktop: barra laterale, barra player, pannello destro
- [ ] 11.10 Libreria e «Tutti i brani»
- [ ] 11.11 Pagine di raccolta: album, artista, playlist, Preferiti
- [ ] 11.12 Home
- [ ] 11.13 Cerca (con YouTube)
- [ ] 11.14 Coda, Testi, menu del brano
- [ ] 11.15 Jam
- [ ] 11.16 Centro Attività
- [ ] 11.17 Impostazioni, Condivisione, dialoghi
- [ ] 11.18 Rifinitura e controlli finali
- [ ] 11.19 Prova a mano (utente)

## Note di deviazione
<!-- una riga per deviazione: data — task — cosa è cambiato e perché -->

## Note di deviazione
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
