import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:codecore/services/theme/background_image.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _png(int w, int h) async {
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xFF3366CC));
  final img = await rec.endRecording().toImage(w, h);
  return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

Future<ui.Image> _decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

void main() {
  late Directory tmp, out;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('bgimg');
    out = Directory('${tmp.path}/theme');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('a big picture is scaled so its longer side is 1600 and kept as a PNG', () async {
    final src = File('${tmp.path}/a.png')..writeAsBytesSync(await _png(2000, 1000));
    final path = (await importBackgroundImage(src, out, 'sea'))!;
    expect(path, startsWith(p.join(out.path, 'bg-sea-')));
    expect(path, endsWith('.png'));
    final img = await _decode(path);
    expect(img.width, 1600);
    expect(img.height, 800);
  });

  test('a small picture keeps its size; a portrait one is limited on its height', () async {
    final small = File('${tmp.path}/s.png')..writeAsBytesSync(await _png(300, 200));
    final img = await _decode((await importBackgroundImage(small, out, 'sea'))!);
    expect([img.width, img.height], [300, 200]);

    final tall = File('${tmp.path}/t.png')..writeAsBytesSync(await _png(600, 1800));
    final t = await _decode((await importBackgroundImage(tall, out, 't'))!);
    expect([t.width, t.height], [533, 1600]);
  });

  test('a new picture replaces the older ones of the same theme only', () async {
    final src = File('${tmp.path}/a.png')..writeAsBytesSync(await _png(50, 50));
    final first = (await importBackgroundImage(src, out, 'sea'))!;
    final other = (await importBackgroundImage(src, out, 'other'))!;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = (await importBackgroundImage(src, out, 'sea'))!;
    expect(File(first).existsSync(), isFalse);
    expect(File(second).existsSync(), isTrue);
    expect(File(other).existsSync(), isTrue, reason: 'another theme\'s picture is not touched');
  });

  test('something that is not a picture, or a missing file, gives null and writes nothing', () async {
    final txt = File('${tmp.path}/x.png')..writeAsStringSync('hello');
    expect(await importBackgroundImage(txt, out, 'sea'), isNull);
    expect(await importBackgroundImage(File('${tmp.path}/none.png'), out, 'sea'), isNull);
    expect(out.existsSync() ? out.listSync() : <FileSystemEntity>[], isEmpty);
  });

  test('prune keeps what is listed and never touches other files', () async {
    out.createSync(recursive: true);
    final keep = File('${out.path}/bg-a-1.png')..writeAsBytesSync([1]);
    final drop = File('${out.path}/bg-b-2.png')..writeAsBytesSync([1]);
    final other = File('${out.path}/notes.txt')..writeAsStringSync('mine');
    final odd = File('${out.path}/bg-c-3.jpg')..writeAsBytesSync([1]);
    await pruneBackgroundImages(out, {keep.path});
    expect(keep.existsSync(), isTrue);
    expect(drop.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
    expect(odd.existsSync(), isTrue);
    await pruneBackgroundImages(Directory('${tmp.path}/missing'), {});
  });

  test('a blurred copy is made once, at most 800 px, next to the picture', () async {
    final src = File('${tmp.path}/a.png')..writeAsBytesSync(await _png(2000, 1000));
    final path = (await importBackgroundImage(src, out, 'sea'))!;
    final blurred = (await blurredBackground(path, 8))!;
    expect(blurred, blurredVariantPath(path, 8));
    expect(p.basename(blurred), startsWith('bg-sea-'), reason: 'tidied with the theme pictures');
    final img = await _decode(blurred);
    expect([img.width, img.height], [800, 400]);
    final made = File(blurred).lastModifiedSync();
    expect(await blurredBackground(path, 8.2), blurred, reason: 'same rounded blur: read, not made');
    expect(File(blurred).lastModifiedSync(), made);
    expect(await blurredBackground('${tmp.path}/none.png', 8), isNull);

    await deleteBackgroundImages(out, 'sea');
    expect(File(blurred).existsSync(), isFalse, reason: 'removed with its theme');
  });
}
