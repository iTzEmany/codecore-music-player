#!/usr/bin/env bash
# Rapporto sulle dipendenze (markdown su stdout): pacchetti con una versione più nuova,
# con avvisi di sicurezza, ritirati o abbandonati. Non aggiorna nulla.
#   scripts/deps_report.sh            # in locale
#   scripts/deps_report.sh >> "$GITHUB_STEP_SUMMARY"   # in CI (deps.yml)
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub outdated --json | python3 scripts/deps_report.py
