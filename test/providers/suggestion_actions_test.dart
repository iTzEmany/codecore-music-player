import 'dart:io';

import 'package:codecore/providers/pending_playlist_adds.dart';
import 'package:codecore/providers/suggestion_actions.dart';
import 'package:codecore/services/audio/online_entries.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/shuffle_plus/suggestion_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _song = YtResult(id: 'v1', title: 'Streamed', channel: 'Chan', duration: null);

void main() {
  late Directory dir;
  late OnlineEntries online;
  late SuggestionLog log;
  late int id;
  late List<(String, String?)> downloads;
  var instant = false; // what the download callback reports
  late List<int> removed;
  late SuggestionActions actions;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('actions');
    online = OnlineEntries();
    id = online.register(_song, seedTitle: 'Seed');
    log = SuggestionLog(
      file: () async => File(p.join(dir.path, 'suggestions.json')),
      writeDelay: const Duration(days: 1),
    );
    await log.load();
    log.add(videoId: 'v1', title: 'Streamed', artist: 'Chan', seedTitle: 'Seed');
    downloads = [];
    instant = false;
    removed = [];
    actions = SuggestionActions(
      online: online,
      log: log,
      download: (r, {tag}) async {
        downloads.add((r.id, tag));
        return instant;
      },
      removeQueueId: (i) async => removed.add(i),
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('download queues the song and marks it downloaded', () async {
    expect(await actions.downloadEntry(id), isFalse);
    expect(downloads, [('v1', null)]);
    expect(log.latest('v1')?.outcome, SuggestionOutcome.downloaded);
  });

  test('an instant promotion is reported to the caller', () async {
    instant = true;
    expect(await actions.downloadEntry(id), isTrue);
  });

  test('add to playlist downloads with the playlist in the tag', () async {
    expect(await actions.addToPlaylist(id, 5), isFalse);
    expect(downloads, [('v1', addToPlaylistTag(5))]);
    expect(log.latest('v1')?.outcome, SuggestionOutcome.downloaded);
  });

  test('dislike marks it and takes it out of the queue', () async {
    await actions.dislike(id);
    expect(log.latest('v1')?.outcome, SuggestionOutcome.disliked);
    expect(log.disliked('v1'), isTrue);
    expect(removed, [id]);
  });

  test('remove only takes it out of the queue', () async {
    await actions.remove(id);
    expect(removed, [id]);
    expect(log.latest('v1')?.outcome, SuggestionOutcome.queued);
  });

  test('an entry the registry forgot downloads nothing', () async {
    online.forget(id);
    expect(await actions.downloadEntry(id), isNull);
    expect(downloads, isEmpty);
  });
}
