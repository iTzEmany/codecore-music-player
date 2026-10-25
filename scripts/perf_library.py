#!/usr/bin/env python3
"""Libreria di prova per le misure della fase 28 (mai mescolata a quella vera).

Crea in build/perf_library/ (ignorata da git) <album> cartelle da <tracks> brani:
file MP3 muti di 30 s (`--seconds`) con titolo, artista, album, numero, anno e genere, più una
cover.jpg di 1200x1200 per album, come le copertine vere. Serve ffmpeg.

    scripts/perf_library.py                # 300 album x 10 = 3000 brani (~60 MB)
    scripts/perf_library.py --albums 30    # più piccola, per una prova veloce
"""
import argparse
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

WORDS = ['notte', 'estate', 'mare', 'strada', 'luce', 'vento', 'città', 'cuore',
         'fuoco', 'treno', 'sogno', 'pioggia', 'stelle', 'tempo', 'casa', 'amore']
GENRES = ['Rock', 'Pop', 'Jazz', 'Cantautori', 'Elettronica', 'Folk', 'Hip hop', 'Classica']
SUFFIXES = ['', '', '', ' (Remastered 2011)', ' - Live', ' (feat. Ospite Speciale)', '']


def run(cmd):
    r = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    if r.returncode != 0:
        raise RuntimeError(' '.join(cmd) + '\n' + r.stderr[-400:])


def title(i):
    n = 1 + i % 5
    words = ' '.join(WORDS[(i * 7 + k * 3) % len(WORDS)] for k in range(n))
    return f'{words.capitalize()} {i}{SUFFIXES[i % len(SUFFIXES)]}'


def make_album(base, out, a, tracks):
    artist = f'Artista {a // 2:03d}'
    album = f'Album {a:03d} {WORDS[a % len(WORDS)]}'
    folder = os.path.join(out, artist, album)
    os.makedirs(folder, exist_ok=True)
    run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'lavfi', '-i', 'testsrc2=size=1200x1200:rate=1',
         '-frames:v', '1', '-vf', f'hue=h={a * 37 % 360}', '-q:v', '3',
         os.path.join(folder, 'cover.jpg')])
    for t in range(tracks):
        i = a * tracks + t
        name = title(i)
        run(['ffmpeg', '-y', '-loglevel', 'error', '-i', base, '-c', 'copy',
             '-id3v2_version', '3',
             '-metadata', f'title={name}', '-metadata', f'artist={artist}',
             '-metadata', f'album_artist={artist}', '-metadata', f'album={album}',
             '-metadata', f'track={t + 1}/{tracks}', '-metadata', f'date={1970 + a % 55}',
             '-metadata', f'genre={GENRES[a % len(GENRES)]}',
             os.path.join(folder, f'{t + 1:02d} - {name.replace("/", " ")}.mp3')])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--albums', type=int, default=300)
    ap.add_argument('--tracks', type=int, default=10)
    # 1-second tracks change every second while playing: uiautomator then rarely finds the UI idle.
    ap.add_argument('--seconds', type=int, default=30)
    ap.add_argument('--out', default='build/perf_library')
    args = ap.parse_args()
    if shutil.which('ffmpeg') is None:
        sys.exit('ffmpeg non trovato')
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, args.out)
    if not os.path.abspath(out).startswith(os.path.join(root, 'build')):
        sys.exit('la libreria di prova va dentro build/')
    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(out)
    base = os.path.join(out, '.base.mp3')
    run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'lavfi', '-i', 'anullsrc=r=8000:cl=mono',
         '-t', str(args.seconds), '-c:a', 'libmp3lame', '-b:a', '8k', base])
    with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as pool:
        list(pool.map(lambda a: make_album(base, out, a, args.tracks), range(args.albums)))
    os.remove(base)
    print(f'{args.albums * args.tracks} brani in {args.albums} album: {out}')


if __name__ == '__main__':
    main()
