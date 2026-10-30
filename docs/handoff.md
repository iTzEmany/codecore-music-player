# Handoff — 2026-10-30 (refactor «arricchimento-unico» pianificato, fasi 69a e 69b)

## Prima di tutto (per la prossima chat)
Prima della fase 70 vengono le fasi **69a** e **69b**, pianificate con `/refactor` il 30/10 (D-275…D-290). Il motivo: il completamento in background non lavora mai. Sul Motorola 1812 brani hanno una parte da completare e il giro si ferma in 15 s a ogni avvio. Inoltre «Arricchisci tutta la libreria» e il background sono due motori diversi, con due barre.

Prompt:

```
/obiettivo fase 69a
```

Poi, in una chat nuova, `/obiettivo fase 69b`. Poi la fase 70 come previsto, a partire dalla sezione «Rilievi dalla fase 69» di `docs/fase-70-ponte-jam-distanza.md`.

## Da sapere (refactor)
- **Analisi e piano:** `docs/refactor/arricchimento-unico/analisi.md`, con i rilievi F-01…F-21 con `file:riga` e le sezioni «Misure di partenza», «Scelte», «Arrivo» e «Rete». Per ogni task, prima di toccare il codice, si leggono i rilievi che chiude.
- **Fasi:** `docs/fase-69a-coda-arricchimento.md` e `docs/fase-69b-arricchimento-unico.md`. I nomi 69a e 69b servono a non confonderle con i task 69.5 e 69.6 della fase 69 (D-283).
- **Intoccabili:** D-102, D-103 e D-104, lo schema DB v15 (nessuna migrazione) e il formato di backup e condivisione (D-280).
- **Cambi di comportamento scelti:**
  - D-277/D-284: un solo comando, «Arricchisci tutta la libreria»;
  - D-278: le curiosità entrano nel lavoro manuale;
  - D-285: lo stato «niente trovato» si assegna solo a un brano mai provato;
  - D-286: la revisione tiene conto dei testi scritti a mano;
  - D-288: niente arricchimento immediato a fine scansione.
- **Misure sul Motorola** a fine 69a e a fine 69b (D-289): si chiede prima se il telefono è libero, poi `install -r` e DB e log copiati solo in lettura. Durante la pianificazione il telefono non è stato toccato oltre la lettura del 30/10, perché un'altra chat ci stava facendo prove.
- Con queste fasi si chiude anche «53.10 completamento intero sul Motorola», qui sotto in «Rinviato».

## Fase 69 (chiusa, PR #67)
La fase 69 è nel codice (PR #67). Comprende i rilievi della prova 68.3 (69.1…69.3) e i mattoni della Jam a distanza:
- `JamGuestLink`;
- `JamGate` (2 richieste al minuto, Sospendi, Blocca), salvato in `JamSecretStore`;
- `jam_crypto` su `sodium`;
- broker MQTT con «Prova connessione».

Decisioni D-264…D-273 in `docs/decisioni.md`. Dopo le fasi 69a e 69b si passa alla fase 70 (`docs/fase-70-ponte-jam-distanza.md`): prima la sezione «Rilievi dalla fase 69», poi 70.1.

## Stato
- **69.1**: la Jam della cassa si riapre quando l'hub torna attivo.
- **69.2**: l'ospite che esce di sua volontà vede «Sei uscito dalla Jam» (D-266).
- **69.3**: 20 posti per le aggiunte a mano (D-264). «Jam piena» solo quando lo è davvero, altrimenti «Non aggiunto alla Jam».
- **69.5–69.9**: interfaccia dell'ospite, gate con le liste in «Rete e dispositivi» (D-271), cifratura, broker. Secondo archivio delle cose segrete: `jam_secrets.json` su desktop, DataStore su Android, fuori dai backup (D-269).
- **69.10**: prova in LAN sul Mi A3 con Linux riuscita (esiti nel documento di fase).
- Broker in diretta:
  - `broker.emqx.io:8883` funziona;
  - `test.mosquitto.org:8883` è rifiutato per il certificato, come previsto;
  - `test.mosquitto.org:8886` chiude dopo il CONNECT.

## Tocca a te
- **69.4 finita in autonomia (D-274)**, esiti in §69.4. Restano solo:
  - «Scarica» che sparisce a foglio aperto, da provare con un brano lungo;
  - decidere se la schermata Jam debba avere il ⋮ con «Scarica».
- **Coda del Motorola**: dopo la prova del 30/10 i primi 6 brani della coda sono quelli di prima, il seguito no (D-186: l'ospite ritrova la sua parte non suonata). Il volume A2DP del Mi A3 è tornato a 7.
- **Mosquitto 8886 da decidere** (D-258): chiude ogni connessione dopo il CONNECT, in tre giri, con TLS valido. Puoi toglierlo dalla lista predefinita (`kDefaultJamBrokers`) o sostituirlo con un altro broker TLS pubblico.
- **Prova a mano del gate**:
  - «Fino alla fine della Jam» durante una Jam vera, e che sparisca al riavvio;
  - una sospensione di 15 minuti che scade.
- **Dalle fasi 66–68** (sezione «Tocca a te» del handoff precedente, nella storia di git):
  - fase 67 sul Motorola;
  - scoperta su /16;
  - fase 66 a mano;
  - pulizia del Mi A3 (Scheggia66, `com.codecore.player.perf`);
  - «La Jam è terminata» per l'ospite che esce: risolto da D-266, da riprovare in 69.4;
  - ascolto 57.7, APK di release con NewPipe, tag `v1.3.0`.

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
- **KO R-102**: a Jam piena il «Suggerito» ripropone brani già suonati nella Jam (§69.4, 30/10). Da correggere con un test che lo riproduce, prima della fase 70 o dentro.
- **⋮ con «Scarica» nella schermata Jam** (R-93, deciso dall'utente il 30/10): oggi «Scarica» c'è solo nel player normale.
- **Da verificare: «Casuale+» torna «Casuale» dopo l'uscita dalla Jam** (visto sul Motorola il 30/10): prima un test che lo riproduce.
- **Bug Shuffle+ (segnalato dall'utente il 30/10)**: con Shuffle+ già acceso, avviare un album o una playlist arricchisce la nuova coda con suggeriti basati sui brani della coda precedente. Sospetto: `_syncSource` svuota pool e semi, ma un `_fill`/`_suggestOne` già in corso (`shuffle_plus_controller.dart`) finisce con i semi vecchi e inserisce lo stesso; il controllo dopo `prepare` non guarda se la sorgente è cambiata. Da riprodurre con un test prima di correggere.
- **Coda di prima della Jam solo in memoria** (`JamController._saved`): l'ospite in «Coda insieme» perde la sua coda originale. Da valutare se salvarla su disco o restituirla intera.
- **Due code per le domande sulla cassa** (`SpeakerMonitor._pending` e la coda della UI): da unificare.
- La posizione mostrata nella Jam salta indietro di circa 1,3 s a ogni avvio di brano (`jam ui: shown position moved`).
- 53.10 completamento intero sul Motorola (fermo a 421/2317).
- Il messaggio «perché niente Shuffle+» (D-87) su un album da 1 brano.
- Gli interruttori del completamento che fermano il giro manuale.
- Il debito dello streaming, in fondo a `docs/fase-47-jam-online.md`.

## Prompt di avvio della prossima sessione
```
/obiettivo fase 70 (ponte e protocollo della «Jam a distanza», docs/fase-70-ponte-jam-distanza.md: prima §Rilievi dalla fase 69)
```

## Prossimi obiettivi
1. **(Consigliato) Fase 70, ponte e protocollo**: si parte dai rilievi della fase 69 scritti in cima al documento di fase. La prima scelta è il tipo delle chiavi in `JamCrypto` (D-272).
2. **69.4 a mano**: chiude anche i `[~]` delle fasi 67 e 68.
3. **Unificare le due code delle domande sulla cassa**.
4. **Ricerca «notte», build p99** (D-176) e prove d'ascolto 57.7.
