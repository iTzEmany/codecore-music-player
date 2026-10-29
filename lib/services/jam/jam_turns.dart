import 'dart:math' show max;

import 'jam_models.dart';

/// Turn-by-turn order of «Coda insieme» (D-187, D-214).
///
/// Items up to [currentIndex] stay put. After it, each owner's items keep their
/// own order and take turns, starting with whoever follows the current item's
/// owner in [participantOrder]; an owner with nothing left is skipped. Items of
/// owners missing from [participantOrder] (who left, D-210) keep their index
/// and the others take turns in the remaining slots. Inherited items count as
/// their owner's part (D-192).
List<JamItem> togetherOrder(
  List<JamItem> items,
  int currentIndex,
  List<String> participantOrder,
) {
  final start = max(0, currentIndex + 1);
  if (start >= items.length) return items;
  final parts = <String, List<JamItem>>{};
  for (final i in items.skip(start)) {
    if (participantOrder.contains(i.ownerDeviceId)) {
      (parts[i.ownerDeviceId] ??= []).add(i);
    }
  }
  final cur = currentIndex >= 0 ? items[currentIndex].ownerDeviceId : null;
  final from = cur == null ? -1 : participantOrder.indexOf(cur);
  // Rotate the owners so the one after the current owner goes first.
  final known = participantOrder.where(parts.containsKey).toList();
  final turn = [
    ...known.where((o) => participantOrder.indexOf(o) > from),
    ...known.where((o) => participantOrder.indexOf(o) <= from),
  ];
  final out = [...items];
  final next = {for (final o in turn) o: 0};
  var slot = start;
  bool free(int i) => participantOrder.contains(items[i].ownerDeviceId);
  var left = parts.values.fold(0, (n, p) => n + p.length);
  while (left > 0) {
    for (final o in turn) {
      final p = parts[o]!, n = next[o]!;
      if (n >= p.length) continue;
      while (!free(slot)) {
        slot++;
      }
      out[slot++] = p[n];
      next[o] = n + 1;
      left--;
    }
  }
  return out;
}
