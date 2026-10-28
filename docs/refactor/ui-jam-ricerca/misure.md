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

## Dopo la fase 60 (`ui-jam-ricerca-60`)

Data: 2026-10-28. Commit `0acd0f1` (ramo `refactor/60-ricerca-e-dock`), stesso dispositivo e comando di «Prima» con `--only "Pallino schede,Tutti i brani,Album,Ricerca «notte»,Fogli,Swipe mini player"`. File grezzo: `build/perf/ui-jam-ricerca-60.md`.

PSS 249 MB (Prima 247, +0,8 %; soglia ≤ 210 MB, fuori come prima). Scansione 3000 brani in 17,0 s (Prima 18,2).

| Scenario | Frame | build p90/p99 ms | raster p90/p99 ms | > 16,7 ms | Soglia | ok | Confronto con Prima |
|---|---|---|---|---|---|---|---|
| Pallino schede | 1623 | 6.8 / 11.4 | 7.1 / 16.2 | 1,2 % | ≤ 2 % | sì | > 16,7: 0,9 → 1,2 % (+0,3 pt), build p99 migliore |
| Tutti i brani | 455 | 5.6 / 12.4 | 8.1 / 15.3 | 1,1 % | ≤ 1 % | no (di 0,1 pt) | 4,0 → 1,1 %: molto meglio |
| Album | 1179 | 5.0 / 9.1 | 7.6 / 17.7 | 1,6 % | ≤ 0,6 % | no | 0,5 → 1,6 %: PEGGIO (+1,1 pt), raster p99 13,6 → 17,7 |
| Ricerca «notte» | 138 | 6.6 / 31.5 | 6.9 / 12.4 | 3,6 % | ≤ 3 %, build p99 ≤ 16 ms | no (> 3 % e build p99) | build p99 34,5 → 31,5 (-9 %, ancora il doppio della soglia); > 16,7: 2,8 → 3,6 % (+0,8 pt, +29 % relativo): PEGGIO |
| Swipe mini player | 423 | 6.4 / 15.6 | 7.9 / 10.3 | 0,9 % | ≤ 2 % | sì | 0,3 → 0,9 %, build p99 14,2 → 15,6 (+10 %), dentro soglia |
| Fogli | 1350 | 9.1 / 22.8 | 7.1 / 12.0 | 2,7 % | ≤ 3 % | sì | 3,7 → 2,7 %: meglio, ora dentro soglia |

Esito (D-170: oltre soglia ≤ 10 % accettato, peggio blocca):
- Swipe mini player: dentro soglia (0,9 % ≤ 2 %), nessun blocco.
- Ricerca «notte»: build p99 31,5 ms resta oltre 16 ms ma è migliorato del 9 % rispetto a Prima (34,5): non peggiora. La quota di frame > 16,7 ms invece sale da 2,8 a 3,6 % ed esce dalla soglia ≤ 3 %: peggio rispetto a Prima, quindi blocca secondo D-170. Campione piccolo (138 frame: 5 frame lenti contro 4).
- Album peggiora (0,5 → 1,6 %, oltre soglia 0,6 %) in raster, non in build: blocca secondo D-170.
- Tutti i brani resta 0,1 pt sopra soglia ma migliora molto (4,0 → 1,1 %): non è un peggioramento, accettato come miglioramento parziale.
- Pallino schede +0,3 pt (dentro soglia). Fogli passa in soglia.
### Dopo la correzione 60.6 (`ui-jam-ricerca-60b`, 9aae22d)

Stesso comando con `--only "Pallino schede,Tutti i brani,Album,Ricerca «notte»"`. File grezzo: `build/perf/ui-jam-ricerca-60b.md`. PSS 224 MB (Prima 247, -60: 249), scansione 16,9 s.

| Scenario | Frame | build p90/p99 ms | raster p90/p99 ms | > 16,7 ms | Soglia | ok | Prima | -60 |
|---|---|---|---|---|---|---|---|---|
| Pallino schede | 1626 | 6.9 / 12.1 | 13.4 / 20.4 | 5,4 % | ≤ 2 % | no | 0,9 % | 1,2 % |
| Tutti i brani | 463 | 5.3 / 13.2 | 8.3 / 15.4 | 0,6 % | ≤ 1 % | sì | 4,0 % | 1,1 % |
| Album | 1183 | 4.0 / 6.8 | 6.8 / 13.0 | 0,6 % | ≤ 0,6 % | sì | 0,5 % | 1,6 % |
| Ricerca «notte» | 143 | 5.2 / 27.5 | 7.6 / 14.6 | 4,9 % | ≤ 3 %, build p99 ≤ 16 ms | no | 2,8 %, build p99 34,5 | 3,6 %, build p99 31,5 |

Esito: Album rientra (0,6 %, uguale alla soglia; Prima 0,5) e Tutti i brani rientra. Ricerca «notte»: build p99 27,5 ms (meglio di Prima -20 % e di -60 -13 %) ma ancora sopra 16 ms, e i frame > 16,7 ms salgono a 4,9 % (7 su 143; Prima 2,8, -60 3,6): peggio di Prima, blocca secondo D-170. Pallino schede 5,4 % è un peggioramento forte (Prima 0,9) dovuto al raster (p90 13,4, p99 20,4) mentre il build è invariato: scenario che non tocca la ricerca, possibile rumore del telefono o effetto del lavoro in isolate; da riconfermare con una seconda misura prima di attribuirlo al codice.
### Dopo la review (`ui-jam-ricerca-60c`, bbf2879)

Stesso comando di `-60b` con `--only "Pallino schede,Tutti i brani,Album,Ricerca «notte»"`. File grezzo: `build/perf/ui-jam-ricerca-60c.md`. PSS 221 MB (Prima 247), scansione 17,4 s. Nota: in `-60b` il precaricamento al focus non era attivo (non partiva); in `-60c` lo è.

| Scenario | Frame | build p90/p99 ms | raster p90/p99 ms | > 16,7 ms | Soglia | ok | Prima | -60 | -60b |
|---|---|---|---|---|---|---|---|---|---|
| Pallino schede | 1707 | 6.1 / 9.9 | 7.1 / 10.5 | 0,5 % | ≤ 2 % | sì | 0,9 % | 1,2 % | 5,4 % |
| Tutti i brani | 460 | 6.0 / 13.7 | 8.2 / 11.8 | 0,9 % | ≤ 1 % | sì | 4,0 % | 1,1 % | 0,6 % |
| Album | 1180 | 4.5 / 9.6 | 7.3 / 16.0 | 0,9 % | ≤ 0,6 % | no (+0,3 pt) | 0,5 % | 1,6 % | 0,6 % |
| Ricerca «notte» | 139 | 6.4 / 26.1 | 7.1 / 16.1 | 2,9 % | ≤ 3 %, build p99 ≤ 16 ms | no (solo build p99) | 2,8 %, p99 34,5 | 3,6 %, p99 31,5 | 4,9 %, p99 27,5 |

Esito: Ricerca «notte» ha ora la quota di frame lenti dentro soglia (2,9 %, praticamente come Prima 2,8) e build p99 26,1 ms: -24 % rispetto a Prima (34,5) ma ancora oltre i 16 ms. Non peggio di Prima, ma resta fuori soglia come Prima. Album 0,9 % è sopra 0,6 % (Prima 0,5, +0,4 pt; 11 frame su 1180, variazione tra run vista anche in `-60b`/`-60`): peggio di Prima, per D-170 blocca. Pallino schede e Tutti i brani in soglia.

## Dopo (fase 64)

Da riempire con lo stesso comando e la stessa tabella.
