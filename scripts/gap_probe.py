#!/usr/bin/env python3
"""Measures the gap between consecutive files rendered by mpv (fase 18.1/18.9).

The click fixtures (test/fixtures/gapless/click-N.*) hold a click every 500 ms,
cut halfway between two clicks, so back to back they must still give 500 ms
between clicks. mpv renders to a WAV (`--ao=pcm`), no sound card or microphone
involved: this measures what mpv does with a playlist, which is what
just_audio_media_kit hands it on desktop.

  scripts/gap_probe.py mp3                # click-1..3.mp3 in one playlist
  scripts/gap_probe.py flac
  scripts/gap_probe.py mixed              # mp3, flac, mp3
  scripts/gap_probe.py mp3 --window       # play 1, then 2 added later and 1 removed (the app's two-track window)
  scripts/gap_probe.py mp3 --gapless=no   # mpv default without the option
  scripts/gap_probe.py mixed --live       # real sound card: records the sink (quiet) with pw-record

Without --live the audio is rendered to a WAV, so it never reopens the output:
good for the playlist logic, blind to format changes. --live plays quietly
(`--volume=15`) through PipeWire and records the sink monitor.

Prints the gaps (ms between clicks minus 500) and exits 0.
"""
import argparse
import json
import os
import socket
import struct
import subprocess
import sys
import tempfile
import time
import wave

FIX = os.path.join(os.path.dirname(__file__), '..', 'test', 'fixtures', 'gapless')
CLICK_EVERY_MS = 500


def files_for(kind):
    pick = {'mp3': ['mp3'] * 3, 'flac': ['flac'] * 3, 'mixed': ['mp3', 'flac', 'mp3']}[kind]
    return [os.path.abspath(os.path.join(FIX, f'click-{i + 1}.{ext}')) for i, ext in enumerate(pick)]


def click_times(path, rel=0.3):
    with wave.open(path) as w:
        rate, ch, width = w.getframerate(), w.getnchannels(), w.getsampwidth()
        raw = w.readframes(w.getnframes())
    n = len(raw) // width
    fmt = {2: '<%dh', 4: '<%di'}[width] % n
    scale = float(1 << (8 * width - 1))
    samples = struct.unpack(fmt, raw)
    peak = max(abs(x) for x in samples) / scale or 1.0
    times, last = [], -10 ** 9
    for i in range(0, n, ch):
        if abs(samples[i]) / scale > rel * peak and i - last > rate // 10:
            times.append(i / ch / rate * 1000.0)
            last = i
    return times, rate


PREFETCH = 'yes'
SINK = 'alsa_output.pci-0000_05_00.6.analog-stereo'


def ao_args(out, live):
    if live:
        return ['--ao=pipewire', '--volume=15']
    return ['--ao=pcm', f'--ao-pcm-file={out}', '--audio-samplerate=22050',
            '--audio-channels=mono', '--audio-format=s16']


def recording(out, live):
    """Context for --live: pw-record on the sink's monitor, 48 kHz mono s16."""
    class Rec:
        def __enter__(self):
            self.p = None
            if live:
                self.p = subprocess.Popen(
                    ['pw-record', '--target', SINK, '-P', 'stream.capture.sink=true',
                     '--rate', '48000', '--channels', '1', '--format', 's16', out],
                    stderr=subprocess.DEVNULL)
                time.sleep(1.0)
            return self

        def __exit__(self, *a):
            if self.p:
                time.sleep(0.7)
                self.p.terminate()
                self.p.wait(timeout=10)
    return Rec()


def run_plain(files, out, gapless, live=False):
    cmd = ['mpv', '--no-config', '--no-video', '--really-quiet', *ao_args(out, live),
           f'--gapless-audio={gapless}', f'--prefetch-playlist={PREFETCH}'] + files
    with recording(out, live):
        subprocess.run(cmd, check=True, timeout=120)


def ipc(sock, *args):
    sock.sendall((json.dumps({'command': list(args)}) + '\n').encode())


def run_window(files, out, gapless, live=False):
    """What the app does: [first], then append the second while the first plays,
    then once the second is current remove the first and append the third."""
    path = os.path.join(tempfile.mkdtemp(), 'ipc')
    cmd = ['mpv', '--no-config', '--no-video', '--really-quiet', *ao_args(out, live),
           f'--gapless-audio={gapless}', f'--prefetch-playlist={PREFETCH}', '--idle=yes',
           f'--input-ipc-server={path}']
    rec = recording(out, live)
    rec.__enter__()
    p = subprocess.Popen(cmd)
    for _ in range(100):
        if os.path.exists(path):
            break
        time.sleep(0.05)
    s = socket.socket(socket.AF_UNIX)
    s.connect(path)
    ipc(s, 'loadfile', files[0], 'replace')
    ipc(s, 'loadfile', files[1], 'append')
    s.setblocking(False)
    state = 0
    deadline = time.time() + 60
    buf = b''
    while time.time() < deadline and p.poll() is None:
        try:
            buf += s.recv(65536)
        except BlockingIOError:
            time.sleep(0.01)
            continue
        while b'\n' in buf:
            line, buf = buf.split(b'\n', 1)
            try:
                ev = json.loads(line)
            except ValueError:
                continue
            if ev.get('event') == 'start-file' and state == 0:
                ipc(s, 'get_property', 'playlist-pos')
            if ev.get('event') == 'file-loaded':
                state += 1
                if state == 2:  # the second became current: slide the window
                    ipc(s, 'playlist-remove', 0)
                    ipc(s, 'loadfile', files[2], 'append')
            if ev.get('event') == 'idle' and state >= 3:
                ipc(s, 'quit')
        if state >= 3 and p.poll() is None:
            time.sleep(0.01)
    if p.poll() is None:
        ipc(s, 'quit')
        p.wait(timeout=10)
    rec.__exit__()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('kind', choices=['mp3', 'flac', 'mixed'])
    ap.add_argument('--window', action='store_true')
    ap.add_argument('--gapless', default='yes')
    ap.add_argument('--live', action='store_true')
    ap.add_argument('--prefetch', default='yes')
    a = ap.parse_args()
    global PREFETCH
    PREFETCH = a.prefetch
    out = os.path.join(tempfile.mkdtemp(), 'out.wav')
    (run_window if a.window else run_plain)(files_for(a.kind), out, a.gapless, a.live)
    times, _ = click_times(out)
    gaps = [round(b - a_ - CLICK_EVERY_MS, 1) for a_, b in zip(times, times[1:])]
    with wave.open(out) as w:
        total = w.getnframes() / w.getframerate()
    print(f'{a.kind}{" window" if a.window else ""}{" live" if a.live else ""} gapless={a.gapless}: '
          f'{len(times)} clicks (18 expected)' + ('' if a.live else f', {total:.2f} s rendered (9.00 expected)'))
    print('  deviation of each interval from 500 ms (ms):', gaps)
    seams = [gaps[i] for i in (5, 11) if i < len(gaps)]
    print('  at the file seams (ms):', seams)


if __name__ == '__main__':
    sys.exit(main())
