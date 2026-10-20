#!/usr/bin/env bash
# Lancia in fila i test d'integrazione su un dispositivo.
#   scripts/integration.sh <id-dispositivo>     (es. emulator-5554, linux)
# ATTENZIONE: su un telefono con dati veri NON usarlo: l'app di prova ha lo stesso
# nome del pacchetto e, con una versione più bassa, Android la reinstalla cancellando
# i dati. Usa l'emulatore o un telefono di prova.
set -euo pipefail
cd "$(dirname "$0")/.."
device="${1:?uso: scripts/integration.sh <id-dispositivo>}"
for t in app_flow playback playlist import perf; do
  echo "== $t"
  flutter test "integration_test/${t}_test.dart" -d "$device"
done
