import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_state.dart';

/// Loading / empty / error / data for an [AsyncValue]. Error: «Riprova» when
/// [onRetry] is given; the exception goes to `AppLog` (via `LoadError`, once).
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.data,
    this.isEmpty,
    this.empty,
    this.onRetry,
    this.loading,
    this.errorMessage,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// With [empty]: when true on the loaded data, [empty] is shown instead.
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;

  /// Replaces the centred spinner (e.g. a thin linear bar).
  final Widget? loading;

  /// Replaces the default `loadFailed` text.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => loading ?? const Center(child: CircularProgressIndicator()),
    error: (e, st) => LoadError(e, st, onRetry: onRetry, message: errorMessage),
    data: (d) =>
        empty != null && (isEmpty?.call(d) ?? false) ? empty! : data(d),
  );
}

/// [AsyncBody] for a sliver list: the error is a fixed-height box, the
/// loading and data slivers are the caller's (so a list keeps its element
/// across loading and data).
class SliverAsyncBody<T> extends StatelessWidget {
  const SliverAsyncBody({
    super.key,
    required this.value,
    required this.data,
    required this.loading,
    this.onRetry,
    this.errorHeight = 240,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget loading;
  final VoidCallback? onRetry;
  final double errorHeight;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => loading,
    error: (e, st) => SliverToBoxAdapter(
      child: SizedBox(
        height: errorHeight,
        child: LoadError(e, st, onRetry: onRetry),
      ),
    ),
    data: data,
  );
}
