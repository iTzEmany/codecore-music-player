import 'package:flutter/material.dart';

import '../../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import 'show_msg.dart';

/// Asks before a destructive or hard-to-undo action. Resolves to false when
/// dismissed.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final cc = context.cc;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: cc.error,
                  foregroundColor: cc.bg,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// One snackbar with an «Annulla» action (3 s; a snackbar with an action
/// would otherwise never time out).
void showUndoSnack(BuildContext context, String text, VoidCallback onUndo) =>
    showMsg(
      context,
      text,
      action: SnackBarAction(label: context.l10n.undo, onPressed: onUndo),
    );
