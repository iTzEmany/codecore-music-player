import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Desktop-wide keyboard shortcuts that keep working wherever focus is.
///
/// Two things plain `CallbackShortcuts` gets wrong here:
/// - it marks a key handled even when the callback ignores it, so Space could
///   not be typed into a text field;
/// - when the focused widget disappears (tab switched, route popped) focus
///   falls back to a route or root scope, above this widget, and every shortcut dies
///   until the user clicks into something. [_ShellKeysState] takes it back.
class ShellKeys extends StatefulWidget {
  const ShellKeys({
    super.key,
    required this.bindings,
    required this.child,
    this.textOnly = const {},
  });

  final Map<ShortcutActivator, VoidCallback> bindings;

  /// Keys that must never fire while a text field has focus (they are text).
  final Set<ShortcutActivator> textOnly;
  final Widget child;

  @override
  State<ShellKeys> createState() => _ShellKeysState();
}

class _ShellKeysState extends State<ShellKeys> {
  final _node = FocusNode(debugLabel: 'ShellKeys');

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_reclaimFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_reclaimFocus);
    _node.dispose();
    super.dispose();
  }

  void _reclaimFocus() {
    if (!_lostFocus()) return;
    // Not inside the notification: requesting focus there would re-enter it.
    scheduleMicrotask(() {
      if (!mounted || _node.hasPrimaryFocus) return;
      if (!_lostFocus()) return;
      if (ModalRoute.of(context)?.isCurrent ?? true) _node.requestFocus();
    });
  }

  /// Focus sits on a scope itself (the route's, or the root): nothing below it
  /// is focused, so key events never reach [_node].
  /// Not the scope of a sheet or dialog: focus there is on purpose, and taking
  /// it would stop Esc from reaching the sheet.
  static bool _lostFocus() {
    final f = FocusManager.instance.primaryFocus;
    if (f is! FocusScopeNode) return false;
    final ctx = f.context;
    return ctx == null || ModalRoute.of(ctx) is! PopupRoute;
  }

  static bool _typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    final typing = _typing();
    for (final e in widget.bindings.entries) {
      if (!e.key.accepts(event, keyboard)) continue;
      if (typing && widget.textOnly.contains(e.key)) {
        return KeyEventResult.ignored;
      }
      e.value();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _node,
    autofocus: true,
    onKeyEvent: _onKey,
    child: widget.child,
  );
}
