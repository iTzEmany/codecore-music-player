#!/usr/bin/env python3
"""Markdown table of outdated dependencies from `flutter pub outdated --json` (stdin)."""
import json
import sys


def version(entry):
    return (entry or {}).get('version') or '—'


def main():
    data = json.load(sys.stdin)
    rows = []
    for p in data.get('packages', []):
        notes = []
        if p.get('isCurrentAffectedByAdvisory'):
            notes.append('🔴 security advisory')
        if p.get('isDiscontinued'):
            replaced = p.get('replacedBy')
            notes.append('discontinued' + (f' (use {replaced})' if replaced else ''))
        if p.get('isCurrentRetracted'):
            notes.append('current version retracted')
        cur, res, lat = (version(p.get(k)) for k in ('current', 'resolvable', 'latest'))
        stale = cur != lat and lat != '—'
        if not (stale or notes):
            continue
        blocked = stale and res == cur
        if blocked:
            notes.append('newer version blocked by constraints')
        rows.append((0 if p.get('isCurrentAffectedByAdvisory') else 1, p['package'],
                     p.get('kind', ''), cur, res, lat, ', '.join(notes)))
    rows.sort()
    advisories = sum(1 for r in rows if r[0] == 0)
    print('### Dependencies\n')
    if not rows:
        print('Everything is up to date.')
        return
    print(f'{len(rows)} package(s) have a newer version or a warning'
          + (f' — **{advisories} with a security advisory**' if advisories else '') + '.\n')
    print('| Package | Kind | Current | Resolvable | Latest | Notes |')
    print('|---|---|---|---|---|---|')
    for _, name, kind, cur, res, lat, notes in rows:
        print(f'| {name} | {kind} | {cur} | {res} | {lat} | {notes} |')


if __name__ == '__main__':
    main()
