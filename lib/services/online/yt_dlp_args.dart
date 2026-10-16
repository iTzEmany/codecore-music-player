import 'youtube_service.dart';

/// Containers a download can end up in (the original format keeps whatever
/// YouTube serves: m4a when there is one, else opus in webm).
const downloadExtensions = ['mp3', 'm4a', 'opus', 'webm'];

/// Command-line for downloading one video with the desktop `yt-dlp`.
/// [jsArgs] are the `--js-runtimes` flags found on this machine.
List<String> buildDownloadArgs({
  required String id,
  required String stem,
  required bool hasFfmpeg,
  required DownloadOptions options,
  List<String> jsArgs = const [],
}) {
  final rate = options.rateLimitKBps;
  final original = options.format == DownloadFormat.original;
  final mp3 = hasFfmpeg && !original;
  return [
    '--no-playlist',
    '--no-warnings',
    '--newline',
    '--no-part',
    '--progress-template',
    'download:PROG %(progress.downloaded_bytes)s '
        '%(progress.total_bytes)s %(progress.total_bytes_estimate)s',
    ...jsArgs,
    if (rate != null && rate > 0) ...['--limit-rate', '${rate}K'],
    '-f',
    mp3 ? 'bestaudio/best' : 'bestaudio[ext=m4a]/bestaudio/best',
    // Extract the audio stream without re-encoding it.
    if (original && hasFfmpeg) '-x',
    if (mp3) ...['-x', '--audio-format', 'mp3', '--audio-quality', '256K'],
    '-o',
    '$stem.%(ext)s',
    'https://www.youtube.com/watch?v=$id',
  ];
}

/// Extension to reserve in [uniquePath]: MP3 when it will be converted, m4a
/// otherwise. Pair it with [anyDownloadExtensionExists] for the uniqueness check.
String reservedExtension({required bool hasFfmpeg, required DownloadOptions options}) =>
    hasFfmpeg && options.format == DownloadFormat.mp3 ? 'mp3' : 'm4a';

/// True when `<stem>.<ext>` exists for any container a download can produce,
/// so the original format cannot overwrite a file saved with another extension.
bool anyDownloadExtensionExists(String path, bool Function(String) exists) {
  final dot = path.lastIndexOf('.');
  final stem = dot < 0 ? path : path.substring(0, dot);
  return downloadExtensions.any((e) => exists('$stem.$e'));
}
