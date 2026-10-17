#!/usr/bin/env python3
"""Checks the relative links of the Markdown files in docs/guida and the
size of the images next to them (< 300 KB). Exit 1 on the first problem list."""
import os
import re
import sys

root = os.path.join(os.path.dirname(__file__), '..', 'docs', 'guida')
bad = []
for name in sorted(os.listdir(root)):
    path = os.path.join(root, name)
    if name.endswith('.md'):
        for target in re.findall(r'\]\(([^)#\s]+)(?:#[^)]*)?\)', open(path, encoding='utf-8').read()):
            if re.match(r'[a-z]+:', target):
                continue
            if not os.path.exists(os.path.normpath(os.path.join(root, target))):
                bad.append(f'{name}: link {target} non esiste')
img = os.path.join(root, 'img')
if os.path.isdir(img):
    for name in os.listdir(img):
        if os.path.getsize(os.path.join(img, name)) > 300 * 1024:
            bad.append(f'img/{name}: più di 300 KB')
print('\n'.join(bad) or 'ok')
sys.exit(1 if bad else 0)
