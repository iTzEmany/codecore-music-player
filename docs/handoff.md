# Handoff — 2026-10-28 (fasi 57–64 fuse: streaming veloce e refactor «ui-jam-ricerca»)

## Stato
- **57** (#45, #46): URL da NewPipeExtractor su Android (D-164, D-173 desugaring per API < 33), vietati ai minori → traccia di YouTube Music, `UrlSession`, brano dopo dall'URL anticipato, gapless e crossfade da URL verso file; crossfade senza esaurire l'Equalizer sul Mi A3.
- **58** (#47) test di caratterizzazione e «Prima» del refactor · **59** (#48) player e seek, scheda del testo stabile · **60** (#49) Ricerca con la barra sopra il dock · **61** (#50) ⋮ sempre a foglio (`showCcActionSheet`) · **62** (#51) Home «aggiunti da poco» che scorre · **63** (#52) la Jam usa la schermata del player · **64** chiusura: misure, metriche, prova a mano, «Risultati» in `docs/refactor/ui-jam-ricerca/analisi.md`.
- Misure finali sul Mi A3 (`docs/refactor/ui-jam-ricerca/misure.md`, «Dopo»): tutti gli scenari in soglia tranne Ricerca «notte», build p99 21,3 ms contro 16 (D-176, −38 % rispetto a Prima). Pallino schede: la prova A/B dà 0,6 % su master contro 1,8–5,1 % sul codice di prima; i 4–5 % delle prime run erano rumore del telefono.
- Prova a mano 64.3 su Linux e Mi A3 fatta; corretti Esc sui fogli dentro una scheda, Esc sul ventaglio aperto col mouse, un solo foglio alla volta su desktop largo, Back col ventaglio aperto.

## Tocca a te
- **Motorola** `ZY22HKD85K`:
  - 57.4 RNF-08 (≤ 5 s al primo suono): `python3 scripts/stream_times.py --adb ZY22HKD85K --last 10` dopo 10 brani online nuovi;
  - installa la build di `master` con `install -r` (c'è ancora il prototipo NewPipe del 28/10 00:00).
- **63.5 Jam con due telefoni** (Motorola host, Mi A3 ospite): seek da anello e barra da entrambi, precedente/successivo dall'ospite, «Termina» con conferma, coda dal pulsante. Esito sotto 63.5 in `docs/PROGRESS.md`. Poi la parte Jam e Motorola di 64.3.
- **57.7 ascolto**: crossfade e gapless fra brani online in coda; vietato ai minori → suona la traccia di YouTube Music; hotspot lento → niente buffering nei primi 10 s. Sul Mi A3 senti se il crossfade è brusco.
- **APK di release con NewPipe**: mai provato a runtime (Rhino senza `jdk.dynalink`); nel log cerca `stream url source=newpipe ... used=1`.
- **Fase 59, seek a mano**: trascina l'anello e intanto passa a una radio, poi rilascia; chiudi il player a drag aperto; rilascia a 0,5× e sulla radio.
- **Da sapere**:
  - il timer di spegnimento segna come scelta solo «A fine brano» (lo stato non conserva i minuti);
  - un tocco fuori dal ventaglio aperto lo chiude e apre anche ciò che c'è sotto (comportamento di `TapRegion`, lasciato così);
  - ✕ di Ricerca chiude la tastiera per D-155.
- `git stash list`: `stash@{0}` è rumore di `dart format lib`, da buttare (`git stash drop`).
- Tag `v1.3.0` ancora non pubblicato (D-92): `git push origin v1.3.0`.

## Dispositivi
- **Motorola edge 40** `ZY22HKD85K`: libreria vera. Solo `install -r`; mai disinstallare né `pm clear`. 120 Hz.
- **Mi A3** `0d7ae9df206e`: si disinstalla solo con `-k`; mai cancellare i file musicali. Misure con `com.codecore.player.perf`. Volume musica originale 0. A schermo spento si blocca col PIN: non spegnerlo durante le misure.
- Su entrambi: mai toccare rotazione o impostazioni di sistema; «Non disturbare» (`cmd notification set_dnd priority|off`) solo durante le misure.
- Misure: `python3 scripts/perf_device.py <id> --label <l> [--no-build --no-push --apk <apk>] [--only "A,B"]`. Per confrontare due commit: un worktree per commit, due APK `--profile` con `CODECORE_PERF=1`, run alternati A,B,A,B con `--only`.

## Rinviato (dal handoff precedente, ancora aperto)
- 53.10 completamento intero sul Motorola (in pausa a 421/2317, ~10 h).
- Jam (47.8): aggiunte dell'ospite subito dopo il brano corrente; swipe «in coda» dell'ospite su una riga online; ruoli host/uscita (R-21); «Scarica» che resta nel ⋮ del player.
- Messaggio «perché niente Shuffle+» (D-87) su un album da 1 brano.
- Interruttori del completamento che fermano il giro manuale.

## Prompt di avvio della prossima sessione
```
Leggi docs/handoff.md, docs/gotchas.md e docs/PROGRESS.md. <obiettivo scelto fra quelli sotto>
```

## Prossimi obiettivi
1. **(Consigliato) Le prove col Motorola** di «Tocca a te» (57.4, 63.5, 64.3), con il telefono collegato: chiudono tre fasi già fuse e dicono se RNF-08 è raggiunto. Prompt: `/obiettivo prove Motorola 57.4, 63.5, 64.3`.
2. **Rilievi della Jam 47.8** (sopra): ora che la Jam è il player, sono il debito più visibile.
3. **Ricerca «notte» build p99** (D-176): l'ultimo scenario fuori soglia; misurare con `--only "Ricerca «notte»"` prima e dopo.
4. **Scoperta dei dispositivi su reti non /24** (visto su UniBA, /16, il 28/10: i telefoni non si vedono e la Jam non parte; sull'hotspot sì). `LanDiscovery._targets` in `lib/services/share/discovery.dart` manda il broadcast diretto a `a.b.c.255` supponendo una /24. Dart non dà la maschera: leggerla dal lato nativo (Android `LinkProperties`, Linux/Windows dal sistema) o provare anche `a.b.255.255`. Reti che filtrano ogni broadcast restano escluse: lì serve il collegamento manuale per la Jam.
5. **Debito dello streaming** (in fondo a `docs/fase-47-jam-online.md`): tre meccanismi «online → libreria», `DownloadsNotifier` grande, `discovery: socket error` ogni 2 s senza rete.
