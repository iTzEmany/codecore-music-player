import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Parsers of YouTube Music text: the bullet is remote data, not UI.
const _parsers = [
  'lib/services/releases/release_diff.dart',
  'lib/services/online/',
];

void main() {
  test('no separator dot in UI string literals', () {
    final dot = RegExp(r"""['"][^'"\n]*(\s·\s|[•→▾])[^'"\n]*['"]""");
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll(r'\', '/'); // Windows separators
      if (!path.endsWith('.dart') || path.startsWith('lib/l10n/') || _parsers.any(path.startsWith)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith('//')) continue;
        if (dot.hasMatch(lines[i])) hits.add('$path:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });
}
