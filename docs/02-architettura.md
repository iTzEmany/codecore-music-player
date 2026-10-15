# Architettura

## Principi
- **Un solo processo, nessun server.** Tutto gira nell'app.
- **Livelli** (le dipendenze vanno solo verso il basso):
  `ui` → `providers` → `services` / `data` → `core`.
- Servizi con interfacce per ciò che dipende da pacchetti esterni fragili.
- Android e desktop condividono tutto il codice; le differenze stanno in `lib/core/platform.dart`
  e in 3 punti ben isolati (permessi, cartella predefinita, notifica media).

## Struttura cartelle (`lib/`)
```
lib/
  main.dart                       # init (media_kit su desktop, audio_service su Android), ProviderScope
  app.dart                        # MaterialApp, tema, localizzazioni
  core/
    app_log.dart                  # AppLog.d/i/w/e (print in debug, file di log ruotato in release)
    platform.dart                 # isAndroid, isDesktop, defaultMusicDir()
    paths.dart                    # appSupportDir, coversDir, downloadsDir
    text_utils.dart               # normalize(), stripDiacritics(), sanitizeFileName()
  data/
    db/tables.dart                # definizioni drift
    db/app_database.dart          # AppDatabase (+ .g.dart generato)
    repositories/
      track_repository.dart
      playlist_repository.dart
      folder_repository.dart
    settings/settings_store.dart  # shared_preferences + modello AppSettings
  services/
    tags/tag_reader.dart                  # interfaccia + TagInfo
    tags/audio_metadata_tag_reader.dart   # implementazione con audio_metadata_reader
    scanner/library_scanner.dart
    covers/cover_store.dart               # salva/trova copertine su disco
    audio/play_queue.dart                 # logica pura di coda/shuffle/repeat
    audio/codecore_audio_handler.dart     # wrapper just_audio (+ BaseAudioHandler)
    online/query_cleaner.dart             # (fase 5)
    online/itunes_client.dart
    online/lrclib_client.dart
    online/lrc_parser.dart
    online/wikipedia_client.dart
    online/enrichment_service.dart
    online/youtube_service.dart
    share/lan_server.dart, lan_client.dart, offers.dart, discovery.dart  # (fase 6)
    jam/jam_state.dart, jam_host.dart, jam_guest.dart, jam_output.dart, jam_cache.dart  # (fase 8)
  providers/                      # provider Riverpod (database, settings, player, library, ...)
  ui/
    theme/app_theme.dart
    shell/app_shell.dart          # navigazione adattiva + mini player
    screens/                      # una cartella per schermata
    widgets/                      # widget riusabili (track_tile, cover_image, ...)
  l10n/                           # app_it.arb, app_en.arb, app_de.arb, app_es.arb (fase 4)
test/                             # specchio di lib/ per la logica pura
```

## Flussi principali
**Scansione:** UI (cartelle scelte) → `LibraryScanner.scan()` in isolate → `TagReader` →
`TrackRepository.upsertBatch()` → `Stream<List<Track>>` → UI si aggiorna da sola.

**Riproduzione:** UI tocca un brano → `PlayerController.playQueue(snapshot, index)` →
`CodecoreAudioHandler` (just_audio) → stream di stato → provider → mini player / now playing.
Su Android, `AudioService` espone lo stesso handler a notifica, schermata di blocco, cuffie.

**Impostazioni:** `SettingsStore` (shared_preferences) → `settingsProvider` (Notifier) → tema/lingua/ecc.
Scritture con debounce 400 ms, mai in un handler di slider a ogni tick.

## Differenze per piattaforma
| Aspetto | Android | Windows / Linux |
|---|---|---|
| Backend audio | ExoPlayer (just_audio) | libmpv (just_audio_media_kit) |
| Notifica / lock screen | `audio_service` | non nella v1 (opzionale fase 7) |
| Permessi file | `READ_MEDIA_AUDIO` (+ `READ_EXTERNAL_STORAGE` ≤ API 32) | nessuno |
| Cartella musica predefinita | `/storage/emulated/0/Music` | `~/Music` (Linux), `%USERPROFILE%\Music` (Windows) |
| Cartella download | `getExternalStorageDirectory()/Music` (nessun permesso) | cartella musica scelta |
| Scelta cartella | `file_picker.getDirectoryPath()` | idem |

## Decisioni già prese (non rimetterle in discussione)
- Tag **solo in lettura** (`audio_metadata_reader`, puro Dart, nessun Rust). Le modifiche dell'utente vivono nel DB.
- Identità brano = `id` intero DB + `path` univoco. Hash SHA-256 calcolato **solo** su richiesta (condivisione).
- Album raggruppati con `albumKey` (vedi `03-modello-dati.md`), non per solo nome.
- Niente gapless/crossfade/"bit-perfect" nella v1: coda gestita a mano. Gapless in fase 7.
- Niente traduzione automatica nella v1 (era un endpoint Google non ufficiale). Eventuale ML Kit solo Android, più avanti.
- Niente server web, niente protocollo MSTP: la fase 6 è un semplice scambio HTTP con PIN.

## Jam (fase 8)
- Un dispositivo suona alla volta (uscita selezionabile); l'altro è telecomando. Nessuna sincronia tra due uscite.
- Stato condiviso autoritativo sull'host (`JamState` con `version`); comandi validati da una funzione pura
  (`applyCommand`) con i permessi: l'ospite non può cambiare brano direttamente.
- I brani restano sul dispositivo del proprietario e si leggono in streaming (`Range`, token di sessione) solo
  se sono in coda; nessuna libreria esposta. Precarico del successivo in cache temporanea.
- Trasporto: lo stesso endpoint HTTP delle offerte (`OfferNode`), aggiornamenti con long polling.
- Codice: `lib/services/jam/` (`jam_models`, `jam_state` = riduttore puro, `jam_host` = rotte `/jam` montate da `OfferNode`,
  `jam_guest` = client, `jam_output` = applica lo stato a un `AudioBackend`, `jam_cache`), orchestrazione in
  `lib/providers/jam_providers.dart` (`JamController`), UI in `lib/ui/screens/jam/`.
- La Jam usa un proprio `AudioBackend`: la coda locale (`PlayQueue`) non viene toccata; la riproduzione locale va in pausa all'avvio.
- Permessi coda: tutti aggiungono e riordinano; l'ospite rimuove solo i propri brani (mai quello in riproduzione) e non
  cambia brano; l'host fa tutto.
