import 'package:codecore/ui/widgets/cc_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Name of one entry: enum name, a `name` getter-less value as text, or the label.
String menuEntryName(Object? v, String? label) {
  if (v is Enum) return v.name;
  if (v != null) return v is String ? v : '$v';
  return label ?? '';
}

/// The entries of the menu now open, in order, whether it is a PopupMenu or an
/// action sheet ([showCcActionSheet]). [named] maps a value to its name
/// (e.g. `TrackAction` -> label); by default enums give `name`.
List<String> shownMenuEntries(
  WidgetTester tester, {
  String Function(Object value)? named,
}) {
  String name(Object v) => named?.call(v) ?? menuEntryName(v, null);
  final popup = tester.widgetList<PopupMenuItem>(
    find.byWidgetPredicate((w) => w is PopupMenuItem),
  );
  if (popup.isNotEmpty) {
    return [
      for (final i in popup)
        i.value != null ? name(i.value as Object) : (i.child as Text).data!,
    ];
  }
  final sheet = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byWidgetPredicate(
      (w) => w is ListTile && w.key is ValueKey<Object>,
    ),
  );
  return [
    for (final t in tester.widgetList<ListTile>(sheet))
      name((t.key! as ValueKey<Object>).value),
  ];
}

/// The ⋮ button that opens a menu: a PopupMenuButton now, an IconButton with
/// a more_vert / more_horiz glyph once the menus are sheets.
Finder menuButton() => find.byWidgetPredicate(
  (w) =>
      w is PopupMenuButton ||
      (w is IconButton &&
          w.icon is Icon &&
          ((w.icon as Icon).icon == Icons.more_vert ||
              (w.icon as Icon).icon == Icons.more_horiz)),
);
