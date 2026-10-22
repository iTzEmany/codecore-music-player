import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../providers/player_providers.dart';
import '../../services/audio/online_entries.dart';
import '../../services/online/google_thumb.dart';
import '../theme/tokens.dart';
import 'cover_image.dart';
import 'net_thumbnail.dart';
import 'radio_art.dart';

/// The picture of a track: the cover of a library track, the thumbnail of
/// the registry for a streamed one (negative id).
class TrackArt extends ConsumerWidget {
  const TrackArt({
    super.key,
    required this.track,
    required this.size,
    this.radius = CcDims.rList,
    this.heroTag,
  });

  final Track track;
  final double size, radius;
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOnlineId(track.id)) {
      return CoverImage(coverKey: track.coverKey, size: size, radius: radius, heroTag: heroTag);
    }
    final online = ref.watch(onlineEntriesProvider);
    final radio = online?.radioOf(track.id)?.station;
    if (radio != null) {
      final art = RadioArt(station: radio, size: size, radius: radius);
      return heroTag == null ? art : Hero(tag: heroTag!, child: art);
    }
    final url = online?[track.id]?.result.thumbnailUrl;
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    Widget image = NetThumbnail(
      url: url == null ? null : googleThumbAt(url, px),
      width: size,
      height: size,
      radius: radius,
      icon: Icons.cloud_outlined,
    );
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return image;
  }
}
