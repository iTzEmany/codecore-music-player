import 'package:codecore/providers/user_activity_provider.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:codecore/ui/widgets/user_activity_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _list() => ListView(children: [for (var i = 0; i < 40; i++) Text('riga $i')]);

/// The scope sits in `MaterialApp.builder`, above the Navigator, as in app.dart.
Future<UserActivity> _pump(WidgetTester t, Widget home) async {
  final activity = UserActivity();
  await t.pumpWidget(
    ProviderScope(
      overrides: [userActivityProvider.overrideWithValue(activity)],
      child: MaterialApp(
        builder: (_, child) => UserActivityScope(child: child!),
        home: home,
      ),
    ),
  );
  return activity;
}

void main() {
  testWidgets('dragging a list touches the user activity', (t) async {
    final activity = await _pump(t, Scaffold(body: _list()));
    expect(activity.lastActivityAt, isNull);
    await t.drag(find.byType(Scrollable), const Offset(0, -100));
    await t.pump();
    expect(activity.lastActivityAt, isNotNull);
  });

  testWidgets('a mouse wheel scroll touches the user activity', (t) async {
    final activity = await _pump(t, Scaffold(body: _list()));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await t.sendEventToBinding(pointer.hover(t.getCenter(find.byType(ListView))));
    await t.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    expect(activity.lastActivityAt, isNotNull);
  });

  testWidgets('a scroll inside a bottom sheet over the page touches it too', (t) async {
    late BuildContext ctx;
    final activity = await _pump(
      t,
      Builder(builder: (c) => Scaffold(body: Text('${(ctx = c).hashCode}'))),
    );
    showModalBottomSheet<void>(context: ctx, builder: (_) => _list());
    await t.pumpAndSettle();
    expect(activity.lastActivityAt, isNull);
    await t.drag(find.byType(Scrollable).last, const Offset(0, -100));
    await t.pump();
    expect(activity.lastActivityAt, isNotNull);
  });
}
