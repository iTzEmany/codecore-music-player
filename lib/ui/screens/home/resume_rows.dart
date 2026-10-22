import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/library_entries.dart';
import '../../../data/repositories/library_queries.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/releases_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/playlist_cover.dart';
import '../../widgets/section_header.dart';
import '../library/album_detail_screen.dart';
import '../now_playing/now_playing_screen.dart' show playContextName;
import '../playlists/playlist_detail_screen.dart';
import '../releases/new_releases_screen.dart';

/// One line of «Riprendi».
sealed class ResumeRow {
  const ResumeRow();
}

/// What is playing now, with its place in the queue.
class QueueResume extends ResumeRow {
  const QueueResume(this.track, this.index, this.length, this.source);
  final Track track;
  final int index, length;
  final PlayContext? source;
}

/// A track left in the middle.
class TrackResume extends ResumeRow {
  const TrackResume(this.track);
  final Track track;
}

/// An album or playlist played lately.
class EntryResume extends ResumeRow {
  const EntryResume(this.entry);
  final LibraryEntry entry;
}

class ReleasesResume extends ResumeRow {
  const ReleasesResume();
}

const _maxRows = 4;

List<ResumeRow> buildResumeRows({
  Track? current,
  List<Track> queue = const [],
  PlayContext? source,
  List<Track> resumable = const [],
  List<LibraryEntry> entries = const [],
  bool hasNewReleases = false,
}) {
  final index = current == null
      ? -1
      : queue.indexWhere((t) => t.id == current.id);
  final queued = current != null && index >= 0;
  final recent = entries.where((e) => e.lastPlayedAt != null).toList()
    ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
  return [
    if (hasNewReleases) const ReleasesResume(),
    if (queued) QueueResume(current, index, queue.length, source),
    for (final t in resumable)
      if (!queued || t.id != current.id) TrackResume(t),
    for (final e in recent) EntryResume(e),
  ].take(_maxRows).toList();
}

/// «Riprendi»: the rows of [buildResumeRows]. Hidden when empty.
class ResumeList extends ConsumerWidget {
  const ResumeList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final albums = ref.watch(albumsProvider).value ?? const <AlbumSummary>[];
    final playlists =
        ref.watch(playlistsProvider).value ?? const <PlaylistSummary>[];
    final newReleases =
        kEnableYoutube && (ref.watch(newReleasesCountProvider).value ?? 0) > 0;
    final rows = buildResumeRows(
      current: ref.watch(currentTrackProvider).value,
      queue: ref.watch(queueProvider).value ?? const [],
      source: ref.watch(playContextProvider),
      resumable: ref.watch(resumableTracksProvider).value ?? const [],
      entries: buildLibraryEntries(
        playlists: playlists,
        albums: albums,
        artists: const [],
        sort: LibrarySort.recent,
      ),
      hasNewReleases: newReleases,
    );
    if (rows.isEmpty) return const SizedBox.shrink();
    final ctrl = ref.read(playerControllerProvider);
    final playing = ref.watch(isPlayingProvider).value ?? false;

    return Column(
      children: [
        SectionHeader(l.homeResume),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
          child: Column(
            children: [
              for (final r in rows)
                switch (r) {
                  ReleasesResume() => HomeRow(
                    key: const ValueKey('resume-releases'),
                    cover: const _IconCover(Icons.new_releases_outlined),
                    title: l.newReleasesTitle,
                    onTap: () =>
                        ShellNav.open<void>(context, const NewReleasesScreen()),
                  ),
                  QueueResume() => HomeRow(
                    key: const ValueKey('resume-queue'),
                    cover: CoverImage(
                      coverKey: r.track.coverKey,
                      size: 48,
                      radius: CcDims.rList,
                    ),
                    title: r.track.title,
                    subtitle: _queueSubtitle(context, r),
                    bar: const _PlayingBar(),
                    // shortcut: a playing row does nothing, open Now Playing if it feels dead.
                    onTap: playing ? null : ctrl.togglePlayPause,
                  ),
                  TrackResume() => HomeRow(
                    key: ValueKey('resume-track-${r.track.id}'),
                    cover: CoverImage(
                      coverKey: r.track.coverKey,
                      size: 48,
                      radius: CcDims.rList,
                    ),
                    title: r.track.title,
                    subtitle: l.homeMinutesLeft(_minutesLeft(r.track)),
                    bar: _Bar(
                      _fraction(r.track.resumePositionMs, r.track.durationMs),
                    ),
                    onTap: () => ctrl.playFromList([r.track], 0),
                  ),
                  EntryResume() => HomeRow(
                    key: ValueKey(
                      'resume-entry-${r.entry.kind.name}-${r.entry.id}',
                    ),
                    cover: r.entry.kind == LibraryKind.playlist
                        ? PlaylistCover(
                            size: 48,
                            radius: CcDims.rList,
                            coverKeys: playlistCoverKeys(null, [
                              r.entry.coverKey,
                            ]),
                          )
                        : CoverImage(
                            coverKey: r.entry.coverKey,
                            size: 48,
                            radius: CcDims.rList,
                          ),
                    title: r.entry.title ?? l.unknownAlbum,
                    subtitle: r.entry.kind == LibraryKind.playlist
                        ? l.tracksCount(r.entry.count)
                        : (r.entry.variousArtists
                              ? l.variousArtists
                              : (r.entry.artist ?? l.unknownArtist)),
                    onTap: () => r.entry.kind == LibraryKind.playlist
                        ? ShellNav.open<void>(
                            context,
                            PlaylistDetailScreen(
                              playlist: r.entry.playlist!.playlist,
                            ),
                          )
                        : ShellNav.open<void>(
                            context,
                            AlbumDetailScreen(album: r.entry.album!),
                          ),
                  ),
                },
            ],
          ),
        ),
      ],
    );
  }

  String _queueSubtitle(BuildContext context, QueueResume r) {
    final l = context.l10n;
    final from = playContextName(l, r.source);
    return from == null
        ? l.homeResumeQueue(r.index + 1, r.length)
        : l.homeResumeQueueFrom(from, r.index + 1, r.length);
  }

  int _minutesLeft(Track t) {
    final left = t.durationMs - (t.resumePositionMs ?? 0);
    return (left / 60000).ceil().clamp(1, 1 << 30);
  }

  double _fraction(int? position, int? duration) =>
      duration == null || duration <= 0 || position == null
      ? 0
      : (position / duration).clamp(0.0, 1.0);
}

/// A cover, two lines and an optional bar: the row of Home lists.
class HomeRow extends StatelessWidget {
  const HomeRow({
    super.key,
    required this.cover,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.bar,
  });

  final Widget cover;
  final String title;
  final String? subtitle;
  final Widget? bar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CcDims.rList),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              cover,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyLarge,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium,
                      ),
                    if (bar != null) ...[const SizedBox(height: 6), bar!],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconCover extends StatelessWidget {
  const _IconCover(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: context.cc.surface2,
      borderRadius: BorderRadius.circular(CcDims.rList),
    ),
    child: Icon(icon, color: context.cc.accent),
  );
}

/// The 2 px progress line under a row.
class _Bar extends StatelessWidget {
  const _Bar(this.fraction);
  final double fraction;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(1),
    child: LinearProgressIndicator(
      value: fraction,
      minHeight: 2,
      color: context.cc.accent,
      backgroundColor: context.cc.surface3,
    ),
  );
}

/// Only this widget follows the position tick, not the whole list.
class _PlayingBar extends ConsumerWidget {
  const _PlayingBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final dur = ref.watch(durationProvider).value;
    return _Bar(
      dur == null || dur.inMilliseconds <= 0
          ? 0
          : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0),
    );
  }
}
