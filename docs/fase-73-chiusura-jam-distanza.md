# Fase 73 — Misure e prova a mano (feature «Jam a distanza»)

**Obiettivo:** la cifratura non pesa sulla UI del telefono più lento e la feature è provata a mano con due telefoni, uno su 4G, sul broker predefinito.

**Prerequisiti:** fasi 69–72 chiuse. Requisiti R-159, RNF-15; decisioni D-248, D-260; rischi K-JD-05, K-JD-06, K-JD-09.

**Comando mirato:** `flutter test test/jam`; misure sul Mi A3 con l'app `com.codecore.player.perf` (`python3 scripts/perf_device.py 0d7ae9df206e --label fase73 --only "<scenari>"` o un integration test dedicato).

## Task

### 73.1 — Costo della cifratura (RNF-15, K-JD-09)
Sul Mi A3: cifratura e decifratura di uno stato da 64 KB (200 item), media e massimo su 50 giri. Oltre 8 ms → `seal`/`open` delle buste grandi in un isolate (`compute`), con un test che lo stato arriva uguale.

**Fatto quando:** misura con data e dispositivo in questo documento; se serve l'isolate, test verde e misura ripetuta.

### 73.2 — Prova a mano con due telefoni (R-159) [utente]
Motorola host, Mi A3 ospite su 4G (hotspot di un terzo telefono o SIM), broker predefinito. Da provare: ingresso via Bluetooth (banner a 2 m, K-JD-06), via QR, via codice da Linux; un amico riconosciuto alla seconda Jam; aggiunte dalla libreria e dalla Ricerca; Sospendi 15 min e Blocca; voce sbagliata in testa alla lista dei broker → riserva; host in pausa in sottofondo 10 min a schermo spento (K-JD-05); ospite in modalità aereo 1 min (rientra) e 11 min (esce con la coda ritrovata).

**Fatto quando:** esiti scritti qui sotto e in `docs/PROGRESS.md`, uno per riga; i KO diventano passi nuovi o vanno in «Rinviato» con il motivo.

### 73.3 — Chiusura
`docs/handoff.md` aggiornato, colonna Fase di R-159 e RNF-15 compilata, `docs/prossimi-lavori.md` §2 lo segna l'utente (non tracciato), pulizia del disco (`pulizia.sh`).

**Fatto quando:** documenti aggiornati, nessun file temporaneo rimasto.
