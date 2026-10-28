import 'package:codecore/providers/library_providers.dart' show searchIndexProvider;
import 'package:codecore/providers/ui_providers.dart';
import 'package:codecore/ui/screens/search/search_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter_test/flutter_test.dart';

// On a phone the Search field lives in the dock; tests that pump only
// `SearchScreen` drive the same shared controller and submit signal.
ProviderContainer _container(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(SearchScreen)));

void typeSearch(WidgetTester t, String text) =>
    _container(t).read(searchControllerProvider).text = text;

void submitSearch(WidgetTester t) =>
    _container(t).read(searchSubmitProvider.notifier).submit();

/// The search index is built on another isolate, which the test clock does
/// not wait for: pump and give the real loop a turn until it is there.
Future<void> indexReady(WidgetTester t) async {
  // First let a write reach the index (drift's notice is on the test clock).
  for (var i = 0; i < 3; i++) {
    await t.pump(const Duration(milliseconds: 50));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
  final c = ProviderScope.containerOf(t.element(find.byType(MaterialApp)));
  if (!c.exists(searchIndexProvider)) return; // nothing asked for it (yet)
  var done = false;
  void finish([Object? _]) => done = true;
  c.read(searchIndexProvider.future).then(finish, onError: finish);
  for (var i = 0; i < 100 && !done; i++) {
    await t.pump(const Duration(milliseconds: 50));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
}
