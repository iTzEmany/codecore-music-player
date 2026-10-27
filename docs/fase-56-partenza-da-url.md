# Fase 56 — Partenza dall'URL

**Obiettivo:** un brano online non in cache parte appena yt-dlp stampa l'URL del flusso, con `loadUri` e gli header che
dà yt-dlp, mentre lo stesso processo continua il download in cache come oggi. Se l'URL non funziona si torna ad
aspettare il file; se scade a metà (anche per un cambio di rete) si riprende dalla posizione. Vale per ricerca,
Shuffle+, album online e coda online; la Jam resta com'è.

**Prerequisiti:** fase 55 chiusa (cronometri, script, «Prova dell'URL» con il comando che funziona).

**Riferimenti:** `docs/feature-streaming-veloce.md` (R-71…R-78, R-82, R-84, R-85; componenti `yt_dlp_args.dart`,
`DownloadProgress`, `YtDlpProcessService`, `YtDlpChannel.kt`, `StreamPreparer`, `_loadCurrent`, errore a metà; flussi 1 e
3; invarianti 1–5; rischi K-SV-01, K-SV-04, K-SV-05, K-SV-07, K-SV-08); decisioni D-138…D-141, D-144, D-145.

**Intoccabili:** formato, selettore e post-elaborazione del download; `StreamCache` e i pin; righe ombra e arricchimento;
Jam (`jam_providers.dart`, `jam_online_adder.dart`: sempre `ready()`); flavor lite; i brani in libreria. Niente a
schermo di nuovo (R-78). Gapless e crossfade restano spenti per gli stream (si accendono nella fase 57). **Nessun
pacchetto nuovo. Schema invariato.**

## Task

### 56.1 — L'URL dalle righe di yt-dlp (desktop)
**File:** `lib/services/online/yt_dlp_args.dart`, `lib/services/online/youtube_service.dart` (`DownloadOptions`,
`DownloadProgress`), `lib/services/online/yt_dlp_process_service.dart`, `test/services/online/yt_dlp_args_test.dart`,
`test/services/online/yt_dlp_process_test.dart`
1. `DownloadOptions.emitStreamUrl` (di serie `false`): aggiunge a `buildDownloadArgs` le due righe `--print before_dl:`
   marcate (prefissi fissi, per esempio `CODECORE_URL ` e `CODECORE_HDR `) più ciò che la 55.4 ha mostrato servire per
   l'avanzamento.
2. `DownloadProgress` ha `streamUrl` e `headers` (nullable). `YtDlpProcessService.download` riconosce le righe marcate ed
   emette un evento con l'URL una volta sola; una riga mancante o rotta = nessun evento (K-SV-07). Un URL con più
   indirizzi (`urls` con `\n`): solo il primo, ed è un URL `https`.

R-71 (desktop).
**Fatto quando:** `flutter test test/services/online/yt_dlp_args_test.dart test/services/online/yt_dlp_process_test.dart`
verde: argomenti presenti solo con l'opzione; righe marcate → un evento con URL e header; riga marcata rotta → nessun
evento e download che finisce come oggi. Prova su Linux col vero yt-dlp: riga `CODECORE_URL` nel log prima della fine.

### 56.2 — L'URL dal canale Android
**File:** `android/app/src/full/kotlin/com/codecore/player/YtDlpChannel.kt`,
`lib/services/online/android_yt_dlp_service.dart`
1. Il lato Kotlin passa le stesse opzioni (`emitStreamUrl` nel dizionario del metodo `download`) e, nel callback di
   youtubedl-android, inoltra le righe marcate a Dart nel campo `line` dell'evento `progress` che esiste già (nessun
   metodo nuovo: decisione presa durante la fase, il probe 55 ha mostrato che le righe arrivano già così).
2. `AndroidYtDlpService` le trasforma nello stesso evento della 56.1. Lite: nessun cambio.

R-71 (Android).
**Fatto quando:** `flutter build apk --debug` riuscito; sul Mi A3 un brano dalla ricerca scrive nel log l'URL prima della
fine del download; `flutter analyze` pulito.

### 56.3 — `StreamPreparer.start()`
**File:** `lib/services/stream/stream_preparer.dart`, `test/services/stream/stream_preparer_test.dart`
1. I download del preparer usano `emitStreamUrl: true`. Il `_Job` tiene l'ultimo URL ricevuto con gli header, l'ora e
   la scadenza letta da `expire=` (se manca: ora + 5 h).
2. `start(key, r)` restituisce un `StreamStart` (file oppure URL con header): il file se è in cache; altrimenti segna il
   job come richiesto (come `ready`) e restituisce il primo fra URL non scaduto e file. `ready()` resta com'è per i suoi
   chiamanti.
3. `restart(key)` per l'URL scaduto: file se pronto; altrimenti, se il job è ancora in corso, lo annulla e lo riavvia, e
   restituisce il nuovo URL (o il file, se arriva prima). Il cronometro della 55.1 aggiunge la voce `url`.

R-71, R-73, R-74, R-76 (parte del preparer).
**Fatto quando:** `flutter test test/services/stream/stream_preparer_test.dart` verde: cache presente → file senza
avviare yt-dlp; URL prima del file → URL; file prima dell'URL → file; URL scaduto → `restart` con file pronto → file;
senza file → nuovo job e nuovo URL; la riga di tempi ha `url=`.

### 56.4 — Il player parte dall'URL
**File:** `lib/services/audio/codecore_audio_handler.dart`, `test/services/audio/online_playback_test.dart`
1. Nel ramo stream di `_loadCurrent`: `start()`; URL → `loadUri(url, headers)` (R-72); file → `load(file)` come oggi.
   L'handler ricorda che il brano in corso suona dall'URL.
2. `loadUri` che fallisce (o URL che non arriva prima del file): si aspetta `ready()` e si carica il file, senza
   messaggio d'errore (R-75); riga `stream timing … fallback=<motivo>`.
3. Durata nel `MediaItem`: quella del backend, con la durata di `YtResult` come ripiego finché il flusso non la dà
   (K-SV-08).
4. La riga `play=` della 55.2 scrive `from=url`.

R-72, R-73, R-75, R-82, R-84, R-85 (parte del codice).
**Fatto quando:** `flutter test test/services/audio/online_playback_test.dart` verde: URL emesso → `loadUri` con URL e
header, nessun `load(file)`; `loadUri` che lancia → `load(file)` dopo `ready()`, nessun errore all'utente; rete a
consumo → stesso comportamento; Shuffle+ e album online passano dallo stesso ramo (un test per l'entrata Shuffle+).

### 56.5 — URL scaduto e cambio di rete
**File:** `lib/services/audio/codecore_audio_handler.dart`, `test/services/audio/stream_expired_test.dart`
1. Un errore di riproduzione sul brano che suona dall'URL, con `BackendException.expired` (o un errore di rete del
   flusso): posizione P salvata; `preparer.restart(key)`; file → `load(file)` + seek P; URL → `loadUri` + seek P (un solo
   tentativo); se fallisce ancora → `ready()`, `load(file)`, seek P (R-76, D-145).
2. In pausa non si fa niente finché non si preme play: il controllo avviene alla ripresa.

R-76.
**Fatto quando:** `flutter test test/services/audio/stream_expired_test.dart` verde con i tre casi del criterio di R-76.

### 56.6 — Controlli di fase (K-SV-01, K-SV-04, K-SV-05)
`flutter analyze` pulito; test toccati verdi; test esistenti verdi: `test/services/stream/`,
`test/services/audio/` (in particolare `gapless_handler_test.dart`, `crossfade_engine_test.dart`,
`radio_playback_test.dart`), test della Jam (`test/jam/`, `test/providers/play_online_jam_test.dart`, `test/providers/jam_seed_test.dart`) e
`stream_promoter_test.dart` (R-86). Revisione del diff: nessun `loadUri` con URL di YouTube nei file della Jam (R-83);
nessun widget nuovo (R-78). Tabella «Dopo 56» con `stream_times.py` su Linux e Mi A3 (Motorola se collegato): 10 brani
come nella 55.5. Spunta in `docs/PROGRESS.md`.

### 56.7 — Prove a mano
Su Linux e sul Mi A3 (Motorola se collegato): tap dalla ricerca → suono in pochi secondi; seek all'80 % appena partito →
riprende con il buffering (R-77); notifica con durata e seek (R-85); Wi-Fi spento a metà brano sul telefono → riprende
dalla posizione (R-76, K-SV-04); secondo ascolto dello stesso brano → `from=cache` nel log (R-73); «Scarica» durante
l'ascolto → il file arriva in libreria (R-86).

## Tabella «Dopo 56»
<!-- 56.6: da riempire -->

## Note
