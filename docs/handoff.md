# Handoff — 2026-10-29 (fasi 66–68 «Jam: cassa e coda insieme», kickoff della «Jam a distanza»)

## Prima di tutto (per la prossima chat)
Kickoff della feature «Jam a distanza» fatto: requisiti, stack, architettura, protocollo di sicurezza e rischi in `docs/feature-jam-distanza.md`, decisioni D-228…D-262, piano nelle fasi 69–73 (`docs/00-INDICE.md`). Pacchetti nuovi ammessi: solo `sodium` e `mqtt_client`. Si parte dalla fase 69.

La feature «Jam: cassa e coda insieme» (`docs/feature-jam-cassa.md`) è nel codice: 66 (#61), 67 (#62), 68 (questa PR). Resta solo la prova a mano 68.3 con il Motorola e le JBL, più le voci di «Tocca a te». Le decisioni della notte sono D-222…D-227 in `docs/decisioni.md`.

## Stato
- **66** «Coda insieme»: modalità della coda, turni fra i partecipanti, l'host continua da solo quando esce l'unico ospite (R-91, D-221).
- **67** «Jam della cassa»: uscite Bluetooth dal nativo, «È una cassa?» con la stima dalla classe (D-212), interruttore «Jam sulla cassa», Jam «in attesa» con il solo annuncio (D-226), «Collega una cassa» e fine dopo 10 minuti, offerta della cassa dell'ospite (R-119). 67.1 e 67.2 sono `[~]`: manca la prova sul Motorola.
- **68**:
  - il broadcast della scoperta usa il prefisso vero (R-117). Android lo legge da `NetworkInterface`, che vede anche l'hotspot (D-227); Linux da `ip`; Windows ripiega su a.b.c.255 e a.b.255.255;
  - una lettura fallita delle uscite Bluetooth non è più una cassa sparita;
  - misure sul Mi A3 in `docs/refactor/ui-jam-ricerca/misure.md` §Fase 68.

## Tocca a te
- **68.3** (Motorola host con le JBL segnate come cassa, Mi A3 ospite, hotspot del Motorola): checklist in `docs/fase-68-scoperta-e-chiusura-jam.md` §68.3, esiti scritti lì, uno per riga.
  - Prima: `flutter build apk --debug` e `adb -s ZY22HKD85K install -r build/app/outputs/flutter-apk/app-debug.apk`.
  - Log utili: `adb -s ZY22HKD85K logcat | grep -iE 'speaker|jam|a2dp'`.
- **Fase 67 sul Motorola**: evento A2DP collegando le JBL; permesso rifiutato e poi riattivato; «È una cassa?» (D-223).
- **Scoperta su /16** (UniBA): i due telefoni sulla rete dell'università devono vedersi e la Jam partire (R-117).
- **Fase 66 a mano**:
  - Mi A3: in «Coda insieme» la maniglia sparisce e torna in «Coda dell'host»;
  - Linux ospite su schermo vero: «Coda dell'host»/«Coda insieme» non cambia la modalità;
  - l'ospite esce con un brano online non suonato e l'host lo prepara da sé (R-91).
- **Mi A3 + Linux abbinati**: Jam normale senza «Collega una cassa» né banner.
- **Mi A3, pulizia e controlli**:
  - 6 file di prova in `/sdcard/Music/CodecoreTest/Scheggia66`: toglili se vuoi;
  - controlla che il bordo verde di sistema visto a fine scheggia 67 sia sparito;
  - l'app `com.codecore.player.perf` è ancora installata.
- **Da decidere**: l'ospite che esce di sua volontà vede «La Jam è terminata» anche se la Jam continua sull'host.
- **`docs/prossimi-lavori.md`** (non tracciato): segna a mano come fatto il §2 «Cassa Bluetooth e modalità della coda».
- Dal handoff precedente:
  - ascolto 57.7;
  - APK di release con NewPipe mai provato a runtime;
  - seek a mano della fase 59;
  - tag `v1.3.0` da pubblicare (`git push origin v1.3.0`).

## Dispositivi
- **Motorola edge 40** `ZY22HKD85K`: libreria vera. Solo `install -r`; mai disinstallare né `pm clear`. 120 Hz.
- **Mi A3** `0d7ae9df206e`:
  - si disinstalla solo con `-k`; mai cancellare i file musicali;
  - le misure vanno sull'app `com.codecore.player.perf`;
  - volume della musica a 0;
  - a schermo spento si blocca col PIN.
- **JBL**: si spengono da sole dopo circa 20 minuti senza suono.
- Su entrambi i telefoni: mai toccare la rotazione o le impostazioni di sistema.
- **Misure**: `python3 scripts/perf_device.py <id> --label <l> [--no-build --no-push --apk <apk>] [--only "A,B"]`. Per un A/B: un worktree per commit e run alternati A, B, A, B.
- **APK**: si compila con `JAVA_HOME=~/.jdks/jbr-17.0.14` (`docs/gotchas.md`).

## Rinviato
- **Due code per le domande sulla cassa** (`SpeakerMonitor._pending` e la coda della UI): da unificare.
- La posizione mostrata nella Jam salta indietro di circa 1,3 s a ogni avvio di brano (`jam ui: shown position moved`).
- 53.10 completamento intero sul Motorola (fermo a 421/2317).
- Il messaggio «perché niente Shuffle+» (D-87) su un album da 1 brano.
- Gli interruttori del completamento che fermano il giro manuale.
- Il debito dello streaming, in fondo a `docs/fase-47-jam-online.md`.

## Prompt di avvio della prossima sessione
```
/obiettivo fase 69 (feature «Jam a distanza», docs/feature-jam-distanza.md)
```
Dopo la prova 68.3, invece:
```
Leggi docs/handoff.md. Ho fatto la prova 68.3: gli esiti sono in docs/fase-68-scoperta-e-chiusura-jam.md §68.3. Trasforma i KO in una fase di rilievi e lanciala con /obiettivo.
```

## Prossimi obiettivi
1. **(Consigliato) Jam a distanza, fasi 69–73**: `/obiettivo fase 69`. La 73.2 (due telefoni, uno su 4G) è a mano.
2. **Esiti della 68.3**: rilievi della prova con la cassa vera, poi 67.1, 67.2 e 68.3 da `[~]` a `[x]`.
3. **Unificare le due code delle domande sulla cassa**: un solo punto che decide cosa mostrare. Oggi la coda del monitor e quella della UI possono mostrarne due di fila.
4. **Ricerca «notte», build p99** (D-176): l'ultimo scenario fuori soglia. Misura con `--only "Ricerca «notte»"` prima e dopo.
5. **Prove d'ascolto 57.7** e APK di release con NewPipe.
