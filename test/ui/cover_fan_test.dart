import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/ui/screens/home/cover_fan.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fan card without a cover shows the album title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildThemeFromColors(CcColors.notte, false),
          home: const Scaffold(
            body: CoverFan(
              albums: [
                AlbumSummary(
                  albumKey: 'k',
                  title: 'Titolo senza copertina',
                  artist: 'A',
                  variousArtists: false,
                  trackCount: 1,
                  durationMs: 1000,
                  year: null,
                  coverKey: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Titolo senza copertina'), findsOneWidget);
  });

  group('fan behaviour', () {
    AlbumSummary album(int i) => AlbumSummary(
      albumKey: 'k$i',
      title: 'Album $i',
      artist: 'A',
      variousArtists: false,
      trackCount: 1,
      durationMs: 1000,
      year: null,
      coverKey: null,
    );

    final pushed = <Route<dynamic>>[];
    final observer = _PushObserver(pushed);

    Future<void> pump(WidgetTester tester, int n) async {
      pushed.clear();
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('it'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildThemeFromColors(CcColors.notte, false),
            navigatorObservers: [observer],
            home: Scaffold(
              body: CoverFan(albums: [for (var i = 0; i < n; i++) album(i)]),
            ),
          ),
        ),
      );
      pushed.clear(); // the home route
    }

    testWidgets('closed, only the first five albums are shown', (t) async {
      await pump(t, 8);
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(ValueKey('fan-cover-$i')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('fan-cover-5')), findsNothing);
    });

    testWidgets('the first tap opens the fan and does not open an album', (
      t,
    ) async {
      await pump(t, 3);
      await t.tap(find.byKey(const ValueKey('fan-cover-1')));
      await t.pumpAndSettle();
      expect(pushed, isEmpty);
    });

    testWidgets('open, all albums are in a row of fixed 84 dp squares with title and artist', (
      t,
    ) async {
      await pump(t, 20);
      await t.tap(find.byKey(const ValueKey('fan-cover-0')));
      await t.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        final sq = find.descendant(
          of: find.byKey(ValueKey('fan-cover-$i')),
          matching: find.byType(Container),
        );
        expect(t.getSize(sq.first), const Size(84, 84));
      }
      // The title text sits under the square (the item is taller than 84 dp).
      final item = find.byKey(const ValueKey('fan-cover-0'));
      expect(t.getSize(item).height, greaterThan(84 + 20));
      expect(
        find.descendant(of: item, matching: find.text('A')),
        findsOneWidget,
      );
      // All 20 are in the list: scroll to the last one.
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('fan-cover-19')),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.byKey(const ValueKey('fan-cover-19')), findsOneWidget);
    });

    testWidgets('open covers say "title, artist"', (t) async {
      final handle = t.ensureSemantics();
      await pump(t, 3);
      await t.tap(find.byKey(const ValueKey('fan-cover-0')));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Album 1, A'), findsOneWidget);
      handle.dispose();
    });

    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
      testWidgets('${key.keyLabel} opens the focused fan', (t) async {
        await pump(t, 3);
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.sendKeyEvent(key);
        await t.pumpAndSettle();
        expect(find.byType(ListView), findsOneWidget);
      });
    }

    testWidgets('Escape closes and the focus stays on the fan', (t) async {
      await pump(t, 3);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('a second tap on the empty area closes the open row', (t) async {
      await pump(t, 3);
      await t.tap(find.byKey(const ValueKey('fan-cover-0')));
      await t.pumpAndSettle();
      final a = t.getRect(find.byKey(const ValueKey('fan-cover-0')));
      final b = t.getRect(find.byKey(const ValueKey('fan-cover-1')));
      await t.tapAt(Offset((a.right + b.left) / 2, a.top + 40));
      await t.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('hover opens, leaving and scrolling do not close', (t) async {
      await pump(t, 8);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(find.byKey(const ValueKey('fan-cover-2'))));
      await t.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
      await mouse.moveTo(const Offset(5, 700));
      await t.drag(find.byType(ListView), const Offset(-100, 0));
      await t.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('a drag of the page outside does not close', (t) async {
      await pump(t, 3);
      await t.tap(find.byKey(const ValueKey('fan-cover-0')));
      await t.pumpAndSettle();
      await t.dragFrom(const Offset(180, 700), const Offset(0, -150));
      await t.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('a tap outside closes the open row', (t) async {
      await pump(t, 3);
      await t.tap(find.byKey(const ValueKey('fan-cover-0')));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(180, 700));
      await t.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('the second tap on a spread cover opens that album', (t) async {
      await pump(t, 3);
      await t.tap(find.byKey(const ValueKey('fan-cover-0')));
      await t.pumpAndSettle();
      await t.tap(
        find.byKey(const ValueKey('fan-cover-2')),
        warnIfMissed: false,
      );
      // The route is pushed on the tap; its page is never built here.
      expect(pushed, hasLength(1));
      await t.pumpWidget(const SizedBox());
    });
  });
}

class _PushObserver extends NavigatorObserver {
  _PushObserver(this.pushed);

  final List<Route<dynamic>> pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);
}
