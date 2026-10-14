# Modello dati (drift / SQLite)

Versione schema iniziale: **1**. Ogni modifica futura = `schemaVersion++` + migrazione scritta
in `onUpgrade` (mai distruttiva). Esporta lo schema con `drift_dev schema dump` se vuoi test di migrazione.

## Tabelle

### `tracks`
| Colonna | Tipo | Note |
|---|---|---|
| `id` | int PK autoincrement | identità interna |
| `path` | text UNIQUE | percorso assoluto sul dispositivo |
| `folderId` | int? | FK logica a `folders.id` (cartella radice di provenienza) |
| `title` | text | mai vuoto: fallback nome file senza estensione |
| `artist` | text? | null se ignoto |
| `albumArtist` | text? | |
| `album` | text? | null se ignoto |
| `albumKey` | text | vedi sotto; indicizzata |
| `trackNumber` | int? | |
| `discNumber` | int? | |
| `year` | int? | |
| `genre` | text? | |
| `durationMs` | int | 0 se ignota |
| `format` | text | estensione minuscola: `mp3`, `flac`, … |
| `sampleRateHz` | int? | |
| `bitDepth` | int? | |
| `bitrateKbps` | int? | |
| `channels` | int? | |
| `sizeBytes` | int | |
| `mtimeMs` | int | per scansione incrementale |
| `hasCover` | bool | default false |
| `coverKey` | text? | nome file della copertina in cache (senza estensione) |
| `isFavorite` | bool | default false |
| `lyricsPlain` | text? | |
| `lyricsSynced` | text? | testo LRC grezzo |
| `curiosities` | text? | estratto Wikipedia |
| `enrichStatus` | int | 0 mai tentato, 1 trovato, 2 non trovato |
| `userEdited` | bool | default false: se true l'arricchimento **non** sovrascrive titolo/artista/album |
| `missing` | bool | default false: file non trovato all'ultima scansione |
| `sha256` | text? | calcolato solo su richiesta |
| `addedAt` | int | epoch ms |
| `playCount` | int | default 0 |
| `lastPlayedAt` | int? | |

Indici: `albumKey`, `artist`, `isFavorite`, `(missing)`, `title COLLATE NOCASE`.

### `folders`
`id` int PK · `path` text UNIQUE · `addedAt` int · `label` text?

### `playlists`
`id` int PK · `name` text · `createdAt` int

### `playlist_tracks`
`playlistId` int · `trackId` int · `position` int · PK(`playlistId`,`trackId`) ·
ON DELETE CASCADE su entrambe (drift: `references(..., onDelete: KeyAction.cascade)`).
Indice su `trackId`.

> Un brano non può comparire due volte nella stessa playlist (scelta voluta, come nella versione Python).

## `albumKey` (chiave di raggruppamento album)
Calcolata in `text_utils.dart`, **sempre** con questa funzione:
```
normalize(s) = stripDiacritics(s).toLowerCase().trim() con spazi multipli → uno
artistPart   = normalize(albumArtist ?? artist ?? '')
albumPart    = normalize(album ?? '')

se albumPart è vuoto oppure in {'album sconosciuto','unknown','unknown album'}:
    albumKey = 'unknown|' + normalize(directory del file)      // raggruppa per cartella
altrimenti:
    albumKey = artistPart + '|' + albumPart
```
Etichetta mostrata in UI: `album` + (`albumArtist ?? artist`). Compilation: se in un albumKey ci
sono più artisti diversi e nessun `albumArtist`, mostra "Artisti vari" (calcolato in query, non salvato).

## Copertine su disco
- Cartella: `<appSupportDir>/covers/`. File: `<coverKey>.jpg` (o `.png` se l'originale è PNG).
- `coverKey` = SHA-1 esadecimale (pacchetto `crypto`) di `albumKey`. Una copertina per album.
- Ordine di ricerca: immagine incorporata nel primo brano dell'album → file `cover.jpg|folder.jpg|front.jpg|cover.png`
  nella stessa cartella → nessuna (`hasCover = false`, non ritentare finché il file cambia).

## Scansione incrementale
Un file è "invariato" se `(path, sizeBytes, mtimeMs)` coincidono con la riga esistente → non rileggere i tag.
File scomparsi: `missing = true` **solo se la cartella radice è raggiungibile**; altrimenti non toccare nulla
(chiavetta scollegata ≠ brani cancellati). Se un file `missing` ricompare → `missing = false`.

## Query tipiche (da implementare nel repository)
- Tutti i brani non missing, ordinati per `sort` (title/artist/album/year/addedAt/duration), con filtro testo.
- Album: `SELECT albumKey, MIN(album), albumArtistLabel, COUNT(*), SUM(durationMs), MIN(coverKey) FROM tracks WHERE missing=0 GROUP BY albumKey`.
- Preferiti: `isFavorite = 1`.
- Ricerca: `LIKE ? ESCAPE '\'` su title, artist, album con `%`/`_` escapati.

## Impostazioni (shared_preferences, non nel DB)
| Chiave | Tipo | Default | Valori |
|---|---|---|---|
| `theme` | string | `oled` | `oled`, `carbon`, `navy`, `light` |
| `fontScale` | double | 1.0 | 0.9, 1.0, 1.15 |
| `compactMode` | bool | false | |
| `reducedMotion` | bool | false | |
| `language` | string | `it` | `it`, `en`, `de`, `es` |
| `musicFolders` | list<string> | `[]` | percorsi radice |
| `autoEnrich` | bool | **false** | arricchimento web automatico |
| `autoLyrics` | bool | **false** | testi LRCLIB automatici |
| `showUndoSnackbar` | bool | true | annulla rimozione preferito |
| `lastQueueIds` | list<string> | `[]` | ultima coda |
| `lastIndex`, `lastPositionMs` | int | 0 | ripresa |
| `volume` | double | 1.0 | |
| `shuffle` | bool | false | |
| `repeat` | string | `off` | `off`, `all`, `one` |

Le vecchie impostazioni finte (crossfade, gapless, normalizzazione, "bit-perfect WASAPI", autoplay) **non** vengono portate.
