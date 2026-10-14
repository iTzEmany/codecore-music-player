#!/usr/bin/env bash
# Hook Stop: finché l'obiettivo autonomo di questa sessione è IN CORSO, rimanda Claude al lavoro.
# Lascia fermare quando: la sessione non ha obiettivo, o è FATTO / BLOCCATO / PAUSA; ci sono lavori in background
# (la loro notifica risveglia Claude); è scattato il tetto di sicurezza (CODECORE_MAX_DI_FILA rimandi di fila
# senza che il file dell'obiettivo o PROGRESS.md cambino, oppure CODECORE_MAX_TOTALE in tutto) → mette in PAUSA.
# Un errore dello script non blocca mai nulla (exit 0 senza output).
set -uo pipefail

MAX_DI_FILA=${CODECORE_MAX_DI_FILA:-6}
MAX_TOTALE=${CODECORE_MAX_TOTALE:-400}

input=$(cat)
sid=$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null) || exit 0
[ -n "$sid" ] || exit 0

proj=${CLAUDE_PROJECT_DIR:-$PWD}
dir=${CODECORE_OBIETTIVI_DIR:-$proj/.claude/obiettivi}
link=$dir/.sessioni/$sid
[ -f "$link" ] || exit 0
goal=$(cat "$link")
[ -f "$goal" ] || {
  rm -f "$link" "$link.n"
  exit 0
}

stato=$(sed -n 's/^stato: *//p' "$goal" | head -1)
case $stato in
FATTO* | BLOCCATO*)
  rm -f "$link" "$link.n"
  exit 0
  ;;
PAUSA*) exit 0 ;;
esac

# lavori in background: Claude li aspetta, non va rimandato al lavoro (né contato)
bg=$(jq -r '(.background_tasks // []) | if type == "array" then length elif type == "object" then (keys | length) else 0 end' <<<"$input" 2>/dev/null)
[ "${bg:-0}" -gt 0 ] 2>/dev/null && exit 0

# "progresso" = cambia il file dell'obiettivo oppure PROGRESS.md
progress=$proj/docs/PROGRESS.md
sig="$(stat -c %Y "$goal")-$(stat -c %Y "$progress" 2>/dev/null || echo 0)"
[ -f "$link.n" ] && read -r tot cons last <"$link.n"
tot=${tot:-0}
cons=${cons:-0}
last=${last:-0}
[ "$sig" != "$last" ] && cons=0
tot=$((tot + 1))
cons=$((cons + 1))
echo "$tot $cons $sig" >"$link.n"

if [ "$cons" -gt "$MAX_DI_FILA" ] || [ "$tot" -gt "$MAX_TOTALE" ]; then
  why="tetto dell'hook Stop: $cons rimandi di fila senza progressi, $tot in tutto"
  sed -i "s/^stato: .*/stato: PAUSA — $why/" "$goal"
  printf -- '- %s %s\n' "$(date '+%m-%d %H:%M')" "PAUSA automatica ($why)" >>"$goal"
  rm -f "$link.n"
  jq -nc --arg m "Obiettivo in PAUSA ($why). File: $goal. Per ripartire: /obiettivo riprendi" '{systemMessage: $m}'
  exit 0
fi

next=$(grep -m1 '^- \[ \]' "$progress" 2>/dev/null | cut -c1-200)
if [ -z "$next" ]; then
  next="(nessun task '[ ]' rimasto in PROGRESS.md: verifica il criterio di fatto e chiudi con FATTO)"
fi
reason="Obiettivo autonomo ancora IN CORSO (rimando $tot). File: $goal.
Non fermarti e non chiedere nulla all'utente. Rileggi il file e docs/PROGRESS.md e riparti da: $next
Se un task richiede l'utente (sudo, telefono, ascolto): mettilo in «Tocca a te» e passa al successivo.
Se hai finito tutto il possibile: scripts/obiettivo.sh chiudi FATTO \"<riassunto>\".
Se sei bloccato su tutto: scripts/obiettivo.sh chiudi BLOCCATO \"<motivo>\"."
jq -nc --arg r "$reason" '{decision: "block", reason: $r}'
exit 0
