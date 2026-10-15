import 'dart:io';

import 'package:codecore/services/jam/jam_cache.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_output.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

JamItem item(int id, {int size = 0}) => JamItem(
    id: id, ownerDeviceId: 'p', title: 't$id', ext: 'mp3', sizeBytes: size);

void main() {
  late HttpServer server;
  late Directory dir;
  late Uri base;
  var hits = 0;
  String? seenToken;

  setUp(() async {
    hits = 0;
    dir = Directory.systemTemp.createTempSync('jamcache');
    server = await io.serve((Request r) {
      hits++;
      seenToken = r.headers['x-jam-token'];
      if (r.url.path == 'gone') return Response.notFound('no');
      return Response.ok(List.filled(64, 7));
    }, InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://127.0.0.1:${server.port}');
  });

  tearDown(() async {
    await server.close(force: true);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('downloads once with the token and serves from cache', () async {
    final c = JamCache(Directory('${dir.path}/c'));
    final f = await c.fetch(item(1), base.resolve('ok'), {'x-jam-token': 'abc'});
    expect(f!.lengthSync(), 64);
    expect(seenToken, 'abc');
    await c.fetch(item(1), base.resolve('ok'), {});
    expect(hits, 1);
    final src = c.sourceFor(item(1), const JamSource.remote(null as dynamic, {}));
    expect(src!.path, f.path);
  });

  test('failure leaves nothing behind; oversize is skipped', () async {
    final c = JamCache(Directory('${dir.path}/c'), maxBytes: 10);
    expect(await c.fetch(item(2), base.resolve('gone'), {}), isNull);
    expect(c.cached(item(2)), isNull);
    expect(await c.fetch(item(3, size: 100), base.resolve('ok'), {}), isNull);
    expect(hits, 1);
    // downloaded larger than declared: dropped
    expect(await c.fetch(item(4), base.resolve('ok'), {}), isNull);
    expect(c.cached(item(4)), isNull);
  });

  test('prune keeps wanted ids, clear wipes the folder', () async {
    final c = JamCache(Directory('${dir.path}/c'));
    await c.fetch(item(1), base.resolve('ok'), {});
    await c.fetch(item(2), base.resolve('ok'), {});
    await c.prune({2});
    expect(c.cached(item(1)), isNull);
    expect(c.cached(item(2)), isNotNull);
    await c.clear();
    expect(Directory('${dir.path}/c').existsSync(), false);
  });
}
