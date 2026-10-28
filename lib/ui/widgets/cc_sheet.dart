import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n_ext.dart';
import '../theme/tokens.dart';

/// Every bottom sheet opens through here: 250 ms, none with «Riduci animazioni».
Future<T?> showCcSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool? showDragHandle,
  bool useRootNavigator = false,
  BoxConstraints? constraints,
  String? barrierLabel,
}) {
  final d = ccDuration(context, CcMotion.sheet);
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    useRootNavigator: useRootNavigator,
    constraints: constraints,
    barrierLabel: barrierLabel,
    sheetAnimationStyle: AnimationStyle(duration: d, reverseDuration: d),
  );
}

/// One row of an action sheet. Closing returns [value]; [onTap] runs after the sheet is gone.
class CcAction<T> {
  const CcAction({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final T? value;
  final VoidCallback? onTap;

  /// Marks the current choice (sort orders): shows a check at the end.
  final bool selected;

  /// Drawn in `cc.error` and moved to the end of the sheet.
  final bool destructive;
}

/// Action sheet: optional [header] (or [title]/[subtitle]), [groups] of 59 dp rows
/// separated by dividers, destructive rows always last. Returns the chosen value.
Future<T?> showCcActionSheet<T>({
  required BuildContext context,
  required List<List<CcAction<T>>> groups,
  Widget? header,
  String? title,
  String? subtitle,
  bool useRootNavigator = false,
}) {
  final normal = [
    for (final g in groups)
      [for (final a in g) if (!a.destructive) a],
  ].where((g) => g.isNotEmpty).toList();
  final destructive = [
    for (final g in groups) for (final a in g) if (a.destructive) a,
  ];
  final all = [...normal, if (destructive.isNotEmpty) destructive];
  final head =
      header ??
      (title == null
          ? null
          : ListTile(
              title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: subtitle == null ? null : Text(subtitle),
            ));
  return showCcSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: useRootNavigator,
    barrierLabel: context.l10n.close,
    builder: (sheet) {
      final cc = sheet.cc;
      var first = true;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * 0.85,
        ),
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: title,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  Navigator.of(sheet).maybePop(),
            },
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (head != null) Semantics(header: true, child: head),
                    for (var i = 0; i < all.length; i++) ...[
                      if (i > 0 || head != null) const Divider(height: 1),
                      for (final a in all[i])
                        SizedBox(
                          height: 59,
                          child: ListTile(
                            key: ValueKey<Object>(a.value ?? a.label),
                            autofocus: first && !(first = false),
                            leading: Icon(
                              a.icon,
                              color: a.destructive ? cc.error : null,
                            ),
                            title: Text(
                              a.label,
                              style: a.destructive
                                  ? TextStyle(color: cc.error)
                                  : null,
                            ),
                            trailing: a.selected
                                ? Icon(Icons.check_rounded, color: cc.accent)
                                : null,
                            selected: a.selected,
                            onTap: () {
                              Navigator.of(sheet).pop(a.value);
                              a.onTap?.call();
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
