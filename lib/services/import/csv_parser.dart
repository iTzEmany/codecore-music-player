/// Minimal RFC 4180 parser: quotes, `""` escapes, separators and line breaks
/// inside quoted fields, `\r\n` or `\n`, leading UTF-8 BOM.
List<List<String>> parseCsv(String text) {
  var s = text;
  if (s.startsWith('﻿')) s = s.substring(1);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldStarted = false;

  void endField() {
    row.add(field.toString());
    field.clear();
    fieldStarted = false;
  }

  void endRow() {
    endField();
    // A lone empty field is a blank line, not a record.
    if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < s.length && s[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
      continue;
    }
    switch (c) {
      case '"':
        // A quote in the middle of an unquoted field is kept literally.
        if (!fieldStarted) {
          inQuotes = true;
          fieldStarted = true;
        } else {
          field.write(c);
        }
      case ',':
        endField();
      case '\r':
        if (i + 1 < s.length && s[i + 1] == '\n') i++;
        endRow();
      case '\n':
        endRow();
      default:
        field.write(c);
        fieldStarted = true;
    }
  }
  if (fieldStarted || field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// RFC 4180 writer: `\r\n` between records, quotes only where needed.
String writeCsv(List<List<String>> rows) {
  String cell(String v) => v.contains(RegExp(r'[",\r\n]'))
      ? '"${v.replaceAll('"', '""')}"'
      : v;
  return rows.map((r) => r.map(cell).join(',')).join('\r\n') +
      (rows.isEmpty ? '' : '\r\n');
}
