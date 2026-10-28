import 'package:codecore/ui/screens/jam/jam_parts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jamTriviaText keeps the text and drops the source url', () {
    expect(jamTriviaText(null), isNull);
    expect(jamTriviaText('https://a.b/x'), isNull);
    expect(jamTriviaText('\nhttps://a.b'), isNull);
    expect(jamTriviaText('testo\nhttps://a.b'), 'testo');
    expect(jamTriviaText('testo\n'), 'testo');
    expect(jamTriviaText('  '), isNull);
    expect(jamTriviaText('uno\ndue\nhttps://a.b'), 'uno\ndue');
  });
}
