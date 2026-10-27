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
### Linux (2026-10-27)
Client: yt-dlp 2026.08.19 (`~/.local/bin/yt-dlp`), `--js-runtimes node`, client di serie (URL con `c=VISIONOS`, itag 251).
Comando: gli argomenti di `buildDownloadArgs` (formato originale, con ffmpeg) più `--progress` e due `--print`:
```
yt-dlp --no-playlist --no-warnings --newline --no-part \
  --progress-template 'download:PROG %(progress.downloaded_bytes)s %(progress.total_bytes)s %(progress.total_bytes_estimate)s' \
  --js-runtimes node --progress -f 'bestaudio/best' -x \
  --print 'before_dl:URLMARK %(urls)s' --print 'before_dl:HDRMARK %(http_headers)j' \
  -o '<stem>.%(ext)s' 'https://www.youtube.com/watch?v=<id>'
```
- URL prima del download: sì. Le righe `URLMARK` e `HDRMARK` escono prima di ogni `PROG`.
- Tempo fino all'URL (dall'avvio): 4,05 s (dQw4w9WgXcQ), 4,33 s (9bZkp7q19f0).
- Avanzamento: sì. Con `--progress` e `--progress-template` le righe `PROG` arrivano come prima.
- Ascolto: `mpv --ytdl=no --no-video --volume=20 --http-header-fields=<User-Agent, Accept, Accept-Language, Sec-Fetch-Mode> --length=30 <url>`, con yt-dlp ancora in download (prova con `--limit-rate 200K`, finiva a 21-24 s).
- 30 s di ascolto: sì, su entrambi i brani. Nessun 403.
- Seek all'80 %: sì (`--start=80%`, nuova richiesta con lo stesso URL), nessun 403, parte a 2:57 su 3:33 e a 3:28 su 4:12.
- Senza `--limit-rate` il download di 3,4 MB finisce in 0,4 s dopo l'URL: la prova «mentre scarica» ha senso solo con il limite.
- Client usato: quello di serie (visionos). `android_vr` non serve, non provato.
- Nota: la prima prova senza `--ytdl=no` e con header incompleti ha dato 403 (mpv passava l'URL a yt-dlp). Non è un 403 di YouTube.

### Mi A3 (0d7ae9df206e): non eseguita, il telefono non ha rete
- Il callback di `YtDlpChannel.kt` riceve già ogni riga (`progress, _, line`) ma la gira solo a Dart con `invokeMethod("progress", ... "line")`: nessun log Kotlin delle righe.
- Costruito (ramo locale, non nella PR) un APK con `Log.i("probe55", ...)` col tempo dall'avvio e i due `--print` (`CODECORE_PERF=1 flutter build apk --debug --target-platform android-arm64 --build-number 55`), installato come `com.codecore.player.perf` con `install -r -d`.
- Il telefono non ha rete: Wi-Fi acceso ma non connesso, dati mobili spenti (`Network is unreachable`, ping fallito). Nessuna impostazione toccata.
- Mancano quindi: tempo fino all'URL, avanzamento, ascolto, seek, client. Da rifare con il telefono su Wi-Fi.
- Worktree e build di prova eliminati. Sul Mi A3 resta l'app `.perf` con la riga di log e i `--print` (da sostituire in 55.5).

## Tabella «Prima»
Build di debug di questo ramo (`flutter build apk --debug --target-platform android-arm64`, `flutter build linux --debug`). 10 brani online mai ascoltati per dispositivo, scelti dalla ricerca (Online), tap, primo suono, brano dopo. Tempi in ms, mediana / massimo, da `python3 scripts/stream_times.py`.

| Data | Dispositivo | yt-dlp | Rete | spawn | downloaded | post | cached | play (cache) |
|---|---|---|---|---|---|---|---|---|
| 2026-10-27 | Motorola edge 40 `ZY22HKD85K` | 2026.10.26 | dati mobili (Wi-Fi spento) | 3647 / 4041 | 21894 / 25144 | 22964 / 26289 | 23041 / 26355 | 23303 / 26626 |
| 2026-10-27 | Mi A3 `0d7ae9df206e` | 2026.10.21 | Wi-Fi: hotspot del Motorola (dati mobili), ping 637 ms | 6207 / 11857 | 38675 / 43146 | 40238 / 44952 | 40352 / 45119 | 41181 / 46421 |
| 2026-10-27 | Linux | 2026.08.19 | Wi-Fi di casa | da rifare (display isolato non disponibile) | | | | |

Motorola (`--adb ZY22HKD85K`):

| metric | n | median ms | max ms |
|---|---|---|---|
| spawn | 10 | 3647 | 4041 |
| downloaded | 10 | 21893.5 | 25144 |
| post | 10 | 22963.5 | 26289 |
| cached | 10 | 23040.5 | 26355 |
| play (cache) | 10 | 23303 | 26626 |
| play (file) | 1 | 114 | 114 |
| play (url) | 0 | - | - |

Mi A3 (`--log` sul log filtrato, vedi Note):

| metric | n | median ms | max ms |
|---|---|---|---|
| spawn | 10 | 6207 | 11857 |
| downloaded | 10 | 38674.5 | 43146 |
| post | 10 | 40238 | 44952 |
| cached | 10 | 40351.5 | 45119 |
| play (cache) | 10 | 41180.5 | 46421 |
| play (file) | 0 | - | - |
| play (url) | 0 | - | - |

Linux, parziale (solo 4 brani, non 10; prova fatta sul display dell'utente, poi sospesa): spawn 4006 / 4092, downloaded 4242 / 5094, post 4823 / 5653, cached 4983 / 5776, play (cache) 5270 / 5935. Non è la riga ufficiale.


## Note
- Linux: da rifare. Il display isolato non è risultato pilotabile (gnome-shell headless: Xwayland senza risposta a xdpyinfo; Xvfb non installato) e l'utente sta lavorando sul suo unico schermo. Servono Xvfb o una sessione dedicata.
- Rete: il Motorola aveva il Wi-Fi spento (misura su dati mobili); il Mi A3 era sul suo hotspot. Nessuna delle due righe è «Wi-Fi di casa»: da ripetere su Wi-Fi vero per un confronto pulito.
- D-146: `spawn` supera 4 s su Android. Motorola 3,6 s (max 4,0 s, al limite); Mi A3 mediana 6,2 s, max 11,9 s (il primo brano, a freddo). Si prosegue lo stesso.
- Su Android il costo è il download: `downloaded` 22 s sul Motorola e 39 s sul Mi A3, contro 4,2 s su Linux. Post-elaborazione (ffmpeg) ~1,1-1,5 s, `cached` +0,1 s, `play` +0,3-1,0 s dopo `cached`: il primo suono arriva solo a download finito, come previsto dalla fase 56.
- Mi A3, prima prova con `com.codecore.player.perf` (probe55, yt-dlp 2026.10.26): URL e header arrivano dopo 38,9 s dall'avvio del processo (`URLMARK` a T+38881 ms, `HDRMARK` a T+38894 ms), cioè prima del download; nello stesso brano `spawn`=51,9 s, `downloaded`=54,2 s. Il probe logga solo le righe `URLMARK`/`HDRMARK`, quindi l'avanzamento non si vede nel logcat: non verificato. Ascolto 30 s e seek sul telefono: non provati. Rete: hotspot del Motorola, che pesa molto sul tempo.
- Dubbio da verificare: tra l'avvio di `_download` (spawn) e l'URL ci sono ~13 s sul Mi A3 prima del processo (possibile `ensureInit()` con l'aggiornamento di yt-dlp a ogni chiamata, vedi `docs/gotchas.md`).
- Mi A3: 4D7u5KF7SP8 (Get Lucky) era già nella cache di streaming del telefono (play=577 ms, senza riga del preparer). Tolta dal log (`grep -v`) e sostituita da un undicesimo brano (Happy); la tabella usa il log filtrato.
- Motorola: la riga `play (file)` è un brano di libreria che la coda ha avviato da sola dopo il primo brano online. Volume musica 9/15 (altoparlante) com'era; il tentativo di abbassarlo con `cmd media_session` non ha funzionato, quindi le prove sono suonate al volume dell'utente. Riportato a 9 con i tasti. Non disturbare messo a `priority` solo durante la prova, poi `off`. Installato solo con `install -r`, nessun problema di firma.
- Mi A3: installato con `install -r` il debug di questo ramo come `com.codecore.player` (era 1.3.0). Resta anche `com.codecore.player.perf` (non rimossa). Volume musica già a 1/15, non toccato. Non disturbare `off` a fine prova.
- Script: il percorso `files/codecore.log` e `--adb` funzionano sul Motorola e sul Mi A3, nessuna correzione necessaria. Il Mi A3 è stato letto con `--log` per poter togliere la riga della cache.
- Brani usati: Blinding Lights (solo Motorola/Linux), Mr Brightside, Rolling in the Deep, Uptown Funk, Hey Ya!, Viva la Vida, Seven Nation Army, Shape of You, Crazy in Love, Get Lucky (Motorola), Somebody That I Used to Know e Happy (Mi A3). Controllati prima con «Nessun risultato in libreria».
