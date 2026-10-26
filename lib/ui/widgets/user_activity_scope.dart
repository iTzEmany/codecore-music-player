import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_activity_provider.dart';

/// Any scroll counts as the user being active (read by the enrichment). Sits
/// above the Navigator, so also the sheets and routes over the shell count.
class UserActivityScope extends ConsumerWidget {
  const UserActivityScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, not read: its busy listener only runs while it has a listener;
    // the value never changes, so nothing rebuilds.
    final activity = ref.watch(userActivityProvider);
    return Listener(
      // Mouse wheel and trackpad (desktop) scroll without a drag.
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) activity.touch();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // Only the user's own drag, not programmatic scrolls.
          if (n is ScrollUpdateNotification && n.dragDetails != null) {
            activity.touch();
          }
          return false;
        },
        child: child,
      ),
    );
  }
}
