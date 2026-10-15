import 'package:codecore/services/import/csv_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain rows with LF and CRLF', () {
    expect(parseCsv('a,b\n1,2\n'), [
      ['a', 'b'],
      ['1', '2'],
    ]);
    expect(parseCsv('a,b\r\n1,2\r\n'), [
      ['a', 'b'],
      ['1', '2'],
    ]);
  });

  test('quoted comma, escaped quote and line break inside a field', () {
    final rows = parseCsv('t,n\n"Hello, World","He said ""hi""\nthere"\n');
    expect(rows[1], ['Hello, World', 'He said "hi"\nthere']);
  });

  test('BOM and missing final newline', () {
    expect(parseCsv('﻿a,b\n1,2'), [
      ['a', 'b'],
      ['1', '2'],
    ]);
  });

  test('empty fields and blank lines', () {
    expect(parseCsv('a,,c\n\n1,2,\n'), [
      ['a', '', 'c'],
      ['1', '2', ''],
    ]);
    expect(parseCsv(''), isEmpty);
  });

  test('quote inside an unquoted field is literal', () {
    expect(parseCsv('5" nails,x\n')[0], ['5" nails', 'x']);
  });
}
