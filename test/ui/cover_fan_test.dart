import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/ui/screens/home/cover_fan.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
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

  group('fan behaviour today', () {
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

    testWidgets('open, the covers shrink below their closed size (F-31)', (
      t,
    ) async {
      await pump(t, 5);
      double width() => t
          .getRect(
            find
                .descendant(
                  of: find.byKey(const ValueKey('fan-cover-0')),
                  matching: find.byType(Container),
                )
                .first,
          )
          .width;
      final before = width();
      await t.tap(find.byKey(const ValueKey('fan-cover-0')));
      await t.pumpAndSettle();
      final after = width();
      expect(after, lessThan(before));
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
