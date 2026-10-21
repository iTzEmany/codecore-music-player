# Codecore Flutter — Indice della documentazione

Obiettivo: riscrivere Codecore come app **standalone** (nessun server, nessun backend) con
un'unica codebase Flutter per Android, Windows e Linux. Uso personale, niente complicazioni.

## Documenti di riferimento (leggili all'occorrenza)
| File | Contenuto |
|---|---|
| `01-regole-di-lavoro.md` | Regole obbligatorie per l'agente (stile, test, verifiche) |
| `02-architettura.md` | Struttura cartelle, livelli, flusso dei dati, scelte tecniche |
| `03-modello-dati.md` | Schema DB drift, chiavi, regole sui dati |
| `04-specifiche-da-python.md` | Logica da portare dalla vecchia app (con i difetti corretti) |
| `99-rischi-e-fallback.md` | Cosa può andare storto e il piano B |

## Fasi (una per volta, in ordine)
| Fase | File | Risultato |
|---|---|---|
| 0 | `fase-0-setup.md` | Progetto creato, dipendenze, "hello world" su Linux e Android |
| 1 | `fase-1-dati-e-scansione.md` | DB + scansione cartelle + tag + copertine |
| 2 | `fase-2-player.md` | Motore audio, coda, notifica Android |
| 3 | `fase-3-interfaccia.md` | Libreria, album, ricerca, mini-player, player a schermo intero |
| 4 | `fase-4-funzioni-libreria.md` | Preferiti, playlist, impostazioni, temi, lingue, modifica tag |
| 5 | `fase-5-online.md` | Arricchimento metadati, testi sincronizzati, download YouTube |
| 6 | `fase-6-condivisione-lan.md` | (Opzionale) invio brani tra dispositivi sulla stessa rete |
| 7 | `fase-7-rifinitura.md` | Gapless, import dal vecchio DB, icone, build finali |
| 8 | `fase-8-jam.md` | Jam sulla rete locale: coda condivisa, brani in streaming dal proprietario, uscita audio selezionabile |
| 9 | `fase-9-jam-multi.md` | Jam con più di 2 dispositivi (fino a 5), inviti anche dagli ospiti |
| 10 | `fase-10-jam-sincronia.md` | Riproduzione sincronizzata su più uscite (orologio condiviso, correzione della deriva) |
| 11 | `fase-11-interfaccia-nuova.md` | Interfaccia nuova nero/viola: Home · Cerca · Libreria, player sempre visibile, desktop a tre zone |
| 12 | `fase-12-import-csv.md` | Importare playlist Spotify da CSV di Exportify: abbinamento con la libreria, ricerca su YouTube Music, download in ordine |
| — | `13-idee-future.md` | Idee per dopo la base (raccolta ragionata): le voci tenute sono diventate le fasi 13–26 |
| 13 | `fase-13-backup-export.md` | Backup e ripristino completo, formato portabile dei dati utente, export playlist (M3U8/CSV/JSON), esporta log |
| 14 | `fase-14-download-robusti.md` | yt-dlp aggiornabile in-app, download in parallelo, ritento a scalare, formato senza ricodifica, ISRC, cache, controllo durata |
| 15 | `fase-15-importazione-2.md` | Import M3U/XSPF e CSV generici, «Sincronizza da CSV», album interi, migliorie della fase 12 |
| 16 | `fase-16-ci-test.md` | CI GitHub (analyze, test, build apk/linux/windows), test d'integrazione su telefono, live notturni, golden, 50.000 brani |
| 17 | `fase-17-riproduzione.md` | Velocità, «riprendi da qui», anteprima, equalizzatore, MPRIS/SMTC, controlli Jam in notifica |
| 18 | `fase-18-gapless-crossfade.md` | Gapless (dietro un'opzione) e crossfade, senza toccare la Jam |
| 19 | `fase-19-interfaccia.md` | Selezione multipla, trascinamento su playlist, tema chiaro e accento, tablet, nuove lingue, onboarding |
| 20 | `fase-20-libreria-intelligente.md` | Cronologia, statistiche/recap, ricerca con operatori, playlist intelligenti, etichette |
| 21 | `fase-21-pulizia-tag.md` | Duplicati e fusione, unire/dividere album, scrittura dei tag nei file (atomica, opzionale) |
| 22 | `fase-22-nuove-fonti.md` | SoundCloud, playlist e canali YouTube come sorgente, traduzione dei testi on-device |
| 23 | `fase-23-podcast.md` | Podcast da RSS: iscrizioni, episodi scaricabili, stato «ascoltato» |
| 24 | `fase-24-dispositivi-fidati.md` | Abbinamento dispositivi, TLS con pinning, scanner QR, sincronizzazione playlist in LAN |
| 25 | `fase-25-android-esteso.md` | Widget, tile rapida, Android Auto, Wear OS, modalità in auto |
| 26 | `fase-26-distribuzione.md` | Pacchetti Linux, installer Windows, APK più piccolo, avviso aggiornamenti, F-Droid, macOS/iOS, guida utente |
| 27 | `fase-27-selezione-ordinata-e-tema-libero.md` | Selezione multipla nell'ordine dei tocchi (con numeri) e tema totalmente personalizzabile (colori, sfondo, immagine) |
| 28 | `fase-28-prestazioni-e-fluidita.md` | Zero lag sul Mi A3 con 3000 brani, microanimazioni, ricerca online diretta (< 1,5 s), ascolto in streaming prima di scaricare, copertine leggere |
| 30 | `fase-30-pagina-artista.md` | Card dell'artista nei risultati online e pagina artista «come Spotify» (i tuoi brani, più ascoltati, album e singoli, video, simili), pagina album con «Scarica album» |
| 31 | `fase-31-shuffle-plus.md` | «Shuffle+»: in casuale, ogni N brani uno che non hai, simile alla playlist (radio di YouTube Music), in streaming, da scaricare o aggiungere a una playlist |
| 32 | `fase-32-ricerca-intelligente.md` | Ricerca con due modi (In libreria · Online): online YouTube Music e YouTube insieme, confidenza, stesso brano in una riga, «Altri risultati», intento (artista, album, brano, indirizzo), fonti come filtro; SoundCloud misurato e proposto fuori dalla ricerca |
| 33 | `fase-33-radio.md` | Radio in diretta da Radio Browser: «Vicino a te» (paese e regione), ricerca, generi, «Le mie radio» salvate (schema v12), ascolto dal lettore principale con titolo in onda, Android Auto |
| 34 | `fase-34-nuove-uscite.md` | Nuove uscite degli artisti seguiti (e, a scelta, dei più ascoltati): un controllo al giorno, «Nuove uscite» in Home, notifica Android (schema v13) |

Dopo la **Fase 3** l'app è già usabile come lettore. Le fasi 5 e 6 sono indipendenti tra loro. La fase 8 (Jam) richiede la 6.

**Fasi 13–26** (dopo la base): raggruppate per area, così ogni fase tocca un sottosistema solo. Ordine consigliato
quello della tabella; dipendenze vere: 15 ← 13 + 14 · 18 ← 17 · 20 ← 19 (selezione multipla per le etichette) ·
21 ← 20 (fusione della cronologia) · 23 ← 17 (segnalibro) · 24 ← 13 (formato portabile) · 26 ← 16 (CI).
Le altre si possono spostare. Le versioni di schema (v5…v10) sono assegnate in quest'ordine: se se ne salta una,
si usa la prossima libera. Ogni fase elenca i **pacchetti nuovi da approvare** prima del task che li usa.

## Come lanciare una fase (prompt da incollare)
```
Leggi CLAUDE.md, docs/01-regole-di-lavoro.md, docs/PROGRESS.md e docs/fase-N-<nome>.md.
Esegui i task della fase N in ordine, uno alla volta. Dopo ogni task: flutter analyze,
flutter test, spunta il task in docs/PROGRESS.md. Fermati se un criterio di verifica
non è soddisfatto o se serve un'azione dell'utente (sudo, dispositivo fisico).
```
Per riprendere dopo una pausa: stesso prompt, l'agente riparte dal primo task non spuntato.

## Convenzione dei task
Ogni task ha: **ID**, **File** da creare/modificare, **Passi** numerati, **Verifica** eseguibile.
Un task deve stare in una sola sessione breve; se è troppo grande, spezzalo e annota in PROGRESS.

## Modalità autonoma (`/obiettivo`)
Avvia Claude Code nella radice del progetto (`codecore-music-player/`) e digita:
| Comando | Effetto |
|---|---|
| `/obiettivo` | Esegue tutte le fasi rimaste, una dietro l'altra, fino alla fine o a un blocco (i task con pacchetti non approvati restano bloccati e si va avanti) |
| `/obiettivo fase 2` | Solo quella fase |
| `/obiettivo stato` | Riassunto: task fatti, prossimo, «Tocca a te» |
| `/obiettivo pausa` | Si ferma subito (puoi anche premere Esc e scrivere «stop») |
| `/obiettivo riprendi` | Riparte dal primo task non spuntato |

Cosa fa: un task alla volta → `flutter analyze` + `flutter test` (+ build) → spunta `PROGRESS.md` → commit
locale di checkpoint (repo git del progetto, nessun push). Le cose che solo tu puoi fare
(sudo, telefono, ascolto) finiscono in «Tocca a te» nel file `.claude/obiettivi/*.md` senza fermare il resto.
Ripartenza da checkpoint: `git log --oneline`, poi `git checkout <commit>` o `git stash list` per i task bloccati.
