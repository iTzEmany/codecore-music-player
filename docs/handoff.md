# Handoff — 2026-10-25

## Stato
- Feature «Streaming e coda online» completa nel codice: fasi 45–49 fuse una PR per fase (#19 cache e motore, #20 streaming dalla ricerca, #21 Jam online, #22 shuffle a 3 stati e Home, #23 artisti ospiti). Decisioni D-89…D-95 in `docs/decisioni.md`.
- Versione `1.3.0+4`; tag locale `v1.3.0` sul commit di chiusura (D-92), **non ancora pubblicato**.
- Verifiche: `flutter analyze` pulito; test mirati di ogni fase e K-01/K-02 verdi in locale; suite completa verde in CI su ogni PR.
- Fluidità (Mi A3, `docs/refactor/ui-fluida/misure.md`): fasi 45, 46, 48 entro un frame dalla base (D-85). La base 30 s a `1c5348a` sostituisce i giri con brani da 1 s, che non erano confrontabili.
- Ogni fase ha avuto review di architettura (Opus) e la scheggia in modalità passo; i bug trovati sono corretti con il loro test. Scheggia in modalità fase sul Mi A3 per 45, 46 e un giro unico 47 (solo online, Jam vietata da D-91)–49: nomi artista troncati e crediti scaricati tenuti interi corretti nella PR di chiusura.

## Tocca a te
- **Tag (D-92):** `git push origin v1.3.0` → costruisce APK, Linux e Windows e pubblica la release; controlla con `gh run list -w release.yml -L 1`.
- **Mi A3, pulizia delle prove:** cancella `Da Funk (2).m4a`, `The Game of Love (Drumless Edition) (2).m4a` e la playlist «scheggia-46»; controlla che la dissolvenza non sia rimasta a 11 s (Impostazioni → Riproduzione).
- **Prove a mano `[~]`** (Linux e Mi A3, elenco in ogni documento di fase): 45.8 cache, 46.10 streaming dalla ricerca, 47.8 Jam online (servono due dispositivi), 48.6 shuffle a 3 stati e Home, 49.5 artisti ospiti. Poi spunta `docs/PROGRESS.md`.
- **Mi A3, lasciato dalla scheggia 47–49:** il brano «Talk to Me (feat. Tyla, Nile Rodgers)» di Damiano David (scaricato provando «Scarica»): tienilo o cancellalo tu.
- **Da decidere:** in Home, con la coda corrente sotto i 5 brani, il pulsante shuffle salta Shuffle+ anche se il Play avvierebbe tutta la libreria (oggi vale la coda corrente, 48.1). E il pulsante «Casuale» delle intestazioni di lista resta a 2 stati: Shuffle+ si raggiunge da player, Home e barra desktop.
- **Log dopo le prove:** niente 403/429 ripetuti (K-04).

## Dispositivi
- **Motorola edge 40** `ZY22HKD85K`: libreria vera. Solo `install -r`; mai disinstallare né `pm clear`.
- **Mi A3** `0d7ae9df206e`: si può disinstallare con `-k`; mai cancellare i file musicali. Misure solo con `com.codecore.player.perf` (D-19).
- Misura: `JAVA_HOME=~/.jdks/jbr-17.0.14 PATH=$JAVA_HOME/bin:$PATH python3 scripts/perf_device.py 0d7ae9df206e --label <l> --playback [--no-push] [--only "A,B"]`.

## Prompt di avvio della prossima sessione
```
Leggi docs/handoff.md, docs/gotchas.md e docs/PROGRESS.md. <obiettivo scelto fra quelli sotto>
```

## Prossimi obiettivi
0. **(Consigliato) I lavori 2b e 3 di `docs/prossimi-lavori.md`** (D-82 li metteva dopo lo streaming, ora chiuso). Prima le prove a mano qui sopra: un bug di streaming trovato a mano conviene correggerlo prima.
1. **Debito noto dello streaming** (in fondo a `docs/fase-47-jam-online.md`): tre meccanismi «online → libreria», `DownloadsNotifier` grande, prefetch che ricomincia da capo, file auto-scaricato dall'uscita Jam non fissato in cache, «Scarica» da una riga ombra senza messaggio; `gapless window edit failed` (IllegalArgumentException) al cambio di shuffle su una coda di 2 brani; `discovery: socket error` ogni 2 s senza rete.
2. **Picchi di build al cambio di brano** (Swipe mini player, Apertura player): `cacheWidth`/`gaplessPlayback` in `track_art.dart`; misura prima e dopo con `--only`.
3. **Memoria e avvio:** PSS ~213–270 MB contro 210 MB; misurare prima con la libreria di prova piccola.
