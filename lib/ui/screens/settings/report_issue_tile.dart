import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import 'report_issue_screen.dart';

/// Settings → Info: opens «Segnala un problema».
class ReportIssueTile extends StatelessWidget {
  const ReportIssueTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListTile(
      leading: const Icon(Icons.flag_outlined),
      title: Text(l.reportIssue),
      subtitle: Text(l.reportIssueHint),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ReportIssueScreen()),
      ),
    );
  }
}
