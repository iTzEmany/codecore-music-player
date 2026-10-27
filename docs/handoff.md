# Handoff — 2026-10-27 (fase 56 fusa: partenza dall'URL)

## Fasi 55–56 (#39, #42)
- 55: righe `stream timing` e `scripts/stream_times.py` (`--log`/`--adb`). 55.4/55.5 chiuse nella #42 (Mi A3 sul Wi-Fi UniBA, Linux in Xvfb).
- 56: il brano online parte dall'URL che yt-dlp stampa prima del download (`StreamPreparer.start`/`restart`), poi passa al file; URL scaduto → riparte dalla posizione, al massimo 2 recuperi per brano (R-76).
- «Dopo 56» (`docs/fase-56-partenza-da-url.md`), primo suono mediano: Linux 4,8 s (era 6,6), Mi A3 37,5 s (era 38,9), Motorola 18,2 s (era 23,3 su dati mobili; ora Wi-Fi di casa).
- **Il collo di bottiglia su Android è prima dell'URL**: ~16 s sul Motorola, ~35 s sul Mi A3, quasi tutto QuickJS che risolve le sfide JS di YouTube. RNF-08 (≤ 5 s sul Motorola) non è raggiunto. Pista: `--cache-dir` per yt-dlp nella cartella dell'app (oggi la cache non esiste, quindi le sfide si risolvono a ogni brano). `android_vr` dà l'URL in 8 s ma solo il formato 18 e il download è fallito.
- Per la 57 (nota in `docs/fase-57-coda-e-transizioni.md`): raccogliere lo stato dell'URL del gestore audio in una piccola classe (`UrlSession`).

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
- **Motorola:** è installata la build di debug di `master` dopo la #42 (27/10 23:18). Per la misura ho ascoltato 12 brani online dalla ricerca (più Hotel California dalla libreria, per errore): finiscono in cronologia e forse nelle statistiche. Il player è in pausa su «Mr. Blue Sky»; la coda di prima è stata sostituita.
- **Wi-Fi spento a metà brano online** (R-76, K-SV-04) su un telefono: il brano si ferma senza crash; riacceso, ▶ riprende dalla posizione. Poi spunta 56.7 in `docs/PROGRESS.md`.
- **Mi A3**: la rotazione automatica era accesa alle 18:54 (non toccata); `com.codecore.player.perf` ha ancora il codice di prova della 55 (android_vr): reinstallala da `master` se ti serve per le misure.
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
0. **(Consigliato) Fase 57, coda e transizioni** (`docs/fase-57-coda-e-transizioni.md`): prompt `/obiettivo fase 57`. Prima, o come primo passo, prova `--cache-dir` su Android e misura con `stream_times.py --adb ZY22HKD85K --last 10`: è la leva più grande sul primo suono.
   Dopo, i rilievi della Jam e il completamento intero rinviati qui sopra.
1. **Debito noto dello streaming** (in fondo a `docs/fase-47-jam-online.md`): tre meccanismi «online → libreria», `DownloadsNotifier` grande, prefetch che ricomincia, file auto-scaricato dall'uscita Jam non fissato, `gapless window edit failed` su una coda di 2 brani, `discovery: socket error` ogni 2 s senza rete.
2. **Rotellina Attività a 120 fps** mentre un'attività gira (costo di batteria) e picchi di build al cambio di brano (`track_art.dart`); misura prima e dopo con `--only`.
