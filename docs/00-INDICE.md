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

Dopo la **Fase 3** l'app è già usabile come lettore. Le fasi 5 e 6 sono indipendenti tra loro.

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
Avvia Claude Code dentro `codecore_flutter/` e digita:
| Comando | Effetto |
|---|---|
| `/obiettivo` | Esegue il piano dalla Fase 0 alla Fase 5 da solo, fino a fine o blocco |
| `/obiettivo fase 2` | Solo quella fase |
| `/obiettivo stato` | Riassunto: task fatti, prossimo, «Tocca a te» |
| `/obiettivo pausa` | Si ferma subito (puoi anche premere Esc e scrivere «stop») |
| `/obiettivo riprendi` | Riparte dal primo task non spuntato |

Cosa fa: un task alla volta → `flutter analyze` + `flutter test` (+ build) → spunta `PROGRESS.md` → commit
locale di checkpoint (repo git dedicato in `codecore_flutter/`, nessun push). Le cose che solo tu puoi fare
(sudo, telefono, ascolto) finiscono in «Tocca a te» nel file `.claude/obiettivi/*.md` senza fermare il resto.
Ripartenza da checkpoint: `git log --oneline`, poi `git checkout <commit>` o `git stash list` per i task bloccati.
