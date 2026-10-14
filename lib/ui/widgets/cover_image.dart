import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/library_providers.dart';

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
    this.radius = 6,
  });

  final String? coverKey;
  final double size, radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.music_note,
          size: size * 0.5, color: scheme.onSurfaceVariant),
    );
    final key = coverKey;
    final file = key == null ? null : ref.watch(coverFileProvider(key));
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
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
  }
}
