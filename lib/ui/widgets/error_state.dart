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
    final cc = context.cc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cc.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
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
