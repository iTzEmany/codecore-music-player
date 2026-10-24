# Misure del refactor «ui-fluida»

Mi A3 (`0d7ae9df206e`), build profile, app separata `com.codecore.player.perf` (D-19), riproduzione attiva.
Comando: `python3 scripts/perf_device.py 0d7ae9df206e --label <label> --playback`. File grezzi in `build/perf/<label>.md`.
Gli scenari nuovi della 38.2 (Apri album, Fogli, Swipe mini player, Apertura player) contano solo i frame dei gesti
(da poco prima a 0,8 s dopo); gli altri usano la finestra intera dello scenario.

## Prima (`ui-fluida-prima`, 24/10, fase 38)

| Scenario | Frame | build p90/p99 ms | raster p90/p99 ms | > 16,7 ms | Soglia | ok |
|---|---|---|---|---|---|---|
| Pallino schede | 154 | 5.9 / 20.9 | 10.4 / 18.6 | 5,8 % | ≤ 2 % | no |
| Tutti i brani | 359 | 4.9 / 8.4 | 9.3 / 14.7 | 0,8 % | ≤ 1 % | sì |
| Album | 707 | 3.3 / 4.7 | 7.3 / 14.9 | 1,0 % | ≤ 0,6 % | no |
| Ricerca «notte» | 142 | 4.1 / 57.4 | 7.8 / 13.1 | 3,5 % | ≤ 3 %, build p99 ≤ 16 ms | no |
| Apri album | 86 | 5.5 / 36.3 | 10.2 / 12.4 | 3,5 % | ≤ 3 % | no |
| Fogli | 1916 | 6.7 / 17.3 | 7.7 / 13.5 | 1,7 % | ≤ 3 % | sì |
| Swipe mini player | 357 | 8.5 / 101.3 | 8.6 / 19.4 | 8,7 % | ≤ 2 % | no |
| Apertura player | 538 | 10.8 / 116.0 | 11.2 / 20.4 | 9,5 % | ≤ 3 %, p99 ≤ 33 ms | no |
| In riproduzione | 478 | 8.8 / 69.1 | 7.9 / 16.5 | 7,7 % | non peggiorare | — |
| Lettore dal dock | 1024 | 11.5 / 70.6 | 8.9 / 16.4 | 9,2 % | — | — |
| Anello | 480 | 8.3 / 15.4 | 6.2 / 9.2 | 0,8 % | — | — |

| Altro | Valore | Soglia | ok |
|---|---|---|---|
| Avvio a freddo (mediana di 5) | 2575 ms | ≤ 2400 ms | no |
| Da `main` al primo frame | 740 ms | — | — |
| PSS | 262 MB | ≤ 210 MB | no |

Nota: avvio e PSS sono peggiori della misura del 22/10 (2363 ms, 201 MB) a parità di codice di prodotto. È probabile
che conti la libreria di prova più grande o lo stato del telefono, e la fase 39 lo verifica.

## Struttura (`python3 scripts/build_len.py lib/ui --metrics`, 24/10)

| Metrica | Prima | Arrivo |
|---|---|---|
| `databaseProvider\|RepositoryProvider` | 74 righe / 44 file | 0 |
| `SnackBar(` | 106 righe / 62 file | 1 |
| `AppBar(` | 48 righe / 42 file | 1 |
| `Duration(milliseconds` | 28 righe / 21 file | ≤ 3 (token) |
| `build` > 120 righe | 26 (di 314) | 0 |
| `build` > 150 righe | 15 | 0 |
| `build` più lungo | `library_screen.dart` 271 righe | ≤ 120 |
