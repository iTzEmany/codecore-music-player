# Rischi noti e piano B

Per ogni rischio: **sintomo** → **cosa fare**. Se scatta un fallback che cambia lo stack, fermati e chiedi all'utente.

| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R1 | `audio_metadata_reader` non legge bene un formato (durata/bitrate/cover) | durata 0, cover assente su certi file | Tieni `TagReader` come interfaccia. Prova `metadata_god` (Rust, richiede cargo — già installato) o `audiotags`. Per la durata: usa la durata che riporta il player al primo caricamento e salvala nel DB. |
| R2 | Su Android l'elenco di `/storage/emulated/0/Music` risulta vuoto pur con permesso | scansione = 0 file | 1) controlla che il permesso sia `audio` (API 33+). 2) prova una cartella scelta con `file_picker`. 3) fallback: `on_audio_query` (o fork mantenuto) per leggere da MediaStore e salvare il percorso restituito. |
| R3 | `just_audio_media_kit` non funziona su Windows/Linux | silenzio o crash all'avvio audio | Verifica `libmpv` (Linux: `libmpv-dev`). Alternative dietro `AudioBackend`: `media_kit` diretto, oppure `audioplayers` (meno controllo). |
| R4 | `audio_service` non supporta il desktop | eccezione su `AudioService.init` | Già previsto: su desktop non si chiama `init`, si usa il handler diretto. |
| R5 | `youtube_explode_dart` si rompe (YouTube cambia) | errori su manifest/stream | Aggiorna il pacchetto (`flutter pub upgrade youtube_explode_dart`). Se persiste: spegni la funzione con `kEnableYoutube=false`; alternativa fuori dall'app: `yt-dlp` da riga di comando. |
| R6 | Windows non compilabile da Linux | `flutter build windows` non disponibile | Compila su una macchina Windows (o CI GitHub Actions `windows-latest`). Sviluppa e testa tutto su Linux + Android. |
| R7 | Prima scansione molto lenta (10k+ file, chiavetta USB) | minuti | È normale la prima volta: scansione in isolate con progresso; la successiva è incrementale. Riduci i blocchi per isolate se la memoria sale. |
| R8 | Android ammazza il servizio in background (risparmio batteria) | musica si ferma a schermo spento | Guida utente: escludere l'app dall'ottimizzazione batteria; verifica `foregroundServiceType=mediaPlayback` e `androidStopForegroundOnPause`. |
| R9 | `drift` + codegen lento o conflitti | build_runner fallisce | `dart run build_runner build --delete-conflicting-outputs`; se persiste `flutter clean` e rigenera. |
| R10 | Scritture tag non supportate | l'utente vuole i tag modificati nel file | Fuori scope v1 (decisione presa). In futuro: `audiotags`/`metadata_god` su copia temporanea + `rename` atomico, mai in-place. |
| R11 | Percorsi Android non-latini / molto lunghi | file non trovato | Usa sempre `File(path)` senza ricostruire stringhe; logga il percorso esatto; non applicare `sanitizeFileName` a percorsi esistenti, solo a nomi nuovi. |
| R12 | Lingua/ARB: chiavi mancanti | `null` in UI | `flutter gen-l10n` fallisce se manca una chiave nel template: tenere `app_it.arb` come template e allineare le altre. |

## Limiti accettati nella v1
- Niente crossfade, niente "bit-perfect/esclusivo", niente equalizzatore (Android: eventuale in fase 7).
- Niente traduzione automatica di testi/curiosità.
- Niente Android Auto.
- Niente scrittura dei tag nei file.
- Condivisione LAN solo HTTP con PIN (non cifrata).

## Jam (fase 8)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R13 | Il proprietario di un brano esce dalla rete | Il brano non parte / si interrompe | Precarico in cache del brano successivo; altrimenti salto con avviso |
| R14 | Android ferma l'app in background (Doze, risparmio energetico) | La Jam si interrompe a schermo spento | Servizio in primo piano con notifica «Termina»; guida utente: escludere dall'ottimizzazione batteria |
| R15 | Deriva tra stato e posizione di ascolto | Il telecomando mostra una posizione diversa | Soglia di correzione 1,5 s; nessuna promessa di sincronia (la riproduzione sincronizzata è fuori scope) |
| R16 | Reti con isolamento dei client o sottoreti diverse | Nessun dispositivo trovato | Messaggio chiaro; collegamento manuale (IP:porta) come fallback |
| R17 | Scarto udibile tra uscite sincronizzate (Wi‑Fi irregolare, Bluetooth) | Eco o «effetto flanger» | Cache completa prima dell'avvio, correzione continua, compensazione manuale della latenza; fallback a uscita singola |
| R18 | Orologio dell'host che salta (NTP, sospensione) | Tutte le uscite si riallineano di colpo | Differenze su orologio monotono, rinnovo periodico dell'offset, isteresi sulle correzioni |

## Importazione da CSV (fase 12)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R19 | `yt-dlp` di sistema troppo vecchio (< 2025.11: niente `--js-runtimes`, «Please sign in») | ricerca/download falliscono con «YouTube ha cambiato qualcosa» | Desktop: Impostazioni → Download → **Aggiorna** (fase 14: binario ufficiale con controllo SHA-256, il vecchio resta `.old`); in alternativa `pip install -U yt-dlp`. Su Android si aggiorna da solo |
| R20 | YouTube risponde 429 / «Sign in to confirm you're not a bot» a molte ricerche di fila | importazione in pausa con avviso «YouTube ha chiesto di rallentare» | Una ricerca alla volta con 1,5 s di pausa; aspettare qualche minuto e «Riprendi» |
| R21 | 403 transitorio sul flusso audio | un brano «con errori» in mezzo a un'importazione | Ritento a scalare nella coda dei download (5/20/60 s, solo errori transitori, fase 14); poi «Riprova tutti» nella schermata «Rivedi» |
| R22 | Exportify cambia nome o ordine delle colonne | «Questo file non sembra un CSV di Exportify» | Le colonne si riconoscono dall'intestazione (`Track Name`, `Artist Name(s)`, `Duration (ms)`…); aggiungere i nuovi nomi in `exportify_reader.dart` |
| R23 | Brano sbagliato scelto con sicurezza (versione live, cover, durata diversa) | nella playlist suona un'altra versione | Soglia 0,80 e durata come criterio principale; i casi dubbi vanno in «Da verificare»; «Cerca a mano» per correggere |

## Download robusti (fase 14)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R27 | Binario yt-dlp scaricato compromesso o troncato | yt-dlp non parte o fa altro | Solo HTTPS da GitHub, SHA-256 contro `SHA2-256SUMS` della stessa release, rinomina atomica, il precedente resta come `yt-dlp.old` (rinominalo per tornare indietro) |
| R28 | Più download insieme → più 403/429 | Righe «con errori» o importazione in pausa | Predefinito 2 (massimo 3); ricerche sempre una alla volta; ritento a scalare con jitter; `rateLimited` mette in pausa; abbassare «Download contemporanei» a 1 |
| R29 | Formato «originale» non leggibile da tag reader o player | Durata 0 o brano che non parte | Spento di default (MP3); se manca m4a si ottiene opus/webm (estensioni già scansionate); riattivare MP3 e riscaricare |
| R30 | Cache delle ricerche con risultati vecchi (video rimosso) | Si propone un video non più disponibile | Scadenza 30 giorni; un download `unavailable` cancella le voci della riga; «Svuota cache ricerche» nelle Impostazioni |
