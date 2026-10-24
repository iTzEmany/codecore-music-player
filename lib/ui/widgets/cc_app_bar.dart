import 'package:flutter/material.dart';

/// The one app bar. Title style, colours and elevation come from the theme.
class CcAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CcAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.titleSpacing,
  });

  /// Plain text title; use [titleWidget] for anything else.
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double? titleSpacing;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) => AppBar(
    title: titleWidget ?? (title == null ? null : Text(title!)),
    actions: actions,
    bottom: bottom,
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    backgroundColor: backgroundColor,
    titleSpacing: titleSpacing,
  );
}
