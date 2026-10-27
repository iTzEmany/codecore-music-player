# Handoff — 2026-10-27 (fase 55 fusa: misura dello streaming)

## Fase 55 (#39)
- Righe `stream timing` in `codecore.log` (preparer: spawn/downloaded/post/cached; player: tap → primo suono) e `scripts/stream_times.py` (`--log`/`--adb`, `--self-test`).
- «Prima» (`docs/fase-55-misura-streaming.md`): il tempo è il download. Motorola su dati mobili: primo suono 23 s, spawn 3,6 s. Mi A3 su hotspot: 41 s, spawn 6,2 s. Linux: URL a ~4 s, prima del download, ascolto e seek senza 403.
- 55.4 e 55.5 a `[~]`: Mi A3 da rimisurare fuori dall hotspot (i dati mobili del Motorola valgono: più veloci del Wi-Fi di casa), Linux con 10 brani (serve un display isolato: Xvfb non c'è; l'utente lavora sul suo unico schermo), Mi A3 avanzamento/ascolto/seek dall'URL.
- Da capire prima della 56: sul Mi A3 l'URL è arrivato a 38,9 s (hotspot) e ~13 s passano prima che yt-dlp parta (forse `ensureInit` con l'aggiornamento).

## Stato (prima della fase 55)
- **Fasi 45–54 fuse** (feature «Streaming e coda online» e «Arricchimento completo»); fase 54 in #34. Versione `1.3.0+4`, tag locale `v1.3.0` **non pubblicato** (D-92).
- **PR delle prove sul Motorola** (ramo `docs/54-prove-motorola`): prove a mano 45–54 sulla libreria vera (2312 brani) e sul Mi A3, più le correzioni trovate provando:
  - Registro: la riga del giro di completamento arriva senza ciclo di provider (`EnrichCompleter.addLog`).
  - LRCLIB riposa 10 minuti dopo un 5xx (prima: 503 a raffica).
  - Prestazioni: schede nascoste senza ticker (`TickerMode`) e rotellina Attività in un `RepaintBoundary`. Sul Motorola il cambio scheda passa da 8–17 % di frame lenti a 0,1 % (`docs/refactor/ui-fluida/misure.md`, «Dopo la fase 54»).
  - `scripts/perf_device.py --real`: misura l'app vera in sola lettura; ogni `input` controlla che l'app sia in primo piano.
  - Shuffle+ da ogni pulsante casuale (D-137): la pillola «Casuale» delle liste fa il ciclo a 3 stati, Home giudica la libreria e non la coda.
- Esiti in `docs/PROGRESS.md`: `[x]` 48.6, 50.11, 51.9, 54.9; `[~]` 45.8, 46.10, 47.8, 49.5, 52.8, 53.10 con la nota di cosa manca.

## Rinviato alla prossima fase (scelta dell'utente, 27/10)
- **53.10 completamento intero sul Motorola**: in pausa a 421/2317 (~9 brani ogni 3 minuti, ~10 h in tutto). Riprendilo dal centro Attività; controlla a fine giro log (niente 429/503 a raffica), riga Memoria (4,8 MB a ~287 brani: testi 4,5 MB) e temperatura.
- **Jam (47.8), rilievi da capire nel codice** (Motorola avvia, Mi A3 si unisce):
  1. Le aggiunte dell'ospite vanno subito dopo il brano corrente, non in fondo (D-80, D-89).
  2. Sull'ospite lo swipe «in coda» su una riga online della ricerca non accoda nulla; ⋮ → «Aggiungi in coda» sì.
  3. Ruoli: chi avvia vede l'altro come «host» e la Jam prende la coda dell'altro; «Esci dalla Jam» di chi ha avviato la chiude per tutti, quindi R-21 non si è potuto provare. Chiarire host/uscita.
  4. «Scarica» resta nel menu ⋮ del player dopo che il brano è in libreria, finché non lo si chiude.
- **Messaggio «perché niente Shuffle+»** (D-87): su un album da 1 brano non si è visto. Verificare con un widget test della pillola dentro `CollectionScaffold`.
- **Completamento e interruttori**: cambiare un interruttore ferma il giro manuale (`stopped:true`); con «Arricchimento automatico» acceso ne riparte uno automatico, spento va riavviato a mano. Decidere se va bene.

## Tocca a te
- **Rotazione dei telefoni**: durante il giro 3 `accelerometer_rotation` è tornata a 1 su entrambi senza nessun comando dei test (non la cambiano né `uiautomator dump` né `screencap`, provato). L'ho rimessa a 0: se la ritrovi accesa, dimmelo con l'ora.
- **Tag (D-92):** `git push origin v1.3.0` → release; controlla con `gh run list -w release.yml -L 1`.
- **Da decidere (scheggia 53):** voce fissa per il Registro; «Svuota» senza conferma; il completamento dopo un giro fallito per rete riparte solo con riavvio, scansione o cambio di interruttori.
- **Mi A3, pulizia vecchie prove:** `Da Funk (2).m4a`, `The Game of Love (Drumless Edition) (2).m4a`, playlist «scheggia-46», dissolvenza non a 11 s; brano «Talk to Me» di Damiano David (tienilo o cancellalo). L'app `com.codecore.player.perf` sul Mi A3 serve solo alle misure.
- **Motorola:** è installata la build di debug con tutte le correzioni; «Crediti e dettagli» e «Curiosità automatiche» rimessi spenti, casuale spento, «The Joker» in coda al posto di «My My, Hey Hey» (forse un ascolto in più nelle statistiche).
- **Backup sul PC** (`.backup-motorola/`, 481 MB): cancellalo quando non ti serve più.

## Dispositivi
- **Motorola edge 40** `ZY22HKD85K`: libreria vera. Solo `install -r`; mai disinstallare né `pm clear`. Schermo a 120 Hz (budget 8,3 ms), lo script conta contro 16,7 ms.
- **Mi A3** `0d7ae9df206e`: si può disinstallare con `-k`; mai cancellare i file musicali. Misure con `com.codecore.player.perf` (D-19).
- Misure: `python3 scripts/perf_device.py <id> --label <l> [--no-push] [--only "A,B"]`; sull'app vera `--real --apk <apk>` (sola lettura).
- Su entrambi: mai toccare rotazione o altre impostazioni di sistema; «Non disturbare» (`cmd notification set_dnd priority|off`) solo durante le misure, poi `off`.

## Prossimo: refactor «ui-jam-ricerca» (fasi 58–64, piano del 2026-10-27)
Jam = player con anello e barra, Ricerca con la barra sopra il dock, ⋮ sempre a foglio, Home «aggiunti da poco» che scorre, scheda del testo stabile.
Ordine: 58 rete · 59 player e seek (testo per primo) · 60 Ricerca e dock · 61 fogli ovunque · 62 Home · 63 Jam = player · 64 chiusura.

Prompt: `/obiettivo fase 58`, **dopo** le fasi 55–57 dello streaming veloce (Prossimi obiettivi, punto 0).

### Da sapere
- Analisi e rilievi F-01..F-58: `docs/refactor/ui-jam-ricerca/analisi.md` (sezioni «Scelte», «Arrivo — UI», «Rete»).
- Mockup approvati (specifica visiva): `docs/refactor/ui-jam-ricerca/mockup/jam-player.html`, `ricerca.html`, `home-aggiunti.html`, `fogli.html`; stile e token da `docs/refactor/ui-fluida/mockup/tokens.css`.
- Decisioni D-147..D-162 in `docs/decisioni.md` (D-161 presa in autonomia: scheda del testo a tutta larghezza e 5 righe fisse).
- `docs/prossimi-lavori.md` non è tracciato da git: F-29/F-30 si verificano in 60.5.

## Prompt di avvio della prossima sessione
```
Leggi docs/handoff.md, docs/gotchas.md e docs/PROGRESS.md. <obiettivo scelto fra quelli sotto>
```

## Prossimi obiettivi
0. **(Consigliato) Fase 56, partenza dall'URL**: i dati mobili del Motorola valgono come rete buona (più veloci del Wi-Fi di casa, utente 27/10); da rimisurare solo il Mi A3 fuori dall hotspot (`python3 scripts/stream_times.py --adb <serial>`) e verifica dei ~13 s prima dell'avvio di yt-dlp su Android. Prompt: `/obiettivo fase 56`. Feature «Streaming veloce», fasi 55–57 (kickoff del 2026-10-27: `docs/feature-streaming-veloce.md`, R-68…R-87, D-138…D-146). Prompt: `/obiettivo fase 55` (poi 56 e 57, una PR per fase). La 55 misura soltanto e scrive la tabella «Prima»; se su Android l'avvio di yt-dlp supera 4 s si prosegue lo stesso (D-146). Motorola da /obiettivo se collegato (backup prima). `docs/prossimi-lavori.md` non è nel repo: la 57.5 lo aggiorna solo se c'è.
   Dopo, i rilievi della Jam e il completamento intero rinviati qui sopra.
1. **Debito noto dello streaming** (in fondo a `docs/fase-47-jam-online.md`): tre meccanismi «online → libreria», `DownloadsNotifier` grande, prefetch che ricomincia, file auto-scaricato dall'uscita Jam non fissato, `gapless window edit failed` su una coda di 2 brani, `discovery: socket error` ogni 2 s senza rete.
2. **Rotellina Attività a 120 fps** mentre un'attività gira (costo di batteria) e picchi di build al cambio di brano (`track_art.dart`); misura prima e dopo con `--only`.
