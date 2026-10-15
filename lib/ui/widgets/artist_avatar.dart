import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'cover_image.dart';

/// 1–2 initials, upper case; «?» for an empty name.
String artistMonogram(String? name) {
  final words = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  final first = String.fromCharCode(words.first.runes.first).toUpperCase();
  if (words.length == 1) return first;
  return first + String.fromCharCode(words[1].runes.first).toUpperCase();
}

/// Deterministic hue limited to violet–magenta–blue (250–320°).
double artistHue(String? name) {
  var h = 0;
  for (final r in (name ?? '').toLowerCase().runes) {
    h = (h * 31 + r) & 0x7fffffff;
  }
  return 250 + (h % 71);
}

/// Circle with the cover of the artist's most frequent album, otherwise a
/// monogram on a dark gradient.
class ArtistAvatar extends StatelessWidget {
  const ArtistAvatar({
    super.key,
    required this.name,
    required this.size,
    this.coverKey,
  });

  final String? name;
  final double size;
  final String? coverKey;

  @override
  Widget build(BuildContext context) {
    if (coverKey != null) {
      return ClipOval(
          child: CoverImage(coverKey: coverKey, size: size, radius: 0));
    }
    final hue = artistHue(name);
    final top = HSLColor.fromAHSL(1, hue, 0.45, 0.30).toColor();
    final bottom = HSLColor.fromAHSL(1, (hue + 20) % 360, 0.5, 0.14).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, bottom]),
      ),
      child: Text(artistMonogram(name),
          style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w700,
              color: context.cc.text)),
    );
  }
}
