import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../core/app_log.dart';

/// Longer side of the cover thumbnails: lists (48 dp) and grid tiles (up to
/// ~110 dp) on a 2.75× phone, without upscaling.
const coverThumbSide = 320;

/// Makes the thumbnail of a cover; null when the cover is already that small
/// or cannot be read.
typedef ThumbnailEncoder = Future<Uint8List?> Function(Uint8List cover);

/// The engine decodes straight to the small size and encodes PNG on its own
/// threads: the UI thread only waits. (No JPEG encoder without a new package:
/// a 320 px PNG is ~50–200 KB and decodes 3–30× faster than the original.)
Future<Uint8List?> encodeCoverThumbnail(Uint8List cover) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(cover);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final w = descriptor.width, h = descriptor.height;
    if (w <= coverThumbSide && h <= coverThumbSide) return null;
    codec = await descriptor.instantiateCodec(
      targetWidth: w >= h ? coverThumbSide : null,
      targetHeight: h > w ? coverThumbSide : null,
    );
    image = (await codec.getNextFrame()).image;
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png?.buffer.asUint8List();
  } on Object catch (e, st) {
    AppLog.w('cover thumbnail failed', e, st);
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}
