// Architecture rule (D-24): lib/ui talks to the data layer only through
// providers (the *Ops in lib/providers), never databaseProvider or
// *RepositoryProvider directly.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _forbidden = RegExp(r'databaseProvider|RepositoryProvider');

void main() {
  test('no lib/ui file uses databaseProvider or *RepositoryProvider', () {
    final offenders = [
      for (final f in Directory('lib/ui').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            _forbidden.hasMatch(f.readAsStringSync()))
          f.path.replaceAll(r'\', '/'),
    ]..sort();
    expect(offenders, isEmpty);
  });
}
