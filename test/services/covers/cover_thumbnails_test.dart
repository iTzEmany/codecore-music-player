import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/services/covers/cover_store.dart';
import 'package:codecore/services/covers/cover_thumbnails.dart';
import 'package:codecore/ui/widgets/cover_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// A real picture of [w]×[h] with detail in it, as PNG bytes.
Future<Uint8List> picture(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  for (var i = 0; i < 40; i++) {
    canvas.drawRect(ui.Rect.fromLTWH(i * w / 40, 0, w / 40, h.toDouble()),
        ui.Paint()..color = ui.Color(0xFF000000 | (i * 0x0A1B2C)));
  }
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<Size> sizeOf(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final img = (await codec.getNextFrame()).image;
  final s = Size(img.width.toDouble(), img.height.toDouble());
  img.dispose();
  return s;
}

/// Big enough to get a thumbnail (the fake encoder does not decode it).
final _big = Uint8List.fromList(List.generate(CoverStore.thumbMinBytes + 10, (i) => i % 251));

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('thumbs'));
  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('the engine makes a 320 px PNG; small or unreadable covers get none', (tester) async {
    await tester.runAsync(() async {
      final thumb = await encodeCoverThumbnail(await picture(1000, 600));
      expect(await sizeOf(thumb!), const Size(320, 192));
      final tall = await encodeCoverThumbnail(await picture(500, 1000));
      expect(await sizeOf(tall!), const Size(160, 320));
      expect(await encodeCoverThumbnail(await picture(200, 200)), isNull);
      expect(await encodeCoverThumbnail(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });

  test('saving a cover writes its thumbnail and says so', () async {
    var made = 0;
    final store = CoverStore(Directory(p.join(tmp.path, 'c')), thumbnails: (b) async {
      made++;
      return Uint8List.fromList([7, 7]);
    });
    final events = <({String key, CoverFiles files})>[];
    final sub = CoverStore.changes.listen(events.add);
    final key = (await store.saveFromBytes('a|b', _big, 'image/jpeg'))!;
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    final thumb = File(p.join(store.dir.path, CoverStore.thumbName(key)));
    expect(thumb.readAsBytesSync(), [7, 7]);
    expect(events.single.key, key);
    expect(events.single.files.thumb, thumb.path);

    await store.saveFromBytes('small', [1, 2, 3], 'image/jpeg');
    expect(made, 1, reason: 'a small cover decodes fast: no thumbnail');

    await store.saveFromBytes('a|b', _big, 'image/jpeg', overwrite: true);
    expect(made, 2, reason: 'a replaced cover gets a new thumbnail');
  });

  test('the background pass makes only the missing thumbnails and resumes', () async {
    final dir = Directory(p.join(tmp.path, 'c'));
    final plain = CoverStore(dir);
    for (final a in ['x', 'y', 'z']) {
      await plain.saveFromBytes(a, _big, 'image/jpeg');
    }
    await plain.saveFromBytes('tiny', [1, 2], 'image/jpeg');
    var calls = 0;
    final failing = CoverStore(dir, thumbnails: (b) async => ++calls == 2 ? null : Uint8List.fromList([1]));
    expect(await failing.fillMissingThumbnails(pause: Duration.zero), 2, reason: 'one failed');
    final working = CoverStore(dir, thumbnails: (b) async => Uint8List.fromList([1]));
    expect(await working.fillMissingThumbnails(pause: Duration.zero), 1, reason: 'only the one left');
    expect(await working.fillMissingThumbnails(pause: Duration.zero), 0);
    final listed = working.listAll();
    expect(listed, hasLength(4));
    expect(listed[CoverStore.coverKeyFor('tiny')]!.thumb, isNull);
    expect(listed.values.where((f) => f.thumb != null), hasLength(3));
  });

  test('the UI index is read once and then follows the changes', () async {
    final dir = Directory(p.join(tmp.path, 'c'));
    final first = (await CoverStore(dir).saveFromBytes('one', [1], 'image/png'))!;
    final container = ProviderContainer(overrides: [coversDirProvider.overrideWithValue(dir)]);
    addTearDown(container.dispose);
    expect(container.read(coverFileProvider(first))!.path, endsWith('$first.png'));
    expect(container.read(coverThumbProvider(first))!.path, endsWith('$first.png'),
        reason: 'no thumbnail: the original');

    final store = CoverStore(dir, thumbnails: (b) async => Uint8List.fromList([1]));
    final second = (await store.saveFromBytes('two', _big, 'image/jpeg'))!;
    await Future<void>.delayed(Duration.zero);
    expect(container.read(coverFileProvider(second))!.path, endsWith('$second.jpg'));
    expect(container.read(coverThumbProvider(second))!.path, endsWith('${second}_t.png'));

    final elsewhere = CoverStore(Directory(p.join(tmp.path, 'other')));
    final third = (await elsewhere.saveFromBytes('three', [1], 'image/png'))!;
    await Future<void>.delayed(Duration.zero);
    expect(container.read(coverFileProvider(third)), isNull, reason: 'another folder');
  });
}
