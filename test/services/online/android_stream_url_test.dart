import 'dart:async';

import 'package:codecore/services/online/android_yt_dlp_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('codecore/ytdlp');
  const video = YtResult(id: 'v', title: 'T', channel: 'C', duration: Duration(minutes: 3));
  final calls = <Map>[];

  void answer(Future<Object?> Function(Map args) f) {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) {
      final args = Map<String, Object?>.from(c.arguments as Map);
      calls.add(args);
      return f(args);
    });
  }

  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test('the fast android_vr client answers: one call, no default clients', () async {
    answer((a) async =>
        '{"url":"https://media.example/fast","http_headers":{"User-Agent":"vr"}}\n');
    final a = await AndroidYtDlpService().streamUrl(video);
    expect(a.uri.toString(), 'https://media.example/fast');
    expect(a.headers, {'User-Agent': 'vr'});
    expect(a.fast, isTrue);
    expect(calls.single['fast'], true);
  });

  test('when the fast client fails, the default clients are tried', () async {
    answer((a) async {
      if (a['fast'] == true) throw PlatformException(code: 'YTDLP', message: 'ERROR: Sign in to confirm your age');
      return 'https://media.example/default';
    });
    final a = await AndroidYtDlpService().streamUrl(video);
    expect(a.uri.toString(), 'https://media.example/default');
    expect(a.fast, isFalse);
    expect(calls.map((c) => c['fast']), [true, null]);
  });

  test('fast: false goes straight to the default clients', () async {
    answer((a) async => 'https://media.example/default\n');
    final a = await AndroidYtDlpService().streamUrl(video, fast: false);
    expect(a.fast, isFalse);
    expect(calls.map((c) => c['fast']), [null]);
  });

  group('hedged request', () {
    const ms = Duration(milliseconds: 1);
    Duration t(int n) => ms * n;

    List<String> mock(Future<Object?> Function(Map<String, Object?> a) f) {
      final cancelled = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) {
        final a = Map<String, Object?>.from(c.arguments as Map);
        if (c.method == 'cancel') {
          cancelled.add('${a['processId']}');
          return Future<Object?>.value();
        }
        calls.add(a);
        return f(a);
      });
      calls.clear();
      return cancelled;
    }

    test('a slow fast client starts the default clients; the first answer wins and the other is cancelled', () async {
      final fastDone = Completer<String>();
      final cancelled = mock((a) => a['fast'] == true
          ? fastDone.future
          : Future<Object?>.delayed(t(30), () => 'https://media.example/default'));
      final svc = AndroidYtDlpService(hedgeAfter: t(60), fastTimeout: t(2000));
      final f = svc.streamUrl(video);
      await Future<void>.delayed(t(30));
      expect(calls.length, 1, reason: 'no hedge yet');
      final a = await f;
      expect(calls.map((c) => c['fast']), [true, null], reason: 'hedged');
      expect(a.uri.toString(), 'https://media.example/default');
      expect(cancelled, hasLength(1), reason: 'the slow fast process is killed');
      fastDone.complete('{"url":"https://media.example/late"}');
      await Future<void>.delayed(t(10));
      expect(a.fast, isFalse);
    });

    test('a fast answer after the hedge started wins and cancels the default clients', () async {
      final cancelled = mock((a) => a['fast'] == true
          ? Future<Object?>.delayed(t(100), () => '{"url":"https://media.example/fast"}')
          : Future<Object?>.delayed(t(3000), () => 'https://media.example/default'));
      final a = await AndroidYtDlpService(hedgeAfter: t(40), fastTimeout: t(2000)).streamUrl(video);
      expect(calls.map((c) => c['fast']), [true, null]);
      expect(a.uri.toString(), 'https://media.example/fast');
      expect(a.fast, isTrue);
      expect(cancelled, hasLength(1));
    });

    test('the fast limit expiring falls back to the default clients', () async {
      mock((a) => a['fast'] == true
          ? Completer<Object?>().future
          : Future<Object?>.delayed(t(10), () => 'https://media.example/default'));
      final a = await AndroidYtDlpService(hedgeAfter: t(1000), fastTimeout: t(50)).streamUrl(video);
      expect(a.uri.toString(), 'https://media.example/default');
    });
  });
}
