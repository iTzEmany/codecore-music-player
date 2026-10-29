import 'package:flutter/material.dart';

import '../../l10n/l10n_ext.dart';
import '../theme/tokens.dart';

/// The one snackbar: replaces the current one and the queue, fixed duration.
/// [persist] keeps an action snackbar until dismissed. Safe after an `await` (does nothing if [context] is gone).
void showMsg(BuildContext context, String text, {SnackBarAction? action, bool persist = false}) {
  if (!context.mounted) return;
  showMsgOn(ScaffoldMessenger.of(context), text, action: action, persist: persist);
}

/// The confirmation of a queue add. [added] is what a Jam took of [wanted] (null: no Jam,
/// all went in); a full Jam says so instead of confirming (D-194).
void showQueued(BuildContext context, int? added, {int wanted = 1, String? ok}) {
  if (!context.mounted) return;
  final l = context.l10n;
  showMsg(
    context,
    added == null || added >= wanted
        ? ok ?? l.addedToQueue
        : added == 0
            ? l.jamFull
            : l.jamAdded(added),
  );
}

/// Same as [showMsg] with a messenger captured earlier: for messages shown
/// after the dialog or sheet that owned the context has closed.
void showMsgOn(
  ScaffoldMessengerState messenger,
  String text, {
  SnackBarAction? action,
  bool persist = false,
}) {
  messenger.clearSnackBars();
  messenger.showSnackBar(SnackBar(
    content: Text(text),
    action: action,
    // Explicit persist: an action alone must not keep it on screen forever.
    persist: persist && action != null,
    duration: action == null ? CcTiming.msg : CcTiming.msgAction,
  ));
}
