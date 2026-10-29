import 'dart:math';

/// Picks a «suggested» track for a part that ran out (R-102, D-185, D-208).
///
/// A genre is drawn with probability proportional to [genreWeights] (how often it
/// appeared in the person's queue from before); [candidates] gives the tracks of
/// that genre (null: any); the ones [isPlayed] in the Jam are left out. A genre with
/// no candidates is dropped and the draw repeats; at the end any library track,
/// at random. Null only when the library has nothing to offer.
Future<T?> pickSuggestion<T>({
  required Map<String, int> genreWeights,
  required Future<List<T>> Function(String? genre) candidates,
  required bool Function(T) isPlayed,
  required Random random,
}) async {
  final left = {
    for (final e in genreWeights.entries)
      if (e.value > 0) e.key: e.value,
  };
  while (left.isNotEmpty) {
    var r = random.nextInt(left.values.reduce((a, b) => a + b));
    final genre = left.entries.firstWhere((e) => (r -= e.value) < 0).key;
    final list = (await candidates(genre)).where((t) => !isPlayed(t)).toList();
    if (list.isNotEmpty) return list[random.nextInt(list.length)];
    left.remove(genre);
  }
  final list = (await candidates(null)).where((t) => !isPlayed(t)).toList();
  return list.isEmpty ? null : list[random.nextInt(list.length)];
}

/// Same song in the Jam's «already played» sense: title and artist, case-blind.
String suggestionKey(String title, String? artist) =>
    '${title.trim().toLowerCase()}|${(artist ?? '').trim().toLowerCase()}';
