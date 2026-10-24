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

## Dopo la fase 39 (`fluidita-dopo`, 24/10)

Stesso telefono e stesso comando. Lo scorrimento di pagina è al 15 % della larghezza (D-46).

| Scenario | Frame | build p90/p99 ms | raster p90/p99 ms | > 16,7 ms | Prima | Soglia | ok |
|---|---|---|---|---|---|---|---|
| Pallino schede | 129 | 7.2 / 19.8 | 8.6 / 22.5 | 3,9 % | 5,8 % | ≤ 2 % | no |
| Tutti i brani | 355 | 5.5 / 12.0 | 9.0 / 16.8 | 1,1 % | 0,8 % | ≤ 1 % | no (pari) |
| Album | 708 | 3.6 / 6.6 | 9.0 / 13.6 | 0,4 % | 1,0 % | ≤ 0,6 % | sì |
| Ricerca «notte» | 134 | 4.0 / 30.1 | 12.0 / 19.2 | 9,7 % | 3,5 % | ≤ 3 %, build p99 ≤ 16 ms | no |
| Apri album | 69 | 6.0 / 36.5 | 9.5 / 13.9 | 4,3 % | 3,5 % | ≤ 3 % | no |
| Fogli | 1744 | 7.6 / 19.0 | 7.8 / 12.5 | 1,8 % | 1,7 % | ≤ 3 % | sì |
| Swipe mini player | 376 | 5.6 / 148.9 | 8.5 / 17.1 | 8,2 % | 8,7 % | ≤ 2 % | no |
| Apertura player | 548 | 10.6 / 71.9 | 7.5 / 15.5 | 6,8 % | 9,5 % | ≤ 3 %, p99 ≤ 33 ms | no |
| In riproduzione | 562 | 8.5 / 67.3 | 7.9 / 14.9 | 5,5 % | 7,7 % | non peggiorare | sì |
| Lettore dal dock | 907 | 10.3 / 119.1 | 7.9 / 14.5 | 7,9 % | 9,2 % | — | — |
| Anello | 489 | 9.2 / 23.9 | 6.5 / 13.0 | 2,7 % | 0,8 % | — | — |

| Altro | Valore | Prima | Soglia | ok |
|---|---|---|---|---|
| Avvio a freddo (mediana di 5) | 2415 ms | 2575 ms | ≤ 2400 ms | no (quasi) |
| PSS | 271 MB (219 MB in un giro breve) | 262 MB | ≤ 210 MB | no |

Altri giri dello stesso codice danno numeri vicini ma non uguali: con 69–140 frame, un frame vale 0,7–1,4 punti, e
«Ricerca» va dal 4,4 % al 9,7 %. Lo scorrimento a tutta larghezza misurato a parte dava «Apri album» al 10 % (D-46).

**Soglie non raggiunte (D-37: annotate, si prosegue).** I picchi stanno nei frame di **build**, non nel raster:
- Swipe e apertura del player (p99 72–149 ms): il cambio di brano ricostruisce il player e decodifica la copertina.
  Da guardare: `cacheWidth` e `gaplessPlayback` in `track_art.dart`, e le card che dipendono dal brano.
- Ricerca: `smartSearch` gira ancora in modo sincrono dentro il provider (39.10 ha tolto solo le ricostruzioni di troppo).
- Pallino schede: il primo frame di una scheda mai aperta costruisce tutta la pagina.
- Avvio e PSS: la libreria di prova più grande pesa; si rimisurano in fase 44.

Struttura dopo la fase 39: `Duration(milliseconds` 13 righe in 4 file (10 sono i token in `tokens.dart`, D-44);
`build` > 150 righe 16, con `now_playing_screen` cresciuto per le card dopo la transizione.

## Dopo la fase 41 (mattoni condivisi, 24/10)

| Metrica | Prima (fase 38) | Dopo la 41 | Arrivo |
|---|---|---|---|
| `SnackBar(` in `lib/ui` | 106 righe / 62 file | 1 (`show_msg.dart`) | 1 |
| `AppBar(` non `CcAppBar` | 48 | 1 (`cc_app_bar.dart`) + 2 `SliverAppBar` + 4 `SelectableAppBar` (varianti dichiarate) | 1 |
| `showModalBottomSheet` | 1 | 1 (`showCcSheet`) | 1 |
| `CircularProgressIndicator` | 32 | 28 | ≤ 3 (non raggiunto: quasi tutti spinner d'azione dentro bottoni e righe, D-50) |
| `LinearProgressIndicator` | 19 | 19 | — (barre con valore, non stati a mano) |
| `.when(` in `lib/ui` | — | 10 (sliver, caricamento/errore propri) | — |
| dialoghi del nome | 6 copie | 1 (`promptName`) | 1 |
| `build` > 120 / > 150 righe | 26 / 15 | 27 / 16 (di 319) | fase 42 |
| `build` più lungo | `library_screen.dart` 271 | `library_screen.dart` 276 | fase 42 |

`lib/app.dart` ha ancora uno `SnackBar(` (avviso di nuova versione: messenger globale senza context, 8 s): fuori da `lib/ui`, resta.
