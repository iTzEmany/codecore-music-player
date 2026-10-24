# Handoff — 2026-10-24

## Stato
- Correzioni del 24-10 fuse (PR #14): download 403 (yt-dlp Android ora si aggiorna prima di ogni operazione), chip della ricerca leggibili, Invio senza risultati locali → online (D-60), pallino dell'anello sopra la copertina, immagine degli artisti più ascoltati, hover dello shuffle solo sul pulsante, swipe in coda che non parte dal bordo (D-59). Provate sul Mi A3.
- Il refactor «ui-fluida» (fasi 38–44) è completo nel codice. Le PR #6–#11 sono fuse, e la fase 44 è nella PR finale.
- Versione `1.3.0+4`. Il tag `v1.3.0` ora si può creare (D-58).
- Verifiche:
  - `flutter analyze` pulito.
  - `flutter test test/ui test/goldens test/providers test/l10n` verde (934 test). La suite completa la esegue la CI.
  - `integration_test` su Linux, un file per volta: 5/5 verdi.
- Misure finali sul Mi A3: `docs/refactor/ui-fluida/misure.md`, sezione «Finale».
  - Entro la soglia: «Tutti i brani» e «Fogli».
  - «Album» è a un frame dalla soglia.
  - Restano sopra: Pallino 4,3 %, Ricerca, Apri album, Swipe mini player, Apertura player, avvio 2500 ms e PSS 270 MB.
  - L'utente le ha accettate (D-57).
- Risultati per rilievo (F-NN), con i commit: `docs/refactor/ui-fluida/analisi.md`, sezione «Risultati».

## Tocca a te
- **Motorola:** `install -r` del nuovo APK e prova l'import di una playlist Spotify e un download da ricerca.
- **Tag (D-58):** `git tag -a v1.3.0 -m "Codecore 1.3.0"`, poi `git push origin v1.3.0`: costruisce APK, Linux e Windows e pubblica la release; controlla con `gh run list -w release.yml -L 1`.
- **Mi A3, a vista:**
  - Il nuovo aspetto: dock, Home, Libreria, album, player e onboarding.
  - Trascina l'anello del player: fa il seek e il tempo segue il dito.
  - Apri il player, scorri una lista, apri un foglio, cambia scheda.
- **Motorola, solo uso, nessuna scrittura:** gli stessi quattro momenti, con `install -r` dell'APK di rilascio.
- **Prove rimaste dalle fasi 39 e 40:**
  - TalkBack sul mini player e su una riga di brano.
  - Carattere di sistema al massimo.
  - Tab su desktop fino a play e copertina.
  - L'avviso del tema illeggibile.

## Dispositivi
- **Motorola edge 40** `ZY22HKD85K`: ha la libreria vera. Solo `install -r`; mai disinstallare né `pm clear`.
- **Mi A3** `0d7ae9df206e`: si può disinstallare con `-k`; mai cancellare i file musicali.
  - Le misure si fanno solo con l'app separata `com.codecore.player.perf` (D-19), con `JAVA_HOME=/home/emanuele/.jdks/jbr-17.0.14`.
- Misura: `python3 scripts/perf_device.py 0d7ae9df206e --label <l> --playback [--no-push] [--only "A,B"]`.

## Prompt di avvio della prossima sessione
```
Leggi docs/handoff.md, docs/gotchas.md e docs/PROGRESS.md. <obiettivo scelto fra quelli sotto>
```

## Prossimi obiettivi
1. **(Consigliato) Picchi di build al cambio di brano.** Swipe mini player 8 %, Apertura player p99 114 ms, Lettore dal dock.
   - Il player si ricostruisce e decodifica la copertina.
   - Da guardare: `cacheWidth` e `gaplessPlayback` in `track_art.dart`, e le card che dipendono dal brano.
   - Misura prima e dopo con `--only`.
   - Comando: `/obiettivo picchi di build al cambio brano (soglie fase 38)`.
2. **Ricerca e prima apertura di una pagina:**
   - `smartSearch` è ancora sincrono nel provider (build p99 35 ms).
   - «Apri album» costruisce tutta la pagina al primo frame.
3. Le prove a mano `[~]` delle fasi 31–37, con i telefoni collegati.
4. Memoria e avvio: PSS 270 MB contro una soglia di 210 MB. Prima conviene misurare con la libreria di prova piccola, per separare la libreria dal codice.
