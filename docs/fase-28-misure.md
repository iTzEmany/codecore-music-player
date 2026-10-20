# Fase 28 — misure prima e dopo

Come si misura (28.1) e cosa è cambiato (28.10). Il Mi A3 non è disponibile: il telefono di misura è il
**Motorola edge 40** (molto più veloce, risultati ottimistici); il riferimento per «vecchio» resta 60 Hz,
cioè **16,7 ms** a frame.

## Strumenti
- **Telefono** — `scripts/perf_library.py` crea in `build/perf_library/` 3000 brani da 1 s in 300 album
  (copertina `cover.jpg` 1200×1200 per album, ~50 MB). `scripts/perf_device.py <id-adb> --label <nome>`
  compila la build *profile* come **app separata** `com.codecore.player.perf` (`CODECORE_PERF=1`, dati suoi:
  la libreria vera non si tocca), le passa la libreria, aspetta la scansione e l'«arricchimento» finto
  (testi, testi sincronizzati e curiosità su ogni brano, ~6 KB), poi misura: avvio a freddo (`am start -W`
  ×5 e tempo da `main` al primo frame), memoria (PSS), e i frame mentre scorre «Tutti i brani», «Album»,
  la ricerca e, con `--playback`, «In riproduzione». Tabella in `build/perf/<nome>.md`.
  I frame li misura l'app stessa (`FrameTiming`, `lib/services/perf/perf_probe.dart`, compilato solo nella
  build perf): `dumpsys gfxinfo` non vede i frame di Flutter, che disegna su una superficie sua.
- **Emulatore / CI** — `integration_test/perf_test.dart` (in `scripts/integration.sh`, job manuale
  «integration» della CI): stesso giro su 3000 brani arricchiti, tempi dei frame stampati (`perf28 …`).
  In debug i numeri valgono solo come confronto tra loro.
- **PC** — `test/data/performance_lists_test.dart` (3000 brani arricchiti) e `performance_50k_test.dart`;
  `CODECORE_PERF_MARGIN=1` per i numeri veri.

## Prima (2026-10-20, commit con tag `perf-prima`)
| Cosa | Valore | Dove |
|---|---|---|
| «Tutti i brani», un aggiornamento dell'elenco, 3000 brani arricchiti | 19 ms, **29,7 MB di testo** nelle righe | PC |
| 50 000 brani: ricerca / album / artisti / tutti i brani / per artista | 32 / 83 / 71 / 832 / 805 ms | PC |
| Ricerca YouTube · YouTube Music (già con 28.4) | 1,0–1,3 s · 1,1–1,7 s | Motorola, LTE |
| Scorrimenti, avvio, memoria con 3000 brani | da misurare: il telefono era in uso (importazione dell'utente) | Motorola |

Ogni scrittura nella tabella dei brani (un download, un arricchimento) fa ripartire le query degli elenchi
aperti: con le righe intere sono ~30 MB di testo copiati a ogni brano scaricato durante un'importazione.

## Dopo, task per task
| Task | Cosa | Prima → dopo | Dove |
|---|---|---|---|
| 28.2 | «Tutti i brani», 3000 brani arricchiti: testo nelle righe | 29,7 MB → **0,4 MB** | PC |
| 28.2 | Stesso elenco con il database in un isolate a parte, come nell'app | 88 ms → **14 ms** a ogni aggiornamento | PC |
| 28.2 | 50 000 brani: ricerca / album / artisti / tutti i brani / per artista | 32 / 83 / 71 / 832 / 805 → 34 / 79 / 68 / 820 / 785 ms (invariati) | PC |
| 28.3 | Decodificare una copertina per una riga di elenco (132 px): JPEG 1200 px / JPEG 3000 px / PNG 3000 px → miniatura 320 px | 8,6 / 50 / 138 ms → **2,9 ms** | PC |
