# Avanzamento

Legenda: `[ ]` da fare · `[~]` codice fatto e verde nei test, manca solo una prova a mano dell'utente · `[x]` fatto.
Spunta a fine task (dopo `flutter analyze` + `flutter test` verdi). Annota **una riga** se hai deviato dal piano.
L'agente riparte sempre dal primo task non spuntato.

## Fase 0 — Setup (`fase-0-setup.md`)
- [ ] 0.1 Verifica toolchain
- [ ] 0.2 Creare il progetto Flutter
- [ ] 0.3 Dipendenze
- [ ] 0.4 Scheletro cartelle e utilità (AppLog, platform, paths, text_utils + test)
- [ ] 0.5 main.dart / app.dart
- [ ] 0.6 Primo build Android
- [ ] 0.7 .gitignore

## Fase 1 — Dati e scansione (`fase-1-dati-e-scansione.md`)
- [ ] 1.1 Tabelle drift
- [ ] 1.2 TagReader + implementazione
- [ ] 1.3 Repository
- [ ] 1.4 Scanner
- [ ] 1.5 Copertine
- [ ] 1.6 Provider
- [ ] 1.7 Permessi Android e cartella predefinita
- [ ] 1.8 Schermata di debug

## Fase 2 — Player (`fase-2-player.md`)
- [ ] 2.1 PlayQueue (+ test)
- [ ] 2.2 AudioBackend / JustAudioBackend
- [ ] 2.3 CodecoreAudioHandler (+ test)
- [ ] 2.4 Inizializzazione per piattaforma
- [ ] 2.5 Provider di stato e controller
- [ ] 2.6 Persistenza e checklist manuale

## Fase 3 — Interfaccia (`fase-3-interfaccia.md`)
- [ ] 3.1 Tema
- [ ] 3.2 Shell adattiva
- [ ] 3.3 Widget riusabili
- [ ] 3.4 Tab Brani
- [ ] 3.5 Tab Album + dettaglio
- [ ] 3.6 Tab Artisti
- [ ] 3.7 Mini-player
- [ ] 3.8 Now Playing + coda
- [ ] 3.9 Scorciatoie da tastiera
- [ ] 3.10 Rimozione schermata di debug

## Fase 4 — Funzioni libreria (`fase-4-funzioni-libreria.md`)
- [ ] 4.1 Preferiti
- [ ] 4.2 Playlist
- [ ] 4.3 Menu azioni brano
- [ ] 4.4 Modifica info brano
- [ ] 4.5 Impostazioni
- [ ] 4.6 Localizzazione it/en/de/es
- [ ] 4.7 Brani mancanti e stati di errore
- [ ] 4.8 Ripresa riproduzione

## Fase 5 — Online (`fase-5-online.md`)
- [ ] 5.1 HTTP di base
- [ ] 5.2 QueryCleaner (+ test)
- [ ] 5.3 Client iTunes (+ test)
- [ ] 5.4 Client LRCLIB + parser LRC (+ test)
- [ ] 5.5 Client Wikipedia
- [ ] 5.6 EnrichmentService (+ test)
- [ ] 5.7 UI arricchimento
- [ ] 5.8 Schermata testi
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
