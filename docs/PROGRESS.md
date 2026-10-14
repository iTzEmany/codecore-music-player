# Avanzamento

Legenda: `[ ]` da fare · `[~]` codice fatto e verde nei test, manca solo una prova a mano dell'utente · `[x]` fatto.
Spunta a fine task (dopo `flutter analyze` + `flutter test` verdi). Annota **una riga** se hai deviato dal piano.
L'agente riparte sempre dal primo task non spuntato.

## Fase 0 — Setup (`fase-0-setup.md`)
- [x] 0.1 Verifica toolchain
- [x] 0.2 Creare il progetto Flutter
- [x] 0.3 Dipendenze
- [x] 0.4 Scheletro cartelle e utilità (AppLog, platform, paths, text_utils + test)
- [x] 0.5 main.dart / app.dart
- [x] 0.6 Primo build Android
- [x] 0.7 .gitignore

## Fase 1 — Dati e scansione (`fase-1-dati-e-scansione.md`)
- [x] 1.1 Tabelle drift
- [x] 1.2 TagReader + implementazione
- [x] 1.3 Repository
- [x] 1.4 Scanner
- [x] 1.5 Copertine
- [x] 1.6 Provider
- [~] 1.7 Permessi Android e cartella predefinita
- [~] 1.8 Schermata di debug

## Fase 2 — Player (`fase-2-player.md`)
- [x] 2.1 PlayQueue (+ test)
- [x] 2.2 AudioBackend / JustAudioBackend
- [x] 2.3 CodecoreAudioHandler (+ test)
- [~] 2.4 Inizializzazione per piattaforma
- [x] 2.5 Provider di stato e controller
- [~] 2.6 Persistenza e checklist manuale

## Fase 3 — Interfaccia (`fase-3-interfaccia.md`)
- [x] 3.1 Tema
- [x] 3.2 Shell adattiva
- [x] 3.3 Widget riusabili
- [~] 3.4 Tab Brani
- [x] 3.5 Tab Album + dettaglio
- [x] 3.6 Tab Artisti
- [x] 3.7 Mini-player
- [x] 3.8 Now Playing + coda
- [~] 3.9 Scorciatoie da tastiera
- [x] 3.10 Rimozione schermata di debug

## Fase 4 — Funzioni libreria (`fase-4-funzioni-libreria.md`)
- [x] 4.1 Preferiti
- [x] 4.2 Playlist
- [x] 4.3 Menu azioni brano
- [x] 4.4 Modifica info brano
- [x] 4.5 Impostazioni
- [x] 4.6 Localizzazione it/en/de/es
- [x] 4.7 Brani mancanti e stati di errore
- [x] 4.8 Ripresa riproduzione

## Fase 5 — Online (`fase-5-online.md`)
- [x] 5.1 HTTP di base
- [x] 5.2 QueryCleaner (+ test)
- [x] 5.3 Client iTunes (+ test)
- [x] 5.4 Client LRCLIB + parser LRC (+ test)
- [x] 5.5 Client Wikipedia
- [x] 5.6 EnrichmentService (+ test)
- [x] 5.7 UI arricchimento
- [x] 5.8 Schermata testi
- [ ] 5.9 YoutubeService
- [ ] 5.10 Coda di download
- [ ] 5.11 Schermata YouTube

## Fase 6 — Condivisione LAN, opzionale (`fase-6-condivisione-lan.md`)
- [ ] 6.1 Server
- [ ] 6.2 Client
- [ ] 6.3 UI
- [ ] 6.4 Integrazione

## Fase 7 — Rifinitura (`fase-7-rifinitura.md`)
- [ ] 7.1 Import dal vecchio DB Python
- [ ] 7.2 Gapless
- [ ] 7.3 ReplayGain
- [ ] 7.4 Controlli multimediali desktop
- [ ] 7.5 Prestazioni
- [ ] 7.6 Accessibilità
- [ ] 7.7 Timer di spegnimento
- [ ] 7.8 Icona e nome app
- [ ] 7.9 Build di rilascio
- [ ] 7.10 Documentazione finale

## Note di deviazione
<!-- una riga per deviazione: data — task — cosa è cambiato e perché -->

## Note di deviazione
- 0.3: `generate: true` (l10n) rimandato alla fase 4 (senza ARB `flutter gen-l10n` fallirebbe). `flutter_localizations` già aggiunto.
- 0.2: MainActivity spostata nel package `com.codecore.player`; `compileSdk = 37` (richiesto da permission_handler_android).
- 1.2: test con fixture mp3/flac generate con ffmpeg in `test/fixtures/`.
- 4.5: versione app in `lib/core/app_info.dart` (nessun package_info_plus, non previsto). Cartelle musicali nel DB (tabella folders), non in shared_preferences.
- 4.6: messaggi di errore del player passano da `PlaybackFailure` (enum) e sono localizzati in UI. Nomi lingua (Italiano/English/…) restano nativi.
- 4.3/4.4: prova a mano delle azioni (menu ⋯ brano, modifica info) su telefono/desktop.
