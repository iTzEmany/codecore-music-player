import 'youtube_service.dart';

/// Command-line for downloading one video with the desktop `yt-dlp`.
/// [jsArgs] are the `--js-runtimes` flags found on this machine.
List<String> buildDownloadArgs({
  required String id,
  required String stem,
  required bool convert,
  required DownloadOptions options,
  List<String> jsArgs = const [],
}) {
  final rate = options.rateLimitKBps;
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
    convert ? 'bestaudio/best' : 'bestaudio[ext=m4a]/bestaudio/best',
    if (convert) ...['-x', '--audio-format', 'mp3', '--audio-quality', '256K'],
    '-o',
    '$stem.%(ext)s',
    'https://www.youtube.com/watch?v=$id',
  ];
}
