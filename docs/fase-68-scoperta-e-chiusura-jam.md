# Fase 68 — Scoperta e chiusura (feature «Jam: cassa e coda insieme»)

**Obiettivo:** la scoperta funziona anche su reti non /24, la fluidità non peggiora e la feature è provata a mano con due telefoni e la «cassa».

**Prerequisiti:** fasi 65, 66 e 67 chiuse. Requisiti R-117, R-118, RNF-13; decisioni D-206, D-215.

**Comando mirato:** `flutter test test/services/share test/jam`; misure con `python3 scripts/perf_device.py 0d7ae9df206e --label fase68 --only "<scenari>"`.

## Task

### 68.1 — Maschera di rete vera (R-117, D-206, K-JC-07)
`LanDiscovery._targets` calcola il broadcast diretto dalla lunghezza del prefisso: Android dal lato nativo (`LinkProperties`, metodo `netPrefix` su `codecore/audio`), Linux da `ip -o -4 addr show`, Windows senza prefisso → `a.b.c.255` e `a.b.255.255`. Lettura fallita → la /24 di oggi.

**Fatto quando:** test della funzione degli indirizzi (/24, /16, /22, /30) e del parser di `ip` su uscite reali; prova su una rete /16 (UniBA) in «Tocca a te».

### 68.2 — Misure di fluidità (RNF-13)
Sul Mi A3 gli scenari di `perf_device.py` che toccano coda e shell (Apertura player, Fogli, Pallino schede) contro «Dopo» di `docs/refactor/ui-jam-ricerca/misure.md`; uno scenario fuori soglia si conferma con la prova A/B (handoff, «Dispositivi») prima di cercarne la causa.

**Fatto quando:** tabella «Fase 68» in `misure.md` con data e dispositivo; nessuno scenario peggiorato oltre il rumore.

### 68.3 — Prova a mano con due telefoni (R-118) [utente]
Hotspot del Motorola; Motorola host con le cuffie JBL segnate come cassa, Mi A3 ospite. Da provare: rilievi R-88 … R-95 (aggiunte in fila, swipe online, uscita con coda ritrovata, copertine, «Scarica», precedente subito dopo successivo, scarto), «Coda insieme» (turni, aggiunta in testa, suggerito, ritorno a «Coda dell'host»), Jam della cassa (domanda, Jam aperta da sé, banner sul Mi A3, richiesta accettata, solo l'host suona, cuffie spente → «Collega una cassa», riaccese → sblocco; poi cuffie spente, ricollegate al Mi A3 → «Suonare la Jam sulla tua cassa?» → suona solo il Mi A3, R-119).

**Fatto quando:** esiti scritti qui sotto, uno per riga; i KO diventano passi nuovi o vanno in «Rinviato» con il motivo.

### 68.4 — Chiusura
`docs/handoff.md` aggiornato, `docs/prossimi-lavori.md` §2 segnato come fatto per «Cassa Bluetooth e modalità della coda», pulizia del disco (`pulizia.sh`).

**Fatto quando:** documenti aggiornati, nessun file temporaneo rimasto.
