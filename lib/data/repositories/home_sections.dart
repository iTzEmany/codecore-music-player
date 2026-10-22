import 'library_queries.dart';

enum Greeting { morning, afternoon, evening }

/// 05–11 morning, 12–17 afternoon, otherwise evening (late nights too).
Greeting greetingForHour(int hour) {
  if (hour >= 5 && hour < 12) return Greeting.morning;
  if (hour >= 12 && hour < 18) return Greeting.afternoon;
  return Greeting.evening;
}

/// Albums played a lot but not for a while, most played first.
List<AlbumSummary> rediscoverAlbums(
  List<AlbumSummary> albums,
  DateTime now, {
  int minPlays = 3,
  Duration idle = const Duration(days: 60),
  int limit = 10,
}) {
  final cutoff = now.subtract(idle).millisecondsSinceEpoch;
  final out = [
    for (final a in albums)
      if (a.playCount >= minPlays &&
          a.lastPlayedAt != null &&
          a.lastPlayedAt! < cutoff)
        a,
  ]..sort((a, b) => b.playCount.compareTo(a.playCount));
  return out.take(limit).toList();
}

/// Albums by latest `addedAt`.
List<AlbumSummary> recentlyAddedAlbums(List<AlbumSummary> albums,
    {int limit = 10}) {
  final out = [...albums]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  return out.take(limit).toList();
}
