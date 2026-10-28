import 'jam_models.dart';

/// Turn-by-turn order of «Coda insieme» (D-187, D-214).
///
/// Items up to [currentIndex] stay put. After it, each owner's items keep their
/// own order and take turns, starting with whoever follows the current item's
/// owner in [participantOrder]; an owner with nothing left is skipped, owners
/// missing from the list come last in order of appearance. Inherited items
/// count as their owner's part (D-192).
List<JamItem> togetherOrder(
  List<JamItem> items,
  int currentIndex,
  List<String> participantOrder,
) {
  final start = currentIndex + 1;
  if (start >= items.length) return items;
  final parts = <String, List<JamItem>>{};
  for (final i in items.skip(start)) {
    (parts[i.ownerDeviceId] ??= []).add(i);
  }
  final known = participantOrder.where(parts.containsKey).toList();
  final owners = [...known, ...parts.keys.where((o) => !known.contains(o))];
  final cur = currentIndex >= 0 ? items[currentIndex].ownerDeviceId : null;
  final from = cur == null ? -1 : participantOrder.indexOf(cur);
  // Rotate the known owners so the one after the current owner goes first.
  final after = known.where((o) => participantOrder.indexOf(o) > from).toList();
  final turn = [
    ...after,
    ...known.where((o) => !after.contains(o)),
    ...owners.skip(known.length),
  ];
  final out = items.sublist(0, start);
  final next = {for (final o in turn) o: 0};
  var left = items.length - start;
  while (left > 0) {
    for (final o in turn) {
      final p = parts[o]!, n = next[o]!;
      if (n < p.length) {
        out.add(p[n]);
        next[o] = n + 1;
        left--;
      }
    }
  }
  return out;
}
