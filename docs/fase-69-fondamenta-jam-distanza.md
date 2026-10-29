# Fase 69 — Fondamenta (feature «Jam a distanza»)

**Obiettivo:** la Jam in LAN riceve l'anti-spam (2 richieste al minuto, Sospendi, Blocca) senza cambiare altro, e i due pacchetti nuovi sono provati prima di costruirci sopra: la crittografia coi vettori noti, i broker veri con «Prova connessione». Sono le prove dei rischi K-JD-01, K-JD-03, K-JD-04 e K-JD-07 (D-260).

**Prerequisiti:** fasi 65–68 chiuse (68.3 a mano non serve). Requisiti R-122, R-129, R-135, R-147 … R-150 (parte LAN), RNF-17; decisioni D-237 … D-239, D-244, D-247, D-251, D-252, D-255, D-258. Aree a rischio: protocollo Jam, primitive crittografiche, manifest e backup. Pacchetti nuovi: solo `sodium` e `mqtt_client` (§Stack di `docs/feature-jam-distanza.md`).

**Comando mirato:** `flutter test test/jam test/ui/jam_screen_test.dart test/ui/settings_index_test.dart test/ui/now_playing_test.dart test/data/settings_store_test.dart test/services/backup`; build `flutter build apk --debug` e `flutter build linux --debug` quando entrano i pacchetti (con `sorveglia.sh --pesante`).

## Task

### 69.1 — `JamGuestLink` senza spostare codice (RNF-17, K-JD-01)
`lib/services/jam/jam_guest_link.dart`: l'interfaccia di §Componenti (`states`, `lost`, `state`, `send`, `probeHostTime`, `invite`, `leave`, `cancelJoin`, `dispose`, `sessionId`/`hostBase`/`fileToken`). `JamGuest` la implementa; in `JamController` `_guest` diventa `JamGuestLink?`. Nessun comportamento cambia.

**Fatto quando:** `git diff origin/master -- test/jam` vuoto e comando mirato verde; `flutter analyze` pulito.

### 69.2 — `admitRequest` e `JamGate` (R-147 … R-150, D-238, D-239)
La validazione di `POST /request` passa in `JamHost.admitRequest(...)`, che il router chiama come oggi (il limite di 5/min per IP resta nel router). `lib/services/jam/jam_gate.dart`, puro con orologio iniettato: 2 richieste al minuto per id (finestra scorrevole, oltre → 429), Sospendi con scadenza o «fine Jam», Blocca e Sblocca. Sospeso o bloccato → richiesta `silent` (202, mai mostrata, non conta per «busy», scade a `jamRequestTtl`). `lib/data/settings/jam_secret_store.dart` (interfaccia chiave–valore su `SharedPreferencesAsync`, mappa nei test) con `jamBlocked` e `jamSuspended`; le sospensioni «fine Jam» si tolgono all'avvio e a fine Jam. Esclusione dal backup Android del file DataStore con `backup_rules.xml` e `data_extraction_rules.xml`.

**Fatto quando:** test con orologio finto di 2/min (terza scartata, dopo 60 s di nuovo accettata), Sospendi 15 min (scartate; a 15 min + 1 s accettate; riavvio simulato con la stessa mappa), «fine Jam», Blocca/Sblocca dopo il riavvio; test che `settingsToJson` non contiene le chiavi del `JamSecretStore`; gli altri test di `test/jam` invariati.

### 69.3 — Sospendi, Blocca e l'avviso dell'ospite (R-147 … R-149, D-237)
`lib/ui/widgets/duration_choice_sheet.dart`: `showDurationChoiceSheet` estratto da `_showSleepSheet` (`now_playing_controls.dart`), usato dal timer e da Sospendi (15, 30, 45, 60 min, «Fino alla fine della Jam»). `jam_request_dialog.dart`: Accetta, Rifiuta, Sospendi, Blocca. Impostazioni della Jam: «Dispositivi bloccati» con «Sblocca» e «Sospesi» con la scadenza. `JamController.request`: contatore locale, alla terza richiesta in 60 s «Aspetta un momento prima di riprovare» senza inviarla. Stringhe ARB it/en/de/es.

**Fatto quando:** test widget del foglio di durata nei due usi (il timer di spegnimento si comporta come prima), del dialogo con quattro azioni, delle liste nelle impostazioni e dell'avviso dell'ospite; `settings_index_test` aggiornato.

### 69.4 — `sodium` nella build e vettori noti (R-135, K-JD-03, K-JD-07)
`sodium` ^4.1.2 nel pubspec; `lib/services/jam/remote/jam_crypto.dart`: `JamCrypto` e `SodiumJamCrypto` con le sole primitive di §Componenti, inizializzate con `SodiumSumoInit.init()`, casualità iniettabile. Ancora nessun uso nell'app.

**Fatto quando:** `test/jam/remote/jam_crypto_test.dart` verde con i vettori di RFC 5869 A.1 (HKDF-SHA-256), draft-irtf-cfrg-xchacha-03 A.3.1 (XChaCha20-Poly1305), libsodium per `kx` e `auth`, più un andata e ritorno di `pad`/`unpad`; `flutter build apk --debug` e `flutter build linux --debug` verdi in locale; la CI della PR verde con i tempi annotati nel documento di fase (anche le build Windows e macOS, se girano sulla PR). Hook fallito o CI oltre il doppio dei tempi di oggi → fermati e scrivilo in «Tocca a te» (K-JD-07).

### 69.5 — Broker e «Prova connessione» (R-122, R-129, D-244, D-251, D-258, K-JD-04)
`mqtt_client` ^10.14.0. `lib/services/jam/remote/mqtt_link.dart`: `MqttLink` e `MqttClientLink` come in §Componenti (TLS con `SecurityContext.defaultContext`, `onBadCertificate` null, `autoReconnect` false, `clientId` casuale). `BrokerEntry` (host, porta, TLS) e `jamBrokers` in shared_preferences con `kDefaultJamBrokers`. `lib/ui/screens/settings/jam_remote_settings.dart`: lista dei broker (aggiungi, togli, riordina, «Ripristina»), avviso per una voce senza TLS, «Prova connessione» (connessione, iscrizione e pubblicazione su un canale casuale, ritorno del messaggio entro 5 s).

**Fatto quando:** test della validazione (host non vuoto, porta 1–65535), test widget di aggiunta, riordino, ripristino, avviso senza TLS e «Prova» con un `FakeMqttLink` riuscito e fallito; `test/live/jam_broker_live_test.dart` (si salta da sé senza `CODECORE_LIVE=1`, come gli altri di `test/live/`) eseguito una volta in locale: `broker.emqx.io:8883` e `test.mosquitto.org:8886` riusciti, `test.mosquitto.org:8883` rifiutato per il certificato (R-129); esiti con la data in questo documento.

### 69.6 — Controlli di fase
`flutter analyze`, comando mirato, build di debug, `/code-review high` su 69.2 e 69.4, scheggia in modalità passo su 69.2 (gate) e 69.5 (validazione dei broker), review di architettura Opus di `JamGuestLink` e `admitRequest`. Prova sul Mi A3 col Linux in LAN (D-91): richieste ripetute, Sospendi 15 min, Blocca e Sblocca.

**Fatto quando:** tutto verde; esiti della prova qui sotto; colonna Fase di R-147 … R-149 e RNF-17 compilata.
