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
- Niente "bit-perfect/esclusivo". Crossfade/gapless (fase 18) e equalizzatore Android (fase 17) sono opzionali.
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

## Importazione 2 (fase 15)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R31 | Un servizio cambia le colonne del suo CSV | «Formato non riconosciuto» o titolo/artista vuoti | Colonne per sinonimi in `csv_profiles.dart` (aggiungere i nuovi nomi); basta un CSV con una colonna titolo e una artista |
| R32 | «Sincronizza» toglie brani che si voleva tenere | La playlist perde brani dopo un aggiornamento del file | L'anteprima mostra quanti ne toglie; si toglie **solo dalla playlist** (file e libreria restano): si riaggiungono dalla libreria; i brani aggiunti a mano non si toccano |
| R33 | M3U/XSPF con codifiche o percorsi strani | Brani non trovati in libreria o titoli storti | Latin-1 di ripiego per `.m3u`, `Uri.decodeFull`, ricerca per cartelle finali; le righe illeggibili sono contate come «ignorate», mai errore sull'intero file; il file XSPF si legge con un lettore a espressioni regolari (pacchetto `xml` solo se serve) |

## CI e test automatici (fase 16)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R34 | Golden diversi tra macchine (font, antialiasing, versione Flutter) | Golden rossi in CI e verdi in locale (o viceversa) | Generati e confrontati solo su Linux con Flutter fissato (3.47.1); tolleranza 0,5 %; font dagli asset; rigenerare con `flutter test --update-goldens test/goldens` solo dopo aver guardato i PNG |
| R35 | Test verdi in locale e rossi in CI (rete, HOME, percorsi, libmpv) | Un solo job rosso | La suite è verificata ermetica (HOME temporaneo, nessuna rete); i test live stanno dietro `CODECORE_LIVE`; per i percorsi `\` guardare il job Windows |
| R36 | YouTube blocca i runner GitHub (IP dei datacenter) nei test live notturni | `nightly.yml` rosso | Sono informativi (`continue-on-error`); la verità resta la prova dal PC di casa |

## Riproduzione avanzata (fase 17)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R37 | Cambiare l'opzione `pitch` di `just_audio_media_kit` altera la correzione di velocità della Jam | La Jam va fuori sincronia o cambia tono | Nessuna modifica fatta (misurato: `scaletempo` tiene 440 Hz a 0,75× e 1,5×); rilanciare `test/jam/` e la misura prima di toccarla |
| R38 | `AndroidEqualizer` non disponibile o con bande strane su alcuni telefoni | Voce Equalizzatore assente o curva poco fedele | `equalizer == null` → voce nascosta; i preset sono interpolati sulle bande reali; errori loggati, riproduzione invariata |
| R39 | Pacchetto MPRIS/SMTC abbandonato o incompatibile con `audio_service` | Niente tasti multimediali di sistema su desktop | Dietro un'interfaccia dedicata; fase 17.7/17.8 ferme in attesa di approvazione dei pacchetti; il resto non dipende |
| R40 | Due notifiche (Jam e `audio_service`) o notifica che resta dopo la Jam | Notifica con il brano sbagliato | Un solo trasporto attivo, staccato in `_teardown`; test dell'handler con trasporto finto; prova con Jam terminata da host e ospite |

## Gapless e crossfade (fase 18)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R41 | La finestra del backend si disallinea dalla coda (brano ripetuto o saltato), o il brano successivo è un file danneggiato | Un brano saltato o ripetuto al passaggio, errore di riproduzione al confine | `PlayQueue` unica autorità, `revision` per ricalcolare, `_onAdvanced` ricarica nel modo normale se la coda non è più quella annunciata; l'impostazione torna su «Normale» (che è il predefinito). Un file illeggibile ma presente non si vede prima del passaggio |
| R42 | mpv o ExoPlayer non sono davvero gapless con certi formati o telefoni | Buco o «clic» al confine | Misurato su Linux (0 ms; mp3 −11 ms per il taglio dell'inizio). `scripts/gap_probe.py` e `test/live/gapless_live_test.dart` rifanno la misura; su Android/Windows prova a orecchio; «Normale» resta disponibile |
| R43 | Regressioni nella Jam o nel timer di spegnimento | Jam fuori sincronia, timer «fine brano» che non ferma | Nessuna modifica ai file della Jam (`git diff` vuoto) e test che lo impediscono (`test/jam/jam_transition_test.dart`); `pauseAtTrackEnd` svuota la finestra e impedisce la dissolvenza |

## Interfaccia (fase 19)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R44 | Gesti in conflitto (pressione lunga, swipe «In coda», riordino, `Draggable` desktop) | Una riga che non si seleziona o che scatta in coda mentre si trascina | In selezione niente swipe; il riordino di una playlist è una modalità a parte (entrando si esce dalla selezione); su desktop il trascinamento parte da pochi pixel (test con mouse simulato) e vince sullo swipe; il menu del brano resta su ⋯, clic destro e (desktop) pressione lunga |
| R45 | Tema chiaro con contrasto insufficiente (copertine chiare, accento giallo) | Testo o icone poco leggibili al sole | Palette chiusa di 8 accenti (scuri nel chiaro), test AA su ogni combinazione (24), `heroTint` chiaro ≥ 7:1; si torna a «Notte viola» da Impostazioni → Aspetto |
| — | Azione di massa sbagliata | Si tolgono 300 brani da una playlist | Conferma col numero, «Annulla» nello snackbar (ripristina le posizioni), niente tocco ai file, backup della fase 13 |

## Libreria intelligente (fase 20)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R46 | `plays` cresce senza limite (anni di ascolti) | Database grande, recap lento | Indici su `played_at` e coprente su `(track_id, played_at, ms_played)`; query aggregate in SQL (misurato: ricapitolo annuale di 100 000 ascolti ~260 ms, mensile ~60 ms); «Cancella cronologia» e interruttore «Registra la cronologia» in Impostazioni; il backup (fase 13) la include |
| R47 | Regole tradotte male in SQL o testo dell'utente iniettato | Risultati sbagliati o query che si rompe mentre si digita | Solo `Variable` (test con `'; DROP TABLE…`, `%`, `_`, `\`); oracolo in Dart sui 28 brani del test; il parser non lancia mai e un termine invalido è testo libero con avviso |
| R48 | Playlist intelligenti o ricerche con molti risultati lente su librerie grandi | Lista che impiega più di mezzo secondo | Misurato su 20 000 brani: ricerche selettive 5–15 ms; con risultati enormi (`-live` = 18 000 brani) il costo è quello di elencarli (~300 ms). Le playlist hanno il limite facoltativo; la ricerca mostra 4 brani e «Mostra tutti» |

## Pulizia libreria e tag (fase 21)
| # | Rischio | Sintomo | Piano B |
|---|---|---|---|
| R49 | Fusione sbagliata (due versioni diverse prese per duplicati) | Un brano live o una traccia con lo stesso titolo sparisce | Anteprima obbligatoria per gruppo, durata entro 2 s, titolo e artista non vuoti, «Non sono duplicati» (si ricorda), i nascosti si ripristinano da Impostazioni → Pulizia libreria → Brani nascosti; l'unione è una sola transazione (provato con un errore a metà) |
| R50 | Scrittura dei tag che rovina il file o perde copertina/ReplayGain | File che non si apre, copertina sparita | **Non ancora implementata** (21.7–21.9 in attesa di approvazione). Verificato in 21.1: `metadata_god` (lofty) conserva audio, copertina e tag sconosciuti, `audiotags` li perde (scartato). Resta il piano: copia, riscrittura, rilettura e confronto, backup, `rename` atomico, opzione spenta di serie |
| R51 | Il pacchetto Rust non compila su una piattaforma | Build Android che fallisce | **Successo su Linux**; su Android `metadata_god` 1.1.0 fallisce con Gradle 9 (cargokit usa `project.exec`, `compileSdk` 33): serve una copia locale con `docs/patches/metadata_god-gradle9.patch`. Windows da provare in CI. Senza il pacchetto la voce non compare |
| R52 | Eliminazione dei file negata (Android, disco esterno) o sbagliata | «Non eliminato», o un file sparisce per errore | Solo dopo due conferme col elenco dei percorsi; mai il file tenuto, mai un collegamento che porta ad esso; errori raccolti con il motivo del sistema e mostrati; i brani non eliminati restano nascosti e ripristinabili |
