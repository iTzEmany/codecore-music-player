import 'dart:io';

import 'package:codecore/services/share/lan_client.dart';
import 'package:codecore/services/share/lan_server.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

void main() {
  late Directory tmp;
  late File audio;
  late List<ShareEntry> entries;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lan');
    audio = File(p.join(tmp.path, 'a.mp3'))
      ..writeAsBytesSync(List.generate(1000, (i) => i % 256));
    entries = [
      ShareEntry(
          id: 1,
          path: audio.path,
          title: 'Song',
          artist: 'Band',
          album: 'Alb',
          sizeBytes: 1000,
          durationMs: 1000,
          ext: 'mp3'),
    ];
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  group('range parser', () {
    test('valid forms', () {
      final a = parseRange('bytes=0-99', 1000);
      expect((a.start, a.end), (0, 99));
      final b = parseRange('bytes=900-', 1000);
      expect((b.start, b.end), (900, 999));
      final c = parseRange('bytes=-100', 1000);
      expect((c.start, c.end), (900, 999));
      expect(parseRange(null, 1000).isFull, true);
      expect(parseRange('bytes=10-5000', 1000).end, 999);
    });
    test('invalid forms', () {
      for (final h in ['bytes=1000-', 'bytes=50-10', 'bytes=-', 'items=0-1', 'bytes=-0']) {
        expect(identical(parseRange(h, 1000), RangeResult.invalid), true, reason: h);
      }
    });
  });

  group('handler', () {
    Handler make({LanGuard? guard}) => buildShareHandler(
          entries: entries,
          guard: guard ?? LanGuard(pin: '123456'),
          deviceName: 'Test',
          clientIp: (_) => '10.0.0.5',
        );
    Request req(String path, {String? pin, String? range}) => Request(
          'GET',
          Uri.parse('http://x/$path'),
          headers: {
            'X-Pin': ?pin,
            'Range': ?range,
          },
        );

    test('wrong PIN -> 401, missing id -> 404, bad range -> 416', () async {
      final h = make();
      expect((await h(req('manifest', pin: '000000'))).statusCode, 401);
      expect((await h(req('file/99', pin: '123456'))).statusCode, 404);
      expect((await h(req('file/abc', pin: '123456'))).statusCode, 404);
      expect(
          (await h(req('file/1', pin: '123456', range: 'bytes=5000-'))).statusCode,
          416);
    });

    test('a path in place of the id never reaches the filesystem', () async {
      final r = await make()(req('file/..%2F..%2Fetc%2Fpasswd', pin: '123456'));
      expect(r.statusCode, 404);
    });

    test('range returns 206 with the right bytes', () async {
      final r = await make()(req('file/1', pin: '123456', range: 'bytes=10-19'));
      expect(r.statusCode, 206);
      expect(r.headers['content-range'], 'bytes 10-19/1000');
      final bytes = await r.read().expand((c) => c).toList();
      expect(bytes, List.generate(10, (i) => 10 + i));
    });

    test('five failures block the IP for 60 s, even with the right PIN', () async {
      var now = DateTime(2026, 1, 1);
      final guard = LanGuard(pin: '123456', now: () => now);
      final h = make(guard: guard);
      for (var i = 0; i < 5; i++) {
        await h(req('manifest', pin: '000000'));
      }
      expect((await h(req('manifest', pin: '123456'))).statusCode, 429);
      now = now.add(const Duration(seconds: 61));
      expect((await h(req('manifest', pin: '123456'))).statusCode, 200);
    });
  });

  group('server + client over loopback', () {
    late LanServer server;
    late ShareInfo info;

    setUp(() async {
      server = LanServer();
      info = await server.start(
          entries: entries, host: '127.0.0.1', deviceName: 'Test PC');
    });
    tearDown(() => server.stop());

    test('hello, manifest, download', () async {
      final c = LanClient();
      expect((await c.hello('127.0.0.1', info.port)).name, 'Test PC');
      final list = await c.manifest('127.0.0.1', info.port, info.pin);
      expect(list.single.title, 'Song');
      final out = Directory(p.join(tmp.path, 'out'));
      String? path;
      await for (final e
          in c.download('127.0.0.1', info.port, info.pin, list.single, out)) {
        path = e.path ?? path;
      }
      expect(p.basename(path!), 'Band - Song.mp3');
      expect(File(path).readAsBytesSync(), audio.readAsBytesSync());
      expect(out.listSync().where((f) => f.path.endsWith('.part')), isEmpty);

      // Second download never overwrites.
      String? second;
      await for (final e
          in c.download('127.0.0.1', info.port, info.pin, list.single, out)) {
        second = e.path ?? second;
      }
      expect(p.basename(second!), 'Band - Song (2).mp3');
    });

    test('wrong PIN is reported', () async {
      expect(
          () => LanClient().manifest('127.0.0.1', info.port, '000000'),
          throwsA(isA<LanException>()
              .having((e) => e.error, 'error', LanError.wrongPin)));
    });

    test('cancel leaves no .part', () async {
      final out = Directory(p.join(tmp.path, 'out2'));
      final cancel = CancelToken();
      final list = await LanClient().manifest('127.0.0.1', info.port, info.pin);
      cancel.cancel();
      await LanClient()
          .download('127.0.0.1', info.port, info.pin, list.single, out,
              cancel: cancel)
          .drain<void>();
      expect(out.existsSync() ? out.listSync() : [], isEmpty);
    });

    test('after stop the server no longer answers', () async {
      await server.stop();
      expect(() => LanClient().hello('127.0.0.1', info.port),
          throwsA(isA<LanException>()));
    });
  });

  test('address parsing', () {
    expect(LanClient.parseAddress('192.168.1.5:8080')!.port, 8080);
    expect(LanClient.parseAddress('http://pc.local:9/x')!.host, 'pc.local');
    expect(LanClient.parseAddress('nonsense'), isNull);
    expect(LanClient.parseAddress('h:99999'), isNull);
  });
}
