import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a flat search result', () {
    const raw = '{"entries":[{"id":"abc","title":"Song","channel":"Band",'
        '"duration":200.0,"thumbnails":[{"url":"https://t/1.jpg"},'
        '{"url":"https://t/2.jpg"}]},{"id":null}]}';
    final r = parseYtDlpJson(raw);
    expect(r.single.id, 'abc');
    expect(r.single.channel, 'Band');
    expect(r.single.duration, const Duration(seconds: 200));
    expect(r.single.thumbnailUrl, 'https://t/2.jpg');
  });

  test('parses a single video JSON', () {
    final r = parseYtDlpJson('{"id":"x","title":"T","uploader":"U"}');
    expect(r.single.channel, 'U');
  });

  test('progress lines', () {
    expect(parseProgressLine('PROG 500 1000 NA')!.fraction, 0.5);
    expect(parseProgressLine('PROG 500 NA 2000')!.total, 2000);
    expect(parseProgressLine('[download] 10%'), isNull);
  });

  test('stderr mapping', () {
    expect(ytExceptionFromStderr('ERROR: Video unavailable').kind,
        YtErrorKind.unavailable);
    expect(ytExceptionFromStderr('Temporary failure in name resolution').kind,
        YtErrorKind.network);
    expect(ytExceptionFromStderr('HTTP Error 403').kind, YtErrorKind.changed);
  });
}
