import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The one snackbar: replaces the current one and the queue, fixed duration.
/// Safe after an `await` (does nothing if [context] is gone).
void showMsg(BuildContext context, String text, {SnackBarAction? action}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: action,
        // persist: false, or an action keeps it on screen forever.
        persist: false,
        duration: action == null ? CcTiming.msg : CcTiming.msgAction,
      ),
    );
}
