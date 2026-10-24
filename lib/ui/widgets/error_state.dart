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
        padding: const EdgeInsets.fromLTRB(
          CcDims.margin,
          CcDims.gap24,
          CcDims.margin,
          0,
        ),
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

/// [ErrorState] that logs its exception once, when it first appears (not on
/// every rebuild, so it is safe to build from `build`).
class LoadError extends StatefulWidget {
  const LoadError(
    this.error,
    this.stack, {
    super.key,
    this.onRetry,
    this.message,
  });

  final Object error;
  final StackTrace stack;
  final VoidCallback? onRetry;
  final String? message;

  @override
  State<LoadError> createState() => _LoadErrorState();
}

class _LoadErrorState extends State<LoadError> {
  @override
  void initState() {
    super.initState();
    AppLog.e('load failed', widget.error, widget.stack);
  }

  @override
  void didUpdateWidget(LoadError old) {
    super.didUpdateWidget(old);
    if (widget.error != old.error) {
      AppLog.e('load failed', widget.error, widget.stack);
    }
  }

  @override
  Widget build(BuildContext context) => ErrorState(
    message: widget.message ?? context.l10n.loadFailed,
    onRetry: widget.onRetry,
  );
}
