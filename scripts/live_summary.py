#!/usr/bin/env python3
"""Markdown summary of a `flutter test --reporter json` log.

Usage: live_summary.py <log.jsonl>   (writes to stdout; CI appends it to the job summary)
Each live test is one line: ✓ answered, ✗ failed or skipped, with the group it belongs to.
"""
import json
import sys


def main(path):
    names = {}
    results = {}
    skipped = set()
    with open(path, encoding='utf-8', errors='replace') as f:
        for line in f:
            line = line.strip()
            if not line.startswith('{'):
                continue
            try:
                e = json.loads(line)
            except json.JSONDecodeError:
                continue
            t = e.get('type')
            if t == 'testStart':
                test = e['test']
                if test.get('name', '').startswith('loading '):
                    continue
                names[test['id']] = test['name']
            elif t == 'testDone':
                if e.get('hidden'):
                    continue
                results[e['testID']] = e.get('result')
                if e.get('skipped'):
                    skipped.add(e['testID'])
    print('### Live sources\n')
    if not results:
        print('No test ran (is `CODECORE_LIVE=1` set?).')
        return 1
    print('| Test | Result |')
    print('|---|---|')
    bad = 0
    for tid, name in names.items():
        if tid not in results:
            continue
        ok = results[tid] == 'success' and tid not in skipped
        bad += 0 if ok else 1
        mark = '✓ answered' if ok else ('— skipped' if tid in skipped else '✗ failed')
        print(f'| {name} | {mark} |')
    print(f'\n{len(results) - bad} of {len(results)} sources answered.')
    return 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit('usage: live_summary.py <log.jsonl>')
    sys.exit(main(sys.argv[1]))
