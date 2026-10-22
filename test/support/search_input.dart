import 'package:codecore/providers/ui_providers.dart';
import 'package:codecore/ui/screens/search/search_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// On a phone the Search field lives in the dock; tests that pump only
// `SearchScreen` drive the same shared controller and submit signal.
ProviderContainer _container(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(SearchScreen)));

void typeSearch(WidgetTester t, String text) =>
    _container(t).read(searchControllerProvider).text = text;

void submitSearch(WidgetTester t) =>
    _container(t).read(searchSubmitProvider.notifier).submit();
