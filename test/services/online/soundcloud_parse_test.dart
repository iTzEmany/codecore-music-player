import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  group('parseSoundCloudJson', () {
    test('full metadata: the two 30 s previews and the null (DRM) entry are gone, full tracks stay', () {
      final res = parseSoundCloudJson(fixture('scsearch.json'));
      expect(res.map((r) => r.id), ['199428706', '2158904142']);
      expect(res.every((r) => r.source == MediaSource.soundcloud), isTrue);
      expect(res.first.duration, const Duration(seconds: 323));
    });

    test('the flat listing the app really asks for: previews by length, the DRM track is listed', () {
      final res = parseSoundCloudJson(fixture('scsearch_flat.json'));
      // 8 entries, two of 30 s.
      expect(res, hasLength(6));
      expect(res.map((r) => r.id), isNot(contains('254112129')));
      expect(res.map((r) => r.id), isNot(contains('254111872')));
      expect(res.map((r) => r.id), contains('2366118086'),
          reason: 'a DRM track fails only when downloaded, with its own error');
      final r = res.firstWhere((x) => x.id == '2158904142');
      expect(r.channel, 'HOUZ');
      expect(r.downloadUrl, startsWith('https://soundcloud.com/'));
      expect(r.thumbnailUrl, isNotNull);
    });

    test('31 s is still a preview, 32 s is not', () {
      String one(int s) => jsonEncode({
        'entries': [
          {'id': '1', 'title': 'T', 'uploader': 'U', 'duration': s, 'ie_key': 'Soundcloud', 'webpage_url': 'https://soundcloud.com/u/t'},
        ],
      });
      expect(parseSoundCloudJson(one(31)), isEmpty);
      expect(parseSoundCloudJson(one(32)), hasLength(1));
    });

    test('formats that are all previews mark a preview even without a short length', () {
      final raw = jsonEncode({
        'entries': [
          {
            'id': '1', 'title': 'T', 'uploader': 'U', 'ie_key': 'Soundcloud', 'webpage_url': 'https://soundcloud.com/u/t',
            'duration': 200,
            'formats': [{'format_id': 'http_mp3_1_0_preview'}, {'format_id': 'hls_mp3_1_0_preview'}],
          },
          {
            'id': '2', 'title': 'T2', 'uploader': 'U', 'ie_key': 'Soundcloud', 'webpage_url': 'https://soundcloud.com/u/t2',
            'duration': 200,
            'formats': [{'format_id': 'hls_aac_160k'}, {'format_id': 'http_mp3_1_0_preview'}],
          },
        ],
      });
      expect(parseSoundCloudJson(raw).map((r) => r.id), ['2']);
    });

    test('an entry without a length is kept (nothing says it is a preview)', () {
      final raw = jsonEncode({
        'entries': [
          {'id': '1', 'title': 'T', 'uploader': 'U', 'ie_key': 'Soundcloud', 'webpage_url': 'https://soundcloud.com/u/t'},
        ],
      });
      expect(parseSoundCloudJson(raw), hasLength(1));
    });

    test('an empty or non-object answer gives nothing', () {
      expect(parseSoundCloudJson('{"entries": []}'), isEmpty);
      expect(parseSoundCloudJson('[]'), isEmpty);
    });
  });

  group('errors', () {
    test('a DRM-protected track is «unavailable», rate limiting stays rate limiting', () {
      expect(ytExceptionFromStderr('ERROR: [soundcloud] 2366118086: This video is DRM protected').kind,
          YtErrorKind.unavailable);
      expect(ytExceptionFromStderr('ERROR: [soundcloud] Unable to download JSON metadata: HTTP Error 429: Too Many Requests').kind,
          YtErrorKind.rateLimited);
      expect(ytExceptionFromStderr('Temporary failure in name resolution').kind, YtErrorKind.network);
    });
  });

  test('a few more results are asked for than wanted, to make up for the previews', () {
    expect(soundCloudFetchCount(5), greaterThan(5));
    expect(soundCloudFetchCount(10), 15);
  });
}
