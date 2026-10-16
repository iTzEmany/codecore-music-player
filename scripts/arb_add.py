#!/usr/bin/env python3
"""Adds strings to every ARB file in lib/l10n in one go.

  scripts/arb_add.py strings.json

strings.json:
  {
    "keys": {
      "selectAll": {"it": "Seleziona tutto", "en": "Select all", "de": "...", "es": "..."},
      "selectedCount": {"it": "{count, plural, one{1 selezionato} other{{count} selezionati}}", ...}
    },
    "placeholders": {"selectedCount": {"count": "int"}, "addedTo": {"name": "String"}}
  }

A key already present is left alone (so the script can be run again); a
language with no ARB file yet is skipped. Run `flutter gen-l10n` afterwards.
"""
import json
import os
import sys

L10N = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')
LANGS = ['it', 'en', 'de', 'es', 'fr', 'pt']


def main():
    spec = json.load(open(sys.argv[1], encoding='utf-8'))
    keys, placeholders = spec['keys'], spec.get('placeholders', {})
    for lang in LANGS:
        path = os.path.join(L10N, f'app_{lang}.arb')
        if not os.path.exists(path):
            continue
        raw = open(path, encoding='utf-8').read().rstrip()
        present = set(json.loads(raw))
        body = raw[:-1].rstrip()
        extra = ''
        for key, texts in keys.items():
            if key in present:
                continue
            if lang not in texts:
                sys.exit(f'{key}: no text for "{lang}"')
            extra += f',\n  {json.dumps(key)}: {json.dumps(texts[lang], ensure_ascii=False)}'
            if key in placeholders:
                meta = {'placeholders': {n: {'type': t} for n, t in placeholders[key].items()}}
                lines = json.dumps(meta, indent=2).replace('\n', '\n  ')
                extra += f',\n  {json.dumps("@" + key)}: {lines}'
        if extra:
            open(path, 'w', encoding='utf-8').write(body + extra + '\n}\n')
            print(f'{lang}: added')


if __name__ == '__main__':
    main()
