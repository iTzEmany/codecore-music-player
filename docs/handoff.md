# Handoff — 2026-10-23

## Stato
- Ultimo commit `52ff9c2`; tag locali `fase-36-ok` e `fase-37-ok`.
- Le fasi 36 (Deezer ed Exportify) e 37 (metadati che viaggiano) sono **complete nel codice**. Anche l'identità «Anello», fasi 1 e 2, è completa.
- `flutter analyze` è pulito e `flutter test` è verde (2446 test, 14:07). `flutter build linux` riesce.
- Database: schema **v14** (ISRC, Deezer). La migrazione v13→v14 è provata su un telefono vero (Mi A3, 69 righe intatte).
- Il piano di `docs/PROGRESS.md` è finito: dopo la fase 37 non ci sono altre fasi scritte.
- Restano solo task `[~]`, cioè prove a mano o su telefono, elencate sotto.

## Prove a mano che restano (dettaglio nelle righe `[~]` di PROGRESS)
- **36.12**
  - PC: importare un CSV di Exportify **piccolo** (2-3 playlist; mai l'Export All, che ha circa 10.000 brani) e controllare anno e copertine.
  - Poi sincronizzare quelle playlist.
- **37.7**
  - PC ↔ Motorola: inviare 5 brani scaricati da YouTube, uno con testo sincronizzato, e controllare i tag in un altro lettore (es. VLC).
  - Sincronizzare fra dispositivi fidati una playlist di 3 brani.
  - Download sul PC con «Scrivi i tag nei file scaricati» acceso e poi spento.
  - Ricevente con l'APK vecchio (provato solo come mittente).
- **31–34** (Shuffle+, ricerca, radio, nuove uscite): prove sul telefono ancora da fare (righe `[~]` 31.1, 31.15, 32.1, 32.10, 32.11, 33.x, 34.x).
- **17.7/17.8** (MPRIS/SMTC): bloccati in attesa dei pacchetti.
- **16.x** (CI): non sono provabili in locale; serve un push su GitHub.

## Già provato dal vivo il 23/10
- **Deezer** (`test/live/deezer_live_test.dart`): 17 brani su 20 trovati con l'album giusto. Una compilation trovata tramite ISRC non sovrascrive l'album.
- **Condivisione Mi A3 → Motorola**
  - Con l'APK vecchio arriva senza errori.
  - Con l'APK nuovo arrivano titolo, album, anno, genere, copertina e testi, e i tag vengono scritti nel file.
- **«Apri» da Chrome** propone Codecore (36.10). I promemoria funzionano (36.11).

## Dispositivi (vedi anche la memoria)
- **Motorola edge 40** `ZY22HKD85K`, Android 15
  - Contiene la libreria vera dell'utente: solo `install -r`, mai disinstallare né `pm clear`.
  - Non si leggono i file esterni dell'app via adb.
- **Mi A3** `0d7ae9df206e`, Android 11
  - Si può disinstallare con `-k`; mai cancellare file musicali.
  - Ha l'APK di debug nuovo, installato con `install -r -d` (con il solo `-r` va in VERSION_DOWNGRADE).
- **Leggere il DB dell'app:** `adb -s X exec-out run-as com.codecore.player cat app_flutter/codecore.sqlite` (più `-wal`), poi `python3 -I` con sqlite3.

## Trappole viste in questa sessione
- Il ricevente **non** applica l'`enrichStatus` del mittente: con 2 (fatto) il brano non verrebbe più riarricchito.
- I metadati ricevuti mettono `user_edited=1`, voluto: una riscansione non li cancella.
- Dopo la v14 non c'è una riscansione forzata: l'ISRC arriva solo da file nuovi o cambiati. Deezer ripiega sulla ricerca per testo.
- `audio_metadata_reader` non legge l'ISRC dagli m4a.
- Senza `country` iTunes cerca solo nel catalogo USA. Deezer non chiede un account (API pubblica), anche se Deezer Free non è disponibile in Italia.

## Prompt di avvio della prossima sessione
```
Leggi docs/handoff.md e docs/PROGRESS.md. <obiettivo scelto fra quelli sotto>
```

## Refactor «ui-fluida» (piano pronto, 2026-10-23)
- Il piano è pronto: fasi **38–44** in `docs/PROGRESS.md` e `docs/fase-38..44-*.md`. Le decisioni sono D-01..D-34 in `docs/decisioni.md`.
- Analisi, rilievi, rete e soglie: `docs/refactor/ui-fluida/analisi.md`.
- Mockup approvati (specifica visiva della fase 43), da aprire con `xdg-open`:
  - `docs/refactor/ui-fluida/mockup/` — now-playing, home, libreria, album-artista, onboarding;
  - `tokens.css`.
- Misura di partenza Mi A3: `build/perf/refactor-prima-mia3.md`.
- L'APK profile in `build/app/outputs/flutter-apk/app-profile.apk` si cancella nella fase 44.
- Avvio, in una nuova chat nella radice del progetto: `/obiettivo fase 38`.

## Prossimi obiettivi
0. **Refactor ui-fluida:** `/obiettivo fase 38` (poi 39 … 44, nell'ordine).
1. **(Consigliato)** Smaltire le prove a mano `[~]` delle fasi 31–37, con i telefoni collegati e il PC.
   - Sono funzioni già scritte ma mai viste dal vivo: è lì che si nascondono i difetti.
   - Comando: `/obiettivo prove a mano [~] fasi 31-37 con telefoni collegati`.
2. Scegliere la prossima fase da `docs/13-idee-future.md` («Le dieci che farei per prime») e scriverne il documento `docs/fase-38-*.md`.
3. Far girare la CI su GitHub (16.x) con un push, quando vuoi pubblicare il repo.
4. MPRIS/SMTC (17.7/17.8), se nel frattempo esistono i pacchetti.
