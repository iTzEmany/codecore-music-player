import 'package:flutter/material.dart';

/// The small movements of phase 28.9. Only opacity and transforms (nothing
/// that changes a size or a layout), 120–220 ms with an easing out, what moves
/// on its own layer (`RepaintBoundary`), and nothing at all with «Riduci
/// animazioni».
abstract final class Motion {
  static const press = Duration(milliseconds: 120);
  static const enter = Duration(milliseconds: 180);
  static const tab = Duration(milliseconds: 160);
  static const pulse = Duration(milliseconds: 220);
  static const dot = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;

  /// Rows that come in one after the other when a list appears.
  static const staggered = 12;
  static const stagger = Duration(milliseconds: 20);
}

/// Shrinks a little (0.97) while pressed: the touch is felt before the next
/// page opens. It only listens, so taps and long presses still reach [child].
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: Motion.press,
        curve: Motion.curve,
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

/// Marks when a list appeared: its first rows come in one after the other
/// ([EnterOnce]) only in the moment after that, never while scrolling later.
class EntranceScope extends StatefulWidget {
  const EntranceScope({super.key, required this.child});

  final Widget child;

  static DateTime? _since(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EntranceClock>()?.since;

  @override
  State<EntranceScope> createState() => _EntranceScopeState();
}

class _EntranceScopeState extends State<EntranceScope> {
  final _since = DateTime.now();

  @override
  Widget build(BuildContext context) => _EntranceClock(since: _since, child: widget.child);
}

class _EntranceClock extends InheritedWidget {
  const _EntranceClock({required this.since, required super.child});

  final DateTime since;

  @override
  bool updateShouldNotify(_EntranceClock old) => old.since != since;
}

/// Row [index] of a list that just appeared: it fades in and rises by 8 px,
/// [Motion.stagger] after the one above. Only the first [Motion.staggered]
/// rows, only inside an [EntranceScope], and only while the list is new.
class EnterOnce extends StatefulWidget {
  const EnterOnce({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  /// Whether row [index] of a list shown since [since] still comes in at [now].
  @visibleForTesting
  static bool shouldEnter(int index, DateTime? since, DateTime now) {
    if (since == null || index >= Motion.staggered) return false;
    final window = Motion.stagger * Motion.staggered + Motion.enter;
    return now.difference(since) < window;
  }

  @override
  State<EnterOnce> createState() => _EnterOnceState();
}

class _EnterOnceState extends State<EnterOnce> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  Animation<double>? _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    final since = EntranceScope._since(context);
    if (MediaQuery.disableAnimationsOf(context) ||
        !EnterOnce.shouldEnter(widget.index, since, DateTime.now())) {
      return;
    }
    // One controller covers the wait and the movement: no extra timer.
    final delay = Motion.stagger * widget.index;
    final total = delay + Motion.enter;
    final c = _c = AnimationController(vsync: this, duration: total);
    _t = CurvedAnimation(
      parent: c,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: Motion.curve),
    );
    c.forward();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (t == null) return widget.child;
    return FadeTransition(
      opacity: t,
      child: AnimatedBuilder(
        animation: t,
        builder: (_, child) => Transform.translate(offset: Offset(0, 8 * (1 - t.value)), child: child),
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

/// Fades the body in when the tab changes; the pages underneath keep their
/// state (the same element stays, only its opacity moves).
class TabFade extends StatefulWidget {
  const TabFade({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<TabFade> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Motion.tab, value: 1);
  late final _opacity = CurvedAnimation(parent: _c, curve: Motion.curve);

  @override
  void didUpdateWidget(TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: RepaintBoundary(child: widget.child),
      );
}

/// The heart of a favourite: it beats once (up to 1.25 and back) when the
/// song becomes a favourite.
class HeartIcon extends StatefulWidget {
  const HeartIcon({super.key, required this.favorite, this.size, this.color});

  final bool favorite;
  final double? size;
  final Color? color;

  @override
  State<HeartIcon> createState() => _HeartIconState();
}

class _HeartIconState extends State<HeartIcon> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Motion.pulse);
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.25).chain(CurveTween(curve: Curves.easeOut)), weight: 45),
    TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1).chain(CurveTween(curve: Curves.easeIn)), weight: 55),
  ]).animate(_c);

  @override
  void didUpdateWidget(HeartIcon old) {
    super.didUpdateWidget(old);
    if (!old.favorite && widget.favorite && !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: Icon(
          widget.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: widget.size,
          color: widget.color,
        ),
      );
}

/// What appears in place of nothing (a selection number, the mini-player):
/// it grows from 0.6 and fades in.
Widget popIn(Widget child, Animation<double> a) => FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween<double>(begin: 0.6, end: 1).animate(a), child: child),
    );

/// Comes in once, rising 16 px and fading in, the first time it is built (the
/// mini-player when the first song starts); later rebuilds do not move it.
class RiseIn extends StatefulWidget {
  const RiseIn({super.key, required this.child});

  final Widget child;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Motion.enter);
  late final _t = CurvedAnimation(parent: _c, curve: Motion.curve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _t,
        child: AnimatedBuilder(
          animation: _t,
          builder: (_, child) => Transform.translate(offset: Offset(0, 16 * (1 - _t.value)), child: child),
          child: RepaintBoundary(child: widget.child),
        ),
      );
}
