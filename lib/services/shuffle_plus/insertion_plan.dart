import '../audio/online_entries.dart' show isOnlineId;

/// Where the next suggestion goes in the play order [items], or null.
///
/// [playedSinceLast] counts the library songs that have started since the
/// last suggestion, the current one included; a suggestion comes after
/// [every] − 1 of them (every 4: three of yours, then one suggested). Null
/// when one is already waiting after the current song, when nothing plays, or
/// when the queue ends before the place (a suggestion would be the last
/// thing played: not worth a request).
int? nextInsertion(
  List<int> items,
  int currentIndex,
  int playedSinceLast,
  int every,
) {
  if (currentIndex < 0 || currentIndex >= items.length) return null;
  for (var i = currentIndex + 1; i < items.length; i++) {
    if (isOnlineId(items[i])) return null;
  }
  final remaining = every - 1 - playedSinceLast;
  final index = currentIndex + 1 + (remaining < 0 ? 0 : remaining);
  return index < items.length ? index : null;
}
