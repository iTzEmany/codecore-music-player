import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:codecore/services/online/download_queue.dart';
import 'package:codecore/services/online/retry_policy.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';

class _Fixed implements Random {
  _Fixed(this.value);
  final double value;
  @override
  bool nextBool() => value > .5;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => (value * max).floor();
}

YtResult r(String id) =>
    YtResult(id: id, title: 'Song', channel: 'Band', duration: null);

void main() {
  group('RetryPolicy', () {
    test('3 attempts at 5, 20 and 60 s, then give up', () {
      final p = RetryPolicy(random: _Fixed(.5), jitter: 0.2);
      expect(p.nextDelay(0, YtErrorKind.network), const Duration(seconds: 5));
      expect(p.nextDelay(1, YtErrorKind.changed), const Duration(seconds: 20));
      expect(p.nextDelay(2, YtErrorKind.network), const Duration(seconds: 60));
      expect(p.nextDelay(3, YtErrorKind.network), isNull);
    });

    test('jitter spreads the delay by ±20 %', () {
      expect(RetryPolicy(random: _Fixed(0)).nextDelay(1, YtErrorKind.network),
          const Duration(seconds: 16));
      expect(RetryPolicy(random: _Fixed(1)).nextDelay(1, YtErrorKind.network),
          const Duration(seconds: 24));
    });

    test('only transient errors are retried', () {
      final p = RetryPolicy();
      for (final k in [
        YtErrorKind.rateLimited,
        YtErrorKind.unavailable,
        YtErrorKind.toolMissing,
        YtErrorKind.toolOutdated,
      ]) {
        expect(p.nextDelay(0, k), isNull, reason: '$k');
      }
    });
  });

  group('DownloadQueue retries', () {
    late List<Duration> waits;
    late List<String> settled;

    DownloadQueue make(Stream<DownloadProgress> Function(YtResult, CancelToken) f,
        {Future<void> Function(Duration)? wait}) {
      waits = [];
      settled = [];
      return DownloadQueue(
        downloader: (res, dir, cancel) => f(res, cancel),
        outDir: () async => Directory.systemTemp,
        onChanged: (_) {},
        retryPolicy: RetryPolicy(random: _Fixed(.5)),
        wait: wait ??
            (d) async {
              waits.add(d);
            },
        onSettled: (i) => settled.add('${i.result.id}:${i.status.name}'),
        uiInterval: Duration.zero,
      );
    }

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

    test('a network error is retried 3 times, then fails for good', () async {
      var calls = 0;
      final q = make((res, c) async* {
        calls++;
        throw const YtException(YtErrorKind.network);
      });
      q.add(r('a'));
      await settle();
      expect(calls, 4, reason: '1 attempt + 3 retries');
      expect(waits, [
        const Duration(seconds: 5),
        const Duration(seconds: 20),
        const Duration(seconds: 60),
      ]);
      expect(q.items.single.status, DownloadStatus.failed);
      expect(q.items.single.error, YtErrorKind.network);
      expect(settled, ['a:failed'], reason: 'one settlement, the final one');
    });

    test('a retry that works settles as done and not before', () async {
      var calls = 0;
      final q = make((res, c) async* {
        calls++;
        if (calls < 3) throw const YtException(YtErrorKind.changed);
        yield DownloadProgress(received: 1, total: 1, path: '/o/${res.id}');
      });
      q.add(r('a'));
      await settle();
      expect(q.items.single.status, DownloadStatus.done);
      expect(q.items.single.attempt, 2);
      expect(settled, ['a:done']);
    });

    test('rate limiting and unavailable videos are not retried', () async {
      var calls = 0;
      final q = make((res, c) async* {
        calls++;
        throw YtException(res.id == 'r'
            ? YtErrorKind.rateLimited
            : YtErrorKind.unavailable);
      });
      q.add(r('r'));
      q.add(r('u'));
      await settle();
      expect(calls, 2);
      expect(waits, isEmpty);
      expect(settled, containsAll(['r:failed', 'u:failed']));
    });

    test('while waiting the item is waitingRetry and frees its slot', () async {
      final gate = Completer<void>();
      var calls = 0;
      final q = make((res, c) async* {
        calls++;
        if (res.id == 'a' && calls == 1) {
          throw const YtException(YtErrorKind.network);
        }
        yield DownloadProgress(received: 1, total: 1, path: '/o/${res.id}');
      }, wait: (d) => gate.future);
      q.add(r('a'));
      q.add(r('b'));
      await settle();
      expect(q.items[0].status, DownloadStatus.waitingRetry);
      expect(q.items[0].retryDelay, const Duration(seconds: 5));
      expect(q.items[1].status, DownloadStatus.done,
          reason: 'b ran while a waited');
      gate.complete();
      await settle();
      expect(q.items[0].status, DownloadStatus.done);
    });

    test('cancelling during the wait ends as cancelled', () async {
      final gate = Completer<void>();
      final q = make((res, c) async* {
        throw const YtException(YtErrorKind.network);
      }, wait: (d) => gate.future);
      q.add(r('a'));
      await settle();
      expect(q.items.single.status, DownloadStatus.waitingRetry);
      q.cancel(q.items.single.id);
      gate.complete();
      await settle();
      expect(q.items.single.status, DownloadStatus.cancelled);
      expect(settled, ['a:cancelled']);
    });
  });
}
