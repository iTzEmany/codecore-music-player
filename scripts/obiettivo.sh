#!/usr/bin/env bash
# File di un obiettivo autonomo e suo legame con la sessione di Claude Code (l'hook Stop
# .claude/hooks/obiettivo-stop.sh lo usa per non lasciar fermare l'agente finché è IN CORSO).
# L'elenco dei task NON sta qui: sta in docs/PROGRESS.md. Qui ci sono stato, decisioni, "Tocca a te" e registro.
#
# Uso:
#   scripts/obiettivo.sh nuovo "<testo>"                      crea il file, lo lega alla sessione, stampa il percorso
#   scripts/obiettivo.sh file                                 percorso del file legato a questa sessione
#   scripts/obiettivo.sh registro "<riga>"                    aggiunge una riga datata al registro
#   scripts/obiettivo.sh chiudi FATTO|BLOCCATO|PAUSA "<motivo>"
#   scripts/obiettivo.sh riprendi [file]                      ri-lega un obiettivo esistente (di serie l'ultimo non FATTO)
#   scripts/obiettivo.sh stato [file]                         riassunto; senza obiettivo: elenco di tutti
#
# File in <progetto>/.claude/obiettivi/. Sessione = CLAUDE_CODE_SESSION_ID. CODECORE_OBIETTIVI_DIR cambia cartella (test).
set -uo pipefail

die() {
  echo "obiettivo: $*" >&2
  exit 1
}

if [ -n "${CODECORE_OBIETTIVI_DIR:-}" ]; then
  dir=$CODECORE_OBIETTIVI_DIR
else
  proj=${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}
  dir=$proj/.claude/obiettivi
fi
mkdir -p "$dir/.sessioni" || die "non riesco a creare $dir"
sid=${CLAUDE_CODE_SESSION_ID:-}
link=${sid:+$dir/.sessioni/$sid}

now() { date '+%F %H:%M'; }
mine() {
  [ -n "$link" ] && [ -f "$link" ] && f=$(cat "$link") && [ -f "$f" ] && echo "$f"
}
touch_line() { sed -i "s/^aggiornato: .*/aggiornato: $(now)/" "$1"; }
log_line() {
  printf -- '- %s %s\n' "$(date '+%m-%d %H:%M')" "$2" >>"$1"
  touch_line "$1"
}
stato_di() { sed -n 's/^stato: *//p' "$1" 2>/dev/null | head -1; }

cmd=${1:-stato}
shift || true
case $cmd in
nuovo)
  testo=${1:-}
  [ -n "$testo" ] || die "manca il testo"
  if f=$(mine); then
    case $(stato_di "$f") in
    FATTO* | BLOCCATO*) ;;
    *) die "questa sessione ha già un obiettivo non chiuso: $f (chiudi oppure riprendi)" ;;
    esac
  fi
  slug=$(printf '%s' "$testo" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '-' | cut -c1-40 | sed 's/^-*//; s/-*$//')
  f=$dir/$(date +%F-%H%M)-${slug:-obiettivo}.md
  [ -e "$f" ] && f=${f%.md}-$$.md
  cat >"$f" <<EOF
# Obiettivo: $testo

stato: IN CORSO
sessione: ${sid:-(fuori da Claude Code)}
inizio: $(now)
aggiornato: $(now)

## Obiettivo (parole dell'utente)
$testo

## Criterio di fatto
<!-- cosa deve essere vero alla fine e con quali comandi si prova -->

## Decisioni prese in autonomia
<!-- una riga per scelta: cosa, perché, come tornare indietro -->

## Tocca a te
<!-- cose che solo l'utente può fare: dispositivo, comandi da incollare, perché. Formato: "- [ ] ..." -->

## Registro
- $(date '+%m-%d %H:%M') avvio
EOF
  [ -n "$link" ] && echo "$f" >"$link" && rm -f "$link.n"
  [ -n "$link" ] || echo "attenzione: CLAUDE_CODE_SESSION_ID assente, l'hook Stop non vedrà questo obiettivo" >&2
  echo "$f"
  ;;
file)
  mine || die "nessun obiettivo legato a questa sessione"
  ;;
registro)
  f=$(mine) || die "nessun obiettivo legato a questa sessione"
  [ -n "${1:-}" ] || die "manca la riga"
  log_line "$f" "$1"
  ;;
chiudi)
  f=$(mine) || die "nessun obiettivo legato a questa sessione"
  s=${1:-}
  case $s in FATTO | BLOCCATO | PAUSA) ;; *) die "stato: FATTO, BLOCCATO o PAUSA" ;; esac
  motivo=${2:-}
  [ -n "$motivo" ] || die "manca il motivo"
  esc=$(printf '%s' "$motivo" | tr '\n' ' ' | sed -e 's/[\/&]/\\&/g')
  sed -i "s/^stato: .*/stato: $s — $esc/" "$f"
  log_line "$f" "stato $s: $motivo"
  case $s in FATTO | BLOCCATO) rm -f "$link" "$link.n" ;; esac
  echo "$f: $s"
  ;;
riprendi)
  f=${1:-}
  if [ -z "$f" ]; then
    f=$(mine) || f=$(grep -L '^stato: FATTO' "$dir"/*.md 2>/dev/null | sort | tail -1)
  fi
  [ -n "$f" ] && [ -f "$f" ] || die "nessun obiettivo da riprendere"
  [ -n "$link" ] || die "CLAUDE_CODE_SESSION_ID assente: riprendi da una sessione di Claude Code"
  sed -i "s/^stato: .*/stato: IN CORSO/; s/^sessione: .*/sessione: $sid/" "$f"
  log_line "$f" "ripreso dalla sessione $sid"
  echo "$f" >"$link"
  rm -f "$link.n"
  echo "$f"
  ;;
stato)
  f=${1:-}
  [ -n "$f" ] || f=$(mine) || f=''
  if [ -z "$f" ]; then
    shopt -s nullglob
    files=("$dir"/*.md)
    [ ${#files[@]} -gt 0 ] || {
      echo "nessun obiettivo in $dir"
      exit 0
    }
    # righe, non parole: il percorso del progetto può contenere spazi
    while IFS= read -r g; do
      printf '%-40s %-17s %s\n' "$(stato_di "$g" | cut -c1-40)" "$(sed -n 's/^aggiornato: //p' "$g" 2>/dev/null)" "$(basename "$g")"
    done < <(printf '%s\n' "${files[@]}" | sort -r)
    exit 0
  fi
  [ -f "$f" ] || die "non trovo $f"
  sed -n '1p; /^stato:/p; /^aggiornato:/p' "$f"
  echo
  proj=${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}
  if [ -f "$proj/docs/PROGRESS.md" ]; then
    echo "Task: $(grep -c '^- \[x\]' "$proj/docs/PROGRESS.md") fatti, $(grep -c '^- \[~\]' "$proj/docs/PROGRESS.md") da verificare a mano, $(grep -c '^- \[ \]' "$proj/docs/PROGRESS.md") da fare"
    echo "Prossimo: $(grep -m1 '^- \[ \]' "$proj/docs/PROGRESS.md")"
    echo
  fi
  echo "Tocca a te:"
  sed -n '/^## Tocca a te/,/^## /{/^- /p}' "$f"
  echo
  echo "Ultime righe del registro:"
  sed -n '/^## Registro/,$p' "$f" | grep '^- ' | tail -n 6
  ;;
*) sed -n '2,15p' "$0" >&2 && exit 2 ;;
esac
