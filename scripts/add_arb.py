#!/usr/bin/env python3
"""Appends keys to the four ARB files: add_arb.py <json file>.
JSON: {"key": {"it": "...", "en": "...", "de": "...", "es": "...", "ph": {"n": "int"}}}"""
import json, sys, re
spec = json.load(open(sys.argv[1]))
for lang in ('it', 'en', 'de', 'es'):
    p = f'lib/l10n/app_{lang}.arb'
    d = json.load(open(p), object_pairs_hook=__import__('collections').OrderedDict)
    for key, v in spec.items():
        if key in d:
            continue
        d[key] = v[lang]
        if v.get('ph'):
            d['@' + key] = {'placeholders': {n: {'type': t} for n, t in v['ph'].items()}}
    json.dump(d, open(p, 'w'), ensure_ascii=False, indent=2)
    open(p, 'a').write('\n')
