import 'dart:async';
import 'dart:io';

import 'package:codecore/services/online/download_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

YtResult r(String id, {String title = 'Song', String channel = 'Band'}) =>
    YtResult(id: id, title: title, channel: channel, duration: null);

void main() {
  test('uniquePath adds numeric suffixes without overwriting', () {
    final taken = {'/d/a.m4a', '/d/a (2).m4a'};
    expect(uniquePath('/d', 'a', 'm4a', taken.contains), '/d/a (3).m4a');
    expect(uniquePath('/d', 'b', 'm4a', taken.contains), '/d/b.m4a');
  });

  test('downloadBaseName sanitises', () {
    expect(downloadBaseName(r('1', title: 'Queen - Who/Wants: Forever (Official Video)', channel: 'Queen')),
        'Queen - WhoWants Forever');
  });

  test('only real youtube hosts are URLs', () {
    expect(isYoutubeUrl('https://www.youtube.com/watch?v=abc'), true);
    expect(isYoutubeUrl('https://youtu.be/abc'), true);
    expect(isYoutubeUrl('https://evil.com/youtube.com'), false);
    expect(isYoutubeUrl('youtube.com is great'), false);
  });

  test('queue runs one at a time and reports done', () async {
    var active = 0, maxActive = 0;
    final done = <String>[];
    final snapshots = <List<DownloadItem>>[];
    final q = DownloadQueue(
      downloader: (res, dir, cancel) async* {
        active++;
        maxActive = active > maxActive ? active : maxActive;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        yield const DownloadProgress(received: 5, total: 10);
        active--;
        yield DownloadProgress(received: 10, total: 10, path: '/o/${res.id}.m4a');
      },
      outDir: () async => Directory.systemTemp,
      onChanged: snapshots.add,
      onDownloaded: (p) async => done.add(p),
      uiInterval: Duration.zero,
    );
    q.add(r('a'));
    q.add(r('b'));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(maxActive, 1);
    expect(done, ['/o/a.m4a', '/o/b.m4a']);
    expect(q.items.every((e) => e.status == DownloadStatus.done), true);
    q.clearFinished();
    expect(q.items, isEmpty);
  });

  test('cancel stops the active item and later ones continue', () async {
    final started = Completer<void>();
    final q = DownloadQueue(
      downloader: (res, dir, cancel) async* {
        if (res.id == 'a') {
          started.complete();
          while (!cancel.isCancelled) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
          return;
        }
        yield DownloadProgress(received: 1, total: 1, path: '/o/${res.id}');
      },
      outDir: () async => Directory.systemTemp,
      onChanged: (_) {},
    );
    q.add(r('a'));
    q.add(r('b'));
    await started.future;
    q.cancel(1);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(q.items[0].status, DownloadStatus.cancelled);
    expect(q.items[1].status, DownloadStatus.done);
  });

  test('errors are mapped per item', () async {
    final q = DownloadQueue(
      downloader: (res, dir, cancel) async* {
        throw const YtException(YtErrorKind.unavailable);
      },
      outDir: () async => Directory.systemTemp,
      onChanged: (_) {},
    );
    q.add(r('x'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(q.items.single.status, DownloadStatus.failed);
    expect(q.items.single.error, YtErrorKind.unavailable);
  });
}
