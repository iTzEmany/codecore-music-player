import 'package:flutter/material.dart';

import '../../services/radio/radio_station.dart';
import '../theme/tokens.dart';
import 'net_thumbnail.dart';

/// A station's picture: its favicon, decoded at the size shown, or the
/// station's initial on a plain tile when it has none or does not load.
class RadioArt extends StatelessWidget {
  const RadioArt({
    super.key,
    required this.station,
    required this.size,
    this.radius = CcDims.rList,
    this.circle = false,
  });

  final RadioStation station;
  final double size, radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final name = station.name.trim();
    final initial = name.isEmpty ? '' : String.fromCharCode(name.runes.first).toUpperCase();
    return NetThumbnail(
      url: station.faviconUrl.isEmpty ? null : station.faviconUrl,
      width: size,
      height: size,
      radius: radius,
      circle: circle,
      icon: Icons.radio_rounded,
      placeholderChild: initial.isEmpty
          ? null
          : Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleSmall!
                    .sized(size * 0.42)
                    .copyWith(color: cc.textMuted),
              ),
            ),
    );
  }
}
