import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/folder_actions.dart';

/// Scan failure banner and progress bar, shared by every library page.
class ScanStatus extends ConsumerWidget {
  const ScanStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanStateProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (scan.error != null && !scan.running)
          MaterialBanner(
            content: Text(context.l10n.scanFailed(scan.error!)),
            actions: [
              TextButton(
                onPressed: () => scanWithPermission(ref),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
      ],
    );
  }
}
