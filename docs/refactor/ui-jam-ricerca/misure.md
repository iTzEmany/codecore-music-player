# Misure del refactor «ui-jam-ricerca»

Data: 2026-10-28. Dispositivo: Mi A3 (`0d7ae9df206e`), build profile, app separata `com.codecore.player.perf`.
Commit di partenza: `d3c03bb` (ramo `test/58-rete-jam-ricerca`). Senza `--playback`.
Comando: `python3 scripts/perf_device.py 0d7ae9df206e --label ui-jam-ricerca-prima --only "Pallino schede,Tutti i brani,Album,Ricerca «notte»,Fogli,Swipe mini player,Apertura player,Anello"`
(Tutti i brani e Album servono: gli scenari sono concatenati.) File grezzo: `build/perf/ui-jam-ricerca-prima.md`.
Soglie: fase 38 (vedi `docs/refactor/ui-fluida/misure.md`, D-57, D-175).

## Prima (`ui-jam-ricerca-prima`)

PSS 247 MB (soglia ≤ 210 MB, fuori). Scansione 3000 brani in 18,2 s.

| Scenario | Frame | build p90/p99 ms | raster p90/p99 ms | > 16,7 ms | Soglia | ok |
|---|---|---|---|---|---|---|
| Pallino schede | 1646 | 7.1 / 12.5 | 7.3 / 11.9 | 0,9 % | ≤ 2 % | sì |
| Tutti i brani | 453 | 5.8 / 14.6 | 8.7 / 23.7 | 4,0 % | ≤ 1 % | no |
| Album | 1179 | 5.0 / 9.3 | 7.1 / 13.6 | 0,5 % | ≤ 0,6 % | sì |
| Ricerca «notte» | 142 | 4.1 / 34.5 | 7.5 / 14.7 | 2,8 % | ≤ 3 %, build p99 ≤ 16 ms | no (build p99) |
| Swipe mini player | 387 | 4.6 / 14.2 | 7.0 / 10.7 | 0,3 % | ≤ 2 % | sì |
| Fogli | 1258 | 11.7 / 25.2 | 7.2 / 12.2 | 3,7 % | ≤ 3 % | no |
| Apertura player | 412 | 4.7 / 35.1 | 8.3 / 13.2 | 2,4 % | ≤ 3 %, p99 ≤ 33 ms | no (build p99 35,1) |
| Anello | 305 | 9.7 / 13.6 | 5.2 / 8.4 | 0,3 % | — | — |

## Dopo (fase 64)

Da riempire con lo stesso comando e la stessa tabella.
