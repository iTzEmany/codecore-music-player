# Codecore (Flutter)

Lettore musicale personale, standalone (nessun backend), per **Android, Linux e Windows**.
Italiano, English, Deutsch, Español.

- Piano di lavoro: [`docs/00-INDICE.md`](docs/00-INDICE.md) · avanzamento: [`docs/PROGRESS.md`](docs/PROGRESS.md)

## Funzioni
- **Libreria**: scansione incrementale di cartelle, tag letti (mai riscritti), copertine, brani / album / artisti,
  ricerca e ordinamenti, brani mancanti gestiti senza perdere preferiti e playlist.
- **Riproduzione**: coda separata dalla lista, shuffle senza ripetizioni, repeat off/all/one, ripresa all'avvio,
  notifica e tasti cuffie su Android, scorciatoie da tastiera su desktop, timer di spegnimento con fade-out.
- **Preferiti, playlist** (copertina personalizzabile, riordino), modifica info (solo nel DB), temi (OLED, carbone, blu notte, chiaro).
- **Online (solo su azione tua o opzioni attive)**: info e copertine da iTunes, testi sincronizzati da LRCLIB,
  curiosità da Wikipedia, ricerca e download da YouTube con yt-dlp.
- **Condivisione LAN** telefono ↔ PC con PIN e QR, senza server esterni.
- **Import** di preferiti, testi e playlist dalla vecchia app Python (Impostazioni → «Importa dalla vecchia app»).

## Installare
- **Android**: `flutter build apk --release --split-per-abi` e `adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
  Il pacchetto include Python, yt-dlp, QuickJS e ffmpeg (YouTube funziona senza backend; il primo avvio estrae i file ed è più lento).
- **Linux**: `flutter build linux --release`, poi eseguire `build/linux/x64/release/bundle/codecore`.
  Servono `libmpv` (`sudo apt install libmpv-dev mpv`). Per YouTube: `yt-dlp` e `ffmpeg` nel PATH (`pip install -U yt-dlp`)
  e un runtime JavaScript (`node`, `deno` o `quickjs`).
- **Windows**: su una macchina Windows con Visual Studio 2022 (C++): `flutter build windows --release`
  e zippare `build\windows\x64\runner\Release\`. Per YouTube servono `yt-dlp.exe` e `ffmpeg.exe` nel PATH.

## Compilare / sviluppare
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # dopo modifiche alle tabelle drift
flutter analyze && flutter test
flutter gen-l10n                                            # dopo modifiche agli ARB
```
Firma Android: crea `android/key.properties` (non versionato) con `storeFile`, `storePassword`, `keyAlias`, `keyPassword`;
senza il file la build release usa la chiave di debug.

## Limiti noti
- Niente crossfade/gapless nativo, niente equalizzatore, niente scrittura dei tag nei file.
- Controlli multimediali di sistema (MPRIS / SMTC) non implementati; i tasti multimediali funzionano a finestra attiva.
- Condivisione LAN in HTTP in chiaro (protetta da PIN, solo per reti domestiche).
- Lo scanner QR non è incluso: inserire IP:porta e PIN o incollare il link del QR.
- yt-dlp cambia spesso: su Android viene aggiornato a ogni avvio; su desktop va aggiornato a mano.

## Note legali
Il download da YouTube può violare i termini del servizio e il diritto d'autore: la funzione è pensata per uso strettamente
personale e si disattiva con `kEnableYoutube = false` in `lib/core/constants.dart`. Testi e metadati provengono da servizi
terzi (LRCLIB, iTunes Search API, Wikipedia — CC BY-SA) e restano di proprietà dei rispettivi titolari.
La libreria `youtubedl-android` usata su Android è sotto licenza GPL-3.0.
