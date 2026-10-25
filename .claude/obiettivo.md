# Profilo obiettivo — Codecore (Flutter)

> Letto da `/obiettivo` all'avvio. Ricavato il 2026-10-25 da CLAUDE.md, ci.yml, memorie e git log.

## Documenti da leggere all'avvio
- `CLAUDE.md`, `docs/01-regole-di-lavoro.md`, `docs/PROGRESS.md`, `docs/decisioni.md`, `docs/handoff.md`, `docs/gotchas.md`
- Feature in corso: `docs/feature-streaming.md` e solo il `docs/fase-N-*.md` corrente

## Modalità
- **PR**: ramo da `origin/master` → PR → `gh pr merge --auto --squash`. **Una PR per fase, un commit per task** (memoria).
- Ramo base: `master` · rami `<tipo>/<descrizione>` · commit Conventional Commits, descrizione in italiano o inglese breve (`feat(45): …`)
- Check obbligatorio: «Analyze and test» (build_runner + gen-l10n senza diff, check_docs_links, analyze, suite completa)

## Verifica
| Livello | Comando | Stima |
|---|---|---|
| mirata | `flutter test <file…>` | 2m |
| statica veloce | `flutter analyze` | 2m |
| codice generato | `dart run build_runner build --delete-conflicting-outputs` (solo tabelle drift) · `flutter gen-l10n` (ARB) | 4m · 1m |
| suite completa (CI; in locale solo se chiesta) | `flutter test` | 6m |
| build | `flutter build apk --debug` · `flutter build linux` | 8m · 10m |
| perf sul Mi A3 | `JAVA_HOME=~/.jdks/jbr-17.0.14 PATH=$JAVA_HOME/bin:$PATH python3 scripts/perf_device.py 0d7ae9df206e --label <l> --playback` | 40m |

## Parallelismo
- Implementer insieme: 3 · comandi pesanti con `sorveglia.sh --pesante` · passi in parallelo solo con disco libero ≥ 20 % (oggi 9 %: in sequenza)

## Pulizia (solo con `pulizia.sh via`)
| Quando | Cosa |
|---|---|
| dopo ogni passo fuso | `build/app/outputs/apk`, `build/perf/*` già riportati in misure.md, log in scratchpad |
| a fine fase | `build/linux` se la fase dopo non lo usa |
| disco ≥ 90 % | `build/app/intermediates`, `build/test_cache`, `build/bench` |
| mai | `build/metadata_god` (Rust, lungo da rifare), `~/.pub-cache`, file musicali del telefono |

## Regole extra del progetto
- Aree a rischio (`/code-review high`): audio handler (`codecore_audio_handler.dart`), query su `tracks` (righe ombra K-02), protocollo Jam
- Nessun pacchetto nuovo (fasi 45–49); schema DB invariato (v14)
- Telefono Mi A3 (`0d7ae9df206e`): installare, misurare, pilotare; disinstallare solo con `-k`; mai cancellare dati o file musicali; niente invii/Jam verso altri (D-91)

## Stime misurate
- `sorveglia.sh`: la stima vuole l'unità (`6m`); un numero nudo vale secondi (2026-10-25)
- `flutter test test/services/audio/ test/providers/` ~ 1m30 (2026-10-25)
- Toccando `lib/ui`: lancia sempre anche `test/ui/architecture_test.dart` (la UI non usa repository né `databaseProvider`; CI rossa in #19)
