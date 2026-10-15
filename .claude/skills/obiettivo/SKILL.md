---
name: obiettivo
description: Esegue in autonomia totale il piano di Codecore (docs/PROGRESS.md) task dopo task, con test e verifica in locale e commit di checkpoint, senza chiedere nulla all'utente finché non viene fermato. Si lancia con /obiettivo [fase N | testo libero]; anche /obiettivo stato | pausa | riprendi [file].
argument-hint: [fase N | fino alla fase N | testo libero] | stato | pausa | riprendi [file]
disable-model-invocation: true
---

# Obiettivo autonomo (Codecore)

Argomenti: `$ARGUMENTS`

Interpretazione:
- `stato` → `scripts/obiettivo.sh stato`, riassumi in 5 righe e fermati.
- `pausa` → `scripts/obiettivo.sh chiudi PAUSA "richiesta dell'utente"`, di' a che punto sei (3 righe) e fermati.
- `riprendi` o `riprendi <file>` → `scripts/obiettivo.sh riprendi [file]`, rileggi il file stampato e `docs/PROGRESS.md`, vai al **passo 2**.
- **vuoto** → obiettivo = «completa il piano di `docs/PROGRESS.md` dalla Fase 0 alla Fase 5, nell'ordine, partendo dal primo task `[ ]`». Fase 6 e 7 solo se richieste esplicitamente.
- `fase N` / `fino alla fase N` / testo libero → obiettivo = quanto scritto, limitato a quel perimetro.

## Regole fisse (non si discutono durante l'obiettivo)
1. **Non chiedere niente all'utente.** Niente `AskUserQuestion`, niente «procedo?», niente «vuoi che…?». Se la documentazione è ambigua scegli l'opzione più semplice coerente con `docs/01…04` e annotala (passo 5).
2. **La memoria sei tu fuori dal contesto**: il file dell'obiettivo (`scripts/obiettivo.sh file`) e `docs/PROGRESS.md`. Dopo una compattazione del contesto la prima cosa è rileggerli.
3. **Niente programmi in primo piano che restano in attesa** (mai `flutter run` in primo piano, mai finestre desktop). Verifica = `flutter analyze` + `flutter test` + (quando serve) `flutter build`. Per ogni schermata nuova scrivi almeno **un widget test** di fumo (`testWidgets`: si costruisce senza eccezioni, mostra gli elementi chiave). Unica eccezione ammessa: la **prova su telefono** del §6.1, quando un documento di fase la chiede.
4. **Comandi lunghi sempre con stima**, in background, via `scripts/sorveglia.sh <stima> <log> -- <comando>` (a 2× diagnosi, a 3× viene fermato). Stime: `flutter pub get` 2m · `dart run build_runner build --delete-conflicting-outputs` 4m · `flutter analyze` 2m · `flutter test` 4m · `flutter build apk --debug` 20m la prima volta, 8m dopo · `flutter build linux` 10m · `flutter create` 3m. Mai `sleep` in ciclo.
5. **Lavora solo dentro `codecore_flutter/`.** La vecchia app in `../codecore/` è solo da leggere. La guardia (`.claude/hooks/guard.sh`) nega sudo, push, comandi git distruttivi e scritture fuori progetto: se nega, **leggi il motivo e segui l'alternativa**, non aggirare.
6. L'hook Stop ti rimanda al lavoro finché lo stato è `IN CORSO`. Per fermarti davvero: `scripts/obiettivo.sh chiudi FATTO|BLOCCATO|PAUSA "<motivo>"`.
7. **Se l'utente ti scrive durante l'obiettivo**: rispondi brevemente. Se chiede di fermarti, cambiare rotta o dice «stop/pausa» → `chiudi PAUSA` subito. Se è solo una domanda, rispondi e riprendi il lavoro.
8. Regole di codice e di qualità: `docs/01-regole-di-lavoro.md` (valgono tutte).

## 1. Avvio (una volta)
1. `scripts/obiettivo.sh nuovo "<obiettivo>"` → stampa il percorso (FILE). Compila «Criterio di fatto» (es. «tutti i task delle fasi 0–5 spuntati, `flutter analyze` e `flutter test` verdi, `flutter build apk --debug` riesce»).
2. Leggi `CLAUDE.md`, `docs/01-regole-di-lavoro.md`, `docs/02-architettura.md`, `docs/03-modello-dati.md`, `docs/04-specifiche-da-python.md` e `docs/PROGRESS.md`.
3. **Repo git locale** (checkpoint): se `git rev-parse --show-toplevel` non coincide con la cartella del progetto, esegui `git init` qui e fai un primo commit dei file esistenti (`git add -A && git commit -m "chore: piano iniziale"`). Se manca l'identità git, usa `git -c user.name="Codecore Agent" -c user.email="agent@codecore.local" commit …`. Il `.gitignore` deve contenere `.claude/obiettivi/`, `.claude/settings.local.json`, `build/`, `.dart_tool/`, `android/key.properties`, `*.jks`: verificalo anche dopo `flutter create`.
4. Controlla l'ambiente e annota in «Tocca a te» ciò che manca, **senza fermarti**:
   - `pkg-config --exists mpv` → se manca: «`sudo apt install libmpv-dev mpv libsqlite3-dev`» (serve solo per compilare/avviare il desktop Linux; `flutter test`, `analyze` e la build Android funzionano lo stesso: usa quelli).
   - `flutter doctor` → licenze Android: «`flutter doctor --android-licenses`» se serve.

## 2. Scelta del task
1. Primo `- [ ]` di `docs/PROGRESS.md` nel perimetro dell'obiettivo. Legenda: `[ ]` da fare · `[~]` codice fatto e verificato dai test, manca solo una prova a mano dell'utente · `[x]` fatto.
2. Leggi **solo** la sezione di quel task nel documento di fase e i file che toccherai.
3. Il task richiede qualcosa che non puoi fare (telefono, ascolto, sudo, Windows)? Fai la parte di codice, verificala con i test, segnala la prova manuale in «Tocca a te» (formato `- [ ] <task>: <cosa provare, su quale dispositivo, comandi>`) e segnalo `[~]`. Se è **impossibile** farne qualsiasi parte, salta al task successivo che non ne dipende.

## 3. Ciclo di un task
1. **Lavoro**: implementa esattamente il task (+ test della logica pura come da `docs/01` §7).
2. **Verifica** nell'ordine, ognuna con `sorveglia.sh`: `dart run build_runner build --delete-conflicting-outputs` (solo se tocchi tabelle drift) → `flutter analyze` → `flutter test`. Se il task lo prevede: `flutter build apk --debug`.
3. **Se è rosso**: leggi l'errore, correggi la causa (non la spia), rilancia. Massimo **3 tentativi con approcci diversi**; mai lo stesso comando uguale senza aver cambiato qualcosa. Dopo il terzo: `git stash push -u -m "bloccato-<task>"`, annota diagnosi in FILE, segna il task in PROGRESS come `[ ] (BLOCCATO: <motivo breve>)`, passa ai task che non ne dipendono. Se tutto ciò che resta dipende dal bloccato → `chiudi BLOCCATO`.
4. **Se è verde — checkpoint**: spunta il task in `docs/PROGRESS.md` (`[x]` o `[~]`), poi
   `git add -A && git commit -m "<tipo>(<fase>): <task> — <descrizione breve>"` con il trailer `Co-Authored-By` del modello in uso. Tipi: `feat`, `fix`, `test`, `chore`, `docs`. **Mai** committare con test rossi.
5. `scripts/obiettivo.sh registro "task X.Y fatto: <una riga>"`.
6. Torna al passo 2.

## 4. Fine di una fase
Quando tutti i task della fase sono `[x]`/`[~]`: verifica la sua «Definition of Done», lancia l'intera suite (`flutter analyze`, `flutter test`), poi `git tag fase-N-ok` e una riga nel registro. Se sono presenti prove manuali, elencale in «Tocca a te» in un solo blocco leggibile. Prosegui con la fase successiva senza fermarti.

## 5. Decisioni
1. Cerca la risposta nei documenti `docs/01…04`, poi nella fase corrente.
2. Se manca: scegli l'opzione più semplice e reversibile, e scrivila **subito** in FILE («Decisioni prese in autonomia») e nelle «Note di deviazione» di `docs/PROGRESS.md`.
3. Non cambiare lo stack né lo schema dati già definiti: se un pacchetto non funziona, applica il piano B di `docs/99-rischi-e-fallback.md`; se non basta, segna il task bloccato.

## 6. Quando serve l'utente o ti blocchi
- Tutto ciò che è solo suo va in «Tocca a te» con **comandi da incollare** e dispositivo. Non blocca gli altri task.
- Se `PushNotification` è disponibile, manda **una** notifica quando compare la prima voce «Tocca a te» e una a fine obiettivo; mai più di una ogni ora.
- Android con telefono collegato (`adb devices` mostra un dispositivo): puoi `flutter install`/`adb install` l'APK di debug per lasciarlo pronto. Avviarlo e pilotarlo solo con la procedura del §6.1.

### 6.1 Prova su telefono (solo se il documento di fase la chiede)
Prerequisiti, altrimenti **salta** e scrivi la prova in «Tocca a te»: `adb devices` mostra un dispositivo `device`; dopo `adb shell input keyevent KEYCODE_WAKEUP` lo screenshot **non** mostra la schermata di blocco.
0. `mkdir -p build/device_shots` (ignorata da git).
1. Avvio **in background** (strumento Bash con `run_in_background`, non via `sorveglia.sh`):
   `flutter run -d <id> --debug --pid-file "build/device_shots/cc.pid" > "build/device_shots/run.log" 2>&1`. Pronto quando il log contiene `Flutter run key commands` (aspetta con Monitor, mai `sleep` in ciclo; tetto 15 min alla prima compilazione).
2. Dopo una modifica: `kill -USR1 $(cat "build/device_shots/cc.pid")` = hot reload; `kill -USR2` = hot restart (serve se cambi provider, `main`, costanti). Controlla nel log `Reloaded`.
3. Screenshot: `adb exec-out screencap -p > "build/device_shots/<task>_<nome>.png"` e **aprilo** con lo strumento di lettura immagini. Gesti: `adb shell input tap X Y`, `adb shell input swipe X1 Y1 X2 Y2 300`, `adb shell input keyevent KEYCODE_BACK`. Ricava le coordinate dallo screenshot (risoluzione: `adb shell wm size`).
4. A fine prova: `kill $(cat "build/device_shots/cc.pid")`. Mai lasciare `flutter run` attivo tra un task e l'altro.
5. **Mai disinstallare l'app** né cancellarne i dati (`adb uninstall`, `pm clear`): sul telefono c'è la libreria vera dell'utente. Se l'installazione fallisce per firma diversa (APK release già installato) o versione più bassa, **fermati**, non accettare la reinstallazione proposta da `flutter run`, e scrivi in «Tocca a te» cosa serve.
6. Non toccare i dati dell'utente durante la prova: niente eliminazione di playlist/cartelle, niente svuota cache, niente invii o Jam verso altri dispositivi.
7. Esito: screenshot citati nel registro (`scripts/obiettivo.sh registro`), difetti visti → correggili nello stesso task. La prova su telefono **non sostituisce** `flutter analyze`/`flutter test`.

## 7. Chiusura
Quando non resta nessun `[ ]` nel perimetro (o restano solo bloccati/da fare dell'utente):
1. `git tag` finale se mancante, `git log --oneline | head` come riepilogo.
2. `scripts/obiettivo.sh chiudi FATTO "<riassunto: N task fatti, M da verificare a mano, K bloccati>"`.
3. Messaggio finale all'utente (max 10 righe): cosa funziona, cosa deve provare lui (rimanda a «Tocca a te»), cosa è bloccato e perché.
