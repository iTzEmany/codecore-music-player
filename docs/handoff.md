# Handoff — 2026-10-28 (fase 65 «Rilievi della Jam», PR #59)

## Prima di tutto (per la prossima chat)
Kickoff della feature «Jam: cassa e coda insieme» fatto il 28/10 (`docs/feature-jam-cassa.md`, R-88…R-119, D-177…D-220). Fasi 65–68 in `docs/PROGRESS.md`. La 65 è nella PR #59 (rilievi chiusi tranne R-91, vedi sotto); si prosegue con `/obiettivo fase 66`. Prima rispondi alla scelta su R-91.

## Stato
- **57** (#45, #46): URL da NewPipeExtractor su Android (D-164, D-173 desugaring per API < 33), vietati ai minori → traccia di YouTube Music, `UrlSession`, brano dopo dall'URL anticipato, gapless e crossfade da URL verso file; crossfade senza esaurire l'Equalizer sul Mi A3.
- **58** (#47) test di caratterizzazione e «Prima» del refactor · **59** (#48) player e seek, scheda del testo stabile · **60** (#49) Ricerca con la barra sopra il dock · **61** (#50) ⋮ sempre a foglio (`showCcActionSheet`) · **62** (#51) Home «aggiunti da poco» che scorre · **63** (#52) la Jam usa la schermata del player · **64** chiusura: misure, metriche, prova a mano, «Risultati» in `docs/refactor/ui-jam-ricerca/analisi.md`.
- Misure finali sul Mi A3 (`docs/refactor/ui-jam-ricerca/misure.md`, «Dopo»): tutti gli scenari in soglia tranne Ricerca «notte», build p99 21,3 ms contro 16 (D-176, −38 % rispetto a Prima). Pallino schede: la prova A/B dà 0,6 % su master contro 1,8–5,1 % sul codice di prima; i 4–5 % delle prime run erano rumore del telefono.
- Prova a mano 64.3 su Linux e Mi A3 fatta; corretti Esc sui fogli dentro una scheda, Esc sul ventaglio aperto col mouse, un solo foglio alla volta su desktop largo, Back col ventaglio aperto.

## Tocca a te
- **Fatto il 28/10 pomeriggio** (#54, #55): sul Motorola c'è la build di `master` badd8bb; 57.4 RNF-08 raggiunto (mediana 4,3 s, n = 5; il gap al cambio non misurato); 64.3 parte Motorola quasi tutta; 63.5 Jam sull'hotspot del Motorola fatta (su UniBA i telefoni non si vedono). 63.5 e 64.3 restano aperte per i rilievi della Jam.
- **Volume del Motorola**: lasciato a 6, era 7 (da adb si muove solo coi tasti, di 2 in 2).
- **Da indagare**: il brano `NmeJbI1l2YA` ha avuto l'URL di NewPipe in 1,8 s ma ha suonato dalla cache a 19,3 s (visto una volta).
- **57.7 ascolto**: crossfade e gapless fra brani online in coda; vietato ai minori → suona la traccia di YouTube Music; hotspot lento → niente buffering nei primi 10 s. Sul Mi A3 senti se il crossfade è brusco.
- **APK di release con NewPipe**: mai provato a runtime (Rhino senza `jdk.dynalink`); nel log cerca `stream url source=newpipe ... used=1`.
- **Fase 59, seek a mano**: trascina l'anello e intanto passa a una radio, poi rilascia; chiudi il player a drag aperto; rilascia a 0,5× e sulla radio.
- **Da sapere**:
  - il timer di spegnimento segna come scelta solo «A fine brano» (lo stato non conserva i minuti);
  - un tocco fuori dal ventaglio aperto lo chiude e apre anche ciò che c'è sotto (comportamento di `TapRegion`, lasciato così);
  - ✕ di Ricerca chiude la tastiera per D-155.
- Tag `v1.3.0` ancora non pubblicato (D-92): `git push origin v1.3.0`.

## Dispositivi
- **Motorola edge 40** `ZY22HKD85K`: libreria vera. Solo `install -r`; mai disinstallare né `pm clear`. 120 Hz.
- **Mi A3** `0d7ae9df206e`: si disinstalla solo con `-k`; mai cancellare i file musicali. Misure con `com.codecore.player.perf`. Volume musica originale 0. A schermo spento si blocca col PIN: non spegnerlo durante le misure.
- Su entrambi: mai toccare rotazione o impostazioni di sistema; «Non disturbare» (`cmd notification set_dnd priority|off`) solo durante le misure.
- Misure: `python3 scripts/perf_device.py <id> --label <l> [--no-build --no-push --apk <apk>] [--only "A,B"]`. Per confrontare due commit: un worktree per commit, due APK `--profile` con `CODECORE_PERF=1`, run alternati A,B,A,B con `--only`.

## Jam: rilievi (fase 65, prova sui telefoni del 28/10)
1. Ruoli e uscita dell'ospite: chiuso per R-90 (coda di prima, in pausa, stesso punto). **Aperto R-91**: con un solo ospite la sua uscita chiude la Jam (`JamHost.removeMember` → `endSession` quando resta solo l'host) e i suoi brani online non suonati si perdono; con ≥ 2 ospiti restano. Scelta di prodotto: l'host continua da solo con la coda della Jam, o la Jam finisce come oggi?
2. Aggiunte dell'ospite in fila dopo il corrente: chiuso (65.1, R-88).
3. Swipe «in coda» online dell'ospite: chiuso, funziona sui telefoni (65.2).
4. «Scarica» nel ⋮ a foglio aperto: chiuso (65.5, R-93).
5. Copertine dell'ospite, scarto di ~2 s e «precedente» da 0:22: chiusi (65.4, 65.7 con orologi a 2,2 s di distanza ora compensati, 65.6). «Rimuovi» dell'ospite è voluto (D-195).
Nuovi, rimandati: la posizione mostrata salta indietro di ~1,3 s a ogni avvio di brano (`jam ui: shown position moved`); sul Motorola la scoperta è rimasta vuota finché l'app non è stata riavviata (fase 68.1).

## Rinviato (dal handoff precedente, ancora aperto)
- 53.10 completamento intero sul Motorola (in pausa a 421/2317, ~10 h).
- Messaggio «perché niente Shuffle+» (D-87) su un album da 1 brano.
- Interruttori del completamento che fermano il giro manuale.

## Prompt di avvio della prossima sessione
```
/obiettivo fase 66
```

## Prossimi obiettivi
1. **(Consigliato) Fasi 66–68, feature «Jam: cassa e coda insieme»** (`docs/feature-jam-cassa.md`): «Coda insieme», Jam della cassa, scoperta e chiusura. Prova finale (68.3) con i due telefoni sull'hotspot e le cuffie JBL segnate come cassa.
2. **Prove d'ascolto 57.7** e APK di release con NewPipe (vedi «Tocca a te»).
3. **Ricerca «notte» build p99** (D-176): l'ultimo scenario fuori soglia; misurare con `--only "Ricerca «notte»"` prima e dopo.
4. **Scoperta dei dispositivi su reti non /24** (ora nella fase 68.1, D-206) (visto su UniBA, /16, il 28/10: i telefoni non si vedono e la Jam non parte; sull'hotspot sì). `LanDiscovery._targets` in `lib/services/share/discovery.dart` manda il broadcast diretto a `a.b.c.255` supponendo una /24. Dart non dà la maschera: leggerla dal lato nativo (Android `LinkProperties`, Linux/Windows dal sistema) o provare anche `a.b.255.255`. Reti che filtrano ogni broadcast restano escluse: lì serve il collegamento manuale per la Jam.
5. **Debito dello streaming** (in fondo a `docs/fase-47-jam-online.md`): tre meccanismi «online → libreria», `DownloadsNotifier` grande, `discovery: socket error` ogni 2 s senza rete.
