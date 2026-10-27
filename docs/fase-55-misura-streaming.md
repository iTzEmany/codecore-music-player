# Fase 55 — Misura dello streaming

**Obiettivo:** sapere dove vanno i 25 s fra il tap su un brano online e il primo suono. Ogni brano preparato scrive in
`codecore.log` una riga con i tempi di ogni pezzo (avvio di yt-dlp, download, post-elaborazione, spostamento in cache,
tap → primo suono), e uno script ne stampa mediana e massimo. Si prova col vero yt-dlp che l'URL si può avere prima del
download e che si ascolta per 30 s. Si scrive la tabella «Prima» su Linux, Mi A3 e Motorola (se è collegato). Il
comportamento per l'utente non cambia.

**Prerequisiti:** fasi 45–47 (`StreamPreparer`, `StreamCache`, ramo stream di `_loadCurrent`), fase 54 chiusa.

**Riferimenti:** `docs/feature-streaming-veloce.md` (R-68, R-69, R-70; componenti `StreamPreparer` e `scripts/stream_times.py`;
«Dati»; rischi K-SV-01, K-SV-03, K-SV-05); decisioni D-138, D-144, D-146.

**Intoccabili:** il percorso di riproduzione (si aggiungono solo misure); formato, argomenti e post-elaborazione di
yt-dlp; `StreamCache`. **Nessun pacchetto nuovo. Schema invariato.**

## Task

### 55.1 — Cronometro nel preparer
**File:** `lib/services/stream/stream_preparer.dart`, `test/services/stream/stream_preparer_test.dart`
1. Il `_Job` tiene un cronometro (orologio iniettabile per i test, come `DateTime.now` altrove nel preparer) dalla
   partenza di `_download`. Voci: `spawn` (primo evento di avanzamento o prima riga di output), `downloaded` (avanzamento
   al 100 % o file trovato), `post` (fine del processo, cioè fine di ffmpeg), `cached` (fine di `cache.put` e della riga
   ombra). Ogni voce è in ms dall'inizio.
2. A fine job, riuscito o no, una riga `AppLog.i` con prefisso fisso: `stream timing key=<key> requested=<0|1>
   attempt=<n> spawn=<ms> downloaded=<ms> post=<ms> cached=<ms> result=<ok|failed|dropped>`. Voci mancanti: `-`.

R-68 (parte del preparer).
**Fatto quando:** `flutter test test/services/stream/stream_preparer_test.dart` verde, con un test che usa un
`YoutubeService` finto e un orologio finto e controlla la riga (voci nell'ordine, `-` per quelle mancanti su un errore).
`flutter analyze` pulito.

### 55.2 — Tap → primo suono nell'handler
**File:** `lib/services/audio/codecore_audio_handler.dart`, `test/services/audio/online_playback_test.dart`
1. Nel ramo stream di `_loadCurrent`, cronometro dal momento in cui si sceglie il brano fino al primo stato «in
   riproduzione» con la posizione che avanza.
2. Riga `stream timing key=<key> play=<ms> from=<cache|file|url>` (oggi solo `cache`; `url` arriva con la fase 56). Una
   riga anche per i brani in libreria, con `from=file`, per avere il confronto.

R-68 (parte del player).
**Fatto quando:** `flutter test test/services/audio/online_playback_test.dart` verde, con un test sulla riga `play=`
(backend finto che passa a «in riproduzione»). `flutter analyze` pulito.

### 55.3 — `scripts/stream_times.py`
**File:** `scripts/stream_times.py` (nuovo)
1. Legge `codecore.log` da un file (`--log <percorso>`) o dal telefono (`--adb <serial>`, con `adb exec-out run-as
   com.codecore.player cat …`; il percorso è quello di `AppLog`/`log_export.dart`).
2. Stampa una tabella in Markdown: per ogni voce (`spawn`, `downloaded`, `post`, `cached`, `play` divisa per `from`),
   numero di brani, mediana e massimo sugli ultimi `--last N` (di serie 10). Righe malformate ignorate e contate.
3. `--self-test`: un log d'esempio dentro lo script, con `assert` sui numeri.

R-69.
**Fatto quando:** `python3 scripts/stream_times.py --self-test` verde; su un log reale di Linux stampa la tabella.

### 55.4 — Prova dell'URL col yt-dlp vero (solo misura)
**File:** sezione «Prova dell'URL» in questo documento (nessun codice dell'app)
1. Su Linux, con gli stessi argomenti di `buildDownloadArgs` più `--print before_dl:…%(urls)s` e
   `--print before_dl:…%(http_headers)j`: l'URL arriva prima del download? L'avanzamento si vede ancora (`--print`
   implica `--quiet`: provare `--progress`/`--newline`)? Tempo fino all'URL. Annota il comando esatto (K-SV-05).
2. Con l'URL e gli header, 30 s di ascolto con `mpv --http-header-fields=…` (o `ffplay -headers`), poi un seek all'80 %,
   mentre yt-dlp sta scaricando: nessun 403? (K-SV-01). Se il client di serie dà 403, provare
   `--extractor-args youtube:player_client=android_vr` e annotare il risultato.
3. Sul Mi A3 con l'app: con una build di debug, controllare che il callback di youtubedl-android riceva le righe di
   `--print` (log del lato Kotlin) e annotare il tempo dall'avvio del processo alla riga dell'URL. Nessun cambio di
   comportamento in `YtDlpChannel.kt`: se serve codice per la prova, resta in un ramo locale e non entra nella PR.

**Fatto quando:** la sezione «Prova dell'URL» qui sotto ha, per Linux e Mi A3: comando, tempo fino all'URL, avanzamento
sì/no, 30 s di ascolto sì/no, seek sì/no, client usato.

### 55.5 — Tabella «Prima» (R-70)
1. Build di debug su Linux, Mi A3 e Motorola (se collegato, con le regole del profilo: backup prima, `install -r`).
2. Su ognuno, 10 brani online mai ascoltati (cache vuota per quei brani), su Wi-Fi, dalla ricerca: tap, ascolto fino al
   primo suono, brano dopo. Poi `scripts/stream_times.py`.
3. Tabella «Prima» qui sotto, con data, dispositivo, versione di yt-dlp e rete. Se su Android `spawn` supera 4 s si
   prosegue lo stesso (D-146): annotalo in «Note».

**Fatto quando:** la tabella «Prima» ha le righe di Linux e Mi A3 (e Motorola se collegato), con le voci di R-68.

### 55.6 — Controlli di fase
`flutter analyze` pulito; test toccati verdi; test esistenti di `test/services/stream/` e di
`test/services/audio/online_playback_test.dart` e `gapless_handler_test.dart` verdi; nessun cambio di comportamento nel
diff (revisione: solo righe di log, cronometri e lo script). Spunta in `docs/PROGRESS.md`.

## Prova dell'URL
<!-- 55.4: da riempire -->

## Tabella «Prima»
<!-- 55.5: da riempire -->

## Note
