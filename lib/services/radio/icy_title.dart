/// Turns the raw «now playing» text of a stream (ICY `StreamTitle`) into
/// something to show, or null when there is nothing worth showing.
///
/// Some publishers send `a~b~c~year~…`: the first two non-empty fields are
/// joined, since the order of artist and title cannot be guessed. A title that
/// is empty or only repeats the station's name is no information.
String? cleanIcyTitle(String? raw, String stationName) {
  var text = raw?.trim() ?? '';
  if (text.contains('~')) {
    final fields = [
      for (final f in text.split('~'))
        if (f.trim().isNotEmpty) f.trim(),
    ];
    text = fields.take(2).join(', ');
  }
  if (text.isEmpty) return null;
  if (text.toLowerCase() == stationName.trim().toLowerCase()) return null;
  return text;
}
