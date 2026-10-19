import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Texts shown by [CcColorPicker]; supplied by the caller (localised).
class CcColorPickerLabels {
  const CcColorPickerLabels({
    required this.hue,
    required this.saturationValue,
    required this.alpha,
    required this.hex,
    required this.invalidHex,
    required this.recent,
  });

  final String hue, saturationValue, alpha, hex, invalidHex, recent;
}

/// '#RRGGBB' (upper case), or '#AARRGGBB' when [withAlpha] is true.
String colorToHex(Color c, {bool withAlpha = false}) {
  final v = c.toARGB32();
  final rgb = (v & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  final a = ((v >> 24) & 0xFF).toRadixString(16).padLeft(2, '0');
  return '#${withAlpha ? a : ''}$rgb'.toUpperCase();
}

final _hexRe = RegExp(r'^[0-9a-fA-F]+$');

/// Accepts '#RGB', '#RRGGBB', '#AARRGGBB' (the '#' is optional, any case,
/// surrounding spaces ignored). Returns null when invalid.
Color? parseHexColor(String input) {
  var s = input.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (!_hexRe.hasMatch(s)) return null;
  switch (s.length) {
    case 3:
      s = s.split('').map((c) => '$c$c').join();
      return Color(int.parse('FF$s', radix: 16));
    case 6:
      return Color(int.parse('FF$s', radix: 16));
    case 8:
      return Color(int.parse(s, radix: 16));
  }
  return null;
}

/// HSV colour picker: saturation/value square, hue slider, optional alpha
/// slider, hex field and a row of recent colours.
class CcColorPicker extends StatefulWidget {
  const CcColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
    required this.labels,
    this.allowAlpha = false,
    this.recent = const [],
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final CcColorPickerLabels labels;
  final bool allowAlpha;
  final List<Color> recent;

  @override
  State<CcColorPicker> createState() => _CcColorPickerState();
}

class _CcColorPickerState extends State<CcColorPicker> {
  static const _maxSquareHeight = 220.0;

  late double _h, _s, _v, _a;
  late final TextEditingController _hexCtrl;
  final _hexFocus = FocusNode();
  final _squareFocus = FocusNode();
  bool _hexInvalid = false;

  @override
  void initState() {
    super.initState();
    _h = 0;
    _loadFrom(widget.color);
    _hexCtrl = TextEditingController(text: _hexText());
    _hexFocus.addListener(_onHexFocus);
    _squareFocus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(CcColorPicker old) {
    super.didUpdateWidget(old);
    if (widget.color.toARGB32() != _current.toARGB32() ||
        old.allowAlpha != widget.allowAlpha) {
      _loadFrom(widget.color);
      _syncText();
    }
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    _hexFocus.dispose();
    _squareFocus.dispose();
    super.dispose();
  }

  void _onHexFocus() {
    if (!_hexFocus.hasFocus) {
      // Leaving the field: show the real colour again.
      _hexInvalid = false;
      _syncText();
    }
  }

  /// Loads [c] keeping the previous hue when [c] is a grey (no hue).
  void _loadFrom(Color c) {
    final hsv = HSVColor.fromColor(c);
    if (hsv.saturation > 0 && hsv.value > 0) _h = hsv.hue;
    _s = hsv.saturation;
    _v = hsv.value;
    _a = widget.allowAlpha ? hsv.alpha : 1.0;
  }

  Color get _current =>
      HSVColor.fromAHSV(widget.allowAlpha ? _a : 1.0, _h, _s, _v).toColor();

  String _hexText() =>
      colorToHex(_current, withAlpha: widget.allowAlpha && _a < 1);

  void _syncText() {
    if (_hexFocus.hasFocus) return;
    final t = _hexText();
    if (_hexCtrl.text != t) _hexCtrl.text = t;
    if (mounted) setState(() {});
  }

  void _changed() {
    setState(() {});
    _syncText();
    widget.onChanged(_current);
  }

  void _setSV(double s, double v) {
    _s = s.clamp(0.0, 1.0);
    _v = v.clamp(0.0, 1.0);
    _changed();
  }

  void _onSquare(Offset p, Size size) {
    _setSV(p.dx / size.width, 1 - p.dy / size.height);
  }

  KeyEventResult _onSquareKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 0.1 : 0.01;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft) {
      _setSV(_s - step, _v);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _setSV(_s + step, _v);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _setSV(_s, _v + step);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      _setSV(_s, _v - step);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _onHexTyped(String text) {
    final c = parseHexColor(text);
    if (c == null) {
      setState(() => _hexInvalid = true);
      return;
    }
    _hexInvalid = false;
    _loadFrom(c);
    setState(() {});
    widget.onChanged(_current);
  }

  void _pickRecent(Color c) {
    _loadFrom(c);
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final l = widget.labels;
    final pct = '${(_s * 100).round()}%, ${(_v * 100).round()}%';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final size = Size(w, (w * 3 / 4).clamp(0.0, _maxSquareHeight));
            return Semantics(
              label: l.saturationValue,
              value: pct,
              focusable: true,
              child: Focus(
                focusNode: _squareFocus,
                onKeyEvent: _onSquareKey,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) {
                    _squareFocus.requestFocus();
                    _onSquare(d.localPosition, size);
                  },
                  onPanDown: (d) => _onSquare(d.localPosition, size),
                  onPanUpdate: (d) => _onSquare(d.localPosition, size),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CcDims.rGrid),
                    child: CustomPaint(
                      size: size,
                      painter: _SvPainter(
                        hue: _h,
                        s: _s,
                        v: _v,
                        outline: cc.text,
                        shadow: cc.bg,
                        focused: _squareFocus.hasFocus,
                        focusColor: cc.accent,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Semantics(
          label: l.hue,
          child: Slider(
            min: 0,
            max: 360,
            value: _h.clamp(0.0, 360.0),
            onChanged: (x) {
              _h = x;
              _changed();
            },
          ),
        ),
        if (widget.allowAlpha)
          Semantics(
            label: l.alpha,
            child: Slider(
              min: 0,
              max: 1,
              value: _a.clamp(0.0, 1.0),
              onChanged: (x) {
                _a = x;
                _changed();
              },
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: l.hex,
                child: TextField(
                  controller: _hexCtrl,
                  focusNode: _hexFocus,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: _onHexTyped,
                  decoration: InputDecoration(
                    labelText: l.hex,
                    errorText: _hexInvalid ? l.invalidHex : null,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _current,
                borderRadius: BorderRadius.circular(CcDims.rGrid),
                border: Border.all(color: cc.surface3),
              ),
            ),
          ],
        ),
        if (widget.recent.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l.recent, style: TextStyle(color: cc.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in widget.recent)
                Semantics(
                  button: true,
                  label: colorToHex(c, withAlpha: widget.allowAlpha),
                  child: InkResponse(
                    key: ValueKey('recent-${c.toARGB32()}'),
                    onTap: () => _pickRecent(c),
                    radius: 20,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: cc.surface3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SvPainter extends CustomPainter {
  _SvPainter({
    required this.hue,
    required this.s,
    required this.v,
    required this.outline,
    required this.shadow,
    required this.focused,
    required this.focusColor,
  });

  final double hue, s, v;
  final Color outline, shadow, focusColor;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pure = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    // White at the left fading to the hue colour at the right.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(colors: [const Color(0xFFFFFFFF), pure])
            .createShader(rect),
    );
    // Transparent at the top fading to black at the bottom.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xFF000000)],
        ).createShader(rect),
    );
    final c = Offset(s * size.width, (1 - v) * size.height);
    final picked = HSVColor.fromAHSV(1, hue, s, v).toColor();
    canvas.drawCircle(c, 11, Paint()..color = shadow.withValues(alpha: 0.5));
    canvas.drawCircle(c, 9, Paint()..color = picked);
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 3 : 2
        ..color = focused ? focusColor : outline,
    );
  }

  @override
  bool shouldRepaint(_SvPainter o) =>
      o.hue != hue ||
      o.s != s ||
      o.v != v ||
      o.focused != focused ||
      o.outline != outline;
}
