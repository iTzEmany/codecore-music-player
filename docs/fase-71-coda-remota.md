# Fase 71 — Coda dell'ospite remoto (feature «Jam a distanza»)

**Obiettivo:** l'ospite remoto mette in coda dalla sua libreria, dalla Ricerca online e da «Coda insieme»; all'host arriva solo il video id e il brano lo scarica o lo riproduce lui. L'ospite remoto vede copertine, scheda e testo senza chiedere niente all'host.

**Prerequisiti:** fase 70 chiusa. Requisiti R-151 … R-155; decisioni D-93, D-240, D-241, D-247. Aree a rischio: protocollo Jam, ordine della coda (`jam_part_feeder.dart`). Nessun pacchetto nuovo.

**Comando mirato:** `flutter test test/jam test/ui/jam_screen_test.dart test/ui/jam_parts_test.dart test/ui/jam_track_info_screen_test.dart` (più i test di `SeedResolver` se cambia).

## Task

### 71.1 — `JamRemoteItems` e aggiunte (R-151, R-152, D-240)
`lib/services/jam/remote/jam_remote_items.dart`: `Track` → item `yt:youtube:<vid>` (`selfFetchable`) con `SeedResolver.resolve` (download che ha fatto il file, poi indice, poi ricerca solo sicura); null → «Non trovato online, non si può aggiungere». Da ospite remoto `JamPart` usa `JamRemoteItems` invece di `jamItemOfTrack` e `addOnline` manda subito l'item `yt:` senza scaricare. «Aggiungi» torna visibile per l'ospite remoto.

**Fatto quando:** test con un resolver finto: brano con video id → item `yt:` senza ricerca; senza → ricerca, trovato → item, non trovato → messaggio e nessun comando inviato; simulazione host + ospite remoto: aggiunta dalla Ricerca online → item `yt:` nella coda dell'host e preparato dall'uscita, nessun messaggio oltre RNF-14.

### 71.2 — «Coda insieme» da remoto (R-153, D-247)
Il feeder della parte di un ospite remoto e i suoi suggeriti passano da `JamRemoteItems`; i brani non trovati si saltano senza fermare il turno.

**Fatto quando:** test del feeder con un resolver finto: non trovati saltati, gli altri entrano a turno come oggi.

### 71.3 — Copertine, scheda e testo (R-154, R-155, D-241)
`jamItemOfTrack` mette `vid` = `DownloadIndex.idForPath(path)` sui brani di libreria dell'host. `JamCover` per l'ospite remoto: video id → miniatura di YouTube, senza → la nota; in LAN resta la copertina del proprietario. Scheda, testo e curiosità dell'ospite remoto dal video id e dai metadati, come nella Jam come player (fase 63).

**Fatto quando:** test widget di `JamCover` da ospite remoto (miniatura, nota, nessuna richiesta a `/cover`); test che la scheda di un item `yt:` non chiama l'host; i test LAN delle copertine invariati.

### 71.4 — Controlli di fase
`flutter analyze`, comando mirato, `/code-review high` su 71.1 e 71.2, scheggia in modalità passo su 71.1, review Opus. Prova in autonomia: Linux host, Mi A3 ospite remoto col codice; aggiunte dalla libreria (con e senza video id) e dalla Ricerca, «Coda insieme» con un brano introvabile.

**Fatto quando:** tutto verde; esiti qui sotto; colonna Fase di R-151 … R-155 compilata.
