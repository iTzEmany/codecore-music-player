#!/usr/bin/env bash
# Pacchetto Linux: bundle release + .desktop + icona in uno zip (build/codecore-linux-x64.zip).
# Prerequisito: flutter build linux --release. Sul sistema serve libmpv (apt install libmpv2).
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import os, shutil, textwrap

bundle = "build/linux/x64/release/bundle"
if not os.path.exists(os.path.join(bundle, "codecore")):
    raise SystemExit("Esegui prima: flutter build linux --release")

out = "build/codecore-linux"
shutil.rmtree(out, ignore_errors=True)
os.makedirs(out)
shutil.copytree(bundle, os.path.join(out, "codecore"))
shutil.copy("assets/icon/icon.png", os.path.join(out, "codecore", "codecore.png"))
with open(os.path.join(out, "codecore.desktop"), "w") as f:
    f.write(textwrap.dedent("""\
        [Desktop Entry]
        Type=Application
        Name=Codecore
        Comment=Lettore musicale personale
        Exec=sh -c 'cd "$(dirname "$(readlink -f "%k")")/codecore" && ./codecore'
        Icon=codecore
        Categories=AudioVideo;Audio;Player;
        Terminal=false
        """))
archive = shutil.make_archive("build/codecore-linux-x64", "zip", out)
print(archive)
PY
