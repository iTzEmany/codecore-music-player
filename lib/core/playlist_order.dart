/// New order of a playlist after a sync. The tracks in [newIndexByTrack] follow
/// the new file; any other track (added by hand) stays right after the track
/// that preceded it, and those at the very start stay at the start.
List<int> reorderForSync(List<int> current, Map<int, int> newIndexByTrack) {
  final head = <int>[];
  final groups = <List<int>>[];
  for (final id in current) {
    if (newIndexByTrack.containsKey(id)) {
      groups.add([id]);
    } else if (groups.isEmpty) {
      head.add(id);
    } else {
      groups.last.add(id);
    }
  }
  groups.sort((a, b) =>
      newIndexByTrack[a.first]!.compareTo(newIndexByTrack[b.first]!));
  return [...head, for (final g in groups) ...g];
}
