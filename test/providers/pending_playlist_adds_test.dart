import 'dart:async';

import 'package:codecore/providers/pending_playlist_adds.dart';
import 'package:codecore/services/online/download_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _song = YtResult(id: 'v1', title: 'T', channel: 'C', duration: null);

DownloadItem _item(DownloadStatus status, {String? tag, String? path}) =>
    DownloadItem(id: 1, result: _song, status: status, tag: tag, path: path);

void main() {
  late StreamController<DownloadItem> settled;
  late List<String> added;

  setUp(() {
    settled = StreamController<DownloadItem>.broadcast(sync: true);
    added = [];
    PendingPlaylistAdds(
      settled: settled.stream,
      trackIdForPath: (path) async => path == '/m/a.m4a' ? 42 : null,
      addTracks: (pl, ids) async => added.add('$pl:$ids'),
    );
  });

  test('a download that finished joins the playlist in its tag', () async {
    settled.add(_item(DownloadStatus.done, tag: addToPlaylistTag(7), path: '/m/a.m4a'));
    await pumpEventQueue();
    expect(added, ['7:[42]']);
  });

  test('a failed download adds nothing', () async {
    settled.add(_item(DownloadStatus.failed, tag: addToPlaylistTag(7)));
    await pumpEventQueue();
    expect(added, isEmpty);
  });

  test('another tag, or none, adds nothing', () async {
    settled.add(_item(DownloadStatus.done, tag: 'import:1:2', path: '/m/a.m4a'));
    settled.add(_item(DownloadStatus.done, path: '/m/a.m4a'));
    await pumpEventQueue();
    expect(added, isEmpty);
  });
}
