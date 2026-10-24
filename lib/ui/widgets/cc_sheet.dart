import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Every bottom sheet opens through here: 250 ms, none with «Riduci animazioni».
Future<T?> showCcSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool? showDragHandle,
  bool useRootNavigator = false,
  BoxConstraints? constraints,
}) {
  final d = ccDuration(context, CcMotion.sheet);
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    useRootNavigator: useRootNavigator,
    constraints: constraints,
    sheetAnimationStyle: AnimationStyle(duration: d, reverseDuration: d),
  );
}
