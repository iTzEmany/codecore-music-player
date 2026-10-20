import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A picture from the network in a [width]×[height] box: decoded at that size,
/// the placeholder until it arrives, then a short fade (none with «Riduci
/// animazioni»). A picture that fails leaves the placeholder.
class NetThumbnail extends StatelessWidget {
  const NetThumbnail({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.icon,
    this.radius = CcDims.rList,
  });

  final String? url;
  final double width, height, radius;
  final IconData icon;

  static const fade = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final placeholder = ColoredBox(
      color: cc.surface3,
      child: Icon(icon, color: cc.textMuted),
    );
    final u = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: u == null
            ? placeholder
            : Stack(
                fit: StackFit.expand,
                children: [
                  placeholder,
                  Image.network(
                    u,
                    cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
                    fit: BoxFit.cover,
                    frameBuilder: (context, image, frame, loadedAtOnce) => loadedAtOnce
                        ? image
                        : AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: ccDuration(context, fade),
                            curve: Curves.easeOut,
                            child: image,
                          ),
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
      ),
    );
  }
}
