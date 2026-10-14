#!/usr/bin/env bash
# Esegue un comando lungo con una STIMA scritta prima: a 2× la stima scrive una diagnosi (riga «SCADENZA»),
# a 3× ferma il comando con tutti i suoi figli (riga «FERMATO», uscita 124). Così un comando incastrato non diventa un'attesa infinita.
#
# Uso:   scripts/sorveglia.sh <stima: 90s | 10m | 1h | secondi> <file di log> -- <comando> [argomenti...]
# Es.:   scripts/sorveglia.sh 12m /tmp/check.log -- just check
#
# L'uscita del comando va nel log; su stdout (e nel log, con «## » davanti) solo le righe di stato: INIZIO, SCADENZA, FERMATO, FINE.
# Per Claude Code: lancialo con run_in_background (la notifica arriva alla fine). Per essere svegliato già a 2×:
#   Monitor su  tail -n +1 -F <log> | grep --line-buffered -E '^## .* (SCADENZA|FERMATO|FINE)'
set -uo pipefail

usage() {
  sed -n '2,13p' "$0" >&2
  exit 2
}

secs() { # 90s | 10m | 1h | 90 → secondi
  local v=$1
  case $v in
  *h) v=${v%h} m=3600 ;;
  *m) v=${v%m} m=60 ;;
  *s) v=${v%s} m=1 ;;
  *) m=1 ;;
  esac
  [[ $v =~ ^[0-9]+$ ]] && [ "$v" -gt 0 ] || return 1
  echo $((v * m))
}

[ $# -ge 3 ] || usage
stima=$(secs "$1") || {
  echo "stima non valida: $1 (usa 90s, 10m, 1h)" >&2
  exit 2
}
log=$2
shift 2
[ "${1:-}" = "--" ] && shift
[ $# -gt 0 ] || usage

mkdir -p "$(dirname "$log")" && : >"$log" || exit 2
say() {
  local m
  m="## $(date +%T) $*"
  echo "$m"
  echo "$m" >>"$log"
}
human() { printf '%dm%02ds' $(($1 / 60)) $(($1 % 60)); }

say "INIZIO stima $(human "$stima"), diagnosi a $(human $((2 * stima))), stop a $(human $((3 * stima))): $*"
start=$(date +%s)
# setsid: il comando guida un gruppo di processi suo, così a 3× si ferma con tutti i figli (cargo, rustc, cmake, gradle…)
setsid "$@" >>"$log" 2>&1 &
pid=$!

warned=0
step=$((stima >= 50 ? 5 : 1)) # passo del controllo: fine per le stime brevi
while kill -0 "$pid" 2>/dev/null; do
  sleep "$step"
  kill -0 "$pid" 2>/dev/null || break
  el=$(($(date +%s) - start))
  if [ "$warned" -eq 0 ] && [ "$el" -ge $((2 * stima)) ]; then
    warned=1
    say "SCADENZA 2× superata ($(human "$el"), stima $(human "$stima")): diagnosi qui sotto; il comando continua fino a 3×"
    {
      echo "## processi del comando (tempo, CPU %, memoria KB):"
      ps --sid "$pid" -o etime=,pcpu=,rss=,args= 2>/dev/null | cut -c1-160 | head -8 | sed 's/^/##   /'
      echo "## dimensione del log: $(stat -c %s "$log") byte; ultime righe del comando:"
      grep -v '^## ' "$log" | tail -n 8 | cut -c1-200 | sed 's/^/##   /'
    } | tee -a "$log"
  fi
  if [ "$el" -ge $((3 * stima)) ]; then
    say "FERMATO a 3× ($(human "$el")): il comando non è finito in tempo; ultime righe:"
    grep -v '^## ' "$log" | tail -n 15 | cut -c1-200 | sed 's/^/##   /' | tee -a "$log"
    kill -TERM -- -"$pid" 2>/dev/null
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done
    kill -KILL -- -"$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    exit 124
  fi
done
wait "$pid"
rc=$?
el=$(($(date +%s) - start))
say "FINE uscita $rc in $(human "$el") (stima $(human "$stima")); ultime righe:"
grep -v '^## ' "$log" | tail -n 15 | cut -c1-200 | sed 's/^/##   /'
exit "$rc"
