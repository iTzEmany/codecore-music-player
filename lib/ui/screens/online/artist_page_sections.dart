import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../services/online/google_thumb.dart';
import '../../../services/online/ytm_artist.dart';
import '../../theme/tokens.dart';
import '../../widgets/net_thumbnail.dart';
import '../../widgets/section_header.dart';

/// Picture size of a release in a carousel.
const releaseCover = 128.0;

/// A picture of [url] at [size] dp, asked of Google at the right step.
String? thumbAt(BuildContext context, String? url, double size) => url == null
    ? null
    : googleThumbAt(url, (size * MediaQuery.devicePixelRatioOf(context)).round());

/// Photo, name and monthly audience at the top of an artist page. Built from
/// the reference the page was opened from, so it is there while the page loads.
class ArtistHeader extends StatelessWidget {
  const ArtistHeader({super.key, required this.artist, this.audience});

  final YtmArtistRef artist;

  /// «25.9M monthly audience» once the page is read.
  final String? audience;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final text = audience ?? artist.audience;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 0, CcDims.margin, 8),
      child: Column(
        children: [
          NetThumbnail(
            url: thumbAt(context, artist.thumbnailUrl, 140),
            width: 140,
            height: 140,
            icon: Icons.person_rounded,
            circle: true,
          ),
          const SizedBox(height: 12),
          Text(artist.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.displaySmall),
          if (text != null && text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: theme.bodyMedium?.copyWith(color: cc.textMuted)),
            ),
        ],
      ),
    );
  }
}

/// «Non in linea · dati del 21/10/2026» over an old copy of the page.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key, required this.fetchedAt});

  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final date = MaterialLocalizations.of(context).formatShortDate(fetchedAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 4, CcDims.margin, 4),
      child: Container(
        key: const ValueKey('offline-notice'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cc.surface1,
          borderRadius: BorderRadius.circular(CcDims.rCard),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 18, color: cc.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(context.l10n.ytmOffline(date),
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grey bars where the songs will be, while the page loads.
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key, this.rows = 5});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Padding(
      key: const ValueKey('page-skeleton'),
      padding: const EdgeInsets.symmetric(horizontal: CcDims.margin, vertical: 12),
      child: Column(
        children: [
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: cc.surface1, borderRadius: BorderRadius.circular(CcDims.rList)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                          color: cc.surface1, borderRadius: BorderRadius.circular(CcDims.rList)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A shelf of albums, singles or EPs, scrolling sideways.
class ReleaseCarousel extends StatelessWidget {
  const ReleaseCarousel({super.key, required this.shelf, required this.onOpen, this.onMore});

  final YtmReleaseShelf shelf;
  final void Function(YtmRelease) onOpen;

  /// Null hides «Mostra tutto» (the page gave no link).
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scaler = MediaQuery.textScalerOf(context);
    final height = releaseCover + 8 + scaler.scale(62);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(shelf.title,
            actionLabel: onMore == null ? null : l.ytmShowAll, onAction: onMore),
        SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: CcDims.margin - 6),
            itemExtent: releaseCover + 12,
            itemCount: shelf.releases.length,
            itemBuilder: (_, i) => ReleaseTile(release: shelf.releases[i], onTap: onOpen),
          ),
        ),
      ],
    );
  }
}

/// One release: cover, title and «EP • 2025».
class ReleaseTile extends StatelessWidget {
  const ReleaseTile({super.key, required this.release, required this.onTap, this.size = releaseCover});

  final YtmRelease release;
  final void Function(YtmRelease) onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    return InkWell(
      key: ValueKey('release-${release.browseId}'),
      borderRadius: BorderRadius.circular(CcDims.rGrid),
      onTap: () => onTap(release),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetThumbnail(
              url: thumbAt(context, release.thumbnailUrl, size),
              width: size,
              height: size,
              radius: CcDims.rGrid,
              icon: Icons.album_rounded,
            ),
            const SizedBox(height: 8),
            Text(release.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.bodyMedium),
            if (release.subtitle.isNotEmpty)
              Text(release.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall?.copyWith(color: cc.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// «Fans might also like»: round photos sideways.
class ArtistCarousel extends StatelessWidget {
  const ArtistCarousel({super.key, required this.shelf, required this.onOpen});

  final YtmArtistShelf shelf;
  final void Function(YtmArtistRef) onOpen;

  static const photo = 96.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final height = photo + 8 + MediaQuery.textScalerOf(context).scale(40);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(shelf.title),
        SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: CcDims.margin - 6),
            itemExtent: photo + 20,
            itemCount: shelf.artists.length,
            itemBuilder: (_, i) {
              final a = shelf.artists[i];
              return InkWell(
                key: ValueKey('similar-${a.id}'),
                borderRadius: BorderRadius.circular(CcDims.rGrid),
                onTap: () => onOpen(a),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      NetThumbnail(
                        url: thumbAt(context, a.thumbnailUrl, photo),
                        width: photo,
                        height: photo,
                        icon: Icons.person_rounded,
                        circle: true,
                      ),
                      const SizedBox(height: 8),
                      Text(a.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The biography: three lines, «Altro» opens the rest.
class AboutSection extends StatefulWidget {
  const AboutSection({super.key, required this.text});

  final String text;

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l.ytmAbout),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
          child: AnimatedSize(
            duration: ccDuration(context, CcMotion.sheet),
            alignment: Alignment.topCenter,
            child: Text(
              widget.text,
              key: const ValueKey('about-text'),
              maxLines: _open ? null : 3,
              overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cc.textMuted),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CcDims.margin - 8),
          child: TextButton(
            key: const ValueKey('about-toggle'),
            onPressed: () => setState(() => _open = !_open),
            child: Text(_open ? l.ytmLess : l.ytmMore),
          ),
        ),
      ],
    );
  }
}
