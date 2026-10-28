import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/player_providers.dart';
import '../theme/tokens.dart';
import 'format_utils.dart';
import 'seek_bar.dart';
import 'smooth_position.dart';

/// Playback fraction 0..1, or null when the duration is unknown.
double? ringProgress(Duration position, Duration? duration) {
  if (duration == null || duration <= Duration.zero) return null;
  return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}

/// The cover inside an open ring (the app logo): the arc fills clockwise from
/// the gap and a dot marks the playhead. [live] (radio, Jam) paints it full.
/// With [seekable] (the full player) dragging on the ring seeks, and the ring
/// is a screen-reader slider.
///
/// [position], [duration] and [onSeek] default to the local player; the Jam
/// passes its own (a [SmoothPosition] fed from JamState). A [position] given
/// at first build must stay given.
class RingProgress extends ConsumerStatefulWidget {
  const RingProgress({
    super.key,
    required this.size,
    required this.child,
    this.live = false,
    this.stroke = 3,
    this.seekable = false,
    this.position,
    this.duration,
    this.onSeek,
  });

  final double size;
  final Widget child;
  final bool live;
  final double stroke;
  final bool seekable;
  final ValueListenable<Duration>? position;
  final Duration? duration;
  final ValueChanged<Duration>? onSeek;

  /// Side of the circle the cover is clipped to inside a ring of [size].
  static double innerSize(double size, {double stroke = 3}) =>
      size -
      2 *
          (stroke <= 3
              ? stroke + 2
              : RingPainter.dotRadius(stroke) + stroke / 2 + 4);

  @override
  ConsumerState<RingProgress> createState() => _RingProgressState();
}

class _RingProgressState extends ConsumerState<RingProgress> {
  /// The player's position when none is injected (never for [live]).
  SmoothPosition? _own;
  ValueListenable<Duration> get _pos => widget.position ?? _own!;

  // [live] can change while mounted (radio, Jam): made when first needed.
  void _ensureOwn() {
    if (widget.position != null || widget.live || _own != null) return;
    _own = SmoothPosition()..followPlayer(ref);
  }

  @override
  void initState() {
    super.initState();
    _ensureOwn();
  }

  @override
  void didUpdateWidget(RingProgress old) {
    super.didUpdateWidget(old);
    _ensureOwn();
    _own?.bindTickerMode(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _own?.bindTickerMode(context);
  }

  /// Fraction under the finger while dragging; the seek happens on release.
  double? _drag;
  bool _focused = false;

  // Same step for the keyboard and for screen readers.
  static const _step = Duration(seconds: 5);

  void _seekTo(Duration d) => widget.onSeek != null
      ? widget.onSeek!(d)
      : ref.read(playerControllerProvider).seek(d);

  Duration? _readDuration() =>
      widget.duration ?? ref.read(durationProvider).value;

  late final SeekDrag _dragNotifier = ref.read(seekDragProvider.notifier);

  @override
  void dispose() {
    // Closed mid-drag: the elapsed time must not stay on the finger.
    if (_drag != null) Future.microtask(() => _dragNotifier.set(null));
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final size = widget.size;
    final inner = RingProgress.innerSize(size, stroke: widget.stroke);
    // Own layer: position ticks re-record the ring only, not the cover.
    Widget paint({Duration? dur, double? fixed}) => RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: RingPainter(
          progress: fixed,
          position: fixed == null && !widget.live ? _pos : null,
          duration: dur,
          arc: cc.accent,
          rest: cc.surface3,
          stroke: widget.stroke,
        ),
      ),
    );
    final ring = widget.live
        ? paint()
        : Consumer(
            builder: (_, ref, _) {
              final dur = widget.duration ?? ref.watch(durationProvider).value;
              // The bar's drag counts too: both show the same fraction.
              final drag = _drag ?? ref.watch(seekDragProvider);
              final ringPaint = paint(dur: dur, fixed: drag);
              if (!widget.seekable || dur == null || dur <= Duration.zero) {
                return ringPaint;
              }
              Duration clamp(Duration d) =>
                  d < Duration.zero ? Duration.zero : (d > dur ? dur : d);
              // Only the semantics node rebuilds on a tick, not the painter.
              return ValueListenableBuilder<Duration>(
                valueListenable: _pos,
                child: ringPaint,
                builder: (_, pos, child) {
                  final shown = drag == null ? pos : dur * drag;
                  return Semantics(
                    slider: true,
                    label: context.l10n.seekPosition,
                    value:
                        '${formatDuration(shown.inMilliseconds)} / '
                        '${formatDuration(dur.inMilliseconds)}',
                    increasedValue: formatDuration(
                      clamp(shown + _step).inMilliseconds,
                    ),
                    decreasedValue: formatDuration(
                      clamp(shown - _step).inMilliseconds,
                    ),
                    onIncrease: () => _seekTo(clamp(shown + _step)),
                    onDecrease: () => _seekTo(clamp(shown - _step)),
                    child: child,
                  );
                },
              );
            },
          );
    Widget body = SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: ClipOval(
              child: SizedBox.square(dimension: inner, child: widget.child),
            ),
          ),
          // Above the cover so the playhead dot is not clipped by it; taps
          // still reach the cover.
          // ignore: deprecated_member_use
          IgnorePointer(ignoringSemantics: false, child: ring),
        ],
      ),
    );
    if (widget.seekable && !widget.live) {
      body = Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (_, e) {
          final step = switch (e.logicalKey) {
            LogicalKeyboardKey.arrowRight => _step,
            LogicalKeyboardKey.arrowLeft => -_step,
            _ => null,
          };
          if (step == null || e is KeyUpEvent) return KeyEventResult.ignored;
          final dur = _readDuration();
          if (dur == null || dur <= Duration.zero) {
            return KeyEventResult.ignored;
          }
          final to = _pos.value + step;
          _seekTo(to < Duration.zero ? Duration.zero : (to > dur ? dur : to));
          return KeyEventResult.handled;
        },
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                _focused &&
                    FocusManager.instance.highlightMode ==
                        FocusHighlightMode.traditional
                ? Border.all(color: cc.accent, width: 2)
                : null,
          ),
          child: _gestures(body),
        ),
      );
    }
    if (!widget.seekable || widget.live) {
      return ExcludeSemantics(child: RepaintBoundary(child: body));
    }
    // The seek band reaches 48 dp out from the cover edge, past the drawing.
    final pad = _band - (size - inner) / 2;
    return _WideHit(pad: pad, child: RepaintBoundary(child: body));
  }

  Widget _gestures(Widget body) {
    final size = widget.size;
    final inner = RingProgress.innerSize(size, stroke: widget.stroke);
    return RawGestureDetector(
      // The ring no longer takes hits itself (it sits above the cover).
      behavior: HitTestBehavior.opaque,
      gestures: {
        _RingSeekRecognizer:
            GestureRecognizerFactoryWithHandlers<_RingSeekRecognizer>(
              () => _RingSeekRecognizer(size, inner),
              (r) {
                r
                  ..size = size
                  ..inner = inner
                  ..onFraction = (f) {
                    setState(() => _drag = f);
                    _dragNotifier.set(f);
                  }
                  ..onEnd = (commit) {
                    final f = _drag;
                    setState(() => _drag = null);
                    _dragNotifier.set(null);
                    final dur = _readDuration();
                    if (commit && f != null && dur != null) {
                      _seekTo(dur * f);
                    }
                  };
              },
            ),
      },
      child: body,
    );
  }
}

/// Width of the seek band, measured outwards from the cover edge.
const _band = 48.0;

/// Wins the arena at once for a touch on the ring band (from the cover edge,
/// 48 dp wide) so the cover's swipe and the sheet drag do not take it;
/// touches elsewhere, the cover included, are ignored.
class _RingSeekRecognizer extends OneSequenceGestureRecognizer {
  _RingSeekRecognizer(this.size, this.inner);

  double size, inner;
  void Function(double fraction)? onFraction;
  void Function(bool commit)? onEnd;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final c = Offset(size / 2, size / 2);
    final d = (event.localPosition - c).distance - inner / 2;
    if (d < 0 || d > _band) return;
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onFraction?.call(RingPainter.fractionAt(event.localPosition - c));
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onFraction?.call(
        RingPainter.fractionAt(
          event.localPosition - Offset(size / 2, size / 2),
        ),
      );
    } else if (event is PointerUpEvent) {
      onEnd?.call(true);
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      onEnd?.call(false);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'ring seek';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}

/// Hit-tests [pad] dp past its own bounds (the position is clamped onto them
/// for the child), so a touch just outside the drawing still reaches it.
class _WideHit extends SingleChildRenderObjectWidget {
  const _WideHit({required this.pad, super.child});

  final double pad;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderWideHit(pad);

  @override
  void updateRenderObject(BuildContext context, _RenderWideHit r) =>
      r.pad = pad;
}

class _RenderWideHit extends RenderProxyBox {
  _RenderWideHit(this.pad);

  double pad;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!(Offset.zero & size).inflate(pad).contains(position)) return false;
    return super.hitTest(
      result,
      position: Offset(
        position.dx.clamp(0.0, size.width - 0.01),
        position.dy.clamp(0.0, size.height - 0.01),
      ),
    );
  }
}

/// Open ring with the gap at top right. [progress] null paints the whole arc
/// in [arc] with no dot.
class RingPainter extends CustomPainter {
  const RingPainter({
    required this.progress,
    required this.arc,
    required this.rest,
    required this.stroke,
    this.position,
    this.duration,
  }) : super(repaint: position);

  /// Fixed fraction (null: whole arc, no dot) unless [position] is given.
  final double? progress;

  /// When set, the painter follows it by itself (`repaint:`): its ticks
  /// repaint the ring without rebuilding anything.
  final ValueListenable<Duration>? position;
  final Duration? duration;
  final Color arc, rest;
  final double stroke;
  double? get _progress =>
      position == null ? progress : ringProgress(position!.value, duration);

  static const _gap = 40 * math.pi / 180;
  static const _sweep = 2 * math.pi - _gap;
  static const _start = -math.pi / 4 + _gap / 2;

  /// Playhead dot radius: 1.1 x stroke, capped for the thick player ring.
  static double dotRadius(double stroke) =>
      math.min(stroke * 1.1, stroke / 2 + 5);

  /// Playback fraction for a point [d] from the ring centre; the gap snaps to
  /// the nearer end.
  static double fractionAt(Offset d) {
    final a = (math.atan2(d.dy, d.dx) - _start) % (2 * math.pi);
    if (a <= _sweep) return a / _sweep;
    return a - _sweep < _gap / 2 ? 1.0 : 0.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dotR = dotRadius(stroke);
    final r = size.shortestSide / 2 - dotR;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, line..color = rest);
    final p = _progress;
    final played = _sweep * (p ?? 1);
    if (played > 0) {
      canvas.drawArc(rect, _start, played, false, line..color = arc);
    }
    if (p == null) return;
    final a = _start + played;
    canvas.drawCircle(
      c + Offset(math.cos(a), math.sin(a)) * r,
      dotR,
      Paint()..color = arc,
    );
  }

  @override
  bool shouldRepaint(RingPainter o) =>
      o.progress != progress ||
      o.position != position ||
      o.duration != duration ||
      o.arc != arc ||
      o.rest != rest ||
      o.stroke != stroke;
}

/// The still accent dot of the track that is playing or paused.
class NowPlayingDot extends StatelessWidget {
  const NowPlayingDot({super.key, this.size = 8});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.nowPlaying,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.cc.accent,
        shape: BoxShape.circle,
      ),
    ),
  );
}
