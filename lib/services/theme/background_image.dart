import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../core/clock.dart';

/// The longest side a background picture is kept at: enough for a phone or a
/// desktop window, small enough not to weigh on memory or on start-up.
const kMaxBackgroundSide = 1600;

const _maxSourceBytes = 25 * 1024 * 1024;

/// Copies [source] into [dir] as a PNG no bigger than [kMaxBackgroundSide],
/// for the theme [themeId], and removes that theme's older pictures. Returns
/// the new path, or null when the file is too big or is not a picture (nothing
/// is changed then). Decoding and encoding run in the engine's own threads.
Future<String?> importBackgroundImage(File source, Directory dir, String themeId) async {
  try {
    if (await source.length() > _maxSourceBytes) return null;
    final bytes = await source.readAsBytes();
    final png = await _scaledPng(bytes);
    if (png == null) return null;
    await dir.create(recursive: true);
    final out = File(p.join(dir.path, 'bg-$themeId-${nowMs()}.png'));
    await out.writeAsBytes(png, flush: true);
    await deleteBackgroundImages(dir, themeId, except: out.path);
    return out.path;
  } on Object catch (e, st) {
    AppLog.w('background picture not imported', e, st);
    return null;
  }
}

Future<Uint8List?> _scaledPng(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final longer = descriptor.width > descriptor.height ? descriptor.width : descriptor.height;
    final scale = longer > kMaxBackgroundSide ? kMaxBackgroundSide / longer : 1.0;
    codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round(),
      targetHeight: (descriptor.height * scale).round(),
    );
    image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } on Object catch (e) {
    AppLog.i('not a picture: $e');
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}

/// A blurred picture is kept at most this long: the blur hides the detail.
const kMaxBlurredSide = 800;

/// Where the copy of [path] blurred by [blur] is kept: next to it, with the
/// same `bg-<id>-` name, so the tidying of the theme pictures covers it too.
String blurredVariantPath(String path, double blur) =>
    '${p.withoutExtension(path)}-blur${blur.round()}.png';

/// [path] blurred by [blur], made once and then read from disk: on screen the
/// picture is drawn as it is, with no filter to compute at every frame.
/// [blur] keeps the meaning it had on screen (logical pixels on a phone about
/// 900 tall). Null when [path] cannot be read.
Future<String?> blurredBackground(String path, double blur) async {
  final out = blurredVariantPath(path, blur);
  if (await File(out).exists()) return out;
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image, blurred;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(await File(path).readAsBytes());
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final longer = math.max(descriptor.width, descriptor.height);
    final scale = longer > kMaxBlurredSide ? kMaxBlurredSide / longer : 1.0;
    final w = (descriptor.width * scale).round(), h = (descriptor.height * scale).round();
    codec = await descriptor.instantiateCodec(targetWidth: w, targetHeight: h);
    image = (await codec.getNextFrame()).image;
    final sigma = blur * math.max(w, h) / 900;
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImage(
      image,
      ui.Offset.zero,
      ui.Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: ui.TileMode.clamp),
    );
    blurred = await recorder.endRecording().toImage(w, h);
    final png = await blurred.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) return null;
    final tmp = File('$out.tmp');
    await tmp.writeAsBytes(png.buffer.asUint8List(), flush: true);
    await tmp.rename(out);
    return out;
  } on Object catch (e, st) {
    AppLog.w('background not blurred: $path', e, st);
    return null;
  } finally {
    blurred?.dispose();
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

/// Removes the pictures of [themeId] in [dir] (all of them, or all but
/// [except]). Only files named `bg-<id>-*.png` are ever touched.
Future<void> deleteBackgroundImages(Directory dir, String themeId, {String? except}) async {
  if (!await dir.exists()) return;
  final prefix = 'bg-$themeId-';
  await for (final f in dir.list()) {
    if (f is! File || (except != null && p.equals(f.path, except))) continue;
    final name = p.basename(f.path);
    if (!name.startsWith(prefix) || !name.endsWith('.png')) continue;
    try {
      await f.delete();
    } on FileSystemException catch (e) {
      AppLog.w('could not remove ${f.path}', e);
    }
  }
}

/// Removes every `bg-*.png` in [dir] whose path is not in [keep] (pictures of
/// themes that were deleted or changed).
Future<void> pruneBackgroundImages(Directory dir, Set<String> keep) async {
  if (!await dir.exists()) return;
  // Compared normalised: a stored path may be spelt with / where the folder
  // listing says \ (Windows), and it must still be kept.
  final kept = {for (final k in keep) p.normalize(p.absolute(k))};
  await for (final f in dir.list()) {
    if (f is! File || kept.contains(p.normalize(p.absolute(f.path)))) continue;
    final name = p.basename(f.path);
    if (!name.startsWith('bg-') || !name.endsWith('.png')) continue;
    try {
      await f.delete();
    } on FileSystemException catch (e) {
      AppLog.w('could not remove ${f.path}', e);
    }
  }
}

/// Names of the blurred copies made by [blurredBackground]: `bg-<id>-….-blur<n>.png`.
const blurredCopyPattern = r'^bg-.*-blur\d+\.png$';

/// Removes only the blurred copies in [dir]; the pictures themselves stay and
/// the copies are made again the next time a theme needs them.
Future<void> deleteBlurredCopies(Directory dir) async {
  if (!await dir.exists()) return;
  final copy = RegExp(blurredCopyPattern);
  await for (final f in dir.list()) {
    if (f is! File || !copy.hasMatch(p.basename(f.path))) continue;
    try {
      await f.delete();
    } on FileSystemException catch (e) {
      AppLog.w('could not remove ${f.path}', e);
    }
  }
}
