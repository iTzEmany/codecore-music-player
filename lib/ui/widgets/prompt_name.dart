import 'package:flutter/material.dart';

import '../../l10n/l10n_ext.dart';

/// Asks for a name. The result is trimmed and never empty: a blank name keeps
/// the dialog open (button and keyboard alike). Null when cancelled.
Future<String?> promptName(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
  String? hint,
  int maxLength = 60,
}) => showDialog<String>(
  context: context,
  builder: (_) => _NameDialog(
    title: title,
    confirmLabel: confirmLabel,
    initial: initial,
    hint: hint,
    maxLength: maxLength,
  ),
);

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initial,
    required this.hint,
    required this.maxLength,
  });

  final String title, confirmLabel, initial;
  final String? hint;
  final int maxLength;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _c.text.trim();
    if (t.isNotEmpty) Navigator.of(context).pop(t);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _c,
      autofocus: true,
      maxLength: widget.maxLength,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
    ],
  );
}
