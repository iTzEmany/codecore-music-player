import 'dart:io';
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
