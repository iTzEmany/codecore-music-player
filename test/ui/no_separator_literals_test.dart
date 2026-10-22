import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Rewritten by plan 2.4; remove this list once it is merged.
const _ownedBy24 = ['lib/ui/screens/search/', 'lib/ui/screens/online/'];

void main() {
  test('no separator dot in UI string literals', () {
    final dot = RegExp(r"""['"][^'"\n]*\s·\s[^'"\n]*['"]""");
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.startsWith('lib/l10n/') || _ownedBy24.any(f.path.startsWith)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith('//')) continue;
        if (dot.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });
}
