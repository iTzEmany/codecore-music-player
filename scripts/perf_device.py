#!/usr/bin/env python3
"""Misure della fase 28 su un telefono vero, con un'app separata.

Installa la build «perf» (pacchetto com.codecore.player.perf, dati suoi: la
libreria vera dell'utente non viene mai toccata), le dà la libreria di prova di
scripts/perf_library.py, poi misura: scansione, avvio a freddo, memoria e i
frame mentre scorre «Tutti i brani», «Album», la ricerca e (con --playback)
«In riproduzione». Tabella in build/perf/<etichetta>.md.

    scripts/perf_library.py
    scripts/perf_device.py <id-adb> --label prima
    scripts/perf_device.py <id-adb> --label dopo --no-push   # stessa libreria, solo l'app nuova

Prende lo schermo per qualche minuto. Con --playback suona brani muti: un'altra
app che sta suonando si mette in pausa.
"""
import argparse
import json
import math
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

PKG = 'com.codecore.player.perf'
ACTIVITY = f'{PKG}/com.codecore.player.MainActivity'
REMOTE = f'/sdcard/Android/data/{PKG}/files'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAME_60HZ = 1000 / 60

assert PKG.endswith('.perf'), 'only the perf app may be cleared'


class Device:
    def __init__(self, serial):
        self.serial = serial

    def adb(self, *args, check=True):
        r = subprocess.run(['adb', '-s', self.serial, *args], capture_output=True, text=True)
        if check and r.returncode != 0:
            raise RuntimeError(f'adb {" ".join(args)}: {r.stderr.strip()}')
        return r.stdout

    def sh(self, cmd, check=True):
        return self.adb('shell', cmd, check=check)

    def now_ms(self):
        return int(self.sh('date +%s%3N').strip())

    def nodes(self):
        for _ in range(5):
            self.sh('rm -f /sdcard/cc_perf_ui.xml', check=False)
            self.sh('uiautomator dump /sdcard/cc_perf_ui.xml', check=False)
            raw = self.sh('cat /sdcard/cc_perf_ui.xml', check=False)
            if raw.strip().startswith('<?xml'):
                self.sh('rm -f /sdcard/cc_perf_ui.xml', check=False)
                out = []
                for n in ET.fromstring(raw).iter('node'):
                    label = (n.get('content-desc') or n.get('text') or '').strip()
                    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', n.get('bounds', ''))
                    if m:
                        x1, y1, x2, y2 = map(int, m.groups())
                        out.append((label, n.get('class', ''), (x1 + x2) // 2, (y1 + y2) // 2))
                return out
            time.sleep(0.8)
        raise RuntimeError('uiautomator dump failed')

    def tap(self, pattern, cls=None):
        rx = re.compile(pattern)
        for label, c, x, y in self.nodes():
            if rx.search(label) and (cls is None or cls in c):
                self.sh(f'input tap {x} {y}')
                time.sleep(1.5)
                return
        raise RuntimeError(f'nothing on screen matches {pattern!r}')

    def flings(self, n=5):
        w, h = map(int, re.search(r'(\d+)x(\d+)', self.sh('wm size')).groups())
        x = w // 2
        for direction in ('up', 'down'):
            for _ in range(n):
                y1, y2 = (int(h * 0.75), int(h * 0.3)) if direction == 'up' else (int(h * 0.3), int(h * 0.75))
                self.sh(f'input swipe {x} {y1} {x} {y2} 120')
                time.sleep(0.4)

    def events(self):
        raw = self.sh(f'cat {REMOTE}/perf/events.jsonl', check=False)
        return [json.loads(l) for l in raw.splitlines() if l.strip().startswith('{')]


def build():
    env = dict(os.environ, CODECORE_PERF='1')
    subprocess.run(['flutter', 'build', 'apk', '--profile', '--target-platform', 'android-arm64',
                    '--dart-define=CODECORE_PERF=true'], cwd=ROOT, env=env, check=True)
    return os.path.join(ROOT, 'build/app/outputs/flutter-apk/app-profile.apk')


def pct(values, p):
    """Nearest-rank percentile, as summarizeFrames in lib/core/frame_stats.dart."""
    if not values:
        return 0.0
    v = sorted(values)
    rank = max(1, min(len(v), math.ceil(p / 100 * len(v))))
    return v[rank - 1]


def summary(bursts):
    raw = [f for b in bursts for f in b.get('raw', [])]
    if not raw:
        return None
    build_ms, raster_ms = [f[0] for f in raw], [f[1] for f in raw]
    budget = min((b.get('budgetMs', FRAME_60HZ) for b in bursts), default=FRAME_60HZ)
    late = lambda limit: sum(1 for b, r in raw if b > limit or r > limit) / len(raw) * 100
    return {
        'frames': len(raw),
        'build': [pct(build_ms, p) for p in (50, 90, 99)],
        'raster': [pct(raster_ms, p) for p in (50, 90, 99)],
        'jank60': late(FRAME_60HZ),
        'jankBudget': late(budget),
        'budget': budget,
    }


def wait_for(dev, event, timeout_s):
    end = time.time() + timeout_s
    while time.time() < end:
        found = [e for e in dev.events() if e.get('event') == event]
        if found:
            return found[-1]
        time.sleep(3)
    raise RuntimeError(f'no «{event}» from the app within {timeout_s} s')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('device')
    ap.add_argument('--label', default=time.strftime('%Y%m%d-%H%M'))
    ap.add_argument('--no-build', action='store_true')
    ap.add_argument('--apk', help='an APK already built (e.g. from an older commit) instead of building')
    ap.add_argument('--no-push', action='store_true', help='keep the perf app data (library already scanned)')
    ap.add_argument('--runs', type=int, default=5, help='cold starts')
    ap.add_argument('--playback', action='store_true', help='also «In riproduzione» (plays silent tracks)')
    args = ap.parse_args()
    dev = Device(args.device)
    lib = os.path.join(ROOT, 'build/perf_library')
    if not args.no_push and not os.path.isdir(lib):
        sys.exit('manca la libreria di prova: scripts/perf_library.py')

    if args.apk:
        apk = os.path.abspath(args.apk)
    elif args.no_build:
        apk = os.path.join(ROOT, 'build/app/outputs/flutter-apk/app-profile.apk')
    else:
        apk = build()
    print(dev.adb('install', '-r', apk).strip().splitlines()[-1])
    model = dev.sh('getprop ro.product.model').strip()
    dev.sh('input keyevent KEYCODE_WAKEUP')

    if not args.no_push:
        dev.sh(f'pm clear {PKG}')
        dev.sh(f'mkdir -p {REMOTE}/Music')
        dev.adb('push', lib + '/.', f'{REMOTE}/Music/')
    else:
        dev.sh(f'rm -f {REMOTE}/perf/events.jsonl', check=False)
    dev.sh(f'am start -W -n {ACTIVITY}')
    scan = None
    if not args.no_push:
        scan = wait_for(dev, 'scan', 900)
        wait_for(dev, 'heavyColumns', 300)
        print(f'scansione: {scan["tracks"]} brani in {scan["ms"] / 1000:.1f} s')

    starts, first = [], []
    for _ in range(args.runs):
        dev.sh(f'am force-stop {PKG}')
        time.sleep(2)
        before = len([e for e in dev.events() if e.get('event') == 'firstFrame'])
        out = dev.sh(f'am start -W -n {ACTIVITY}')
        m = re.search(r'TotalTime:\s*(\d+)', out)
        if m:
            starts.append(int(m.group(1)))
        time.sleep(5)
        ff = [e for e in dev.events() if e.get('event') == 'firstFrame']
        if len(ff) > before:
            first.append(ff[-1]['ms'])
    time.sleep(3)

    windows = {}

    def scenario(name, setup, action):
        setup()
        time.sleep(2.5)
        t0 = dev.now_ms()
        action()
        time.sleep(2.5)
        windows[name] = (t0, dev.now_ms() + 3000)
        print(f'  {name}: fatto')

    scenario('Tutti i brani', lambda: (dev.tap(r'^Libreria'), dev.tap(r'^Tutti i brani')), dev.flings)
    scenario('Album', lambda: (dev.sh('input keyevent KEYCODE_BACK'), time.sleep(1), dev.tap(r'^Album$')),
             dev.flings)
    scenario('Ricerca «notte»',
             lambda: (dev.sh('input keyevent KEYCODE_BACK'), time.sleep(1), dev.tap(r'^Cerca'),
                      dev.tap(r'', cls='EditText')),
             lambda: (dev.sh('input text notte'), time.sleep(2), dev.flings(3)))
    if args.playback:
        scenario('In riproduzione',
                 lambda: (dev.tap(r'^Libreria'), dev.tap(r'^Tutti i brani'), dev.tap(r'^[A-Z].* \d+')),
                 lambda: (dev.tap(r'Artista \d+'), time.sleep(2), dev.sh('input keyevent KEYCODE_BACK')))
        dev.sh('input keyevent KEYCODE_MEDIA_PAUSE', check=False)

    mem = dev.sh(f'dumpsys meminfo {PKG}')
    pss = re.search(r'TOTAL PSS:\s*(\d+)', mem) or re.search(r'^\s*TOTAL\s+(\d+)', mem, re.M)
    events = dev.events()
    bursts = [e for e in events if e.get('event') == 'burst']

    lines = [f'# Misure fase 28 — {args.label}', '',
             f'Dispositivo: {model} ({args.device}), build profile, app separata `{PKG}`.', '']
    if scan:
        lines.append(f'- Scansione: {scan["tracks"]} brani in {scan["ms"] / 1000:.1f} s')
    if starts:
        lines.append(f'- Avvio a freddo (`am start -W`, TotalTime): mediana {sorted(starts)[len(starts) // 2]} ms '
                     f'su {len(starts)} ({", ".join(map(str, starts))})')
    if first:
        lines.append(f'- Da `main` al primo frame: mediana {sorted(first)[len(first) // 2]} ms')
    if pss:
        lines.append(f'- Memoria (PSS totale): {int(pss.group(1)) // 1024} MB')
    lines += ['', '| Scenario | Frame | build p50/p90/p99 ms | raster p50/p90/p99 ms | > 16,7 ms | > budget |',
              '|---|---|---|---|---|---|']
    for name, (t0, t1) in windows.items():
        s = summary([b for b in bursts if t0 <= b['t'] <= t1])
        if s is None:
            lines.append(f'| {name} | 0 | – | – | – | – |')
            continue
        f3 = lambda v: '/'.join(f'{x:.1f}' for x in v)
        lines.append(f'| {name} | {s["frames"]} | {f3(s["build"])} | {f3(s["raster"])} | '
                     f'{s["jank60"]:.1f} % | {s["jankBudget"]:.1f} % ({s["budget"]:.1f} ms) |')
    out_dir = os.path.join(ROOT, 'build/perf')
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, f'{args.label}.md'), 'w') as f:
        f.write('\n'.join(lines) + '\n')
    with open(os.path.join(out_dir, f'{args.label}.events.jsonl'), 'w') as f:
        f.write('\n'.join(json.dumps(e) for e in events) + '\n')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
