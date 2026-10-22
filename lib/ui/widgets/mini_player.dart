import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/jam_providers.dart';
import '../../providers/player_providers.dart';
import '../../services/jam/jam_models.dart';
import '../screens/devices/devices_sheet.dart';
import '../screens/jam/jam_screen.dart';
import '../screens/now_playing/now_playing_screen.dart';
import '../theme/cover_tint.dart';
import '../theme/tokens.dart';
import 'favorite_actions.dart';
import 'motion.dart';
import 'radio_now.dart';
import 'ring_progress.dart';
import '../../providers/radio_providers.dart' show onAirProvider;
import 'track_art.dart';

/// Shared-element tag of the cover between mini-player and Now Playing.
const kPlayerCoverHero = 'player-cover';

const _swipeDistance = 72.0;
const _swipeVelocity = 700.0;
const _flingDuration = Duration(milliseconds: 160);

/// The card above the bottom bar: tinted by the cover, swipe sideways to
/// change track, up or tap to open Now Playing. With a Jam active it shows
/// the Jam's track and controls.
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle =
      AnimationController(vsync: this, duration: _flingDuration)
        ..addListener(() {
          final a = _anim;
          if (a != null) setState(() => _dx = a.value);
        });
  Animation<double>? _anim;
  double _dx = 0;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  Future<void> _animateTo(double target) {
    _anim = Tween<double>(
      begin: _dx,
      end: target,
    ).animate(CurvedAnimation(parent: _settle, curve: Curves.easeOut));
    return _settle.forward(from: 0);
  }

  Future<void> _onDragEnd(
    DragEndDetails d,
    double width,
    PlayerController ctrl,
  ) async {
    final v = d.primaryVelocity ?? 0;
    final go = _dx.abs() > _swipeDistance || v.abs() > _swipeVelocity;
    final wantsNext = (_dx != 0 ? _dx : -v) < 0;
    // Past the last track the player would stop and the card disappear.
    if (!go || (wantsNext && !ctrl.hasNext)) {
      await _animateTo(0);
      return;
    }
    final dir = (_dx != 0 ? _dx : -v).sign;
    await _animateTo(dir * width);
    if (!mounted) return;
    dir < 0 ? ctrl.next() : ctrl.previous();
    setState(() => _dx = -dir * width * 0.4);
    await _animateTo(0);
  }

  void _openNowPlaying() => Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const NowPlayingScreen(),
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );

  void _openJam() => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: (_) => const JamScreen()));

  @override
  Widget build(BuildContext context) {
    final jam = ref.watch(jamProvider);
    final jamItem = jam.active ? jam.jam?.current : null;
    final track =
        ref.watch(liveCurrentTrackProvider).value ??
        ref.watch(currentTrackProvider).value;
    final inJam = jam.active;
    if (!inJam && track == null) return const SizedBox.shrink();

    final cc = context.cc;
    final l = context.l10n;
    final theme = Theme.of(context).textTheme;
    final ctrl = ref.read(playerControllerProvider);
    final width = MediaQuery.sizeOf(context).width;

    final radio = (!inJam && track != null) ? radioOfTrack(ref, track) : null;
    final onAir = radio == null ? null : ref.watch(onAirProvider).value;
    final String title;
    final String subtitle;
    final String? coverKey;
    final bool playing;
    if (inJam) {
      title = jamItem?.title ?? l.jamNothingPlaying;
      subtitle = l.jamPeople(jam.jam?.participants.length ?? 1);
      coverKey = null;
      playing = jam.jam?.playing ?? false;
    } else {
      final texts = radio == null ? null : radioTexts(l, radio, onAir);
      final t = track!;
      title = texts?.title ?? t.title;
      subtitle = texts?.subtitle ?? t.artist ?? l.unknownArtist;
      coverKey = t.coverKey;
      playing = ref.watch(isPlayingProvider).value ?? false;
    }
    final tint = inJam
        ? cc.surface1
        : (coverKey == null
              ? cc.surface1
              : resolvedHeroTint(context, ref, coverKey));
    final reduce = MediaQuery.disableAnimationsOf(context);

    final card = AnimatedContainer(
      duration: reduce ? Duration.zero : CcMotion.color,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(CcDims.rCard),
      ),
      clipBehavior: Clip.antiAlias,
      height: CcDims.miniPlayerHeight,
      child: Row(
        children: [
          const SizedBox(width: 8),
          if (inJam)
            RingProgress(
              size: 48,
              live: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cc.surface3,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.queue_music_rounded, color: cc.accent),
              ),
            )
          else
            RingProgress(
              size: 48,
              live: radio != null,
              child: TrackArt(
                track: track!,
                size: 38,
                radius: 19,
                heroTag: kPlayerCoverHero,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    if (inJam)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.circle, size: 8, color: cc.accent),
                      ),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _MiniButton(
            icon: Icons.devices_rounded,
            tooltip: l.devicesTitle,
            onPressed: () => DevicesSheet.show(context),
          ),
          if (radio != null)
            RadioStarButton(station: radio, compact: true, color: cc.textMuted)
          else if (!inJam && track != null)
            _MiniButton(
              icon: Icons.favorite_rounded,
              iconWidget: HeartIcon(favorite: track.isFavorite),
              color: track.isFavorite ? cc.accent : null,
              tooltip: track.isFavorite ? l.removeFromFavorites : l.favorite,
              onPressed: () => toggleFavorite(context, ref, track),
            ),
          _MiniButton(
            icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: cc.text,
            size: 28,
            tooltip: playing ? l.pause : l.play,
            onPressed: inJam
                ? () => ref
                      .read(jamProvider.notifier)
                      .send(
                        playing
                            ? const JamCommand.pause()
                            : const JamCommand.play(),
                      )
                : ctrl.togglePlayPause,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );

    return RiseIn(
      child: Padding(
        padding: const EdgeInsets.all(CcDims.miniPlayerMargin),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: inJam ? _openJam : _openNowPlaying,
          onHorizontalDragStart: inJam ? null : (_) => _settle.stop(),
          onHorizontalDragUpdate: inJam
              ? null
              : (d) => setState(() => _dx += d.delta.dx),
          onHorizontalDragEnd: inJam ? null : (d) => _onDragEnd(d, width, ctrl),
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < -300) {
              inJam ? _openJam() : _openNowPlaying();
            }
          },
          child: Transform.translate(offset: Offset(_dx, 0), child: card),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.size = 22,
    this.iconWidget,
  });

  final IconData icon;

  /// In place of [icon] (the heart that beats).
  final Widget? iconWidget;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: size,
    color: color ?? context.cc.textMuted,
    visualDensity: VisualDensity.compact,
    icon: iconWidget ?? Icon(icon),
  );
}
