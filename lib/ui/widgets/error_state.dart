import 'package:flutter/material.dart';

import '../../core/app_log.dart';
import '../../l10n/l10n_ext.dart';
import '../theme/tokens.dart';

/// Friendly failure view. The exception itself goes to `AppLog`, never here.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(CcDims.margin, CcDims.gap24, CcDims.margin, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: Theme.of(context).textTheme.titleSmall),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

/// For `AsyncValue.when(error:)`: logs the exception, shows a plain message.
Widget loadErrorState(
  BuildContext context,
  Object error,
  StackTrace stack, {
  VoidCallback? onRetry,
}) {
  AppLog.e('load failed', error, stack);
  return ErrorState(message: context.l10n.loadFailed, onRetry: onRetry);
}
