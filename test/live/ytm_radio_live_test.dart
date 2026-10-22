// Opt-in: the real radio of a song on YouTube Music (a few requests) and the
// yt-dlp mix used when it cannot be read. A failure here means YouTube changed
// the answer: see R70 in docs/99-rischi-e-fallback.md and refresh the fixtures
// in test/fixtures/innertube.
//   CODECORE_LIVE=1 flutter test test/live/ytm_radio_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:codecore/services/online/ytm_radio_parser.dart';
import 'package:codecore/services/online/ytm_radio_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Mother» (Pink Floyd, The Wall): the id of the song, not of a video.
const _seed = 'o7MlC_Qrmmc';

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? false : 'set CODECORE_LIVE=1';
  const timeout = Timeout(Duration(minutes: 2));

  late YtmRadioService radio;
  setUp(() => radio = YtmRadioService(
      InnerTubeClient(), YtDlpProcessService(executable: Platform.environment['YTDLP'])));

  test('the radio of a song has 20+ songs with an album, the seed first', () async {
    final page = await radio.page(_seed);
    final songs = page.items.where((i) => i.kind == RadioKind.song).toList();
    expect(songs.length, greaterThanOrEqualTo(20));
    expect(page.items.first.isSeed, isTrue);
    expect(page.items.first.result.id, _seed);
    expect(page.continuation, isNotNull);
  }, skip: skip, timeout: timeout);

  test('the continuation brings more rows', () async {
    final first = await radio.page(_seed);
    final next = await radio.page(_seed, continuation: first.continuation);
    expect(next.items, isNotEmpty);
  }, skip: skip, timeout: timeout);

  test('the yt-dlp mix has 20+ rows when the direct answer is not readable', () async {
    final page = await radio.radioFallback(_seed);
    expect(page.items.length, greaterThanOrEqualTo(20));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
