import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/library_providers.dart';
import '../theme/tokens.dart';

/// Resolves a cover file once per key (no repeated disk checks while scrolling).
final coverFileProvider = Provider.family<File?, String>((ref, key) {
  final dir = ref.watch(coversDirProvider);
  for (final ext in const ['jpg', 'png']) {
    final f = File('${dir.path}/$key.$ext');
    if (f.existsSync()) return f;
  }
  return null;
});

class CoverImage extends ConsumerWidget {
  const CoverImage({
    super.key,
    required this.coverKey,
    required this.size,
    this.radius = CcDims.rList,
    this.heroTag,
  });

  final String? coverKey;
  final double size, radius;

  /// Shared-element tag (mini-player ↔ Now Playing); null = no Hero.
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = context.cc;
    final placeholder = ColoredBox(
      color: cc.surface3,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.5,
        color: cc.textMuted,
      ),
    );
    final key = coverKey;
    final file = key == null ? null : ref.watch(coverFileProvider(key));
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: file == null
            ? placeholder
            : Image.file(
                file,
                cacheWidth: px,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return image;
  }
}
